import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/core/widgets/micro_interactions/animated_add_button.dart';
import 'package:focus_flow/core/widgets/micro_interactions/animated_checkbox.dart';
import 'package:focus_flow/core/widgets/micro_interactions/animated_checkmark.dart';
import 'package:focus_flow/core/widgets/micro_interactions/animated_delete.dart';
import 'package:focus_flow/core/widgets/micro_interactions/animated_number.dart';
import 'package:focus_flow/core/widgets/micro_interactions/save_status_button.dart';

void main() {
  group('AnimatedDelete', () {
    testWidgets('renders child initially and calls onDeleteConfirmed upon trigger',
        (tester) async {
      bool deleted = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedDelete.builder(
              onDeleteConfirmed: () async {
                deleted = true;
              },
              builder: (context, startDelete) => TextButton(
                onPressed: startDelete,
                child: const Text('Delete Me'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Delete Me'), findsOneWidget);
      expect(deleted, isFalse);

      await tester.tap(find.text('Delete Me'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(deleted, isTrue);
    });

    testWidgets('fires callback only once despite multiple triggers', (tester) async {
      int deleteCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedDelete.builder(
              onDeleteConfirmed: () async {
                deleteCount++;
              },
              builder: (context, startDelete) => Row(
                children: [
                  TextButton(
                    onPressed: startDelete,
                    child: const Text('Trigger 1'),
                  ),
                  TextButton(
                    onPressed: startDelete,
                    child: const Text('Trigger 2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Trigger 1'));
      await tester.tap(find.text('Trigger 2'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(deleteCount, equals(1));
    });
  });

  group('SaveStatusButton', () {
    testWidgets('transitions from IDLE to SAVING to SUCCESS and prevents double submit',
        (tester) async {
      int callCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaveStatusButton(
              label: 'Save Changes',
              onSubmit: () async {
                callCount++;
                await Future.delayed(const Duration(milliseconds: 100));
              },
            ),
          ),
        ),
      );

      expect(find.text('Save Changes'), findsOneWidget);

      await tester.tap(find.text('Save Changes'));
      await tester.pump();

      // In saving state
      expect(callCount, equals(1));

      // Attempt double tap
      await tester.tap(find.byType(SaveStatusButton));
      await tester.pump();
      expect(callCount, equals(1));

      // Advance through delayed future
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pump();

      // State is now success ("Saved")
      expect(find.text('✓ Saved'), findsOneWidget);

      // Auto-reset after hold
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(find.text('Save Changes'), findsOneWidget);
    });

    testWidgets('handles error gracefully without showing success', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SaveStatusButton(
              label: 'Save Profile',
              onSubmit: () async {
                throw Exception('Network error');
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Save Profile'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('✓ Saved'), findsNothing);
      expect(find.text('Save Profile'), findsOneWidget);
    });
  });

  group('AnimatedCheckbox', () {
    testWidgets('toggles and animates checkmark', (tester) async {
      bool checked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return AnimatedCheckbox(
                  value: checked,
                  onChanged: (val) {
                    setState(() => checked = val);
                  },
                );
              },
            ),
          ),
        ),
      );

      expect(checked, isFalse);
      await tester.tap(find.byType(AnimatedCheckbox));
      await tester.pump();
      expect(checked, isTrue);

      await tester.pump(const Duration(milliseconds: 250));
      await tester.pumpAndSettle();
    });
  });

  group('AnimatedNumber', () {
    testWidgets('animates value transition smoothly', (tester) async {
      double value = 100.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  children: [
                    AnimatedNumber(
                      value: value,
                      prefix: '\$',
                      fractionDigits: 2,
                    ),
                    TextButton(
                      onPressed: () => setState(() => value = 250.0),
                      child: const Text('Change'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('\$100.00'), findsOneWidget);

      await tester.tap(find.text('Change'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.text('\$250.00'), findsOneWidget);
    });
  });

  group('AnimatedCheckmark', () {
    testWidgets('renders CustomPaint with stroke drawing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedCheckmark(
              size: 24,
              color: Colors.green,
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedCheckmark), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
    });
  });

  group('AnimatedAddButton', () {
    testWidgets('cycles from plus to checkmark and back after successful action',
        (tester) async {
      int count = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnimatedAddButton(
              onPressed: () async {
                count++;
              },
            ),
          ),
        ),
      );

      expect(count, equals(0));
      await tester.tap(find.byType(AnimatedAddButton));
      await tester.pump();

      expect(count, equals(1));

      // Checkmark displayed during hold
      await tester.pump(const Duration(milliseconds: 100));
      // Reverts back after duration
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
    });
  });
}
