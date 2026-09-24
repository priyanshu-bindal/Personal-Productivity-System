import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/register_screen.dart';
import '../features/auth/forgot_password_screen.dart';
import '../features/auth/email_verification_screen.dart';
import '../features/today/today_screen.dart';
import '../features/skills/skills_screen.dart';
import '../features/skills/skill_detail_screen.dart';
import '../features/calendar/calendar_screen.dart';
import '../features/progress/progress_screen.dart';
import '../features/notes/notes_screen.dart';
import '../features/money/money_screen.dart';
import '../features/money/category_transactions_screen.dart';
import '../features/money/trash_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/streak/streak_screen.dart';
import '../features/messages/messages_screen.dart';
import '../features/messages/new_message_screen.dart';
import '../features/messages/chat_screen.dart';
import 'scaffold_with_nav_bar.dart';

/// Bridges a Stream into a [Listenable] so GoRouter can react to auth changes.
class _GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  _GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final _authRefreshNotifier = _GoRouterRefreshStream(
  SupabaseService.client.auth.onAuthStateChange,
);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    // refreshListenable makes GoRouter re-run redirect on every auth state change
    refreshListenable: _authRefreshNotifier,
    redirect: (BuildContext context, GoRouterState state) {
      final user = SupabaseService.currentUser;
      final isAuthRoute = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/onboarding') ||
          state.matchedLocation.startsWith('/forgot-password') ||
          state.matchedLocation.startsWith('/email-verification');

      if (user == null && !isAuthRoute) {
        return '/login';
      }
      if (user != null && isAuthRoute) {
        return '/today';
      }
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/onboarding',
        redirect: (context, state) => '/login',
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const LoginScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Forward/enter curve
            final enterCurved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            // Secondary curve (when register or another screen pushes over login)
            final secondaryCurved = CurvedAnimation(
              parent: secondaryAnimation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );

            return AnimatedBuilder(
              animation: secondaryCurved,
              builder: (context, staticChild) {
                final double depthScale = 1.0 - (0.05 * secondaryCurved.value);
                final double depthOpacity = 1.0 - (0.45 * secondaryCurved.value);
                final double depthSlideX = -0.04 * secondaryCurved.value;

                return Transform.translate(
                  offset: Offset(depthSlideX * MediaQuery.of(context).size.width, 0),
                  child: Transform.scale(
                    scale: depthScale,
                    child: Opacity(
                      opacity: depthOpacity.clamp(0.0, 1.0),
                      child: staticChild,
                    ),
                  ),
                );
              },
              child: FadeTransition(
                opacity: enterCurved,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.0, 0.04),
                    end: Offset.zero,
                  ).animate(enterCurved),
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
        ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const RegisterScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.10, 0.0),
                  end: Offset.zero,
                ).animate(curved),
                child: Transform.scale(
                  scale: 0.96 + (0.04 * curved.value),
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 420),
          reverseTransitionDuration: const Duration(milliseconds: 360),
        ),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ForgotPasswordScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.08, 0.0),
                  end: Offset.zero,
                ).animate(curved),
                child: Transform.scale(
                  scale: 0.96 + (0.04 * curved.value),
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 350),
        ),
      ),
      GoRoute(
        path: '/email-verification',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),

      // Bottom Navigation Shell with smooth entrance transition
      StatefulShellRoute.indexedStack(
        pageBuilder: (context, state, navigationShell) => CustomTransitionPage(
          key: state.pageKey,
          child: ScaffoldWithNavBar(navigationShell: navigationShell),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            );
            return FadeTransition(
              opacity: curved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.03),
                  end: Offset.zero,
                ).animate(curved),
                child: Transform.scale(
                  scale: 0.95 + (0.05 * curved.value),
                  child: child,
                ),
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/skills',
                builder: (context, state) => const SkillsScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return SkillDetailScreen(skillId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
        ],
      ),

      // Sub-routes outside shell
      GoRoute(
        path: '/notes',
        builder: (context, state) => const NotesScreen(),
      ),
      GoRoute(
        path: '/money',
        builder: (context, state) => const MoneyScreen(),
        routes: [
          GoRoute(
            path: 'category/:category',
            pageBuilder: (context, state) {
              final category = state.pathParameters['category'] ?? '';
              return CustomTransitionPage(
                key: state.pageKey,
                child: CategoryTransactionsScreen(category: category),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );
                  return FadeTransition(
                    opacity:
                        Tween<double>(begin: 0.0, end: 1.0).animate(curved),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 250),
                reverseTransitionDuration: const Duration(milliseconds: 220),
              );
            },
          ),
          GoRoute(
            path: 'trash',
            pageBuilder: (context, state) {
              return CustomTransitionPage(
                key: state.pageKey,
                child: const TrashScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                    reverseCurve: Curves.easeInCubic,
                  );
                  return FadeTransition(
                    opacity:
                        Tween<double>(begin: 0.0, end: 1.0).animate(curved),
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.06, 0),
                        end: Offset.zero,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 250),
                reverseTransitionDuration: const Duration(milliseconds: 220),
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const MessagesScreen(),
        routes: [
          GoRoute(
            path: 'new',
            builder: (context, state) => const NewMessageScreen(),
          ),
          GoRoute(
            path: 'chat/:id',
            builder: (context, state) {
              final id = state.pathParameters['id']!;
              final extra = state.extra as Map<String, dynamic>?;
              return ChatScreen(
                conversationId: id,
                otherChatId: extra?['otherChatId'] as String?,
                otherDisplayName: extra?['otherDisplayName'] as String?,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/streak',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const StreakScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOut,
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.04, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 320),
        ),
      ),
    ],
  );
});
