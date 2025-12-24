import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import '../utils/logger.dart';

/// Service for uploading photos via the backend API
/// The backend handles all AWS S3 logic - Flutter just sends files to the API
class PhotoUploadService {
  // Backend API URL - use 10.0.2.2 for Android emulator
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    // Android emulator uses 10.0.2.2 to reach host machine
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    }
    // iOS simulator and desktop use localhost
    return 'http://localhost:8000';
  }

  /// Upload a photo to S3 via the backend
  /// Returns the S3 URL of the uploaded photo
  static Future<PhotoUploadResult> uploadPhoto({
    required File file,
    required String tripId,
    required String authToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/upload/photo?trip_id=$tripId');
      
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $authToken'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
          contentType: MediaType('image', _getImageType(file.path)),
        ));

      AppLogger.info('Uploading photo to: $uri');
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        AppLogger.info('Photo uploaded successfully: ${data['url']}');
        return PhotoUploadResult(
          success: true,
          photoId: data['photo_id'],
          url: data['url'],
          tripId: data['trip_id'],
        );
      } else {
        final error = json.decode(response.body)['detail'] ?? 'Upload failed';
        AppLogger.error('Upload failed: $error');
        return PhotoUploadResult(success: false, error: error);
      }
    } catch (e, stackTrace) {
      AppLogger.error('Upload exception', e, stackTrace);
      return PhotoUploadResult(success: false, error: e.toString());
    }
  }

  /// List photos for a trip
  static Future<List<PhotoInfo>> listPhotos({
    required String tripId,
    required String authToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/upload/photos/$tripId');
      
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $authToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final photos = (data['photos'] as List)
            .map((p) => PhotoInfo.fromJson(p))
            .toList();
        return photos;
      } else {
        AppLogger.error('Failed to list photos: ${response.body}');
        return [];
      }
    } catch (e, stackTrace) {
      AppLogger.error('List photos exception', e, stackTrace);
      return [];
    }
  }

  /// Delete a photo
  static Future<bool> deletePhoto({
    required String photoId,
    required String tripId,
    required String authToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/upload/photo/$photoId?trip_id=$tripId');
      
      final response = await http.delete(
        uri,
        headers: {'Authorization': 'Bearer $authToken'},
      );

      return response.statusCode == 200;
    } catch (e, stackTrace) {
      AppLogger.error('Delete photo exception', e, stackTrace);
      return false;
    }
  }

  /// Check if backend is reachable
  static Future<bool> healthCheck() async {
    try {
      final uri = Uri.parse('$baseUrl/health');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 5),
      );
      return response.statusCode == 200;
    } catch (e) {
      AppLogger.error('Health check failed: $e');
      return false;
    }
  }

  static String _getImageType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'png';
      case 'webp':
        return 'webp';
      case 'heic':
        return 'heic';
      default:
        return 'jpeg';
    }
  }
}

/// Result of a photo upload
class PhotoUploadResult {
  final bool success;
  final String? photoId;
  final String? url;
  final String? tripId;
  final String? error;

  PhotoUploadResult({
    required this.success,
    this.photoId,
    this.url,
    this.tripId,
    this.error,
  });
}

/// Info about an uploaded photo
class PhotoInfo {
  final String key;
  final String url;
  final int size;
  final String lastModified;

  PhotoInfo({
    required this.key,
    required this.url,
    required this.size,
    required this.lastModified,
  });

  factory PhotoInfo.fromJson(Map<String, dynamic> json) {
    return PhotoInfo(
      key: json['key'] ?? '',
      url: json['url'] ?? '',
      size: json['size'] ?? 0,
      lastModified: json['last_modified'] ?? '',
    );
  }
}
