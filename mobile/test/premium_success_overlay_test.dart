import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/core/widgets/micro_interactions/premium_success_overlay.dart';

void main() {
  group('PremiumSuccessOverlay', () {
    testWidgets('renders title, subtitle, and custom painter correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PremiumSuccessOverlay(
              title: 'Cache Cleared Successfully',
              subtitle: 'Your app is refreshed and ready.',
              autoDismissDelay: Duration(seconds: 10),
            ),
          ),
        ),
      );

      // Verify custom painter is present
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify text elements
      expect(find.text('Cache Cleared Successfully'), findsOneWidget);
      expect(find.text('Your app is refreshed and ready.'), findsOneWidget);

      // Forward animation
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Cache Cleared Successfully'), findsOneWidget);
    });

    testWidgets('auto dismisses and invokes onDismissed after specified delay', (tester) async {
      bool dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (context) => Scaffold(
                body: PremiumSuccessOverlay(
                  title: 'Cache Cleared Successfully',
                  subtitle: 'Your app is refreshed and ready.',
                  autoDismissDelay: const Duration(milliseconds: 500),
                  onDismissed: () => dismissed = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(dismissed, isFalse);

      // Advance clock past auto-dismiss duration
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('PremiumSuccessOverlay.show displays modal and dismisses cleanly', (tester) async {
      late BuildContext capturedContext;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                capturedContext = context;
                return ElevatedButton(
                  onPressed: () {
                    PremiumSuccessOverlay.show(
                      context: context,
                      title: 'Cache Cleared Successfully',
                      subtitle: 'Your app is refreshed and ready.',
                      autoDismissDelay: const Duration(milliseconds: 800),
                    );
                  },
                  child: const Text('Show Overlay'),
                );
              },
            ),
          ),
        ),
      );

      // Tap to trigger show
      await tester.tap(find.text('Show Overlay'));
      await tester.pump(); // Start transition
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Cache Cleared Successfully'), findsOneWidget);
      expect(find.text('Your app is refreshed and ready.'), findsOneWidget);

      // Ensure calling show again while active does not stack another overlay
      PremiumSuccessOverlay.show(
        context: capturedContext,
        title: 'Duplicate Cache Overlay',
      );
      await tester.pump();
      expect(find.text('Duplicate Cache Overlay'), findsNothing);

      // Advance time to allow auto-dismissal
      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();

      expect(find.text('Cache Cleared Successfully'), findsNothing);
    });

    testWidgets('respects disableAnimations accessibility setting', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: PremiumSuccessOverlay(
                title: 'Instant Cache Cleared',
                subtitle: 'No animation test.',
                autoDismissDelay: Duration(seconds: 10),
              ),
            ),
          ),
        ),
      );

      // Single pump should immediately render text and complete controller
      await tester.pump();
      expect(find.text('Instant Cache Cleared'), findsOneWidget);
      expect(find.text('No animation test.'), findsOneWidget);
    });
  });
}
