import 'package:intl/intl.dart';

/// Extension methods for DateTime
extension DateTimeExtensions on DateTime {
  /// Format as "MMM dd, yyyy" (e.g., "Jan 15, 2024")
  String toShortDateString() {
    return DateFormat('MMM dd, yyyy').format(this);
  }
  
  /// Format as "MMMM dd, yyyy" (e.g., "January 15, 2024")
  String toLongDateString() {
    return DateFormat('MMMM dd, yyyy').format(this);
  }
  
  /// Format as "MMM dd" (e.g., "Jan 15")
  String toMonthDay() {
    return DateFormat('MMM dd').format(this);
  }
  
  /// Format as relative time (e.g., "2 hours ago", "3 days ago")
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else if (difference.inDays < 365) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else {
      return '${(difference.inDays / 365).floor()}y ago';
    }
  }
  
  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }
  
  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year && 
           month == yesterday.month && 
           day == yesterday.day;
  }
  
  /// Format chat timestamp
  String toChatTimestamp() {
    if (isToday) {
      return DateFormat('HH:mm').format(this);
    } else if (isYesterday) {
      return 'Yesterday';
    } else if (DateTime.now().difference(this).inDays < 7) {
      return DateFormat('EEE').format(this); // Day name
    } else {
      return toShortDateString();
    }
  }
}

/// Extension methods for String
extension StringExtensions on String {
  /// Check if string is a valid email
  bool get isValidEmail {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(this);
  }
  
  /// Check if string is a valid password (min 8 chars, 1 uppercase, 1 lowercase, 1 number)
  bool get isValidPassword {
    return length >= 8 &&
        contains(RegExp(r'[A-Z]')) &&
        contains(RegExp(r'[a-z]')) &&
        contains(RegExp(r'[0-9]'));
  }
  
  /// Capitalize first letter
  String get capitalize {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
  
  /// Truncate string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

/// Extension methods for int
extension IntExtensions on int {
  /// Format as currency
  String toCurrency({String symbol = '\$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 0);
    return formatter.format(this);
  }
  
  /// Format with commas
  String toFormattedString() {
    final formatter = NumberFormat('#,###');
    return formatter.format(this);
  }
}

/// Extension methods for double
extension DoubleExtensions on double {
  /// Format as currency
  String toCurrency({String symbol = '\$'}) {
    final formatter = NumberFormat.currency(symbol: symbol, decimalDigits: 2);
    return formatter.format(this);
  }
}
