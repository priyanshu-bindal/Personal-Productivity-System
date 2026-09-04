import 'learning_session.dart';

class Skill {
  final String id;
  final String userId;
  final String name;
  final String category;
  final String? description;
  final String level;
  final int progress;
  final String? target;
  final int weeklyTarget;
  final int sessionDuration;
  final List<String> preferredDays;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Computed/Derived properties
  final List<LearningSession> sessions;
  final LearningSession? todaySession;
  final int weeklyCompleted;
  final int consistencyPct;
  final int streak;
  final int totalMinutes;
  final double learningHours;

  Skill({
    required this.id,
    required this.userId,
    required this.name,
    required this.category,
    this.description,
    required this.level,
    this.progress = 0,
    this.target,
    this.weeklyTarget = 3,
    this.sessionDuration = 60,
    required this.preferredDays,
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.sessions = const [],
    this.todaySession,
    this.weeklyCompleted = 0,
    this.consistencyPct = 100,
    this.streak = 0,
    this.totalMinutes = 0,
    this.learningHours = 0.0,
  });

  factory Skill.fromJson(Map<String, dynamic> json, {List<LearningSession> allSessions = const []}) {
    final skillId = json['id'] as String;
    final prefDays = (json['preferred_days'] as List?)?.map((e) => e.toString()).toList() ??
        ['Monday', 'Wednesday', 'Friday'];

    final skillSessions = allSessions.where((s) => s.skillId == skillId).toList();
    final todayStr = DateTime.now().toIso8601String().split('T')[0];
    final tSession = skillSessions.where((s) => s.scheduledDate == todayStr).firstOrNull;

    // Past & today sessions using compareTo
    final pastAndToday = skillSessions
        .where((s) => s.scheduledDate.compareTo(todayStr) <= 0)
        .toList();

    final totalPlannedUpToToday = pastAndToday.length;
    final totalCompletedUpToToday = pastAndToday.where((s) => s.status == 'completed').length;
    final computedConsistency = totalPlannedUpToToday > 0
        ? ((totalCompletedUpToToday / totalPlannedUpToToday) * 100).round()
        : 100;

    // Schedule-aware streak calculation
    int calculatedStreak = 0;
    final sortedPast = [...pastAndToday]..sort((a, b) => b.scheduledDate.compareTo(a.scheduledDate));
    for (final s in sortedPast) {
      if (s.status == 'completed') {
        calculatedStreak++;
      } else if (s.status == 'skipped' || (s.status == 'planned' && s.scheduledDate.compareTo(todayStr) < 0)) {
        break;
      }
    }

    // Weekly completed count (this week: Monday to Sunday)
    final now = DateTime.now();
    final dayOfWeek = now.weekday;
    final monday = now.subtract(Duration(days: dayOfWeek - 1));
    final mondayStr = monday.toIso8601String().split('T')[0];
    final sunday = monday.add(const Duration(days: 6));
    final sundayStr = sunday.toIso8601String().split('T')[0];

    final weeklyCompletedCount = skillSessions
        .where((s) =>
            s.scheduledDate.compareTo(mondayStr) >= 0 &&
            s.scheduledDate.compareTo(sundayStr) <= 0 &&
            s.status == 'completed')
        .length;

    final completedSessions = skillSessions.where((s) => s.status == 'completed');
    final minutes = completedSessions.fold<int>(
      0,
      (sum, s) => sum + (s.actualDuration ?? s.plannedDuration),
    );

    final hours = (minutes / 60.0 * 10).round() / 10.0;

    return Skill(
      id: skillId,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      category: json['category'] as String? ?? 'Programming',
      description: json['description'] as String?,
      level: json['level'] as String? ?? 'Beginner',
      progress: computedConsistency,
      target: json['target'] as String?,
      weeklyTarget: json['weekly_target'] as int? ?? prefDays.length,
      sessionDuration: json['session_duration'] as int? ?? 60,
      preferredDays: prefDays,
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : DateTime.now(),
      sessions: skillSessions,
      todaySession: tSession,
      weeklyCompleted: weeklyCompletedCount,
      consistencyPct: computedConsistency,
      streak: calculatedStreak,
      totalMinutes: minutes,
      learningHours: hours,
    );
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'user_id': userId,
      'name': name,
      'category': category,
      'description': description,
      'level': level,
      'progress': progress,
      'target': target,
      'weekly_target': weeklyTarget,
      'session_duration': sessionDuration,
      'preferred_days': preferredDays,
      'status': status,
    };
  }
}
