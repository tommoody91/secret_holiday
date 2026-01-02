import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/models/suggestion_model.dart';

/// Screen showing destination suggestions as beautiful cards
class SuggestionResultsScreen extends ConsumerWidget {
  final SuggestionResponse response;
  final String groupId;

  const SuggestionResultsScreen({
    super.key,
    required this.response,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Destinations Found'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Add filter options
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search summary
          _buildSearchSummary(theme),
          
          // Results
          Expanded(
            child: response.destinations.isEmpty
                ? _buildEmptyState(theme)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: response.destinations.length,
                    itemBuilder: (context, index) {
                      final destination = response.destinations[index];
                      return _DestinationCard(
                        destination: destination,
                        rank: index + 1,
                        onTap: () => _showDestinationDetails(context, destination),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSummary(ThemeData theme) {
    final criteria = response.searchCriteria;
    final origins = response.originsUsed.map((o) => o.iataCode).join(', ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.success, size: 20),
              const SizedBox(width: 8),
              Text(
                'Found ${response.totalFound} destinations under £${criteria['budget_per_person']}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Searching from: $origins',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flight_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No destinations found',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try increasing your budget or selecting different dates',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showDestinationDetails(BuildContext context, DestinationSuggestion destination) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _DestinationDetailsSheet(
        destination: destination,
        groupId: groupId,
      ),
    );
  }
}

/// A beautiful card for displaying a destination suggestion
class _DestinationCard extends StatelessWidget {
  final DestinationSuggestion destination;
  final int rank;
  final VoidCallback onTap;

  const _DestinationCard({
    required this.destination,
    required this.rank,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Get a gradient color based on value
    Color priceColor;
    if (destination.reasons.any((r) => r.contains('Great value'))) {
      priceColor = AppColors.success;
    } else if (destination.reasons.any((r) => r.contains('Good value'))) {
      priceColor = AppColors.primary;
    } else {
      priceColor = AppColors.textSecondary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder / gradient header
            Container(
              height: 120,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getCountryColor(destination.countryCode),
                    _getCountryColor(destination.countryCode).withValues(alpha: 0.7),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  // Rank badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '#$rank',
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  // Price badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: priceColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '£${destination.pricePerPerson.toStringAsFixed(0)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  // Destination name overlay
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          destination.displayName,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              Shadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        if (destination.country != null)
                          Text(
                            destination.country!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Details section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Flight info
                  Row(
                    children: [
                      Icon(Icons.flight_takeoff, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'From ${destination.bestOrigin}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      if (destination.totalPrice != null)
                        Text(
                          'Total: £${destination.totalPrice!.toStringAsFixed(0)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  if (destination.departureDate != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          _formatDateRange(destination.departureDate, destination.returnDate),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (destination.reasons.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: destination.reasons.map((reason) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            reason,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateRange(String? departure, String? returnDate) {
    if (departure == null) return '';
    if (returnDate == null) return departure;
    return '$departure → $returnDate';
  }

  Color _getCountryColor(String? countryCode) {
    // Return a color based on country for visual variety
    switch (countryCode?.toUpperCase()) {
      case 'ES':
        return const Color(0xFFE74C3C); // Spain - red/orange
      case 'FR':
        return const Color(0xFF3498DB); // France - blue
      case 'IT':
        return const Color(0xFF27AE60); // Italy - green
      case 'DE':
        return const Color(0xFF2C3E50); // Germany - dark
      case 'PT':
        return const Color(0xFF16A085); // Portugal - teal
      case 'GR':
        return const Color(0xFF2980B9); // Greece - blue
      case 'HR':
        return const Color(0xFFE67E22); // Croatia - orange
      case 'NL':
        return const Color(0xFFF39C12); // Netherlands - orange
      case 'CZ':
        return const Color(0xFF8E44AD); // Czech - purple
      case 'PL':
        return const Color(0xFFE74C3C); // Poland - red
      case 'HU':
        return const Color(0xFF27AE60); // Hungary - green
      case 'AT':
        return const Color(0xFFE74C3C); // Austria - red
      case 'TR':
        return const Color(0xFFC0392B); // Turkey - dark red
      case 'MA':
        return const Color(0xFFD35400); // Morocco - rust
      default:
        return AppColors.primary;
    }
  }
}

/// Bottom sheet showing destination details
class _DestinationDetailsSheet extends StatelessWidget {
  final DestinationSuggestion destination;
  final String groupId;

  const _DestinationDetailsSheet({
    required this.destination,
    required this.groupId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                destination.displayName,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (destination.country != null)
                                Text(
                                  destination.country!,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                '£${destination.pricePerPerson.toStringAsFixed(0)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'per person',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Flight details
                    _buildDetailRow(
                      context,
                      Icons.flight_takeoff,
                      'Flying from',
                      destination.bestOrigin,
                    ),
                    if (destination.departureDate != null)
                      _buildDetailRow(
                        context,
                        Icons.calendar_today,
                        'Travel dates',
                        '${destination.departureDate} → ${destination.returnDate ?? 'TBD'}',
                      ),
                    if (destination.totalPrice != null)
                      _buildDetailRow(
                        context,
                        Icons.group,
                        'Total for group',
                        '£${destination.totalPrice!.toStringAsFixed(0)}',
                      ),
                    
                    const SizedBox(height: 24),
                    
                    // Reasons
                    if (destination.reasons.isNotEmpty) ...[
                      Text(
                        'Why we recommend this',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...destination.reasons.map((reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 20,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 12),
                            Text(reason),
                          ],
                        ),
                      )),
                    ],
                    
                    const SizedBox(height: 32),
                    
                    // Actions
                    FilledButton.icon(
                      onPressed: () {
                        // TODO: Save as planned destination
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Coming soon: Save destinations for your group!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.bookmark_add),
                      label: const Text('Save Destination'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Keep Browsing'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
