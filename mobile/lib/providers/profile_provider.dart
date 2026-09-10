import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import '../services/supabase_jwt_recovery.dart';

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  return ProfileNotifier();
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  ProfileNotifier() : super(const AsyncValue.loading()) {
    fetchProfile();
  }

  // --- Fetch ----------------------------------------------------------------

  Future<void> fetchProfile() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    // Keep existing data visible while we refresh (avoids flash-of-loading).
    if (state is! AsyncLoading) {
      // Already have data — silently refresh in background; keep showing it.
    } else {
      state = const AsyncValue.loading();
    }

    try {
      final result = await SupabaseJwtRecovery.withJwtRecovery(
        SupabaseService.client,
        () => _doFetch(userId),
      );
      state = AsyncValue.data(result);
    } on PostgrestException catch (e, st) {
      // Surface a typed error so TodayScreen can display a friendly message.
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<UserProfile?> _doFetch(String userId) async {
    final user = SupabaseService.currentUser;
    final res = await SupabaseService.client
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .maybeSingle();

    if (res != null) {
      return UserProfile.fromJson(res, email: user?.email ?? '');
    }

    // Profile row missing — upsert a minimal one.
    final newRes = await SupabaseService.client
        .from('profiles')
        .upsert({
          'id': userId,
          'full_name': user?.userMetadata?['full_name'] ?? '',
          'avatar_url': user?.userMetadata?['avatar_url'] ?? '',
        })
        .select()
        .single();

    return UserProfile.fromJson(newRes, email: user?.email ?? '');
  }

  // --- Update ---------------------------------------------------------------

  Future<void> updateProfile({String? fullName, String? avatarUrl}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final updateData = <String, dynamic>{};
    if (fullName != null) updateData['full_name'] = fullName;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

    await SupabaseJwtRecovery.withJwtRecovery(
      SupabaseService.client,
      () async {
        await SupabaseService.client
            .from('profiles')
            .update(updateData)
            .eq('id', userId);
        if (fullName != null) {
          await SupabaseService.client.auth
              .updateUser(UserAttributes(data: {'full_name': fullName}));
        }
      },
    );
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
    if (defaultSessionDuration != null) {
      updateData['default_session_duration'] = defaultSessionDuration;
    }
    if (practiceReminders != null) {
      updateData['practice_reminders'] = practiceReminders;
    }
    if (dailyReminderTime != null) {
      updateData['daily_reminder_time'] = dailyReminderTime;
    }

    try {
      await SupabaseJwtRecovery.withJwtRecovery(
        SupabaseService.client,
        () => SupabaseService.client
            .from('profiles')
            .update(updateData)
            .eq('id', userId),
      );
    } catch (_) {
      // Preferences update failure is non-fatal; silently continue.
    }
    await fetchProfile();
  }
}
