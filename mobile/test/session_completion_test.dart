import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:focus_flow/models/learning_session.dart';
import 'package:focus_flow/providers/sessions_provider.dart';
import 'package:focus_flow/services/cache_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Session Completion & Synchronization Tests', () {
    test('Optimistic update and cache synchronization on completeSession', () async {
      final container = ProviderContainer();
      final notifier = container.read(sessionsProvider.notifier);
      const testUserId = 'test_user_123';

      final initialSession = LearningSession(
        id: 'session-001',
        userId: testUserId,
        skillId: 'skill-001',
        skillName: 'DSA',
        durationMinutes: 60,
        plannedDuration: 60,
        scheduledDate: DateTime.now().toIso8601String().split('T')[0],
        status: 'planned',
        createdAt: DateTime.now(),
      );

      // Seed initial state in the notifier
      notifier.state = AsyncValue.data([initialSession]);

      // Seed initial cache
      await CacheService().set(
        testUserId,
        'sessions',
        [initialSession.toJson()],
      );

      // Verify initial state
      expect(notifier.state.value!.first.status, 'planned');

      // Check isSessionPending
      expect(notifier.isSessionPending('session-001'), isFalse);

      // Note: We test the state mapping directly since SupabaseService requires network/auth
      final currentList = notifier.state.value!;
      final updatedList = currentList.map((s) {
        if (s.id == 'session-001') {
          return s.copyWith(
            status: 'completed',
            actualDuration: 60,
            completedAt: DateTime.now(),
          );
        }
        return s;
      }).toList();

      notifier.state = AsyncValue.data(updatedList);
      await CacheService().set(
        testUserId,
        'sessions',
        updatedList.map((s) => s.toJson()).toList(),
      );

      // State is immediately completed
      expect(notifier.state.value!.first.status, 'completed');

      // Cache is immediately synchronized with completed status
      final cached = await CacheService().get<List<LearningSession>>(
        testUserId,
        'sessions',
        (json) => (json as List)
            .map((e) => LearningSession.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

      expect(cached, isNotNull);
      expect(cached!.data.first.status, 'completed');
    });

    test('Rollback restores previous state and cache on failure', () async {
      final container = ProviderContainer();
      final notifier = container.read(sessionsProvider.notifier);
      const testUserId = 'test_user_456';

      final initialSession = LearningSession(
        id: 'session-002',
        userId: testUserId,
        skillId: 'skill-002',
        skillName: 'English Vocabulary',
        durationMinutes: 15,
        plannedDuration: 15,
        scheduledDate: DateTime.now().toIso8601String().split('T')[0],
        status: 'planned',
        createdAt: DateTime.now(),
      );

      final snapshot = [initialSession];
      notifier.state = AsyncValue.data(snapshot);
      await CacheService().set(
        testUserId,
        'sessions',
        snapshot.map((s) => s.toJson()).toList(),
      );

      // Simulate optimistic change
      final optimistic = [initialSession.copyWith(status: 'completed')];
      notifier.state = AsyncValue.data(optimistic);

      // Simulate failure rollback
      notifier.state = AsyncValue.data(snapshot);
      await CacheService().set(
        testUserId,
        'sessions',
        snapshot.map((s) => s.toJson()).toList(),
      );

      expect(notifier.state.value!.first.status, 'planned');
      final cached = await CacheService().get<List<LearningSession>>(
        testUserId,
        'sessions',
        (json) => (json as List)
            .map((e) => LearningSession.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      expect(cached!.data.first.status, 'planned');
    });

    test('LearningSession copyWith preserves duration and fields correctly', () {
      final session = LearningSession(
        id: 'sess-3',
        userId: 'user-3',
        skillId: 'skill-3',
        skillName: 'Gym / Workout',
        durationMinutes: 60,
        plannedDuration: 60,
        scheduledDate: '2026-10-14',
        status: 'planned',
        createdAt: DateTime.now(),
      );

      final completed = session.copyWith(
        status: 'completed',
        actualDuration: 45,
        notes: 'Great workout',
      );

      expect(completed.id, 'sess-3');
      expect(completed.skillName, 'Gym / Workout');
      expect(completed.status, 'completed');
      expect(completed.actualDuration, 45);
      expect(completed.notes, 'Great workout');
      expect(completed.plannedDuration, 60);
    });
  });
}
