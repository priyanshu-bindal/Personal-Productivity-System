import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/budget.dart';
import '../services/supabase_service.dart';
import 'auth_provider.dart';

final expenseSearchProvider = StateProvider<String>((ref) => '');
final expenseCategoryFilterProvider = StateProvider<String?>((ref) => null);

final expensesProvider = StateNotifierProvider<ExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return ExpensesNotifier(userId);
});

class ExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  static int _uuidCounter = 0;
  final String? _userId;

  ExpensesNotifier([this._userId])
      : super(_userId == null ? const AsyncValue.data([]) : const AsyncValue.loading()) {
    if (_userId != null) {
      fetchExpenses();
    }
  }

  Future<void> fetchExpenses() async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }

    try {
      final res = await SupabaseService.client
          .from('expenses')
          .select('*')
          .eq('user_id', effectiveUserId)
          .isFilter('deleted_at', null)
          .order('expense_date', ascending: false);

      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;
      final list = (res as List).map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
      
      // Preserve any in-flight optimistic expenses that haven't reconciled yet and are not deleted
      final current = state.value ?? [];
      final inFlightOptimistic = current.where((e) => e.isOptimistic && e.deletedAt == null).toList();
      if (inFlightOptimistic.isNotEmpty) {
        state = AsyncValue.data([...inFlightOptimistic, ...list]);
      } else {
        state = AsyncValue.data(list);
      }
    } catch (e, st) {
      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;
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
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return null;
    }

    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final tempId = 'opt_${DateTime.now().microsecondsSinceEpoch}_${_uuidCounter++}';

    // 1. Immediate optimistic insertion
    final optimisticExpense = Expense(
      id: tempId,
      userId: effectiveUserId,
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
            'user_id': effectiveUserId,
            'amount': amount,
            'description': description,
            'category': category.toLowerCase(),
            'payment_method': paymentMethod.toLowerCase().replaceAll(' ', '_'),
            'expense_date': dateStr,
            'note': note,
          })
          .select()
          .single();

      if (!mounted || SupabaseService.currentUserId != effectiveUserId) {
        return null;
      }

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
      if (mounted && SupabaseService.currentUserId == effectiveUserId) {
        final latestList = state.value ?? [];
        final updatedList = latestList.where((e) => e.id != tempId).toList();
        state = AsyncValue.data(updatedList);
      }
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
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return;
    }

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
          .eq('user_id', effectiveUserId)
          .select()
          .single();

      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;

      final confirmed = Expense.fromJson(res);
      final latestList = List<Expense>.from(state.value ?? []);
      final latestIndex = latestList.indexWhere((e) => e.id == expenseId);
      if (latestIndex != -1) {
        latestList[latestIndex] = confirmed;
        state = AsyncValue.data(latestList);
      }
    } catch (e) {
      if (mounted && SupabaseService.currentUserId == effectiveUserId) {
        final latestList = List<Expense>.from(state.value ?? []);
        final latestIndex = latestList.indexWhere((e) => e.id == expenseId);
        if (latestIndex != -1) {
          latestList[latestIndex] = originalItem;
          state = AsyncValue.data(latestList);
        }
      }
      rethrow;
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return;
    }

    final currentList = state.value ?? [];
    final index = currentList.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;
    final removedItem = currentList[index];

    // Optimistically remove from active list
    final updatedList = List<Expense>.from(currentList)..removeAt(index);
    state = AsyncValue.data(updatedList);

    try {
      final nowUtc = DateTime.now().toUtc();
      await SupabaseService.client
          .from('expenses')
          .update({'deleted_at': nowUtc.toIso8601String()})
          .eq('id', expenseId)
          .eq('user_id', effectiveUserId);
    } catch (e) {
      // Rollback
      if (mounted && SupabaseService.currentUserId == effectiveUserId) {
        final latestList = List<Expense>.from(state.value ?? []);
        final insertIndex = index.clamp(0, latestList.length);
        latestList.insert(insertIndex, removedItem);
        state = AsyncValue.data(latestList);
      }
      rethrow;
    }
  }

  Future<void> restoreExpense(Expense expense) async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return;
    }

    final restoredItem = expense.copyWith(clearDeletedAt: true, isOptimistic: false);

    // Optimistically insert back into active list if not already present
    final currentList = state.value ?? [];
    final existingIndex = currentList.indexWhere((e) => e.id == expense.id);
    if (existingIndex == -1) {
      state = AsyncValue.data([restoredItem, ...currentList]);
    }

    try {
      await SupabaseService.client
          .from('expenses')
          .update({'deleted_at': null})
          .eq('id', expense.id)
          .eq('user_id', effectiveUserId);
    } catch (e) {
      // Rollback optimistic restoration
      if (mounted && SupabaseService.currentUserId == effectiveUserId) {
        final latestList = state.value ?? [];
        state = AsyncValue.data(latestList.where((e) => e.id != expense.id).toList());
      }
      rethrow;
    }
  }
}

