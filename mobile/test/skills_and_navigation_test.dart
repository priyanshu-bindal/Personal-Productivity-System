import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/core/widgets/custom_bottom_sheet.dart';
import 'package:focus_flow/core/widgets/premium_dropdown_field.dart';
import 'package:focus_flow/providers/chat_provider.dart';
import 'package:focus_flow/routes/scaffold_with_nav_bar.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

GoRouter _createTestRouter() {
  StatefulShellBranch branch(String path, String label) => StatefulShellBranch(
        routes: [
          GoRoute(path: path, builder: (context, state) => Text(label)),
        ],
      );

  return GoRouter(
    initialLocation: '/today',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          branch('/today', 'TodayScreenContent'),
          branch('/skills', 'SkillsScreenContent'),
          branch('/calendar', 'CalendarScreenContent'),
          branch('/progress', 'ProgressScreenContent'),
          branch('/notes', 'NotesScreenContent'),
          branch('/money', 'MoneyScreenContent'),
          branch('/settings', 'SettingsScreenContent'),
        ],
      ),
      GoRoute(
        path: '/messages',
        builder: (context, state) => const Text('MessagesScreenContent'),
      ),
    ],
  );
}

Future<void> _pumpShell(WidgetTester tester, {int unread = 0}) async {
  SharedPreferences.setMockInitialValues({});
  tester.view.physicalSize = const Size(412, 915);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        totalUnreadChatCountProvider.overrideWith((ref) => Stream.value(unread)),
      ],
      child: MaterialApp.router(routerConfig: _createTestRouter()),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSidebar(WidgetTester tester) async {
  await tester.tap(find.text('More'));
  await tester.pumpAndSettle();
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

  group('ScaffoldWithNavBar glass navbar & sidebar', () {
    testWidgets('Navbar shows default pinned tabs plus More; More opens sidebar',
        (WidgetTester tester) async {
      await _pumpShell(tester, unread: 3);

      for (final label in ['Today', 'Skills', 'Calendar', 'Progress', 'More']) {
        expect(find.text(label), findsOneWidget);
      }
      expect(find.text('TodayScreenContent'), findsOneWidget);
      expect(find.text('NAVIGATE'), findsNothing);

      await _openSidebar(tester);

      expect(find.text('NAVIGATE'), findsOneWidget);
      for (final label in ['Notes', 'Money', 'Messages', 'Settings']) {
        expect(find.text(label), findsOneWidget);
      }
      // Unread badge on the Messages row
      expect(find.text('3'), findsOneWidget);

      // Tapping the scrim closes it
      await tester.tapAt(const Offset(405, 400));
      await tester.pumpAndSettle();
      expect(find.text('NAVIGATE'), findsNothing);
    });

    testWidgets('Tapping a navbar tab switches branch', (WidgetTester tester) async {
      await _pumpShell(tester);

      await tester.tap(find.text('Skills'));
      await tester.pumpAndSettle();
      expect(find.text('SkillsScreenContent'), findsOneWidget);
    });

    testWidgets('Selecting a sidebar tab switches branch and closes sidebar',
        (WidgetTester tester) async {
      await _pumpShell(tester);
      await _openSidebar(tester);

      await tester.tap(find.text('Notes'));
      await tester.pumpAndSettle();

      expect(find.text('NotesScreenContent'), findsOneWidget);
      expect(find.text('NAVIGATE'), findsNothing);
    });

    testWidgets('Selecting Messages in sidebar pushes /messages',
        (WidgetTester tester) async {
      await _pumpShell(tester, unread: 5);
      await _openSidebar(tester);

      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      expect(find.text('MessagesScreenContent'), findsOneWidget);
    });

    testWidgets('Pinning a tab in the sidebar editor adds it to the navbar',
        (WidgetTester tester) async {
      await _pumpShell(tester);
      // Unpin Progress, pin Money.
      await _openSidebar(tester);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      final progressMinus = find.byIcon(LucideIcons.minusCircle).at(3); // Progress
      await tester.ensureVisible(progressMinus);
      await tester.pumpAndSettle();
      await tester.tap(progressMinus);
      await tester.pumpAndSettle();
      final moneyRow = find.ancestor(
        of: find.text('Money').last,
        matching: find.byType(Row),
      );
      final moneyPlus =
          find.descendant(of: moneyRow.first, matching: find.byIcon(LucideIcons.plusCircle));
      await tester.ensureVisible(moneyPlus);
      await tester.pumpAndSettle();
      await tester.tap(moneyPlus);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(405, 400));
      await tester.pumpAndSettle();

      expect(find.text('Progress'), findsNothing);
      expect(find.text('Money'), findsOneWidget);

      await tester.tap(find.text('Money'));
      await tester.pumpAndSettle();
      expect(find.text('MoneyScreenContent'), findsOneWidget);
    });

    testWidgets('Cannot unpin below the 2-tab minimum', (WidgetTester tester) async {
      await _pumpShell(tester);
      await _openSidebar(tester);
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      for (var i = 0; i < 3; i++) {
        final minus = find.byIcon(LucideIcons.minusCircle).first;
        await tester.ensureVisible(minus);
        await tester.pumpAndSettle();
        await tester.tap(minus);
        await tester.pumpAndSettle();
      }
      expect(find.byIcon(LucideIcons.minusCircle), findsNWidgets(2));
      await tester.pump(const Duration(seconds: 2)); // let the limit hint fade
    });
  });
}
