import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Shared JWT-recovery helper for Supabase PostgREST calls.
///
/// PGRST303 ("JWT issued at future") can surface when the app restores a
/// cached Supabase session whose `iat` claim is slightly in the future due to
/// clock skew or a stale token. The fix is to refresh the session once and
/// retry the failed request.
///
/// This class ensures:
/// 1. Recovery is attempted AT MOST ONCE per error occurrence.
/// 2. Only ONE concurrent refreshSession call is active at any time.
///    Multiple providers racing at startup will all wait on the same Future
///    rather than spawning parallel refreshes.
/// 3. Non-JWT errors are re-thrown as-is without touching the session.
class SupabaseJwtRecovery {
  SupabaseJwtRecovery._();

  /// The in-flight refresh Future, if one is already running.
  static Future<void>? _inflightRefresh;

  // --- Public API ---------------------------------------------------------

  /// Executes [operation] and, if a PGRST303 JWT error is thrown, refreshes
  /// the Supabase session (at most one concurrent refresh) and retries
  /// [operation] exactly one more time.
  ///
  /// All other errors propagate unchanged.
  static Future<T> withJwtRecovery<T>(
    SupabaseClient supabase,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (e) {
      if (!_isPgrst303(e)) rethrow;

      _logJwtDiagnostics(supabase, e);

      // Refresh session — shared Future prevents concurrent storms.
      await _refreshOnce(supabase);

      // Brief pause so PostgREST sees the new token.
      await Future<void>.delayed(const Duration(milliseconds: 600));

      // Retry ONCE — let any error from here propagate to the caller.
      return await operation();
    }
  }

  // --- Helpers ------------------------------------------------------------

  static bool _isPgrst303(Object error) {
    if (error is PostgrestException) {
      if (error.code == 'PGRST303') return true;
      if (error.message.toLowerCase().contains('jwt issued at future')) return true;
    }
    return false;
  }

  /// At most one refreshSession() runs at a time across all callers.
  static Future<void> _refreshOnce(SupabaseClient supabase) {
    _inflightRefresh ??= supabase.auth
        .refreshSession()
        .then((_) {
          debugPrint('[SupabaseJwtRecovery] Session refreshed successfully.');
        })
        .catchError((Object e) {
          debugPrint('[SupabaseJwtRecovery] refreshSession() failed: $e');
          // Do not rethrow — let the retry attempt run and surface its own error.
        })
        .whenComplete(() {
          _inflightRefresh = null;
        });
    return _inflightRefresh!;
  }

  /// Logs JWT timing WITHOUT logging the token itself.
  static void _logJwtDiagnostics(SupabaseClient supabase, Object error) {
    try {
      final accessToken = supabase.auth.currentSession?.accessToken;
      if (accessToken == null) {
        debugPrint('[SupabaseJwtRecovery] PGRST303 but no active session.');
        return;
      }

      final parts = accessToken.split('.');
      if (parts.length < 2) return;

      final payload = parts[1];
      final padded = payload + ('=' * ((4 - payload.length % 4) % 4));
      final decoded = utf8.decode(base64Url.decode(padded));
      final claims = jsonDecode(decoded) as Map<String, dynamic>;

      final iat = claims['iat'] as int?;
      final exp = claims['exp'] as int?;
      final clientNow = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      debugPrint('[SupabaseJwtRecovery] PGRST303 JWT diagnostic:');
      debugPrint('  iat       = $iat');
      debugPrint('  exp       = $exp');
      debugPrint('  clientNow = $clientNow');
      if (iat != null) {
        final diff = iat - clientNow;
        debugPrint('  iat - now = $diff s  (positive = iat in future = clock skew)');
      }
      debugPrint('  error     = $error');
    } catch (_) {
      debugPrint('[SupabaseJwtRecovery] Could not decode JWT for diagnostics.');
    }
  }
}
