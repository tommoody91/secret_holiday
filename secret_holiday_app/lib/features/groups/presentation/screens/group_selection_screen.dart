import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../data/models/group_model.dart';
import '../../providers/group_provider.dart';

class GroupSelectionScreen extends ConsumerWidget {
  const GroupSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userGroupsAsync = ref.watch(userGroupsProvider);
    final selectedGroupId = ref.watch(selectedGroupProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Groups'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () {
              if (selectedGroupId != null) {
                context.push('/group-settings/$selectedGroupId');
              } else {
                AppSnackBar.show(
                  context: context,
                  message: 'Please select a group first',
                  type: SnackBarType.info,
                );
              }
            },
          ),
        ],
      ),
      body: userGroupsAsync.when(
        loading: () => const Center(child: LoadingIndicator()),
        error: (error, stack) => ErrorDisplay(
          message: 'Failed to load groups: $error',
          onRetry: () => ref.invalidate(userGroupsProvider),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groups.length + 1, // +1 for action buttons
            itemBuilder: (context, index) {
              if (index == groups.length) {
                return _buildActionButtons(context);
              }

              final group = groups[index];
              final isSelected = group.id == selectedGroupId;

              return _buildGroupCard(
                context,
                ref,
                group,
                isSelected,
                theme,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyState(
      icon: Icons.group_off,
      title: 'No Groups Yet',
      message: 'Create or join a group to start planning trips!',
      onAction: () => context.go(RouteConstants.createGroup),
      actionLabel: 'Create Group',
    );
  }

  Widget _buildGroupCard(
    BuildContext context,
    WidgetRef ref,
    GroupModel group,
    bool isSelected,
    ThemeData theme,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          ref.read(selectedGroupProvider.notifier).selectGroup(group.id);
          AppSnackBar.show(
            context: context,
            message: '${group.name} selected',
            type: SnackBarType.success,
            duration: const Duration(seconds: 1),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Group Icon
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.group,
                      color: theme.colorScheme.onPrimaryContainer,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Group Name & Members
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${group.members.length} ${group.members.length == 1 ? 'member' : 'members'}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Selected Indicator
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                ],
              ),

              // Upcoming Trip Info
              if (group.upcomingTripStartDate != null) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.flight_takeoff,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Next trip: ${_formatDate(group.upcomingTripStartDate!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 16),
        PrimaryButton(
          text: 'Create New Group',
          onPressed: () => context.go(RouteConstants.createGroup),
          icon: Icons.add,
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          text: 'Join Group',
          onPressed: () => context.go(RouteConstants.joinGroup),
          icon: Icons.link,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;

    if (difference < 0) {
      return 'Past';
    } else if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference < 7) {
      return 'In $difference days';
    } else {
      return '${date.month}/${date.day}/${date.year}';
    }
  }
}
