import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? profilePictureUrl;
  final String? phoneNumber;
  
  // Travel Information (encrypted in storage)
  final String? passportNumber;
  final DateTime? passportExpiry;
  final String? frequentFlyerNumber;
  final String? preferredAirport;
  final List<String>? dietaryRestrictions;
  final List<String>? allergies;
  final String? emergencyContact;
  final String? emergencyPhone;
  
  // App metadata
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;
  
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.profilePictureUrl,
    this.phoneNumber,
    this.passportNumber,
    this.passportExpiry,
    this.frequentFlyerNumber,
    this.preferredAirport,
    this.dietaryRestrictions,
    this.allergies,
    this.emergencyContact,
    this.emergencyPhone,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory UserModel.fromJson(Map<String, dynamic> json) => 
      _$UserModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$UserModelToJson(this);
  
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel.fromJson({...data, 'id': doc.id});
  }
  
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id'); // Firestore auto-generates IDs
    return json;
  }
  
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? profilePictureUrl,
    String? phoneNumber,
    String? passportNumber,
    DateTime? passportExpiry,
    String? frequentFlyerNumber,
    String? preferredAirport,
    List<String>? dietaryRestrictions,
    List<String>? allergies,
    String? emergencyContact,
    String? emergencyPhone,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      passportNumber: passportNumber ?? this.passportNumber,
      passportExpiry: passportExpiry ?? this.passportExpiry,
      frequentFlyerNumber: frequentFlyerNumber ?? this.frequentFlyerNumber,
      preferredAirport: preferredAirport ?? this.preferredAirport,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      emergencyPhone: emergencyPhone ?? this.emergencyPhone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        email,
        name,
        profilePictureUrl,
        phoneNumber,
        passportNumber,
        passportExpiry,
        frequentFlyerNumber,
        preferredAirport,
        dietaryRestrictions,
        allergies,
        emergencyContact,
        emergencyPhone,
        createdAt,
        updatedAt,
      ];
  
  // Helper methods for Firestore Timestamp conversion
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
