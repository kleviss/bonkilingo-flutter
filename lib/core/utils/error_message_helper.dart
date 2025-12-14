import 'package:supabase_flutter/supabase_flutter.dart';
import '../network/api_exception.dart';

/// Helper class to extract user-friendly error messages from exceptions
class ErrorMessageHelper {
  /// Get a user-friendly error message from an exception
  static String getUserFriendlyMessage(dynamic error) {
    if (error is AuthException) {
      return _parseAuthException(error);
    }

    if (error is AppAuthException) {
      return _parseAppAuthException(error);
    }

    if (error is NetworkException) {
      return _parseNetworkException(error);
    }

    if (error is ServerException) {
      return _parseServerException(error);
    }

    // Try to parse string errors that might contain Supabase error info
    final errorString = error.toString();
    return _parseStringError(errorString);
  }

  /// Parse Supabase AuthException
  static String _parseAuthException(AuthException error) {
    // Check for specific error codes
    final message = error.message.toLowerCase();

    if (message.contains('invalid_credentials') ||
        message.contains('invalid login') ||
        error.statusCode == '400') {
      return 'Invalid email or password. Please check your credentials and try again.';
    }

    if (message.contains('email_not_confirmed') ||
        message.contains('email not confirmed')) {
      return 'Please verify your email address before signing in. Check your inbox for a confirmation email.';
    }

    if (message.contains('user_not_found')) {
      return 'No account found with this email address. Please sign up first.';
    }

    if (message.contains('email_already_registered') ||
        message.contains('user already registered')) {
      return 'An account with this email already exists. Please sign in instead.';
    }

    if (message.contains('weak_password') ||
        message.contains('password is too weak')) {
      return 'Password is too weak. Please use a stronger password with at least 6 characters.';
    }

    if (message.contains('invalid_email') ||
        message.contains('invalid email format')) {
      return 'Please enter a valid email address.';
    }

    if (message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('host lookup') ||
        message.contains('socket')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    // Extract the actual message if it's user-friendly
    if (error.message.isNotEmpty &&
        !error.message.contains('AuthApiException') &&
        !error.message.contains('AppAuthException')) {
      // Clean up the message
      String cleanMessage = error.message;
      // Remove technical prefixes
      cleanMessage = cleanMessage.replaceAll(RegExp(r'^.*?message:\s*'), '');
      cleanMessage = cleanMessage.replaceAll(RegExp(r',\s*statusCode:.*$'), '');
      cleanMessage = cleanMessage.replaceAll(RegExp(r',\s*code:.*$'), '');
      cleanMessage = cleanMessage.trim();

      if (cleanMessage.isNotEmpty && cleanMessage.length < 200) {
        return cleanMessage;
      }
    }

    return 'An authentication error occurred. Please try again.';
  }

  /// Parse AppAuthException (wrapper around Supabase errors)
  static String _parseAppAuthException(AppAuthException error) {
    final message = error.message;
    final lowerMessage = message.toLowerCase();

    // Check if it contains AuthException info (e.g., "AuthApiException (message: ...)")
    if (lowerMessage.contains('authapiexception')) {
      // Try multiple regex patterns to extract the message
      // Pattern 1: message: Invalid login credentials
      var match = RegExp(r'message:\s*([^,)]+)', caseSensitive: false)
          .firstMatch(message);
      if (match != null) {
        final innerMessage = match.group(1)?.trim() ?? '';
        if (innerMessage.isNotEmpty) {
          return _parseAuthExceptionMessage(innerMessage);
        }
      }

      // Pattern 2: Check for code field
      match =
          RegExp(r'code:\s*([^,)]+)', caseSensitive: false).firstMatch(message);
      if (match != null) {
        final code = match.group(1)?.trim().toLowerCase() ?? '';
        if (code == 'invalid_credentials') {
          return 'Invalid email or password. Please check your credentials and try again.';
        }
      }
    }

    // Check for common error patterns in the message itself
    if (lowerMessage.contains('invalid_credentials') ||
        lowerMessage.contains('invalid login')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }

    if (lowerMessage.contains('email_not_confirmed')) {
      return 'Please verify your email address before signing in. Check your inbox for a confirmation email.';
    }

    if (lowerMessage.contains('user_not_found')) {
      return 'No account found with this email address. Please sign up first.';
    }

    if (lowerMessage.contains('email_already_registered') ||
        lowerMessage.contains('user already registered')) {
      return 'An account with this email already exists. Please sign in instead.';
    }

    if (lowerMessage.contains('network') ||
        lowerMessage.contains('connection') ||
        lowerMessage.contains('timeout') ||
        lowerMessage.contains('host lookup') ||
        lowerMessage.contains('socket') ||
        lowerMessage.contains('failed host lookup')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    return 'An authentication error occurred. Please try again.';
  }

  /// Parse network exceptions
  static String _parseNetworkException(NetworkException error) {
    final message = error.message.toLowerCase();

    if (message.contains('timeout')) {
      return 'Request timed out. Please check your internet connection and try again.';
    }

    if (message.contains('host lookup') ||
        message.contains('failed host lookup') ||
        message.contains('socket')) {
      return 'Unable to connect to the server. Please check your internet connection and try again.';
    }

    return 'Network error. Please check your internet connection and try again.';
  }

  /// Parse server exceptions
  static String _parseServerException(ServerException error) {
    final message = error.message.toLowerCase();

    if (message.contains('500') || message.contains('internal server error')) {
      return 'Server error. Please try again later.';
    }

    if (message.contains('503') || message.contains('service unavailable')) {
      return 'Service temporarily unavailable. Please try again later.';
    }

    return 'An error occurred while processing your request. Please try again.';
  }

  /// Parse string errors (fallback)
  static String _parseStringError(String errorString) {
    final lowerError = errorString.toLowerCase();

    // Check for common patterns
    if (lowerError.contains('invalid_credentials') ||
        lowerError.contains('invalid login')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }

    if (lowerError.contains('email_not_confirmed')) {
      return 'Please verify your email address before signing in.';
    }

    if (lowerError.contains('user_not_found')) {
      return 'No account found with this email address.';
    }

    if (lowerError.contains('email_already_registered')) {
      return 'An account with this email already exists. Please sign in instead.';
    }

    if (lowerError.contains('network') ||
        lowerError.contains('connection') ||
        lowerError.contains('timeout') ||
        lowerError.contains('host lookup') ||
        lowerError.contains('socket') ||
        lowerError.contains('failed host lookup')) {
      return 'Network error. Please check your internet connection and try again.';
    }

    // If it's a technical error message, return generic message
    if (lowerError.contains('exception') ||
        lowerError.contains('error') ||
        lowerError.length > 100) {
      return 'An error occurred. Please try again.';
    }

    return errorString;
  }

  /// Helper to parse auth exception message strings
  static String _parseAuthExceptionMessage(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('invalid_credentials') ||
        lowerMessage.contains('invalid login')) {
      return 'Invalid email or password. Please check your credentials and try again.';
    }

    if (lowerMessage.contains('email_not_confirmed')) {
      return 'Please verify your email address before signing in.';
    }

    if (lowerMessage.contains('user_not_found')) {
      return 'No account found with this email address.';
    }

    if (lowerMessage.contains('email_already_registered')) {
      return 'An account with this email already exists. Please sign in instead.';
    }

    return message;
  }
}
