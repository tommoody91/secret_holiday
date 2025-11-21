// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupRules _$GroupRulesFromJson(Map<String, dynamic> json) => GroupRules(
  budgetPerPerson: (json['budgetPerPerson'] as num).toInt(),
  maxTripDays: (json['maxTripDays'] as num).toInt(),
  luggageAllowance: json['luggageAllowance'] as String,
  noRepeatCountries: json['noRepeatCountries'] as bool? ?? false,
  customRules:
      (json['customRules'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$GroupRulesToJson(GroupRules instance) =>
    <String, dynamic>{
      'budgetPerPerson': instance.budgetPerPerson,
      'maxTripDays': instance.maxTripDays,
      'luggageAllowance': instance.luggageAllowance,
      'noRepeatCountries': instance.noRepeatCountries,
      'customRules': instance.customRules,
    };

GroupMember _$GroupMemberFromJson(Map<String, dynamic> json) => GroupMember(
  userId: json['userId'] as String,
  name: json['name'] as String,
  profilePictureUrl: json['profilePictureUrl'] as String?,
  role: json['role'] as String? ?? 'member',
  yearLastOrganized: (json['yearLastOrganized'] as num?)?.toInt(),
  joinedAt: GroupMember._timestampFromJson(json['joinedAt']),
);

Map<String, dynamic> _$GroupMemberToJson(GroupMember instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'name': instance.name,
      'profilePictureUrl': instance.profilePictureUrl,
      'role': instance.role,
      'yearLastOrganized': instance.yearLastOrganized,
      'joinedAt': GroupMember._timestampToJson(instance.joinedAt),
    };

GroupModel _$GroupModelFromJson(Map<String, dynamic> json) => GroupModel(
  id: json['id'] as String,
  name: json['name'] as String,
  createdBy: json['createdBy'] as String,
  currentOrganizerId: json['currentOrganizerId'] as String?,
  members: (json['members'] as List<dynamic>)
      .map((e) => GroupMember.fromJson(e as Map<String, dynamic>))
      .toList(),
  memberIds: (json['memberIds'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  rules: GroupRules.fromJson(json['rules'] as Map<String, dynamic>),
  inviteCode: json['inviteCode'] as String,
  upcomingTripStartDate: json['upcomingTripStartDate'] == null
      ? null
      : DateTime.parse(json['upcomingTripStartDate'] as String),
  upcomingTripEndDate: json['upcomingTripEndDate'] == null
      ? null
      : DateTime.parse(json['upcomingTripEndDate'] as String),
  createdAt: GroupModel._timestampFromJson(json['createdAt']),
  updatedAt: GroupModel._timestampFromJson(json['updatedAt']),
);

Map<String, dynamic> _$GroupModelToJson(
  GroupModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'createdBy': instance.createdBy,
  'currentOrganizerId': instance.currentOrganizerId,
  'members': instance.members.map((e) => e.toJson()).toList(),
  'memberIds': instance.memberIds,
  'rules': instance.rules.toJson(),
  'inviteCode': instance.inviteCode,
  'upcomingTripStartDate': instance.upcomingTripStartDate?.toIso8601String(),
  'upcomingTripEndDate': instance.upcomingTripEndDate?.toIso8601String(),
  'createdAt': GroupModel._timestampToJson(instance.createdAt),
  'updatedAt': GroupModel._timestampToJson(instance.updatedAt),
};
