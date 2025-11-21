import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/route_constants.dart';
import '../../../../core/presentation/widgets/widgets.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/models/group_model.dart';
import '../../providers/group_provider.dart';

class GroupSettingsScreen extends ConsumerStatefulWidget {
  final String groupId;

  const GroupSettingsScreen({super.key, required this.groupId});

  @override
  ConsumerState<GroupSettingsScreen> createState() => _GroupSettingsScreenState();
}

class _GroupSettingsScreenState extends ConsumerState<GroupSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final groupRepository = ref.watch(groupRepositoryProvider);
    final currentUser = ref.watch(authStateChangesProvider).value;

    return StreamBuilder<GroupModel>(
      stream: groupRepository.getGroupStream(widget.groupId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: LoadingIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group Settings')),
            body: ErrorDisplay(
              message: 'Failed to load group: ${snapshot.error}',
              onRetry: () => setState(() {}),
            ),
          );
        }

        if (!snapshot.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('Group Settings')),
            body: const ErrorDisplay(
              message: 'Group not found',
            ),
          );
        }

        final group = snapshot.data!;
        final currentMember = group.members.firstWhere(
          (m) => m.userId == currentUser?.uid,
          orElse: () => GroupMember(
            userId: '',
            name: '',
            role: 'member',
            joinedAt: DateTime.now(),
          ),
        );
        final isAdmin = currentMember.role == 'admin';

        return Scaffold(
          appBar: AppBar(
            title: const Text('Group Settings'),
            actions: [
              if (isAdmin)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit Settings',
                  onPressed: () {
                    context.push('/group-settings/${widget.groupId}/edit');
                  },
                ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildGroupInfoSection(group),
              const SizedBox(height: 24),
              _buildInviteCodeSection(context, group),
              const SizedBox(height: 24),
              _buildMembersSection(context, group, currentUser?.uid ?? '', isAdmin),
              const SizedBox(height: 24),
              _buildRulesSection(group),
              const SizedBox(height: 24),
              _buildDangerZone(context, group, isAdmin),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGroupInfoSection(GroupModel group) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Group Information',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Name', group.name),
            _buildInfoRow('Members', '${group.members.length}'),
            _buildInfoRow(
              'Created',
              '${group.createdAt.month}/${group.createdAt.day}/${group.createdAt.year}',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInviteCodeSection(BuildContext context, GroupModel group) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Invite Code',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      group.inviteCode,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        fontFamily: 'monospace',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SecondaryButton(
              text: 'Copy Invite Code',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: group.inviteCode));
                AppSnackBar.show(
                  context: context,
                  message: 'Invite code copied!',
                  type: SnackBarType.success,
                );
              },
              icon: Icons.copy,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection(
    BuildContext context,
    GroupModel group,
    String currentUserId,
    bool isAdmin,
  ) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Members (${group.members.length})',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...group.members.map((member) => _buildMemberTile(
              context,
              member,
              group.id,
              currentUserId,
              isAdmin,
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    GroupMember member,
    String groupId,
    String currentUserId,
    bool isAdmin,
  ) {
    final theme = Theme.of(context);
    final isCurrentUser = member.userId == currentUserId;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: UserAvatar(
        imageUrl: member.profilePictureUrl,
        name: member.name,
        size: 40,
      ),
      title: Row(
        children: [
          Text(member.name),
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            Text(
              '(You)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        member.role == 'admin' ? 'Admin' : 'Member',
        style: TextStyle(
          color: member.role == 'admin'
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: isAdmin && !isCurrentUser
          ? PopupMenuButton(
              itemBuilder: (context) => [
                if (member.role == 'member')
                  PopupMenuItem(
                    child: const Text('Make Admin'),
                    onTap: () => _updateMemberRole(groupId, member.userId, 'admin'),
                  ),
                if (member.role == 'admin')
                  PopupMenuItem(
                    child: const Text('Remove Admin'),
                    onTap: () => _updateMemberRole(groupId, member.userId, 'member'),
                  ),
                PopupMenuItem(
                  child: const Text('Remove from Group'),
                  onTap: () => _removeMember(groupId, member.userId, member.name),
                ),
              ],
            )
          : null,
    );
  }

  Widget _buildRulesSection(GroupModel group) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rule, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Travel Rules',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow('Budget Per Person', '\$${group.rules.budgetPerPerson}'),
            _buildInfoRow('Max Trip Days', '${group.rules.maxTripDays} days'),
            _buildInfoRow('Luggage', group.rules.luggageAllowance),
            _buildInfoRow(
              'No Repeat Countries',
              group.rules.noRepeatCountries ? 'Yes' : 'No',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, GroupModel group, bool isAdmin) {
    final theme = Theme.of(context);
    
    return Card(
      color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text(
                  'Danger Zone',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            SecondaryButton(
              text: 'Leave Group',
              onPressed: () => _confirmLeaveGroup(context, group),
              icon: Icons.exit_to_app,
            ),
            if (isAdmin) ...[
              const SizedBox(height: 12),
              SecondaryButton(
                text: 'Delete Group',
                onPressed: () => _confirmDeleteGroup(context, group),
                icon: Icons.delete_forever,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateMemberRole(String groupId, String userId, String newRole) async {
    try {
      await ref.read(groupProvider.notifier).updateMemberRole(
        groupId: groupId,
        userId: userId,
        newRole: newRole,
      );

      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Member role updated',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Failed to update role: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _removeMember(String groupId, String userId, String memberName) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Remove Member',
      message: 'Remove $memberName from the group?',
      confirmText: 'Remove',
      cancelText: 'Cancel',
    );

    if (confirmed != true) return;

    try {
      await ref.read(groupProvider.notifier).removeMember(
        groupId: groupId,
        userId: userId,
      );

      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: '$memberName removed from group',
          type: SnackBarType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.show(
          context: context,
          message: 'Failed to remove member: ${e.toString()}',
          type: SnackBarType.error,
        );
      }
    }
  }

  Future<void> _confirmLeaveGroup(BuildContext context, GroupModel group) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Leave Group',
      message: 'Are you sure you want to leave "${group.name}"?',
      confirmText: 'Leave',
      cancelText: 'Cancel',
    );

    if (confirmed != true) return;

    // User confirmed, now leave and navigate
    final groupId = group.id;
    final groupName = group.name;

    try {
      // Leave the group
      await ref.read(groupRepositoryProvider).leaveGroup(groupId);
      
      // Clear selection if this was the selected group
      final selectedGroupId = ref.read(selectedGroupProvider);
      if (selectedGroupId == groupId) {
        ref.read(selectedGroupProvider.notifier).clearSelection();
      }

      if (!mounted) return;
      
      // Navigate to home
      context.go(RouteConstants.home);
      
      // Show success
      AppSnackBar.show(
        context: context,
        message: 'Left group "$groupName" successfully',
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      
      AppSnackBar.show(
        context: context,
        message: 'Failed to leave group: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  Future<void> _confirmDeleteGroup(BuildContext context, GroupModel group) async {
    final confirmed = await ConfirmDialog.show(
      context: context,
      title: 'Delete Group',
      message: 'Permanently delete "${group.name}"? This cannot be undone.',
      confirmText: 'Delete',
      cancelText: 'Cancel',
      isDestructive: true,
    );

    if (confirmed != true) return;

    // User confirmed, now delete and navigate
    final groupId = group.id;
    final groupName = group.name;

    try {
      // Delete the group
      await ref.read(groupRepositoryProvider).deleteGroup(groupId);
      
      // Clear selection if this was the selected group
      final selectedGroupId = ref.read(selectedGroupProvider);
      if (selectedGroupId == groupId) {
        ref.read(selectedGroupProvider.notifier).clearSelection();
      }

      if (!mounted) return;
      
      // Navigate to home
      context.go(RouteConstants.home);
      
      // Show success
      AppSnackBar.show(
        context: context,
        message: 'Group "$groupName" deleted successfully',
        type: SnackBarType.success,
      );
    } catch (e) {
      if (!mounted) return;
      
      AppSnackBar.show(
        context: context,
        message: 'Failed to delete group: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }
}
