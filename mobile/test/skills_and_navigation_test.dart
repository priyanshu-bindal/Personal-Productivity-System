import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/core/widgets/custom_bottom_sheet.dart';
import 'package:focus_flow/core/widgets/premium_dropdown_field.dart';
import 'package:focus_flow/providers/chat_provider.dart';
import 'package:focus_flow/routes/scaffold_with_nav_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

GoRouter _createTestRouter() {
  return GoRouter(
    initialLocation: '/today',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const Text('TodayScreenContent'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/skills',
                builder: (context, state) => const Text('SkillsScreenContent'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/calendar',
                builder: (context, state) => const Text('CalendarScreenContent'),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const Text('ProgressScreenContent'),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const Text('MessagesScreenContent'),
      ),
      GoRoute(
        path: '/notes',
        builder: (context, state) => const Text('NotesScreenContent'),
      ),
      GoRoute(
        path: '/money',
        builder: (context, state) => const Text('MoneyScreenContent'),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const Text('SettingsScreenContent'),
      ),
    ],
  );
}

void main() {
  group('PremiumDropdownField Widget Tests', () {
    testWidgets('Renders selected value, opens popover on tap, and selects new item',
        (WidgetTester tester) async {
      String selected = 'Design';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setState) {
                  return PremiumDropdownField<String>(
                    label: 'Category',
                    value: selected,
                    items: const [
                      PremiumDropdownItem(
                        value: 'Programming',
                        label: 'Programming',
                        icon: LucideIcons.code,
                      ),
                      PremiumDropdownItem(
                        value: 'Design',
                        label: 'Design',
                        icon: LucideIcons.palette,
                      ),
                      PremiumDropdownItem(
                        value: 'Music',
                        label: 'Music',
                        icon: LucideIcons.music,
                      ),
                    ],
                    onChanged: (val) {
                      setState(() {
                        selected = val;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Verify initial selected state
      expect(find.text('Design'), findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('Programming'), findsNothing);

      // Tap to open popover
      await tester.tap(find.text('Design'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Items should now be visible in popover
      expect(find.text('Programming'), findsOneWidget);
      expect(find.text('Music'), findsOneWidget);

      // Select 'Programming'
      await tester.tap(find.text('Programming'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Popover should be dismissed and value updated
      expect(selected, 'Programming');
      expect(find.text('Programming'), findsOneWidget);
      expect(find.text('Music'), findsNothing);
    });

    testWidgets('Dismisses popover on tap outside', (WidgetTester tester) async {
      String selected = 'Music';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PremiumDropdownField<String>(
                label: 'Category',
                value: selected,
                items: const [
                  PremiumDropdownItem(
                    value: 'Programming',
                    label: 'Programming',
                    icon: LucideIcons.code,
                  ),
                  PremiumDropdownItem(
                    value: 'Music',
                    label: 'Music',
                    icon: LucideIcons.music,
                  ),
                ],
                onChanged: (val) {},
              ),
            ),
          ),
        ),
      );

      // Tap to open
      await tester.tap(find.text('Music'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Programming'), findsOneWidget);

      // Tap outside on the top left of the screen (modal barrier)
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      // Popover should close
      expect(find.text('Programming'), findsNothing);
      expect(find.text('Music'), findsOneWidget);
    });
  });

  group('CustomBottomSheet Widget Tests', () {
    testWidgets('Renders title, subtitle, close button and content smoothly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    CustomBottomSheet.show(
                      context: context,
                      title: 'Add New Skill',
                      subtitle: 'Track your learning journey',
                      child: const Text('Sheet Content Here'),
                    );
                  },
                  child: const Text('Open Sheet'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Add New Skill'), findsOneWidget);
      expect(find.text('Track your learning journey'), findsOneWidget);
      expect(find.text('Sheet Content Here'), findsOneWidget);

      // Tap close button
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      expect(find.text('Add New Skill'), findsNothing);
    });
  });

  group('ScaffoldWithNavBar More Menu Tests', () {
    testWidgets('Tapping More tab opens floating menu with 4 options and unread badge',
        (WidgetTester tester) async {
      final router = _createTestRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            totalUnreadChatCountProvider.overrideWith((ref) => Stream.value(3)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state: 5 tab items and Today content
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Skills'), findsOneWidget);
      expect(find.text('Calendar'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('More'), findsOneWidget);
      expect(find.text('TodayScreenContent'), findsOneWidget);

      // More menu should not be open yet
      expect(find.text('MORE FEATURES'), findsNothing);
      expect(find.text('Messages'), findsNothing);

      // Tap "More" tab
      await tester.tap(find.text('More'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Floating menu is now open!
      expect(find.text('MORE FEATURES'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('Money Tracker'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Verify unread badge count (3)
      expect(find.text('3'), findsOneWidget);

      // Tapping "More" tab again closes the menu
      await tester.tap(find.text('More'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('MORE FEATURES'), findsNothing);
      expect(find.text('Messages'), findsNothing);
    });

    testWidgets('Tapping another nav tab closes More menu and switches branch',
        (WidgetTester tester) async {
      final router = _createTestRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            totalUnreadChatCountProvider.overrideWith((ref) => Stream.value(0)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open More menu
      await tester.tap(find.text('More'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('MORE FEATURES'), findsOneWidget);

      // Tap Skills tab (index 1)
      await tester.tap(find.text('Skills'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Should have switched branch and closed menu
      expect(find.text('SkillsScreenContent'), findsOneWidget);
      expect(find.text('MORE FEATURES'), findsNothing);
    });

    testWidgets('Selecting Messages item in More menu closes menu and pushes /messages',
        (WidgetTester tester) async {
      final router = _createTestRouter();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            totalUnreadChatCountProvider.overrideWith((ref) => Stream.value(5)),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Open More menu
      await tester.tap(find.text('More'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('MORE FEATURES'), findsOneWidget);

      // Tap Messages
      await tester.tap(find.text('Messages'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      // Navigated to MessagesScreenContent
      expect(find.text('MessagesScreenContent'), findsOneWidget);
    });
  });
}
