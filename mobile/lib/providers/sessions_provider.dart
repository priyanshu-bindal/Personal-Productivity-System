import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_session.dart';
import '../services/supabase_service.dart';
import '../core/utils/session_generator.dart';
import 'auth_provider.dart';
import 'streak_provider.dart';

final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, AsyncValue<List<LearningSession>>>(
        (ref) {
  final userId = ref.watch(currentUserIdProvider);
  return SessionsNotifier(ref, userId);
});

class SessionsNotifier
    extends StateNotifier<AsyncValue<List<LearningSession>>> {
  final Ref _ref;
  final String? _userId;

  SessionsNotifier(this._ref, [this._userId])
      : super(_userId == null
            ? const AsyncValue.data([])
            : const AsyncValue.loading()) {
    if (_userId != null) {
      fetchSessions();
    }
  }

  Future<void> fetchSessions() async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }

    try {
      // Auto-generate missing planned sessions in background
      SessionGenerator.autoGenerateSessions(effectiveUserId).catchError((_) {});

      final res = await SupabaseService.client
          .from('learning_sessions')
          .select('*, skill:skills(name)')
          .eq('user_id', effectiveUserId)
          .order('scheduled_date', ascending: false);

      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;
      final list = (res as List)
          .map((e) => LearningSession.fromJson(e as Map<String, dynamic>))
          .toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> completeSession(String sessionId,
      {int? actualDuration, String? notes}) async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return;
    }

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
          .eq('id', sessionId)
          .eq('user_id', effectiveUserId);

      await fetchSessions();

      // ── Streak check ──────────────────────────────────────────────────────
      if (mounted && SupabaseService.currentUserId == effectiveUserId) {
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
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return;
    }

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
          .eq('id', sessionId)
          .eq('user_id', effectiveUserId);
      await fetchSessions();
    } catch (e) {
      fetchSessions();
      rethrow;
    }
  }
}
