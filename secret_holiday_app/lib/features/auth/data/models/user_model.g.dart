// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  profilePictureUrl: json['profilePictureUrl'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  passportNumber: json['passportNumber'] as String?,
  passportExpiry: json['passportExpiry'] == null
      ? null
      : DateTime.parse(json['passportExpiry'] as String),
  frequentFlyerNumber: json['frequentFlyerNumber'] as String?,
  preferredAirport: json['preferredAirport'] as String?,
  dietaryRestrictions: (json['dietaryRestrictions'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  allergies: (json['allergies'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  emergencyContact: json['emergencyContact'] as String?,
  emergencyPhone: json['emergencyPhone'] as String?,
  createdAt: UserModel._timestampFromJson(json['createdAt']),
  updatedAt: UserModel._timestampFromJson(json['updatedAt']),
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'profilePictureUrl': instance.profilePictureUrl,
  'phoneNumber': instance.phoneNumber,
  'passportNumber': instance.passportNumber,
  'passportExpiry': instance.passportExpiry?.toIso8601String(),
  'frequentFlyerNumber': instance.frequentFlyerNumber,
  'preferredAirport': instance.preferredAirport,
  'dietaryRestrictions': instance.dietaryRestrictions,
  'allergies': instance.allergies,
  'emergencyContact': instance.emergencyContact,
  'emergencyPhone': instance.emergencyPhone,
  'createdAt': UserModel._timestampToJson(instance.createdAt),
  'updatedAt': UserModel._timestampToJson(instance.updatedAt),
};
