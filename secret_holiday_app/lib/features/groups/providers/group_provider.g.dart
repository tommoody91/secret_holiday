// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the GroupRepository instance

@ProviderFor(groupRepository)
const groupRepositoryProvider = GroupRepositoryProvider._();

/// Provides the GroupRepository instance

final class GroupRepositoryProvider
    extends
        $FunctionalProvider<GroupRepository, GroupRepository, GroupRepository>
    with $Provider<GroupRepository> {
  /// Provides the GroupRepository instance
  const GroupRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupRepositoryHash();

  @$internal
  @override
  $ProviderElement<GroupRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GroupRepository create(Ref ref) {
    return groupRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GroupRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GroupRepository>(value),
    );
  }
}

String _$groupRepositoryHash() => r'1c0b7da626de70818de616cf4d78e1bb87e90235';

/// Stream of all groups the current user is a member of

@ProviderFor(userGroups)
const userGroupsProvider = UserGroupsProvider._();

/// Stream of all groups the current user is a member of

final class UserGroupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GroupModel>>,
          List<GroupModel>,
          Stream<List<GroupModel>>
        >
    with $FutureModifier<List<GroupModel>>, $StreamProvider<List<GroupModel>> {
  /// Stream of all groups the current user is a member of
  const UserGroupsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userGroupsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userGroupsHash();

  @$internal
  @override
  $StreamProviderElement<List<GroupModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<GroupModel>> create(Ref ref) {
    return userGroups(ref);
  }
}

String _$userGroupsHash() => r'cd55765d019ee212745f57e3483ad2d3a0bfd657';

/// Tracks the currently selected group ID
/// This is used throughout the app to determine which group context to use

@ProviderFor(SelectedGroup)
const selectedGroupProvider = SelectedGroupProvider._();

/// Tracks the currently selected group ID
/// This is used throughout the app to determine which group context to use
final class SelectedGroupProvider
    extends $NotifierProvider<SelectedGroup, String?> {
  /// Tracks the currently selected group ID
  /// This is used throughout the app to determine which group context to use
  const SelectedGroupProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedGroupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedGroupHash();

  @$internal
  @override
  SelectedGroup create() => SelectedGroup();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$selectedGroupHash() => r'310f64de879c76e64931ce9cb0c83e20e04bc77b';

/// Tracks the currently selected group ID
/// This is used throughout the app to determine which group context to use

abstract class _$SelectedGroup extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

/// Stream of the currently selected group's full data
/// Returns null if no group is selected

@ProviderFor(selectedGroupData)
const selectedGroupDataProvider = SelectedGroupDataProvider._();

/// Stream of the currently selected group's full data
/// Returns null if no group is selected

final class SelectedGroupDataProvider
    extends
        $FunctionalProvider<
          AsyncValue<GroupModel?>,
          GroupModel?,
          Stream<GroupModel?>
        >
    with $FutureModifier<GroupModel?>, $StreamProvider<GroupModel?> {
  /// Stream of the currently selected group's full data
  /// Returns null if no group is selected
  const SelectedGroupDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedGroupDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedGroupDataHash();

  @$internal
  @override
  $StreamProviderElement<GroupModel?> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<GroupModel?> create(Ref ref) {
    return selectedGroupData(ref);
  }
}

String _$selectedGroupDataHash() => r'88fe6b88f534e32d907977393b674b418141e617';

/// Group management notifier - handles all group operations

@ProviderFor(GroupNotifier)
const groupProvider = GroupNotifierProvider._();

/// Group management notifier - handles all group operations
final class GroupNotifierProvider
    extends $AsyncNotifierProvider<GroupNotifier, void> {
  /// Group management notifier - handles all group operations
  const GroupNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'groupProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$groupNotifierHash();

  @$internal
  @override
  GroupNotifier create() => GroupNotifier();
}

String _$groupNotifierHash() => r'033358e677f6a6be2352baf27c6380e27387f06a';

/// Group management notifier - handles all group operations

abstract class _$GroupNotifier extends $AsyncNotifier<void> {
  FutureOr<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    build();
    final ref = this.ref as $Ref<AsyncValue<void>, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, void>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, null);
  }
}
