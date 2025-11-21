import 'package:equatable/equatable.dart';

/// Base class for application failures
abstract class Failure extends Equatable {
  final String message;
  
  const Failure(this.message);
  
  @override
  List<Object?> get props => [message];
}

/// Authentication failures
class AuthFailure extends Failure {
  const AuthFailure(super.message);
  
  static const wrongPassword = AuthFailure('Wrong password provided');
  static const userNotFound = AuthFailure('No user found with this email');
  static const emailAlreadyInUse = AuthFailure('Email already in use');
  static const weakPassword = AuthFailure('Password is too weak');
  static const invalidEmail = AuthFailure('Invalid email address');
  static const userDisabled = AuthFailure('This account has been disabled');
  static const operationNotAllowed = AuthFailure('Operation not allowed');
  static const tooManyRequests = AuthFailure('Too many requests. Please try again later');
}

/// Network failures
class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
  
  static const noConnection = NetworkFailure('No internet connection');
  static const timeout = NetworkFailure('Connection timeout');
  static const serverError = NetworkFailure('Server error occurred');
}

/// Database failures
class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
  
  static const notFound = DatabaseFailure('Data not found');
  static const permissionDenied = DatabaseFailure('Permission denied');
  static const unavailable = DatabaseFailure('Service unavailable');
}

/// Storage failures
class StorageFailure extends Failure {
  const StorageFailure(super.message);
  
  static const uploadFailed = StorageFailure('Failed to upload file');
  static const downloadFailed = StorageFailure('Failed to download file');
  static const fileTooLarge = StorageFailure('File size exceeds limit');
}

/// Validation failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Cache failures
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Unknown failures
class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unknown error occurred']);
}
