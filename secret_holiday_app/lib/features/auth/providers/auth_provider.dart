import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:secret_holiday_app/features/auth/data/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

/// Provides the AuthRepository instance
@riverpod
AuthRepository authRepository(Ref ref) {
  return AuthRepository();
}

/// Provides the current Firebase User stream
/// Updates automatically when auth state changes
@riverpod
Stream<User?> authStateChanges(Ref ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.authStateChanges;
}

/// Provides the current user as a one-time fetch
/// Use authStateChanges for listening to changes
@riverpod
Future<User?> currentUser(Ref ref) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.currentUser;
}

/// Auth actions provider - handles all authentication operations
/// This is a notifier that maintains loading and error states
@riverpod
class AuthNotifier extends _$AuthNotifier {
  @override
  FutureOr<User?> build() async {
    // Initialize with current user
    final authRepository = ref.watch(authRepositoryProvider);
    return authRepository.currentUser;
  }

  /// Sign in with email and password
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signIn(email: email, password: password);
      return authRepository.currentUser;
    });
  }

  /// Sign up with email and password
  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signUp(email: email, password: password, name: name);
      return authRepository.currentUser;
    });
  }

  /// Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.signOut();
      return null;
    });
  }

  /// Send password reset email
  Future<void> resetPassword(String email) async {
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.resetPassword(email);
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.resendVerificationEmail();
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    final authRepository = ref.read(authRepositoryProvider);
    return authRepository.currentUser?.emailVerified ?? false;
  }

  /// Reload user data
  Future<void> reloadUser() async {
    final authRepository = ref.read(authRepositoryProvider);
    await authRepository.currentUser?.reload();
    state = AsyncValue.data(authRepository.currentUser);
  }
}
