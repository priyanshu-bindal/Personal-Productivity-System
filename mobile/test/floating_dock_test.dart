import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/widgets/floating_dock.dart';

void main() {
  const testItems = [
    DockItem(icon: Icons.today_rounded, label: 'Today'),
    DockItem(icon: Icons.psychology_rounded, label: 'Skills'),
    DockItem(icon: Icons.calendar_month_rounded, label: 'Calendar'),
    DockItem(icon: Icons.insights_rounded, label: 'Progress'),
    DockItem(
      icon: Icons.grid_view_rounded,
      label: 'More',
      badge: true,
      actionOnly: true,
    ),
  ];

  Widget buildDockApp({
    int currentIndex = 0,
    ValueChanged<int>? onChanged,
    bool switchWhileDragging = true,
    bool disableAnimations = false,
    Size size = const Size(390, 844),
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        padding: const EdgeInsets.only(bottom: 34),
        disableAnimations: disableAnimations,
      ),
      child: MaterialApp(
        home: Scaffold(
          extendBody: true,
          bottomNavigationBar: FloatingDock(
            items: testItems,
            currentIndex: currentIndex,
            onChanged: onChanged ?? (_) {},
            switchWhileDragging: switchWhileDragging,
          ),
        ),
      ),
    );
  }

  group('FloatingDock UI & Responsiveness', () {
    testWidgets('Renders all tab items, labels and semantics',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildDockApp());
      await tester.pumpAndSettle();

      for (final item in testItems) {
        expect(find.text(item.label), findsOneWidget);
        expect(find.byIcon(item.icon), findsOneWidget);
        expect(
          find.bySemanticsLabel(item.label),
          findsOneWidget,
        );
      }
    });

    testWidgets('Adapts to narrow screen (320px) without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildDockApp(size: const Size(320, 640)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final item in testItems) {
        expect(find.text(item.label), findsOneWidget);
      }
    });

    testWidgets('Adapts to 360px screen without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildDockApp(size: const Size(360, 800)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final item in testItems) {
        expect(find.text(item.label), findsOneWidget);
      }
    });

    testWidgets('Adapts to wide tablet screen (1024px)',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildDockApp(size: const Size(1024, 768)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      for (final item in testItems) {
        expect(find.text(item.label), findsOneWidget);
      }
    });
  });

  group('FloatingDock Gestures & Switching', () {
    testWidgets('Tapping a tab triggers onChanged with its index',
        (WidgetTester tester) async {
      int selected = 0;
      await tester.pumpWidget(
        buildDockApp(
          currentIndex: 0,
          onChanged: (i) => selected = i,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skills'));
      await tester.pumpAndSettle();
      expect(selected, 1);

      await tester.tap(find.text('Progress'));
      await tester.pumpAndSettle();
      expect(selected, 3);
    });

    testWidgets(
        'Dragging horizontally switches tabs live when switchWhileDragging is true',
        (WidgetTester tester) async {
      final selectedIndices = <int>[];
      await tester.pumpWidget(
        buildDockApp(
          currentIndex: 0,
          switchWhileDragging: true,
          onChanged: (i) => selectedIndices.add(i),
        ),
      );
      await tester.pumpAndSettle();

      final firstItem = find.text('Today');
      final firstPos = tester.getCenter(firstItem);

      // Start drag at first item and drag right across to More
      final gesture = await tester.startGesture(firstPos);
      await tester.pump();

      // Drag right by 64px (to Skills)
      await gesture.moveBy(const Offset(64, 0));
      await tester.pump();

      // Drag right by another 64px (to Calendar)
      await gesture.moveBy(const Offset(64, 0));
      await tester.pump();

      // Drag vertically outside bounds while moving horizontally
      await gesture.moveBy(const Offset(64, -100));
      await tester.pump();

      await gesture.up();
      await tester.pumpAndSettle();

      expect(selectedIndices, containsAllInOrder([1, 2, 3]));
    });

    testWidgets(
        'When switchWhileDragging is false, onChanged is only called on release',
        (WidgetTester tester) async {
      final selectedIndices = <int>[];
      await tester.pumpWidget(
        buildDockApp(
          currentIndex: 0,
          switchWhileDragging: false,
          onChanged: (i) => selectedIndices.add(i),
        ),
      );
      await tester.pumpAndSettle();

      final firstItem = find.text('Today');
      final firstPos = tester.getCenter(firstItem);

      final gesture = await tester.startGesture(firstPos);
      await tester.pump();

      // Move to Skills
      await gesture.moveBy(const Offset(64, 0));
      await tester.pump();
      expect(selectedIndices, isEmpty);

      // Move to Calendar
      await gesture.moveBy(const Offset(64, 0));
      await tester.pump();
      expect(selectedIndices, isEmpty);

      // Lift finger
      await gesture.up();
      await tester.pumpAndSettle();

      expect(selectedIndices, [2]);
    });

    testWidgets('Dragging past edges clamps to first and last tabs',
        (WidgetTester tester) async {
      int lastIndex = 0;
      await tester.pumpWidget(
        buildDockApp(
          currentIndex: 2,
          onChanged: (i) => lastIndex = i,
        ),
      );
      await tester.pumpAndSettle();

      final centerItem = find.text('Calendar');
      final centerPos = tester.getCenter(centerItem);

      // Drag far left beyond dock
      final gesture = await tester.startGesture(centerPos);
      await tester.pump();
      await gesture.moveBy(const Offset(-400, 0));
      await tester.pump();
      expect(lastIndex, 0);

      // Drag far right beyond dock (tab 4 is actionOnly, so it fires on release)
      await gesture.moveBy(const Offset(800, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      expect(lastIndex, 4);
    });

    testWidgets(
        'Normal tap on a different tab fires onChanged exactly once when parent updates currentIndex',
        (WidgetTester tester) async {
      int changeCount = 0;
      int activeIndex = 0;

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return buildDockApp(
              currentIndex: activeIndex,
              onChanged: (i) {
                changeCount++;
                setState(() => activeIndex = i);
              },
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Skills'));
      await tester.pumpAndSettle();

      expect(changeCount, 1);
      expect(activeIndex, 1);
    });

    testWidgets(
        'Re-tapping active tab fires onChanged once to support iOS pop-to-root',
        (WidgetTester tester) async {
      int changeCount = 0;
      await tester.pumpWidget(
        buildDockApp(
          currentIndex: 0,
          onChanged: (_) => changeCount++,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();

      expect(changeCount, 1);
    });

    testWidgets(
        'Dragging across actionOnly tab does not fire live, fires once on release',
        (WidgetTester tester) async {
      final changes = <int>[];
      await tester.pumpWidget(
        buildDockApp(
          currentIndex: 3, // Progress
          onChanged: (i) => changes.add(i),
        ),
      );
      await tester.pumpAndSettle();

      final progressPos = tester.getCenter(find.text('Progress'));
      final gesture = await tester.startGesture(progressPos);
      await tester.pump();

      // Drag right to More (actionOnly)
      await gesture.moveBy(const Offset(64, 0));
      await tester.pump();

      // Should NOT fire live while dragging over actionOnly tab
      expect(changes, isEmpty);

      // Release over More
      await gesture.up();
      await tester.pumpAndSettle();

      // Fires on release
      expect(changes, [4]);
    });

    testWidgets('Pointer cancel resets pressed state without committing tab change',
        (WidgetTester tester) async {
      final changes = <int>[];
      await tester.pumpWidget(
        buildDockApp(
          currentIndex: 0,
          switchWhileDragging: false,
          onChanged: (i) => changes.add(i),
        ),
      );
      await tester.pumpAndSettle();

      final firstPos = tester.getCenter(find.text('Today'));
      final gesture = await tester.startGesture(firstPos);
      await tester.pump();

      await gesture.moveBy(const Offset(64, 0)); // Move to Skills
      await tester.pump();

      // System cancel
      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(changes, isEmpty);
    });

    testWidgets('Respects reduced motion settings without scale animation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        buildDockApp(
          currentIndex: 0,
          disableAnimations: true,
        ),
      );
      await tester.pumpAndSettle();

      final centerItem = find.text('Today');
      final centerPos = tester.getCenter(centerItem);

      final gesture = await tester.startGesture(centerPos);
      await tester.pump();

      expect(tester.takeException(), isNull);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
