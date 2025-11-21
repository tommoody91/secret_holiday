import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/logger.dart';
import '../models/group_model.dart';

/// Repository for group-related operations with Firebase Firestore
class GroupRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  GroupRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  // Collection references
  CollectionReference get _groupsCollection => _firestore.collection('groups');
  CollectionReference get _usersCollection => _firestore.collection('users');

  /// Generate a random 6-character invite code
  String generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // Exclude confusing characters
    final random = Random();
    return List.generate(6, (index) => chars[random.nextInt(chars.length)]).join();
  }

  /// Validate if an invite code exists and return the group
  Future<GroupModel?> validateInviteCode(String inviteCode) async {
    try {
      AppLogger.info('Validating invite code: $inviteCode');
      
      final querySnapshot = await _groupsCollection
          .where('inviteCode', isEqualTo: inviteCode.toUpperCase())
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        AppLogger.warning('Invite code not found: $inviteCode');
        return null;
      }

      final groupDoc = querySnapshot.docs.first;
      return GroupModel.fromFirestore(groupDoc);
    } catch (e) {
      AppLogger.error('Error validating invite code: $e');
      throw ServerException('Failed to validate invite code');
    }
  }

  /// Create a new group
  Future<GroupModel> createGroup({
    required String name,
    required int budgetPerPerson,
    required int maxTripDays,
    required String luggageAllowance,
    bool noRepeatCountries = false,
    List<String> customRules = const [],
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('User not authenticated');
      }

      AppLogger.info('Creating group: $name for user: ${user.uid}');

      // Generate unique invite code
      String inviteCode = generateInviteCode();
      bool codeExists = true;
      int attempts = 0;
      
      while (codeExists && attempts < 10) {
        final existing = await validateInviteCode(inviteCode);
        if (existing == null) {
          codeExists = false;
        } else {
          inviteCode = generateInviteCode();
          attempts++;
        }
      }

      if (codeExists) {
        throw ServerException('Failed to generate unique invite code');
      }

      final now = DateTime.now();
      final groupRef = _groupsCollection.doc();

      // Get user display name
      final userDoc = await _usersCollection.doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final userName = userData?['name'] ?? user.displayName ?? 'Unknown';

      final groupData = GroupModel(
        id: groupRef.id,
        name: name,
        createdBy: user.uid,
        currentOrganizerId: null, // No organizer until first trip
        members: [
          GroupMember(
            userId: user.uid,
            name: userName,
            profilePictureUrl: user.photoURL,
            role: 'admin',
            joinedAt: now,
          ),
        ],
        memberIds: [user.uid], // Array for efficient querying
        rules: GroupRules(
          budgetPerPerson: budgetPerPerson,
          maxTripDays: maxTripDays,
          luggageAllowance: luggageAllowance,
          noRepeatCountries: noRepeatCountries,
          customRules: customRules,
        ),
        inviteCode: inviteCode,
        createdAt: now,
        updatedAt: now,
      );

      await groupRef.set(groupData.toFirestore());
      AppLogger.info('Group created successfully: ${groupRef.id}');

      return groupData;
    } on AuthException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      AppLogger.error('Error creating group: $e');
      throw ServerException('Failed to create group');
    }
  }

  /// Join an existing group using invite code
  Future<GroupModel> joinGroup(String inviteCode) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('User not authenticated');
      }

      AppLogger.info('User ${user.uid} joining group with code: $inviteCode');

      // Validate invite code
      final group = await validateInviteCode(inviteCode);
      if (group == null) {
        throw DataException('Invalid invite code');
      }

      // Check if user is already a member
      final isAlreadyMember = group.members.any((member) => member.userId == user.uid);
      if (isAlreadyMember) {
        AppLogger.warning('User already a member of group: ${group.id}');
        return group;
      }

      // Get user display name
      final userDoc = await _usersCollection.doc(user.uid).get();
      final userData = userDoc.data() as Map<String, dynamic>?;
      final userName = userData?['name'] ?? user.displayName ?? 'Unknown';

      // Add user as member
      final newMember = GroupMember(
        userId: user.uid,
        name: userName,
        profilePictureUrl: user.photoURL,
        role: 'member',
        joinedAt: DateTime.now(),
      );

      final updatedMembers = [...group.members, newMember];
      final updatedMemberIds = [...group.memberIds, user.uid];
      
      await _groupsCollection.doc(group.id).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
        'memberIds': updatedMemberIds,
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info('User joined group successfully: ${group.id}');

      return group.copyWith(
        members: updatedMembers,
        memberIds: updatedMemberIds,
        updatedAt: DateTime.now(),
      );
    } on AuthException {
      rethrow;
    } on DataException {
      rethrow;
    } catch (e) {
      AppLogger.error('Error joining group: $e');
      throw ServerException('Failed to join group');
    }
  }

  /// Get all groups for the current user
  Stream<List<GroupModel>> getUserGroups() {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('User not authenticated');
    }

    AppLogger.info('Getting groups for user: ${user.uid}');

    // Use memberIds array for efficient querying
    return _groupsCollection
        .where('memberIds', arrayContains: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => GroupModel.fromFirestore(doc))
              .toList();
        });
  }

  /// Get a specific group by ID
  Future<GroupModel> getGroup(String groupId) async {
    try {
      AppLogger.info('Getting group: $groupId');
      
      final doc = await _groupsCollection.doc(groupId).get();
      
      if (!doc.exists) {
        throw DataException('Group not found');
      }

      return GroupModel.fromFirestore(doc);
    } catch (e) {
      if (e is DataException) rethrow;
      AppLogger.error('Error getting group: $e');
      throw ServerException('Failed to get group');
    }
  }

  /// Get a specific group as a stream
  Stream<GroupModel> getGroupStream(String groupId) {
    AppLogger.info('Watching group: $groupId');
    
    return _groupsCollection
        .doc(groupId)
        .snapshots()
        .map((doc) {
          if (!doc.exists) {
            throw DataException('Group not found');
          }
          return GroupModel.fromFirestore(doc);
        });
  }

  /// Update group settings
  Future<void> updateGroupSettings({
    required String groupId,
    String? name,
    GroupRules? rules,
    DateTime? upcomingTripStartDate,
    DateTime? upcomingTripEndDate,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('User not authenticated');
      }

      AppLogger.info('Updating group settings: $groupId');

      // Check if user is admin
      final group = await getGroup(groupId);
      final userMember = group.members.firstWhere(
        (member) => member.userId == user.uid,
        orElse: () => throw AuthException('User not a member of this group'),
      );

      if (userMember.role != 'admin') {
        throw AuthException('Only admins can update group settings');
      }

      final updates = <String, dynamic>{
        'updatedAt': Timestamp.now(),
      };

      if (name != null) updates['name'] = name;
      if (rules != null) updates['rules'] = rules.toJson();
      if (upcomingTripStartDate != null) {
        updates['upcomingTripStartDate'] = Timestamp.fromDate(upcomingTripStartDate);
      }
      if (upcomingTripEndDate != null) {
        updates['upcomingTripEndDate'] = Timestamp.fromDate(upcomingTripEndDate);
      }

      await _groupsCollection.doc(groupId).update(updates);
      AppLogger.info('Group settings updated successfully');
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Error updating group settings: $e');
      throw ServerException('Failed to update group settings');
    }
  }

  /// Add a member to the group (used internally, prefer joinGroup)
  Future<void> addMember({
    required String groupId,
    required String userId,
    required String name,
    String? profilePictureUrl,
    String role = 'member',
  }) async {
    try {
      AppLogger.info('Adding member $userId to group $groupId');

      final group = await getGroup(groupId);
      
      // Check if already a member
      if (group.members.any((m) => m.userId == userId)) {
        AppLogger.warning('User already a member');
        return;
      }

      final newMember = GroupMember(
        userId: userId,
        name: name,
        profilePictureUrl: profilePictureUrl,
        role: role,
        joinedAt: DateTime.now(),
      );

      final updatedMembers = [...group.members, newMember];
      final updatedMemberIds = [...group.memberIds, userId];

      await _groupsCollection.doc(groupId).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
        'memberIds': updatedMemberIds,
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info('Member added successfully');
    } catch (e) {
      AppLogger.error('Error adding member: $e');
      throw ServerException('Failed to add member');
    }
  }

  /// Remove a member from the group
  Future<void> removeMember({
    required String groupId,
    required String userId,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw AuthException('User not authenticated');
      }

      AppLogger.info('Removing member $userId from group $groupId');

      final group = await getGroup(groupId);

      // Check permissions: admin can remove anyone, users can remove themselves
      final currentUserMember = group.members.firstWhere(
        (m) => m.userId == currentUser.uid,
        orElse: () => throw AuthException('Not a member of this group'),
      );

      if (currentUserMember.role != 'admin' && currentUser.uid != userId) {
        throw AuthException('Only admins can remove other members');
      }

      final updatedMembers = group.members.where((m) => m.userId != userId).toList();
      final updatedMemberIds = group.memberIds.where((id) => id != userId).toList();

      // If no members left, delete the group
      if (updatedMembers.isEmpty) {
        await _groupsCollection.doc(groupId).delete();
        AppLogger.info('Group deleted (no members left)');
        return;
      }

      // Don't allow removing last admin (only check if there are remaining members)
      final memberToRemove = group.members.firstWhere((m) => m.userId == userId);
      if (memberToRemove.role == 'admin') {
        final remainingAdmins = updatedMembers.where((m) => m.role == 'admin').toList();
        if (remainingAdmins.isEmpty) {
          throw DataException('Cannot remove the last admin');
        }
      }

      await _groupsCollection.doc(groupId).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
        'memberIds': updatedMemberIds,
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info('Member removed successfully');
    } on AuthException {
      rethrow;
    } on DataException {
      rethrow;
    } catch (e) {
      AppLogger.error('Error removing member: $e');
      throw ServerException('Failed to remove member');
    }
  }

  /// Update a member's role (admin only)
  Future<void> updateMemberRole({
    required String groupId,
    required String userId,
    required String newRole, // 'admin' or 'member'
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw AuthException('User not authenticated');
      }

      AppLogger.info('Updating member role: $userId to $newRole in group $groupId');

      final group = await getGroup(groupId);

      // Check if current user is admin
      final currentUserMember = group.members.firstWhere(
        (m) => m.userId == currentUser.uid,
        orElse: () => throw AuthException('Not a member of this group'),
      );

      if (currentUserMember.role != 'admin') {
        throw AuthException('Only admins can change member roles');
      }

      // Don't allow demoting last admin
      if (newRole == 'member') {
        final admins = group.members.where((m) => m.role == 'admin').toList();
        final memberToUpdate = group.members.firstWhere((m) => m.userId == userId);
        
        if (memberToUpdate.role == 'admin' && admins.length == 1) {
          throw DataException('Cannot demote the last admin');
        }
      }

      final updatedMembers = group.members.map((member) {
        if (member.userId == userId) {
          return GroupMember(
            userId: member.userId,
            name: member.name,
            profilePictureUrl: member.profilePictureUrl,
            role: newRole,
            yearLastOrganized: member.yearLastOrganized,
            joinedAt: member.joinedAt,
          );
        }
        return member;
      }).toList();

      await _groupsCollection.doc(groupId).update({
        'members': updatedMembers.map((m) => m.toJson()).toList(),
        'updatedAt': Timestamp.now(),
      });

      AppLogger.info('Member role updated successfully');
    } on AuthException {
      rethrow;
    } on DataException {
      rethrow;
    } catch (e) {
      AppLogger.error('Error updating member role: $e');
      throw ServerException('Failed to update member role');
    }
  }

  /// Leave a group (convenience method)
  Future<void> leaveGroup(String groupId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException('User not authenticated');
    }

    await removeMember(groupId: groupId, userId: user.uid);
  }

  /// Delete a group (admin only)
  Future<void> deleteGroup(String groupId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException('User not authenticated');
      }

      AppLogger.info('Deleting group: $groupId');

      final group = await getGroup(groupId);

      // Check if user is admin
      final userMember = group.members.firstWhere(
        (m) => m.userId == user.uid,
        orElse: () => throw AuthException('Not a member of this group'),
      );

      if (userMember.role != 'admin') {
        throw AuthException('Only admins can delete groups');
      }

      await _groupsCollection.doc(groupId).delete();
      AppLogger.info('Group deleted successfully');
    } on AuthException {
      rethrow;
    } catch (e) {
      AppLogger.error('Error deleting group: $e');
      throw ServerException('Failed to delete group');
    }
  }
}
