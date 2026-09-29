import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/money/models/expense_filter_state.dart';
import 'package:focus_flow/features/money/money_screen.dart';
import 'package:focus_flow/features/money/widgets/expense_filter_bar.dart';
import 'package:focus_flow/features/money/widgets/money_pdf_export_dialog.dart';
import 'package:focus_flow/models/expense.dart';
import 'package:focus_flow/providers/money_provider.dart';
import 'package:intl/intl.dart';

void main() {
  final now = DateTime.now();
  final todayStr = DateFormat('yyyy-MM-dd').format(now);
  final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));
  final lastMonthDate = DateTime(now.year, now.month - 1, 15);
  final lastMonthStr = DateFormat('yyyy-MM-dd').format(lastMonthDate);

  final sampleExpenses = [
    Expense(
      id: 'e1',
      userId: 'u1',
      amount: 250.0,
      description: 'Morning Coffee',
      category: 'food',
      paymentMethod: 'upi',
      expenseDate: todayStr,
      createdAt: now,
      note: 'Espresso with almond milk',
    ),
    Expense(
      id: 'e2',
      userId: 'u1',
      amount: 1200.0,
      description: 'Supermarket Groceries',
      category: 'food',
      paymentMethod: 'credit_card',
      expenseDate: yesterdayStr,
      createdAt: now.subtract(const Duration(days: 1)),
    ),
    Expense(
      id: 'e3',
      userId: 'u1',
      amount: 3500.0,
      description: 'Flight Ticket',
      category: 'travel',
      paymentMethod: 'bank_transfer',
      expenseDate: lastMonthStr,
      createdAt: lastMonthDate,
      note: 'Vacation flight',
    ),
  ];

  group('1. Quick Filters - ExpenseFilterState Unit Tests', () {
    test('Default filter state has 0 active filters', () {
      const state = ExpenseFilterState();
      expect(state.activeFilterCount, 0);
      expect(state.hasActiveFilters, isFalse);
      expect(state.dateFilter, QuickDateFilter.all);
      expect(state.category, isNull);
      expect(state.paymentMethod, isNull);
      expect(state.amountRange, AmountFilterRange.all);
    });

    test('Filters by Date: Today', () {
      const state = ExpenseFilterState(dateFilter: QuickDateFilter.today);
      expect(state.activeFilterCount, 1);
      final filtered = state.apply(sampleExpenses);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'e1');
    });

    test('Filters by Category: Food', () {
      const state = ExpenseFilterState(category: 'food');
      expect(state.activeFilterCount, 1);
      final filtered = state.apply(sampleExpenses);
      expect(filtered.length, 2);
      expect(filtered.every((e) => e.category == 'food'), isTrue);
    });

    test('Filters by Payment Method: Credit Card', () {
      const state = ExpenseFilterState(paymentMethod: 'credit_card');
      expect(state.activeFilterCount, 1);
      final filtered = state.apply(sampleExpenses);
      expect(filtered.length, 1);
      expect(filtered.first.id, 'e2');
    });

    test('Filters by Amount Range: Under 500, 500-2000, Above 2000', () {
      const under500 = ExpenseFilterState(amountRange: AmountFilterRange.under500);
      expect(under500.apply(sampleExpenses).length, 1); // e1: 250

      const between = ExpenseFilterState(amountRange: AmountFilterRange.between500And2000);
      expect(between.apply(sampleExpenses).length, 1); // e2: 1200

      const above = ExpenseFilterState(amountRange: AmountFilterRange.above2000);
      expect(above.apply(sampleExpenses).length, 1); // e3: 3500
    });

    test('Custom Date Range filtering works accurately', () {
      final range = DateTimeRange(
        start: now.subtract(const Duration(days: 2)),
        end: now,
      );
      final state = ExpenseFilterState(
        dateFilter: QuickDateFilter.customRange,
        customDateRange: range,
      );
      final filtered = state.apply(sampleExpenses);
      // e1 (today) and e2 (yesterday) are within 2 days, e3 (last month) is not
      expect(filtered.length, 2);
      expect(filtered.any((e) => e.id == 'e3'), isFalse);
    });

    test('reset() restores clean state', () {
      final state = ExpenseFilterState(
        dateFilter: QuickDateFilter.thisWeek,
        category: 'travel',
        amountRange: AmountFilterRange.above2000,
      );
      expect(state.activeFilterCount, 3);
      final resetState = state.reset();
      expect(resetState.activeFilterCount, 0);
      expect(resetState.hasActiveFilters, isFalse);
    });
  });

  group('2. Quick Filters UI & Contextual Empty States', () {
    testWidgets('ExpenseFilterBar renders quick filter chips and clear all button', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expenseFilterStateProvider.overrideWith(
              (ref) => const ExpenseFilterState(dateFilter: QuickDateFilter.today),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: ExpenseFilterBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('All'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This Week'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);
      expect(find.text('1 filter active'), findsOneWidget);
      expect(find.text('Clear All'), findsOneWidget);
    });

    testWidgets('Empty State Situation 1: No expenses yet when list is empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expensesProvider.overrideWith(
              (ref) => FakeExpensesNotifier(const AsyncValue.data([])),
            ),
            expenseFilterStateProvider.overrideWith(
              (ref) => const ExpenseFilterState(),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MoneyScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Expenses tab
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();

      expect(find.text('No expenses yet'), findsOneWidget);
      expect(
        find.text('Start tracking your spending to understand where your money goes.'),
        findsOneWidget,
      );
      expect(find.text('Add Expense'), findsWidgets);
    });

    testWidgets('Empty State Situation 2: No matching expenses when search/filter active', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expensesProvider.overrideWith(
              (ref) => FakeExpensesNotifier(AsyncValue.data(sampleExpenses)),
            ),
            expenseSearchProvider.overrideWith((ref) => 'NonExistentXYZ'),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MoneyScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Switch to Expenses tab
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();

      expect(find.text('No matching expenses'), findsOneWidget);
      expect(
        find.text('Try changing your filters or date range.'),
        findsOneWidget,
      );
      expect(find.text('Clear Filters'), findsOneWidget);
    });
  });

  group('3. Money-Specific PDF Export Dialog Tests', () {
    testWidgets('Renders MoneyPdfExportDialog with correct period and count', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));

      const filter = ExpenseFilterState(dateFilter: QuickDateFilter.today);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MoneyPdfExportDialog(
              expenses: [sampleExpenses.first],
              filterState: filter,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Export Financial Report'), findsOneWidget);
      expect(find.text('MATCHING TRANSACTIONS'), findsOneWidget);
      expect(find.text('1 expenses'), findsOneWidget);
      expect(find.text('Generate & Share PDF'), findsOneWidget);
    });
  });
}

class FakeExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>>
    implements ExpensesNotifier {
  FakeExpensesNotifier(super.initialState);

  @override
  Future<void> fetchExpenses() async {}

  @override
  Future<Expense?> addExpense({
    required double amount,
    required String description,
    required String category,
    required String paymentMethod,
    required DateTime date,
    String? note,
  }) async => null;

  @override
  Future<void> updateExpense({
    required String expenseId,
    required double amount,
    required String description,
    required String category,
    required String paymentMethod,
    required DateTime date,
    String? note,
  }) async {}

  @override
  Future<void> deleteExpense(String expenseId) async {}

  @override
  Future<void> restoreExpense(Expense expense) async {}
}
