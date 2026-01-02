import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/activity_model.dart';
import '../data/repositories/activity_repository.dart';

/// Provider for the ActivityRepository
final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  return ActivityRepository();
});

/// Stream provider for all activities in a trip
final tripActivitiesProvider = StreamProvider.family<List<ActivityModel>, ({String groupId, String tripId})>((ref, params) {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getActivitiesStream(params.groupId, params.tripId);
});

/// Stream provider for activities on a specific day
final dayActivitiesProvider = StreamProvider.family<List<ActivityModel>, ({String groupId, String tripId, int dayNumber})>((ref, params) {
  final repository = ref.watch(activityRepositoryProvider);
  return repository.getActivitiesForDayStream(params.groupId, params.tripId, params.dayNumber);
});

/// Service class for activity operations (not a notifier, just a utility)
class ActivityService {
  final ActivityRepository _repository;
  
  ActivityService(this._repository);

  /// Create a new activity
  Future<ActivityModel> createActivity({
    required String groupId,
    required String tripId,
    required int dayNumber,
    required String name,
    String? description,
    String? location,
    String? placeId,
    double? latitude,
    double? longitude,
    String? category,
    String? notes,
    double? estimatedCost,
    String? startTime,
    String? endTime,
    int? durationMinutes,
  }) async {
    return await _repository.createActivity(
      groupId: groupId,
      tripId: tripId,
      dayNumber: dayNumber,
      name: name,
      description: description,
      location: location,
      placeId: placeId,
      latitude: latitude,
      longitude: longitude,
      category: category,
      notes: notes,
      estimatedCost: estimatedCost,
      startTime: startTime,
      endTime: endTime,
      durationMinutes: durationMinutes,
    );
  }

  /// Update an existing activity
  Future<void> updateActivity({
    required String groupId,
    required String tripId,
    required ActivityModel activity,
  }) async {
    await _repository.updateActivity(groupId, tripId, activity);
  }

  /// Delete an activity
  Future<void> deleteActivity({
    required String groupId,
    required String tripId,
    required String activityId,
  }) async {
    await _repository.deleteActivity(groupId, tripId, activityId);
  }

  /// Reorder activities within a day
  Future<void> reorderActivities({
    required String groupId,
    required String tripId,
    required int dayNumber,
    required List<String> activityIds,
  }) async {
    await _repository.reorderActivities(groupId, tripId, dayNumber, activityIds);
  }

  /// Move activity to a different day
  Future<void> moveActivityToDay({
    required String groupId,
    required String tripId,
    required String activityId,
    required int newDayNumber,
  }) async {
    await _repository.moveActivityToDay(groupId, tripId, activityId, newDayNumber);
  }

  /// Toggle activity completion
  Future<void> toggleCompleted({
    required String groupId,
    required String tripId,
    required String activityId,
    required bool isCompleted,
  }) async {
    await _repository.toggleActivityCompleted(
      groupId,
      tripId,
      activityId,
      isCompleted,
    );
  }
}

/// Provider for activity service
final activityServiceProvider = Provider<ActivityService>((ref) {
  final repository = ref.watch(activityRepositoryProvider);
  return ActivityService(repository);
});
