// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the TripRepository instance

@ProviderFor(tripRepository)
const tripRepositoryProvider = TripRepositoryProvider._();

/// Provides the TripRepository instance

final class TripRepositoryProvider
    extends $FunctionalProvider<TripRepository, TripRepository, TripRepository>
    with $Provider<TripRepository> {
  /// Provides the TripRepository instance
  const TripRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripRepositoryHash();

  @$internal
  @override
  $ProviderElement<TripRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  TripRepository create(Ref ref) {
    return tripRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TripRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TripRepository>(value),
    );
  }
}

String _$tripRepositoryHash() => r'bcfe05d8084305f06ddac9ce044eef08839a86a9';

/// Stream of all trips for the currently selected group

@ProviderFor(groupTrips)
const groupTripsProvider = GroupTripsFamily._();

/// Stream of all trips for the currently selected group

final class GroupTripsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TripModel>>,
          List<TripModel>,
          Stream<List<TripModel>>
        >
    with $FutureModifier<List<TripModel>>, $StreamProvider<List<TripModel>> {
  /// Stream of all trips for the currently selected group
  const GroupTripsProvider._({
    required GroupTripsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'groupTripsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$groupTripsHash();

  @override
  String toString() {
    return r'groupTripsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TripModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TripModel>> create(Ref ref) {
    final argument = this.argument as String;
    return groupTrips(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GroupTripsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$groupTripsHash() => r'e027a8372853710782797aa2ceb744ac9e040886';

/// Stream of all trips for the currently selected group

final class GroupTripsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TripModel>>, String> {
  const GroupTripsFamily._()
    : super(
        retry: null,
        name: r'groupTripsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream of all trips for the currently selected group

  GroupTripsProvider call(String groupId) =>
      GroupTripsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'groupTripsProvider';
}

/// Stream of upcoming trips for the currently selected group

@ProviderFor(upcomingTrips)
const upcomingTripsProvider = UpcomingTripsFamily._();

/// Stream of upcoming trips for the currently selected group

final class UpcomingTripsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TripModel>>,
          List<TripModel>,
          Stream<List<TripModel>>
        >
    with $FutureModifier<List<TripModel>>, $StreamProvider<List<TripModel>> {
  /// Stream of upcoming trips for the currently selected group
  const UpcomingTripsProvider._({
    required UpcomingTripsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'upcomingTripsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$upcomingTripsHash();

  @override
  String toString() {
    return r'upcomingTripsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TripModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TripModel>> create(Ref ref) {
    final argument = this.argument as String;
    return upcomingTrips(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UpcomingTripsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$upcomingTripsHash() => r'4112085e1b4d8ced9f197722146405c7d265244a';

/// Stream of upcoming trips for the currently selected group

final class UpcomingTripsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TripModel>>, String> {
  const UpcomingTripsFamily._()
    : super(
        retry: null,
        name: r'upcomingTripsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream of upcoming trips for the currently selected group

  UpcomingTripsProvider call(String groupId) =>
      UpcomingTripsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'upcomingTripsProvider';
}

/// Stream of past trips for the currently selected group

@ProviderFor(pastTrips)
const pastTripsProvider = PastTripsFamily._();

/// Stream of past trips for the currently selected group

final class PastTripsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TripModel>>,
          List<TripModel>,
          Stream<List<TripModel>>
        >
    with $FutureModifier<List<TripModel>>, $StreamProvider<List<TripModel>> {
  /// Stream of past trips for the currently selected group
  const PastTripsProvider._({
    required PastTripsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'pastTripsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$pastTripsHash();

  @override
  String toString() {
    return r'pastTripsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<List<TripModel>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<TripModel>> create(Ref ref) {
    final argument = this.argument as String;
    return pastTrips(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PastTripsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$pastTripsHash() => r'85d8cb67934f1481076a96d7f1c4e3c01fefc726';

/// Stream of past trips for the currently selected group

final class PastTripsFamily extends $Family
    with $FunctionalFamilyOverride<Stream<List<TripModel>>, String> {
  const PastTripsFamily._()
    : super(
        retry: null,
        name: r'pastTripsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Stream of past trips for the currently selected group

  PastTripsProvider call(String groupId) =>
      PastTripsProvider._(argument: groupId, from: this);

  @override
  String toString() => r'pastTripsProvider';
}

/// Get a specific trip by ID

@ProviderFor(tripDetails)
const tripDetailsProvider = TripDetailsFamily._();

/// Get a specific trip by ID

final class TripDetailsProvider
    extends
        $FunctionalProvider<
          AsyncValue<TripModel>,
          TripModel,
          FutureOr<TripModel>
        >
    with $FutureModifier<TripModel>, $FutureProvider<TripModel> {
  /// Get a specific trip by ID
  const TripDetailsProvider._({
    required TripDetailsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'tripDetailsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$tripDetailsHash();

  @override
  String toString() {
    return r'tripDetailsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<TripModel> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<TripModel> create(Ref ref) {
    final argument = this.argument as (String, String);
    return tripDetails(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is TripDetailsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$tripDetailsHash() => r'e4a923c6409ea9fa8440575a4185e2e94e5f4617';

/// Get a specific trip by ID

final class TripDetailsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TripModel>, (String, String)> {
  const TripDetailsFamily._()
    : super(
        retry: null,
        name: r'tripDetailsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Get a specific trip by ID

  TripDetailsProvider call(String groupId, String tripId) =>
      TripDetailsProvider._(argument: (groupId, tripId), from: this);

  @override
  String toString() => r'tripDetailsProvider';
}

/// Trip management notifier - handles all trip operations

@ProviderFor(TripNotifier)
const tripProvider = TripNotifierProvider._();

/// Trip management notifier - handles all trip operations
final class TripNotifierProvider
    extends $NotifierProvider<TripNotifier, AsyncValue<void>> {
  /// Trip management notifier - handles all trip operations
  const TripNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'tripProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$tripNotifierHash();

  @$internal
  @override
  TripNotifier create() => TripNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<void> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<void>>(value),
    );
  }
}

String _$tripNotifierHash() => r'256f853d078b8e481a80101aa4c33116aafa095e';

/// Trip management notifier - handles all trip operations

abstract class _$TripNotifier extends $Notifier<AsyncValue<void>> {
  AsyncValue<void> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<void>, AsyncValue<void>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<void>, AsyncValue<void>>,
              AsyncValue<void>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
