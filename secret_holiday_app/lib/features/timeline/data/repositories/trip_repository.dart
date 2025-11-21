import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/trip_model.dart';

/// Repository for trip-related operations with Firebase Firestore
class TripRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  TripRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  /// Get trips collection reference for a group
  CollectionReference _getTripsCollection(String groupId) {
    return _firestore.collection('groups').doc(groupId).collection('trips');
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
    int adventurousness = 50,
    int foodFocus = 50,
    int urbanVsNature = 50,
    int budgetFlexibility = 50,
    int pacePreference = 50,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('User not authenticated');
      }

      AppLogger.info('Creating trip: $tripName for group: $groupId');

      final now = DateTime.now();
      final year = startDate.year;
      final tripRef = _getTripsCollection(groupId).doc();

      // Get organizer name from user
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();
      final organizerName = userData?['name'] ?? user.displayName ?? 'Unknown';

      // Get all group members to set as default participants
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final groupData = groupDoc.data() as Map<String, dynamic>;
      final members = (groupData['members'] as List<dynamic>)
          .map((m) => m as Map<String, dynamic>)
          .toList();
      final participantIds = members.map((m) => m['userId'] as String).toList();

      // Calculate initial status based on dates
      final initialStatus = _calculateStatus(startDate, endDate, now);

      final tripData = TripModel(
        id: tripRef.id,
        groupId: groupId,
        year: year,
        tripName: tripName,
        location: TripLocation(
          destination: destination,
          country: country,
          countryCode: countryCode,
          latitude: latitude ?? 0.0,
          longitude: longitude ?? 0.0,
        ),
        organizerId: user.uid,
        organizerName: organizerName,
        startDate: startDate,
        endDate: endDate,
        summary: summary,
        itinerary: const [], // Empty initially
        media: const [], // Empty initially
        coverPhotoUrl: null,
        totalCost: 0, // Will be calculated from expenses
        costPerPerson: budgetPerPerson,
        status: initialStatus,
        participantIds: participantIds,
        adventurousness: adventurousness,
        foodFocus: foodFocus,
        urbanVsNature: urbanVsNature,
        budgetFlexibility: budgetFlexibility,
        pacePreference: pacePreference,
        createdAt: now,
        updatedAt: now,
      );

      await tripRef.set(tripData.toFirestore());
      AppLogger.info('Trip created successfully: ${tripRef.id}');

      return tripData;
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Error creating trip', e, stackTrace);
      throw ServerException('Failed to create trip');
    }
  }

  /// Get a specific trip by ID
  Future<TripModel> getTrip(String groupId, String tripId) async {
    try {
      AppLogger.info('Getting trip: $tripId from group: $groupId');

      final doc = await _getTripsCollection(groupId).doc(tripId).get();

      if (!doc.exists) {
        throw DataException('Trip not found');
      }

      return TripModel.fromFirestore(doc);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting trip', e, stackTrace);
      throw ServerException('Failed to get trip');
    }
  }

  /// Stream all trips for a group
  Stream<List<TripModel>> getTripsStream(String groupId) {
    AppLogger.info('Watching trips for group: $groupId');

    return _getTripsCollection(groupId)
        .orderBy('startDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TripModel.fromFirestore(doc)).toList();
    });
  }

  /// Get upcoming trips for a group
  Stream<List<TripModel>> getUpcomingTrips(String groupId) {
    final now = DateTime.now();

    return _getTripsCollection(groupId)
        .where('startDate', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('startDate', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TripModel.fromFirestore(doc)).toList();
    });
  }

  /// Get past trips for a group
  Stream<List<TripModel>> getPastTrips(String groupId) {
    final now = DateTime.now();

    return _getTripsCollection(groupId)
        .where('endDate', isLessThan: Timestamp.fromDate(now))
        .orderBy('endDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TripModel.fromFirestore(doc)).toList();
    });
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
    try {
      AppLogger.info('Updating trip: $tripId');

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (tripName != null) updates['tripName'] = tripName;
      if (destination != null) updates['location.destination'] = destination;
      if (country != null) updates['location.country'] = country;
      if (countryCode != null) updates['location.countryCode'] = countryCode;
      if (latitude != null) updates['location.latitude'] = latitude;
      if (longitude != null) updates['location.longitude'] = longitude;
      if (startDate != null) {
        updates['startDate'] = Timestamp.fromDate(startDate);
        updates['year'] = startDate.year;
      }
      if (endDate != null) updates['endDate'] = Timestamp.fromDate(endDate);
      if (summary != null) updates['summary'] = summary;
      if (budgetPerPerson != null) updates['costPerPerson'] = budgetPerPerson;
      if (coverPhotoUrl != null) updates['coverPhotoUrl'] = coverPhotoUrl;
      if (status != null) updates['status'] = status.name;
      if (participantIds != null) updates['participantIds'] = participantIds;
      if (adventurousness != null) updates['adventurousness'] = adventurousness;
      if (foodFocus != null) updates['foodFocus'] = foodFocus;
      if (urbanVsNature != null) updates['urbanVsNature'] = urbanVsNature;
      if (budgetFlexibility != null) updates['budgetFlexibility'] = budgetFlexibility;
      if (pacePreference != null) updates['pacePreference'] = pacePreference;

      await _getTripsCollection(groupId).doc(tripId).update(updates);
      AppLogger.info('Trip updated successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error updating trip', e, stackTrace);
      throw ServerException('Failed to update trip');
    }
  }

  /// Calculate trip status based on dates
  TripStatus _calculateStatus(DateTime startDate, DateTime endDate, DateTime now) {
    if (now.isBefore(startDate)) return TripStatus.planning;
    if (now.isAfter(endDate)) return TripStatus.completed;
    return TripStatus.ongoing;
  }

  /// Delete a trip
  Future<void> deleteTrip(String groupId, String tripId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('User not authenticated');
      }

      AppLogger.info('Deleting trip: $tripId');

      // Get the trip to check permissions
      final trip = await getTrip(groupId, tripId);

      // Get group to check if user is admin
      final groupDoc = await _firestore.collection('groups').doc(groupId).get();
      final groupData = groupDoc.data() as Map<String, dynamic>;
      final members = (groupData['members'] as List<dynamic>)
          .map((m) => m as Map<String, dynamic>)
          .toList();

      final userMember = members.firstWhere(
        (member) => member['userId'] == user.uid,
        orElse: () => throw AuthException('User not a member of this group'),
      );

      // Only organizer or admin can delete
      if (trip.organizerId != user.uid && userMember['role'] != 'admin') {
        throw AuthException('Only the organizer or admin can delete this trip');
      }

      await _getTripsCollection(groupId).doc(tripId).delete();
      AppLogger.info('Trip deleted successfully');
    } on AuthException {
      rethrow;
    } catch (e, stackTrace) {
      AppLogger.error('Error deleting trip', e, stackTrace);
      throw ServerException('Failed to delete trip');
    }
  }

  /// Add media to a trip
  Future<void> addMedia(
    String groupId,
    String tripId,
    TripMedia media,
  ) async {
    try {
      AppLogger.info('Adding media to trip: $tripId');

      await _getTripsCollection(groupId).doc(tripId).update({
        'media': FieldValue.arrayUnion([media.toJson()]),
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info('Media added successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error adding media', e, stackTrace);
      throw ServerException('Failed to add media');
    }
  }

  /// Remove media from a trip
  Future<void> removeMedia(
    String groupId,
    String tripId,
    TripMedia media,
  ) async {
    try {
      AppLogger.info('Removing media from trip: $tripId');

      await _getTripsCollection(groupId).doc(tripId).update({
        'media': FieldValue.arrayRemove([media.toJson()]),
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info('Media removed successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Error removing media', e, stackTrace);
      throw ServerException('Failed to remove media');
    }
  }
}
