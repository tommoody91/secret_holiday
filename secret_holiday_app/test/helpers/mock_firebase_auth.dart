import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/annotations.dart';

// This annotation tells mockito's build_runner to generate mocks for these classes
// Run: dart run build_runner build --delete-conflicting-outputs
@GenerateMocks([
  FirebaseAuth,
  User,
  UserCredential,
])
void main() {}