final budgetsProvider = StateNotifierProvider<BudgetsNotifier, AsyncValue<List<Budget>>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return BudgetsNotifier(userId);
});

class BudgetsNotifier extends StateNotifier<AsyncValue<List<Budget>>> {
  final String? _userId;

  BudgetsNotifier([this._userId])
      : super(_userId == null ? const AsyncValue.data([]) : const AsyncValue.loading()) {
    if (_userId != null) {
      fetchBudgets();
    }
  }

  Future<void> fetchBudgets() async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      if (mounted) state = const AsyncValue.data([]);
      return;
    }

    try {
      final now = DateTime.now();
      final monthKey = DateFormat('yyyy-MM-01').format(now);

      final res = await SupabaseService.client
          .from('budgets')
          .select('*')
          .eq('user_id', effectiveUserId)
          .eq('month', monthKey);

      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;
      final list = (res as List).map((e) => Budget.fromJson(e as Map<String, dynamic>)).toList();
      state = AsyncValue.data(list);
    } catch (e, st) {
      if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setBudget({required String category, required double monthlyLimit}) async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return;
    }

    final now = DateTime.now();
    final monthKey = DateFormat('yyyy-MM-01').format(now);
    final cat = category.toLowerCase();

    final existing = await SupabaseService.client
        .from('budgets')
        .select('id')
        .eq('user_id', effectiveUserId)
        .eq('category', cat)
        .eq('month', monthKey)
        .maybeSingle();

    if (!mounted || SupabaseService.currentUserId != effectiveUserId) return;

    if (existing != null) {
      await SupabaseService.client
          .from('budgets')
          .update({'monthly_limit': monthlyLimit})
          .eq('id', existing['id'])
          .eq('user_id', effectiveUserId);
    } else {
      await SupabaseService.client.from('budgets').insert({
        'user_id': effectiveUserId,
        'category': cat,
        'monthly_limit': monthlyLimit,
        'month': monthKey,
      });
    }
    await fetchBudgets();
  }

  Future<void> deleteBudget(String budgetId) async {
    final effectiveUserId = _userId ?? SupabaseService.currentUserId;
    if (effectiveUserId == null ||
        !mounted ||
        SupabaseService.currentUserId != effectiveUserId) {
      return;
    }

    await SupabaseService.client
        .from('budgets')
        .delete()
        .eq('id', budgetId)
        .eq('user_id', effectiveUserId);
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
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
      dailyTotals[e.expenseDate] = (dailyTotals[e.expenseDate] ?? 0) + e.amount;
    }
  }

  final dayOfMonth = now.day > 0 ? now.day : 1;
  final avgDaily = monthSum / dayOfMonth;

  String highestCat = 'None';
  double highestAmt = 0;
  catTotals.forEach((cat, amt) {
    if (amt > highestAmt) {
      highestAmt = amt;
      highestCat = cat;
    }
  });

  // Daily Chart for last 7 days
  final List<Map<String, dynamic>> dailyChart = [];
  for (int i = 6; i >= 0; i--) {
    final d = now.subtract(Duration(days: i));
    final dStr = DateFormat('yyyy-MM-dd').format(d);
    final dayLabel = DateFormat('E').format(d);
    dailyChart.add({
      'day': dayLabel,
      'date': dStr,
      'amount': dailyTotals[dStr] ?? 0.0,
    });
  }

  // Category Breakdown sorted descending
  final List<Map<String, dynamic>> catBreakdown = [];
  catTotals.forEach((cat, amt) {
    final pct = monthSum > 0 ? (amt / monthSum * 100) : 0.0;
    catBreakdown.add({
      'category': cat,
      'amount': amt,
      'percentage': pct,
    });
  });
  catBreakdown.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));

  return MoneySummary(
    todayTotal: todaySum,
    monthTotal: monthSum,
    avgDaily: avgDaily,
    highestCategory: highestCat,
    highestCategoryAmount: highestAmt,
    dailyChartData: dailyChart,
    categoryBreakdown: catBreakdown,
  );
});
