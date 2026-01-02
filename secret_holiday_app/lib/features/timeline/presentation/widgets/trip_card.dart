import 'package:flutter/material.dart';
import 'package:secret_holiday_app/core/theme/app_colors.dart';
import '../../data/models/trip_model.dart';

/// Modern trip card widget for displaying trip information
class TripCard extends StatelessWidget {
  final TripModel trip;
  final VoidCallback? onTap;
  final bool isPast;

  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = trip.durationDays;
    final hasCoverPhoto = trip.coverPhotoUrl != null && trip.coverPhotoUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover photo or gradient header
              if (hasCoverPhoto)
                _buildCoverPhoto()
              else
                _buildGradientHeader(theme),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Trip name and destination
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                trip.tripName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_outlined,
                                    size: 14,
                                    color: AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${trip.location.destination}, ${trip.location.country}',
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
                          ),
                        ),
                        // Status badge
                        _buildStatusBadge(),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Date and details row
                    Row(
                      children: [
                        _buildInfoPill(
                          Icons.calendar_today_outlined,
                          '${_formatShortDate(trip.startDate)} - ${_formatShortDate(trip.endDate)}',
                        ),
                        const SizedBox(width: 8),
                        _buildInfoPill(
                          Icons.schedule,
                          '$days ${days == 1 ? 'day' : 'days'}',
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Footer with budget and participants
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Budget
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.currency_pound,
                                size: 14,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${trip.costPerPerson} pp',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        
                        // Participants
                        if (trip.participantIds.isNotEmpty)
                          Row(
                            children: [
                              // Show avatars stack
                              SizedBox(
                                width: 52,
                                height: 24,
                                child: Stack(
                                  children: [
                                    for (int i = 0; i < trip.participantIds.length.clamp(0, 3); i++)
                                      Positioned(
                                        left: i * 14.0,
                                        child: Container(
                                          width: 24,
                                          height: 24,
                                          decoration: BoxDecoration(
                                            color: [
                                              AppColors.primary,
                                              AppColors.accent,
                                              Colors.purple,
                                            ][i % 3],
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: theme.colorScheme.surface,
                                              width: 2,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${i + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverPhoto() {
    return Stack(
      children: [
        Container(
          height: 140,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(trip.coverPhotoUrl!),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Gradient overlay
        Container(
          height: 140,
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
      ],
    );
  }

  Widget _buildGradientHeader(ThemeData theme) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStatusColor(trip.currentStatus),
            _getStatusColor(trip.currentStatus).withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Pattern
          Positioned(
            right: -20,
            top: -20,
            child: Icon(
              Icons.flight_takeoff,
              size: 100,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          // Country flag placeholder
          Positioned(
            left: 16,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flag, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    trip.location.country,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(trip.currentStatus).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getStatusIcon(trip.currentStatus),
            size: 14,
            color: _getStatusColor(trip.currentStatus),
          ),
          const SizedBox(width: 4),
          Text(
            _getStatusLabel(trip.currentStatus),
            style: TextStyle(
              fontSize: 12,
              color: _getStatusColor(trip.currentStatus),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.textSecondary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textSecondary),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  Color _getStatusColor(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return AppColors.primary;
      case TripStatus.ongoing:
        return AppColors.accent;
      case TripStatus.completed:
        return AppColors.textSecondary;
      case TripStatus.cancelled:
        return AppColors.error;
    }
  }

  IconData _getStatusIcon(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return Icons.edit_calendar;
      case TripStatus.ongoing:
        return Icons.flight_takeoff;
      case TripStatus.completed:
        return Icons.check_circle_outline;
      case TripStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }

  String _getStatusLabel(TripStatus status) {
    switch (status) {
      case TripStatus.planning:
        return 'Planning';
      case TripStatus.ongoing:
        return 'Active';
      case TripStatus.completed:
        return 'Complete';
      case TripStatus.cancelled:
        return 'Cancelled';
    }
  }
}
