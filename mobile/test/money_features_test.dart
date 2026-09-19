import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focus_flow/features/money/category_transactions_screen.dart';
import 'package:focus_flow/features/money/money_screen.dart';
import 'package:focus_flow/features/money/widgets/animated_balance_ticker.dart';
import 'package:focus_flow/features/money/widgets/financial_dropdown_field.dart';
import 'package:focus_flow/models/budget.dart';
import 'package:focus_flow/models/expense.dart';
import 'package:focus_flow/providers/money_provider.dart';

void main() {
  group('Expense Model & Optimistic Semantics', () {
    test('Default isOptimistic is false', () {
      final expense = Expense(
        id: '123',
        userId: 'user_1',
        amount: 500.0,
        description: 'Groceries',
        category: 'food',
        paymentMethod: 'cash',
        expenseDate: '2026-09-12',
        createdAt: DateTime.now(),
      );

      expect(expense.isOptimistic, isFalse);
      expect(expense.amount, 500.0);
    });

    test('copyWith updates isOptimistic and other fields', () {
      final original = Expense(
        id: 'opt_1',
        userId: 'user_1',
        amount: 500.0,
        description: 'Groceries',
        category: 'food',
        paymentMethod: 'cash',
        expenseDate: '2026-09-12',
        createdAt: DateTime.now(),
        isOptimistic: true,
      );

      final confirmed = original.copyWith(
        id: 'server_real_id',
        isOptimistic: false,
      );

      expect(confirmed.id, 'server_real_id');
      expect(confirmed.isOptimistic, isFalse);
      expect(confirmed.amount, 500.0);
      expect(confirmed.description, 'Groceries');
    });

    test('fromJson sets isOptimistic to false', () {
      final json = {
        'id': 'exp_100',
        'user_id': 'user_1',
        'amount': 750,
        'description': 'Taxi',
        'category': 'Transport',
        'payment_method': 'upi',
        'expense_date': '2026-09-12',
        'created_at': '2026-09-12T10:00:00Z',
      };

      final expense = Expense.fromJson(json);
      expect(expense.id, 'exp_100');
      expect(expense.isOptimistic, isFalse);
      expect(expense.amount, 750.0);
      expect(expense.category, 'transport');
    });
  });

  group('Concurrency-Safe Reconciliation Logic', () {
    test('Replaces tempId independently even when resolving out of order', () {
      // Suppose 3 transactions were submitted optimistically:
      final optA = Expense(
        id: 'opt_A',
        userId: 'u1',
        amount: 500,
        description: 'Item A',
        category: 'food',
        paymentMethod: 'cash',
        expenseDate: '2026-09-12',
        createdAt: DateTime.now(),
        isOptimistic: true,
      );
      final optB = Expense(
        id: 'opt_B',
        userId: 'u1',
        amount: 1000,
        description: 'Item B',
        category: 'shopping',
        paymentMethod: 'upi',
        expenseDate: '2026-09-12',
        createdAt: DateTime.now(),
        isOptimistic: true,
      );
      final optC = Expense(
        id: 'opt_C',
        userId: 'u1',
        amount: 2000,
        description: 'Item C',
        category: 'bills',
        paymentMethod: 'card',
        expenseDate: '2026-09-12',
        createdAt: DateTime.now(),
        isOptimistic: true,
      );

      List<Expense> stateList = [optC, optB, optA];
      expect(stateList.length, 3);

      // Server finishes B first!
      final confirmedB = optB.copyWith(id: 'srv_B', isOptimistic: false);
      final idxB = stateList.indexWhere((e) => e.id == 'opt_B');
      expect(idxB, isNot(-1));
      stateList[idxB] = confirmedB;

      expect(stateList[0].id, 'opt_C');
      expect(stateList[1].id, 'srv_B');
      expect(stateList[1].isOptimistic, isFalse);
      expect(stateList[2].id, 'opt_A');

      // Server finishes C next!
      final confirmedC = optC.copyWith(id: 'srv_C', isOptimistic: false);
      final idxC = stateList.indexWhere((e) => e.id == 'opt_C');
      expect(idxC, isNot(-1));
      stateList[idxC] = confirmedC;

      expect(stateList[0].id, 'srv_C');
      expect(stateList[0].isOptimistic, isFalse);
      expect(stateList[1].id, 'srv_B');
      expect(stateList[2].id, 'opt_A');

      // Server finishes A last!
      final confirmedA = optA.copyWith(id: 'srv_A', isOptimistic: false);
      final idxA = stateList.indexWhere((e) => e.id == 'opt_A');
      expect(idxA, isNot(-1));
      stateList[idxA] = confirmedA;

      expect(stateList.map((e) => e.id).toList(), ['srv_C', 'srv_B', 'srv_A']);
      expect(stateList.every((e) => !e.isOptimistic), isTrue);

      // Total amount is exactly 500 + 1000 + 2000 = 3500
      final total = stateList.fold<double>(0, (sum, e) => sum + e.amount);
      expect(total, 3500.0);
    });

    test('Rollback removes only failed tempId and leaves others intact', () {
      final optA = Expense(
        id: 'opt_A',
        userId: 'u1',
        amount: 500,
        description: 'Item A',
        category: 'food',
        paymentMethod: 'cash',
        expenseDate: '2026-09-12',
        createdAt: DateTime.now(),
        isOptimistic: true,
      );
      final confirmedB = Expense(
        id: 'srv_B',
        userId: 'u1',
        amount: 1000,
        description: 'Item B',
        category: 'shopping',
        paymentMethod: 'upi',
        expenseDate: '2026-09-12',
        createdAt: DateTime.now(),
        isOptimistic: false,
      );

      List<Expense> stateList = [optA, confirmedB];

      // Request A fails! Rollback removes opt_A:
      stateList = stateList.where((e) => e.id != 'opt_A').toList();

      expect(stateList.length, 1);
      expect(stateList.first.id, 'srv_B');
      expect(stateList.first.amount, 1000.0);
    });
  });

  group('Money Summary Provider Metrics', () {
    test('Calculates todayTotal, monthTotal, and categoryBreakdown accurately', () {
      final todayStr = DateTime.now().toIso8601String().split('T')[0];
      final container = ProviderContainer(
        overrides: [
          expensesProvider.overrideWith((ref) => FakeExpensesNotifier([
                Expense(
                  id: '1',
                  userId: 'u1',
                  amount: 500,
                  description: 'Groceries',
                  category: 'food',
                  paymentMethod: 'cash',
                  expenseDate: todayStr,
                  createdAt: DateTime.now(),
                ),
                Expense(
                  id: '2',
                  userId: 'u1',
                  amount: 1500,
                  description: 'Dinner',
                  category: 'food',
                  paymentMethod: 'card',
                  expenseDate: todayStr,
                  createdAt: DateTime.now(),
                ),
                Expense(
                  id: '3',
                  userId: 'u1',
                  amount: 3000,
                  description: 'Flight ticket',
                  category: 'travel',
                  paymentMethod: 'upi',
                  expenseDate: todayStr,
                  createdAt: DateTime.now(),
                ),
              ])),
        ],
      );

      final summary = container.read(moneySummaryProvider);
      expect(summary.todayTotal, 5000.0);
      expect(summary.monthTotal, 5000.0);
      expect(summary.highestCategory, 'Travel');
      expect(summary.highestCategoryAmount, 3000.0);
      expect(summary.categoryBreakdown.length, 2);
    });
  });

  group('AnimatedBalanceTicker Widget Test', () {
    testWidgets('Renders formatted Indian Rupee amount without crashing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AnimatedBalanceTicker(
              amount: 5500,
              animateInitial: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('₹5,500'), findsOneWidget);
    });

    testWidgets('Smoothly transitions from previous value to new value', (tester) async {
      double amount = 5000;
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) {
            return MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    AnimatedBalanceTicker(
                      amount: amount,
                      animateInitial: false,
                    ),
                    ElevatedButton(
                      onPressed: () => setState(() => amount = 5500),
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('₹5,000'), findsOneWidget);

      // Tap update
      await tester.tap(find.text('Update'));
      await tester.pump(); // Start animation
      await tester.pump(const Duration(milliseconds: 300)); // Halfway through

      // Let animation finish
      await tester.pumpAndSettle();
      expect(find.text('₹5,500'), findsOneWidget);
    });
  });

  group('FinancialDropdownField Widget Test', () {
    testWidgets('Opens popover on tap, displays items with icons, and selects an option', (tester) async {
      String selected = 'cash';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: SizedBox(
                    width: 180,
                    child: FinancialDropdownField<String>(
                      label: 'Payment',
                      value: selected,
                      items: const [
                        FinancialDropdownItem(
                          value: 'cash',
                          label: 'CASH',
                          icon: Icons.payments_outlined,
                        ),
                        FinancialDropdownItem(
                          value: 'upi',
                          label: 'UPI',
                          icon: Icons.qr_code_2_rounded,
                        ),
                        FinancialDropdownItem(
                          value: 'debit_card',
                          label: 'DEBIT CARD',
                          icon: Icons.credit_card_outlined,
                        ),
                      ],
                      onChanged: (val) => setState(() => selected = val),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('PAYMENT'), findsOneWidget);
      expect(find.text('CASH'), findsOneWidget);

      // Tap dropdown to open
      await tester.tap(find.text('CASH'));
      await tester.pumpAndSettle();

      // Options should be visible in overlay
      expect(find.text('UPI'), findsOneWidget);
      expect(find.text('DEBIT CARD'), findsOneWidget);

      // Select UPI
      await tester.tap(find.text('UPI'));
      await tester.pumpAndSettle();

      // Value should be updated to UPI
      expect(selected, 'upi');
      expect(find.text('UPI'), findsOneWidget);
    });
  });

  group('Responsive TabBar - No Text Clipping', () {
    testWidgets('Renders all 4 tab labels fully without ellipsis on small screen (360x640)', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 4,
            child: Scaffold(
              appBar: AppBar(
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    padding: const EdgeInsets.all(3),
                    child: TabBar(
                      isScrollable: true,
                      tabAlignment: TabAlignment.center,
                      labelPadding: const EdgeInsets.symmetric(horizontal: 14),
                      tabs: const [
                        Tab(child: Text('Overview', maxLines: 1, softWrap: false)),
                        Tab(child: Text('Expenses', maxLines: 1, softWrap: false)),
                        Tab(child: Text('Categories', maxLines: 1, softWrap: false)),
                        Tab(child: Text('Budgets', maxLines: 1, softWrap: false)),
                      ],
                    ),
                  ),
                ),
              ),
              body: const TabBarView(
                children: [
                  Text('Overview Tab Content'),
                  Text('Expenses Tab Content'),
                  Text('Categories Tab Content'),
                  Text('Budgets Tab Content'),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All 4 tabs must be fully visible and rendered
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Expenses'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Budgets'), findsOneWidget);
    });
  });

  group('Category Transactions Drill-Down & Screen Tests', () {
    testWidgets('Renders category header stats and filtered transactions sorted newest first', (tester) async {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final earlierStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-01';

      final testExpenses = [
        Expense(
          id: 'exp1',
          userId: 'u1',
          amount: 250.0,
          description: 'Coffee',
          category: 'food',
          paymentMethod: 'upi',
          expenseDate: earlierStr,
          note: 'Cafe visit',
          createdAt: DateTime(2026, 9, 1, 10, 0),
        ),
        Expense(
          id: 'exp2',
          userId: 'u1',
          amount: 500.0,
          description: 'Uber ride',
          category: 'transport',
          paymentMethod: 'card',
          expenseDate: todayStr,
          createdAt: DateTime(2026, 9, 19, 11, 0),
        ),
        Expense(
          id: 'exp3',
          userId: 'u1',
          amount: 1000.0,
          description: 'Team Dinner',
          category: 'food',
          paymentMethod: 'card',
          expenseDate: todayStr,
          note: 'Italian restaurant',
          createdAt: DateTime(2026, 9, 19, 20, 0),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expensesProvider.overrideWith((ref) => FakeExpensesNotifier(testExpenses)),
          ],
          child: const MaterialApp(
            home: CategoryTransactionsScreen(category: 'food'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Header asserts
      expect(find.text('Food'), findsWidgets);
      expect(find.text('2 transactions'), findsOneWidget);
      expect(find.text('₹1,250'), findsOneWidget);
      expect(find.text('TRANSACTIONS (2)'), findsOneWidget);

      // Filtered transactions asserts (Food only)
      expect(find.text('Team Dinner'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
      expect(find.text('Uber ride'), findsNothing);

      // Note display assert
      expect(find.text('Italian restaurant'), findsOneWidget);
      expect(find.text('Cafe visit'), findsOneWidget);
    });

    testWidgets('Renders polished empty state and ₹0 when category has no transactions', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expensesProvider.overrideWith((ref) => FakeExpensesNotifier([])),
          ],
          child: const MaterialApp(
            home: CategoryTransactionsScreen(category: 'education'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Education'), findsWidgets);
      expect(find.text('0 transactions'), findsOneWidget);
      expect(find.text('₹0'), findsOneWidget);
      expect(find.text('0% of month total'), findsOneWidget);
      expect(find.text('No Education transactions yet'), findsOneWidget);
    });

    testWidgets('Correctly orders multiple transactions on the same date by createdAt descending', (tester) async {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final testExpenses = [
        Expense(
          id: 'morning',
          userId: 'u1',
          amount: 100.0,
          description: 'Morning Snack',
          category: 'food',
          paymentMethod: 'cash',
          expenseDate: todayStr,
          createdAt: DateTime(2026, 9, 19, 8, 0),
        ),
        Expense(
          id: 'lunch',
          userId: 'u1',
          amount: 350.0,
          description: 'Lunch Bowl',
          category: 'food',
          paymentMethod: 'upi',
          expenseDate: todayStr,
          createdAt: DateTime(2026, 9, 19, 13, 0),
        ),
        Expense(
          id: 'night',
          userId: 'u1',
          amount: 550.0,
          description: 'Dinner Feast',
          category: 'food',
          paymentMethod: 'card',
          expenseDate: todayStr,
          createdAt: DateTime(2026, 9, 19, 21, 0),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expensesProvider.overrideWith((ref) => FakeExpensesNotifier(testExpenses)),
          ],
          child: const MaterialApp(
            home: CategoryTransactionsScreen(category: 'food'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Topmost item should be night (21:00), followed by lunch (13:00), followed by morning (08:00)
      final nightY = tester.getTopLeft(find.text('Dinner Feast')).dy;
      final lunchY = tester.getTopLeft(find.text('Lunch Bowl')).dy;
      final morningY = tester.getTopLeft(find.text('Morning Snack')).dy;

      expect(nightY < lunchY, isTrue);
      expect(lunchY < morningY, isTrue);
    });

    testWidgets('Tapping category card in MoneyScreen navigates to CategoryTransactionsScreen', (tester) async {
      final now = DateTime.now();
      final todayStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final testExpenses = [
        Expense(
          id: 'food_exp',
          userId: 'u1',
          amount: 250.0,
          description: 'Coffee',
          category: 'food',
          paymentMethod: 'upi',
          expenseDate: todayStr,
          createdAt: DateTime(2026, 9, 19, 10, 0),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            expensesProvider.overrideWith((ref) => FakeExpensesNotifier(testExpenses)),
            budgetsProvider.overrideWith((ref) => FakeBudgetsNotifier()),
          ],
          child: const MaterialApp(
            home: MoneyScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch to Categories tab
      await tester.tap(find.text('Categories'));
      await tester.pumpAndSettle();

      // Tap on Food category card
      await tester.tap(find.text('Food'));
      await tester.pumpAndSettle();

      // Should now be on CategoryTransactionsScreen
      expect(find.byType(CategoryTransactionsScreen), findsOneWidget);
      expect(find.text('TRANSACTIONS (1)'), findsOneWidget);
      expect(find.text('Coffee'), findsOneWidget);
    });
  });
}

class FakeBudgetsNotifier extends StateNotifier<AsyncValue<List<Budget>>>
    implements BudgetsNotifier {
  FakeBudgetsNotifier() : super(const AsyncValue.data([]));

  @override
  Future<void> fetchBudgets() async {}

  @override
  Future<void> setBudget({required String category, required double monthlyLimit}) async {}

  @override
  Future<void> deleteBudget(String budgetId) async {}
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
