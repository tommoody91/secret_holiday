import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/utils/logger.dart';
import '../../core/error/exceptions.dart';

/// Local storage service for media files
/// This handles storing images/videos locally on device
/// Can be easily switched to Firebase Storage later
class LocalStorageService {
  static const String _mediaFolder = 'secret_holiday_media';
  static const String _profilePicturesFolder = 'profile_pictures';
  static const String _tripMediaFolder = 'trip_media';
  static const String _chatMediaFolder = 'chat_media';
  
  /// Get the app's documents directory
  Future<Directory> _getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory;
  }
  
  /// Create a folder if it doesn't exist
  Future<Directory> _createFolder(String folderName) async {
    final appDir = await _getAppDirectory();
    final folder = Directory('${appDir.path}/$_mediaFolder/$folderName');
    
    if (!await folder.exists()) {
      await folder.create(recursive: true);
      AppLogger.info('Created folder: ${folder.path}');
    }
    
    return folder;
  }
  
  /// Save a file to local storage
  /// Returns the local file path
  Future<String> saveFile({
    required File file,
    required String fileName,
    required String category, // 'profile', 'trip', 'chat'
  }) async {
    try {
      String folderName;
      switch (category) {
        case 'profile':
          folderName = _profilePicturesFolder;
          break;
        case 'trip':
          folderName = _tripMediaFolder;
          break;
        case 'chat':
          folderName = _chatMediaFolder;
          break;
        default:
          folderName = 'other';
      }
      
      final folder = await _createFolder(folderName);
      final newPath = '${folder.path}/$fileName';
      final savedFile = await file.copy(newPath);
      
      AppLogger.info('File saved to: $newPath');
      return savedFile.path;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to save file', e, stackTrace);
      throw const CacheException('Failed to save file locally');
    }
  }
  
  /// Delete a file from local storage
  Future<void> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        AppLogger.info('File deleted: $filePath');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to delete file', e, stackTrace);
      throw const CacheException('Failed to delete file');
    }
  }
  
  /// Get a file from local storage
  Future<File?> getFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to get file', e, stackTrace);
      return null;
    }
  }
  
  /// Check if a file exists
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }
  
  /// Get total storage used by the app
  Future<int> getTotalStorageUsed() async {
    try {
      final appDir = await _getAppDirectory();
      final mediaDir = Directory('${appDir.path}/$_mediaFolder');
      
      if (!await mediaDir.exists()) {
        return 0;
      }
      
      int totalSize = 0;
      await for (final entity in mediaDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
      
      return totalSize;
    } catch (e, stackTrace) {
      AppLogger.error('Failed to calculate storage', e, stackTrace);
      return 0;
    }
  }
  
  /// Clear all cached media
  Future<void> clearAllMedia() async {
    try {
      final appDir = await _getAppDirectory();
      final mediaDir = Directory('${appDir.path}/$_mediaFolder');
      
      if (await mediaDir.exists()) {
        await mediaDir.delete(recursive: true);
        AppLogger.info('All media cleared');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Failed to clear media', e, stackTrace);
      throw const CacheException('Failed to clear media');
    }
  }
}
