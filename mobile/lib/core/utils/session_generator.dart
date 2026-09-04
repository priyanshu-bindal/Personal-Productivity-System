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

  static Future<void> autoGenerateSessions() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    try {
      final supabase = SupabaseService.client;
      final List<dynamic> skillsResponse = await supabase
          .from('skills')
          .select('*')
          .eq('user_id', userId);

      if (skillsResponse.isEmpty) return;

      final skills = List<Map<String, dynamic>>.from(skillsResponse);
      final today = DateTime.now();
      final List<Map<String, dynamic>> sessionsToInsert = [];

      for (int i = -7; i <= 14; i++) {
        final d = today.add(Duration(days: i));
        final dayName = dayNames[d.weekday % 7];
        final dateStr = d.toIso8601String().split('T')[0];

        for (final skill in skills) {
          final prefDays = (skill['preferred_days'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              ['Monday', 'Wednesday', 'Friday'];

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
    } catch (e) {
      // Fire & forget background handling
    }
  }
}
