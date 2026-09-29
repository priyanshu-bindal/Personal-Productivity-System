import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/expense.dart';

/// Quick date filter presets.
enum QuickDateFilter {
  all,
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  customRange,
}

/// Amount filter ranges.
enum AmountFilterRange {
  all,
  under500,
  between500And2000,
  above2000,
}

/// Immutable state representing all active filters on the expenses list.
@immutable
class ExpenseFilterState {
  final QuickDateFilter dateFilter;
  final DateTimeRange? customDateRange;
  final String? category;
  final String? paymentMethod;
  final AmountFilterRange amountRange;

  const ExpenseFilterState({
    this.dateFilter = QuickDateFilter.all,
    this.customDateRange,
    this.category,
    this.paymentMethod,
    this.amountRange = AmountFilterRange.all,
  });

  /// Count of active filters (excluding 'All' defaults).
  int get activeFilterCount {
    int count = 0;
    if (dateFilter != QuickDateFilter.all) count++;
    if (category != null && category!.isNotEmpty && category != 'all') count++;
    if (paymentMethod != null && paymentMethod!.isNotEmpty && paymentMethod != 'all') count++;
    if (amountRange != AmountFilterRange.all) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  /// User-friendly label for the current date filter.
  String get dateFilterLabel {
    switch (dateFilter) {
      case QuickDateFilter.all:
        return 'All Time';
      case QuickDateFilter.today:
        return 'Today';
      case QuickDateFilter.thisWeek:
        return 'This Week';
      case QuickDateFilter.thisMonth:
        return 'This Month';
      case QuickDateFilter.lastMonth:
        return 'Last Month';
      case QuickDateFilter.customRange:
        if (customDateRange != null) {
          final s = DateFormat('MMM d').format(customDateRange!.start);
          final e = DateFormat('MMM d, yyyy').format(customDateRange!.end);
          return '$s – $e';
        }
        return 'Custom Range';
    }
  }

  /// User-friendly description for the amount filter.
  String get amountFilterLabel {
    switch (amountRange) {
      case AmountFilterRange.all:
        return 'All Amounts';
      case AmountFilterRange.under500:
        return '< ₹500';
      case AmountFilterRange.between500And2000:
        return '₹500 – ₹2,000';
      case AmountFilterRange.above2000:
        return '> ₹2,000';
    }
  }

  /// Generates a human-readable reporting period string (used in PDF export & dialogs).
  String getReportingPeriod([List<Expense>? expenses]) {
    final now = DateTime.now();
    switch (dateFilter) {
      case QuickDateFilter.all:
        if (expenses != null && expenses.isNotEmpty) {
          final dates = expenses.map((e) => e.expenseDate).toList()..sort();
          try {
            final start = DateTime.parse(dates.first);
            final end = DateTime.parse(dates.last);
            final sStr = DateFormat('MMMM d, yyyy').format(start);
            final eStr = DateFormat('MMMM d, yyyy').format(end);
            return start == end ? sStr : '$sStr – $eStr';
          } catch (_) {}
        }
        return 'All Recorded Transactions';
      case QuickDateFilter.today:
        return DateFormat('MMMM d, yyyy').format(now);
      case QuickDateFilter.thisWeek:
        final dayOfWeek = now.weekday;
        final monday = now.subtract(Duration(days: dayOfWeek - 1));
        final sunday = monday.add(const Duration(days: 6));
        return '${DateFormat('MMM d').format(monday)} – ${DateFormat('MMM d, yyyy').format(sunday)}';
      case QuickDateFilter.thisMonth:
        return DateFormat('MMMM yyyy').format(now);
      case QuickDateFilter.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1, 1);
        return DateFormat('MMMM yyyy').format(lastMonth);
      case QuickDateFilter.customRange:
        if (customDateRange != null) {
          final s = DateFormat('MMMM d, yyyy').format(customDateRange!.start);
          final e = DateFormat('MMMM d, yyyy').format(customDateRange!.end);
          return '$s – $e';
        }
        return 'Custom Date Range';
    }
  }

  /// Filters an expense list based on this filter state and search query.
  List<Expense> apply(List<Expense> expenses, {String searchQuery = ''}) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final thisMonthStr = DateFormat('yyyy-MM').format(now);
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastMonthStr = DateFormat('yyyy-MM').format(lastMonth);

