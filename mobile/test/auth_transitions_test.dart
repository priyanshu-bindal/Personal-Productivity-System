import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/auth/auth_flow_screen.dart';
import 'package:focus_flow/features/auth/widgets/liquid_glass_card.dart';
import 'package:focus_flow/features/auth/widgets/focusflow_logo.dart';
import 'package:focus_flow/routes/liquid_page_transition.dart';

void main() {
  group('AuthFlowScreen Tests', () {
    testWidgets(
        'AuthFlowScreen renders in login mode by default with logo and card',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowScreen(),
          ),
        ),
      );

      // Logo and the login card should be visible
      expect(find.byType(FocusFlowLogo), findsOneWidget);
      expect(find.byType(LiquidGlassCard), findsOneWidget);

      // Login-mode title text should be present
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets(
        'AuthFlowScreen in login mode shows sign-in button and sign-up link',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowScreen(),
          ),
        ),
      );

      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets(
        'Tapping Sign Up link switches to register mode without navigation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowScreen(),
          ),
        ),
      );

      // Tap the Sign Up link text
      await tester.tap(find.text('Sign Up'));
      await tester.pump(); // trigger setState
      await tester.pump(const Duration(milliseconds: 300)); // finish animation

      // Register card title should now appear (also appears in button label → findsWidgets)
      expect(find.text('Create Account'), findsWidgets);
      // Login title should be gone
      expect(find.text('Welcome Back'), findsNothing);
    });

    testWidgets(
        'Hero tag focusflow-brand is present in AuthFlowScreen',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowScreen(),
          ),
        ),
      );

      // The Hero widget with the brand tag should exist
      final heroFinder = find.byWidgetPredicate(
        (widget) => widget is Hero && widget.tag == 'focusflow-brand',
      );
      expect(heroFinder, findsOneWidget);
    });

    test(
        'LiquidPageTransition.authMainScreen creates page with correct durations',
        () {
      final mainPage = LiquidPageTransition.authMainScreen(
        key: const ValueKey('login'),
        child: const SizedBox(),
      );
      expect(mainPage.transitionDuration, const Duration(milliseconds: 380));
      expect(
          mainPage.reverseTransitionDuration, const Duration(milliseconds: 340));
    });
  });
}
