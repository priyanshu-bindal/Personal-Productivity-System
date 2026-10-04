import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'supabase_service.dart';

/// Encapsulates cached data along with its freshness status and timestamp.
class CacheResult<T> {
  final T data;
  final bool isFresh;
  final DateTime cachedAt;

  const CacheResult({
    required this.data,
    required this.isFresh,
    required this.cachedAt,
  });
}

/// Centralized, production-ready, user-scoped caching service.
///
/// Guarantees:
/// 1. Complete User Isolation: Keys are strictly scoped by `userId` (`ff_cache_{userId}_{resource}`).
/// 2. Verification on read and write against `currentAuthenticatedUserId`.
/// 3. Resource-specific TTLs for optimal freshness and responsiveness.
/// 4. Does NOT cache sensitive authentication credentials or tokens.
/// 5. Never touches notification preferences or system configurations on cache clear.
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  static const String _keyPrefix = 'ff_cache_';

  /// Standard resource-specific Time-To-Live durations.
  static const Map<String, Duration> _resourceTtls = {
    'profile': Duration(minutes: 10),
    'skills': Duration(minutes: 8),
    'sessions': Duration(minutes: 3),
    'expenses': Duration(minutes: 3),
    'budgets': Duration(minutes: 5),
    'calendar': Duration(minutes: 3),
  };

  static const Duration _defaultTtl = Duration(minutes: 5);

  /// Builds a strictly user-scoped cache key.
  String _userKey(String userId, String resource) =>
      '$_keyPrefix${userId}_$resource';

  Duration _getTtl(String resource, [Duration? customTtl]) {
    if (customTtl != null) return customTtl;
    return _resourceTtls[resource] ?? _defaultTtl;
  }

  // ─── Cache Read ────────────────────────────────────────────────────────────

  /// Retrieves a cached resource for [userId].
  ///
  /// Returns `null` on cache miss or user mismatch.
  /// If data is present, returns [CacheResult] indicating whether it is fresh or stale.
  Future<CacheResult<T>?> get<T>(
    String userId,
    String resource,
    T Function(dynamic json) fromJson, {
    Duration? customTtl,
  }) async {
    if (userId.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _userKey(userId, resource);
      final raw = prefs.getString(key);

      if (raw == null || raw.isEmpty) {
        debugPrint('[Cache] MISS: user=$userId resource=$resource');
        return null;
      }

      final envelope = jsonDecode(raw);
      if (envelope is! Map<String, dynamic>) {
        await prefs.remove(key);
        return null;
      }

      final cachedUserId = envelope['userId'] as String?;
      final cachedAtStr = envelope['cachedAt'] as String?;
      final dataJson = envelope['data'];

      // Strict user boundary check:
      // 1. Envelope userId must match target userId.
      // 2. Target userId must match currently active Supabase user.
      final currentAuthId = SupabaseService.currentUserId;
      if (cachedUserId != userId || (currentAuthId != null && currentAuthId != userId)) {
        debugPrint('[Cache] MISMATCH: requested=$userId cached=$cachedUserId current=$currentAuthId resource=$resource');
        await prefs.remove(key);
        return null;
      }

      if (cachedAtStr == null || dataJson == null) {
        await prefs.remove(key);
        return null;
      }

      final cachedAt = DateTime.tryParse(cachedAtStr) ?? DateTime.now();
      final age = DateTime.now().difference(cachedAt);
      final ttl = _getTtl(resource, customTtl);
      final isFresh = age < ttl;

      if (isFresh) {
        debugPrint('[Cache] HIT: user=$userId resource=$resource (age: ${age.inSeconds}s)');
      } else {
        debugPrint('[Cache] STALE: user=$userId resource=$resource (age: ${age.inSeconds}s)');
      }

      final parsed = fromJson(dataJson);
      return CacheResult<T>(
        data: parsed,
        isFresh: isFresh,
        cachedAt: cachedAt,
      );
    } catch (e) {
      debugPrint('[Cache] Read error for $resource: $e');
      return null;
    }
  }

  // ─── Cache Write ───────────────────────────────────────────────────────────

  /// Saves [rawJson] into the user-scoped cache for [userId].
  ///
  /// Rejects writes if [userId] does not match the active authenticated user,
  /// preventing stale background writes during account transitions.
  Future<void> set(
    String userId,
    String resource,
    dynamic rawJson,
  ) async {
    if (userId.isEmpty) return;

    // Safety guard against race conditions during sign out / account switch
    final currentAuthId = SupabaseService.currentUserId;
    if (currentAuthId != null && currentAuthId != userId) {
      debugPrint('[Cache] REJECTED SET: user=$userId != currentAuth=$currentAuthId');
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _userKey(userId, resource);

      final envelope = {
        'userId': userId,
        'cachedAt': DateTime.now().toIso8601String(),
        'data': rawJson,
      };

      await prefs.setString(key, jsonEncode(envelope));
      debugPrint('[Cache] SET: user=$userId resource=$resource');
    } catch (e) {
      debugPrint('[Cache] Write error for $resource: $e');
    }
  }

  // ─── Cache Invalidation ────────────────────────────────────────────────────

  /// Removes a single cached resource for [userId].
  Future<void> invalidate(String userId, String resource) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = _userKey(userId, resource);
      await prefs.remove(key);
      debugPrint('[Cache] INVALIDATED: user=$userId resource=$resource');
    } catch (_) {}
  }

  /// Clears all cached resources specifically belonging to [userId].
  ///
  /// Completely removes User A's data without affecting User B or any system preferences.
  Future<void> clearUser(String userId) async {
    if (userId.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = '$_keyPrefix${userId}_';
      final keysToRemove = prefs.getKeys().where((k) => k.startsWith(prefix)).toList();

      for (final k in keysToRemove) {
        await prefs.remove(k);
      }
      debugPrint('[Cache] CLEARED: user=$userId (${keysToRemove.length} entries removed)');
    } catch (e) {
      debugPrint('[Cache] Clear error for user $userId: $e');
    }
  }

  /// Clears all user caches in the application.
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = prefs.getKeys().where((k) => k.startsWith(_keyPrefix)).toList();

      for (final k in keysToRemove) {
        await prefs.remove(k);
      }
      debugPrint('[Cache] CLEARED: all users (${keysToRemove.length} entries removed)');
    } catch (e) {
      debugPrint('[Cache] Clear all error: $e');
    }
  }

  // ─── Cache Metrics & Auditing ──────────────────────────────────────────────

  /// Calculates the true UTF-8 byte size of cached data on disk.
  Future<int> getEstimatedCacheSizeInBytes([String? userId]) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = userId != null && userId.isNotEmpty
          ? '$_keyPrefix${userId}_'
          : _keyPrefix;

      int totalBytes = 0;
      for (final key in prefs.getKeys()) {
        if (key.startsWith(prefix)) {
          final val = prefs.getString(key);
          if (val != null) {
            totalBytes += utf8.encode(val).length;
          }
        }
      }
      return totalBytes;
    } catch (_) {
      return 0;
    }
  }

  /// Returns a human-friendly representation of the cache size (e.g. `24.5 KB`).
  Future<String> getFormattedCacheSize([String? userId]) async {
    final bytes = await getEstimatedCacheSizeInBytes(userId);
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  /// Returns the most recent cache timestamp for [userId].
  Future<DateTime?> getLastRefreshedTime(String userId) async {
    if (userId.isEmpty) return null;
    try {
      final prefs = await SharedPreferences.getInstance();
      final prefix = '$_keyPrefix${userId}_';
      DateTime? latest;

      for (final key in prefs.getKeys()) {
        if (key.startsWith(prefix)) {
          final raw = prefs.getString(key);
          if (raw != null) {
            try {
              final env = jsonDecode(raw);
              if (env is Map && env['cachedAt'] != null) {
                final date = DateTime.tryParse(env['cachedAt'] as String);
                if (date != null && (latest == null || date.isAfter(latest))) {
                  latest = date;
                }
              }
            } catch (_) {}
          }
        }
      }
      return latest;
    } catch (_) {
      return null;
    }
  }
}
