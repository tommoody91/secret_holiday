import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/memory_model.dart';

/// Repository for managing memories (photos/videos) in Firestore
class MemoryRepository {
  final FirebaseFirestore _firestore;

  MemoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get collection reference for memories
  CollectionReference<Map<String, dynamic>> _memoriesCollection(
    String groupId,
    String tripId,
  ) {
    return _firestore
        .collection('groups')
        .doc(groupId)
        .collection('trips')
        .doc(tripId)
        .collection('memories');
  }

  /// Create a new memory
  Future<MemoryModel> createMemory({
    required String groupId,
    required String tripId,
    required String url,
    required String type,
    required String uploadedBy,
    int? dayNumber,
    String? activityId,
    String? activityName,
    String? caption,
  }) async {
    final memory = MemoryModel(
      id: '', // Will be set by Firestore
      tripId: tripId,
      url: url,
      type: type,
      uploadedBy: uploadedBy,
      uploadedAt: DateTime.now(),
      dayNumber: dayNumber,
      activityId: activityId,
      activityName: activityName,
      caption: caption,
    );

    final docRef = await _memoriesCollection(groupId, tripId).add(memory.toFirestore());
    return memory.copyWith(id: docRef.id);
  }

  /// Get all memories for a trip
  Stream<List<MemoryModel>> watchMemories(String groupId, String tripId) {
    return _memoriesCollection(groupId, tripId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => MemoryModel.fromFirestore(doc)).toList());
  }

  /// Get memories filtered by day
  Stream<List<MemoryModel>> watchMemoriesByDay(
    String groupId,
    String tripId,
    int dayNumber,
  ) {
    return _memoriesCollection(groupId, tripId)
        .where('dayNumber', isEqualTo: dayNumber)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => MemoryModel.fromFirestore(doc)).toList());
  }

  /// Get memories filtered by activity
  Stream<List<MemoryModel>> watchMemoriesByActivity(
    String groupId,
    String tripId,
    String activityId,
  ) {
    return _memoriesCollection(groupId, tripId)
        .where('activityId', isEqualTo: activityId)
        .orderBy('uploadedAt', descending: true)
        .snapshots()
        .map((snapshot) => 
            snapshot.docs.map((doc) => MemoryModel.fromFirestore(doc)).toList());
  }

  /// Update memory metadata
  Future<void> updateMemory({
    required String groupId,
    required String tripId,
    required String memoryId,
    int? dayNumber,
    String? activityId,
    String? activityName,
    String? caption,
    bool clearDayNumber = false,
    bool clearActivityId = false,
  }) async {
    final updates = <String, dynamic>{};
    
    if (clearDayNumber) {
      updates['dayNumber'] = FieldValue.delete();
    } else if (dayNumber != null) {
      updates['dayNumber'] = dayNumber;
    }
    
    if (clearActivityId) {
      updates['activityId'] = FieldValue.delete();
      updates['activityName'] = FieldValue.delete();
    } else if (activityId != null) {
      updates['activityId'] = activityId;
      updates['activityName'] = activityName;
    }
    
    if (caption != null) {
      updates['caption'] = caption;
    }
    
    if (updates.isNotEmpty) {
      await _memoriesCollection(groupId, tripId).doc(memoryId).update(updates);
    }
  }

  /// Delete a memory
  Future<void> deleteMemory({
    required String groupId,
    required String tripId,
    required String memoryId,
  }) async {
    await _memoriesCollection(groupId, tripId).doc(memoryId).delete();
  }
}
