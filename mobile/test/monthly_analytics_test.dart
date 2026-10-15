import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/money/models/expense_filter_state.dart';
import 'package:focus_flow/models/expense.dart';
import 'package:focus_flow/providers/money_provider.dart';

void main() {
  group('Monthly Analytics & Spending Calculations', () {
    final now = DateTime.now();

    final testExpenses = [
      // Current Month Expenses
      Expense(
        id: 'e1',
        userId: 'u1',
        amount: 1500.0,
        category: 'food',
        expenseDate: DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10),
        paymentMethod: 'upi',
        description: 'Groceries',
        createdAt: DateTime(now.year, now.month, 1),
      ),
      Expense(
        id: 'e2',
        userId: 'u1',
        amount: 2500.0,
        category: 'shopping',
        expenseDate: DateTime(now.year, now.month, 2).toIso8601String().substring(0, 10),
        paymentMethod: 'credit_card',
        description: 'New shoes',
        createdAt: DateTime(now.year, now.month, 2),
      ),
      Expense(
        id: 'e3',
        userId: 'u1',
        amount: 500.0,
        category: 'food',
        expenseDate: DateTime(now.year, now.month, 3).toIso8601String().substring(0, 10),
        paymentMethod: 'cash',
        description: 'Lunch',
        createdAt: DateTime(now.year, now.month, 3),
      ),
      // Soft-deleted expense (should be ignored)
      Expense(
        id: 'e_del',
        userId: 'u1',
        amount: 9999.0,
        category: 'food',
        expenseDate: DateTime(now.year, now.month, 1).toIso8601String().substring(0, 10),
        paymentMethod: 'upi',
        description: 'Cancelled transaction',
        createdAt: DateTime(now.year, now.month, 1),
        deletedAt: DateTime(now.year, now.month, 1),
      ),
      // Previous Month Expenses
      Expense(
        id: 'e_prev1',
        userId: 'u1',
        amount: 2000.0,
        category: 'food',
        expenseDate: DateTime(now.year, now.month - 1, 10).toIso8601String().substring(0, 10),
        paymentMethod: 'upi',
        description: 'Dinner with friends',
        createdAt: DateTime(now.year, now.month - 1, 10),
      ),
      Expense(
        id: 'e_prev2',
        userId: 'u1',
        amount: 1000.0,
        category: 'bills',
        expenseDate: DateTime(now.year, now.month - 1, 15).toIso8601String().substring(0, 10),
        paymentMethod: 'bank_transfer',
        description: 'Internet bill',
        createdAt: DateTime(now.year, now.month - 1, 15),
      ),
    ];

    test('Selected month defaults to start of current month', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final selectedMonth = container.read(selectedMoneyMonthProvider);
      expect(selectedMonth.year, equals(now.year));
      expect(selectedMonth.month, equals(now.month));
      expect(selectedMonth.day, equals(1));
    });

    test('Current month analytics computes accurate total, average, and categories', () {
      final container = ProviderContainer(
        overrides: [
          expensesProvider.overrideWith(
            (ref) => FakeExpensesNotifier(AsyncValue.data(testExpenses)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final analytics = container.read(monthlyAnalyticsProvider);

      expect(analytics.isCurrentMonth, isTrue);
      expect(analytics.isFutureMonth, isFalse);
      // Total = 1500 + 2500 + 500 = 4500 (e_del excluded)
      expect(analytics.totalExpense, equals(4500.0));
      expect(analytics.transactionCount, equals(3));

      // Elapsed days in current month equals now.day
      expect(analytics.elapsedDays, equals(now.day));
      expect(analytics.avgDailySpending, equals(4500.0 / now.day));

      // Top category is shopping (2500) or food (2000)
      expect(analytics.highestCategory.toLowerCase(), equals('shopping'));
      expect(analytics.highestCategoryAmount, equals(2500.0));

      // Category breakdown percentage check
      expect(analytics.categoryBreakdowns.length, equals(2));
      final topCat = analytics.categoryBreakdowns.first;
      expect(topCat.category.toLowerCase(), equals('shopping'));
      expect(topCat.amount, equals(2500.0));
      expect(topCat.percentage, closeTo((2500.0 / 4500.0) * 100, 0.01));

      final secondCat = analytics.categoryBreakdowns[1];
      expect(secondCat.category.toLowerCase(), equals('food'));
      expect(secondCat.amount, equals(2000.0));
      expect(secondCat.percentage, closeTo((2000.0 / 4500.0) * 100, 0.01));

      // Sum of percentages must equal 100%
      expect(topCat.percentage + secondCat.percentage, closeTo(100.0, 0.01));
    });

    test('Month-over-month comparison math and zero division handling', () {
      final container = ProviderContainer(
        overrides: [
          expensesProvider.overrideWith(
            (ref) => FakeExpensesNotifier(AsyncValue.data(testExpenses)),
          ),
        ],
      );
      addTearDown(container.dispose);

      final analytics = container.read(monthlyAnalyticsProvider);

      // Current month: 4500, Previous month: 3000
      expect(analytics.previousMonthTotal, equals(3000.0));
      expect(analytics.hasPreviousMonthData, isTrue);
      expect(analytics.differenceFromPreviousMonth, equals(1500.0));
      // Percentage change: ((4500 - 3000) / 3000) * 100 = 50.0%
      expect(analytics.percentageChangeFromPreviousMonth, closeTo(50.0, 0.01));
    });

    test('Zero division guard when previous month has zero expenses', () {
      // Only current month expenses
      final container = ProviderContainer(
        overrides: [
          expensesProvider.overrideWith(
            (ref) => FakeExpensesNotifier(
              AsyncValue.data([testExpenses[0]]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final analytics = container.read(monthlyAnalyticsProvider);
      expect(analytics.previousMonthTotal, equals(0.0));
      expect(analytics.hasPreviousMonthData, isFalse);
      // Division by zero is avoided and produces 100.0% increase safely
      expect(analytics.percentageChangeFromPreviousMonth, equals(100.0));
    });

    test('Historical month uses full calendar days for daily average', () {
      final container = ProviderContainer(
        overrides: [
          expensesProvider.overrideWith(
            (ref) => FakeExpensesNotifier(AsyncValue.data(testExpenses)),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Switch to previous month
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      container.read(selectedMoneyMonthProvider.notifier).state = prevMonth;

      final analytics = container.read(monthlyAnalyticsProvider);
      expect(analytics.isCurrentMonth, isFalse);
      expect(analytics.isFutureMonth, isFalse);
      expect(analytics.totalExpense, equals(3000.0));
      expect(analytics.transactionCount, equals(2));

      final daysInPrevMonth = DateTime(prevMonth.year, prevMonth.month + 1, 0).day;
      expect(analytics.daysInMonth, equals(daysInPrevMonth));
      // In historical month, daily average divides by total calendar days of that month
      expect(analytics.avgDailySpending, equals(3000.0 / daysInPrevMonth));
    });

    test('Future month has 0 elapsed days and 0 daily average', () {
      final container = ProviderContainer(
        overrides: [
          expensesProvider.overrideWith(
            (ref) => FakeExpensesNotifier(AsyncValue.data(testExpenses)),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Switch to next year
      final futureMonth = DateTime(now.year + 1, 1, 1);
      container.read(selectedMoneyMonthProvider.notifier).state = futureMonth;

      final analytics = container.read(monthlyAnalyticsProvider);
      expect(analytics.isCurrentMonth, isFalse);
      expect(analytics.isFutureMonth, isTrue);
      expect(analytics.totalExpense, equals(0.0));
      expect(analytics.elapsedDays, equals(0));
      expect(analytics.avgDailySpending, equals(0.0));
      expect(analytics.categoryBreakdowns, isEmpty);
    });

    test('ExpenseFilterState with QuickDateFilter.selectedMonth correctly filters expenses', () {
      final prevMonth = DateTime(now.year, now.month - 1, 1);
      final filter = ExpenseFilterState(
        dateFilter: QuickDateFilter.selectedMonth,
        selectedMonthDate: prevMonth,
      );

      final filtered = filter.apply(testExpenses);
      // testExpenses has 2 previous month non-deleted expenses (e_prev1, e_prev2)
      expect(filtered.length, equals(2));
      expect(filtered.every((e) => e.expenseDate.startsWith(
            '${prevMonth.year}-${prevMonth.month.toString().padLeft(2, '0')}',
          )), isTrue);
    });
  });
}

class FakeExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>>
    implements ExpensesNotifier {
  FakeExpensesNotifier(super.state);

  @override
  Future<void> fetchExpenses({bool forceRefresh = false}) async {}

  @override
  Future<Expense> addExpense({
    required double amount,
    required String description,
    required String category,
    required String paymentMethod,
    required DateTime date,
    String? note,
  }) async {
    throw UnimplementedError();
  }

  Future<void> editExpense({
    required String id,
    required double amount,
    required String description,
    required String category,
    required String paymentMethod,
    required DateTime date,
    String? note,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateExpense({
    required String expenseId,
    required double amount,
    required String description,
    required String category,
    required String paymentMethod,
    required DateTime date,
    String? note,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteExpense(String id) async {}

  @override
  Future<void> restoreExpense(Expense expense) async {}

  Future<void> permanentlyDeleteExpense(String id) async {}
}
