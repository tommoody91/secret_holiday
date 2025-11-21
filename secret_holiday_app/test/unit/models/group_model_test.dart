import 'package:flutter_test/flutter_test.dart';
import 'package:secret_holiday_app/features/groups/data/models/group_model.dart';
import '../../helpers/test_data.dart';

void main() {
  group('GroupModel', () {
    group('JSON Serialization', () {
      test('toJson converts model to JSON correctly', () {
        final group = TestData.activeGroup;
        final json = group.toJson();

        expect(json['id'], group.id);
        expect(json['name'], group.name);
        expect(json['createdBy'], group.createdBy);
        expect(json['currentOrganizerId'], group.currentOrganizerId);
        expect(json['inviteCode'], group.inviteCode);
        expect(json['memberIds'], group.memberIds);
        
        // Check nested rules object
        expect(json['rules'], isNotNull);
        expect(json['rules']['budgetPerPerson'], group.rules.budgetPerPerson);
        expect(json['rules']['maxTripDays'], group.rules.maxTripDays);
        expect(json['rules']['luggageAllowance'], group.rules.luggageAllowance);
        expect(json['rules']['noRepeatCountries'], group.rules.noRepeatCountries);
        expect(json['rules']['customRules'], group.rules.customRules);
        
        // Check members array
        expect(json['members'], isA<List>());
        expect(json['members'].length, group.members.length);
      });

      test('fromJson creates model from JSON correctly', () {
        final originalGroup = TestData.activeGroup;
        final json = originalGroup.toJson();
        final decodedGroup = GroupModel.fromJson(json);

        expect(decodedGroup.id, originalGroup.id);
        expect(decodedGroup.name, originalGroup.name);
        expect(decodedGroup.createdBy, originalGroup.createdBy);
        expect(decodedGroup.currentOrganizerId, originalGroup.currentOrganizerId);
        expect(decodedGroup.inviteCode, originalGroup.inviteCode);
        expect(decodedGroup.memberIds, originalGroup.memberIds);
        expect(decodedGroup.members.length, originalGroup.members.length);
        expect(decodedGroup.rules.budgetPerPerson, originalGroup.rules.budgetPerPerson);
      });

      test('JSON roundtrip preserves all data', () {
        final originalGroup = TestData.activeGroup;
        final json = originalGroup.toJson();
        final decodedGroup = GroupModel.fromJson(json);

        expect(decodedGroup, equals(originalGroup));
      });

      test('handles groups with upcoming trip dates', () {
        final groupWithTrip = TestData.activeGroup;
        expect(groupWithTrip.upcomingTripStartDate, isNotNull);
        expect(groupWithTrip.upcomingTripEndDate, isNotNull);
        
        final json = groupWithTrip.toJson();
        final decodedGroup = GroupModel.fromJson(json);

        expect(decodedGroup.upcomingTripStartDate, groupWithTrip.upcomingTripStartDate);
        expect(decodedGroup.upcomingTripEndDate, groupWithTrip.upcomingTripEndDate);
      });

      test('handles groups without upcoming trip dates', () {
        final groupWithoutTrip = TestData.newGroup;
        expect(groupWithoutTrip.upcomingTripStartDate, isNull);
        expect(groupWithoutTrip.upcomingTripEndDate, isNull);

        final json = groupWithoutTrip.toJson();
        final decodedGroup = GroupModel.fromJson(json);

        expect(decodedGroup.upcomingTripStartDate, isNull);
        expect(decodedGroup.upcomingTripEndDate, isNull);
      });

      test('handles group with single member', () {
        final singleMemberGroup = TestData.newGroup;
        expect(singleMemberGroup.members.length, 1);
        expect(singleMemberGroup.memberIds.length, 1);

        final json = singleMemberGroup.toJson();
        final decodedGroup = GroupModel.fromJson(json);

        expect(decodedGroup.members.length, 1);
        expect(decodedGroup.memberIds.length, 1);
        expect(decodedGroup.members[0].userId, singleMemberGroup.members[0].userId);
      });

      test('handles group with multiple members', () {
        final largeGroup = TestData.largeGroup;
        expect(largeGroup.members.length, 5);
        expect(largeGroup.memberIds.length, 5);

        final json = largeGroup.toJson();
        final decodedGroup = GroupModel.fromJson(json);

        expect(decodedGroup.members.length, 5);
        expect(decodedGroup.memberIds.length, 5);
      });
    });

    group('copyWith', () {
      test('creates new instance with updated name', () {
        final original = TestData.activeGroup;
        final updated = original.copyWith(name: 'New Group Name');

        expect(updated.name, 'New Group Name');
        expect(updated.id, original.id);
        expect(original.name, 'Adventure Squad'); // Original unchanged
      });

      test('creates new instance with updated currentOrganizerId', () {
        final original = TestData.activeGroup;
        final updated = original.copyWith(currentOrganizerId: 'user3');

        expect(updated.currentOrganizerId, 'user3');
        expect(original.currentOrganizerId, 'user2');
      });

      test('creates new instance with updated rules', () {
        final original = TestData.activeGroup;
        final newRules = GroupRules(
          budgetPerPerson: 2000,
          maxTripDays: 10,
          luggageAllowance: 'Unlimited',
          noRepeatCountries: false,
        );
        final updated = original.copyWith(rules: newRules);

        expect(updated.rules.budgetPerPerson, 2000);
        expect(updated.rules.maxTripDays, 10);
        expect(original.rules.budgetPerPerson, 1000);
      });

      test('creates new instance with updated members', () {
        final original = TestData.activeGroup;
        final newMember = GroupMember(
          userId: 'user4',
          name: 'New Member',
          role: 'member',
          joinedAt: DateTime.now(),
        );
        final updatedMembers = [...original.members, newMember];
        final updatedMemberIds = [...original.memberIds, 'user4'];
        
        final updated = original.copyWith(
          members: updatedMembers,
          memberIds: updatedMemberIds,
        );

        expect(updated.members.length, 4);
        expect(updated.memberIds.length, 4);
        expect(original.members.length, 3);
        expect(original.memberIds.length, 3);
      });

      test('creates new instance with updated upcoming trip dates', () {
        final original = TestData.activeGroup;
        final newStartDate = DateTime(2026, 7, 1);
        final newEndDate = DateTime(2026, 7, 10);
        final updated = original.copyWith(
          upcomingTripStartDate: newStartDate,
          upcomingTripEndDate: newEndDate,
        );

        expect(updated.upcomingTripStartDate, newStartDate);
        expect(updated.upcomingTripEndDate, newEndDate);
        expect(original.upcomingTripStartDate, isNot(newStartDate));
      });

      test('returns identical instance when no parameters provided', () {
        final original = TestData.activeGroup;
        final updated = original.copyWith();

        expect(updated, equals(original));
      });
    });

    group('Equality', () {
      test('two groups with same data are equal', () {
        final group1 = TestData.activeGroup;
        final group2 = GroupModel.fromJson(group1.toJson());

        expect(group1, equals(group2));
      });

      test('two groups with different IDs are not equal', () {
        final group1 = TestData.activeGroup;
        final group2 = group1.copyWith(id: 'different_id');

        expect(group1, isNot(equals(group2)));
      });

      test('two groups with different names are not equal', () {
        final group1 = TestData.activeGroup;
        final group2 = group1.copyWith(name: 'Different Name');

        expect(group1, isNot(equals(group2)));
      });

      test('two groups with different memberIds are not equal', () {
        final group1 = TestData.activeGroup;
        final group2 = group1.copyWith(memberIds: ['user1', 'user2']);

        expect(group1, isNot(equals(group2)));
      });
    });

    group('GroupRules', () {
      test('serializes and deserializes correctly', () {
        final rules = TestData.defaultRules;
        final json = rules.toJson();
        final decoded = GroupRules.fromJson(json);

        expect(decoded.budgetPerPerson, rules.budgetPerPerson);
        expect(decoded.maxTripDays, rules.maxTripDays);
        expect(decoded.luggageAllowance, rules.luggageAllowance);
        expect(decoded.noRepeatCountries, rules.noRepeatCountries);
        expect(decoded.customRules, rules.customRules);
      });

      test('handles empty customRules list', () {
        final rules = TestData.flexibleRules;
        expect(rules.customRules, isEmpty);

        final json = rules.toJson();
        final decoded = GroupRules.fromJson(json);

        expect(decoded.customRules, isEmpty);
      });
    });

    group('GroupMember', () {
      test('serializes and deserializes correctly', () {
        final member = TestData.adminMember;
        final json = member.toJson();
        final decoded = GroupMember.fromJson(json);

        expect(decoded.userId, member.userId);
        expect(decoded.name, member.name);
        expect(decoded.profilePictureUrl, member.profilePictureUrl);
        expect(decoded.role, member.role);
        expect(decoded.yearLastOrganized, member.yearLastOrganized);
        expect(decoded.joinedAt, member.joinedAt);
      });

      test('handles member without profile picture', () {
        final member = TestData.regularMember;
        expect(member.profilePictureUrl, isNull);

        final json = member.toJson();
        final decoded = GroupMember.fromJson(json);

        expect(decoded.profilePictureUrl, isNull);
      });

      test('handles member without yearLastOrganized', () {
        final member = TestData.newMember;
        expect(member.yearLastOrganized, isNull);

        final json = member.toJson();
        final decoded = GroupMember.fromJson(json);

        expect(decoded.yearLastOrganized, isNull);
      });

      test('defaults role to member', () {
        final member = GroupMember(
          userId: 'user123',
          name: 'Test User',
          joinedAt: DateTime.now(),
        );

        expect(member.role, 'member');
      });

      test('admin role is preserved', () {
        final adminMember = TestData.adminMember;
        expect(adminMember.role, 'admin');

        final json = adminMember.toJson();
        final decoded = GroupMember.fromJson(json);

        expect(decoded.role, 'admin');
      });
    });
  });
}
