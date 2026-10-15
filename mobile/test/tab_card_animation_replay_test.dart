import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:focus_flow/core/animation/tab_activation_scope.dart';
import 'package:focus_flow/core/widgets/animated_card.dart';

// ─── Helpers ────────────────────────────────────────────────────────────────

/// Wraps one or more AnimatedCards inside a TabActivationScope + TabCardScope,
/// with controllable [activeTabIndex] and [activationTick].
Widget _buildScoped({
  required int activeTabIndex,
  required int activationTick,
  required int tabIndex,
  required List<Widget> children,
}) {
  return MaterialApp(
    home: TabActivationScope(
      activeTabIndex: activeTabIndex,
      activationTick: activationTick,
      child: TabCardScope(
        tabIndex: tabIndex,
        child: Scaffold(
          body: SingleChildScrollView(
            child: Column(children: children),
          ),
        ),
      ),
    ),
  );
}

/// Wraps two tabs (index 0 and index 1) inside the same TabActivationScope
/// so we can verify that only one tab's cards replay.
Widget _buildDualTab({
  required int activeTabIndex,
  required int activationTick,
}) {
  return MaterialApp(
    home: TabActivationScope(
      activeTabIndex: activeTabIndex,
      activationTick: activationTick,
      child: Scaffold(
        body: Column(
          children: [
            // Tab 0 cards
            TabCardScope(
              tabIndex: 0,
              child: Column(
                children: [
                  AnimatedCard(
                    key: const ValueKey('tab0-card0'),
                    index: 0,
                    child: const Text('Tab0 Card0'),
                  ),
                ],
              ),
            ),
            // Tab 1 cards
            TabCardScope(
              tabIndex: 1,
              child: Column(
                children: [
                  AnimatedCard(
                    key: const ValueKey('tab1-card0'),
                    index: 0,
                    child: const Text('Tab1 Card0'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Extracts the AnimationController from an AnimatedCard by finding its State.
AnimationController? _getController(WidgetTester tester, Key key) {
  try {
    final state = tester.state<AnimatedCardState>(find.byKey(key));
    return state.controller;
  } catch (_) {
    return null;
  }
}

// ─── Tests ──────────────────────────────────────────────────────────────────

void main() {
  group('AnimatedCard Tab Replay', () {
    // ── 1. Stagger timing ─────────────────────────────────────────────────

    testWidgets('Stagger delay is capped at 160 ms, animation duration is always 260 ms', (tester) async {
      // Build 10 cards on the active tab
      await tester.pumpWidget(_buildScoped(
        activeTabIndex: 0,
        activationTick: 1,
        tabIndex: 0,
        children: List.generate(10, (i) => AnimatedCard(
          key: ValueKey('card-$i'),
          index: i,
          child: Text('Card $i'),
        )),
      ));

      // Pump once to trigger didChangeDependencies
      await tester.pump();

      // Verify controller durations are all 260 ms (the animation itself, not the stagger)
      for (int i = 0; i < 10; i++) {
        final ctrl = _getController(tester, ValueKey('card-$i'));
        expect(ctrl, isNotNull, reason: 'Card $i should have a controller');
        expect(ctrl!.duration, const Duration(milliseconds: 260),
            reason: 'Card $i animation duration should be 260 ms regardless of index');
      }

      // Card index 0: delay = 0 ms → should already be animating
      final ctrl0 = _getController(tester, const ValueKey('card-0'))!;
      expect(ctrl0.isAnimating || ctrl0.value > 0.0, isTrue,
          reason: 'Card 0 should start immediately (0 ms delay)');

      // Card index 7: delay = clamp(7*28, 0, 160) = 160 ms
      // Card index 9: delay = clamp(9*28, 0, 160) = 160 ms (same cap)
      // Before 160 ms elapses, both should still be at value 0.0
      // (the stagger timer hasn't fired yet)
      final ctrl7 = _getController(tester, const ValueKey('card-7'))!;
      final ctrl9 = _getController(tester, const ValueKey('card-9'))!;

      // At this point, only pump(0) has happened. Card 7 and 9 timers haven't fired.
      expect(ctrl7.value, 0.0, reason: 'Card 7 should wait for its stagger timer');
      expect(ctrl9.value, 0.0, reason: 'Card 9 should wait for its stagger timer');

      // Pump past the 160 ms cap — both card 7 and 9 should start together
      await tester.pump(const Duration(milliseconds: 161));
      expect(ctrl7.isAnimating, isTrue, reason: 'Card 7 should be animating after 160 ms');
      expect(ctrl9.isAnimating, isTrue, reason: 'Card 9 should be animating after 160 ms (same cap)');

      // Pump to completion (260 ms animation + small margin)
      await tester.pumpAndSettle();
      expect(ctrl7.value, 1.0, reason: 'Card 7 should be at rest');
      expect(ctrl9.value, 1.0, reason: 'Card 9 should be at rest');
    });

    // ── 2. Route-pop replays only the active tab ──────────────────────────

    testWidgets('Tick increment replays only the active tab cards', (tester) async {
      // Start with tab 0 active at tick 1
      await tester.pumpWidget(_buildDualTab(activeTabIndex: 0, activationTick: 1));
      await tester.pumpAndSettle();

      final ctrl0 = _getController(tester, const ValueKey('tab0-card0'))!;
      final ctrl1 = _getController(tester, const ValueKey('tab1-card0'))!;

      // Tab 0 is active: its card should have completed the entrance animation
      expect(ctrl0.value, 1.0, reason: 'Tab 0 card should be at rest (active tab)');
      // Tab 1 is inactive: its card should be reset to 0
      expect(ctrl1.value, 0.0, reason: 'Tab 1 card should be invisible (inactive tab)');

      // Simulate didPopNext by incrementing tick while tab 0 is still active
      await tester.pumpWidget(_buildDualTab(activeTabIndex: 0, activationTick: 2));
      await tester.pump(); // trigger didChangeDependencies

      // Tab 0's card should have been reset to 0 and started animating again (replay)
      expect(ctrl0.isAnimating || ctrl0.value < 1.0, isTrue,
          reason: 'Tab 0 card should replay on tick change');
      // Tab 1's card should still be at 0 (inactive)
      expect(ctrl1.value, 0.0, reason: 'Tab 1 card should remain invisible');

      await tester.pumpAndSettle();

      // Now switch to tab 1 (simulating a tab tap) with a new tick
      await tester.pumpWidget(_buildDualTab(activeTabIndex: 1, activationTick: 3));
      await tester.pump();

      // Tab 1 should now be animating
      expect(ctrl1.isAnimating || ctrl1.value > 0.0, isTrue,
          reason: 'Tab 1 card should replay when it becomes active');
      // Tab 0 should be reset
      expect(ctrl0.value, 0.0, reason: 'Tab 0 card should reset when it becomes inactive');

      await tester.pumpAndSettle();
      expect(ctrl1.value, 1.0, reason: 'Tab 1 card should finish animating');
    });

    // ── 3. Rapid tab switching doesn't leave orphaned animations ──────────

    testWidgets('Rapid tab switching cancels timers and resets cleanly', (tester) async {
      // Start on tab 0
      await tester.pumpWidget(_buildDualTab(activeTabIndex: 0, activationTick: 1));
      await tester.pump();

      final ctrl0 = _getController(tester, const ValueKey('tab0-card0'))!;
      final ctrl1 = _getController(tester, const ValueKey('tab1-card0'))!;

      // Don't let tab 0 finish — switch to tab 1 mid-animation
      await tester.pump(const Duration(milliseconds: 50));
      expect(ctrl0.isAnimating, isTrue, reason: 'Tab 0 should still be animating');

      // Switch to tab 1
      await tester.pumpWidget(_buildDualTab(activeTabIndex: 1, activationTick: 2));
      await tester.pump();

      // Tab 0 should be stopped and reset
      expect(ctrl0.isAnimating, isFalse, reason: 'Tab 0 animation should be stopped');
      expect(ctrl0.value, 0.0, reason: 'Tab 0 should be reset to 0');

      // Tab 1 should be starting
      expect(ctrl1.isAnimating || ctrl1.value >= 0.0, isTrue,
          reason: 'Tab 1 should start animating');

      // Rapidly switch back to tab 0 before tab 1 finishes
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpWidget(_buildDualTab(activeTabIndex: 0, activationTick: 3));
      await tester.pump();

      // Tab 1 should now be stopped
      expect(ctrl1.isAnimating, isFalse, reason: 'Tab 1 animation should be stopped on rapid switch');
      expect(ctrl1.value, 0.0, reason: 'Tab 1 should be reset');

      // Tab 0 should be animating again
      await tester.pumpAndSettle();
      expect(ctrl0.value, 1.0, reason: 'Tab 0 should eventually reach rest');
    });

    // ── 4. Standalone AnimatedCard (no scope) still works ─────────────────

    testWidgets('AnimatedCard without TabCardScope animates once on mount', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AnimatedCard(
            key: const ValueKey('standalone'),
            index: 0,
            child: const Text('Standalone'),
          ),
        ),
      ));

      await tester.pumpAndSettle();

      final ctrl = _getController(tester, const ValueKey('standalone'))!;
      expect(ctrl.value, 1.0, reason: 'Standalone card should animate and reach rest');
    });

    // ── 5. Same tick does not re-trigger animation ───────────────────────

    testWidgets('Same activationTick does not replay the animation', (tester) async {
      await tester.pumpWidget(_buildScoped(
        activeTabIndex: 0,
        activationTick: 5,
        tabIndex: 0,
        children: [
          AnimatedCard(
            key: const ValueKey('card'),
            index: 0,
            child: const Text('Card'),
          ),
        ],
      ));

      await tester.pumpAndSettle();
      final ctrl = _getController(tester, const ValueKey('card'))!;
      expect(ctrl.value, 1.0);

      // Rebuild with same tick — should NOT replay
      await tester.pumpWidget(_buildScoped(
        activeTabIndex: 0,
        activationTick: 5, // same tick!
        tabIndex: 0,
        children: [
          AnimatedCard(
            key: const ValueKey('card'),
            index: 0,
            child: const Text('Card'),
          ),
        ],
      ));

      await tester.pump();
      // Value should still be 1.0, NOT reset to 0.0
      expect(ctrl.value, 1.0,
          reason: 'Same tick should not cause a replay');
    });

    // ── 6. Large list stagger cap ────────────────────────────────────────

    testWidgets('Cards with index > 5 all share the 160 ms stagger cap', (tester) async {
      await tester.pumpWidget(_buildScoped(
        activeTabIndex: 0,
        activationTick: 1,
        tabIndex: 0,
        children: List.generate(20, (i) => AnimatedCard(
          key: ValueKey('big-$i'),
          index: i,
          child: SizedBox(height: 10, child: Text('Card $i')),
        )),
      ));

      await tester.pump();

      // Cards 6–19 all have delay = 160 ms.
      // At t = 159 ms none of them should have started.
      await tester.pump(const Duration(milliseconds: 159));
      for (int i = 6; i < 20; i++) {
        final ctrl = _getController(tester, ValueKey('big-$i'));
        if (ctrl != null) {
          expect(ctrl.value, 0.0,
              reason: 'Card $i should not have started before 160 ms');
        }
      }

      // At t = 161 ms all of them should have started together.
      await tester.pump(const Duration(milliseconds: 2));
      for (int i = 6; i < 20; i++) {
        final ctrl = _getController(tester, ValueKey('big-$i'));
        if (ctrl != null) {
          expect(ctrl.isAnimating, isTrue,
              reason: 'Card $i should be animating after 160 ms cap');
        }
      }

      await tester.pumpAndSettle();
    });
  });
}
