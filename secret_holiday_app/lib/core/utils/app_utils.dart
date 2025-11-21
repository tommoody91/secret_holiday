import 'dart:math';

/// Utility class for various helper functions
class AppUtils {
  /// Generate a random invite code
  static String generateInviteCode({int length = 6}) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }
  
  /// Generate a unique ID
  static String generateUniqueId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(999999);
    return '$timestamp$random';
  }
  
  /// Validate passport number format (basic validation)
  static bool isValidPassportNumber(String passportNumber) {
    // Basic check: 6-9 alphanumeric characters
    return RegExp(r'^[A-Z0-9]{6,9}$').hasMatch(passportNumber.toUpperCase());
  }
  
  /// Calculate trip duration in days
  static int calculateTripDuration(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }
  
  /// Get budget category name
  static String getBudgetCategoryName(int budget) {
    if (budget < 1000) {
      return 'Budget-Friendly';
    } else if (budget < 2500) {
      return 'Mid-Range';
    } else {
      return 'Luxury';
    }
  }
  
  /// Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1048576) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1073741824) {
      return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1073741824).toStringAsFixed(1)} GB';
  }
  
  /// Show snackbar helper
  static void showErrorSnackbar(String message) {
    // This will be implemented with context when needed
    // For now, it's a placeholder for the pattern
  }
  
  /// Validate group name
  static bool isValidGroupName(String name) {
    return name.trim().isNotEmpty && name.length >= 3 && name.length <= 50;
  }
  
  /// Get initials from name
  static String getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
  
  /// Calculate days until trip
  static int daysUntilTrip(DateTime tripDate) {
    final now = DateTime.now();
    return tripDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }
}
