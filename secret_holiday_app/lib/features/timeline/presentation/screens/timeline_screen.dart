import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_holiday_app/core/theme/app_colors.dart';
import 'package:secret_holiday_app/features/groups/providers/group_provider.dart';
import '../../data/models/trip_model.dart';
import '../../providers/trip_provider.dart';
import '../widgets/trip_card.dart';

class TimelineScreen extends ConsumerWidget {
  const TimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedGroupAsync = ref.watch(selectedGroupDataProvider);

    return selectedGroupAsync.when(
      data: (group) {
        if (group == null) {
          return _buildNoGroupState(context);
        }

        // Watch trips for the selected group
        final tripsAsync = ref.watch(groupTripsProvider(group.id));
        
        return tripsAsync.when(
          data: (trips) {
            if (trips.isEmpty) {
              return _buildEmptyState(context, group.name, group.id);
            }
            return _buildTripsView(context, ref, group.name, group.id, trips);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Error loading trips: $error'),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
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
              'Error loading timeline',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.error,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoGroupState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add,
              size: 100,
              color: AppColors.textSecondary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Group Selected',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Create or join a group to start planning your secret holiday!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/create-group');
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Group'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripsView(BuildContext context, WidgetRef ref, String groupName, 
      String groupId, List<TripModel> trips) {
    // Separate trips into upcoming and past
    final now = DateTime.now();
    final upcomingTrips = trips.where((trip) => trip.startDate.isAfter(now)).toList();
    final pastTrips = trips.where((trip) => trip.endDate.isBefore(now)).toList();
    final ongoingTrips = trips.where((trip) => 
      trip.startDate.isBefore(now) && trip.endDate.isAfter(now)
    ).toList();
    
    return Stack(
      children: [
        RefreshIndicator(
      onRefresh: () async {
        // Refresh is automatic with Riverpod streams
        await Future.delayed(const Duration(milliseconds: 500));
      },
      child: CustomScrollView(
        slivers: [
          // Group Header
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.group, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          groupName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${trips.length} ${trips.length == 1 ? 'trip' : 'trips'}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Ongoing Trips Section
          if (ongoingTrips.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Happening Now',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final trip = ongoingTrips[index];
                  return TripCard(
                    trip: trip,
                    onTap: () {
                      context.push('/trip/${trip.id}', extra: {'groupId': groupId});
                    },
                  );
                },
                childCount: ongoingTrips.length,
              ),
            ),
          ],

          // Upcoming Trips Section
          if (upcomingTrips.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Upcoming Trips',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final trip = upcomingTrips[index];
                  return TripCard(
                    trip: trip,
                    onTap: () {
                      context.push('/trip/${trip.id}', extra: {'groupId': groupId});
                    },
                  );
                },
                childCount: upcomingTrips.length,
              ),
            ),
          ],

          // Past Trips Section
          if (pastTrips.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                child: Text(
                  'Past Trips',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final trip = pastTrips[index];
                  return TripCard(
                    trip: trip,
                    isPast: true,
                    onTap: () {
                      context.push('/trip/${trip.id}', extra: {'groupId': groupId});
                    },
                  );
                },
                childCount: pastTrips.length,
              ),
            ),
          ],

          // Add bottom padding for FAB
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
        ),
        // FAB positioned at bottom right
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            onPressed: () {
              context.push('/add-trip?groupId=$groupId');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Trip'),
            backgroundColor: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, String groupName, String groupId) {
    return CustomScrollView(
      slivers: [
        // Group Header
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.group,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        groupName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'No trips planned yet',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Empty State
        SliverFillRemaining(
          hasScrollBody: false,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.flight_takeoff,
                    size: 100,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No Trips Yet',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Start planning your next secret holiday adventure!',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      context.push('/add-trip?groupId=$groupId');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add Trip'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
