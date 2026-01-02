import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a memory (photo/video) linked to a trip
class MemoryModel {
  final String id;
  final String tripId;
  final String url;
  final String type; // 'photo' or 'video'
  final String uploadedBy;
  final DateTime uploadedAt;
  final int? dayNumber;
  final String? activityId;
  final String? activityName; // Denormalized for display
  final String? caption;

  const MemoryModel({
    required this.id,
    required this.tripId,
    required this.url,
    required this.type,
    required this.uploadedBy,
    required this.uploadedAt,
    this.dayNumber,
    this.activityId,
    this.activityName,
    this.caption,
  });

  factory MemoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MemoryModel(
      id: doc.id,
      tripId: data['tripId'] ?? '',
      url: data['url'] ?? '',
      type: data['type'] ?? 'photo',
      uploadedBy: data['uploadedBy'] ?? '',
      uploadedAt: (data['uploadedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      dayNumber: data['dayNumber'] as int?,
      activityId: data['activityId'] as String?,
      activityName: data['activityName'] as String?,
      caption: data['caption'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tripId': tripId,
      'url': url,
      'type': type,
      'uploadedBy': uploadedBy,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
      'dayNumber': dayNumber,
      'activityId': activityId,
      'activityName': activityName,
      'caption': caption,
    };
  }

  MemoryModel copyWith({
    String? id,
    String? tripId,
    String? url,
    String? type,
    String? uploadedBy,
    DateTime? uploadedAt,
    int? dayNumber,
    String? activityId,
    String? activityName,
    String? caption,
    bool clearDayNumber = false,
    bool clearActivityId = false,
  }) {
    return MemoryModel(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      url: url ?? this.url,
      type: type ?? this.type,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      dayNumber: clearDayNumber ? null : (dayNumber ?? this.dayNumber),
      activityId: clearActivityId ? null : (activityId ?? this.activityId),
      activityName: activityName ?? this.activityName,
      caption: caption ?? this.caption,
    );
  }
}
