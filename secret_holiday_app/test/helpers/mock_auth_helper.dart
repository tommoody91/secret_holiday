import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'mock_firebase_auth.mocks.dart';

/// Helper class to create consistent mock users and credentials for testing
class MockAuthHelper {
  /// Create a mock User with default or custom properties
  static MockUser createMockUser({
    String uid = 'test-user-id',
    String email = 'test@example.com',
    String? displayName = 'Test User',
    String? photoURL,
    bool emailVerified = true,
  }) {
    final mockUser = MockUser();
    
    when(mockUser.uid).thenReturn(uid);
    when(mockUser.email).thenReturn(email);
    when(mockUser.displayName).thenReturn(displayName);
    when(mockUser.photoURL).thenReturn(photoURL);
    when(mockUser.emailVerified).thenReturn(emailVerified);
    
    // Mock reload method (used in email verification)
    when(mockUser.reload()).thenAnswer((_) async => {});
    
    // Mock sendEmailVerification
    when(mockUser.sendEmailVerification()).thenAnswer((_) async => {});
    
    // Mock delete method
    when(mockUser.delete()).thenAnswer((_) async => {});
    
    return mockUser;
  }
  
  /// Create a mock UserCredential with a user
  static MockUserCredential createMockUserCredential(User user) {
    final mockCredential = MockUserCredential();
    when(mockCredential.user).thenReturn(user);
    return mockCredential;
  }
  
  /// Set up a mock FirebaseAuth instance with a current user
  static void setupMockAuthWithUser(MockFirebaseAuth mockAuth, MockUser mockUser) {
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(mockUser));
  }
  
  /// Set up a mock FirebaseAuth instance with no current user
  static void setupMockAuthWithoutUser(MockFirebaseAuth mockAuth) {
    when(mockAuth.currentUser).thenReturn(null);
    when(mockAuth.authStateChanges()).thenAnswer((_) => Stream.value(null));
  }
}
