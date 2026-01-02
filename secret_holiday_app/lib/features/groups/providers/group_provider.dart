import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:secret_holiday_app/features/groups/data/models/group_model.dart';
import 'package:secret_holiday_app/features/groups/data/repositories/group_repository.dart';

part 'group_provider.g.dart';

/// Provides the GroupRepository instance
@riverpod
GroupRepository groupRepository(Ref ref) {
  return GroupRepository();
}

/// Stream of all groups the current user is a member of
@riverpod
Stream<List<GroupModel>> userGroups(Ref ref) {
  final repository = ref.watch(groupRepositoryProvider);
  return repository.getUserGroups();
}

/// Tracks the currently selected group ID
/// This is used throughout the app to determine which group context to use
@riverpod
class SelectedGroup extends _$SelectedGroup {
  @override
  String? build() {
    // Initialize with null - will be set when user selects a group
    return null;
  }

  /// Set the currently active group
  void selectGroup(String groupId) {
    state = groupId;
  }

  /// Clear the selected group
  void clearSelection() {
    state = null;
  }
}

/// Stream of the currently selected group's full data
/// Returns null if no group is selected
@riverpod
Stream<GroupModel?> selectedGroupData(Ref ref) {
  final selectedGroupId = ref.watch(selectedGroupProvider);
  
  if (selectedGroupId == null) {
    return Stream.value(null);
  }

  final repository = ref.watch(groupRepositoryProvider);
  return repository.getGroupStream(selectedGroupId);
}

/// Group management notifier - handles all group operations
@riverpod
class GroupNotifier extends _$GroupNotifier {
  @override
  FutureOr<void> build() {
    // No initial state needed
  }

  /// Create a new group
  Future<GroupModel> createGroup({
    required String name,
    required int budgetPerPerson,
    required int maxTripDays,
    String luggageAllowance = 'Not specified',
    bool noRepeatCountries = false,
    List<String> customRules = const [],
    String? photoUrl,
  }) async {
    state = const AsyncValue.loading();
    
    return await AsyncValue.guard(() async {
      final repository = ref.read(groupRepositoryProvider);
      final group = await repository.createGroup(
        name: name,
        budgetPerPerson: budgetPerPerson,
        maxTripDays: maxTripDays,
        luggageAllowance: luggageAllowance,
        noRepeatCountries: noRepeatCountries,
        customRules: customRules,
        photoUrl: photoUrl,
      );

      // Auto-select the newly created group
      ref.read(selectedGroupProvider.notifier).selectGroup(group.id);
      
      state = const AsyncValue.data(null);
      return group;
    }).then((asyncValue) {
      state = asyncValue;
      if (asyncValue.hasValue) {
        return asyncValue.value!;
      } else {
        throw asyncValue.error!;
      }
    });
  }

  /// Join an existing group using invite code
  Future<GroupModel> joinGroup(String inviteCode) async {
    state = const AsyncValue.loading();
    
    return await AsyncValue.guard(() async {
      final repository = ref.read(groupRepositoryProvider);
      final group = await repository.joinGroup(inviteCode);

      // Auto-select the newly joined group
      ref.read(selectedGroupProvider.notifier).selectGroup(group.id);
      
      state = const AsyncValue.data(null);
      return group;
    }).then((asyncValue) {
      state = asyncValue;
      if (asyncValue.hasValue) {
        return asyncValue.value!;
      } else {
        throw asyncValue.error!;
      }
    });
  }

  /// Update group settings (admin only)
  Future<void> updateGroupSettings({
    required String groupId,
    String? name,
    GroupRules? rules,
    DateTime? upcomingTripStartDate,
    DateTime? upcomingTripEndDate,
  }) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(groupRepositoryProvider);
      await repository.updateGroupSettings(
        groupId: groupId,
        name: name,
        rules: rules,
        upcomingTripStartDate: upcomingTripStartDate,
        upcomingTripEndDate: upcomingTripEndDate,
      );
    });
  }

  /// Remove a member from the group
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(groupRepositoryProvider);
      await repository.removeMember(groupId: groupId, userId: userId);
    });
  }

  /// Update a member's role (admin only)
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required String newRole,
  }) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(groupRepositoryProvider);
      await repository.updateMemberRole(
        groupId: groupId,
        userId: userId,
        newRole: newRole,
      );
    });
  }

  /// Leave a group
  Future<void> leaveGroup(String groupId) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(groupRepositoryProvider);
      await repository.leaveGroup(groupId);

      // Clear selection if leaving the currently selected group
      final selectedGroupId = ref.read(selectedGroupProvider);
      if (selectedGroupId == groupId) {
        ref.read(selectedGroupProvider.notifier).clearSelection();
      }
    });
  }

  /// Delete a group (admin only)
  Future<void> deleteGroup(String groupId) async {
    state = const AsyncValue.loading();
    
    state = await AsyncValue.guard(() async {
      final repository = ref.read(groupRepositoryProvider);
      await repository.deleteGroup(groupId);

      // Clear selection if deleting the currently selected group
      final selectedGroupId = ref.read(selectedGroupProvider);
      if (selectedGroupId == groupId) {
        ref.read(selectedGroupProvider.notifier).clearSelection();
      }
    });
  }

  /// Validate an invite code
  Future<GroupModel?> validateInviteCode(String inviteCode) async {
    final repository = ref.read(groupRepositoryProvider);
    return await repository.validateInviteCode(inviteCode);
  }
}
