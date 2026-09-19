import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense.dart';
import '../services/supabase_service.dart';

final trashedExpensesProvider =
    StateNotifierProvider<TrashedExpensesNotifier, AsyncValue<List<Expense>>>((ref) {
  return TrashedExpensesNotifier();
});

class TrashedExpensesNotifier extends StateNotifier<AsyncValue<List<Expense>>> {
  TrashedExpensesNotifier() : super(const AsyncValue.loading()) {
    fetchTrashed();
  }

  /// Fetches all trashed expenses (deleted_at IS NOT NULL) sorted newest deleted first.
  /// Also triggers safe, idempotent background cleanup for records expired past 30 days.
  Future<void> fetchTrashed() async {
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
          .not('deleted_at', 'is', null)
          .order('deleted_at', ascending: false);

      final list = (res as List)
          .map((e) => Expense.fromJson(e as Map<String, dynamic>))
          .toList();

      state = AsyncValue.data(list);

      // Safe opportunistic cleanup of expired records (older than exactly 30 days)
      cleanupExpiredExpenses();
    } catch (e, st) {
      if (state.value == null) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  /// Restores a trashed expense by setting deleted_at = NULL in Supabase.
  /// Optimistically removes the item from the Trash list immediately.
  Future<void> restore(Expense expense) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final currentList = state.value ?? [];
    final index = currentList.indexWhere((e) => e.id == expense.id);
    if (index == -1) return;
    final removedItem = currentList[index];

    // Optimistically remove from Trash
    state = AsyncValue.data(List<Expense>.from(currentList)..removeAt(index));

    try {
      await SupabaseService.client
          .from('expenses')
          .update({'deleted_at': null})
          .eq('id', expense.id);
    } catch (e) {
      // Rollback
      final latestList = List<Expense>.from(state.value ?? []);
      final insertIndex = index.clamp(0, latestList.length);
      latestList.insert(insertIndex, removedItem);
      state = AsyncValue.data(latestList);
      rethrow;
    }
  }

  /// Permanently deletes a single expense from Supabase.
  /// Optimistically removes it from the Trash list.
  Future<void> permanentlyDelete(String expenseId) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final currentList = state.value ?? [];
    final index = currentList.indexWhere((e) => e.id == expenseId);
    if (index == -1) return;
    final removedItem = currentList[index];

    // Optimistically remove from Trash
    state = AsyncValue.data(List<Expense>.from(currentList)..removeAt(index));

    try {
      await SupabaseService.client
          .from('expenses')
          .delete()
          .eq('id', expenseId);
    } catch (e) {
      // Rollback
      final latestList = List<Expense>.from(state.value ?? []);
      final insertIndex = index.clamp(0, latestList.length);
      latestList.insert(insertIndex, removedItem);
      state = AsyncValue.data(latestList);
      rethrow;
    }
  }

  /// Cleans up expenses deleted >= 30 exact UTC days ago.
  ///
  /// Criteria:
  ///   cutoffUtc = nowUtc - 30 days
  ///   delete where deleted_at < cutoffUtc
  Future<void> cleanupExpiredExpenses() async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    final nowUtc = DateTime.now().toUtc();
    final cutoffUtc = nowUtc.subtract(const Duration(days: 30));

    try {
      await SupabaseService.client
          .from('expenses')
          .delete()
          .eq('user_id', userId)
          .not('deleted_at', 'is', null)
          .lt('deleted_at', cutoffUtc.toIso8601String());

      // Filter out any locally cached items that have expired
      final currentList = state.value ?? [];
      final validList = currentList.where((e) {
        if (e.deletedAt == null) return false;
        final expiryUtc = e.deletedAt!.toUtc().add(const Duration(days: 30));
        return nowUtc.isBefore(expiryUtc);
      }).toList();

      if (validList.length != currentList.length) {
        state = AsyncValue.data(validList);
      }
    } catch (_) {
      // Silent error: background cleanup is opportunistic and safe to retry
    }
  }
}
