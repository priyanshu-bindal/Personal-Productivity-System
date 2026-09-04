class UserProfile {
  final String id;
  final String email;
  final String fullName;
  final String avatarUrl;
  final int defaultSessionDuration;
  final bool practiceReminders;
  final String dailyReminderTime;

  // Streak tracking (stored in Supabase profiles table)
  final int currentStreak;
  final int longestStreak;
  final String? lastStreakDate; // 'YYYY-MM-DD'

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.avatarUrl,
    this.defaultSessionDuration = 60,
    this.practiceReminders = true,
    this.dailyReminderTime = '09:00',
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastStreakDate,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json, {String email = ''}) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: email.isNotEmpty ? email : (json['email'] as String? ?? ''),
      fullName: json['full_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String? ?? '',
      defaultSessionDuration: json['default_session_duration'] as int? ?? 60,
      practiceReminders: json['practice_reminders'] as bool? ?? true,
      dailyReminderTime: json['daily_reminder_time'] as String? ?? '09:00',
      currentStreak: json['current_streak'] as int? ?? 0,
      longestStreak: json['longest_streak'] as int? ?? 0,
      lastStreakDate: json['last_streak_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'default_session_duration': defaultSessionDuration,
      'practice_reminders': practiceReminders,
      'daily_reminder_time': dailyReminderTime,
      'current_streak': currentStreak,
      'longest_streak': longestStreak,
      'last_streak_date': lastStreakDate,
    };
  }

  UserProfile copyWith({
    String? fullName,
    String? avatarUrl,
    int? defaultSessionDuration,
    bool? practiceReminders,
    String? dailyReminderTime,
    int? currentStreak,
    int? longestStreak,
    String? lastStreakDate,
    bool clearLastStreakDate = false,
  }) {
    return UserProfile(
      id: id,
      email: email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      defaultSessionDuration: defaultSessionDuration ?? this.defaultSessionDuration,
      practiceReminders: practiceReminders ?? this.practiceReminders,
      dailyReminderTime: dailyReminderTime ?? this.dailyReminderTime,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastStreakDate: clearLastStreakDate ? null : (lastStreakDate ?? this.lastStreakDate),
    );
  }
}
