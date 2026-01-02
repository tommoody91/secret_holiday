// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityModel _$ActivityModelFromJson(Map<String, dynamic> json) =>
    ActivityModel(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      dayNumber: (json['dayNumber'] as num).toInt(),
      orderIndex: (json['orderIndex'] as num).toInt(),
      name: json['name'] as String,
      description: json['description'] as String?,
      location: json['location'] as String?,
      placeId: json['placeId'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      category: json['category'] as String?,
      notes: json['notes'] as String?,
      estimatedCost: (json['estimatedCost'] as num?)?.toDouble(),
      actualCost: (json['actualCost'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'GBP',
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt(),
      photoIds:
          (json['photoIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isCompleted: json['isCompleted'] as bool? ?? false,
      isBooked: json['isBooked'] as bool? ?? false,
      bookingReference: json['bookingReference'] as String?,
      bookingUrl: json['bookingUrl'] as String?,
      createdBy: json['createdBy'] as String,
      createdAt: ActivityModel._timestampFromJson(json['createdAt']),
      updatedAt: ActivityModel._timestampFromJson(json['updatedAt']),
    );

Map<String, dynamic> _$ActivityModelToJson(ActivityModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'dayNumber': instance.dayNumber,
      'orderIndex': instance.orderIndex,
      'name': instance.name,
      'description': instance.description,
      'location': instance.location,
      'placeId': instance.placeId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'category': instance.category,
      'notes': instance.notes,
      'estimatedCost': instance.estimatedCost,
      'actualCost': instance.actualCost,
      'currency': instance.currency,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'durationMinutes': instance.durationMinutes,
      'photoIds': instance.photoIds,
      'isCompleted': instance.isCompleted,
      'isBooked': instance.isBooked,
      'bookingReference': instance.bookingReference,
      'bookingUrl': instance.bookingUrl,
      'createdBy': instance.createdBy,
      'createdAt': ActivityModel._timestampToJson(instance.createdAt),
      'updatedAt': ActivityModel._timestampToJson(instance.updatedAt),
    };
