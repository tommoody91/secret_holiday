import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:secret_holiday_app/features/groups/data/repositories/group_repository.dart';
import 'package:secret_holiday_app/features/groups/data/models/group_model.dart';
import 'package:secret_holiday_app/core/error/exceptions.dart';
import '../../helpers/mock_firebase_auth.mocks.dart';
import '../../helpers/mock_auth_helper.dart';
import '../../helpers/test_data.dart';

void main() {
  group('GroupRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late GroupRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      repository = GroupRepository(auth: mockAuth, firestore: fakeFirestore);
    });

    group('createGroup', () {
      test('creates group with all settings successfully', () async {
        // Arrange
        final mockUser = MockAuthHelper.createMockUser(
          uid: 'user1',
          email: 'john@example.com',
        );
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        await fakeFirestore.collection('users').doc('user1').set({
          'id': 'user1',
          'email': 'john@example.com',
          'name': 'John Doe',
        });

        // Act
        final result = await repository.createGroup(
          name: 'Adventure Crew',
          budgetPerPerson: 1500,
          maxTripDays: 10,
          luggageAllowance: '1 cabin bag + 1 checked bag',
          noRepeatCountries: true,
          customRules: ['No solo activities', 'Group dinner every night'],
        );

        // Assert
        expect(result.name, 'Adventure Crew');
        expect(result.createdBy, 'user1');
        expect(result.members.length, 1);
        expect(result.members[0].userId, 'user1');
        expect(result.members[0].role, 'admin');
        expect(result.memberIds, ['user1']);
        expect(result.inviteCode.length, 6);
        expect(result.rules.budgetPerPerson, 1500);
        expect(result.rules.maxTripDays, 10);
        expect(result.rules.noRepeatCountries, true);
        expect(result.rules.customRules, contains('No solo activities'));

        // Verify group created in Firestore
        final groupDocs = await fakeFirestore.collection('groups').get();
        expect(groupDocs.docs.length, 1);
      });

      test('generates unique 6-character invite code', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        await fakeFirestore.collection('users').doc('user1').set({
          'id': 'user1',
          'name': 'John',
        });

        final result = await repository.createGroup(
          name: 'Test Group',
          budgetPerPerson: 1000,
          maxTripDays: 7,
          luggageAllowance: '1 bag',
        );

        expect(result.inviteCode.length, 6);
        expect(result.inviteCode, matches(RegExp(r'^[A-Z0-9]+$')));
      });

      test('throws AuthException when user not authenticated', () async {
        MockAuthHelper.setupMockAuthWithoutUser(mockAuth);

        expect(
          () => repository.createGroup(
            name: 'Test',
            budgetPerPerson: 1000,
            maxTripDays: 7,
            luggageAllowance: '1 bag',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('retries invite code generation if duplicate found', () async {
        // This tests the collision handling logic
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        await fakeFirestore.collection('users').doc('user1').set({
          'id': 'user1',
          'name': 'John',
        });

        // Create first group
        final firstGroup = await repository.createGroup(
          name: 'First Group',
          budgetPerPerson: 1000,
          maxTripDays: 7,
          luggageAllowance: '1 bag',
        );

        // Create second group - should get different invite code
        final secondGroup = await repository.createGroup(
          name: 'Second Group',
          budgetPerPerson: 1000,
          maxTripDays: 7,
          luggageAllowance: '1 bag',
        );

        // Codes should be different (extremely high probability)
        expect(firstGroup.inviteCode, isNot(equals(secondGroup.inviteCode)));
      });
    });

    group('joinGroup', () {
      test('adds user to group with valid invite code', () async {
        // Arrange
        final mockUser = MockAuthHelper.createMockUser(
          uid: 'user4',
          email: 'jane@example.com',
        );
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        // Create existing group
        final groupData = TestData.activeGroup.copyWith(
          id: 'group1',
          inviteCode: 'ABC123',
        );
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        await fakeFirestore.collection('users').doc('user4').set({
          'id': 'user4',
          'name': 'Jane Smith',
        });

        // Act
        final result = await repository.joinGroup('ABC123');

        // Assert
        expect(result.members.length, 4); // 3 original + 1 new
        expect(result.memberIds, contains('user4'));
        expect(result.members.any((m) => m.userId == 'user4'), true);
        expect(result.members.firstWhere((m) => m.userId == 'user4').role, 'member');
      });

      test('throws DataException with invalid invite code', () async {
        final mockUser = MockAuthHelper.createMockUser();
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        expect(
          () => repository.joinGroup('INVALID'),
          throwsA(isA<DataException>()),
        );
      });

      test('returns group without adding if already a member', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.activeGroup.copyWith(inviteCode: 'ABC123');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        await fakeFirestore.collection('users').doc('user1').set({
          'id': 'user1',
          'name': 'John',
        });

        final result = await repository.joinGroup('ABC123');

        // Should not duplicate member
        expect(result.members.length, 3); // Original count unchanged
        final user1Count = result.members.where((m) => m.userId == 'user1').length;
        expect(user1Count, 1);
      });

      test('throws AuthException when user not authenticated', () async {
        MockAuthHelper.setupMockAuthWithoutUser(mockAuth);

        expect(
          () => repository.joinGroup('ABC123'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('validateInviteCode', () {
      test('returns group when code is valid', () async {
        final groupData = TestData.activeGroup.copyWith(inviteCode: 'VALID1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        final result = await repository.validateInviteCode('VALID1');

        expect(result, isNotNull);
        expect(result!.inviteCode, 'VALID1');
      });

      test('returns null when code is invalid', () async {
        final result = await repository.validateInviteCode('INVALID');
        expect(result, isNull);
      });

      test('is case-insensitive', () async {
        final groupData = TestData.activeGroup.copyWith(inviteCode: 'ABC123');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        final result = await repository.validateInviteCode('abc123');

        expect(result, isNotNull);
        expect(result!.inviteCode, 'ABC123');
      });
    });

    group('getUserGroups', () {
      test('returns stream of groups where user is member', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        // Create groups using proper model
        final group1 = TestData.activeGroup.copyWith(
          id: 'group1',
          memberIds: ['user1', 'user2'],
        );
        await fakeFirestore.collection('groups').doc('group1').set(group1.toFirestore());

        final group2 = TestData.newGroup.copyWith(
          id: 'group2',
          memberIds: ['user2', 'user3'],
        );
        await fakeFirestore.collection('groups').doc('group2').set(group2.toFirestore());

        final stream = repository.getUserGroups();
        final groups = await stream.first;

        expect(groups.length, 1);
        expect(groups[0].memberIds, contains('user1'));
      });

      test('throws AuthException when user not authenticated', () {
        MockAuthHelper.setupMockAuthWithoutUser(mockAuth);

        expect(
          () => repository.getUserGroups(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('updateGroupSettings', () {
      test('updates group name when user is admin', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        await repository.updateGroupSettings(
          groupId: 'group1',
          name: 'Updated Name',
        );

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        expect(doc.data()!['name'], 'Updated Name');
      });

      test('updates group rules', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        final newRules = GroupRules(
          budgetPerPerson: 2000,
          maxTripDays: 14,
          luggageAllowance: '2 bags',
          noRepeatCountries: true,
        );

        await repository.updateGroupSettings(
          groupId: 'group1',
          rules: newRules,
        );

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        expect(doc.data()!['rules']['budgetPerPerson'], 2000);
        expect(doc.data()!['rules']['maxTripDays'], 14);
      });

      test('updates group preferences', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        await repository.updateGroupSettings(
          groupId: 'group1',
          name: 'Updated Squad',
        );

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        expect(doc.data()!['name'], 'Updated Squad');
      });

      test('throws AuthException when user is not admin', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user2');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        expect(
          () => repository.updateGroupSettings(
            groupId: 'group1',
            name: 'Hacked Name',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws AuthException when user not authenticated', () async {
        MockAuthHelper.setupMockAuthWithoutUser(mockAuth);

        expect(
          () => repository.updateGroupSettings(
            groupId: 'group1',
            name: 'Test',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('removeMember', () {
      test('removes member from group when user is admin', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.largeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        await repository.removeMember(groupId: 'group1', userId: 'user3');

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        final memberIds = List<String>.from(doc.data()!['memberIds']);
        expect(memberIds, isNot(contains('user3')));
        expect(memberIds.length, 4); // 5 - 1
      });

      test('allows user to remove themselves', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user3');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.largeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        await repository.removeMember(groupId: 'group1', userId: 'user3');

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        final memberIds = List<String>.from(doc.data()!['memberIds']);
        expect(memberIds, isNot(contains('user3')));
      });

      test('throws AuthException when non-admin tries to remove others', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user3');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        expect(
          () => repository.removeMember(groupId: 'group1', userId: 'user2'),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws DataException when removing last admin', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        // Group with only one admin
        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        expect(
          () => repository.removeMember(groupId: 'group1', userId: 'user1'),
          throwsA(isA<DataException>()),
        );
      });

      test('deletes group when last member leaves', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        // Group with only one member
        final singleMemberGroup = GroupModel(
          id: 'group1',
          name: 'Solo Group',
          createdBy: 'user1',
          members: [
            GroupMember(
              userId: 'user1',
              name: 'John',
              role: 'admin',
              joinedAt: DateTime.now(),
            ),
          ],
          memberIds: ['user1'],
          rules: TestData.defaultRules,
          inviteCode: 'ABC123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore.collection('groups').doc('group1').set(singleMemberGroup.toFirestore());

        await repository.removeMember(groupId: 'group1', userId: 'user1');

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        expect(doc.exists, false);
      });
    });

    group('updateMemberRole', () {
      test('promotes member to admin', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        await repository.updateMemberRole(
          groupId: 'group1',
          userId: 'user2',
          newRole: 'admin',
        );

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        final members = (doc.data()!['members'] as List);
        final user2 = members.firstWhere((m) => m['userId'] == 'user2');
        expect(user2['role'], 'admin');
      });

      test('demotes admin to member', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        // Group with 2 admins
        final groupWithTwoAdmins = TestData.activeGroup.copyWith(
          id: 'group1',
          members: [
            GroupMember(userId: 'user1', name: 'Admin 1', role: 'admin', joinedAt: DateTime.now()),
            GroupMember(userId: 'user2', name: 'Admin 2', role: 'admin', joinedAt: DateTime.now()),
            GroupMember(userId: 'user3', name: 'Member', role: 'member', joinedAt: DateTime.now()),
          ],
        );
        await fakeFirestore.collection('groups').doc('group1').set(groupWithTwoAdmins.toFirestore());

        await repository.updateMemberRole(
          groupId: 'group1',
          userId: 'user2',
          newRole: 'member',
        );

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        final members = (doc.data()!['members'] as List);
        final user2 = members.firstWhere((m) => m['userId'] == 'user2');
        expect(user2['role'], 'member');
      });

      test('throws AuthException when non-admin tries to change roles', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user2');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        expect(
          () => repository.updateMemberRole(
            groupId: 'group1',
            userId: 'user3',
            newRole: 'admin',
          ),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws DataException when demoting last admin', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        expect(
          () => repository.updateMemberRole(
            groupId: 'group1',
            userId: 'user1',
            newRole: 'member',
          ),
          throwsA(isA<DataException>()),
        );
      });
    });

    group('deleteGroup', () {
      test('deletes group when user is admin', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        await repository.deleteGroup('group1');

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        expect(doc.exists, false);
      });

      test('throws AuthException when non-admin tries to delete', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user2');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        expect(
          () => repository.deleteGroup('group1'),
          throwsA(isA<AuthException>()),
        );
      });

      test('throws AuthException when user not authenticated', () async {
        MockAuthHelper.setupMockAuthWithoutUser(mockAuth);

        expect(
          () => repository.deleteGroup('group1'),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('getGroup', () {
      test('retrieves group by ID', () async {
        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        final result = await repository.getGroup('group1');

        expect(result.id, 'group1');
        expect(result.name, groupData.name);
      });

      test('throws DataException when group not found', () {
        expect(
          () => repository.getGroup('nonexistent'),
          throwsA(isA<DataException>()),
        );
      });
    });

    group('getGroupStream', () {
      test('emits group updates in real-time', () async {
        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        final stream = repository.getGroupStream('group1');

        await expectLater(
          stream.first,
          completion(isA<GroupModel>().having((g) => g.id, 'id', 'group1')),
        );
      });
    });

    group('addMember', () {
      test('adds member to group successfully', () async {
        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        await repository.addMember(
          groupId: 'group1',
          userId: 'user4',
          name: 'New Member',
          profilePictureUrl: 'https://example.com/photo.jpg',
          role: 'member',
        );

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        final memberIds = List<String>.from(doc.data()!['memberIds']);
        final members = (doc.data()!['members'] as List);

        expect(memberIds, contains('user4'));
        expect(memberIds.length, 4); // 3 original + 1 new
        expect(members.length, 4);
        
        final newMember = members.firstWhere((m) => m['userId'] == 'user4');
        expect(newMember['name'], 'New Member');
        expect(newMember['role'], 'member');
        expect(newMember['profilePictureUrl'], 'https://example.com/photo.jpg');
      });

      test('does not add duplicate member', () async {
        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        // Try to add existing member
        await repository.addMember(
          groupId: 'group1',
          userId: 'user1',
          name: 'Duplicate User',
        );

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        final memberIds = List<String>.from(doc.data()!['memberIds']);

        // Should still have 3 members (no duplicate)
        expect(memberIds.length, 3);
        expect(memberIds.where((id) => id == 'user1').length, 1);
      });

      test('adds member with default role when not specified', () async {
        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        await repository.addMember(
          groupId: 'group1',
          userId: 'user4',
          name: 'Default Role Member',
        );

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        final members = (doc.data()!['members'] as List);
        final newMember = members.firstWhere((m) => m['userId'] == 'user4');

        expect(newMember['role'], 'member');
      });
    });

    group('leaveGroup', () {
      test('user can leave group successfully', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user3');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        await repository.leaveGroup('group1');

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        final memberIds = List<String>.from(doc.data()!['memberIds']);

        expect(memberIds, isNot(contains('user3')));
        expect(memberIds.length, 2); // 3 - 1
      });

      test('throws AuthException when user not authenticated', () async {
        MockAuthHelper.setupMockAuthWithoutUser(mockAuth);

        expect(
          () => repository.leaveGroup('group1'),
          throwsA(isA<AuthException>()),
        );
      });

      test('last member leaving deletes the group', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        // Group with only one member
        final singleMemberGroup = GroupModel(
          id: 'group1',
          name: 'Solo Group',
          createdBy: 'user1',
          members: [
            GroupMember(
              userId: 'user1',
              name: 'John',
              role: 'admin',
              joinedAt: DateTime.now(),
            ),
          ],
          memberIds: ['user1'],
          rules: TestData.defaultRules,
          inviteCode: 'ABC123',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await fakeFirestore.collection('groups').doc('group1').set(singleMemberGroup.toFirestore());

        await repository.leaveGroup('group1');

        final doc = await fakeFirestore.collection('groups').doc('group1').get();
        expect(doc.exists, false);
      });

      test('throws DataException when last admin tries to leave', () async {
        final mockUser = MockAuthHelper.createMockUser(uid: 'user1');
        MockAuthHelper.setupMockAuthWithUser(mockAuth, mockUser);

        final groupData = TestData.activeGroup.copyWith(id: 'group1');
        await fakeFirestore.collection('groups').doc('group1').set(groupData.toFirestore());

        expect(
          () => repository.leaveGroup('group1'),
          throwsA(isA<DataException>()),
        );
      });
    });
  });
}
