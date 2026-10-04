import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';
import '../services/user_session_manager.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  try {
    return SupabaseService.client.auth.onAuthStateChange;
  } catch (_) {
    return const Stream.empty();
  }
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.value?.session?.user ?? SupabaseService.currentUser;
});

/// Emits the current Supabase user's UID (or null if unauthenticated).
/// Serves as the primary reactivity boundary for all user-scoped data.
final currentUserIdProvider = Provider<String?>((ref) {
  final user = ref.watch(currentUserProvider);
  return user?.id ?? SupabaseService.currentUserId;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

class AuthController extends StateNotifier<AsyncValue<void>> {
  final Ref? _ref;

  AuthController([this._ref]) : super(const AsyncValue.data(null));

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncValue.loading();
    try {
      final res = await SupabaseService.client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final newUserId = res.user?.id;
      if (_ref != null) {
        await _ref.read(userSessionManagerProvider).onUserSignedIn(newUserId);
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await SupabaseService.client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': fullName},
      );
      if (res.session != null && res.user != null) {
        if (_ref != null) {
          await _ref
              .read(userSessionManagerProvider)
              .onUserSignedIn(res.user!.id);
        }
      }
      state = const AsyncValue.data(null);
      return res;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      // 1. Wipe all user-scoped in-memory state and Firebase bridge BEFORE signing out
      if (_ref != null) {
        await _ref.read(userSessionManagerProvider).onUserSignedOut();
      }
      // 2. Sign out of Supabase
      await SupabaseService.client.auth.signOut();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();
    try {
      await SupabaseService.client.auth.resetPasswordForEmail(email);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});
