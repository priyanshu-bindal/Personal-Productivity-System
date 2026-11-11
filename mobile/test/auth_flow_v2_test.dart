import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/auth_v2/auth_flow_v2_screen.dart';
import 'package:focus_flow/features/auth_v2/widgets/auth_background_v2.dart';
import 'package:focus_flow/features/auth_v2/widgets/auth_logo_v2.dart';
import 'package:focus_flow/features/auth_v2/widgets/glass_auth_field_v2.dart';
import 'package:focus_flow/features/auth_v2/widgets/liquid_glass_primary_button_v2.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpAuth(WidgetTester tester,
      {AuthModeV2 mode = AuthModeV2.login}) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(home: AuthFlowV2Screen(initialMode: mode)),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final f = find.text(text);
    await tester.ensureVisible(f.first);
    await tester.tap(f.first);
    await tester.pumpAndSettle();
  }

  group('AuthFlowV2Screen', () {
    testWidgets('Sign in renders brand, segmented control and form', (tester) async {
      await pumpAuth(tester);

      expect(find.byType(AuthBackgroundV2), findsOneWidget);
      expect(find.byType(AuthLogoV2), findsOneWidget);
      expect(find.text('FocusFlow'), findsOneWidget);
      expect(find.text('Stay focused. Keep growing.'), findsOneWidget);

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
      // "Sign in" appears in the segmented control and on the button.
      expect(find.text('Sign in'), findsNWidgets(2));
      expect(find.byType(GlassAuthFieldV2), findsNWidgets(2));
      expect(find.byType(LiquidGlassPrimaryButtonV2), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('Validates empty sign-in fields', (tester) async {
      await pumpAuth(tester);

      final button = find.byType(LiquidGlassPrimaryButtonV2);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });

    testWidgets('Segmented control switches to Sign up and back', (tester) async {
      await pumpAuth(tester);

      await tapText(tester, 'Sign up');
      expect(find.text('Create your account'), findsOneWidget);
      expect(find.text('Create account'), findsOneWidget);
      expect(find.byType(GlassAuthFieldV2), findsNWidgets(4));

      await tapText(tester, 'Sign in');
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.byType(GlassAuthFieldV2), findsNWidgets(2));
    });

    testWidgets('Forgot password opens reset step and returns', (tester) async {
      await pumpAuth(tester);

      await tapText(tester, 'Forgot password?');
      expect(find.text('Reset password'), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);
      // Segmented control is hidden on the reset step.
      expect(find.text('Sign up'), findsNothing);

      await tapText(tester, 'Sign in'); // back chevron label
      expect(find.text('Welcome back'), findsOneWidget);
    });

    testWidgets('Reset step validates email', (tester) async {
      await pumpAuth(tester, mode: AuthModeV2.forgotPassword);

      await tapText(tester, 'Send reset link');
      expect(find.text('Please enter your email address.'), findsOneWidget);
    });

    testWidgets('Sign up validates matching passwords and shows strength',
        (tester) async {
      await pumpAuth(tester, mode: AuthModeV2.register);

      final fields = find.byType(TextField);
      expect(fields, findsNWidgets(4));
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'john@example.com');
      await tester.enterText(fields.at(2), 'Password123!x');
      await tester.enterText(fields.at(3), 'password999');
      await tester.pumpAndSettle();

      expect(find.text('Strong'), findsOneWidget);

      final button = find.byType(LiquidGlassPrimaryButtonV2);
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('Password visibility toggles', (tester) async {
      await pumpAuth(tester);

      TextField passwordField() =>
          tester.widget<TextField>(find.byType(TextField).at(1));
      expect(passwordField().obscureText, isTrue);

      await tester.tap(find.bySemanticsLabel('Show password'));
      await tester.pumpAndSettle();
      expect(passwordField().obscureText, isFalse);
    });
  });
}
