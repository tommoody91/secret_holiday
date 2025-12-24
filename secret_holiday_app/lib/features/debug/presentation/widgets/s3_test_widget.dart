import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/photo_upload_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Debug widget to test S3 photo uploads via the backend API
class S3TestWidget extends ConsumerStatefulWidget {
  const S3TestWidget({super.key});

  @override
  ConsumerState<S3TestWidget> createState() => _S3TestWidgetState();
}

class _S3TestWidgetState extends ConsumerState<S3TestWidget> {
  bool _isLoading = false;
  String _status = 'Ready to test';
  List<PhotoInfo> _uploadedPhotos = [];
  bool _backendHealthy = false;

  @override
  void initState() {
    super.initState();
    _checkBackendHealth();
  }

  Future<void> _checkBackendHealth() async {
    setState(() => _status = 'Checking backend connection...');
    final healthy = await PhotoUploadService.healthCheck();
    setState(() {
      _backendHealthy = healthy;
      _status = healthy 
          ? '✅ Backend connected at ${PhotoUploadService.baseUrl}'
          : '❌ Backend not reachable at ${PhotoUploadService.baseUrl}';
    });
  }

  Future<String?> _getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _status = '❌ Not logged in');
      return null;
    }
    return await user.getIdToken();
  }

  Future<void> _uploadPhoto() async {
    final token = await _getAuthToken();
    if (token == null) return;

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 85,
    );

    if (pickedFile == null) {
      setState(() => _status = 'No image selected');
      return;
    }

    setState(() {
      _isLoading = true;
      _status = 'Uploading...';
    });

    final result = await PhotoUploadService.uploadPhoto(
      file: File(pickedFile.path),
      tripId: 'test-trip-123', // Test trip ID
      authToken: token,
    );

    setState(() {
      _isLoading = false;
      if (result.success) {
        _status = '✅ Upload successful!\nURL: ${result.url}';
      } else {
        _status = '❌ Upload failed: ${result.error}';
      }
    });

    // Refresh photo list
    if (result.success) {
      await _listPhotos();
    }
  }

  Future<void> _listPhotos() async {
    final token = await _getAuthToken();
    if (token == null) return;

    setState(() {
      _isLoading = true;
      _status = 'Loading photos...';
    });

    final photos = await PhotoUploadService.listPhotos(
      tripId: 'test-trip-123',
      authToken: token,
    );

    setState(() {
      _isLoading = false;
      _uploadedPhotos = photos;
      _status = 'Found ${photos.length} photos';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 S3 Upload Test'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _backendHealthy ? Colors.green[50] : Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _backendHealthy ? Icons.check_circle : Icons.error,
                          color: _backendHealthy ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Backend Status',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _checkBackendHealth,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Check Backend'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || !_backendHealthy ? null : _listPhotos,
                    icon: const Icon(Icons.list),
                    label: const Text('List Photos'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Upload Button
            ElevatedButton.icon(
              onPressed: _isLoading || !_backendHealthy ? null : _uploadPhoto,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isLoading ? 'Uploading...' : 'Upload Photo to S3'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),

            const SizedBox(height: 24),

            // Photo Grid
            if (_uploadedPhotos.isNotEmpty) ...[
              Text(
                'Uploaded Photos (${_uploadedPhotos.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _uploadedPhotos.length,
                itemBuilder: (context, index) {
                  final photo = _uploadedPhotos[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      photo.url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image),
                        );
                      },
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 24),

            // Instructions
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Flutter sends photo to backend API\n'
                      '2. Backend validates Firebase auth token\n'
                      '3. Backend uploads to AWS S3\n'
                      '4. S3 URL returned to Flutter\n\n'
                      'Backend URL: ${PhotoUploadService.baseUrl}',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
