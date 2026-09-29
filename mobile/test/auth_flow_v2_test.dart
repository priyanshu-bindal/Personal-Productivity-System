import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/auth_v2/auth_flow_v2_screen.dart';
import 'package:focus_flow/features/auth_v2/widgets/auth_background_v2.dart';
import 'package:focus_flow/features/auth_v2/widgets/auth_logo_v2.dart';
import 'package:focus_flow/features/auth_v2/widgets/glass_auth_field_v2.dart';
import 'package:focus_flow/features/auth_v2/widgets/liquid_glass_auth_card_v2.dart';
import 'package:focus_flow/features/auth_v2/widgets/liquid_glass_primary_button_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Configure mobile test viewport (e.g. 412x915 Pixel 7 device size)
  void setMobileViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('AuthFlowV2Screen UI & Interactions Tests', () {
    testWidgets('Renders Login mode by default with all required elements',
        (tester) async {
      setMobileViewport(tester);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowV2Screen(),
          ),
        ),
      );

      // Fast forward opening animation (350ms)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // 1. Verify Background and Logo
      expect(find.byType(AuthBackgroundV2), findsOneWidget);
      expect(find.byType(AuthLogoV2), findsOneWidget);
      expect(find.text('Stay focused. Keep growing.'), findsOneWidget);

      // 2. Verify Liquid Glass Card
      expect(find.byType(LiquidGlassAuthCardV2), findsOneWidget);

      // 3. Verify Titles
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue to FocusFlow'), findsOneWidget);

      // 4. Verify Fields & Buttons
      expect(find.byType(GlassAuthFieldV2), findsNWidgets(2)); // Email & Password
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.byType(LiquidGlassPrimaryButtonV2), findsOneWidget);
      expect(find.text('Continue with Google'), findsNothing);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('Validates empty fields on Login submission', (tester) async {
      setMobileViewport(tester);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowV2Screen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final signInButton = find.byType(LiquidGlassPrimaryButtonV2);
      await tester.ensureVisible(signInButton);
      await tester.tap(signInButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Error messages should appear
      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('Switches to Sign Up mode and back to Login smoothly',
        (tester) async {
      setMobileViewport(tester);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowV2Screen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Tap Sign Up link
      final signUpLink = find.text('Sign Up');
      await tester.ensureVisible(signUpLink);
      await tester.tap(signUpLink);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Verify Sign Up view: both title and button say "Create Account"
      expect(find.text('Create Account'), findsNWidgets(2));
      expect(find.text('Start building better habits with FocusFlow.'),
          findsOneWidget);
      expect(find.byType(GlassAuthFieldV2),
          findsNWidgets(4)); // Name, Email, Password, Confirm

      // Tap Sign In link to switch back
      final signInLink = find.text('Sign In');
      await tester.ensureVisible(signInLink);
      await tester.tap(signInLink);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Verify back in Login mode
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.byType(GlassAuthFieldV2), findsNWidgets(2));
    });

    testWidgets('Switches to Forgot Password mode and back to Login',
        (tester) async {
      setMobileViewport(tester);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowV2Screen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Tap Forgot password?
      final forgotLink = find.text('Forgot password?');
      await tester.ensureVisible(forgotLink);
      await tester.tap(forgotLink);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Verify Forgot Password view
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Back to Sign In'), findsOneWidget);

      // Tap Back to Sign In
      final backLink = find.text('Back to Sign In');
      await tester.ensureVisible(backLink);
      await tester.tap(backLink);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Verify back in Login mode
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('Validates Sign Up passwords match', (tester) async {
      setMobileViewport(tester);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AuthFlowV2Screen(
              initialMode: AuthModeV2.register,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Enter text into the 4 fields
      final textFields = find.byType(TextField);
      expect(textFields, findsNWidgets(4));

      await tester.enterText(textFields.at(0), 'John Doe');
      await tester.enterText(textFields.at(1), 'john@example.com');
      await tester.enterText(textFields.at(2), 'password123');
      await tester.enterText(textFields.at(3), 'password999');

      final createButton = find.byType(LiquidGlassPrimaryButtonV2);
      await tester.ensureVisible(createButton);
      await tester.tap(createButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });
  });
}
