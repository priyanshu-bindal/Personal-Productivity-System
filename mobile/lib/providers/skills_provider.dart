import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/skill.dart';
import '../models/learning_session.dart';
import '../services/supabase_service.dart';
import '../core/utils/session_generator.dart';
import 'sessions_provider.dart';

/// A stable provider that holds the [SkillsNotifier] singleton.
/// By NOT watching [sessionsProvider] here, Riverpod never destroys and
/// re-creates the notifier when sessions change — eliminating the
/// ~1 second Supabase re-fetch that was triggered on every navigation.
final skillsProvider =
    StateNotifierProvider<SkillsNotifier, AsyncValue<List<Skill>>>((ref) {
  final notifier = SkillsNotifier();

  // Wire session updates reactively: whenever sessionsProvider emits a new
  // list, push it into the existing notifier so skills are recomputed
  // from cached data — no network round-trip on navigation.
  ref.listen<AsyncValue<List<LearningSession>>>(
    sessionsProvider,
    (_, next) {
      if (next.hasValue) {
        notifier.updateSessions(next.value!);
      }
    },
    fireImmediately: true,
  );

  return notifier;
});

class SkillsNotifier extends StateNotifier<AsyncValue<List<Skill>>> {
  List<LearningSession> _sessions = [];

  SkillsNotifier() : super(const AsyncValue.loading()) {
    fetchSkills();
  }

  /// Called reactively by the provider when [sessionsProvider] emits.
  /// Recomputes skill stats from the cached session list without hitting
  /// the network again.
  void updateSessions(List<LearningSession> sessions) {
    _sessions = sessions;
    // If we already have skill data, recompute stats from new sessions
    // without a network round-trip.
    final current = state.value;
    if (current != null && current.isNotEmpty) {
      _recomputeFromCache(current, sessions);
    }
  }

  /// Recomputes skill derived properties (streak, consistency, etc.) from
  /// cached JSON-like data by re-mapping through [Skill.fromJson] using the
  /// locally cached fields — no Supabase call needed.
  void _recomputeFromCache(
      List<Skill> skills, List<LearningSession> sessions) {
    final recomputed = skills.map((s) {
      // Re-run the same derivation logic as Skill.fromJson but with fresh
      // sessions instead of re-fetching the skill row from the DB.
      return _recomputeSkill(s, sessions);
    }).toList();
    if (mounted) state = AsyncValue.data(recomputed);
  }

  /// Reconstructs a [Skill] with updated session-derived stats.
  Skill _recomputeSkill(Skill s, List<LearningSession> allSessions) {
    final skillSessions = allSessions.where((ls) => ls.skillId == s.id).toList();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final tSession =
        skillSessions.where((ls) => ls.scheduledDate == todayStr).firstOrNull;

    final pastAndToday = skillSessions
        .where((ls) => ls.scheduledDate.compareTo(todayStr) <= 0)
        .toList();

    final totalPlanned = pastAndToday.length;
    final totalCompleted =
        pastAndToday.where((ls) => ls.status == 'completed').length;
    final consistency =
        totalPlanned > 0 ? ((totalCompleted / totalPlanned) * 100).round() : 100;

    int streak = 0;
    final sorted = [...pastAndToday]
      ..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    for (final ls in sorted) {
      if (ls.status == 'completed') {
        streak++;
      } else if (ls.status == 'skipped' ||
          (ls.status == 'planned' &&
              ls.scheduledDate.compareTo(todayStr) < 0)) {
        break;
      }
    }

    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final mondayStr = monday.toIso8601String().split('T')[0];
    final sundayStr =
        monday.add(const Duration(days: 6)).toIso8601String().split('T')[0];

    final weeklyCompleted = skillSessions
        .where((ls) =>
            ls.scheduledDate.compareTo(mondayStr) >= 0 &&
            ls.scheduledDate.compareTo(sundayStr) <= 0 &&
            ls.status == 'completed')
        .length;

    final minutes = skillSessions
        .where((ls) => ls.status == 'completed')
        .fold<int>(0, (sum, ls) => sum + (ls.actualDuration ?? ls.plannedDuration));
    final hours = (minutes / 60.0 * 10).round() / 10.0;

    return Skill(
      id: s.id,
      userId: s.userId,
      name: s.name,
      category: s.category,
      description: s.description,
      level: s.level,
      progress: consistency,
      target: s.target,
      weeklyTarget: s.weeklyTarget,
      sessionDuration: s.sessionDuration,
      preferredDays: s.preferredDays,
      status: s.status,
      createdAt: s.createdAt,
      updatedAt: s.updatedAt,
      sessions: skillSessions,
      todaySession: tSession,
      weeklyCompleted: weeklyCompleted,
      consistencyPct: consistency,
      streak: streak,
      totalMinutes: minutes,
      learningHours: hours,
    );
  }

  Future<void> fetchSkills() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final res = await SupabaseService.client
          .from('skills')
          .select('*')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      final list = (res as List)
          .map((e) => Skill.fromJson(e as Map<String, dynamic>,
              allSessions: _sessions))
          .toList();

      if (!mounted) return;
      state = AsyncValue.data(list);
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createSkill({
    required String name,
    required String category,
    required String level,
    required int sessionDuration,
    required List<String> preferredDays,
    String? description,
    String? target,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final insertData = {
      'user_id': userId,
      'name': name,
      'category': category,
      'description': description,
      'level': level,
      'progress': 0,
      'target': target,
      'weekly_target': preferredDays.length,
      'session_duration': sessionDuration,
      'preferred_days': preferredDays,
      'status': 'active',
    };

    try {
      await SupabaseService.client.from('skills').insert(insertData);
    } catch (e) {
      // Fallback if migration 002 isn't applied
      insertData.remove('session_duration');
      insertData.remove('preferred_days');
      insertData.remove('status');
      await SupabaseService.client.from('skills').insert(insertData);
    }

    await SessionGenerator.autoGenerateSessions();
    await fetchSkills();
  }

  Future<void> updateSkill(String skillId, {
    String? name,
    String? category,
    String? level,
    int? sessionDuration,
    List<String>? preferredDays,
    String? description,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final updateData = <String, dynamic>{};
    if (name != null) updateData['name'] = name;
    if (category != null) updateData['category'] = category;
    if (level != null) updateData['level'] = level;
    if (sessionDuration != null) updateData['session_duration'] = sessionDuration;
    if (preferredDays != null) {
      updateData['preferred_days'] = preferredDays;
      updateData['weekly_target'] = preferredDays.length;
    }
    if (description != null) updateData['description'] = description;

    try {
      await SupabaseService.client
          .from('skills')
          .update(updateData)
          .eq('id', skillId);
    } catch (e) {
      updateData.remove('session_duration');
      updateData.remove('preferred_days');
      await SupabaseService.client
          .from('skills')
          .update(updateData)
          .eq('id', skillId);
    }

    await SessionGenerator.autoGenerateSessions();
    await fetchSkills();
  }

  Future<void> deleteSkill(String skillId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    await SupabaseService.client
        .from('skills')
        .delete()
        .eq('id', skillId);
    await fetchSkills();
  }
}
