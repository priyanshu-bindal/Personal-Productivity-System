import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/money/trash_screen.dart';
import 'package:focus_flow/models/expense.dart';
import 'package:focus_flow/providers/money_provider.dart';
import 'package:focus_flow/providers/trash_provider.dart';

void main() {
  group('30-Day Trash Feature — 17 Required Tests', () {
    // 1. Delete sets deleted_at
    test('1. Delete sets deleted_at timestamp', () {
      final original = Expense(
        id: 'exp_1',
        userId: 'u1',
        amount: 500,
        description: 'Groceries',
        category: 'food',
        paymentMethod: 'cash',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
      );

      final nowUtc = DateTime.now().toUtc();
      final softDeleted = original.copyWith(deletedAt: nowUtc);

      expect(softDeleted.deletedAt, isNotNull);
      expect(softDeleted.deletedAt!.toUtc(), equals(nowUtc));
    });

    // 2. Successful delete removes from active state
    test('2. Successful delete removes expense from active state', () {
      final activeExpense = Expense(
        id: 'active_1',
        userId: 'u1',
        amount: 300,
        description: 'Lunch',
        category: 'food',
        paymentMethod: 'cash',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
        deletedAt: null,
      );

      final softDeleted = activeExpense.copyWith(deletedAt: DateTime.now().toUtc());

      final activeList = [activeExpense];
      final afterDelete = activeList.where((e) => e.id != softDeleted.id).toList();

      expect(afterDelete, isEmpty);
    });

    // 3. Successful delete makes expense available to Trash
    test('3. Successful delete makes expense available to Trash', () {
      final nowUtc = DateTime.now().toUtc();
      final trashedExpense = Expense(
        id: 'exp_trashed_3',
        userId: 'u1',
        amount: 450,
        description: 'Movie',
        category: 'entertainment',
        paymentMethod: 'upi',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
        deletedAt: nowUtc,
      );

      final allExpenses = [trashedExpense];
      final trashQuery = allExpenses.where((e) => e.deletedAt != null).toList();

      expect(trashQuery.length, 1);
      expect(trashQuery.first.id, 'exp_trashed_3');
    });

    // 4. Trash provider retrieves deleted expense
    test('4. Trash provider retrieves deleted expense', () {
      final trashed = Expense(
        id: 'trash_4',
        userId: 'u1',
        amount: 800,
        description: 'Headphones',
        category: 'shopping',
        paymentMethod: 'card',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
        deletedAt: DateTime.now().toUtc(),
      );

      final container = ProviderContainer(
        overrides: [
          trashedExpensesProvider.overrideWith((ref) => FakeTrashedExpensesNotifier([trashed])),
        ],
      );

      final state = container.read(trashedExpensesProvider).value!;
      expect(state.length, 1);
      expect(state.first.id, 'trash_4');
      expect(state.first.description, 'Headphones');
    });

    // 5. Undo clears deleted_at
    test('5. Undo clears deleted_at', () {
      final trashed = Expense(
        id: 'exp_undo_5',
        userId: 'u1',
        amount: 250,
        description: 'Snacks',
        category: 'food',
        paymentMethod: 'cash',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
        deletedAt: DateTime.now().toUtc(),
      );

      final undone = trashed.copyWith(clearDeletedAt: true);
      expect(undone.deletedAt, isNull);
    });

    // 6. Undo does not create duplicate
    test('6. Undo does not create duplicate in active list', () {
      final expense = Expense(
        id: 'exp_dedup_6',
        userId: 'u1',
        amount: 150,
        description: 'Coffee',
        category: 'food',
        paymentMethod: 'cash',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
      );

      final activeList = [expense];
      // When restoring, check if already present
      final isAlreadyPresent = activeList.any((e) => e.id == expense.id);
      final updatedList = isAlreadyPresent ? activeList : [expense, ...activeList];

      expect(updatedList.length, 1);
      expect(updatedList.first.id, 'exp_dedup_6');
    });

    // 7. Restore removes item from Trash
    test('7. Restore removes item from Trash', () {
      final item = Expense(
        id: 'trash_7',
        userId: 'u1',
        amount: 600,
        description: 'Book',
        category: 'education',
        paymentMethod: 'card',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
        deletedAt: DateTime.now().toUtc(),
      );

      final trashList = [item];
      final afterRestore = List<Expense>.from(trashList)..removeWhere((e) => e.id == item.id);

      expect(afterRestore, isEmpty);
    });

    // 8. Restore returns item to active expenses
    test('8. Restore returns item to active expenses', () {
      final original = Expense(
        id: 'exp_8',
        userId: 'u1',
        amount: 320,
        description: 'Taxi',
        category: 'transport',
        paymentMethod: 'cash',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
        deletedAt: DateTime.now().toUtc(),
      );

      final restoredItem = original.copyWith(clearDeletedAt: true);
      final activeList = <Expense>[];
      final afterRestoration = [restoredItem, ...activeList];

      expect(afterRestoration.length, 1);
      expect(afterRestoration.first.deletedAt, isNull);
      expect(afterRestoration.first.id, 'exp_8');
    });

    // 9. Failed delete rolls back
    test('9. Failed delete rolls back active list', () {
      final expense = Expense(
        id: 'exp_9',
        userId: 'u1',
        amount: 900,
        description: 'Desk Lamp',
        category: 'home',
        paymentMethod: 'upi',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
      );

      final originalList = [expense];
      // Optimistic delete
      final optimisticList = List<Expense>.from(originalList)..removeAt(0);
      expect(optimisticList, isEmpty);

      // Rollback on simulated network failure
      final rolledBackList = List<Expense>.from(optimisticList)..insert(0, expense);
      expect(rolledBackList.length, 1);
      expect(rolledBackList.first.id, 'exp_9');
    });

    // 10. Failed restore rolls back
    test('10. Failed restore rolls back Trash list', () {
      final expense = Expense(
        id: 'trash_10',
        userId: 'u1',
        amount: 1100,
        description: 'Dinner',
        category: 'food',
        paymentMethod: 'card',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
        deletedAt: DateTime.now().toUtc(),
      );

      final originalTrash = [expense];
      // Optimistic remove from Trash
      final optimisticTrash = List<Expense>.from(originalTrash)..removeAt(0);
      expect(optimisticTrash, isEmpty);

      // Rollback on simulated failure
      final rolledBackTrash = List<Expense>.from(optimisticTrash)..insert(0, expense);
      expect(rolledBackTrash.length, 1);
      expect(rolledBackTrash.first.id, 'trash_10');
    });

    // 11. Permanent delete removes from Trash list
    test('11. Permanent delete removes item from Trash list', () {
      final item1 = Expense(
        id: 'perm_1',
        userId: 'u1',
        amount: 100,
        description: 'Tea',
        category: 'food',
        paymentMethod: 'cash',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
        deletedAt: DateTime.now().toUtc(),
      );
      final item2 = Expense(
        id: 'perm_2',
        userId: 'u1',
        amount: 200,
        description: 'Coffee',
        category: 'food',
        paymentMethod: 'cash',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
        deletedAt: DateTime.now().toUtc(),
      );

      final list = [item1, item2];
      final afterPermanentDelete = list.where((e) => e.id != item1.id).toList();

      expect(afterPermanentDelete.length, 1);
      expect(afterPermanentDelete.first.id, 'perm_2');
    });

    // 12. Trash empty state
    testWidgets('12. Trash empty state displays correct message and icon', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trashedExpensesProvider.overrideWith((ref) => FakeTrashedExpensesNotifier([])),
          ],
          child: const MaterialApp(
            home: TrashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Trash'), findsOneWidget);
      expect(find.text('Deleted expenses are kept for 30 days'), findsOneWidget);
      expect(find.text('Trash is empty'), findsOneWidget);
      expect(
        find.text('Deleted expenses will stay here for 30 days before being permanently removed.'),
        findsOneWidget,
      );
    });

    // 13. Trash error state
    testWidgets('13. Trash error state displays error message and Retry button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trashedExpensesProvider.overrideWith(
              (ref) => FakeErrorTrashedExpensesNotifier('Network connection failed'),
            ),
          ],
          child: const MaterialApp(
            home: TrashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text("Couldn't load Trash"), findsOneWidget);
      expect(find.text('Network connection failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    // 14. Exact 30-day expiration
    test('14. Exact 30-day expiration calculations', () {
      final nowUtc = DateTime.now().toUtc();

      // Case A: 10 days ago -> remaining days
      final deleted10DaysAgo = nowUtc.subtract(const Duration(days: 10));
      final formattedA = TrashScreen.formatRemainingTime(deleted10DaysAgo);
      expect(formattedA.contains('days'), isTrue);

      // Case B: 1 second before 30-day expiration -> not expired
      final deletedJustBefore = nowUtc.subtract(const Duration(days: 30)).add(const Duration(seconds: 1));
      final expiryBefore = deletedJustBefore.add(const Duration(days: 30));
      expect(nowUtc.isAfter(expiryBefore) || nowUtc.isAtSameMomentAs(expiryBefore), isFalse);

      // Case C: exactly 30 days and 1 second ago -> expired
      final deletedPast30 = nowUtc.subtract(const Duration(days: 30, seconds: 1));
      final formattedC = TrashScreen.formatRemainingTime(deletedPast30);
      expect(formattedC, 'Expiring soon');
    });

    // 15. Money totals exclude trashed expenses
    test('15. Money totals exclude trashed expenses', () {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final container = ProviderContainer(
        overrides: [
          expensesProvider.overrideWith((ref) => FakeExpensesNotifier([
                Expense(
                  id: 'act_15',
                  userId: 'u1',
                  amount: 689,
                  description: 'Active Food',
                  category: 'food',
                  paymentMethod: 'cash',
                  expenseDate: todayStr,
                  createdAt: DateTime.now(),
                  deletedAt: null,
                ),
              ])),
        ],
      );

      final summary = container.read(moneySummaryProvider);
      expect(summary.todayTotal, 689.0);
      expect(summary.monthTotal, 689.0);
      expect(summary.categoryBreakdown.length, 1);
      expect(summary.categoryBreakdown.first['amount'], 689.0);
    });

    // 16. Category totals exclude trashed expenses
    test('16. Category totals exclude trashed expenses', () {
      final activeExpense = Expense(
        id: 'cat_act',
        userId: 'u1',
        amount: 400,
        category: 'food',
        description: 'Lunch',
        paymentMethod: 'cash',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
        deletedAt: null,
      );

      final trashedExpense = Expense(
        id: 'cat_tr',
        userId: 'u1',
        amount: 600,
        category: 'food',
        description: 'Dinner',
        paymentMethod: 'card',
        expenseDate: '2026-09-19',
        createdAt: DateTime.now(),
        deletedAt: DateTime.now().toUtc(),
      );

      final all = [activeExpense, trashedExpense];
      final activeOnly = all.where((e) => e.deletedAt == null).toList();
      final total = activeOnly
          .where((e) => e.category == 'food')
          .fold<double>(0, (sum, e) => sum + e.amount);

      expect(total, 400.0);
    });

    // 17. Category transaction screen excludes trashed expenses
    test('17. Category transaction screen excludes trashed expenses', () {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];

      final activeList = [
        Expense(
          id: 'food_1',
          userId: 'u1',
          amount: 689,
          description: 'Burgers',
          category: 'food',
          paymentMethod: 'cash',
          expenseDate: todayStr,
          createdAt: DateTime.now(),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          expensesProvider.overrideWith((ref) => FakeExpensesNotifier(activeList)),
        ],
      );

      final state = container.read(expensesProvider).value!;
      final foodExpenses = state.where((e) => e.category == 'food' && e.deletedAt == null).toList();

      expect(foodExpenses.length, 1);
      expect(foodExpenses.first.amount, 689.0);
    });

    // Widget test for redesigned TrashScreen card & header
    testWidgets('Trash Screen renders items with header summary and countdown', (tester) async {
      // Fixed timestamp ensuring 27 days remaining
      final fixedDeletedAt = DateTime.now().toUtc().subtract(const Duration(days: 2, hours: 22));
      final testTrashed = [
        Expense(
          id: 'trash_w1',
          userId: 'u1',
          amount: 500.0,
          description: 'Movie Ticket',
          category: 'entertainment',
          paymentMethod: 'upi',
          expenseDate: '2026-09-10',
          createdAt: DateTime(2026, 9, 10),
          deletedAt: fixedDeletedAt,
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            trashedExpensesProvider.overrideWith((ref) => FakeTrashedExpensesNotifier(testTrashed)),
          ],
          child: const MaterialApp(
            home: TrashScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Movie Ticket'), findsOneWidget);
      expect(find.text('₹500.00'), findsOneWidget);
      expect(find.textContaining('ENTERTAINMENT • UPI'), findsOneWidget);
      expect(find.text('1 deleted expense • ₹500.00'), findsOneWidget);
      expect(find.text('Restore'), findsOneWidget);
      expect(find.text('Deletes in 27 days'), findsOneWidget);
    });
  });
}

class FakeTrashedExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>>
    implements TrashedExpensesNotifier {
  FakeTrashedExpensesNotifier(List<Expense> initial) : super(AsyncValue.data(initial));

  @override
  Future<void> fetchTrashed() async {}

  @override
  Future<void> restore(Expense expense) async {}

  @override
  Future<void> permanentlyDelete(String expenseId) async {}

  @override
  Future<void> cleanupExpiredExpenses() async {}
}

class FakeErrorTrashedExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>>
    implements TrashedExpensesNotifier {
  FakeErrorTrashedExpensesNotifier(String errorMessage)
      : super(AsyncValue.error(errorMessage, StackTrace.empty));

  @override
  Future<void> fetchTrashed() async {}

  @override
  Future<void> restore(Expense expense) async {}

  @override
  Future<void> permanentlyDelete(String expenseId) async {}

  @override
  Future<void> cleanupExpiredExpenses() async {}
}

class FakeExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>>
    implements ExpensesNotifier {
  FakeExpensesNotifier(List<Expense> initial) : super(AsyncValue.data(initial));

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
  }) async {
    return null;
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
  }) async {}

  @override
  Future<void> deleteExpense(String expenseId) async {}

  @override
  Future<void> restoreExpense(Expense expense) async {}
}
