import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/photo_upload_service.dart';
import '../../data/models/trip_model.dart';
import '../../data/models/activity_model.dart';
import '../../data/models/memory_model.dart';
import '../../providers/activity_provider.dart';
import '../../providers/memory_provider.dart';

/// Memories tab showing photo/video gallery for the trip with filtering
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
  MemoryFilterState _filterState = const MemoryFilterState();
  bool _groupedByDay = true;  // Default to grouped view
  Set<int> _expandedDays = {};  // Track which day sections are expanded

  Future<void> _pickAndUploadPhotos() async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (token == null || userId == null) {
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

    // Show dialog to select day and activity (optional)
    final linkInfo = await _showDayActivitySelectionDialog();
    if (linkInfo == null) return; // User cancelled

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
    final memoryRepository = ref.read(memoryRepositoryProvider);

    for (final pickedFile in pickedFiles) {
      // Upload to S3
      final result = await PhotoUploadService.uploadPhoto(
        file: File(pickedFile.path),
        tripId: widget.trip.id,
        authToken: token,
        dayNumber: linkInfo.dayNumber,
        activityId: linkInfo.activityId,
      );

      if (result.success && result.url != null) {
        // Save to Firestore for querying/filtering
        await memoryRepository.createMemory(
          groupId: widget.groupId,
          tripId: widget.trip.id,
          url: result.url!,
          type: 'photo',
          uploadedBy: userId,
          dayNumber: linkInfo.dayNumber,
          activityId: linkInfo.activityId,
          activityName: linkInfo.activityName,
        );
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

  Future<_MemoryLinkInfo?> _showDayActivitySelectionDialog() async {
    int? selectedDay;
    String? selectedActivityId;
    String? selectedActivityName;
    List<ActivityModel> dayActivities = [];
    bool isLoadingActivities = false;

    return showDialog<_MemoryLinkInfo>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Memory'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Optionally link this memory to a specific day or activity',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Day selector
                    DropdownButtonFormField<int?>(
                      decoration: const InputDecoration(
                        labelText: 'Day (optional)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('No specific day'),
                        ),
                        ...List.generate(
                          widget.trip.durationDays,
                          (index) {
                            final dayNum = index + 1;
                            final date = widget.trip.startDate.add(Duration(days: index));
                            return DropdownMenuItem<int?>(
                              value: dayNum,
                              child: Text('Day $dayNum - ${_formatDate(date)}'),
                            );
                          },
                        ),
                      ],
                      onChanged: (value) async {
                        setDialogState(() {
                          selectedDay = value;
                          selectedActivityId = null;
                          selectedActivityName = null;
                          dayActivities = [];
                          isLoadingActivities = value != null;
                        });
                        
                        // Load activities for selected day
                        if (value != null) {
                          try {
                            final activities = await ref.read(
                              dayActivitiesProvider((
                                groupId: widget.groupId,
                                tripId: widget.trip.id,
                                dayNumber: value,
                              )).future,
                            );
                            setDialogState(() {
                              dayActivities = activities;
                              isLoadingActivities = false;
                            });
                          } catch (e) {
                            setDialogState(() {
                              isLoadingActivities = false;
                            });
                          }
                        }
                      },
                    ),
                    
                    // Activity selector (only show if day is selected)
                    if (selectedDay != null) ...[
                      const SizedBox(height: 16),
                      if (isLoadingActivities)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8),
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        )
                      else if (dayActivities.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, 
                                size: 18, 
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'No activities on this day yet',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        DropdownButtonFormField<String?>(
                          decoration: const InputDecoration(
                            labelText: 'Activity (optional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.event),
                          ),
                          isExpanded: true,
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('No specific activity'),
                            ),
                            ...dayActivities.map((activity) {
                              final iconCode = ActivityCategory.icons[activity.category] ?? 0xe8b8;
                              return DropdownMenuItem<String?>(
                                value: activity.id,
                                child: Row(
                                  children: [
                                    Icon(
                                      IconData(iconCode, fontFamily: 'MaterialIcons'),
                                      size: 18,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        activity.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            final activity = value != null 
                                ? dayActivities.firstWhere((a) => a.id == value)
                                : null;
                            setDialogState(() {
                              selectedActivityId = value;
                              selectedActivityName = activity?.name;
                            });
                          },
                        ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(_MemoryLinkInfo(
                      dayNumber: selectedDay,
                      activityId: selectedActivityId,
                      activityName: selectedActivityName,
                    ));
                  },
                  child: const Text('Select Photos'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final memoriesAsync = ref.watch(
      tripMemoriesProvider((groupId: widget.groupId, tripId: widget.trip.id)),
    );
    
    return memoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text('Error loading memories: $error'),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickAndUploadPhotos,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add First Memory'),
            ),
          ],
        ),
      ),
      data: (allMemories) {
        // Apply filter
        final filteredMemories = _applyFilter(allMemories, _filterState);
        
        if (allMemories.isEmpty && !_isUploading) {
          return _buildEmptyState(context);
        }

        return Stack(
          children: [
            CustomScrollView(
              slivers: [
                // Header with count and filter
                SliverToBoxAdapter(
                  child: _buildHeader(context, allMemories.length, filteredMemories.length, _filterState),
                ),

                // Filter chips (only show in grid view, grouped view has built-in organization)
                if (!_groupedByDay)
                  SliverToBoxAdapter(
                    child: _buildFilterChips(context, allMemories),
                  ),

                // Upload status
                if (_isUploading)
                  SliverToBoxAdapter(
                    child: _buildUploadStatus(),
                  ),

                // Content - either grouped by day or flat grid
                if (_groupedByDay)
                  ..._buildGroupedByDayView(context, filteredMemories)
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: filteredMemories.isEmpty
                        ? SliverToBoxAdapter(
                            child: _buildNoFilterResults(context, _filterState),
                          )
                        : SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              mainAxisSpacing: 4,
                              crossAxisSpacing: 4,
                            ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final memory = filteredMemories[index];
                                return _MemoryThumbnail(
                                  memory: memory,
                                  onTap: () => _showFullScreenViewer(
                                    context, 
                                    filteredMemories, 
                                    index,
                                  ),
                                );
                              },
                              childCount: filteredMemories.length,
                            ),
                          ),
                  ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
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
      },
    );
  }

  List<MemoryModel> _applyFilter(List<MemoryModel> memories, MemoryFilterState filter) {
    switch (filter.filterType) {
      case MemoryFilterType.all:
        return memories;
      case MemoryFilterType.day:
        if (filter.selectedDay == null) return memories;
        return memories.where((m) => m.dayNumber == filter.selectedDay).toList();
      case MemoryFilterType.activity:
        if (filter.selectedActivityId == null) return memories;
        return memories.where((m) => m.activityId == filter.selectedActivityId).toList();
    }
  }

  /// Build memories grouped by day with collapsible sections
  List<Widget> _buildGroupedByDayView(BuildContext context, List<MemoryModel> memories) {
    if (memories.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _buildNoFilterResults(context, _filterState),
        ),
      ];
    }

    // Group memories by day
    final Map<int?, List<MemoryModel>> groupedMemories = {};
    for (final memory in memories) {
      final day = memory.dayNumber;
      groupedMemories.putIfAbsent(day, () => []).add(memory);
    }

    // Sort days (null/untagged last)
    final sortedDays = groupedMemories.keys.toList()
      ..sort((a, b) {
        if (a == null) return 1;
        if (b == null) return -1;
        return a.compareTo(b);
      });

    final slivers = <Widget>[];

    for (final day in sortedDays) {
      final dayMemories = groupedMemories[day]!;
      final isExpanded = day == null || !_expandedDays.contains(day);
      final dayDate = day != null 
          ? widget.trip.startDate.add(Duration(days: day - 1))
          : null;

      // Day header
      slivers.add(
        SliverToBoxAdapter(
          child: InkWell(
            onTap: () {
              setState(() {
                if (day != null) {
                  if (_expandedDays.contains(day)) {
                    _expandedDays.remove(day);
                  } else {
                    _expandedDays.add(day);
                  }
                }
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.textSecondary.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: day != null 
                          ? AppColors.primary.withValues(alpha: 0.1)
                          : AppColors.textSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      day != null ? Icons.calendar_today : Icons.photo_library,
                      size: 20,
                      color: day != null ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          day != null ? 'Day $day' : 'Untagged Photos',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (dayDate != null)
                          Text(
                            _formatDate(dayDate),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '${dayMemories.length} ${dayMemories.length == 1 ? 'photo' : 'photos'}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Day photos (if expanded)
      if (isExpanded) {
        slivers.add(
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final memory = dayMemories[index];
                  // Find the index in the full memories list for fullscreen viewer
                  final fullIndex = memories.indexOf(memory);
                  return _MemoryThumbnail(
                    memory: memory,
                    onTap: () => _showFullScreenViewer(context, memories, fullIndex),
                  );
                },
                childCount: dayMemories.length,
              ),
            ),
          ),
        );
      }
    }

    return slivers;
  }

  Widget _buildHeader(BuildContext context, int totalCount, int filteredCount, MemoryFilterState filterState) {
    final isFiltered = filterState.filterType != MemoryFilterType.all;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isFiltered
                    ? '$filteredCount of $totalCount memories'
                    : '$totalCount memories',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (isFiltered)
                Text(
                  filterState.filterType == MemoryFilterType.day
                      ? 'Day ${filterState.selectedDay}'
                      : filterState.selectedActivityName ?? 'Activity',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.primary,
                      ),
                ),
            ],
          ),
          Row(
            children: [
              // View mode toggle
              IconButton(
                icon: Icon(_groupedByDay ? Icons.view_agenda : Icons.grid_view),
                onPressed: () => setState(() {
                  _groupedByDay = !_groupedByDay;
                  if (_groupedByDay) {
                    // Expand all days by default when switching to grouped view
                    _expandedDays = {};
                  }
                }),
                tooltip: _groupedByDay ? 'Grid View' : 'Group by Day',
              ),
              // Add photos button
              IconButton(
                icon: const Icon(Icons.add_a_photo),
                onPressed: _isUploading ? null : _pickAndUploadPhotos,
                tooltip: 'Add Photos',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, List<MemoryModel> allMemories) {
    // Get unique days and activities from memories
    final uniqueDays = allMemories
        .where((m) => m.dayNumber != null)
        .map((m) => m.dayNumber!)
        .toSet()
        .toList()
      ..sort();
    
    final uniqueActivities = <String, String>{};
    for (final m in allMemories) {
      if (m.activityId != null && m.activityName != null) {
        uniqueActivities[m.activityId!] = m.activityName!;
      }
    }

    if (uniqueDays.isEmpty && uniqueActivities.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filter by',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // All chip
                FilterChip(
                  label: const Text('All'),
                  selected: _filterState.filterType == MemoryFilterType.all,
                  onSelected: (_) => setState(() => _filterState = MemoryFilterState.all()),
                ),
                const SizedBox(width: 8),
                
                // Day chips
                ...uniqueDays.map((day) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: const Icon(Icons.calendar_today, size: 16),
                    label: Text('Day $day'),
                    selected: _filterState.filterType == MemoryFilterType.day && 
                              _filterState.selectedDay == day,
                    onSelected: (_) => setState(() => _filterState = MemoryFilterState.forDay(day)),
                  ),
                )),
                
                // Activity chips
                ...uniqueActivities.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: const Icon(Icons.event, size: 16),
                    label: Text(
                      entry.value.length > 15 
                          ? '${entry.value.substring(0, 15)}...' 
                          : entry.value,
                    ),
                    selected: _filterState.filterType == MemoryFilterType.activity && 
                              _filterState.selectedActivityId == entry.key,
                    onSelected: (_) => setState(() => _filterState = MemoryFilterState.forActivity(entry.key, entry.value)),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildUploadStatus() {
    return Padding(
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
    );
  }

  Widget _buildNoFilterResults(BuildContext context, MemoryFilterState filterState) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.filter_list_off,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            filterState.filterType == MemoryFilterType.day
                ? 'No memories for Day ${filterState.selectedDay}'
                : 'No memories for this activity',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {
              setState(() => _filterState = MemoryFilterState.all());
            },
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Memories Yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start capturing your trip moments!\nAdd photos to relive your adventures.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _pickAndUploadPhotos,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('Add First Memory'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenViewer(
    BuildContext context,
    List<MemoryModel> memories,
    int initialIndex,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenMemoryViewer(
          memories: memories,
          initialIndex: initialIndex,
          groupId: widget.groupId,
          tripId: widget.trip.id,
          trip: widget.trip,
        ),
      ),
    );
  }
}

/// Thumbnail widget for a memory in the grid
class _MemoryThumbnail extends StatelessWidget {
  final MemoryModel memory;
  final VoidCallback onTap;

  const _MemoryThumbnail({required this.memory, required this.onTap});

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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                memory.url,
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
            ),
          ),

          // Day badge
          if (memory.dayNumber != null)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'D${memory.dayNumber}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          // Video indicator
          if (memory.type == 'video')
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
class _FullScreenMemoryViewer extends ConsumerStatefulWidget {
  final List<MemoryModel> memories;
  final int initialIndex;
  final String groupId;
  final String tripId;
  final TripModel trip;

  const _FullScreenMemoryViewer({
    required this.memories,
    required this.initialIndex,
    required this.groupId,
    required this.tripId,
    required this.trip,
  });

  @override
  ConsumerState<_FullScreenMemoryViewer> createState() => _FullScreenMemoryViewerState();
}

class _FullScreenMemoryViewerState extends ConsumerState<_FullScreenMemoryViewer> {
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

  Future<void> _deleteMemory(MemoryModel memory) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Memory'),
        content: const Text('Are you sure you want to delete this memory?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final repository = ref.read(memoryRepositoryProvider);
      await repository.deleteMemory(
        groupId: widget.groupId,
        tripId: widget.tripId,
        memoryId: memory.id,
      );
      
      // Also delete from S3
      final token = await FirebaseAuth.instance.currentUser?.getIdToken();
      if (token != null) {
        await PhotoUploadService.deletePhoto(
          photoId: memory.id,
          tripId: widget.tripId,
          authToken: token,
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memory deleted')),
        );
      }
    }
  }

  Future<void> _editMemory(MemoryModel memory) async {
    final result = await showDialog<_EditMemoryResult>(
      context: context,
      builder: (context) => _EditMemoryDialog(
        memory: memory,
        trip: widget.trip,
        groupId: widget.groupId,
      ),
    );

    if (result != null) {
      final repository = ref.read(memoryRepositoryProvider);
      await repository.updateMemory(
        groupId: widget.groupId,
        tripId: widget.tripId,
        memoryId: memory.id,
        dayNumber: result.dayNumber,
        activityId: result.activityId,
        activityName: result.activityName,
        clearDayNumber: result.clearDayNumber,
        clearActivityId: result.clearActivityId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Memory updated')),
        );
      }
    }
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
            itemCount: widget.memories.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final memory = widget.memories[index];
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    memory.url,
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
                      // Close button
                      _buildIconButton(Icons.close, () => Navigator.pop(context)),

                      // Photo counter
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_currentIndex + 1} / ${widget.memories.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      // Action buttons
                      Row(
                        children: [
                          // Edit button
                          _buildIconButton(
                            Icons.edit_outlined, 
                            () => _editMemory(widget.memories[_currentIndex]),
                          ),
                          const SizedBox(width: 4),
                          // Delete button
                          _buildIconButton(
                            Icons.delete_outline, 
                            () => _deleteMemory(widget.memories[_currentIndex]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Bottom bar with memory info
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
                  child: _buildMemoryInfo(widget.memories[_currentIndex]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black45,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
      ),
    );
  }

  Widget _buildMemoryInfo(MemoryModel memory) {
    final chips = <Widget>[];
    
    if (memory.dayNumber != null) {
      chips.add(_buildInfoChip(Icons.calendar_today, 'Day ${memory.dayNumber}'));
    }
    
    if (memory.activityName != null) {
      chips.add(_buildInfoChip(Icons.event, memory.activityName!));
    }

    if (chips.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// Helper class for memory linking info
class _MemoryLinkInfo {
  final int? dayNumber;
  final String? activityId;
  final String? activityName;

  const _MemoryLinkInfo({
    this.dayNumber,
    this.activityId,
    this.activityName,
  });
}

/// Result from edit memory dialog
class _EditMemoryResult {
  final int? dayNumber;
  final String? activityId;
  final String? activityName;
  final bool clearDayNumber;
  final bool clearActivityId;

  const _EditMemoryResult({
    this.dayNumber,
    this.activityId,
    this.activityName,
    this.clearDayNumber = false,
    this.clearActivityId = false,
  });
}

/// Dialog for editing memory tags (day and activity)
class _EditMemoryDialog extends ConsumerStatefulWidget {
  final MemoryModel memory;
  final TripModel trip;
  final String groupId;

  const _EditMemoryDialog({
    required this.memory,
    required this.trip,
    required this.groupId,
  });

  @override
  ConsumerState<_EditMemoryDialog> createState() => _EditMemoryDialogState();
}

class _EditMemoryDialogState extends ConsumerState<_EditMemoryDialog> {
  int? _selectedDay;
  String? _selectedActivityId;
  String? _selectedActivityName;
  List<ActivityModel> _dayActivities = [];
  bool _isLoadingActivities = false;

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.memory.dayNumber;
    _selectedActivityId = widget.memory.activityId;
    _selectedActivityName = widget.memory.activityName;
    
    // Load activities if day is already selected
    if (_selectedDay != null) {
      _loadActivitiesForDay(_selectedDay!);
    }
  }

  Future<void> _loadActivitiesForDay(int dayNumber) async {
    setState(() => _isLoadingActivities = true);
    try {
      final activities = await ref.read(
        dayActivitiesProvider((
          groupId: widget.groupId,
          tripId: widget.trip.id,
          dayNumber: dayNumber,
        )).future,
      );
      if (mounted) {
        setState(() {
          _dayActivities = activities;
          _isLoadingActivities = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingActivities = false);
      }
    }
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Memory Tags'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tag this photo to a specific day or activity',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            
            // Day selector
            DropdownButtonFormField<int?>(
              value: _selectedDay,
              decoration: const InputDecoration(
                labelText: 'Day',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calendar_today),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('No specific day'),
                ),
                ...List.generate(
                  widget.trip.durationDays,
                  (index) {
                    final dayNum = index + 1;
                    final date = widget.trip.startDate.add(Duration(days: index));
                    return DropdownMenuItem<int?>(
                      value: dayNum,
                      child: Text('Day $dayNum - ${_formatDate(date)}'),
                    );
                  },
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedDay = value;
                  _selectedActivityId = null;
                  _selectedActivityName = null;
                  _dayActivities = [];
                });
                
                if (value != null) {
                  _loadActivitiesForDay(value);
                }
              },
            ),
            
            // Activity selector (only show if day is selected)
            if (_selectedDay != null) ...[
              const SizedBox(height: 16),
              if (_isLoadingActivities)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_dayActivities.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, 
                        size: 18, 
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No activities on this day yet',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                DropdownButtonFormField<String?>(
                  value: _selectedActivityId,
                  decoration: const InputDecoration(
                    labelText: 'Activity',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.event),
                  ),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('No specific activity'),
                    ),
                    ..._dayActivities.map((activity) {
                      final iconCode = ActivityCategory.icons[activity.category] ?? 0xe8b8;
                      return DropdownMenuItem<String?>(
                        value: activity.id,
                        child: Row(
                          children: [
                            Icon(
                              IconData(iconCode, fontFamily: 'MaterialIcons'),
                              size: 18,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                activity.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    final activity = value != null 
                        ? _dayActivities.firstWhere((a) => a.id == value)
                        : null;
                    setState(() {
                      _selectedActivityId = value;
                      _selectedActivityName = activity?.name;
                    });
                  },
                ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(_EditMemoryResult(
              dayNumber: _selectedDay,
              activityId: _selectedActivityId,
              activityName: _selectedActivityName,
              clearDayNumber: widget.memory.dayNumber != null && _selectedDay == null,
              clearActivityId: widget.memory.activityId != null && _selectedActivityId == null,
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
