import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/photo_upload_service.dart';
import '../../data/models/trip_model.dart';

/// Memories tab showing photo/video gallery for the trip
class MemoriesTab extends ConsumerStatefulWidget {
  final String groupId;
  final TripModel trip;

  const MemoriesTab({super.key, required this.groupId, required this.trip});

  @override
  ConsumerState<MemoriesTab> createState() => _MemoriesTabState();
}

class _MemoriesTabState extends ConsumerState<MemoriesTab> {
  bool _isUploading = false;
  String? _uploadStatus;
  final List<PhotoInfo> _uploadedPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadUploadedPhotos();
  }

  Future<void> _loadUploadedPhotos() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) return;

    final photos = await PhotoUploadService.listPhotos(
      tripId: widget.trip.id,
      authToken: token,
    );

    if (mounted) {
      setState(() {
        _uploadedPhotos.clear();
        _uploadedPhotos.addAll(photos);
      });
    }
  }

  Future<void> _pickAndUploadPhotos() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to upload photos')),
      );
      return;
    }

    // Check backend connectivity first
    final isHealthy = await PhotoUploadService.healthCheck();
    if (!isHealthy) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cannot connect to server at ${PhotoUploadService.baseUrl}. Make sure the backend is running.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(
      maxWidth: 1920,
      imageQuality: 85,
    );

    if (pickedFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadStatus = 'Uploading ${pickedFiles.length} photo(s)...';
    });

    int successCount = 0;
    int failCount = 0;

    for (final pickedFile in pickedFiles) {
      final result = await PhotoUploadService.uploadPhoto(
        file: File(pickedFile.path),
        tripId: widget.trip.id,
        authToken: token,
      );

      if (result.success) {
        successCount++;
      } else {
        failCount++;
      }

      if (mounted) {
        setState(() {
          _uploadStatus = 'Uploaded $successCount of ${pickedFiles.length}...';
        });
      }
    }

    // Refresh photo list
    await _loadUploadedPhotos();

    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadStatus = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failCount == 0
                ? '✅ Uploaded $successCount photo(s) successfully!'
                : '⚠️ Uploaded $successCount, failed $failCount',
          ),
          backgroundColor: failCount == 0 ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Combine trip.media with uploaded photos from S3
    final allMedia = [
      ...widget.trip.media,
      ..._uploadedPhotos.map((p) => TripMedia(
            id: p.key,
            url: p.url,
            type: 'photo',
            uploadedBy: FirebaseAuth.instance.currentUser?.uid ?? '',
            uploadedAt: DateTime.now(),
          )),
    ];

    if (allMedia.isEmpty && !_isUploading) {
      return _buildEmptyState(context);
    }

    return Stack(
      children: [
        CustomScrollView(
          slivers: [
            // View toggle and filter options
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${allMedia.length} memories',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Row(
                      children: [
                        // Add photos button
                        IconButton(
                          icon: const Icon(Icons.add_a_photo),
                          onPressed: _isUploading ? null : _pickAndUploadPhotos,
                          tooltip: 'Add Photos',
                        ),
                        // Refresh button
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _isUploading ? null : _loadUploadedPhotos,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Upload status
            if (_isUploading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          const SizedBox(width: 12),
                          Text(_uploadStatus ?? 'Uploading...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Photo grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final media = allMedia[index];
                  return _MediaThumbnail(
                    media: media,
                    onTap: () => _showFullScreenViewer(context, allMedia, index),
                  );
                }, childCount: allMedia.length),
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),

        // FAB for adding photos
        Positioned(
          bottom: 80,
          right: 16,
          child: FloatingActionButton(
            onPressed: _isUploading ? null : _pickAndUploadPhotos,
            backgroundColor: _isUploading ? Colors.grey : AppColors.primary,
            child: _isUploading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.add_a_photo),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Memories Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Start capturing moments from your trip!',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadPhotos,
              icon: _isUploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_a_photo),
              label: Text(_isUploading ? 'Uploading...' : 'Add Photos'),
            ),
            if (_uploadStatus != null) ...[
              const SizedBox(height: 16),
              Text(
                _uploadStatus!,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showFullScreenViewer(
      BuildContext context, List<TripMedia> media, int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenMemoryViewer(
          media: media,
          initialIndex: initialIndex,
        ),
      ),
    );
  }
}

class _MediaThumbnail extends StatelessWidget {
  final TripMedia media;
  final VoidCallback onTap;

  const _MediaThumbnail({required this.media, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Thumbnail
          Container(
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: media.thumbnailUrl != null || media.url.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Image.network(
                      media.thumbnailUrl ?? media.url,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(
                            Icons.broken_image,
                            color: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  )
                : const Center(
                    child: Icon(Icons.image, color: AppColors.textSecondary),
                  ),
          ),

          // Video indicator
          if (media.type == 'video')
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.play_arrow,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Full screen photo/video viewer with swipe navigation
class _FullScreenMemoryViewer extends StatefulWidget {
  final List<TripMedia> media;
  final int initialIndex;

  const _FullScreenMemoryViewer({
    required this.media,
    required this.initialIndex,
  });

  @override
  State<_FullScreenMemoryViewer> createState() =>
      _FullScreenMemoryViewerState();
}

class _FullScreenMemoryViewerState extends State<_FullScreenMemoryViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Photo PageView
          PageView.builder(
            controller: _pageController,
            itemCount: widget.media.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final media = widget.media[index];
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    media.url,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.white54,
                              size: 64,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Failed to load image',
                              style: TextStyle(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // Top bar with close button and counter
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close button - larger tap target
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),

                      // Photo counter
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.media.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Spacer for symmetry
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom bar with caption
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black54, Colors.transparent],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.media[_currentIndex].caption != null &&
                          widget.media[_currentIndex].caption!.isNotEmpty) ...[
                        Text(
                          widget.media[_currentIndex].caption!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
