import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/chat_provider.dart';
import '../providers/money_provider.dart';
import '../providers/notes_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/sessions_provider.dart';
import '../providers/skills_provider.dart';
import '../providers/streak_provider.dart';
import '../providers/trash_provider.dart';
import 'firebase_service.dart';
import 'supabase_service.dart';

/// Central coordinator for the authenticated user session lifecycle.
///
/// Responsibilities:
/// 1. Detects transitions between authenticated users (User A -> User B).
/// 2. Ensures previous user-scoped in-memory state is completely invalidated
///    BEFORE new user data is ever rendered or queried.
/// 3. Signs out and re-establishes the Firebase Auth bridge so Firestore
///    listeners never retain or leak the previous user's credentials or streams.
/// 4. Discards all user-scoped Riverpod providers upon SIGNED_OUT or user change.
class UserSessionManager {
  final Ref _ref;
  String? _currentUserId;
  StreamSubscription<AuthState>? _authSub;

  UserSessionManager(this._ref);

  /// Initializes the session coordinator and starts listening to Supabase auth events.
  void initialize() {
    _currentUserId = SupabaseService.currentUserId;
    _authSub?.cancel();
    _authSub = SupabaseService.client.auth.onAuthStateChange.listen((data) {
      _handleAuthStateChange(data.event, data.session?.user.id);
    });
  }

  /// Cancels active auth subscriptions.
  void dispose() {
    _authSub?.cancel();
    _authSub = null;
  }

  /// Handles incoming Supabase auth events reactively.
  Future<void> _handleAuthStateChange(
      AuthChangeEvent event, String? eventUserId) async {
    final effectiveUserId = eventUserId ?? SupabaseService.currentUserId;

    switch (event) {
      case AuthChangeEvent.signedOut:
        await onUserSignedOut();
        break;
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.userUpdated:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.initialSession:
        if (effectiveUserId != _currentUserId) {
          await onUserSignedIn(effectiveUserId);
        }
        break;
      default:
        if (effectiveUserId != _currentUserId) {
          if (effectiveUserId == null) {
            await onUserSignedOut();
          } else {
            await onUserSignedIn(effectiveUserId);
          }
        }
        break;
    }
  }

  /// Called before or during sign-out to clean up all user-scoped state,
  /// terminate Firebase bridge session, and reset all user providers.
  Future<void> onUserSignedOut() async {
    _currentUserId = null;
    await FirebaseService.signOut();
    _invalidateUserScopedProviders();
  }

  /// Called upon successful sign-in or auth user transition.
  Future<void> onUserSignedIn(String? newUserId) async {
    final prevUserId = _currentUserId;
    _currentUserId = newUserId;

    // If switching between different authenticated accounts, cleanly sign out Firebase first
    if (prevUserId != null && prevUserId != newUserId) {
      await FirebaseService.signOut();
    }

    _invalidateUserScopedProviders();
  }

  /// Synchronously and comprehensively invalidates all Riverpod providers
  /// holding user-specific data, models, streams, or search/filter states.
  void _invalidateUserScopedProviders() {
    // Profile & user settings
    _ref.invalidate(profileProvider);
    _ref.invalidate(streakProvider);

    // Learning sessions & skills
    _ref.invalidate(sessionsProvider);
    _ref.invalidate(skillsProvider);

    // Personal finance & budgets & trash
    _ref.invalidate(expensesProvider);
    _ref.invalidate(budgetsProvider);
    _ref.invalidate(trashedExpensesProvider);
    _ref.invalidate(expenseSearchProvider);
    _ref.invalidate(expenseCategoryFilterProvider);
    _ref.invalidate(expenseFilterStateProvider);

    // Notes
    _ref.invalidate(notesProvider);
    _ref.invalidate(noteSearchQueryProvider);
    _ref.invalidate(noteSortNewestProvider);

    // Chat & Firebase bridge state
    _ref.invalidate(firebaseChatUidProvider);
    _ref.invalidate(currentChatUserShortIdProvider);
    _ref.invalidate(conversationsStreamProvider);
    _ref.invalidate(totalUnreadChatCountProvider);
  }
}

/// Global provider for the [UserSessionManager] singleton.
final userSessionManagerProvider = Provider<UserSessionManager>((ref) {
  final manager = UserSessionManager(ref);
  manager.initialize();
  ref.onDispose(() => manager.dispose());
  return manager;
});
