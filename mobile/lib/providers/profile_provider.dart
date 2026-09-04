import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';

final profileProvider = StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  ProfileNotifier() : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    try {
      final user = SupabaseService.currentUser;
      final res = await SupabaseService.client
          .from('profiles')
          .select('*')
          .eq('id', userId)
          .maybeSingle();

      if (res != null) {
        state = AsyncValue.data(UserProfile.fromJson(res, email: user?.email ?? ''));
      } else {
        final newRes = await SupabaseService.client
            .from('profiles')
            .upsert({
              'id': userId,
              'full_name': user?.userMetadata?['full_name'] ?? '',
              'avatar_url': user?.userMetadata?['avatar_url'] ?? '',
            })
            .select()
            .single();

        state = AsyncValue.data(UserProfile.fromJson(newRes, email: user?.email ?? ''));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final updateData = <String, dynamic>{};
    if (fullName != null) updateData['full_name'] = fullName;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

    await SupabaseService.client.from('profiles').update(updateData).eq('id', userId);
    if (fullName != null) {
      await SupabaseService.client.auth.updateUser(UserAttributes(data: {'full_name': fullName}));
    }
    await fetchProfile();
  }

  Future<void> updatePreferences({
    int? defaultSessionDuration,
    bool? practiceReminders,
    String? dailyReminderTime,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final updateData = <String, dynamic>{};
    if (defaultSessionDuration != null) updateData['default_session_duration'] = defaultSessionDuration;
    if (practiceReminders != null) updateData['practice_reminders'] = practiceReminders;
    if (dailyReminderTime != null) updateData['daily_reminder_time'] = dailyReminderTime;

    try {
      await SupabaseService.client.from('profiles').update(updateData).eq('id', userId);
    } catch (e) {
      // Graceful fallback
    }
    await fetchProfile();
  }
}
