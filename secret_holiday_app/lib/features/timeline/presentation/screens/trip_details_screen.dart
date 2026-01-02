import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../../groups/providers/group_provider.dart';
import '../../data/models/trip_model.dart';
import '../../providers/trip_provider.dart';
import '../widgets/itinerary_tab.dart';
import '../widgets/memories_tab.dart';

class TripDetailsScreen extends ConsumerStatefulWidget {
  final String groupId;
  final String tripId;

  const TripDetailsScreen({
    super.key,
    required this.groupId,
    required this.tripId,
  });

  @override
  ConsumerState<TripDetailsScreen> createState() => _TripDetailsScreenState();
}

class _TripDetailsScreenState extends ConsumerState<TripDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatDateRange(DateTime start, DateTime end) {
    if (start.year == end.year && start.month == end.month) {
      return '${DateFormat('MMM d').format(start)} - ${DateFormat('d, yyyy').format(end)}';
    }
    return '${_formatDate(start)} - ${_formatDate(end)}';
  }

  List<Widget> _buildAppBarActions(BuildContext context, TripModel trip) {
    final currentUserAsync = ref.watch(currentUserProvider);
    final groupAsync = ref.watch(selectedGroupDataProvider);

    return currentUserAsync.maybeWhen(
      data: (user) {
        if (user == null) return [];

        final canEdit = groupAsync.maybeWhen(
          data: (group) {
            if (group == null) return false;
            // Check if user is organizer or admin
            if (trip.organizerId == user.uid) return true;
            final member = group.members.firstWhere(
              (m) => m.userId == user.uid,
              orElse: () => throw Exception('User not found'),
            );
            return member.role == 'admin';
          },
          orElse: () => false,
        );

        if (!canEdit) return [];

        return [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _handleEdit(trip),
            tooltip: 'Edit Trip',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _handleDelete(context, trip),
            tooltip: 'Delete Trip',
          ),
        ];
      },
      orElse: () => [],
    );
  }

  void _handleEdit(TripModel trip) {
    context.push('/edit-trip', extra: {
      'groupId': widget.groupId,
      'trip': trip,
    });
  }

  Future<void> _handleDelete(BuildContext context, TripModel trip) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip'),
        content: Text(
          'Are you sure you want to delete "${trip.tripName}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final notifier = ref.read(tripProvider.notifier);
      await notifier.deleteTrip(
        groupId: widget.groupId,
        tripId: widget.tripId,
      );

      if (!mounted) return;

      AppSnackBar.show(
        context: context,
        message: 'Trip deleted successfully',
        type: SnackBarType.success,
      );

      context.pop(); // Go back to timeline
    } catch (e) {
      if (!mounted) return;

      AppSnackBar.show(
        context: context,
        message: 'Failed to delete trip: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tripAsync = ref.watch(
      tripDetailsProvider(widget.groupId, widget.tripId),
    );

    return Scaffold(
      body: tripAsync.when(
        data: (trip) => _buildContent(context, trip),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Error loading trip',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.error,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              SecondaryButton(
                text: 'Go Back',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, TripModel trip) {
    final now = DateTime.now();
    final isPast = trip.endDate.isBefore(now);
    final isUpcoming = trip.startDate.isAfter(now);

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          actions: _buildAppBarActions(context, trip),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              trip.location.destination,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    isPast
                        ? AppColors.textSecondary
                        : isUpcoming
                            ? AppColors.primary
                            : AppColors.accent,
                    isPast
                        ? AppColors.textSecondary.withValues(alpha: 0.7)
                        : isUpcoming
                            ? AppColors.primary.withValues(alpha: 0.7)
                            : AppColors.accent.withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: trip.coverPhotoUrl != null
                  ? Image.network(
                      trip.coverPhotoUrl!,
                      fit: BoxFit.cover,
                    )
                  : Center(
                      child: Icon(
                        isPast
                            ? Icons.check_circle_outline
                            : Icons.flight_takeoff,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                    ),
            ),
          ),
        ),

        // Tab Bar
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickyTabBarDelegate(
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Itinerary'),
                Tab(text: 'Memories'),
                Tab(text: 'Expenses'),
              ],
            ),
          ),
        ),

        // Tab Content
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, trip),
              _buildItineraryTab(context, trip),
              _buildMemoriesTab(context, trip),
              _buildExpensesTab(context, trip),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewTab(BuildContext context, TripModel trip) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Modern unified trip card (Instagram/Airbnb style)
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip Info Section (no duplicate cover photo - it's already in the SliverAppBar)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Badge Row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(trip.currentStatus)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _getStatusColor(trip.currentStatus)
                                  .withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(trip.currentStatus),
                                color: _getStatusColor(trip.currentStatus),
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getStatusLabel(trip.currentStatus),
                                style: TextStyle(
                                  color: _getStatusColor(trip.currentStatus),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        if (trip.participantIds.isNotEmpty)
                          Row(
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${trip.participantIds.length} going',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Trip Name
                    Text(
                      trip.tripName,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Quick Info Grid
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.location_on_outlined,
                          trip.location.destination,
                        ),
                        const SizedBox(width: 16),
                        _buildInfoChip(
                          Icons.calendar_today_outlined,
                          '${trip.durationDays} days',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildInfoChip(
                          Icons.currency_pound,
                          '${trip.costPerPerson} pp',
                        ),
                        const SizedBox(width: 16),
                        _buildInfoChip(
                          Icons.flag_outlined,
                          trip.location.country,
                        ),
                      ],
                    ),
                    
                    // Divider
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Divider(
                        color: AppColors.textSecondary.withValues(alpha: 0.2),
                      ),
                    ),
                    
                    // Date Range
                    _buildDetailRow(
                      Icons.date_range,
                      'Dates',
                      _formatDateRange(trip.startDate, trip.endDate),
                      theme,
                    ),
                    const SizedBox(height: 16),
                    
                    // Organizer
                    _buildDetailRow(
                      Icons.person_outline,
                      'Organised by',
                      trip.organizerName,
                      theme,
                      trailing: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: Text(
                          trip.organizerName.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    
                    // Description
                    if (trip.summary.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        'About this trip',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        trip.summary,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 80), // Bottom padding for FAB
      ],
    );
  }

  Widget _buildItineraryTab(BuildContext context, TripModel trip) {
    return ItineraryTab(
      groupId: widget.groupId,
      trip: trip,
    );
  }

  Widget _buildMemoriesTab(BuildContext context, TripModel trip) {
    return MemoriesTab(
      groupId: widget.groupId,
      trip: trip,
    );
  }

  Widget _buildExpensesTab(BuildContext context, TripModel trip) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'Expenses Coming Soon',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Expense tracking feature will be available in Sprint 10',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  // Cover section for overview card
  Widget _buildCoverSection(TripModel trip, ThemeData theme) {
    // Show cover photo if available
    if (trip.coverPhotoUrl != null && trip.coverPhotoUrl!.isNotEmpty) {
      return Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(trip.coverPhotoUrl!),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withValues(alpha: 0.3),
              ],
            ),
          ),
        ),
      );
    }
    
    // Default gradient header with destination icon
    return Container(
      height: 120,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.8),
            AppColors.primary.withValues(alpha: 0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Pattern overlay
          Positioned.fill(
            child: CustomPaint(
              painter: _PatternPainter(),
            ),
          ),
          // Center icon
          Center(
            child: Icon(
              Icons.flight_takeoff,
              size: 48,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }

  // Info chip widget for quick stats
  Widget _buildInfoChip(IconData icon, String text) {
    return Expanded(
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // Detail row widget for full-width info
  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value,
    ThemeData theme, {
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return Colors.blue;
      case TripStatus.ongoing:
        return Colors.green;
      case TripStatus.completed:
        return Colors.grey;
      case TripStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return Icons.schedule;
      case TripStatus.ongoing:
        return Icons.flight_takeoff;
      case TripStatus.completed:
        return Icons.check_circle;
      case TripStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _getStatusLabel(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return 'Planning';
      case TripStatus.ongoing:
        return 'Ongoing';
      case TripStatus.completed:
        return 'Completed';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }
}

// Sticky TabBar Delegate
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _StickyTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_StickyTabBarDelegate oldDelegate) {
    return false;
  }
}

// Pattern painter for cover gradient
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    // Draw subtle diagonal pattern
    const spacing = 30.0;
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      final path = Path()
        ..moveTo(i, 0)
        ..lineTo(i + size.height, size.height)
        ..lineTo(i + size.height + 2, size.height)
        ..lineTo(i + 2, 0)
        ..close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
