import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secret_holiday_app/core/error/exceptions.dart';
import 'package:secret_holiday_app/core/error/failures.dart';
import 'package:secret_holiday_app/core/utils/logger.dart';
import 'package:secret_holiday_app/features/auth/data/models/user_model.dart';

/// Repository for authentication operations
class AuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;
  
  /// Get current user
  User? get currentUser => _auth.currentUser;
  
  /// Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  /// Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      AppLogger.info('Attempting to sign up user: $email');
      
      // Create user in Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('Failed to create user');
      }
      
      // Send email verification
      await user.sendEmailVerification();
      
      // Create user document in Firestore
      final now = DateTime.now();
      final userModel = UserModel(
        id: user.uid,
        email: email,
        name: name,
        createdAt: now,
        updatedAt: now,
      );
      
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(userModel.toFirestore());
      
      AppLogger.info('User signed up successfully: ${user.uid}');
      return userModel;
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth error during sign up', e);
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during sign up', e, stackTrace);
      throw const AuthException('Failed to sign up');
    }
  }
  
  /// Sign in with email and password
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('Attempting to sign in user: $email');
      
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final user = userCredential.user;
      if (user == null) {
        throw const AuthException('Failed to sign in');
      }
      
      // Get user data from Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      
      if (!userDoc.exists) {
        throw const AuthException('User data not found');
      }
      
      AppLogger.info('User signed in successfully: ${user.uid}');
      return UserModel.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth error during sign in', e);
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during sign in', e, stackTrace);
      throw const AuthException('Failed to sign in');
    }
  }
  
  /// Sign out
  Future<void> signOut() async {
    try {
      AppLogger.info('Signing out user');
      await _auth.signOut();
    } catch (e, stackTrace) {
      AppLogger.error('Error signing out', e, stackTrace);
      throw const AuthException('Failed to sign out');
    }
  }
  
  /// Send password reset email
  Future<void> resetPassword(String email) async {
    try {
      AppLogger.info('Sending password reset email to: $email');
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      AppLogger.error('Firebase Auth error during password reset', e);
      throw _handleAuthException(e);
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during password reset', e, stackTrace);
      throw const AuthException('Failed to send password reset email');
    }
  }
  
  /// Resend verification email
  Future<void> resendVerificationEmail() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw const AuthException('No user signed in');
      }
      
      await user.sendEmailVerification();
      AppLogger.info('Verification email sent to: ${user.email}');
    } catch (e, stackTrace) {
      if (e is AuthException) rethrow;
      AppLogger.error('Error sending verification email', e, stackTrace);
      throw const AuthException('Failed to send verification email');
    }
  }
  
  /// Get user data from Firestore
  Future<UserModel> getUserData(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        throw const DatabaseFailure('User data not found');
      }
      
      return UserModel.fromFirestore(userDoc);
    } catch (e, stackTrace) {
      AppLogger.error('Error getting user data', e, stackTrace);
      throw const DatabaseFailure('Failed to get user data');
    }
  }
  
  /// Update user data
  Future<void> updateUserData(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(user.id)
          .update(user.toFirestore());
      
      AppLogger.info('User data updated: ${user.id}');
    } catch (e, stackTrace) {
      AppLogger.error('Error updating user data', e, stackTrace);
      throw const DatabaseFailure('Failed to update user data');
    }
  }
  
  /// Handle Firebase Auth exceptions
  AuthException _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return const AuthException('No user found with this email');
      case 'wrong-password':
        return const AuthException('Wrong password provided');
      case 'email-already-in-use':
        return const AuthException('Email already in use');
      case 'weak-password':
        return const AuthException('Password is too weak');
      case 'invalid-email':
        return const AuthException('Invalid email address');
      case 'user-disabled':
        return const AuthException('This account has been disabled');
      case 'too-many-requests':
        return const AuthException('Too many requests. Please try again later');
      default:
        return AuthException(e.message ?? 'Authentication error');
    }
  }
}
