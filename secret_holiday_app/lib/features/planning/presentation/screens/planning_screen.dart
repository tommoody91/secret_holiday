import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../groups/data/models/group_model.dart';
import '../../../groups/providers/group_provider.dart';
import 'suggestion_wizard_screen.dart';

/// AI Planning screen - helps users find destinations within budget
class PlanningScreen extends ConsumerWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userGroupsAsync = ref.watch(userGroupsProvider);
    final selectedGroupId = ref.watch(selectedGroupProvider);

    return Scaffold(
      body: SafeArea(
        child: userGroupsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text('Error loading groups: $e'),
          ),
          data: (groups) {
            if (groups.isEmpty) {
              return _buildNoGroupsState(theme);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          Icons.auto_awesome,
                          size: 32,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Trip Finder',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Find destinations within your budget',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Group selection
                  Text(
                    'Select a group to plan for',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  ...groups.map((group) => _GroupCard(
                    group: group,
                    isSelected: group.id == selectedGroupId,
                    onTap: () => ref.read(selectedGroupProvider.notifier)
                        .selectGroup(group.id),
                    onStartPlanning: () => _startPlanning(context, group),
                  )),
                  
                  const SizedBox(height: 32),
                  
                  // How it works section
                  _buildHowItWorks(theme),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNoGroupsState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 80,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'No Groups Yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create or join a group to start planning trips with AI assistance',
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

  Widget _buildHowItWorks(ThemeData theme) {
    final steps = [
      (
        icon: Icons.attach_money,
        title: 'Set Budget',
        description: 'Tell us how much per person'
      ),
      (
        icon: Icons.calendar_month,
        title: 'Pick Dates',
        description: 'Choose months or specific dates'
      ),
      (
        icon: Icons.location_on,
        title: 'Starting Point',
        description: 'Enter your UK location'
      ),
      (
        icon: Icons.flight,
        title: 'Get Results',
        description: 'See destinations sorted by price'
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How it works',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: steps.map((step) {
            final index = steps.indexOf(step);
            return Expanded(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      step.icon,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    step.title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.description,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _startPlanning(BuildContext context, GroupModel group) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SuggestionWizardScreen(group: group),
      ),
    );
  }
}

/// Card for displaying a group
class _GroupCard extends StatelessWidget {
  final GroupModel group;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onStartPlanning;

  const _GroupCard({
    required this.group,
    required this.isSelected,
    required this.onTap,
    required this.onStartPlanning,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: AppColors.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Group photo or initials
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                    backgroundImage: group.photoUrl != null
                        ? NetworkImage(group.photoUrl!)
                        : null,
                    child: group.photoUrl == null
                        ? Text(
                            group.name.substring(0, 1).toUpperCase(),
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: AppColors.primary,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${group.members.length} members • Budget: £${group.rules.budgetPerPerson}/person',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(Icons.check_circle, color: AppColors.primary),
                ],
              ),
              if (isSelected) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onStartPlanning,
                    icon: const Icon(Icons.auto_awesome),
                    label: const Text('Find Destinations'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
