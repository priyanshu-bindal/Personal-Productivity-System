import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/supabase_service.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth_v2/auth_flow_v2_screen.dart';
import '../features/auth/email_verification_screen.dart';
import '../core/theme/legacy_messages_theme.dart';
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
import '../features/messages/messages_screen.dart';
import '../features/messages/new_message_screen.dart';
import '../features/messages/chat_screen.dart';
import 'scaffold_with_nav_bar.dart';
import 'liquid_page_transition.dart';

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

/// Global route observer enabling RouteAware subscription across tabs and pushed screens
final appRouteObserver = RouteObserver<ModalRoute<void>>();

/// Root navigator — detail screens use it to cover the floating navbar.
final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/login',
    observers: [appRouteObserver],
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
      // Persistent Auth Shell with shared LiquidBackground
      ShellRoute(
        builder: (context, state, child) {
          // Static OLED canvas. (The old animated painter here ran forever
          // behind opaque auth screens — pure wasted GPU on slow phones.)
          return ColoredBox(color: Colors.black, child: child);
        },
        routes: [
          // Onboarding — shared continuous LiquidBackground, pure fade+scale transition
          GoRoute(
            path: '/onboarding',
            pageBuilder: (context, state) =>
                LiquidPageTransition.onboardingScreen(
              key: state.pageKey,
              child: const OnboardingScreen(),
            ),
          ),
          // Single route for all auth card modes (login / register / forgot)
          GoRoute(
            path: '/login',
            pageBuilder: (context, state) =>
                LiquidPageTransition.authFlowScreen(
              key: state.pageKey,
              child: const AuthFlowV2Screen(),
            ),
          ),
          // Backward-compat redirects so any deep-link or old code still works
          GoRoute(
            path: '/register',
            redirect: (context, state) => '/login',
          ),
          GoRoute(
            path: '/forgot-password',
            redirect: (context, state) => '/login',
          ),
        ],
      ),
      GoRoute(
        path: '/email-verification',
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),

      // Main app shell — every pinnable tab is a branch so it can live in the
      // bottom bar or the sidebar. Tab switches cross-fade smoothly.
      StatefulShellRoute(
        pageBuilder: (context, state, navigationShell) =>
            LiquidPageTransition.appShell(
          key: state.pageKey,
          child: ScaffoldWithNavBar(navigationShell: navigationShell),
        ),
        navigatorContainerBuilder: (context, navigationShell, children) =>
            AnimatedBranchContainer(
          currentIndex: navigationShell.currentIndex,
          children: [
            for (var i = 0; i < children.length; i++)
              // Notes & Money weren't designed around a floating bar; give them
              // a bottom inset so their lists and FABs clear it.
              (i == 4 || i == 5) ? NavBarSafeInset(child: children[i]) : children[i],
          ],
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
                    builder: (context, state) =>
                        SkillDetailScreen(skillId: state.pathParameters['id']!),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, state) => const NotesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/money',
                builder: (context, state) => const MoneyScreen(),
                routes: [
                  GoRoute(
                    path: 'category/:category',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => CategoryTransactionsScreen(
                      category: state.pathParameters['category'] ?? '',
                    ),
                  ),
                  GoRoute(
                    path: 'trash',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => const TrashScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),

      // Messages — intentionally unchanged: pushed full-screen with its
      // original theme and stock page transition.
      GoRoute(
        path: '/messages',
        pageBuilder: (context, state) => PlatformDefaultPage(
          key: state.pageKey,
          child: const MessagesScreen(),
        ),
        routes: [
          GoRoute(
            path: 'new',
            pageBuilder: (context, state) => PlatformDefaultPage(
              key: state.pageKey,
              child: const NewMessageScreen(),
            ),
          ),
          GoRoute(
            path: 'chat/:id',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              final extra = state.extra as Map<String, dynamic>?;
              return PlatformDefaultPage(
                key: state.pageKey,
                child: ChatScreen(
                  conversationId: id,
                  otherChatId: extra?['otherChatId'] as String?,
                  otherDisplayName: extra?['otherDisplayName'] as String?,
                ),
              );
            },
          ),
        ],
      ),
    ],
  );
});
