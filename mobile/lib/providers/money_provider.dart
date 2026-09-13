import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../services/supabase_service.dart';

final expenseSearchProvider = StateProvider<String>((ref) => '');
final expenseCategoryFilterProvider = StateProvider<String?>((ref) => null);

final expensesProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  return ExpensesNotifier();
});

class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  static int _uuidCounter = 0;

  ExpensesNotifier() : super(const AsyncValue.loading()) {
    fetchExpenses();
  }

  Future<void> fetchExpenses() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final res = await SupabaseService.client
          .from('expenses')
          .select('*')
          .eq('user_id', userId)
          .order('expense_date', ascending: false);

      final list = (res as List).map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
      
      // Preserve any in-flight optimistic expenses that haven't reconciled yet
      final current = state.value ?? [];
      final inFlightOptimistic = current.where((e) => e.isOptimistic).toList();
      if (inFlightOptimistic.isNotEmpty) {
        state = AsyncValue.data([...inFlightOptimistic, ...list]);
      } else {
        state = AsyncValue.data(list);
      }
    } catch (e, st) {
      if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<Expense?> addExpense({
    required double amount,
    required String description,
    required String category,
    required String paymentMethod,
    required DateTime date,
    String? note,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return null;

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final tempId = 'opt_${DateTime.now().microsecondsSinceEpoch}_${_uuidCounter++}';

    // 1. Immediate optimistic insertion
    final optimisticExpense = Expense(
      id: tempId,
      userId: userId,
      amount: amount,
      description: description,
      category: category.toLowerCase(),
      paymentMethod: paymentMethod.toLowerCase().replaceAll(' ', '_'),
      expenseDate: dateStr,
      note: note,
      createdAt: DateTime.now(),
      isOptimistic: true,
    );

    final currentList = state.value ?? [];
    state = AsyncValue.data([optimisticExpense, ...currentList]);

    try {
      // 2. Single database roundtrip (INSERT + SELECT)
      final res = await SupabaseService.client
          .from('expenses')
          .insert({
            'user_id': userId,
            'amount': amount,
            'description': description,
            'category': category.toLowerCase(),
            'payment_method': paymentMethod.toLowerCase().replaceAll(' ', '_'),
            'expense_date': dateStr,
            'note': note,
          })
          .select()
          .single();

      final confirmedExpense = Expense.fromJson(res);

      // 3. Concurrency-safe reconciliation: replace strictly by unique tempId
      final latestList = state.value ?? [];
      final index = latestList.indexWhere((e) => e.id == tempId);
      if (index != -1) {
        final updatedList = List<Expense>.from(latestList);
        updatedList[index] = confirmedExpense;
        state = AsyncValue.data(updatedList);
      } else {
        // In case tempId wasn't found, ensure confirmed item is present without duplication
        final exists = latestList.any((e) => e.id == confirmedExpense.id);
        if (!exists) {
          state = AsyncValue.data([confirmedExpense, ...latestList]);
        }
      }
      return confirmedExpense;
    } catch (e) {
      // 4. Rollback: remove the specific optimistic item without disturbing other transactions
      final latestList = state.value ?? [];
      final updatedList = latestList.where((e) => e.id != tempId).toList();
      state = AsyncValue.data(updatedList);
      rethrow;
    }
  }

  Future<void> updateExpense({
    required String expenseId,
    required double amount,
    required String description,
    required String category,
    required String paymentMethod,
    required DateTime date,
    String? note,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final currentList = state.value ?? [];
    final index = currentList.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;
    final originalItem = currentList[index];

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final optimisticUpdated = originalItem.copyWith(
      amount: amount,
      description: description,
      category: category.toLowerCase(),
      paymentMethod: paymentMethod.toLowerCase().replaceAll(' ', '_'),
      expenseDate: dateStr,
      note: note,
      isOptimistic: true,
    );

    final updatedList = List<Expense>.from(currentList);
    updatedList[index] = optimisticUpdated;
    state = AsyncValue.data(updatedList);

    try {
      final res = await SupabaseService.client
          .from('expenses')
          .update({
            'amount': amount,
            'description': description,
            'category': category.toLowerCase(),
            'payment_method': paymentMethod.toLowerCase().replaceAll(' ', '_'),
            'expense_date': dateStr,
            'note': note,
          })
          .eq('id', expenseId)
          .select()
          .single();

      final confirmed = Expense.fromJson(res);
      final latestList = List<Expense>.from(state.value ?? []);
      final latestIndex = latestList.indexWhere((e) => e.id == expenseId);
      if (latestIndex != -1) {
        latestList[latestIndex] = confirmed;
        state = AsyncValue.data(latestList);
      }
    } catch (e) {
      final latestList = List<Expense>.from(state.value ?? []);
      final latestIndex = latestList.indexWhere((e) => e.id == expenseId);
      if (latestIndex != -1) {
        latestList[latestIndex] = originalItem;
        state = AsyncValue.data(latestList);
      }
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final currentList = state.value ?? [];
    final index = currentList.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;
    final removedItem = currentList[index];

    // Optimistically remove
    final updatedList = List<Expense>.from(currentList)..removeAt(index);
    state = AsyncValue.data(updatedList);

    try {
      await SupabaseService.client.from('expenses').delete().eq('id', expenseId);
    } catch (e) {
      // Rollback
      final latestList = List<Expense>.from(state.value ?? []);
      final insertIndex = index.clamp(0, latestList.length);
      latestList.insert(insertIndex, removedItem);
      state = AsyncValue.data(latestList);
      rethrow;
    }
  }
}

final budgetsProvider = StateNotifierProvider<BudgetsNotifier, AsyncValue<List<Budget>>>((ref) {
  return BudgetsNotifier();
});

class BudgetsNotifier extends StateNotifier<AsyncValue<List<Budget>>> {
  BudgetsNotifier() : super(const AsyncValue.loading()) {
    fetchBudgets();
  }

  Future<void> fetchBudgets() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final now = DateTime.now();
      final monthKey = DateFormat('yyyy-MM-01').format(now);

      final res = await SupabaseService.client
          .from('budgets')
          .select('*')
          .eq('user_id', userId)
          .eq('month', monthKey);

      final list = (res as List).map((e) => Budget.fromJson(e as Map<String, dynamic>)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setBudget({required String category, required double monthlyLimit}) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final now = DateTime.now();
    final monthKey = DateFormat('yyyy-MM-01').format(now);
    final cat = category.toLowerCase();

    final existing = await SupabaseService.client
        .from('budgets')
        .select('id')
        .eq('user_id', userId)
        .eq('category', cat)
        .eq('month', monthKey)
        .maybeSingle();

    if (existing != null) {
      await SupabaseService.client
          .from('budgets')
          .update({'monthly_limit': monthlyLimit})
          .eq('id', existing['id']);
    } else {
      await SupabaseService.client.from('budgets').insert({
        'user_id': userId,
        'category': cat,
        'monthly_limit': monthlyLimit,
        'month': monthKey,
      });
    }
    await fetchBudgets();
  }

  Future<void> deleteBudget(String budgetId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    await SupabaseService.client.from('budgets').delete().eq('id', budgetId);
    await fetchBudgets();
  }
}

// Derived Money Metrics
class MoneySummary {
  final double todayTotal;
  final double monthTotal;
  final double avgDaily;
  final String highestCategory;
  final double highestCategoryAmount;
  final List<Map<String, dynamic>> dailyChartData;
  final List<Map<String, dynamic>> categoryBreakdown;

  MoneySummary({
    required this.todayTotal,
    required this.monthTotal,
    required this.avgDaily,
    required this.highestCategory,
    required this.highestCategoryAmount,
    required this.dailyChartData,
    required this.categoryBreakdown,
  });
}

final moneySummaryProvider = Provider<MoneySummary>((ref) {
  final expenses = ref.watch(expensesProvider).value ?? [];

  final now = DateTime.now();
  final todayStr = DateFormat('yyyy-MM-dd').format(now);
  final monthPrefix = DateFormat('yyyy-MM').format(now);

  double todaySum = 0;
  double monthSum = 0;

  final Map<String, double> catTotals = {};
  final Map<String, double> dailyTotals = {};

  for (final e in expenses) {
    if (e.expenseDate == todayStr) {
      todaySum += e.amount;
    }
    if (e.expenseDate.startsWith(monthPrefix)) {
      monthSum += e.amount;

      final cat = e.category.toLowerCase();
      catTotals[cat] = (catTotals[cat] ?? 0) + e.amount;

      dailyTotals[e.expenseDate] = (dailyTotals[e.expenseDate] ?? 0) + e.amount;
    }
  }

  final daysElapsed = now.day;
  final avg = daysElapsed > 0 ? monthSum / daysElapsed : 0.0;

  String topCat = 'None';
  double topCatAmt = 0;
  catTotals.forEach((cat, amt) {
    if (amt > topCatAmt) {
      topCatAmt = amt;
      topCat = cat;
    }
  });

  // Category breakdown list
  final breakdown = catTotals.entries.map((entry) {
    return {
      'category': entry.key,
      'amount': entry.value,
      'percentage': monthSum > 0 ? ((entry.value / monthSum) * 100).round() : 0,
    };
  }).toList()
    ..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

  // Daily chart data sorted by date
  final dailyChart = dailyTotals.entries.map((entry) {
    return {
      'date': entry.key,
      'amount': entry.value,
    };
  }).toList()
    ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

  return MoneySummary(
    todayTotal: todaySum,
    monthTotal: monthSum,
    avgDaily: avg,
    highestCategory: topCat.isNotEmpty ? topCat[0].toUpperCase() + topCat.substring(1) : 'None',
    highestCategoryAmount: topCatAmt,
    dailyChartData: dailyChart,
    categoryBreakdown: breakdown,
  );
});
