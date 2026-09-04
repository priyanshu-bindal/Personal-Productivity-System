class LearningSession {
  final String id;
  final String userId;
  final String? skillId;
  final String? skillName;
  final int durationMinutes;
  final int plannedDuration;
  final int? actualDuration;
  final String scheduledDate; // YYYY-MM-DD
  final String status; // 'planned', 'completed', 'skipped'
  final DateTime? completedAt;
  final String? notes;
  final DateTime createdAt;

  LearningSession({
    required this.id,
    required this.userId,
    this.skillId,
    this.skillName,
    required this.durationMinutes,
    required this.plannedDuration,
    this.actualDuration,
    required this.scheduledDate,
    required this.status,
    this.completedAt,
    this.notes,
    required this.createdAt,
  });

  factory LearningSession.fromJson(Map<String, dynamic> json) {
    String? sName;
    if (json['skill'] != null && json['skill'] is Map) {
      sName = json['skill']['name'] as String?;
    }

    return LearningSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      skillId: json['skill_id'] as String?,
      skillName: sName,
      durationMinutes: json['duration_minutes'] as int? ?? json['planned_duration'] as int? ?? 60,
      plannedDuration: json['planned_duration'] as int? ?? json['duration_minutes'] as int? ?? 60,
      actualDuration: json['actual_duration'] as int?,
      scheduledDate: json['scheduled_date'] as String? ?? 
          (json['created_at'] != null 
              ? (json['created_at'] as String).split('T')[0] 
              : DateTime.now().toIso8601String().split('T')[0]),
      status: json['status'] as String? ?? 'planned',
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at'] as String) : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'skill_id': skillId,
      'duration_minutes': durationMinutes,
      'planned_duration': plannedDuration,
      'actual_duration': actualDuration,
      'scheduled_date': scheduledDate,
      'status': status,
      'completed_at': completedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  LearningSession copyWith({
    String? status,
    int? actualDuration,
    DateTime? completedAt,
    String? notes,
  }) {
    return LearningSession(
      id: id,
      userId: userId,
      skillId: skillId,
      skillName: skillName,
      durationMinutes: durationMinutes,
      plannedDuration: plannedDuration,
      actualDuration: actualDuration ?? this.actualDuration,
      scheduledDate: scheduledDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      createdAt: createdAt,
    );
  }
}
