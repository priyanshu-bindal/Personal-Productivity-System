import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_flow/services/cache_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CacheService — User-Scoped Isolation & Safety', () {
    test('User A data is isolated and User B cannot read User A data', () async {
      final cache = CacheService();
      const userA = 'user_aaa_111';
      const userB = 'user_bbb_222';

      // Set User A's profile cache
      await cache.set(userA, 'profile', {'name': 'Alice', 'role': 'Engineer'});

      // Attempt to read User A's data using User B's ID
      final userBRead = await cache.get<Map<String, dynamic>>(
        userB,
        'profile',
        (json) => json as Map<String, dynamic>,
      );

      // Must be null (complete isolation)
      expect(userBRead, isNull);

      // User A can read their own data
      final userARead = await cache.get<Map<String, dynamic>>(
        userA,
        'profile',
        (json) => json as Map<String, dynamic>,
      );

      expect(userARead, isNotNull);
      expect(userARead!.data['name'], 'Alice');
      expect(userARead.isFresh, isTrue);
    });

    test('clearUser only clears target user and preserves other users data', () async {
      final cache = CacheService();
      const userA = 'user_aaa_111';
      const userB = 'user_bbb_222';

      await cache.set(userA, 'skills', [{'name': 'Dart'}]);
      await cache.set(userB, 'skills', [{'name': 'Python'}]);

      // Clear User A
      await cache.clearUser(userA);

      // User A's cache is gone
      final aRead = await cache.get<List>(userA, 'skills', (json) => json as List);
      expect(aRead, isNull);

      // User B's cache remains completely intact
      final bRead = await cache.get<List>(userB, 'skills', (json) => json as List);
      expect(bRead, isNotNull);
      expect(bRead!.data.first['name'], 'Python');
    });

    test('Cache operations do not remove system or notification preferences', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('focusflow_practice_reminders_user_aaa_111', true);
      await prefs.setString('focusflow_device_unique_id', 'device-xyz');

      final cache = CacheService();
      await cache.set('user_aaa_111', 'expenses', [{'amount': 15.0}]);

      // Clear user cache
      await cache.clearUser('user_aaa_111');

      // System preferences remain
      expect(prefs.getBool('focusflow_practice_reminders_user_aaa_111'), isTrue);
      expect(prefs.getString('focusflow_device_unique_id'), 'device-xyz');
    });

    test('Cache TTL marks data as stale after expiry duration', () async {
      final cache = CacheService();
      const user = 'user_ttl_test';

      await cache.set(user, 'custom', {'key': 'val'});

      // Fresh read with normal TTL
      final fresh = await cache.get<Map<String, dynamic>>(
        user,
        'custom',
        (json) => json as Map<String, dynamic>,
        customTtl: const Duration(hours: 1),
      );
      expect(fresh, isNotNull);
      expect(fresh!.isFresh, isTrue);

      // Stale read with zero TTL
      final stale = await cache.get<Map<String, dynamic>>(
        user,
        'custom',
        (json) => json as Map<String, dynamic>,
        customTtl: Duration.zero,
      );
      expect(stale, isNotNull);
      expect(stale!.isFresh, isFalse);
      expect(stale.data['key'], 'val');
    });

    test('invalidate removes specific resource only', () async {
      final cache = CacheService();
      const user = 'user_inval_test';

      await cache.set(user, 'sessions', [1, 2, 3]);
      await cache.set(user, 'skills', [4, 5, 6]);

      await cache.invalidate(user, 'sessions');

      final sessions = await cache.get<List>(user, 'sessions', (j) => j as List);
      final skills = await cache.get<List>(user, 'skills', (j) => j as List);

      expect(sessions, isNull);
      expect(skills, isNotNull);
    });

    test('Cache size metrics calculate correct formatting', () async {
      final cache = CacheService();
      const user = 'user_metric_test';

      final initialSize = await cache.getFormattedCacheSize(user);
      expect(initialSize, '0 B');

      await cache.set(user, 'large_resource', {
        'items': List.generate(50, (i) => 'Item $i in list with some descriptive text')
      });

      final sizeBytes = await cache.getEstimatedCacheSizeInBytes(user);
      expect(sizeBytes, greaterThan(0));

      final formattedSize = await cache.getFormattedCacheSize(user);
      expect(formattedSize.contains('B') || formattedSize.contains('KB'), isTrue);

      final lastRefreshed = await cache.getLastRefreshedTime(user);
      expect(lastRefreshed, isNotNull);
    });
  });
}
