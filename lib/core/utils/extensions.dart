import 'package:intl/intl.dart';

extension StringExtensions on String {
  /// Capitalize the first letter of the string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
    );
    return emailRegex.hasMatch(this);
  }

  /// Get word count in string
  int get wordCount {
    if (trim().isEmpty) return 0;
    return trim().split(RegExp(r'\s+')).length;
  }

  /// Truncate string with ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }
}

extension DateTimeExtensions on DateTime {
  /// Format date as 'MM/dd/yyyy'
  String get formattedDate {
    return DateFormat('MM/dd/yyyy').format(this);
  }

  /// Format date as 'MMM dd, yyyy' (e.g., Jan 01, 2024)
  String get formattedDateLong {
    return DateFormat('MMM dd, yyyy').format(this);
  }

  /// Format time as 'hh:mm a' (e.g., 10:30 AM)
  String get formattedTime {
    return DateFormat('hh:mm a').format(this);
  }

  /// Get relative time (e.g., '2 hours ago')
  String get relativeTime {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return 'Just now';
    }
  }
}

extension IntExtensions on int {
  /// Format number with thousands separator (e.g., 1000 -> 1,000)
  String get formatted {
    return NumberFormat('#,###').format(this);
  }
}

extension ListExtensions<T> on List<T> {
  /// Safely get element at index or return null
  T? getOrNull(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }
}

