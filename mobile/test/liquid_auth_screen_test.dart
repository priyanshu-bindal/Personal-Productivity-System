import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/auth/auth_flow_screen.dart';
import 'package:focus_flow/features/auth/widgets/liquid_auth_background.dart';
import 'package:focus_flow/features/auth/widgets/liquid_auth_card.dart';
import 'package:focus_flow/features/auth/widgets/liquid_auth_field.dart';
import 'package:focus_flow/features/auth/widgets/liquid_auth_secondary_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FocusFlow Liquid Auth UI Tests', () {
    testWidgets('Renders Login content by default with all required elements',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowScreen(),
          ),
        ),
      );

      // Fast-forward entrance animation (800ms)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      // Check background and card presence
      expect(find.byType(LiquidAuthBackground), findsOneWidget);
      expect(find.byType(LiquidAuthCard), findsOneWidget);

      // Check titles & subtitles
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue to FocusFlow'), findsOneWidget);

      // Check fields and buttons
      expect(find.byType(LiquidAuthTextField), findsNWidgets(2)); // Email & Password
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Validates email and password on Login submission',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      // Tap Sign In without filling fields
      await tester.tap(find.text('Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Validation error message appears inline
      expect(find.text('Please enter your email address.'), findsOneWidget);
    });

    testWidgets('Smoothly switches between Login, Sign Up, and Forgot Password',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      // 1. Switch to Sign Up
      await tester.tap(find.text('Sign Up'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350)); // transition complete

      expect(find.text('Create Account'), findsWidgets);
      expect(find.text('Welcome Back'), findsNothing);

      // 2. Switch back to Sign In
      // Scroll down slightly if needed to bring Sign In link into view
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final signInLink = find.text('Sign In');
      await tester.tap(signInLink);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Create Account'), findsNothing);

      // 3. Switch to Forgot Password
      await tester.tap(find.text('Forgot password?'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Reset password'), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);

      // 4. Return to Sign In
      await tester.tap(find.text('Back to Sign In'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Reset password'), findsNothing);
    });

    testWidgets('Forgot Password displays email validation error',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowScreen(initialMode: AuthMode.forgotPassword),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      // Tap Send reset link without entering email
      await tester.tap(find.text('Send reset link'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Please enter your email address.'), findsOneWidget);
    });

    testWidgets('Tapping Google button triggers interaction without crashing',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      await tester.tap(find.byType(LiquidAuthSecondaryButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Google authentication will be available soon.'),
          findsOneWidget);
    });
  });
}