    // Week boundaries (Monday to Sunday)
    final dayOfWeek = now.weekday;
    final monday = now.subtract(Duration(days: dayOfWeek - 1));
    final mondayStr = DateFormat('yyyy-MM-dd').format(monday);
    final sunday = monday.add(const Duration(days: 6));
    final sundayStr = DateFormat('yyyy-MM-dd').format(sunday);

    final q = searchQuery.toLowerCase().trim();

    return expenses.where((e) {
      // 1. Text Search Filter
      if (q.isNotEmpty) {
        final matchesDesc = e.description.toLowerCase().contains(q);
        final matchesCat = e.category.toLowerCase().contains(q);
        final matchesNote = (e.note ?? '').toLowerCase().contains(q);
        if (!matchesDesc && !matchesCat && !matchesNote) return false;
      }

      // 2. Date Filter
      switch (dateFilter) {
        case QuickDateFilter.all:
          break;
        case QuickDateFilter.today:
          if (e.expenseDate != todayStr) return false;
          break;
        case QuickDateFilter.thisWeek:
          if (e.expenseDate.compareTo(mondayStr) < 0 ||
              e.expenseDate.compareTo(sundayStr) > 0) {
            return false;
          }
          break;
        case QuickDateFilter.thisMonth:
          if (!e.expenseDate.startsWith(thisMonthStr)) return false;
          break;
        case QuickDateFilter.lastMonth:
          if (!e.expenseDate.startsWith(lastMonthStr)) return false;
          break;
        case QuickDateFilter.customRange:
          if (customDateRange != null) {
            final startStr = DateFormat('yyyy-MM-dd').format(customDateRange!.start);
            final endStr = DateFormat('yyyy-MM-dd').format(customDateRange!.end);
            if (e.expenseDate.compareTo(startStr) < 0 ||
                e.expenseDate.compareTo(endStr) > 0) {
              return false;
            }
          }
          break;
      }

      // 3. Category Filter
      if (category != null && category!.isNotEmpty && category != 'all') {
        if (e.category.toLowerCase() != category!.toLowerCase()) return false;
      }

      // 4. Payment Method Filter
      if (paymentMethod != null &&
          paymentMethod!.isNotEmpty &&
          paymentMethod != 'all') {
        final normMethod = paymentMethod!.toLowerCase().replaceAll(' ', '_');
        if (e.paymentMethod.toLowerCase() != normMethod) return false;
      }

      // 5. Amount Range Filter
      switch (amountRange) {
        case AmountFilterRange.all:
          break;
        case AmountFilterRange.under500:
          if (e.amount >= 500) return false;
          break;
        case AmountFilterRange.between500And2000:
          if (e.amount < 500 || e.amount > 2000) return false;
          break;
        case AmountFilterRange.above2000:
          if (e.amount <= 2000) return false;
          break;
      }

      return true;
    }).toList();
  }

  ExpenseFilterState copyWith({
    QuickDateFilter? dateFilter,
    DateTimeRange? customDateRange,
    bool clearCustomDateRange = false,
    String? category,
    bool clearCategory = false,
    String? paymentMethod,
    bool clearPaymentMethod = false,
    AmountFilterRange? amountRange,
  }) {
    return ExpenseFilterState(
      dateFilter: dateFilter ?? this.dateFilter,
      customDateRange: clearCustomDateRange ? null : (customDateRange ?? this.customDateRange),
      category: clearCategory ? null : (category ?? this.category),
      paymentMethod: clearPaymentMethod ? null : (paymentMethod ?? this.paymentMethod),
      amountRange: amountRange ?? this.amountRange,
    );
  }

  ExpenseFilterState reset() => const ExpenseFilterState();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseFilterState &&
          runtimeType == other.runtimeType &&
          dateFilter == other.dateFilter &&
          customDateRange == other.customDateRange &&
          category == other.category &&
          paymentMethod == other.paymentMethod &&
          amountRange == other.amountRange;

  @override
  int get hashCode =>
      dateFilter.hashCode ^
      customDateRange.hashCode ^
      category.hashCode ^
      paymentMethod.hashCode ^
      amountRange.hashCode;
}
