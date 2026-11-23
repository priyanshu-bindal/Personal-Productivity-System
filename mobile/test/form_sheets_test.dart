import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/core/theme/app_theme.dart';
import 'package:focus_flow/core/widgets/custom_bottom_sheet.dart';
import 'package:focus_flow/features/money/add_expense_sheet.dart';
import 'package:focus_flow/features/skills/add_skill_sheet.dart';
import 'package:lucide_icons/lucide_icons.dart';

void main() {
  testWidgets(
    'Expense sheet slides in and out and keeps cents in quick amounts',
    (tester) async {
      Map<String, dynamic>? result;
      await _pumpForm(
        tester,
        width: 360,
        title: 'Add Expense',
        icon: LucideIcons.wallet,
        form: const AddExpenseSheet(),
        onResult: (value) => result = value,
      );

      final header = find.text('Add Expense').first;
      await tester.tap(find.text('Open form'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final enteringTop = tester.getTopLeft(header).dy;
      await tester.pumpAndSettle();
      final restingTop = tester.getTopLeft(header).dy;
      expect(enteringTop, greaterThan(restingTop));
      expect(tester.testTextInput.isVisible, isFalse);

      await tester.enterText(find.byType(TextFormField).first, '12.50');
      await tester.tap(find.text('+₹100'));
      await tester.pumpAndSettle();
      expect(find.text('112.5'), findsOneWidget);

      final submit = find.widgetWithText(FilledButton, 'Add Expense');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      expect(tester.getTopLeft(header).dy, greaterThan(restingTop));
      await tester.pumpAndSettle();
      expect(find.text('Add Expense'), findsNothing);
      expect(result?['amount'], 112.5);
      expect(result?['description'], 'Food expense');
    },
  );

  testWidgets('Skill form preserves its data while the keyboard resizes it', (
    tester,
  ) async {
    Map<String, dynamic>? result;
    await _pumpForm(
      tester,
      width: 320,
      title: 'Edit Skill',
      icon: LucideIcons.bookOpen,
      reduceMotion: true,
      form: const AddSkillSheet(existingSkillId: 'skill', initialDuration: 15),
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('Open form'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, '15m'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'Spanish');

    tester.view.viewInsets = const FakeViewPadding(bottom: 440);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    tester.view.resetViewInsets();
    await tester.pumpAndSettle();
    expect(find.text('Spanish'), findsOneWidget);

    final tuesday = find.text('Tue');
    await tester.ensureVisible(tuesday);
    await tester.tap(tuesday);
    await tester.pumpAndSettle();
    expect(find.text('1.0 hrs / week · 4 sessions'), findsOneWidget);

    final submit = find.widgetWithText(FilledButton, 'Update Skill');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pump();
    expect(find.text('Edit Skill'), findsNothing);
    expect(result?['name'], 'Spanish');
    expect(result?['sessionDuration'], 15);
    expect(result?['preferredDays'], contains('Tuesday'));
  });
}

Future<void> _pumpForm(
  WidgetTester tester, {
  required double width,
  required String title,
  required IconData icon,
  required Widget form,
  required ValueChanged<Map<String, dynamic>?> onResult,
  bool reduceMotion = false,
}) async {
  tester.view.physicalSize = Size(width, 640);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetViewInsets);

  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.darkTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: child!,
      ),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              onResult(
                await CustomBottomSheet.show<Map<String, dynamic>>(
                  context: context,
                  title: title,
                  leadingIcon: icon,
                  child: form,
                ),
              );
            },
            child: const Text('Open form'),
          ),
        ),
      ),
    ),
  );
}
