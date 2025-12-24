import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/trip_model.dart';

/// Itinerary tab showing day-by-day planning and activities
class ItineraryTab extends StatelessWidget {
  final String groupId;
  final TripModel trip;

  const ItineraryTab({super.key, required this.groupId, required this.trip});

  @override
  Widget build(BuildContext context) {
    final days = _generateDays();

    if (days.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final itineraryDay = trip.itinerary.firstWhere(
          (d) => d.dayNumber == day['dayNumber'],
          orElse: () => ItineraryDay(
            dayNumber: day['dayNumber'] as int,
            description: '',
            activities: [],
          ),
        );

        return _DayCard(
          dayNumber: day['dayNumber'] as int,
          date: day['date'] as DateTime,
          itineraryDay: itineraryDay,
          isToday: day['isToday'] as bool,
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

class _DayCard extends StatelessWidget {
  final int dayNumber;
  final DateTime date;
  final ItineraryDay itineraryDay;
  final bool isToday;

  const _DayCard({
    required this.dayNumber,
    required this.date,
    required this.itineraryDay,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isToday
            ? const BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: ExpansionTile(
        initiallyExpanded: isToday,
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.primary
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '$dayNumber',
              style: theme.textTheme.titleLarge?.copyWith(
                color: isToday ? Colors.white : AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Row(
          children: [
            Text(
              'Day $dayNumber',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (isToday) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
        subtitle: Text(
          DateFormat('EEEE, MMMM d').format(date),
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (itineraryDay.description.isNotEmpty) ...[
                  Text(
                    itineraryDay.description,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                ],
                if (itineraryDay.activities.isNotEmpty) ...[
                  Text(
                    'Activities',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...itineraryDay.activities.map(
                    (activity) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(child: Text(activity)),
                        ],
                      ),
                    ),
                  ),
                ] else
                  Center(
                    child: Text(
                      'No activities planned yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
