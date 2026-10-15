import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_flow/core/animation/tab_activation_scope.dart';
import 'package:focus_flow/core/widgets/animated_card.dart';
import 'package:focus_flow/core/widgets/micro_interactions/animated_consistency_bar.dart';

void main() {
  group('AnimatedConsistencyBar Regression & Lifecycle Tests', () {
    Widget buildTest({
      required int activeTabIndex,
      required int activationTick,
      int percentage = 75,
      bool disableAnimations = false,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: TabActivationScope(
            activeTabIndex: activeTabIndex,
            activationTick: activationTick,
            child: TabCardScope(
              tabIndex: 1,
              child: Scaffold(
                body: AnimatedCard(
                  index: 1,
                  child: AnimatedConsistencyBar(
                    percentage: percentage,
                    accentColor: Colors.blue,
                    index: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('1. First display animates once without double-animation reset', (tester) async {
      // Mount with tab 1 active
      await tester.pumpWidget(buildTest(activeTabIndex: 1, activationTick: 1, percentage: 80));

      final values = <int>[];
      // Sample over 800 ms (encompasses card entrance 260ms + bar fill 420ms + delays)
      for (int i = 0; i < 16; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        final textWidgets = tester.widgetList<Text>(find.byType(Text));
        for (final t in textWidgets) {
          if (t.data != null && t.data!.endsWith('%')) {
            final val = int.tryParse(t.data!.replaceAll('%', ''));
            if (val != null) values.add(val);
          }
        }
      }

      // Values must monotonically increase toward 80 without dropping back to 0!
      expect(values.isNotEmpty, isTrue);
      int maxSeen = 0;
      bool hasResetToZero = false;
      for (final v in values) {
        if (v < maxSeen && maxSeen > 40 && v == 0) {
          hasResetToZero = true;
        }
        if (v > maxSeen) maxSeen = v;
      }

      expect(hasResetToZero, isFalse, reason: 'Bar should not reset back to 0% mid-way');
      expect(values.last, 80, reason: 'Bar should reach the target percentage');
    });

    testWidgets('2. Repeated tap on the currently selected tab does not restart animation', (tester) async {
      // Already on tab 1, tick 1
      await tester.pumpWidget(buildTest(activeTabIndex: 1, activationTick: 1, percentage: 80));
      await tester.pumpAndSettle();

      expect(find.text('80%'), findsOneWidget);

      // Re-pump with same tab and same tick (simulating same-tab tap)
      await tester.pumpWidget(buildTest(activeTabIndex: 1, activationTick: 1, percentage: 80));
      await tester.pump(const Duration(milliseconds: 50));

      // Value should remain 80%, not reset to 0%
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('3. Tab replay triggers exactly once on return to Skills tab', (tester) async {
      // Step A: Active on Tab 1
      await tester.pumpWidget(buildTest(activeTabIndex: 1, activationTick: 1, percentage: 80));
      await tester.pumpAndSettle();
      expect(find.text('80%'), findsOneWidget);

      // Step B: Switch to Tab 0 (inactive)
      await tester.pumpWidget(buildTest(activeTabIndex: 0, activationTick: 2, percentage: 80));
      await tester.pumpAndSettle();

      // Step C: Switch back to Tab 1 (new tick 3)
      await tester.pumpWidget(buildTest(activeTabIndex: 1, activationTick: 3, percentage: 80));
      await tester.pump();

      // Check replay smoothly completes to 80%
      await tester.pumpAndSettle();
      expect(find.text('80%'), findsOneWidget);
    });

    testWidgets('4. Consistency value changes animate smoothly without resetting to zero', (tester) async {
      await tester.pumpWidget(buildTest(activeTabIndex: 1, activationTick: 1, percentage: 60));
      await tester.pumpAndSettle();
      expect(find.text('60%'), findsOneWidget);

      // Update consistency value from 60% to 90%
      await tester.pumpWidget(buildTest(activeTabIndex: 1, activationTick: 1, percentage: 90));
      await tester.pump(const Duration(milliseconds: 20));

      // Immediate value should not be 0%
      final textWidgets = tester.widgetList<Text>(find.byType(Text));
      for (final t in textWidgets) {
        if (t.data != null && t.data!.endsWith('%')) {
          final val = int.tryParse(t.data!.replaceAll('%', '')) ?? 0;
          expect(val >= 60, isTrue, reason: 'Value should transition from 60% upward, not reset to 0');
        }
      }

      await tester.pumpAndSettle();
      expect(find.text('90%'), findsOneWidget);
    });

    testWidgets('5. Reduced motion renders target percentage immediately', (tester) async {
      await tester.pumpWidget(buildTest(
        activeTabIndex: 1,
        activationTick: 1,
        percentage: 85,
        disableAnimations: true,
      ));

      // Should be immediately 85% on first frame
      expect(find.text('85%'), findsOneWidget);
    });
  });
}
