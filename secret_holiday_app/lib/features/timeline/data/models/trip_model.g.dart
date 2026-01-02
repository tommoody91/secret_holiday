// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItineraryDay _$ItineraryDayFromJson(Map<String, dynamic> json) => ItineraryDay(
  dayNumber: (json['dayNumber'] as num).toInt(),
  description: json['description'] as String,
  activities:
      (json['activities'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  photoUrls: (json['photoUrls'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$ItineraryDayToJson(ItineraryDay instance) =>
    <String, dynamic>{
      'dayNumber': instance.dayNumber,
      'description': instance.description,
      'activities': instance.activities,
      'photoUrls': instance.photoUrls,
    };

TripLocation _$TripLocationFromJson(Map<String, dynamic> json) => TripLocation(
  destination: json['destination'] as String,
  country: json['country'] as String,
  countryCode: json['countryCode'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
);

Map<String, dynamic> _$TripLocationToJson(TripLocation instance) =>
    <String, dynamic>{
      'destination': instance.destination,
      'country': instance.country,
      'countryCode': instance.countryCode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };

TripMedia _$TripMediaFromJson(Map<String, dynamic> json) => TripMedia(
  id: json['id'] as String,
  url: json['url'] as String,
  type: json['type'] as String,
  uploadedBy: json['uploadedBy'] as String,
  caption: json['caption'] as String?,
  thumbnailUrl: json['thumbnailUrl'] as String?,
  dayNumber: (json['dayNumber'] as num?)?.toInt(),
  activityId: json['activityId'] as String?,
  uploadedAt: TripMedia._timestampFromJson(json['uploadedAt']),
);

Map<String, dynamic> _$TripMediaToJson(TripMedia instance) => <String, dynamic>{
  'id': instance.id,
  'url': instance.url,
  'type': instance.type,
  'uploadedBy': instance.uploadedBy,
  'caption': instance.caption,
  'thumbnailUrl': instance.thumbnailUrl,
  'dayNumber': instance.dayNumber,
  'activityId': instance.activityId,
  'uploadedAt': TripMedia._timestampToJson(instance.uploadedAt),
};

TripModel _$TripModelFromJson(Map<String, dynamic> json) => TripModel(
  id: json['id'] as String,
  groupId: json['groupId'] as String,
  year: (json['year'] as num).toInt(),
  tripName: json['tripName'] as String,
  location: TripLocation.fromJson(json['location'] as Map<String, dynamic>),
  organizerId: json['organizerId'] as String,
  organizerName: json['organizerName'] as String,
  startDate: TripModel._timestampFromJson(json['startDate']),
  endDate: TripModel._timestampFromJson(json['endDate']),
  summary: json['summary'] as String,
  itinerary:
      (json['itinerary'] as List<dynamic>?)
          ?.map((e) => ItineraryDay.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  media:
      (json['media'] as List<dynamic>?)
          ?.map((e) => TripMedia.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  coverPhotoUrl: json['coverPhotoUrl'] as String?,
  totalCost: (json['totalCost'] as num).toInt(),
  costPerPerson: (json['costPerPerson'] as num).toInt(),
  status:
      $enumDecodeNullable(
        _$TripStatusEnumMap,
        json['status'],
        unknownValue: TripStatus.planning,
      ) ??
      TripStatus.planning,
  participantIds:
      (json['participantIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  adventurousness: (json['adventurousness'] as num?)?.toInt() ?? 50,
  foodFocus: (json['foodFocus'] as num?)?.toInt() ?? 50,
  urbanVsNature: (json['urbanVsNature'] as num?)?.toInt() ?? 50,
  budgetFlexibility: (json['budgetFlexibility'] as num?)?.toInt() ?? 50,
  pacePreference: (json['pacePreference'] as num?)?.toInt() ?? 50,
  createdAt: TripModel._timestampFromJson(json['createdAt']),
  updatedAt: TripModel._timestampFromJson(json['updatedAt']),
);

Map<String, dynamic> _$TripModelToJson(TripModel instance) => <String, dynamic>{
  'id': instance.id,
  'groupId': instance.groupId,
  'year': instance.year,
  'tripName': instance.tripName,
  'location': instance.location.toJson(),
  'organizerId': instance.organizerId,
  'organizerName': instance.organizerName,
  'startDate': TripModel._timestampToJson(instance.startDate),
  'endDate': TripModel._timestampToJson(instance.endDate),
  'summary': instance.summary,
  'itinerary': instance.itinerary.map((e) => e.toJson()).toList(),
  'media': instance.media.map((e) => e.toJson()).toList(),
  'coverPhotoUrl': instance.coverPhotoUrl,
  'totalCost': instance.totalCost,
  'costPerPerson': instance.costPerPerson,
  'status': _$TripStatusEnumMap[instance.status]!,
  'participantIds': instance.participantIds,
  'adventurousness': instance.adventurousness,
  'foodFocus': instance.foodFocus,
  'urbanVsNature': instance.urbanVsNature,
  'budgetFlexibility': instance.budgetFlexibility,
  'pacePreference': instance.pacePreference,
  'createdAt': TripModel._timestampToJson(instance.createdAt),
  'updatedAt': TripModel._timestampToJson(instance.updatedAt),
};

const _$TripStatusEnumMap = {
  TripStatus.planning: 'planning',
  TripStatus.ongoing: 'ongoing',
  TripStatus.completed: 'completed',
  TripStatus.cancelled: 'cancelled',
};
