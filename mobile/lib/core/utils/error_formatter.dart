import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorFormatter {
  static String format(dynamic error) {
    if (error == null) return 'Something went wrong. Please try again.';

    final str = error.toString().toLowerCase();

    // Network / connectivity errors
    if (str.contains('socketexception') ||
        str.contains('failed host lookup') ||
        str.contains('clientexception') ||
        str.contains('networkimage') ||
        str.contains('errno = 7') ||
        str.contains('connection refused') ||
        str.contains('network is unreachable')) {
      return 'Unable to connect. Please check your internet connection and try again.';
    }

    // Supabase AuthException — map to user-friendly messages
    if (error is AuthException) {
      return _mapAuthError(error.message);
    }

    // Generic exception prefix stripping
    final raw = error.toString();
    if (raw.startsWith('Exception: ')) {
      return _mapAuthError(raw.substring(11));
    }

    return 'Something went wrong. Please try again.';
  }

  static String _mapAuthError(String message) {
    final lower = message.toLowerCase();

    // Invalid credentials / wrong password / email not found
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid credentials') ||
        lower.contains('wrong password') ||
        lower.contains('user not found') ||
        lower.contains('no user found') ||
        lower.contains('email not confirmed') == false &&
            lower.contains('email') &&
            lower.contains('not found')) {
      return 'Incorrect email or password.';
    }

    // Email already in use
    if (lower.contains('user already registered') ||
        lower.contains('email already') ||
        lower.contains('already been registered')) {
      return 'An account with this email already exists. Please sign in instead.';
    }

    // Rate limiting / too many attempts
    if (lower.contains('too many') ||
        lower.contains('rate limit') ||
        lower.contains('email rate limit exceeded')) {
      return 'Too many login attempts. Please wait a few minutes and try again.';
    }

    // Weak password
    if (lower.contains('weak password') || lower.contains('password should')) {
      return 'Password must contain at least 6 characters.';
    }

    // Email confirmation required
    if (lower.contains('email not confirmed')) {
      return 'Please verify your email address before signing in.';
    }

    // Token / session expired
    if (lower.contains('refresh token') ||
        lower.contains('jwt expired') ||
        lower.contains('session expired')) {
      return 'Your session has expired. Please sign in again.';
    }

    // Generic fallback — do not expose raw Supabase message
    return 'Something went wrong. Please try again.';
  }
}
