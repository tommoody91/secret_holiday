import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/models/trip_model.dart';
import '../data/repositories/trip_repository.dart';

part 'trip_provider.g.dart';

/// Provides the TripRepository instance
@riverpod
TripRepository tripRepository(Ref ref) {
  return TripRepository();
}

/// Stream of all trips for the currently selected group
@riverpod
Stream<List<TripModel>> groupTrips(Ref ref, String groupId) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getTripsStream(groupId);
}

/// Stream of upcoming trips for the currently selected group
@riverpod
Stream<List<TripModel>> upcomingTrips(Ref ref, String groupId) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getUpcomingTrips(groupId);
}

/// Stream of past trips for the currently selected group
@riverpod
Stream<List<TripModel>> pastTrips(Ref ref, String groupId) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getPastTrips(groupId);
}

/// Get a specific trip by ID
@riverpod
Future<TripModel> tripDetails(Ref ref, String groupId, String tripId) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getTrip(groupId, tripId);
}

/// Trip management notifier - handles all trip operations
@riverpod
class TripNotifier extends _$TripNotifier {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  /// Create a new trip
  Future<TripModel> createTrip({
    required String groupId,
    required String tripName,
    required String destination,
    required String country,
    required String countryCode,
    required DateTime startDate,
    required DateTime endDate,
    required String summary,
    required int budgetPerPerson,
    double? latitude,
    double? longitude,
    String? coverPhotoUrl,
    int adventurousness = 50,
    int foodFocus = 50,
    int urbanVsNature = 50,
    int budgetFlexibility = 50,
    int pacePreference = 50,
  }) async {
    final repository = ref.read(tripRepositoryProvider);
    return await repository.createTrip(
      groupId: groupId,
      tripName: tripName,
      destination: destination,
      country: country,
      countryCode: countryCode,
      startDate: startDate,
      endDate: endDate,
      summary: summary,
      budgetPerPerson: budgetPerPerson,
      latitude: latitude,
      longitude: longitude,
      coverPhotoUrl: coverPhotoUrl,
      adventurousness: adventurousness,
      foodFocus: foodFocus,
      urbanVsNature: urbanVsNature,
      budgetFlexibility: budgetFlexibility,
      pacePreference: pacePreference,
    );
  }

  /// Update trip details
  Future<void> updateTrip({
    required String groupId,
    required String tripId,
    String? tripName,
    String? destination,
    String? country,
    String? countryCode,
    DateTime? startDate,
    DateTime? endDate,
    String? summary,
    int? budgetPerPerson,
    String? coverPhotoUrl,
    TripStatus? status,
    List<String>? participantIds,
    double? latitude,
    double? longitude,
    int? adventurousness,
    int? foodFocus,
    int? urbanVsNature,
    int? budgetFlexibility,
    int? pacePreference,
  }) async {
    final repository = ref.read(tripRepositoryProvider);
    await repository.updateTrip(
      groupId: groupId,
      tripId: tripId,
      tripName: tripName,
      destination: destination,
      country: country,
      countryCode: countryCode,
      startDate: startDate,
      endDate: endDate,
      summary: summary,
      budgetPerPerson: budgetPerPerson,
      coverPhotoUrl: coverPhotoUrl,
      status: status,
      participantIds: participantIds,
      latitude: latitude,
      longitude: longitude,
      adventurousness: adventurousness,
      foodFocus: foodFocus,
      urbanVsNature: urbanVsNature,
      budgetFlexibility: budgetFlexibility,
      pacePreference: pacePreference,
    );
  }

  /// Delete a trip
  Future<void> deleteTrip({
    required String groupId,
    required String tripId,
  }) async {
    final repository = ref.read(tripRepositoryProvider);
    await repository.deleteTrip(groupId, tripId);
  }

  /// Add media to a trip
  Future<void> addMedia({
    required String groupId,
    required String tripId,
    required TripMedia media,
  }) async {
    final repository = ref.read(tripRepositoryProvider);
    await repository.addMedia(groupId, tripId, media);
  }

  /// Remove media from a trip
  Future<void> removeMedia({
    required String groupId,
    required String tripId,
    required TripMedia media,
  }) async {
    final repository = ref.read(tripRepositoryProvider);
    await repository.removeMedia(groupId, tripId, media);
  }
}
