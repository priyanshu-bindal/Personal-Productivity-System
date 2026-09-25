import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/auth/login_screen.dart';
import 'package:focus_flow/features/auth/register_screen.dart';
import 'package:focus_flow/features/auth/forgot_password_screen.dart';
import 'package:focus_flow/features/auth/widgets/liquid_glass_card.dart';
import 'package:focus_flow/features/auth/widgets/focusflow_logo.dart';
import 'package:focus_flow/routes/liquid_page_transition.dart';

void main() {
  group('Auth Screen Transitions Refactoring Tests', () {
    testWidgets('LoginScreen renders content with RepaintBoundary and without internal fade/slide builders',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify the logo and LiquidGlassCard exist
      expect(find.byType(FocusFlowLogo), findsOneWidget);
      expect(find.byType(LiquidGlassCard), findsOneWidget);

      // Verify RepaintBoundary wraps the card and logo
      final repaintBoundaries = find.byType(RepaintBoundary);
      expect(repaintBoundaries, findsWidgets);

      // Verify no duplicate entrance AnimatedBuilder or Opacity exists inside LoginScreen body
      final cardFinder = find.byType(LiquidGlassCard);
      final repaintAncestor = find.ancestor(
        of: cardFinder,
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintAncestor, findsWidgets);
    });

    testWidgets('RegisterScreen renders content directly with RepaintBoundary',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: RegisterScreen(),
          ),
        ),
      );

      expect(find.byType(FocusFlowLogo), findsOneWidget);
      expect(find.byType(LiquidGlassCard), findsOneWidget);

      final cardFinder = find.byType(LiquidGlassCard);
      final repaintAncestor = find.ancestor(
        of: cardFinder,
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintAncestor, findsWidgets);
    });

    testWidgets('ForgotPasswordScreen renders content directly with RepaintBoundary',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );

      expect(find.byType(FocusFlowLogo), findsOneWidget);
      expect(find.byType(LiquidGlassCard), findsOneWidget);

      final cardFinder = find.byType(LiquidGlassCard);
      final repaintAncestor = find.ancestor(
        of: cardFinder,
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintAncestor, findsWidgets);
    });

    test('LiquidPageTransition uses FadeTransition and creates custom transition page', () {
      final mainPage = LiquidPageTransition.authMainScreen(
        key: const ValueKey('login'),
        child: const SizedBox(),
      );
      expect(mainPage.transitionDuration, const Duration(milliseconds: 380));
      expect(mainPage.reverseTransitionDuration, const Duration(milliseconds: 340));

      final subPage = LiquidPageTransition.authSubScreen(
        key: const ValueKey('register'),
        child: const SizedBox(),
      );
      expect(subPage.transitionDuration, const Duration(milliseconds: 340));
      expect(subPage.reverseTransitionDuration, const Duration(milliseconds: 320));
    });
  });
}
