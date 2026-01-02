import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'activity_model.g.dart';

/// Represents a single activity in the trip itinerary
@JsonSerializable(explicitToJson: true)
class ActivityModel extends Equatable {
  final String id;
  final String tripId;
  final int dayNumber;
  final int orderIndex; // For reordering within a day
  
  final String name;
  final String? description;
  final String? location; // Address or place name
  final String? placeId; // Google Places ID for linking
  final double? latitude;
  final double? longitude;
  
  final String? category; // e.g., 'food', 'sightseeing', 'transport', 'accommodation'
  final String? notes;
  
  // Cost tracking
  final double? estimatedCost;
  final double? actualCost;
  final String currency; // Default: GBP
  
  // Time tracking
  final String? startTime; // Format: "HH:mm"
  final String? endTime;   // Format: "HH:mm"
  final int? durationMinutes;
  
  // Media & status
  final List<String> photoIds; // IDs of associated memories/photos
  final bool isCompleted;
  final bool isBooked; // For things that need reservations
  final String? bookingReference;
  final String? bookingUrl;
  
  final String createdBy;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;

  const ActivityModel({
    required this.id,
    required this.tripId,
    required this.dayNumber,
    required this.orderIndex,
    required this.name,
    this.description,
    this.location,
    this.placeId,
    this.latitude,
    this.longitude,
    this.category,
    this.notes,
    this.estimatedCost,
    this.actualCost,
    this.currency = 'GBP',
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.photoIds = const [],
    this.isCompleted = false,
    this.isBooked = false,
    this.bookingReference,
    this.bookingUrl,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ActivityModel.fromJson(Map<String, dynamic> json) =>
      _$ActivityModelFromJson(json);

  Map<String, dynamic> toJson() => _$ActivityModelToJson(this);

  factory ActivityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityModel.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }

  ActivityModel copyWith({
    String? id,
    String? tripId,
    int? dayNumber,
    int? orderIndex,
    String? name,
    String? description,
    String? location,
    String? placeId,
    double? latitude,
    double? longitude,
    String? category,
    String? notes,
    double? estimatedCost,
    double? actualCost,
    String? currency,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    List<String>? photoIds,
    bool? isCompleted,
    bool? isBooked,
    String? bookingReference,
    String? bookingUrl,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActivityModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      dayNumber: dayNumber ?? this.dayNumber,
      orderIndex: orderIndex ?? this.orderIndex,
      name: name ?? this.name,
      description: description ?? this.description,
      location: location ?? this.location,
      placeId: placeId ?? this.placeId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      category: category ?? this.category,
      notes: notes ?? this.notes,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      actualCost: actualCost ?? this.actualCost,
      currency: currency ?? this.currency,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      photoIds: photoIds ?? this.photoIds,
      isCompleted: isCompleted ?? this.isCompleted,
      isBooked: isBooked ?? this.isBooked,
      bookingReference: bookingReference ?? this.bookingReference,
      bookingUrl: bookingUrl ?? this.bookingUrl,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get formatted time range string
  String? get timeRange {
    if (startTime == null) return null;
    if (endTime != null) return '$startTime - $endTime';
    return startTime;
  }

  /// Get formatted cost string
  String? get formattedCost {
    final cost = actualCost ?? estimatedCost;
    if (cost == null) return null;
    final symbol = currency == 'GBP' ? '£' : currency;
    return '$symbol${cost.toStringAsFixed(2)}';
  }

  @override
  List<Object?> get props => [
        id,
        tripId,
        dayNumber,
        orderIndex,
        name,
        description,
        location,
        placeId,
        latitude,
        longitude,
        category,
        notes,
        estimatedCost,
        actualCost,
        currency,
        startTime,
        endTime,
        durationMinutes,
        photoIds,
        isCompleted,
        isBooked,
        bookingReference,
        bookingUrl,
        createdBy,
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

/// Activity categories for filtering and display
class ActivityCategory {
  static const String food = 'food';
  static const String sightseeing = 'sightseeing';
  static const String transport = 'transport';
  static const String accommodation = 'accommodation';
  static const String entertainment = 'entertainment';
  static const String shopping = 'shopping';
  static const String nature = 'nature';
  static const String culture = 'culture';
  static const String relaxation = 'relaxation';
  static const String adventure = 'adventure';
  static const String nightlife = 'nightlife';
  static const String other = 'other';

  static const List<String> all = [
    food,
    sightseeing,
    transport,
    accommodation,
    entertainment,
    shopping,
    nature,
    culture,
    relaxation,
    adventure,
    nightlife,
    other,
  ];

  static const Map<String, String> labels = {
    food: 'Food & Dining',
    sightseeing: 'Sightseeing',
    transport: 'Transport',
    accommodation: 'Accommodation',
    entertainment: 'Entertainment',
    shopping: 'Shopping',
    nature: 'Nature & Outdoors',
    culture: 'Culture & History',
    relaxation: 'Relaxation & Spa',
    adventure: 'Adventure & Sports',
    nightlife: 'Nightlife',
    other: 'Other',
  };

  static const Map<String, int> icons = {
    food: 0xe532, // Icons.restaurant
    sightseeing: 0xe3ab, // Icons.camera_alt
    transport: 0xe1d7, // Icons.directions_car
    accommodation: 0xe588, // Icons.hotel
    entertainment: 0xe87d, // Icons.local_activity
    shopping: 0xe8cc, // Icons.shopping_bag
    nature: 0xe52f, // Icons.park
    culture: 0xe80c, // Icons.museum
    relaxation: 0xea62, // Icons.spa
    adventure: 0xe566, // Icons.hiking
    nightlife: 0xea46, // Icons.nightlife
    other: 0xe8b8, // Icons.more_horiz
  };
}
