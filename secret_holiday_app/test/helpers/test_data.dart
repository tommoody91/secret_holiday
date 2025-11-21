import 'package:secret_holiday_app/features/timeline/data/models/trip_model.dart';
import 'package:secret_holiday_app/features/groups/data/models/group_model.dart';

/// Test data fixtures for unit and integration tests
class TestData {
  // Fixed dates for consistent testing
  static final DateTime baseDate = DateTime(2025, 1, 1);
  static final DateTime pastDate = DateTime(2024, 6, 1);
  static final DateTime futureDate = DateTime(2026, 6, 1);
  static final DateTime now = DateTime.now();

  // Sample Trip Location
  static const TripLocation parisLocation = TripLocation(
    destination: 'Paris',
    country: 'France',
    countryCode: 'FR',
    latitude: 48.8566,
    longitude: 2.3522,
  );

  static const TripLocation tokyoLocation = TripLocation(
    destination: 'Tokyo',
    country: 'Japan',
    countryCode: 'JP',
    latitude: 35.6762,
    longitude: 139.6503,
  );

  // Sample Itinerary Day
  static const ItineraryDay day1 = ItineraryDay(
    dayNumber: 1,
    description: 'Arrival and Eiffel Tower visit',
    activities: ['Airport transfer', 'Hotel check-in', 'Eiffel Tower'],
  );

  static const ItineraryDay day2 = ItineraryDay(
    dayNumber: 2,
    description: 'Louvre Museum and Seine River cruise',
    activities: ['Louvre Museum', 'Lunch at café', 'Seine River cruise'],
  );

  // Sample Trip Media
  static TripMedia photoMedia = TripMedia(
    id: 'media1',
    url: 'https://example.com/photo.jpg',
    type: 'photo',
    uploadedBy: 'user1',
    caption: 'Beautiful view from Eiffel Tower',
    uploadedAt: baseDate,
  );

  static TripMedia videoMedia = TripMedia(
    id: 'media2',
    url: 'https://example.com/video.mp4',
    type: 'video',
    uploadedBy: 'user2',
    thumbnailUrl: 'https://example.com/thumb.jpg',
    uploadedAt: baseDate.add(Duration(hours: 2)),
  );

  // Sample Trips
  static TripModel upcomingTrip = TripModel(
    id: 'trip1',
    groupId: 'group1',
    year: futureDate.year,
    tripName: 'Paris Adventure 2026',
    location: parisLocation,
    organizerId: 'user1',
    organizerName: 'John Doe',
    startDate: futureDate,
    endDate: futureDate.add(Duration(days: 6)),
    summary: 'A week exploring the beautiful city of Paris',
    itinerary: [day1, day2],
    media: [],
    coverPhotoUrl: 'https://example.com/paris-cover.jpg',
    totalCost: 5000,
    costPerPerson: 1000,
    status: TripStatus.planning,
    participantIds: ['user1', 'user2', 'user3'],
    createdAt: baseDate,
    updatedAt: baseDate,
  );

  static TripModel ongoingTrip = TripModel(
    id: 'trip2',
    groupId: 'group1',
    year: now.year,
    tripName: 'Tokyo Experience',
    location: tokyoLocation,
    organizerId: 'user2',
    organizerName: 'Jane Smith',
    startDate: now.subtract(Duration(days: 2)),
    endDate: now.add(Duration(days: 3)),
    summary: 'Exploring modern and traditional Tokyo',
    itinerary: [],
    media: [photoMedia, videoMedia],
    totalCost: 8000,
    costPerPerson: 2000,
    status: TripStatus.ongoing,
    participantIds: ['user1', 'user2'],
    createdAt: baseDate.subtract(Duration(days: 30)),
    updatedAt: now.subtract(Duration(days: 2)),
  );

  static TripModel completedTrip = TripModel(
    id: 'trip3',
    groupId: 'group1',
    year: pastDate.year,
    tripName: 'Barcelona Summer',
    location: TripLocation(
      destination: 'Barcelona',
      country: 'Spain',
      countryCode: 'ES',
      latitude: 41.3851,
      longitude: 2.1734,
    ),
    organizerId: 'user3',
    organizerName: 'Bob Johnson',
    startDate: pastDate,
    endDate: pastDate.add(Duration(days: 4)),
    summary: 'Summer holiday in Barcelona',
    itinerary: [],
    media: [photoMedia],
    totalCost: 3000,
    costPerPerson: 750,
    status: TripStatus.completed,
    participantIds: ['user1', 'user2', 'user3', 'user4'],
    createdAt: pastDate.subtract(Duration(days: 60)),
    updatedAt: pastDate.add(Duration(days: 5)),
  );

