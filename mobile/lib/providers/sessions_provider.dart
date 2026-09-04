import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_session.dart';
import '../services/supabase_service.dart';
import '../core/utils/session_generator.dart';
import 'streak_provider.dart';

final sessionsProvider = StateNotifierProvider<SessionsNotifier, AsyncValue<List<LearningSession>>>((ref) {
  return SessionsNotifier(ref);
});

class SessionsNotifier extends StateNotifier<AsyncValue<List<LearningSession>>> {
  final Ref _ref;

  SessionsNotifier(this._ref) : super(const AsyncValue.loading()) {
    fetchSessions();
  }

  Future<void> fetchSessions() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      // Auto-generate missing planned sessions in background
      SessionGenerator.autoGenerateSessions().catchError((_) {});

      final res = await SupabaseService.client
          .from('learning_sessions')
          .select('*, skill:skills(name)')
          .eq('user_id', userId)
          .order('scheduled_date', ascending: false);

      final list = (res as List).map((e) => LearningSession.fromJson(e as Map<String, dynamic>)).toList();
      if (!mounted) return;
      state = AsyncValue.data(list);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeSession(String sessionId, {int? actualDuration, String? notes}) async {
    final currentList = state.value ?? [];
    final nowIso = DateTime.now().toIso8601String();
    final dur = actualDuration ?? 60;

    // Optimistic UI update
    state = AsyncValue.data(
      currentList.map((s) {
        if (s.id == sessionId) {
          return s.copyWith(
            status: 'completed',
            actualDuration: dur,
            completedAt: DateTime.parse(nowIso),
            notes: notes,
          );
        }
        return s;
      }).toList(),
    );

    try {
      await SupabaseService.client
          .from('learning_sessions')
          .update({
            'status': 'completed',
            'completed_at': nowIso,
            'actual_duration': dur,
            'duration_minutes': dur,
            'notes': notes,
          })
          .eq('id', sessionId);

      await fetchSessions();

      // ── Streak check ──────────────────────────────────────────────────────
      // Run after the fresh session list is in state, so the check sees the
      // newly completed session as 'completed'.
      if (mounted) {
        await _ref
            .read(streakProvider.notifier)
            .checkAndUpdateStreak(state.value ?? []);
      }
    } catch (e) {
      fetchSessions();
      rethrow;
    }
  }

  Future<void> skipSession(String sessionId) async {
    final currentList = state.value ?? [];

    state = AsyncValue.data(
      currentList.map((s) {
        if (s.id == sessionId) {
          return s.copyWith(status: 'skipped');
        }
        return s;
      }).toList(),
    );

    try {
      await SupabaseService.client
          .from('learning_sessions')
          .update({'status': 'skipped'})
          .eq('id', sessionId);
      await fetchSessions();
    } catch (e) {
      fetchSessions();
      rethrow;
    }
  }
}
