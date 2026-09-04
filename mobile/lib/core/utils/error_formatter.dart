import 'package:supabase_flutter/supabase_flutter.dart';

class ErrorFormatter {
  static String format(dynamic error) {
    if (error == null) return 'An unexpected error occurred.';

    final str = error.toString();
    if (error is AuthException) {
      return error.message;
    }
    if (str.contains('SocketException') ||
        str.contains('Failed host lookup') ||
        str.contains('ClientException') ||
        str.contains('NetworkImage') ||
        str.contains('errno = 7')) {
      return 'No internet connection. Please check your network and try again.';
    }
    if (str.startsWith('Exception: ')) {
      return str.substring(11);
    }
    return str;
  }
}
