import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/trip_model.dart';
import '../../data/models/activity_model.dart';
import '../../providers/activity_provider.dart';

/// Itinerary tab showing day-by-day planning and activities
class ItineraryTab extends ConsumerWidget {
  final String groupId;
  final TripModel trip;

  const ItineraryTab({super.key, required this.groupId, required this.trip});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final days = _generateDays();

    if (days.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        return _DayCard(
          groupId: groupId,
          tripId: trip.id,
          dayNumber: day['dayNumber'] as int,
          date: day['date'] as DateTime,
          isToday: day['isToday'] as bool,
          destination: trip.location.destination,
        );
      },
    );
  }

  List<Map<String, dynamic>> _generateDays() {
    final days = <Map<String, dynamic>>[];
    final now = DateTime.now();
    var currentDate = trip.startDate;
    var dayNumber = 1;

    while (!currentDate.isAfter(trip.endDate)) {
      final isToday =
          currentDate.year == now.year &&
          currentDate.month == now.month &&
          currentDate.day == now.day;

      days.add({
        'dayNumber': dayNumber,
        'date': currentDate,
        'isToday': isToday,
      });

      currentDate = currentDate.add(const Duration(days: 1));
      dayNumber++;
    }

    return days;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Itinerary Yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Trip dates will appear here once the trip starts.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends ConsumerStatefulWidget {
  final String groupId;
  final String tripId;
  final int dayNumber;
  final DateTime date;
  final bool isToday;
  final String destination;

  const _DayCard({
    required this.groupId,
    required this.tripId,
    required this.dayNumber,
    required this.date,
    required this.isToday,
    required this.destination,
  });

  @override
  ConsumerState<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends ConsumerState<_DayCard> {
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.isToday;
  }

  void _navigateToAddActivity() {
    context.push(
      '/trip/${widget.tripId}/add-activity',
      extra: {
        'groupId': widget.groupId,
        'tripId': widget.tripId,
        'dayNumber': widget.dayNumber,
        'date': widget.date,
        'destination': widget.destination,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activitiesAsync = ref.watch(
      dayActivitiesProvider((groupId: widget.groupId, tripId: widget.tripId, dayNumber: widget.dayNumber)),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: widget.isToday
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: Column(
        children: [
          // Day Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Day Number Badge
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: widget.isToday
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${widget.dayNumber}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: widget.isToday ? Colors.white : AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Day Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Day ${widget.dayNumber}',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.isToday) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'TODAY',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          DateFormat('EEEE, MMMM d').format(widget.date),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Activity count badge
                  activitiesAsync.when(
                    data: (activities) => activities.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${activities.length}',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  const SizedBox(width: 8),
                  
                  // Expand/collapse icon
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
          
          // Expanded Content
          if (_isExpanded) ...[
            const Divider(height: 1),
            _buildActivitiesSection(activitiesAsync, theme),
          ],
        ],
      ),
    );
  }

  Widget _buildActivitiesSection(
    AsyncValue<List<ActivityModel>> activitiesAsync,
    ThemeData theme,
  ) {
    return activitiesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: LoadingIndicator()),
      ),
      error: (error, _) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 32,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load activities',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _navigateToAddActivity,
              icon: const Icon(Icons.add),
              label: const Text('Add Activity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
      data: (activities) {
        if (activities.isEmpty) {
          return _buildEmptyActivities(theme);
        }
        return _buildActivityList(activities, theme);
      },
    );
  }

  Widget _buildEmptyActivities(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.event_note_outlined,
            size: 48,
            color: AppColors.textSecondary.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No activities planned',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _navigateToAddActivity,
            icon: const Icon(Icons.add),
            label: const Text('Add Activity'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityList(List<ActivityModel> activities, ThemeData theme) {
    return Column(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: activities.length,
          itemBuilder: (context, index) {
            final activity = activities[index];
            return ReorderableDragStartListener(
              key: ValueKey(activity.id),
              index: index,
              child: _ActivityTile(
                activity: activity,
                groupId: widget.groupId,
                tripId: widget.tripId,
                dayNumber: widget.dayNumber,
                destination: widget.destination,
              ),
            );
          },
          onReorder: (oldIndex, newIndex) {
            if (newIndex > oldIndex) newIndex--;
            final activityIds = activities.map((a) => a.id).toList();
            final movedId = activityIds.removeAt(oldIndex);
            activityIds.insert(newIndex, movedId);
            
            ref.read(activityServiceProvider).reorderActivities(
              groupId: widget.groupId,
              tripId: widget.tripId,
              dayNumber: widget.dayNumber,
              activityIds: activityIds,
            );
          },
        ),
        
        // Add activity button
        Padding(
          padding: const EdgeInsets.all(16),
          child: OutlinedButton.icon(
            onPressed: _navigateToAddActivity,
            icon: const Icon(Icons.add),
            label: const Text('Add Activity'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 44),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends ConsumerWidget {
  final ActivityModel activity;
  final String groupId;
  final String tripId;
  final int dayNumber;
  final String destination;

  const _ActivityTile({
    required this.activity,
    required this.groupId,
    required this.tripId,
    required this.dayNumber,
    required this.destination,
  });

  void _showEditDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditActivitySheet(
        activity: activity,
        groupId: groupId,
        tripId: tripId,
        dayNumber: dayNumber,
        destination: destination,
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: Text('Are you sure you want to delete "${activity.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(activityServiceProvider).deleteActivity(
                  groupId: groupId,
                  tripId: tripId,
                  activityId: activity.id,
                );
                if (context.mounted) {
                  AppSnackBar.show(
                    context: context,
                    message: 'Activity deleted',
                    type: SnackBarType.success,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  AppSnackBar.show(
                    context: context,
                    message: 'Failed to delete activity',
                    type: SnackBarType.error,
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: activity.isCompleted
            ? AppColors.success.withValues(alpha: 0.05)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: activity.isCompleted
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Icon(
              Icons.drag_indicator,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 8),
            // Category icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                IconData(
                  ActivityCategory.icons[activity.category] ?? 0xe8b8,
                  fontFamily: 'MaterialIcons',
                ),
                size: 20,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        title: Text(
          activity.name,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            decoration: activity.isCompleted
                ? TextDecoration.lineThrough
                : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (activity.timeRange != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activity.timeRange!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            if (activity.formattedCost != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.payments_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    activity.formattedCost!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
            if (activity.location != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      activity.location!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Checkbox
            Checkbox(
              value: activity.isCompleted,
              activeColor: AppColors.success,
              onChanged: (value) {
                ref.read(activityServiceProvider).toggleCompleted(
                  groupId: groupId,
                  tripId: tripId,
                  activityId: activity.id,
                  isCompleted: value ?? false,
                );
              },
            ),
            // More options menu
            PopupMenuButton<String>(
              icon: Icon(
                Icons.more_vert,
                color: AppColors.textSecondary,
              ),
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditDialog(context, ref);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(context, ref);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit_outlined, size: 20),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_outline, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => _showEditDialog(context, ref),
      ),
    );
  }
}

/// Edit Activity Bottom Sheet
class _EditActivitySheet extends ConsumerStatefulWidget {
  final ActivityModel activity;
  final String groupId;
  final String tripId;
  final int dayNumber;
  final String destination;

  const _EditActivitySheet({
    required this.activity,
    required this.groupId,
    required this.tripId,
    required this.dayNumber,
    required this.destination,
  });

  @override
  ConsumerState<_EditActivitySheet> createState() => _EditActivitySheetState();
}

class _EditActivitySheetState extends ConsumerState<_EditActivitySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late TextEditingController _costController;
  String? _selectedCategory;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.activity.name);
    _locationController = TextEditingController(text: widget.activity.location ?? '');
    _notesController = TextEditingController(text: widget.activity.notes ?? '');
    _costController = TextEditingController(
      text: widget.activity.estimatedCost?.toStringAsFixed(2) ?? '',
    );
    _selectedCategory = widget.activity.category;
    _startTime = _parseTime(widget.activity.startTime);
    _endTime = _parseTime(widget.activity.endTime);
  }

  TimeOfDay? _parseTime(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length != 2) return null;
    return TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts[1]) ?? 0,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    _costController.dispose();
    super.dispose();
  }

  Future<void> _selectStartTime() async {
    final time = await _showScrollableTimePicker(_startTime ?? TimeOfDay.now());
    if (time != null) {
      setState(() => _startTime = time);
    }
  }

  Future<void> _selectEndTime() async {
    final time = await _showScrollableTimePicker(_endTime ?? _startTime ?? TimeOfDay.now());
    if (time != null) {
      setState(() => _endTime = time);
    }
  }

  Future<TimeOfDay?> _showScrollableTimePicker(TimeOfDay initialTime) async {
    int selectedHour = initialTime.hour;
    int selectedMinute = initialTime.minute;
    
    return showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                        Text(
                          'Select Time',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(
                            context,
                            TimeOfDay(hour: selectedHour, minute: selectedMinute),
                          ),
                          child: Text(
                            'Done',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 200,
                    child: Row(
                      children: [
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: selectedHour,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setModalState(() => selectedHour = index);
                            },
                            children: List.generate(24, (index) {
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: const TextStyle(fontSize: 22),
                                ),
                              );
                            }),
                          ),
                        ),
                        const Text(
                          ':',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Expanded(
                          child: CupertinoPicker(
                            scrollController: FixedExtentScrollController(
                              initialItem: selectedMinute,
                            ),
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              setModalState(() => selectedMinute = index);
                            },
                            children: List.generate(60, (index) {
                              return Center(
                                child: Text(
                                  index.toString().padLeft(2, '0'),
                                  style: const TextStyle(fontSize: 22),
                                ),
                              );
                            }),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Set time';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    try {
      final updatedActivity = widget.activity.copyWith(
        name: _nameController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        category: _selectedCategory,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        estimatedCost: _costController.text.isEmpty
            ? null
            : double.tryParse(_costController.text),
        startTime: _startTime != null
            ? '${_startTime!.hour.toString().padLeft(2, '0')}:${_startTime!.minute.toString().padLeft(2, '0')}'
            : null,
        endTime: _endTime != null
            ? '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}'
            : null,
        updatedAt: DateTime.now(),
      );

      await ref.read(activityServiceProvider).updateActivity(
        groupId: widget.groupId,
        tripId: widget.tripId,
        activity: updatedActivity,
      );

      if (mounted) {
        Navigator.pop(context);
        AppSnackBar.show(
          context: context,
          message: 'Activity updated!',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Failed to update activity',
          type: SnackBarType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                Text(
                  'Edit Activity',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Name field
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Activity Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (v) =>
                      v?.trim().isEmpty ?? true ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Category
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: ActivityCategory.all.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            IconData(
                              ActivityCategory.icons[category] ?? 0xe8b8,
                              fontFamily: 'MaterialIcons',
                            ),
                            size: 20,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(ActivityCategory.labels[category] ?? category),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v),
                ),
                const SizedBox(height: 16),

                // Location
                TextFormField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    labelText: 'Location',
                    hintText: 'Address or place name',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time selection
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeSelector(
                        label: 'Start',
                        time: _startTime,
                        onTap: _selectStartTime,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTimeSelector(
                        label: 'End',
                        time: _endTime,
                        onTap: _selectEndTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Cost
                TextFormField(
                  controller: _costController,
                  decoration: InputDecoration(
                    labelText: 'Estimated Cost',
                    hintText: '0.00',
                    prefixText: '£ ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16),

                // Notes
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Any additional details...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required TimeOfDay? time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.access_time,
              size: 20,
              color: time != null ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    _formatTime(time),
                    style: TextStyle(
                      fontWeight: time != null ? FontWeight.w500 : FontWeight.normal,
                      color: time != null
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
