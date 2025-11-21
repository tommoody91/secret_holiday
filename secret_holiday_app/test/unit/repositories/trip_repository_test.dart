import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:secret_holiday_app/features/timeline/data/repositories/trip_repository.dart';
import 'package:secret_holiday_app/features/timeline/data/models/trip_model.dart';
import 'package:secret_holiday_app/core/error/exceptions.dart';
import '../../helpers/mock_firebase_auth.mocks.dart';
import '../../helpers/mock_auth_helper.dart';
import '../../helpers/test_data.dart';

void main() {
  late TripRepository repository;
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth();
    repository = TripRepository(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  group('TripRepository', () {
    group('createTrip', () {
      test('creates trip with all details successfully', () async {
        // Arrange
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        await fakeFirestore.collection('users').doc('user1').set({
          'id': 'user1',
          'name': 'John Doe',
        });

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        // Act
        final futureDate = DateTime.now().add(Duration(days: 180));
        final result = await repository.createTrip(
          groupId: 'group1',
          tripName: 'Tokyo Adventure',
          destination: 'Tokyo',
          country: 'Japan',
          countryCode: 'JP',
          startDate: futureDate,
          endDate: futureDate.add(Duration(days: 6)),
          summary: 'Amazing trip to Tokyo',
          budgetPerPerson: 2000,
          latitude: 35.6762,
          longitude: 139.6503,
        );

        // Assert
        expect(result.tripName, 'Tokyo Adventure');
        expect(result.location.destination, 'Tokyo');
        expect(result.location.country, 'Japan');
        expect(result.location.latitude, 35.6762);
        expect(result.organizerId, 'user1');
        expect(result.organizerName, 'John Doe');
        expect(result.costPerPerson, 2000);
        expect(result.status, TripStatus.planning);
        expect(result.participantIds, containsAll(['user1', 'user2', 'user3']));
      });

      test('calculates status as ongoing when between dates', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        await fakeFirestore.collection('users').doc('user1').set({'name': 'John'});
        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        final yesterday = DateTime.now().subtract(Duration(days: 1));
        final tomorrow = DateTime.now().add(Duration(days: 1));

        final result = await repository.createTrip(
          groupId: 'group1',
          tripName: 'Current Trip',
          destination: 'Paris',
          country: 'France',
          countryCode: 'FR',
          startDate: yesterday,
          endDate: tomorrow,
          summary: 'Ongoing trip',
          budgetPerPerson: 1500,
        );

        expect(result.status, TripStatus.ongoing);
      });

      test('calculates status as completed when past end date', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        await fakeFirestore.collection('users').doc('user1').set({'name': 'John'});
        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        final lastWeek = DateTime.now().subtract(Duration(days: 7));
        final yesterday = DateTime.now().subtract(Duration(days: 1));

        final result = await repository.createTrip(
          groupId: 'group1',
          tripName: 'Past Trip',
          destination: 'Rome',
          country: 'Italy',
          countryCode: 'IT',
          startDate: lastWeek,
          endDate: yesterday,
          summary: 'Completed trip',
          budgetPerPerson: 1800,
        );

        expect(result.status, TripStatus.completed);
      });

      test('auto-populates participants from group members', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        await fakeFirestore.collection('users').doc('user1').set({'name': 'John'});
        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        final futureDate = DateTime.now().add(Duration(days: 90));
        final result = await repository.createTrip(
          groupId: 'group1',
          tripName: 'Group Trip',
          destination: 'London',
          country: 'UK',
          countryCode: 'GB',
          startDate: futureDate,
          endDate: futureDate.add(Duration(days: 6)),
          summary: 'All members included',
          budgetPerPerson: 2500,
        );

        expect(result.participantIds.length, 3);
        expect(result.participantIds, containsAll(['user1', 'user2', 'user3']));
      });

      test('throws AuthException when user not authenticated', () {
        MockAuthHelper.setupMockAuthWithoutUser(mockAuth);

        expect(
          () => repository.createTrip(
            groupId: 'group1',
            tripName: 'Trip',
            destination: 'Paris',
            country: 'France',
            countryCode: 'FR',
            startDate: DateTime(2025, 6, 1),
            endDate: DateTime(2025, 6, 7),
            summary: 'Test',
            budgetPerPerson: 1000,
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('creates trip with custom travel preferences', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        await fakeFirestore.collection('users').doc('user1').set({'name': 'John'});
        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        final futureDate = DateTime.now().add(Duration(days: 90));
        final result = await repository.createTrip(
          groupId: 'group1',
          tripName: 'Adventure Trip',
          destination: 'New Zealand',
          country: 'New Zealand',
          countryCode: 'NZ',
          startDate: futureDate,
          endDate: futureDate.add(Duration(days: 14)),
          summary: 'Adventurous outdoor trip',
          budgetPerPerson: 3000,
          adventurousness: 90,
          foodFocus: 60,
          urbanVsNature: 20,
          budgetFlexibility: 70,
          pacePreference: 80,
        );

        expect(result.adventurousness, 90);
        expect(result.foodFocus, 60);
        expect(result.urbanVsNature, 20);
        expect(result.budgetFlexibility, 70);
        expect(result.pacePreference, 80);

        // Verify saved to Firestore
        final doc = await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc(result.id)
            .get();
        expect(doc.data()!['adventurousness'], 90);
        expect(doc.data()!['foodFocus'], 60);
      });

      test('creates trip with default preferences when not specified', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        await fakeFirestore.collection('users').doc('user1').set({'name': 'John'});
        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        final futureDate = DateTime.now().add(Duration(days: 60));
        final result = await repository.createTrip(
          groupId: 'group1',
          tripName: 'Standard Trip',
          destination: 'Barcelona',
          country: 'Spain',
          countryCode: 'ES',
          startDate: futureDate,
          endDate: futureDate.add(Duration(days: 7)),
          summary: 'City break',
          budgetPerPerson: 1200,
        );

        // Should use defaults (50)
        expect(result.adventurousness, 50);
        expect(result.foodFocus, 50);
        expect(result.urbanVsNature, 50);
        expect(result.budgetFlexibility, 50);
        expect(result.pacePreference, 50);
      });
    });

    group('getTrip', () {
      test('retrieves trip by ID successfully', () async {
        final tripData = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
        );
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(tripData.toFirestore());

        final result = await repository.getTrip('group1', 'trip1');

        expect(result.id, 'trip1');
        expect(result.tripName, tripData.tripName);
      });

      test('throws ServerException when trip not found', () {
        expect(
          () => repository.getTrip('group1', 'nonexistent'),
          throwsA(isA<ServerException>()),
        );
      });
    });

    group('getTripsStream', () {
      test('returns stream of all trips ordered by start date', () async {
        final trip1 = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
          startDate: DateTime(2025, 6, 1),
        );
        final trip2 = TestData.ongoingTrip.copyWith(
          id: 'trip2',
          groupId: 'group1',
          startDate: DateTime(2025, 5, 1),
        );

        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(trip1.toFirestore());
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip2')
            .set(trip2.toFirestore());

        final stream = repository.getTripsStream('group1');
        final trips = await stream.first;

        expect(trips.length, 2);
        expect(trips[0].id, 'trip1'); // Most recent first (descending)
        expect(trips[1].id, 'trip2');
      });
    });

    group('getUpcomingTrips', () {
      test('returns only future trips', () async {
        final futureTrip = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
          startDate: DateTime.now().add(Duration(days: 30)),
        );
        final pastTrip = TestData.completedTrip.copyWith(
          id: 'trip2',
          groupId: 'group1',
          startDate: DateTime.now().subtract(Duration(days: 30)),
        );

        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(futureTrip.toFirestore());
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip2')
            .set(pastTrip.toFirestore());

        final stream = repository.getUpcomingTrips('group1');
        final trips = await stream.first;

        expect(trips.length, 1);
        expect(trips[0].id, 'trip1');
      });
    });

    group('getPastTrips', () {
      test('returns only past trips', () async {
        final futureTrip = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
          endDate: DateTime.now().add(Duration(days: 30)),
        );
        final pastTrip = TestData.completedTrip.copyWith(
          id: 'trip2',
          groupId: 'group1',
          endDate: DateTime.now().subtract(Duration(days: 1)),
        );

        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(futureTrip.toFirestore());
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip2')
            .set(pastTrip.toFirestore());

        final stream = repository.getPastTrips('group1');
        final trips = await stream.first;

        expect(trips.length, 1);
        expect(trips[0].id, 'trip2');
      });
    });

    group('updateTrip', () {
      test('updates trip name successfully', () async {
        final tripData = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
        );
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(tripData.toFirestore());

        await repository.updateTrip(
          groupId: 'group1',
          tripId: 'trip1',
          tripName: 'Updated Trip Name',
        );

        final doc = await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .get();
        final updated = TripModel.fromFirestore(doc);

        expect(updated.tripName, 'Updated Trip Name');
      });

      test('updates location details', () async {
        final tripData = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
        );
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(tripData.toFirestore());

        await repository.updateTrip(
          groupId: 'group1',
          tripId: 'trip1',
          destination: 'New York',
          country: 'USA',
          countryCode: 'US',
          latitude: 40.7128,
          longitude: -74.0060,
        );

        final doc = await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .get();
        final updated = TripModel.fromFirestore(doc);

        expect(updated.location.destination, 'New York');
        expect(updated.location.country, 'USA');
        expect(updated.location.latitude, 40.7128);
      });

      test('updates status', () async {
        final tripData = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
          status: TripStatus.planning,
        );
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(tripData.toFirestore());

        await repository.updateTrip(
          groupId: 'group1',
          tripId: 'trip1',
          status: TripStatus.ongoing,
        );

        final doc = await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .get();
        final updated = TripModel.fromFirestore(doc);

        expect(updated.status, TripStatus.ongoing);
      });

      test('updates participant list', () async {
        final tripData = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
        );
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(tripData.toFirestore());

        await repository.updateTrip(
          groupId: 'group1',
          tripId: 'trip1',
          participantIds: ['user1', 'user2'],
        );

        final doc = await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .get();
        final updated = TripModel.fromFirestore(doc);

        expect(updated.participantIds, ['user1', 'user2']);
      });

      test('updates travel preferences successfully', () async {
        final tripData = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
        );
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(tripData.toFirestore());

        await repository.updateTrip(
          groupId: 'group1',
          tripId: 'trip1',
          adventurousness: 85,
          foodFocus: 95,
          urbanVsNature: 15,
          budgetFlexibility: 60,
          pacePreference: 75,
        );

        final doc = await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .get();
        final updated = TripModel.fromFirestore(doc);

        expect(updated.adventurousness, 85);
        expect(updated.foodFocus, 95);
        expect(updated.urbanVsNature, 15);
        expect(updated.budgetFlexibility, 60);
        expect(updated.pacePreference, 75);
      });

      test('updates only specified preferences, leaving others unchanged', () async {
        final tripData = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
          adventurousness: 70,
          foodFocus: 60,
          urbanVsNature: 40,
          budgetFlexibility: 55,
          pacePreference: 65,
        );
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(tripData.toFirestore());

        // Only update 2 preferences
        await repository.updateTrip(
          groupId: 'group1',
          tripId: 'trip1',
          adventurousness: 90,
          foodFocus: 80,
        );

        final doc = await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .get();
        final updated = TripModel.fromFirestore(doc);

        // Updated values
        expect(updated.adventurousness, 90);
        expect(updated.foodFocus, 80);
        // Unchanged values
        expect(updated.urbanVsNature, 40);
        expect(updated.budgetFlexibility, 55);
        expect(updated.pacePreference, 65);
      });
    });

    group('deleteTrip', () {
      test('organizer can delete trip', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final tripData = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
          organizerId: 'user1',
        );
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(tripData.toFirestore());

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        await repository.deleteTrip('group1', 'trip1');

        final doc = await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .get();
        expect(doc.exists, false);
      });

      test('admin can delete trip', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final tripData = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
          organizerId: 'user2', // Different organizer
        );
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(tripData.toFirestore());

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        await repository.deleteTrip('group1', 'trip1');

        final doc = await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .get();
        expect(doc.exists, false);
      });

      test('throws AuthException when non-admin non-organizer tries to delete', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user3'); // Regular member
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final tripData = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
          organizerId: 'user2',
        );
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(tripData.toFirestore());

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        expect(
          () => repository.deleteTrip('group1', 'trip1'),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws AuthException when user not authenticated', () {
        MockAuthHelper.setupMockAuthWithoutUser(mockAuth);

        expect(
          () => repository.deleteTrip('group1', 'trip1'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('addMedia', () {
      test('adds media to trip successfully', () async {
        final tripData = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
          media: [],
        );
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(tripData.toFirestore());

        final newMedia = TripMedia(
          id: 'media1',
          url: 'https://example.com/photo.jpg',
          type: 'photo',
          uploadedBy: 'user1',
          uploadedAt: DateTime.now(),
        );

        await repository.addMedia('group1', 'trip1', newMedia);

        final doc = await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .get();
        final updated = TripModel.fromFirestore(doc);

        expect(updated.media.length, 1);
        expect(updated.media[0].url, 'https://example.com/photo.jpg');
        expect(updated.media[0].type, 'photo');
      });
    });

    group('removeMedia', () {
      test('removes media from trip successfully', () async {
        final mediaToRemove = TripMedia(
          id: 'media1',
          url: 'https://example.com/photo.jpg',
          type: 'photo',
          uploadedBy: 'user1',
          uploadedAt: DateTime(2025, 1, 1),
        );

        final tripData = TestData.upcomingTrip.copyWith(
          id: 'trip1',
          groupId: 'group1',
          media: [mediaToRemove],
        );
        await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .set(tripData.toFirestore());

        await repository.removeMedia('group1', 'trip1', mediaToRemove);

        final doc = await fakeFirestore
            .collection('groups')
            .doc('group1')
            .collection('trips')
            .doc('trip1')
            .get();
        final updated = TripModel.fromFirestore(doc);

        expect(updated.media.length, 0);
      });
    });
  });
}
