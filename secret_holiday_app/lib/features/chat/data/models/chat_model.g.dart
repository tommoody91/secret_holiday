// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
  id: json['id'] as String,
  groupId: json['groupId'] as String,
  senderId: json['senderId'] as String,
  senderName: json['senderName'] as String,
  senderPhotoUrl: json['senderPhotoUrl'] as String?,
  message: json['message'] as String,
  mediaUrl: json['mediaUrl'] as String?,
  mediaType: json['mediaType'] as String?,
  timestamp: ChatMessage._timestampFromJson(json['timestamp']),
  readBy:
      (json['readBy'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'senderId': instance.senderId,
      'senderName': instance.senderName,
      'senderPhotoUrl': instance.senderPhotoUrl,
      'message': instance.message,
      'mediaUrl': instance.mediaUrl,
      'mediaType': instance.mediaType,
      'timestamp': ChatMessage._timestampToJson(instance.timestamp),
      'readBy': instance.readBy,
    };
