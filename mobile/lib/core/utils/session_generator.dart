import 'package:shared_preferences/shared_preferences.dart';
import '../../services/supabase_service.dart';

class SessionGenerator {
  static const List<String> dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];

  static Future<void> autoGenerateSessions([String? targetUserId]) async {
    final userId = targetUserId ?? SupabaseService.currentUserId;
    if (userId == null) return;

    try {
      // Throttle: avoid redundant heavy upserts on every app launch.
      // Run at most once per 12 hours per user.
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = 'last_session_gen_ts_$userId';
      final lastGen = prefs.getInt(cacheKey);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      if (lastGen != null && (nowMs - lastGen) < const Duration(hours: 12).inMilliseconds) {
        return; // Already generated recently
      }

      final supabase = SupabaseService.client;
      final List<dynamic> skillsResponse = await supabase
          .from('skills')
          .select('*')
          .eq('user_id', userId);

      if (skillsResponse.isEmpty) return;
      if (SupabaseService.currentUserId != userId) return;

      final skills = List<Map<String, dynamic>>.from(skillsResponse);
      final today = DateTime.now();
      final List<Map<String, dynamic>> sessionsToInsert = [];

      for (int i = -7; i <= 14; i++) {
        final d = today.add(Duration(days: i));
        final dayName = dayNames[d.weekday % 7];
        final dateStr = d.toIso8601String().split('T')[0];

        for (final skill in skills) {
          final rawDays = skill['preferred_days'] as List?;
          // If preferred_days is explicitly empty or ['None'], do not schedule
          if (rawDays != null && rawDays.isEmpty) continue;
          final prefDays = rawDays?.map((e) => e.toString()).toList() ??
              ['Monday', 'Wednesday', 'Friday'];
          if (prefDays.contains('None')) continue;

          if (prefDays.contains(dayName)) {
            sessionsToInsert.add({
              'user_id': userId,
              'skill_id': skill['id'],
              'scheduled_date': dateStr,
              'planned_duration': skill['session_duration'] ?? 60,
              'duration_minutes': skill['session_duration'] ?? 60,
              'status': 'planned',
            });
          }
        }
      }

      if (sessionsToInsert.isNotEmpty) {
        await supabase
            .from('learning_sessions')
            .upsert(
              sessionsToInsert,
              onConflict: 'user_id,skill_id,scheduled_date',
              ignoreDuplicates: true,
            );
      }

      // Record successful generation timestamp
      await prefs.setInt(cacheKey, nowMs);
    } catch (e) {
      // Fire & forget background handling
    }
  }
}
