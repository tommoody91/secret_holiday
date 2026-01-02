import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/activity_model.dart';

/// Repository for managing trip activities in Firestore
class ActivityRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  ActivityRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get activities collection reference for a trip
  CollectionReference<Map<String, dynamic>> _activitiesCollection(
    String groupId,
    String tripId,
  ) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('trips')
        .doc(tripId)
        .collection('activities');
  }

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
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Get the next order index for this day
    final existingActivities = await getActivitiesForDay(groupId, tripId, dayNumber);
    final orderIndex = existingActivities.isEmpty
        ? 0
        : existingActivities.map((a) => a.orderIndex).reduce((a, b) => a > b ? a : b) + 1;

    final now = DateTime.now();
    final docRef = _activitiesCollection(groupId, tripId).doc();

    final activity = ActivityModel(
      id: docRef.id,
      tripId: tripId,
      dayNumber: dayNumber,
      orderIndex: orderIndex,
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
      createdBy: user.uid,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(activity.toFirestore());
    return activity;
  }

  /// Get all activities for a trip
  Stream<List<ActivityModel>> getActivitiesStream(String groupId, String tripId) {
    return _activitiesCollection(groupId, tripId)
        .orderBy('dayNumber')
        .orderBy('orderIndex')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityModel.fromFirestore(doc))
            .toList());
  }

  /// Get activities for a specific day
  Future<List<ActivityModel>> getActivitiesForDay(
    String groupId,
    String tripId,
    int dayNumber,
  ) async {
    final snapshot = await _activitiesCollection(groupId, tripId)
        .where('dayNumber', isEqualTo: dayNumber)
        .orderBy('orderIndex')
        .get();

    return snapshot.docs.map((doc) => ActivityModel.fromFirestore(doc)).toList();
  }

  /// Stream activities for a specific day
  Stream<List<ActivityModel>> getActivitiesForDayStream(
    String groupId,
    String tripId,
    int dayNumber,
  ) {
    return _activitiesCollection(groupId, tripId)
        .where('dayNumber', isEqualTo: dayNumber)
        .orderBy('orderIndex')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ActivityModel.fromFirestore(doc))
            .toList());
  }

  /// Update an activity
  Future<void> updateActivity(
    String groupId,
    String tripId,
    ActivityModel activity,
  ) async {
    await _activitiesCollection(groupId, tripId)
        .doc(activity.id)
        .update(activity.copyWith(updatedAt: DateTime.now()).toFirestore());
  }

  /// Delete an activity
  Future<void> deleteActivity(
    String groupId,
    String tripId,
    String activityId,
  ) async {
    await _activitiesCollection(groupId, tripId).doc(activityId).delete();
  }

  /// Reorder activities within a day
  Future<void> reorderActivities(
    String groupId,
    String tripId,
    int dayNumber,
    List<String> activityIds,
  ) async {
    final batch = _firestore.batch();
    final collection = _activitiesCollection(groupId, tripId);

    for (int i = 0; i < activityIds.length; i++) {
      batch.update(collection.doc(activityIds[i]), {
        'orderIndex': i,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Move an activity to a different day
  Future<void> moveActivityToDay(
    String groupId,
    String tripId,
    String activityId,
    int newDayNumber,
  ) async {
    // Get new order index for target day
    final targetActivities = await getActivitiesForDay(groupId, tripId, newDayNumber);
    final newOrderIndex = targetActivities.isEmpty
        ? 0
        : targetActivities.map((a) => a.orderIndex).reduce((a, b) => a > b ? a : b) + 1;

    await _activitiesCollection(groupId, tripId).doc(activityId).update({
      'dayNumber': newDayNumber,
      'orderIndex': newOrderIndex,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Toggle activity completion status
  Future<void> toggleActivityCompleted(
    String groupId,
    String tripId,
    String activityId,
    bool isCompleted,
  ) async {
    await _activitiesCollection(groupId, tripId).doc(activityId).update({
      'isCompleted': isCompleted,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Add a photo to an activity
  Future<void> addPhotoToActivity(
    String groupId,
    String tripId,
    String activityId,
    String photoId,
  ) async {
    await _activitiesCollection(groupId, tripId).doc(activityId).update({
      'photoIds': FieldValue.arrayUnion([photoId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Remove a photo from an activity
  Future<void> removePhotoFromActivity(
    String groupId,
    String tripId,
    String activityId,
    String photoId,
  ) async {
    await _activitiesCollection(groupId, tripId).doc(activityId).update({
      'photoIds': FieldValue.arrayRemove([photoId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
