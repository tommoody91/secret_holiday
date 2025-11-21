import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:secret_holiday_app/features/auth/data/repositories/auth_repository.dart';
import 'package:secret_holiday_app/features/auth/data/models/user_model.dart';
import 'package:secret_holiday_app/core/error/exceptions.dart';
import 'package:secret_holiday_app/core/error/failures.dart';
import '../../helpers/mock_firebase_auth.mocks.dart';
import '../../helpers/mock_auth_helper.dart';

void main() {
  group('AuthRepository', () {
    late FakeFirebaseFirestore fakeFirestore;
    late MockFirebaseAuth mockAuth;
    late AuthRepository repository;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      mockAuth = MockFirebaseAuth();
      repository = AuthRepository(auth: mockAuth, firestore: fakeFirestore);
    });

    group('signUp', () {
      test('creates user in Firebase Auth and Firestore successfully', () async {
        // Arrange
        final mockUser = MockAuthHelper.createMockUser(
          uid: 'new-user-id',
          email: 'newuser@example.com',
          emailVerified: false,
        );
        final mockCredential = MockAuthHelper.createMockUserCredential(mockUser);

        when(mockAuth.createUserWithEmailAndPassword(
          email: 'newuser@example.com',
          password: 'Password123!',
        )).thenAnswer((_) async => mockCredential);

        // Act
        final result = await repository.signUp(
          email: 'newuser@example.com',
          password: 'Password123!',
          name: 'New User',
        );

        // Assert
        expect(result.id, 'new-user-id');
        expect(result.email, 'newuser@example.com');
        expect(result.name, 'New User');

        // Verify user created in Auth
        verify(mockAuth.createUserWithEmailAndPassword(
          email: 'newuser@example.com',
          password: 'Password123!',
        )).called(1);

        // Verify email verification sent
        verify(mockUser.sendEmailVerification()).called(1);

        // Verify user document created in Firestore
        final userDoc = await fakeFirestore.collection('users').doc('new-user-id').get();
        expect(userDoc.exists, true);
        expect(userDoc.data()!['email'], 'newuser@example.com');
        expect(userDoc.data()!['name'], 'New User');
      });

      test('throws AuthException when email already in use', () async {
        // Arrange
        when(mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(
          FirebaseAuthException(code: 'email-already-in-use'),
        );

        // Act & Assert
        expect(
          () => repository.signUp(
            email: 'existing@example.com',
            password: 'Password123!',
            name: 'Test User',
          ),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Email already in use',
          )),
        );
      });

      test('throws AuthException when password is weak', () async {
        // Arrange
        when(mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(
          FirebaseAuthException(code: 'weak-password'),
        );

        // Act & Assert
        expect(
          () => repository.signUp(
            email: 'test@example.com',
            password: '123',
            name: 'Test User',
          ),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Password is too weak',
          )),
        );
      });

      test('throws AuthException when email is invalid', () async {
        // Arrange
        when(mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(
          FirebaseAuthException(code: 'invalid-email'),
        );

        // Act & Assert
        expect(
          () => repository.signUp(
            email: 'invalid-email',
            password: 'Password123!',
            name: 'Test User',
          ),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Invalid email address',
          )),
        );
      });

      test('throws AuthException when user creation fails', () async {
        // Arrange
        final mockCredential = MockUserCredential();
        when(mockCredential.user).thenReturn(null);

        when(mockAuth.createUserWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockCredential);

        // Act & Assert
        expect(
          () => repository.signUp(
            email: 'test@example.com',
            password: 'Password123!',
            name: 'Test User',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signIn', () {
      test('signs in user and retrieves data from Firestore', () async {
        // Arrange
        final mockUser = MockAuthHelper.createMockUser(
          uid: 'existing-user-id',
          email: 'john@example.com',
        );
        final mockCredential = MockAuthHelper.createMockUserCredential(mockUser);

        // Pre-populate Firestore
        await fakeFirestore.collection('users').doc('existing-user-id').set({
          'id': 'existing-user-id',
          'email': 'john@example.com',
          'name': 'John Doe',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        when(mockAuth.signInWithEmailAndPassword(
          email: 'john@example.com',
          password: 'Password123!',
        )).thenAnswer((_) async => mockCredential);

        // Act
        final result = await repository.signIn(
          email: 'john@example.com',
          password: 'Password123!',
        );

        // Assert
        expect(result.id, 'existing-user-id');
        expect(result.email, 'john@example.com');
        expect(result.name, 'John Doe');

        verify(mockAuth.signInWithEmailAndPassword(
          email: 'john@example.com',
          password: 'Password123!',
        )).called(1);
      });

      test('throws AuthException when user not found', () async {
        // Arrange
        when(mockAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(
          FirebaseAuthException(code: 'user-not-found'),
        );

        // Act & Assert
        expect(
          () => repository.signIn(
            email: 'nonexistent@example.com',
            password: 'Password123!',
          ),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'No user found with this email',
          )),
        );
      });

      test('throws AuthException when password is wrong', () async {
        // Arrange
        when(mockAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(
          FirebaseAuthException(code: 'wrong-password'),
        );

        // Act & Assert
        expect(
          () => repository.signIn(
            email: 'john@example.com',
            password: 'WrongPassword',
          ),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Wrong password provided',
          )),
        );
      });

      test('throws AuthException when account is disabled', () async {
        // Arrange
        when(mockAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(
          FirebaseAuthException(code: 'user-disabled'),
        );

        // Act & Assert
        expect(
          () => repository.signIn(
            email: 'disabled@example.com',
            password: 'Password123!',
          ),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'This account has been disabled',
          )),
        );
      });

      test('throws AuthException when too many requests', () async {
        // Arrange
        when(mockAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenThrow(
          FirebaseAuthException(code: 'too-many-requests'),
        );

        // Act & Assert
        expect(
          () => repository.signIn(
            email: 'test@example.com',
            password: 'Password123!',
          ),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Too many requests. Please try again later',
          )),
        );
      });

      test('throws AuthException when user data not found in Firestore', () async {
        // Arrange
        final mockUser = MockAuthHelper.createMockUser();
        final mockCredential = MockAuthHelper.createMockUserCredential(mockUser);

        when(mockAuth.signInWithEmailAndPassword(
          email: anyNamed('email'),
          password: anyNamed('password'),
        )).thenAnswer((_) async => mockCredential);

        // Note: Not creating user document in Firestore

        // Act & Assert
        expect(
          () => repository.signIn(
            email: 'test@example.com',
            password: 'Password123!',
          ),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('signOut', () {
      test('signs out user successfully', () async {
        // Arrange
        when(mockAuth.signOut()).thenAnswer((_) async => {});

        // Act
        await repository.signOut();

        // Assert
        verify(mockAuth.signOut()).called(1);
      });

      test('throws AuthException when sign out fails', () async {
        // Arrange
        when(mockAuth.signOut()).thenThrow(Exception('Sign out failed'));

        // Act & Assert
        expect(
          () => repository.signOut(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('resetPassword', () {
      test('sends password reset email successfully', () async {
        // Arrange
        when(mockAuth.sendPasswordResetEmail(
          email: 'john@example.com',
        )).thenAnswer((_) async => {});

        // Act
        await repository.resetPassword('john@example.com');

        // Assert
        verify(mockAuth.sendPasswordResetEmail(
          email: 'john@example.com',
        )).called(1);
      });

      test('throws AuthException when email not found', () async {
        // Arrange
        when(mockAuth.sendPasswordResetEmail(
          email: anyNamed('email'),
        )).thenThrow(
          FirebaseAuthException(code: 'user-not-found'),
        );

        // Act & Assert
        expect(
          () => repository.resetPassword('nonexistent@example.com'),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'No user found with this email',
          )),
        );
      });

      test('throws AuthException when email is invalid', () async {
        // Arrange
        when(mockAuth.sendPasswordResetEmail(
          email: anyNamed('email'),
        )).thenThrow(
          FirebaseAuthException(code: 'invalid-email'),
        );

        // Act & Assert
        expect(
          () => repository.resetPassword('invalid-email'),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'Invalid email address',
          )),
        );
      });
    });

    group('resendVerificationEmail', () {
      test('sends verification email successfully', () async {
        // Arrange
        final mockUser = MockAuthHelper.createMockUser(emailVerified: false);
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        await repository.resendVerificationEmail();

        // Assert
        verify(mockUser.sendEmailVerification()).called(1);
      });

      test('throws AuthException when no user signed in', () async {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act & Assert
        expect(
          () => repository.resendVerificationEmail(),
          throwsA(isA<AuthException>().having(
            (e) => e.message,
            'message',
            'No user signed in',
          )),
        );
      });

      test('throws AuthException when email verification fails', () async {
        // Arrange
        final mockUser = MockAuthHelper.createMockUser();
        when(mockAuth.currentUser).thenReturn(mockUser);
        when(mockUser.sendEmailVerification()).thenThrow(Exception('Failed'));

        // Act & Assert
        expect(
          () => repository.resendVerificationEmail(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('getUserData', () {
      test('retrieves user data from Firestore', () async {
        // Arrange
        await fakeFirestore.collection('users').doc('user123').set({
          'id': 'user123',
          'email': 'john@example.com',
          'name': 'John Doe',
          'profilePictureUrl': 'https://example.com/photo.jpg',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });

        // Act
        final result = await repository.getUserData('user123');

        // Assert
        expect(result.id, 'user123');
        expect(result.email, 'john@example.com');
        expect(result.name, 'John Doe');
        expect(result.profilePictureUrl, 'https://example.com/photo.jpg');
      });

      test('throws DatabaseFailure when user not found', () async {
        // Act & Assert
        expect(
          () => repository.getUserData('nonexistent'),
          throwsA(isA<DatabaseFailure>()),
        );
      });
    });

    group('updateUserData', () {
      test('updates user data in Firestore successfully', () async {
        // Arrange
        final now = DateTime.now();
        await fakeFirestore.collection('users').doc('user123').set({
          'id': 'user123',
          'email': 'john@example.com',
          'name': 'John Doe',
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        });

        final updatedUser = UserModel(
          id: 'user123',
          email: 'john@example.com',
          name: 'John Smith', // Changed name
          profilePictureUrl: 'https://example.com/new-photo.jpg', // Added photo
          createdAt: now,
          updatedAt: DateTime.now(),
        );

        // Act
        await repository.updateUserData(updatedUser);

        // Assert
        final doc = await fakeFirestore.collection('users').doc('user123').get();
        expect(doc.data()!['name'], 'John Smith');
        expect(doc.data()!['profilePictureUrl'], 'https://example.com/new-photo.jpg');
      });

      test('throws DatabaseFailure when update fails', () async {
        // Arrange
        final user = UserModel(
          id: 'nonexistent',
          email: 'test@example.com',
          name: 'Test',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Act & Assert
        expect(
          () => repository.updateUserData(user),
          throwsA(isA<DatabaseFailure>()),
        );
      });
    });

    group('currentUser', () {
      test('returns current user when signed in', () {
        // Arrange
        final mockUser = MockAuthHelper.createMockUser();
        when(mockAuth.currentUser).thenReturn(mockUser);

        // Act
        final result = repository.currentUser;

        // Assert
        expect(result, isNotNull);
        expect(result!.uid, 'test-user-id');
        expect(result.email, 'test@example.com');
      });

      test('returns null when no user signed in', () {
        // Arrange
        when(mockAuth.currentUser).thenReturn(null);

        // Act
        final result = repository.currentUser;

        // Assert
        expect(result, isNull);
      });
    });

    group('authStateChanges', () {
      test('emits user when authentication state changes', () async {
        // Arrange
        final mockUser = MockAuthHelper.createMockUser();
        when(mockAuth.authStateChanges()).thenAnswer(
          (_) => Stream.value(mockUser),
        );

        // Act
        final stream = repository.authStateChanges;

        // Assert
        await expectLater(
          stream,
          emits(isA<MockUser>().having(
            (u) => u.uid,
            'uid',
            'test-user-id',
          )),
        );
      });

      test('emits null when user signs out', () async {
        // Arrange
        when(mockAuth.authStateChanges()).thenAnswer(
          (_) => Stream.value(null),
        );

        // Act
        final stream = repository.authStateChanges;

        // Assert
        await expectLater(stream, emits(null));
      });
    });
  });
}
