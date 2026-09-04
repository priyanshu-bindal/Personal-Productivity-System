import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/learning_session.dart';
import '../providers/profile_provider.dart';
import '../services/supabase_service.dart';

// ─── State ──────────────────────────────────────────────────────────────────

class StreakState {
  final int currentStreak;
  final int longestStreak;
  final String? lastStreakDate;
  /// True for one frame after a streak increment — used to trigger animation
  final bool justIncremented;

  const StreakState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStreakDate,
    this.justIncremented = false,
  });

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    String? lastStreakDate,
    bool? justIncremented,
    bool clearLastStreakDate = false,
  }) {
    return StreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStreakDate:
          clearLastStreakDate ? null : (lastStreakDate ?? this.lastStreakDate),
      justIncremented: justIncremented ?? this.justIncremented,
    );
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final streakProvider =
    StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  return StreakNotifier(ref);
});

class StreakNotifier extends StateNotifier<StreakState> {
  final Ref _ref;

  StreakNotifier(this._ref) : super(const StreakState()) {
    _loadFromProfile();
  }

  // ── Bootstrap from cached profile ────────────────────────────────────────

  void _loadFromProfile() {
    final profile = _ref.read(profileProvider).value;
    if (profile != null) {
      state = StreakState(
        currentStreak: profile.currentStreak,
        longestStreak: profile.longestStreak,
        lastStreakDate: profile.lastStreakDate,
      );
    }
  }

  /// Called from [SessionsNotifier.completeSession] after DB write succeeds.
  /// Checks whether all of today's sessions are done and updates the streak.
  Future<void> checkAndUpdateStreak(List<LearningSession> allSessions) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    final todaySessions =
        allSessions.where((s) => s.scheduledDate == today).toList();

    // Neutral day — no sessions scheduled, do nothing
    if (todaySessions.isEmpty) return;

    final allCompleted =
        todaySessions.every((s) => s.status == 'completed');

    // Not all done yet — user still has time
    if (!allCompleted) return;

    // Idempotency guard — already counted today
    if (state.lastStreakDate == today) return;

    // Compute new streak value
    int newStreak;
    if (state.lastStreakDate == yesterday) {
      newStreak = state.currentStreak + 1;
    } else {
      // Gap or first ever — restart
      newStreak = 1;
    }

    final newLongest =
        newStreak > state.longestStreak ? newStreak : state.longestStreak;

    // Optimistic local update + animation flag
    state = state.copyWith(
      currentStreak: newStreak,
      longestStreak: newLongest,
      lastStreakDate: today,
      justIncremented: true,
    );

    // Persist to Supabase
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    try {
      await SupabaseService.client.from('profiles').update({
        'current_streak': newStreak,
        'longest_streak': newLongest,
        'last_streak_date': today,
      }).eq('id', userId);

      // Refresh profile so the rest of the app sees the new values
      await _ref.read(profileProvider.notifier).fetchProfile();
    } catch (_) {
      // Streak still shows locally even if network fails
    }

    // Clear the "just incremented" flag after a short delay
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      state = state.copyWith(justIncremented: false);
    }
  }

  /// Sync streak state from the latest profile data (call after fetchProfile).
  void syncFromProfile() {
    final profile = _ref.read(profileProvider).value;
    if (profile == null) return;
    // Don't override justIncremented if it's still active
    state = state.copyWith(
      currentStreak: profile.currentStreak,
      longestStreak: profile.longestStreak,
      lastStreakDate: profile.lastStreakDate,
    );
  }

  /// Compute per-day success for the last N days (used by details sheet).
  /// Returns a list of (date, status) sorted oldest→newest.
  List<({DateTime date, bool hasScheduled, bool allCompleted})>
      computeLastNDays(List<LearningSession> allSessions, {int n = 7}) {
    final result = <({DateTime date, bool hasScheduled, bool allCompleted})>[];
    final today = DateTime.now();

    for (int i = n - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      final dayStr = DateFormat('yyyy-MM-dd').format(day);
      final daySessions =
          allSessions.where((s) => s.scheduledDate == dayStr).toList();

      final hasScheduled = daySessions.isNotEmpty;
      final allCompleted =
          hasScheduled && daySessions.every((s) => s.status == 'completed');

      result.add((date: day, hasScheduled: hasScheduled, allCompleted: allCompleted));
    }

    return result;
  }
}
