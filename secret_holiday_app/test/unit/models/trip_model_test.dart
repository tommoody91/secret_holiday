import 'package:flutter_test/flutter_test.dart';
import 'package:secret_holiday_app/features/timeline/data/models/trip_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('TripModel', () {
    group('JSON Serialization', () {
      test('toJson converts model to JSON correctly', () {
        final trip = TestData.upcomingTrip;
        final json = trip.toJson();

        expect(json['id'], trip.id);
        expect(json['tripName'], trip.tripName);
        expect(json['groupId'], trip.groupId);
        expect(json['year'], trip.year);
        expect(json['summary'], trip.summary);
        expect(json['totalCost'], trip.totalCost);
        expect(json['costPerPerson'], trip.costPerPerson);
        expect(json['organizerId'], trip.organizerId);
        expect(json['organizerName'], trip.organizerName);
        expect(json['status'], trip.status.name);
        expect(json['participantIds'], trip.participantIds);
        
        // Check nested location object
        expect(json['location'], isNotNull);
        expect(json['location']['destination'], trip.location.destination);
        expect(json['location']['country'], trip.location.country);
        expect(json['location']['latitude'], trip.location.latitude);
        expect(json['location']['longitude'], trip.location.longitude);
        
        // Check itinerary
        expect(json['itinerary'], isA<List>());
        expect(json['itinerary'].length, trip.itinerary.length);
      });

      test('fromJson creates model from JSON correctly', () {
        final originalTrip = TestData.upcomingTrip;
        final json = originalTrip.toJson();
        final decodedTrip = TripModel.fromJson(json);

        expect(decodedTrip.id, originalTrip.id);
        expect(decodedTrip.tripName, originalTrip.tripName);
        expect(decodedTrip.groupId, originalTrip.groupId);
        expect(decodedTrip.year, originalTrip.year);
        expect(decodedTrip.location.destination, originalTrip.location.destination);
        expect(decodedTrip.location.country, originalTrip.location.country);
        expect(decodedTrip.startDate, originalTrip.startDate);
        expect(decodedTrip.endDate, originalTrip.endDate);
        expect(decodedTrip.summary, originalTrip.summary);
        expect(decodedTrip.totalCost, originalTrip.totalCost);
        expect(decodedTrip.costPerPerson, originalTrip.costPerPerson);
        expect(decodedTrip.status, originalTrip.status);
        expect(decodedTrip.participantIds, originalTrip.participantIds);
        expect(decodedTrip.itinerary.length, originalTrip.itinerary.length);
      });

      test('JSON roundtrip preserves all data', () {
        final originalTrip = TestData.ongoingTrip;
        final json = originalTrip.toJson();
        final decodedTrip = TripModel.fromJson(json);

        expect(decodedTrip, equals(originalTrip));
      });

      test('handles trips with media correctly', () {
        final tripWithMedia = TestData.ongoingTrip;
        expect(tripWithMedia.media.length, 2);
        
        final json = tripWithMedia.toJson();
        final decodedTrip = TripModel.fromJson(json);

        expect(decodedTrip.media.length, 2);
        expect(decodedTrip.media[0].id, tripWithMedia.media[0].id);
        expect(decodedTrip.media[0].url, tripWithMedia.media[0].url);
        expect(decodedTrip.media[0].type, tripWithMedia.media[0].type);
        expect(decodedTrip.media[1].thumbnailUrl, tripWithMedia.media[1].thumbnailUrl);
      });

      test('handles trips without optional fields', () {
        // Create a trip with minimal required fields (no coverPhotoUrl)
        final minimalTrip = TripModel(
          id: 'minimal-trip',
          groupId: 'group1',
          year: 2026,
          tripName: 'Minimal Trip',
          location: TestData.parisLocation,
          organizerId: 'user1',
          organizerName: 'John Doe',
          startDate: TestData.futureDate,
          endDate: TestData.futureDate.add(Duration(days: 3)),
          summary: 'A simple trip',
          itinerary: [],
          media: [],
          coverPhotoUrl: null, // Optional field is null
          totalCost: 1000,
          costPerPerson: 500,
          status: TripStatus.planning,
          participantIds: ['user1'],
          createdAt: TestData.baseDate,
          updatedAt: TestData.baseDate,
        );

        final json = minimalTrip.toJson();
        final decodedTrip = TripModel.fromJson(json);

        expect(decodedTrip.coverPhotoUrl, isNull);
        expect(decodedTrip.itinerary, isEmpty);
        expect(decodedTrip.media, isEmpty);
      });
    });

    group('Computed Properties', () {
      test('durationDays calculates correctly for 7-day trip', () {
        final trip = TestData.upcomingTrip;
        expect(trip.durationDays, 7);
      });

      test('durationDays calculates correctly for single-day trip', () {
        final oneDayTrip = TestData.upcomingTrip.copyWith(
          endDate: TestData.upcomingTrip.startDate,
        );
        expect(oneDayTrip.durationDays, 1);
      });

      test('currentStatus returns planning for future trips', () {
        final futureTrip = TripModel(
          id: 'test',
          groupId: 'group1',
          year: 2026,
          tripName: 'Future Trip',
          location: TestData.parisLocation,
          organizerId: 'user1',
          organizerName: 'John',
          startDate: DateTime.now().add(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 37)),
          summary: 'A future trip',
          totalCost: 5000,
          costPerPerson: 1000,
          status: TripStatus.planning,
          participantIds: ['user1'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(futureTrip.currentStatus, TripStatus.planning);
      });

      test('currentStatus returns ongoing for current trips', () {
        final ongoingTrip = TripModel(
          id: 'test',
          groupId: 'group1',
          year: DateTime.now().year,
          tripName: 'Current Trip',
          location: TestData.parisLocation,
          organizerId: 'user1',
          organizerName: 'John',
          startDate: DateTime.now().subtract(Duration(days: 2)),
          endDate: DateTime.now().add(Duration(days: 3)),
          summary: 'An ongoing trip',
          totalCost: 5000,
          costPerPerson: 1000,
          status: TripStatus.ongoing,
          participantIds: ['user1'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(ongoingTrip.currentStatus, TripStatus.ongoing);
      });

      test('currentStatus returns completed for past trips', () {
        final pastTrip = TripModel(
          id: 'test',
          groupId: 'group1',
          year: 2024,
          tripName: 'Past Trip',
          location: TestData.parisLocation,
          organizerId: 'user1',
          organizerName: 'John',
          startDate: DateTime.now().subtract(Duration(days: 30)),
          endDate: DateTime.now().subtract(Duration(days: 23)),
          summary: 'A completed trip',
          totalCost: 5000,
          costPerPerson: 1000,
          status: TripStatus.completed,
          participantIds: ['user1'],
          createdAt: DateTime.now().subtract(Duration(days: 60)),
          updatedAt: DateTime.now().subtract(Duration(days: 22)),
        );

        expect(pastTrip.currentStatus, TripStatus.completed);
      });

      test('currentStatus returns cancelled regardless of dates', () {
        final cancelledFutureTrip = TripModel(
          id: 'test',
          groupId: 'group1',
          year: 2026,
          tripName: 'Cancelled Trip',
          location: TestData.parisLocation,
          organizerId: 'user1',
          organizerName: 'John',
          startDate: DateTime.now().add(Duration(days: 30)),
          endDate: DateTime.now().add(Duration(days: 37)),
          summary: 'A cancelled trip',
          totalCost: 5000,
          costPerPerson: 1000,
          status: TripStatus.cancelled,
          participantIds: ['user1'],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(cancelledFutureTrip.currentStatus, TripStatus.cancelled);
      });
    });

    group('copyWith', () {
      test('creates new instance with updated tripName', () {
        final original = TestData.upcomingTrip;
        final updated = original.copyWith(tripName: 'New Trip Name');

        expect(updated.tripName, 'New Trip Name');
        expect(updated.id, original.id);
        expect(updated.groupId, original.groupId);
        expect(original.tripName, 'Paris Adventure 2026'); // Original unchanged
      });

      test('creates new instance with updated status', () {
        final original = TestData.upcomingTrip;
        final updated = original.copyWith(status: TripStatus.cancelled);

        expect(updated.status, TripStatus.cancelled);
        expect(original.status, TripStatus.planning);
      });

      test('creates new instance with updated participantIds', () {
        final original = TestData.upcomingTrip;
        final updated = original.copyWith(
          participantIds: ['user1', 'user2', 'user3', 'user4'],
        );

        expect(updated.participantIds.length, 4);
        expect(original.participantIds.length, 3);
      });

      test('creates new instance with updated dates', () {
        final original = TestData.upcomingTrip;
        final newStartDate = DateTime(2027, 1, 1);
        final newEndDate = DateTime(2027, 1, 10);
        final updated = original.copyWith(
          startDate: newStartDate,
          endDate: newEndDate,
        );

        expect(updated.startDate, newStartDate);
        expect(updated.endDate, newEndDate);
        expect(updated.durationDays, 10);
        expect(original.startDate, isNot(newStartDate));
      });

      test('creates new instance with updated location', () {
        final original = TestData.upcomingTrip;
        final updated = original.copyWith(location: TestData.tokyoLocation);

        expect(updated.location.destination, 'Tokyo');
        expect(updated.location.country, 'Japan');
        expect(original.location.destination, 'Paris');
      });

      test('creates new instance with updated media', () {
        final original = TestData.upcomingTrip;
        final newMedia = [TestData.photoMedia, TestData.videoMedia];
        final updated = original.copyWith(media: newMedia);

        expect(updated.media.length, 2);
        expect(original.media.length, 0);
      });

      test('returns identical instance when no parameters provided', () {
        final original = TestData.upcomingTrip;
        final updated = original.copyWith();

        expect(updated, equals(original));
      });
    });

    group('Equality', () {
      test('two trips with same data are equal', () {
        final trip1 = TestData.upcomingTrip;
        final trip2 = TripModel.fromJson(trip1.toJson());

        expect(trip1, equals(trip2));
      });

      test('two trips with different IDs are not equal', () {
        final trip1 = TestData.upcomingTrip;
        final trip2 = trip1.copyWith(id: 'different_id');

        expect(trip1, isNot(equals(trip2)));
      });

      test('two trips with different names are not equal', () {
        final trip1 = TestData.upcomingTrip;
        final trip2 = trip1.copyWith(tripName: 'Different Name');

        expect(trip1, isNot(equals(trip2)));
      });
    });

    group('TripLocation', () {
      test('serializes and deserializes correctly', () {
        final location = TestData.parisLocation;
        final json = location.toJson();
        final decoded = TripLocation.fromJson(json);

        expect(decoded.destination, location.destination);
        expect(decoded.country, location.country);
        expect(decoded.countryCode, location.countryCode);
        expect(decoded.latitude, location.latitude);
        expect(decoded.longitude, location.longitude);
      });
    });

    group('ItineraryDay', () {
      test('serializes and deserializes correctly', () {
        final day = TestData.day1;
        final json = day.toJson();
        final decoded = ItineraryDay.fromJson(json);

        expect(decoded.dayNumber, day.dayNumber);
        expect(decoded.description, day.description);
        expect(decoded.activities, day.activities);
      });

      test('handles optional photoUrls', () {
        final dayWithPhotos = ItineraryDay(
          dayNumber: 1,
          description: 'Day with photos',
          activities: ['Activity 1'],
          photoUrls: ['url1', 'url2'],
        );

        final json = dayWithPhotos.toJson();
        final decoded = ItineraryDay.fromJson(json);

        expect(decoded.photoUrls, isNotNull);
        expect(decoded.photoUrls!.length, 2);
      });
    });

    group('TripMedia', () {
      test('serializes and deserializes photo correctly', () {
        final photo = TestData.photoMedia;
        final json = photo.toJson();
        final decoded = TripMedia.fromJson(json);

        expect(decoded.id, photo.id);
        expect(decoded.url, photo.url);
        expect(decoded.type, photo.type);
        expect(decoded.uploadedBy, photo.uploadedBy);
        expect(decoded.caption, photo.caption);
      });

      test('serializes and deserializes video with thumbnail', () {
        final video = TestData.videoMedia;
        final json = video.toJson();
        final decoded = TripMedia.fromJson(json);

        expect(decoded.id, video.id);
        expect(decoded.type, 'video');
        expect(decoded.thumbnailUrl, video.thumbnailUrl);
      });
    });

    group('Travel Preferences', () {
      test('defaults all preference values to 50 when not provided', () {
        final trip = TripModel(
          id: 'test-trip',
          tripName: 'Test Trip',
          groupId: 'group1',
          year: 2025,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: 7)),
          location: TestData.parisLocation,
          organizerId: 'user1',
          organizerName: 'John',
          participantIds: ['user1'],
          itinerary: [],
          status: TripStatus.planning,
          summary: 'A test trip',
          totalCost: 1000,
          costPerPerson: 500,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(trip.adventurousness, 50);
        expect(trip.foodFocus, 50);
        expect(trip.urbanVsNature, 50);
        expect(trip.budgetFlexibility, 50);
        expect(trip.pacePreference, 50);
      });

      test('accepts custom preference values', () {
        final trip = TripModel(
          id: 'test-trip',
          tripName: 'Adventure Trip',
          groupId: 'group1',
          year: 2025,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: 7)),
          location: TestData.parisLocation,
          organizerId: 'user1',
          organizerName: 'John',
          participantIds: ['user1'],
          itinerary: [],
          status: TripStatus.planning,
          summary: 'An adventure trip',
          totalCost: 2000,
          costPerPerson: 1000,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          adventurousness: 90,
          foodFocus: 70,
          urbanVsNature: 30,
          budgetFlexibility: 60,
          pacePreference: 80,
        );

        expect(trip.adventurousness, 90);
        expect(trip.foodFocus, 70);
        expect(trip.urbanVsNature, 30);
        expect(trip.budgetFlexibility, 60);
        expect(trip.pacePreference, 80);
      });

      test('serializes preferences to JSON correctly', () {
        final trip = TripModel(
          id: 'test-trip',
          tripName: 'Test Trip',
          groupId: 'group1',
          year: 2025,
          startDate: DateTime.now(),
          endDate: DateTime.now().add(Duration(days: 7)),
          location: TestData.parisLocation,
          organizerId: 'user1',
          organizerName: 'John',
          participantIds: ['user1'],
          itinerary: [],
          status: TripStatus.planning,
          summary: 'A test trip',
          totalCost: 1500,
          costPerPerson: 750,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          adventurousness: 75,
          foodFocus: 85,
          urbanVsNature: 40,
          budgetFlexibility: 55,
          pacePreference: 65,
        );

        final json = trip.toJson();

        expect(json['adventurousness'], 75);
        expect(json['foodFocus'], 85);
        expect(json['urbanVsNature'], 40);
        expect(json['budgetFlexibility'], 55);
        expect(json['pacePreference'], 65);
      });

      test('deserializes preferences from JSON correctly', () {
        final json = {
          'id': 'test-trip',
          'tripName': 'Test Trip',
          'groupId': 'group1',
          'year': 2025,
          'startDate': DateTime.now().toIso8601String(),
          'endDate': DateTime.now().add(Duration(days: 7)).toIso8601String(),
          'location': {
            'destination': 'Paris',
            'country': 'France',
            'countryCode': 'FR',
            'latitude': 48.8566,
            'longitude': 2.3522,
          },
          'organizerId': 'user1',
          'organizerName': 'John',
          'participantIds': ['user1'],
          'itinerary': [],
          'status': 'planning',
          'summary': 'Test summary',
          'totalCost': 1000.0,
          'costPerPerson': 500.0,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
          'adventurousness': 95,
          'foodFocus': 80,
          'urbanVsNature': 20,
          'budgetFlexibility': 70,
          'pacePreference': 90,
        };

        final trip = TripModel.fromJson(json);

        expect(trip.adventurousness, 95);
        expect(trip.foodFocus, 80);
        expect(trip.urbanVsNature, 20);
        expect(trip.budgetFlexibility, 70);
        expect(trip.pacePreference, 90);
      });

      test('copyWith updates preferences correctly', () {
        final original = TestData.upcomingTrip;
        
        final updated = original.copyWith(
          adventurousness: 100,
          foodFocus: 90,
          urbanVsNature: 10,
          budgetFlexibility: 80,
          pacePreference: 95,
        );

        expect(updated.adventurousness, 100);
        expect(updated.foodFocus, 90);
        expect(updated.urbanVsNature, 10);
        expect(updated.budgetFlexibility, 80);
        expect(updated.pacePreference, 95);
        
        // Original should be unchanged
        expect(original.adventurousness, 50); // default value
        expect(original.foodFocus, 50);
      });

      test('preferences are included in equality comparison', () {
        final trip1 = TestData.upcomingTrip.copyWith(adventurousness: 70);
        final trip2 = TestData.upcomingTrip.copyWith(adventurousness: 80);

        expect(trip1, isNot(equals(trip2)));
      });
    });
  });
}
