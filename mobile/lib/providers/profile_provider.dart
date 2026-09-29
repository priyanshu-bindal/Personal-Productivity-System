import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import '../services/supabase_jwt_recovery.dart';
import 'auth_provider.dart';

final profileProvider =
    StateNotifierProvider<ProfileNotifier, AsyncValue<UserProfile?>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ProfileNotifier(userId);
});

class ProfileNotifier extends StateNotifier<AsyncValue<UserProfile?>> {
  final String? _userId;

  ProfileNotifier([this._userId])
      : super(_userId == null
            ? const AsyncValue.data(null)
            : const AsyncValue.loading()) {
    if (_userId != null) {
      fetchProfile();
    }
  }

  // --- Fetch ----------------------------------------------------------------

  Future<void> fetchProfile() async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      if (mounted) state = const AsyncValue.data(null);
      return;
    }

    try {
      final result = await SupabaseJwtRecovery.withJwtRecovery(
        SupabaseService.client,
        () => _doFetch(effectiveUserId),
      );
      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;
      state = AsyncValue.data(result);
    } on PostgrestException catch (e, st) {
      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;
      state = AsyncValue.error(e, st);
    } catch (e, st) {
      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;
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
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return;
    }

    final updateData = <String, dynamic>{};
    if (fullName != null) updateData['full_name'] = fullName;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

    await SupabaseJwtRecovery.withJwtRecovery(
      SupabaseService.client,
      () async {
        await SupabaseService.client
            .from('profiles')
            .update(updateData)
            .eq('id', effectiveUserId);
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
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return;
    }

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
            .eq('id', effectiveUserId),
      );
    } catch (_) {
      // Preferences update failure is non-fatal; silently continue.
    }
    await fetchProfile();
  }

  // --- Account Deletion Scheduling ------------------------------------------

  Future<void> scheduleDeletion() async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      throw Exception('Not authenticated');
    }

    final now = DateTime.now().toUtc();
    final scheduledFor = now.add(const Duration(days: 15));

    await SupabaseJwtRecovery.withJwtRecovery(
      SupabaseService.client,
      () => SupabaseService.client.from('profiles').update({
        'deletion_requested_at': now.toIso8601String(),
        'deletion_scheduled_for': scheduledFor.toIso8601String(),
      }).eq('id', effectiveUserId),
    );
    await fetchProfile();
  }

  Future<void> cancelDeletion() async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      throw Exception('Not authenticated');
    }

    await SupabaseJwtRecovery.withJwtRecovery(
      SupabaseService.client,
      () => SupabaseService.client.from('profiles').update({
        'deletion_requested_at': null,
        'deletion_scheduled_for': null,
      }).eq('id', effectiveUserId),
    );
    await fetchProfile();
  }
}
