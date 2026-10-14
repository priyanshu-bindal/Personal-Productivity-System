import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/learning_session.dart';
import '../services/supabase_service.dart';
import '../services/cache_service.dart';
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
  final Set<String> _pendingSessionIds = {};

  SessionsNotifier(this._ref, [this._userId])
      : super(_userId == null
            ? const AsyncValue.data([])
            : const AsyncValue.loading()) {
    if (_userId != null) {
      fetchSessions();
    }
  }

  bool isSessionPending(String sessionId) =>
      _pendingSessionIds.contains(sessionId);

  Future<void> fetchSessions({bool forceRefresh = false}) async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }

    // Cache-First check
    if (!forceRefresh) {
      final cached = await CacheService().get<List<LearningSession>>(
        effectiveUserId,
        'sessions',
        (json) => (json as List)
            .map((e) => LearningSession.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

      if (cached != null) {
        if (mounted && SupabaseService.currentUserId == effectiveUserId) {
          state = AsyncValue.data(cached.data);
        }
        if (cached.isFresh) {
          return; // Valid fresh data served instantly
        }
      }
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

      // Persist to user-scoped cache
      await CacheService().set(
        effectiveUserId,
        'sessions',
        list.map((s) => s.toJson()).toList(),
      );

      state = AsyncValue.data(list);
    } catch (e, st) {
      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;
      if (state.value == null || state.value!.isEmpty) {
        state = AsyncValue.error(e, st);
      }
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

    // Prevent duplicate concurrent requests for the same session
    if (_pendingSessionIds.contains(sessionId)) return;
    _pendingSessionIds.add(sessionId);

    final currentList = state.value ?? [];
    final sessionIndex = currentList.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) {
      _pendingSessionIds.remove(sessionId);
      return;
    }

    final targetSession = currentList[sessionIndex];
    if (targetSession.status == 'completed') {
      _pendingSessionIds.remove(sessionId);
      return;
    }

    final nowIso = DateTime.now().toIso8601String();
    final dur = actualDuration ?? targetSession.plannedDuration;

    final updatedSession = targetSession.copyWith(
      status: 'completed',
      actualDuration: dur,
      completedAt: DateTime.parse(nowIso),
      notes: notes,
    );

    final updatedList = List<LearningSession>.from(currentList);
    updatedList[sessionIndex] = updatedSession;

    // 1. Optimistic UI update: State is updated immediately
    state = AsyncValue.data(updatedList);

    // 2. Synchronize user-scoped cache immediately so subsequent reads never see stale 'planned' state
    await CacheService().set(
      effectiveUserId,
      'sessions',
      updatedList.map((s) => s.toJson()).toList(),
    );

    try {
      // 3. Persist completion to Supabase exactly once
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

      // Invalidate calendar cache so it reconciles on next visit
      CacheService().invalidate(effectiveUserId, 'calendar');

      // 4. Streak check with authoritative updated session list
      if (mounted && SupabaseService.currentUserId == effectiveUserId) {
        await _ref
            .read(streakProvider.notifier)
            .checkAndUpdateStreak(updatedList);
      }
    } catch (e) {
      // 5. Rollback on failure: restore previous state and cache
      if (mounted && SupabaseService.currentUserId == effectiveUserId) {
        state = AsyncValue.data(currentList);
        await CacheService().set(
          effectiveUserId,
          'sessions',
          currentList.map((s) => s.toJson()).toList(),
        );
      }
      rethrow;
    } finally {
      _pendingSessionIds.remove(sessionId);
    }
  }

  Future<void> skipSession(String sessionId) async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return;
    }

    if (_pendingSessionIds.contains(sessionId)) return;
    _pendingSessionIds.add(sessionId);

    final currentList = state.value ?? [];
    final sessionIndex = currentList.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) {
      _pendingSessionIds.remove(sessionId);
      return;
    }

    final targetSession = currentList[sessionIndex];
    if (targetSession.status == 'skipped') {
      _pendingSessionIds.remove(sessionId);
      return;
    }

    final updatedSession = targetSession.copyWith(status: 'skipped');
    final updatedList = List<LearningSession>.from(currentList);
    updatedList[sessionIndex] = updatedSession;

    state = AsyncValue.data(updatedList);

    await CacheService().set(
      effectiveUserId,
      'sessions',
      updatedList.map((s) => s.toJson()).toList(),
    );

    try {
      await SupabaseService.client
          .from('learning_sessions')
          .update({'status': 'skipped'})
          .eq('id', sessionId)
          .eq('user_id', effectiveUserId);

      CacheService().invalidate(effectiveUserId, 'calendar');
    } catch (e) {
      if (mounted && SupabaseService.currentUserId == effectiveUserId) {
        state = AsyncValue.data(currentList);
        await CacheService().set(
          effectiveUserId,
          'sessions',
          currentList.map((s) => s.toJson()).toList(),
        );
      }
      rethrow;
    } finally {
      _pendingSessionIds.remove(sessionId);
    }
  }
}
