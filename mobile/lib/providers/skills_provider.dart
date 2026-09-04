import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/skill.dart';
import '../models/learning_session.dart';
import '../services/supabase_service.dart';
import '../core/utils/session_generator.dart';
import 'sessions_provider.dart';

final skillsProvider = StateNotifierProvider<SkillsNotifier, AsyncValue<List<Skill>>>((ref) {
  final sessionsAsync = ref.watch(sessionsProvider);
  final notifier = SkillsNotifier(sessionsAsync.value ?? []);
  return notifier;
});

class SkillsNotifier extends StateNotifier<AsyncValue<List<Skill>>> {
  final List<LearningSession> _sessions;

  SkillsNotifier(this._sessions) : super(const AsyncValue.loading()) {
    fetchSkills();
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
          .map((e) => Skill.fromJson(e as Map<String, dynamic>, allSessions: _sessions))
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
      await SupabaseService.client.from('skills').update(updateData).eq('id', skillId);
    } catch (e) {
      updateData.remove('session_duration');
      updateData.remove('preferred_days');
      await SupabaseService.client.from('skills').update(updateData).eq('id', skillId);
    }

    await SessionGenerator.autoGenerateSessions();
    await fetchSkills();
  }

  Future<void> deleteSkill(String skillId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    await SupabaseService.client.from('skills').delete().eq('id', skillId);
    await fetchSkills();
  }
}
