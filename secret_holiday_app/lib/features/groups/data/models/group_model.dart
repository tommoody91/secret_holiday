import 'package:json_annotation/json_annotation.dart';
import 'package:equatable/equatable.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

part 'group_model.g.dart';

@JsonSerializable(explicitToJson: true)
class GroupRules extends Equatable {
  final int budgetPerPerson; // in USD
  final int maxTripDays;
  final String luggageAllowance;
  final bool noRepeatCountries;
  final List<String> customRules;
  
  const GroupRules({
    required this.budgetPerPerson,
    required this.maxTripDays,
    required this.luggageAllowance,
    this.noRepeatCountries = false,
    this.customRules = const [],
  });
  
  factory GroupRules.fromJson(Map<String, dynamic> json) =>
      _$GroupRulesFromJson(json);
  
  Map<String, dynamic> toJson() => _$GroupRulesToJson(this);
  
  @override
  List<Object?> get props => [budgetPerPerson, maxTripDays, luggageAllowance, noRepeatCountries, customRules];
}

@JsonSerializable(explicitToJson: true)
class GroupMember extends Equatable {
  final String userId;
  final String name;
  final String? profilePictureUrl;
  final String role; // 'admin' or 'member'
  final int? yearLastOrganized;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime joinedAt;
  
  const GroupMember({
    required this.userId,
    required this.name,
    this.profilePictureUrl,
    this.role = 'member',
    this.yearLastOrganized,
    required this.joinedAt,
  });
  
  factory GroupMember.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberFromJson(json);
  
  Map<String, dynamic> toJson() => _$GroupMemberToJson(this);
  
  @override
  List<Object?> get props => [userId, name, profilePictureUrl, role, yearLastOrganized, joinedAt];
  
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
class GroupModel extends Equatable {
  final String id;
  final String name;
  final String createdBy;
  final String? currentOrganizerId;
  final List<GroupMember> members;
  
  // Array of user IDs for efficient Firestore queries
  // This is derived from members list and stored separately
  final List<String> memberIds;
  
  final GroupRules rules;
  final String inviteCode;
  
  // Upcoming trip info
  final DateTime? upcomingTripStartDate;
  final DateTime? upcomingTripEndDate;
  
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime createdAt;
  @JsonKey(fromJson: _timestampFromJson, toJson: _timestampToJson)
  final DateTime updatedAt;
  
  const GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    this.currentOrganizerId,
    required this.members,
    required this.memberIds,
    required this.rules,
    required this.inviteCode,
    this.upcomingTripStartDate,
    this.upcomingTripEndDate,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory GroupModel.fromJson(Map<String, dynamic> json) =>
      _$GroupModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$GroupModelToJson(this);
  
  factory GroupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupModel.fromJson({...data, 'id': doc.id});
  }
  
  Map<String, dynamic> toFirestore() {
    final json = toJson();
    json.remove('id');
    return json;
  }
  
  GroupModel copyWith({
    String? id,
    String? name,
    String? createdBy,
    String? currentOrganizerId,
    List<GroupMember>? members,
    List<String>? memberIds,
    GroupRules? rules,
    String? inviteCode,
    DateTime? upcomingTripStartDate,
    DateTime? upcomingTripEndDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      createdBy: createdBy ?? this.createdBy,
      currentOrganizerId: currentOrganizerId ?? this.currentOrganizerId,
      members: members ?? this.members,
      memberIds: memberIds ?? this.memberIds,
      rules: rules ?? this.rules,
      inviteCode: inviteCode ?? this.inviteCode,
      upcomingTripStartDate: upcomingTripStartDate ?? this.upcomingTripStartDate,
      upcomingTripEndDate: upcomingTripEndDate ?? this.upcomingTripEndDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  @override
  List<Object?> get props => [
        id,
        name,
        createdBy,
        currentOrganizerId,
        members,
        memberIds,
        rules,
        inviteCode,
        upcomingTripStartDate,
        upcomingTripEndDate,
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