  static TripModel cancelledTrip = TripModel(
    id: 'trip4',
    groupId: 'group2',
    year: futureDate.year,
    tripName: 'Cancelled Trip',
    location: parisLocation,
    organizerId: 'user1',
    organizerName: 'John Doe',
    startDate: futureDate.add(Duration(days: 30)),
    endDate: futureDate.add(Duration(days: 35)),
    summary: 'This trip was cancelled',
    totalCost: 4000,
    costPerPerson: 1000,
    status: TripStatus.cancelled,
    participantIds: ['user1', 'user2'],
    createdAt: baseDate,
    updatedAt: baseDate.add(Duration(days: 1)),
  );

  // Sample Group Rules
  static const GroupRules defaultRules = GroupRules(
    budgetPerPerson: 1000,
    maxTripDays: 7,
    luggageAllowance: 'One checked bag + carry-on',
    noRepeatCountries: true,
    customRules: ['No work talk', 'Everyone takes turns cooking'],
  );

  static const GroupRules flexibleRules = GroupRules(
    budgetPerPerson: 2000,
    maxTripDays: 14,
    luggageAllowance: 'Two checked bags + carry-on',
    noRepeatCountries: false,
    customRules: [],
  );

  // Sample Group Members
  static GroupMember adminMember = GroupMember(
    userId: 'user1',
    name: 'John Doe',
    profilePictureUrl: 'https://example.com/john.jpg',
    role: 'admin',
    yearLastOrganized: 2024,
    joinedAt: baseDate.subtract(Duration(days: 365)),
  );

  static GroupMember regularMember = GroupMember(
    userId: 'user2',
    name: 'Jane Smith',
    role: 'member',
    joinedAt: baseDate.subtract(Duration(days: 300)),
  );

  static GroupMember newMember = GroupMember(
    userId: 'user3',
    name: 'Bob Johnson',
    role: 'member',
    joinedAt: baseDate.subtract(Duration(days: 30)),
  );

  // Sample Groups
  static GroupModel activeGroup = GroupModel(
    id: 'group1',
    name: 'Adventure Squad',
    createdBy: 'user1',
    currentOrganizerId: 'user2',
    members: [adminMember, regularMember, newMember],
    memberIds: ['user1', 'user2', 'user3'],
    rules: defaultRules,
    inviteCode: 'SQUAD2025',
    upcomingTripStartDate: futureDate,
    upcomingTripEndDate: futureDate.add(Duration(days: 6)),
    createdAt: baseDate.subtract(Duration(days: 365)),
    updatedAt: baseDate,
  );

  static GroupModel newGroup = GroupModel(
    id: 'group2',
    name: 'Travel Buddies',
    createdBy: 'user4',
    members: [
      GroupMember(
        userId: 'user4',
        name: 'Alice Williams',
        role: 'admin',
        joinedAt: baseDate,
      ),
    ],
    memberIds: ['user4'],
    rules: flexibleRules,
    inviteCode: 'BUDDIES2025',
    createdAt: baseDate,
    updatedAt: baseDate,
  );

  static GroupModel largeGroup = GroupModel(
    id: 'group3',
    name: 'Big Family Trip',
    createdBy: 'user1',
    currentOrganizerId: 'user1',
    members: [
      adminMember,
      regularMember,
      newMember,
      GroupMember(userId: 'user4', name: 'User 4', role: 'member', joinedAt: baseDate),
      GroupMember(userId: 'user5', name: 'User 5', role: 'member', joinedAt: baseDate),
    ],
    memberIds: ['user1', 'user2', 'user3', 'user4', 'user5'],
    rules: defaultRules,
    inviteCode: 'FAMILY2025',
    createdAt: baseDate.subtract(Duration(days: 730)),
    updatedAt: baseDate.subtract(Duration(days: 100)),
  );
}
