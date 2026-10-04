import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import '../services/supabase_service.dart';
import '../services/supabase_jwt_recovery.dart';
import '../services/notification_service.dart';
import '../services/cache_service.dart';
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

  Future<void> fetchProfile({bool forceRefresh = false}) async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      if (mounted) state = const AsyncValue.data(null);
      return;
    }

    // Cache-first check
    if (!forceRefresh) {
      final cached = await CacheService().get<UserProfile>(
        effectiveUserId,
        'profile',
        (json) {
          final user = SupabaseService.currentUser;
          return UserProfile.fromJson(
            json as Map<String, dynamic>,
            email: user?.email ?? '',
          );
        },
      );

      if (cached != null) {
        if (mounted && SupabaseService.currentUserId == effectiveUserId) {
          state = AsyncValue.data(cached.data);
        }
        if (cached.isFresh) {
          return; // Serve fresh cached data immediately
        }
      }
    }

    try {
      final result = await SupabaseJwtRecovery.withJwtRecovery(
        SupabaseService.client,
        () => _doFetch(effectiveUserId),
      );
      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;

      // Persist to cache before updating state
      if (result != null) {
        await CacheService().set(effectiveUserId, 'profile', result.toJson());
      }

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

    UserProfile profile;
    if (res != null) {
      profile = UserProfile.fromJson(res, email: user?.email ?? '');
    } else {
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

      profile = UserProfile.fromJson(newRes, email: user?.email ?? '');
    }

    // Check if user has an explicit local preference in SharedPreferences
    final storedPref = await NotificationService().getStoredPreference(userId);
    if (storedPref != null) {
      profile = profile.copyWith(practiceReminders: storedPref);
    }
    return profile;
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
    await CacheService().invalidate(effectiveUserId, 'profile');
    await fetchProfile(forceRefresh: true);
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

    // Optimistically update Riverpod state so UI updates immediately without lag
    if (state.hasValue && state.value != null) {
      state = AsyncValue.data(state.value!.copyWith(
        defaultSessionDuration: defaultSessionDuration,
        practiceReminders: practiceReminders,
        dailyReminderTime: dailyReminderTime,
      ));
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
    await CacheService().invalidate(effectiveUserId, 'profile');
    await fetchProfile(forceRefresh: true);
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
    await CacheService().invalidate(effectiveUserId, 'profile');
    await fetchProfile(forceRefresh: true);
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
    await CacheService().invalidate(effectiveUserId, 'profile');
    await fetchProfile(forceRefresh: true);
  }
}
