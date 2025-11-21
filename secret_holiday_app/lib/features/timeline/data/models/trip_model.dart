import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'trip_model.g.dart';

/// Trip status based on dates
enum TripStatus {
  planning,   // Before start date
  ongoing,    // Between start and end date
  completed,  // After end date
  cancelled,  // Manually cancelled
}

@JsonSerializable(explicitToJson: true)
class ItineraryDay extends Equatable {
  final int dayNumber;
  final String description;
  final List<String> activities;
  final List<String>? photoUrls;
  
  const ItineraryDay({
    required this.dayNumber,
    required this.description,
    this.activities = const [],
    this.photoUrls,
  });
  
  factory ItineraryDay.fromJson(Map<String, dynamic> json) =>
      _$ItineraryDayFromJson(json);
  
  Map<String, dynamic> toJson() => _$ItineraryDayToJson(this);
  
  @override
  List<Object?> get props => [dayNumber, description, activities, photoUrls];
}

@JsonSerializable(explicitToJson: true)
class TripLocation extends Equatable {
  final String destination; // City or region name
  final String country;
  final String countryCode;
  final double latitude;
  final double longitude;
  
  const TripLocation({
    required this.destination,
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
  });
  
  factory TripLocation.fromJson(Map<String, dynamic> json) =>
      _$TripLocationFromJson(json);
  
  Map<String, dynamic> toJson() => _$TripLocationToJson(this);
  
  @override
  List<Object?> get props => [destination, country, countryCode, latitude, longitude];
}

@JsonSerializable(explicitToJson: true)
class TripMedia extends Equatable {
  final String id;
  final String url;
  final String type; // 'photo' or 'video'
  final String uploadedBy;
  final String? caption;
  final String? thumbnailUrl; // For videos
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime uploadedAt;
  
  const TripMedia({
    required this.id,
    required this.url,
    required this.type,
    required this.uploadedBy,
    this.caption,
    this.thumbnailUrl,
    required this.uploadedAt,
  });
  
  factory TripMedia.fromJson(Map<String, dynamic> json) =>
      _$TripMediaFromJson(json);
  
  Map<String, dynamic> toJson() => _$TripMediaToJson(this);
  
  @override
  List<Object?> get props => [id, url, type, uploadedBy, caption, thumbnailUrl, uploadedAt];
  
  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.parse(timestamp as String);
  }
  
  static dynamic _timestampToJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}

@JsonSerializable(explicitToJson: true)
class TripModel extends Equatable {
  final String id;
  final String groupId;
  final int year;
  final String tripName; // Optional friendly name
  final TripLocation location;
  final String organizerId;
  final String organizerName;
  
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime startDate;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime endDate;
  
  final String summary; // Overall trip description
  final List<ItineraryDay> itinerary;
  final List<TripMedia> media;
  
  final String? coverPhotoUrl;
  final int totalCost; // Total group cost
  final int costPerPerson;
  
  // New fields for Sprint 4 completion
  @JsonKey(unknownEnumValue: TripStatus.planning)
  final TripStatus status;
  final List<String> participantIds; // Group member IDs participating in this trip
  
  // Trip preferences (0-100 scale) - moved from GroupModel
  final int adventurousness; // 0=relaxing, 100=adventurous
  final int foodFocus; // 0=not important, 100=foodie
  final int urbanVsNature; // 0=nature, 100=urban
  final int budgetFlexibility; // 0=strict, 100=flexible
  final int pacePreference; // 0=slow/relaxed, 100=fast-paced
  
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;
  
  const TripModel({
    required this.id,
    required this.groupId,
    required this.year,
    required this.tripName,
    required this.location,
    required this.organizerId,
    required this.organizerName,
    required this.startDate,
    required this.endDate,
    required this.summary,
    this.itinerary = const [],
    this.media = const [],
    this.coverPhotoUrl,
    required this.totalCost,
    required this.costPerPerson,
    this.status = TripStatus.planning,
    this.participantIds = const [],
    this.adventurousness = 50,
    this.foodFocus = 50,
    this.urbanVsNature = 50,
    this.budgetFlexibility = 50,
    this.pacePreference = 50,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory TripModel.fromJson(Map<String, dynamic> json) =>
      _$TripModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$TripModelToJson(this);
  
  factory TripModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TripModel.fromJson({...data, 'id': doc.id});
  }
  
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }
  
  int get durationDays => endDate.difference(startDate).inDays + 1;
  
  /// Returns the current status based on dates (unless manually cancelled)
  TripStatus get currentStatus {
    if (status == TripStatus.cancelled) return TripStatus.cancelled;
    final now = DateTime.now();
    if (now.isBefore(startDate)) return TripStatus.planning;
    if (now.isAfter(endDate)) return TripStatus.completed;
    return TripStatus.ongoing;
  }
  
  TripModel copyWith({
    String? id,
    String? groupId,
    int? year,
    String? tripName,
    TripLocation? location,
    String? organizerId,
    String? organizerName,
    DateTime? startDate,
    DateTime? endDate,
    String? summary,
    List<ItineraryDay>? itinerary,
    List<TripMedia>? media,
    String? coverPhotoUrl,
    int? totalCost,
    int? costPerPerson,
    TripStatus? status,
    List<String>? participantIds,
    int? adventurousness,
    int? foodFocus,
    int? urbanVsNature,
    int? budgetFlexibility,
    int? pacePreference,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TripModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      year: year ?? this.year,
      tripName: tripName ?? this.tripName,
      location: location ?? this.location,
      organizerId: organizerId ?? this.organizerId,
      organizerName: organizerName ?? this.organizerName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      summary: summary ?? this.summary,
      itinerary: itinerary ?? this.itinerary,
      media: media ?? this.media,
      coverPhotoUrl: coverPhotoUrl ?? this.coverPhotoUrl,
      totalCost: totalCost ?? this.totalCost,
      costPerPerson: costPerPerson ?? this.costPerPerson,
      status: status ?? this.status,
      participantIds: participantIds ?? this.participantIds,
      adventurousness: adventurousness ?? this.adventurousness,
      foodFocus: foodFocus ?? this.foodFocus,
      urbanVsNature: urbanVsNature ?? this.urbanVsNature,
      budgetFlexibility: budgetFlexibility ?? this.budgetFlexibility,
      pacePreference: pacePreference ?? this.pacePreference,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        groupId,
        year,
        tripName,
        location,
        organizerId,
        organizerName,
        startDate,
        endDate,
        summary,
        itinerary,
        media,
        coverPhotoUrl,
        totalCost,
        costPerPerson,
        status,
        participantIds,
        adventurousness,
        foodFocus,
        urbanVsNature,
        budgetFlexibility,
        pacePreference,
        createdAt,
        updatedAt,
      ];
  
  static DateTime _timestampFromJson(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return timestamp.toDate();
    }
    return DateTime.parse(timestamp as String);
  }
  
  static dynamic _timestampToJson(DateTime dateTime) {
    return Timestamp.fromDate(dateTime);
  }
}
