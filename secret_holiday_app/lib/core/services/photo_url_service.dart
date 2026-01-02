import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../utils/logger.dart';
import 'photo_upload_service.dart';

/// A cached photo URL with expiration tracking
class CachedPhotoUrl {
  final String s3Key;
  final String presignedUrl;
  final DateTime fetchedAt;
  
  /// URLs are valid for 24 hours, but we refresh after 20 hours to be safe
  static const Duration cacheValidDuration = Duration(hours: 20);
  
  CachedPhotoUrl({
    required this.s3Key,
    required this.presignedUrl,
    required this.fetchedAt,
  });
  
  bool get isExpired {
    return DateTime.now().difference(fetchedAt) > cacheValidDuration;
  }
  
  bool get isValid => !isExpired;
}

/// Service for managing photo URLs from S3
/// 
/// This service handles the pattern of:
/// 1. Storing S3 keys in Firestore (which never expire)
/// 2. Fetching fresh presigned URLs from the backend when needed
/// 3. Caching URLs locally to minimize backend calls
/// 
/// Usage:
/// ```dart
/// final url = await PhotoUrlService.getUrl(s3Key: 'trips/123/photos/abc.jpg');
/// // Use url in CachedNetworkImage
/// ```
class PhotoUrlService {
  static final PhotoUrlService _instance = PhotoUrlService._internal();
  factory PhotoUrlService() => _instance;
  PhotoUrlService._internal();
  
  /// In-memory cache of presigned URLs
  final Map<String, CachedPhotoUrl> _urlCache = {};
  
  /// Get the backend base URL from PhotoUploadService
  static String get _baseUrl => PhotoUploadService.baseUrl;
  
  /// Get a fresh presigned URL for an S3 key
  /// 
  /// If the URL is cached and still valid, returns the cached URL.
  /// Otherwise fetches a fresh URL from the backend.
  /// 
  /// [s3Key] - The S3 object key (e.g., 'trips/123/photos/abc.jpg')
  /// [forceRefresh] - If true, ignores cache and fetches fresh URL
  /// 
  /// Returns the presigned URL or null if fetch fails
  static Future<String?> getUrl({
    required String s3Key,
    bool forceRefresh = false,
  }) async {
    return _instance._getUrl(s3Key: s3Key, forceRefresh: forceRefresh);
  }
  
  /// Instance method for getting URL (allows testing)
  Future<String?> _getUrl({
    required String s3Key,
    bool forceRefresh = false,
  }) async {
    // Check if it's already a full URL (legacy data or presigned URL)
    if (s3Key.startsWith('http://') || s3Key.startsWith('https://')) {
      AppLogger.debug('PhotoUrlService: Key is already a URL, returning as-is');
      return s3Key;
    }
    
    // Check cache first
    if (!forceRefresh) {
      final cached = _urlCache[s3Key];
      if (cached != null && cached.isValid) {
        AppLogger.debug('PhotoUrlService: Using cached URL for $s3Key');
        return cached.presignedUrl;
      }
    }
    
    // Fetch fresh URL from backend
    try {
      final authToken = await _getAuthToken();
      if (authToken == null) {
        AppLogger.error('PhotoUrlService: No auth token available');
        return null;
      }
      
      final uri = Uri.parse('$_baseUrl/photos/url').replace(
        queryParameters: {'key': s3Key},
      );
      
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $authToken'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final url = data['url'] as String;
        
        // Cache the URL
        _urlCache[s3Key] = CachedPhotoUrl(
          s3Key: s3Key,
          presignedUrl: url,
          fetchedAt: DateTime.now(),
        );
        
        AppLogger.debug('PhotoUrlService: Fetched fresh URL for $s3Key');
        return url;
      } else {
        AppLogger.error('PhotoUrlService: Failed to get URL - ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      AppLogger.error('PhotoUrlService: Exception getting URL', e, stackTrace);
      return null;
    }
  }
  
  /// Get multiple presigned URLs at once (more efficient for lists)
  /// 
  /// [s3Keys] - List of S3 object keys
  /// [forceRefresh] - If true, ignores cache and fetches all fresh
  /// 
  /// Returns a map of s3Key -> presignedUrl
  static Future<Map<String, String>> getUrls({
    required List<String> s3Keys,
    bool forceRefresh = false,
  }) async {
    return _instance._getUrls(s3Keys: s3Keys, forceRefresh: forceRefresh);
  }
  
  Future<Map<String, String>> _getUrls({
    required List<String> s3Keys,
    bool forceRefresh = false,
  }) async {
    final result = <String, String>{};
    final keysToFetch = <String>[];
    
    // Check cache first for each key
    for (final s3Key in s3Keys) {
      // Handle legacy URLs
      if (s3Key.startsWith('http://') || s3Key.startsWith('https://')) {
        result[s3Key] = s3Key;
        continue;
      }
      
      if (!forceRefresh) {
        final cached = _urlCache[s3Key];
        if (cached != null && cached.isValid) {
          result[s3Key] = cached.presignedUrl;
          continue;
        }
      }
      
      keysToFetch.add(s3Key);
    }
    
    // Fetch remaining keys from backend
    if (keysToFetch.isNotEmpty) {
      try {
        final authToken = await _getAuthToken();
        if (authToken == null) {
          AppLogger.error('PhotoUrlService: No auth token available');
          return result;
        }
        
        final uri = Uri.parse('$_baseUrl/photos/urls');
        
        final response = await http.post(
          uri,
          headers: {
            'Authorization': 'Bearer $authToken',
            'Content-Type': 'application/json',
          },
          body: json.encode(keysToFetch),
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final urls = (data['urls'] as Map<String, dynamic>).cast<String, String>();
          
          // Cache all fetched URLs
          final now = DateTime.now();
          urls.forEach((key, url) {
            _urlCache[key] = CachedPhotoUrl(
              s3Key: key,
              presignedUrl: url,
              fetchedAt: now,
            );
            result[key] = url;
          });
          
          AppLogger.debug('PhotoUrlService: Batch fetched ${urls.length} URLs');
        } else {
          AppLogger.error('PhotoUrlService: Batch fetch failed - ${response.statusCode}');
        }
      } catch (e, stackTrace) {
        AppLogger.error('PhotoUrlService: Batch fetch exception', e, stackTrace);
      }
    }
    
    return result;
  }
  
  /// Handle a 403 error by refreshing the URL
  /// 
  /// Call this when CachedNetworkImage gets a 403 (expired URL).
  /// Returns a fresh URL that can be used to retry loading.
  static Future<String?> handleExpiredUrl(String s3Key) async {
    AppLogger.info('PhotoUrlService: Handling expired URL for $s3Key');
    return getUrl(s3Key: s3Key, forceRefresh: true);
  }
  
  /// Clear the URL cache (useful on logout or memory pressure)
  static void clearCache() {
    _instance._urlCache.clear();
    AppLogger.debug('PhotoUrlService: Cache cleared');
  }
  
  /// Remove a specific key from cache
  static void invalidate(String s3Key) {
    _instance._urlCache.remove(s3Key);
  }
  
  /// Get Firebase auth token
  static Future<String?> _getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }
      return await user.getIdToken();
    } catch (e) {
      AppLogger.error('PhotoUrlService: Failed to get auth token', e);
      return null;
    }
  }
}
