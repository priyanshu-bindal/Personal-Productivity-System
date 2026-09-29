import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ocean_theme.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../providers/money_provider.dart';
import '../models/expense_filter_state.dart';
import 'transaction_list_item.dart';

/// Premium compact Quick Filters bar for the Expenses screen.
class ExpenseFilterBar extends ConsumerWidget {
  const ExpenseFilterBar({super.key});

  static const Color _focusFlowBlue = Color(0xFF2F6BFF);
  static const Color _cardBg = Color(0xFF0E1526);
  static const Color _borderIdle = Color(0xFF1B2B48);
  static const Color _textDim = Color(0xFF7E93A8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(expenseFilterStateProvider);

    final isCategoryActive = filterState.category != null &&
        filterState.category!.isNotEmpty &&
        filterState.category != 'all';
    final categoryLabel = isCategoryActive
        ? filterState.category![0].toUpperCase() +
            filterState.category!.substring(1)
        : 'Category';
    final categoryIcon = isCategoryActive
        ? TransactionListItem.getCategoryIcon(filterState.category!)
        : LucideIcons.tag;

    final isPaymentActive = filterState.paymentMethod != null &&
        filterState.paymentMethod!.isNotEmpty &&
        filterState.paymentMethod != 'all';
    final paymentLabel = isPaymentActive
        ? _formatPaymentMethodName(filterState.paymentMethod!)
        : 'Payment';

    final isAmountActive = filterState.amountRange != AmountFilterRange.all;
    final amountLabel = isAmountActive
        ? filterState.amountFilterLabel
        : 'Amount';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Tier 1: Quick Date Presets (Horizontal Scroll)
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildFilterChip(
                label: 'All',
                isActive: filterState.dateFilter == QuickDateFilter.all,
                onTap: () {
                  ref.read(expenseFilterStateProvider.notifier).state =
                      filterState.copyWith(
                    dateFilter: QuickDateFilter.all,
                    clearCustomDateRange: true,
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Today',
                isActive: filterState.dateFilter == QuickDateFilter.today,
                onTap: () {
                  ref.read(expenseFilterStateProvider.notifier).state =
                      filterState.copyWith(
                    dateFilter: QuickDateFilter.today,
                    clearCustomDateRange: true,
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'This Week',
                isActive: filterState.dateFilter == QuickDateFilter.thisWeek,
                onTap: () {
                  ref.read(expenseFilterStateProvider.notifier).state =
                      filterState.copyWith(
                    dateFilter: QuickDateFilter.thisWeek,
                    clearCustomDateRange: true,
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'This Month',
                isActive: filterState.dateFilter == QuickDateFilter.thisMonth,
                onTap: () {
                  ref.read(expenseFilterStateProvider.notifier).state =
                      filterState.copyWith(
                    dateFilter: QuickDateFilter.thisMonth,
                    clearCustomDateRange: true,
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: 'Last Month',
                isActive: filterState.dateFilter == QuickDateFilter.lastMonth,
                onTap: () {
                  ref.read(expenseFilterStateProvider.notifier).state =
                      filterState.copyWith(
                    dateFilter: QuickDateFilter.lastMonth,
                    clearCustomDateRange: true,
                  );
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: filterState.dateFilter == QuickDateFilter.customRange &&
                        filterState.customDateRange != null
                    ? filterState.dateFilterLabel
                    : 'Custom Range',
                icon: LucideIcons.calendar,
                isActive: filterState.dateFilter == QuickDateFilter.customRange,
                onTap: () => _openCustomDateRangePicker(context, ref, filterState),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // 2. Tier 2: Refined Dimension Filters (Category, Payment, Amount)
        SizedBox(
          height: 36,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children: [
              _buildDropdownFilterChip(
                label: categoryLabel,
                icon: categoryIcon,
                isActive: isCategoryActive,
                onTap: () => _openCategoryFilterSheet(context, ref, filterState),
              ),
              const SizedBox(width: 8),
              _buildDropdownFilterChip(
                label: paymentLabel,
                icon: LucideIcons.creditCard,
                isActive: isPaymentActive,
                onTap: () => _openPaymentMethodFilterSheet(context, ref, filterState),
              ),
              const SizedBox(width: 8),
              _buildDropdownFilterChip(
                label: amountLabel,
                icon: LucideIcons.indianRupee,
                isActive: isAmountActive,
                onTap: () => _openAmountRangeFilterSheet(context, ref, filterState),
              ),
            ],
          ),
        ),

        // 2. Active Filter Indicator & Clear All
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: filterState.hasActiveFilters
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _focusFlowBlue.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _focusFlowBlue.withValues(alpha: 0.35),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                color: _focusFlowBlue,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${filterState.activeFilterCount} ${filterState.activeFilterCount == 1 ? 'filter' : 'filters'} active',
                              style: const TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      PressableScale(
                        scaleFactor: 0.95,
                        onTap: () {
                          ref.read(expenseFilterStateProvider.notifier).state =
                              filterState.reset();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                LucideIcons.rotateCcw,
                                size: 12,
                                color: _focusFlowBlue,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Clear All',
                                style: TextStyle(
                                  color: _focusFlowBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  static Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return PressableScale(
      scaleFactor: 0.96,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _focusFlowBlue : _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _focusFlowBlue : _borderIdle,
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _focusFlowBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isActive ? Colors.white : _textDim,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildDropdownFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return PressableScale(
      scaleFactor: 0.96,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _focusFlowBlue.withValues(alpha: 0.18) : _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _focusFlowBlue : _borderIdle,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 13,
                color: isActive ? _focusFlowBlue : _textDim,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronDown,
              size: 13,
              color: isActive ? _focusFlowBlue : _textDim,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPaymentMethodName(String method) {
    switch (method.toLowerCase()) {
      case 'upi':
        return 'UPI';
      case 'cash':
        return 'Cash';
      case 'debit_card':
        return 'Debit Card';
      case 'credit_card':
        return 'Credit Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return 'Other';
    }
  }

  // ─── Custom Date Range Picker Modal ──────────────────────────────
  static void _openCustomDateRangePicker(
    BuildContext context,
    WidgetRef ref,
    ExpenseFilterState currentState,
  ) async {
    final now = DateTime.now();
    DateTime tempStart = currentState.customDateRange?.start ??
        now.subtract(const Duration(days: 14));
    DateTime tempEnd = currentState.customDateRange?.end ?? now;

    final result = await showModalBottomSheet<DateTimeRange>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final startLabel = DateFormat('MMMM d, yyyy').format(tempStart);
            final endLabel = DateFormat('MMMM d, yyyy').format(tempEnd);

            return Container(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              decoration: const BoxDecoration(
                color: OceanTheme.card,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(color: _borderIdle, width: 1),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet grabber
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: _borderIdle,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Select Custom Date Range',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(LucideIcons.x,
                              color: _textDim, size: 18),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Start & End Date Selection Tiles
                    Row(
                      children: [
                        // Start Date
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tempStart,
                                firstDate: DateTime(2020),
                                lastDate: tempEnd,
                                builder: (ctx, child) =>
                                    _darkDatePickerTheme(ctx, child),
                              );
                              if (picked != null) {
                                setModalState(() => tempStart = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: OceanTheme.bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _borderIdle),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'START DATE',
                                    style: TextStyle(
                                      color: _textDim,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    startLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // End Date
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: tempEnd,
                                firstDate: tempStart,
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                                builder: (ctx, child) =>
                                    _darkDatePickerTheme(ctx, child),
                              );
                              if (picked != null) {
                                setModalState(() => tempEnd = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              decoration: BoxDecoration(
                                color: OceanTheme.bg,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: _borderIdle),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'END DATE',
                                    style: TextStyle(
                                      color: _textDim,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    endLabel,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Action Buttons (Cancel / Apply)
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.textDim,
                              side: const BorderSide(color: _borderIdle),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(
                                DateTimeRange(start: tempStart, end: tempEnd),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _focusFlowBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Apply',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      ref.read(expenseFilterStateProvider.notifier).state =
          currentState.copyWith(
        dateFilter: QuickDateFilter.customRange,
        customDateRange: result,
      );
    }
  }

  // ─── Category Picker Sheet ───────────────────────────────────────
  static void _openCategoryFilterSheet(
    BuildContext context,
    WidgetRef ref,
    ExpenseFilterState currentState,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(sheetContext).size.height * 0.65,
          ),
          decoration: const BoxDecoration(
            color: OceanTheme.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: _borderIdle)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _borderIdle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter by Category',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: _textDim, size: 18),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: _borderIdle, height: 1),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // "All Categories" option
                      _buildSelectorTile(
                        icon: LucideIcons.layoutGrid,
                        iconColor: _textDim,
                        title: 'All Categories',
                        isSelected: currentState.category == null ||
                            currentState.category == 'all',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          ref.read(expenseFilterStateProvider.notifier).state =
                              currentState.copyWith(clearCategory: true);
                        },
                      ),
                      ...AppConstants.expenseCategories.map((c) {
                        final label = c[0].toUpperCase() + c.substring(1);
                        final icon = TransactionListItem.getCategoryIcon(c);
                        final color = TransactionListItem.getCategoryColor(c);
                        final isSel = currentState.category?.toLowerCase() == c.toLowerCase();

                        return _buildSelectorTile(
                          icon: icon,
                          iconColor: color,
                          title: label,
                          isSelected: isSel,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            ref.read(expenseFilterStateProvider.notifier).state =
                                currentState.copyWith(category: c);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Payment Method Picker Sheet ─────────────────────────────────
  static void _openPaymentMethodFilterSheet(
    BuildContext context,
    WidgetRef ref,
    ExpenseFilterState currentState,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: OceanTheme.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: _borderIdle)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _borderIdle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter by Payment Method',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: _textDim, size: 18),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: _borderIdle, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSelectorTile(
                        icon: LucideIcons.layoutGrid,
                        iconColor: _textDim,
                        title: 'All Payment Methods',
                        isSelected: currentState.paymentMethod == null ||
                            currentState.paymentMethod == 'all',
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          ref.read(expenseFilterStateProvider.notifier).state =
                              currentState.copyWith(clearPaymentMethod: true);
                        },
                      ),
                      ...AppConstants.paymentMethods.map((m) {
                        final label = _formatPaymentMethodName(m);
                        final isSel = currentState.paymentMethod?.toLowerCase() ==
                            m.toLowerCase();

                        return _buildSelectorTile(
                          icon: LucideIcons.creditCard,
                          iconColor: const Color(0xFF60A5FA),
                          title: label,
                          isSelected: isSel,
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            ref.read(expenseFilterStateProvider.notifier).state =
                                currentState.copyWith(paymentMethod: m);
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Amount Range Picker Sheet ───────────────────────────────────
  static void _openAmountRangeFilterSheet(
    BuildContext context,
    WidgetRef ref,
    ExpenseFilterState currentState,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: const BoxDecoration(
            color: OceanTheme.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(top: BorderSide(color: _borderIdle)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _borderIdle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 16, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter by Amount Range',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.x, color: _textDim, size: 18),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),
                const Divider(color: _borderIdle, height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildSelectorTile(
                        icon: LucideIcons.circleDot,
                        iconColor: _textDim,
                        title: 'All Amounts',
                        isSelected: currentState.amountRange == AmountFilterRange.all,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          ref.read(expenseFilterStateProvider.notifier).state =
                              currentState.copyWith(
                                  amountRange: AmountFilterRange.all);
                        },
                      ),
                      _buildSelectorTile(
                        icon: LucideIcons.arrowDown,
                        iconColor: AppColors.accentAmber,
                        title: 'Under ₹500',
                        isSelected:
                            currentState.amountRange == AmountFilterRange.under500,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          ref.read(expenseFilterStateProvider.notifier).state =
                              currentState.copyWith(
                                  amountRange: AmountFilterRange.under500);
                        },
                      ),
                      _buildSelectorTile(
                        icon: LucideIcons.arrowUpDown,
                        iconColor: _focusFlowBlue,
                        title: '₹500 – ₹2,000',
                        isSelected: currentState.amountRange ==
                            AmountFilterRange.between500And2000,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          ref.read(expenseFilterStateProvider.notifier).state =
                              currentState.copyWith(
                                  amountRange:
                                      AmountFilterRange.between500And2000);
                        },
                      ),
                      _buildSelectorTile(
                        icon: LucideIcons.arrowUp,
                        iconColor: const Color(0xFFEC4899),
                        title: 'Above ₹2,000',
                        isSelected:
                            currentState.amountRange == AmountFilterRange.above2000,
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          ref.read(expenseFilterStateProvider.notifier).state =
                              currentState.copyWith(
                                  amountRange: AmountFilterRange.above2000);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildSelectorTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                LucideIcons.check,
                color: _focusFlowBlue,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }

  static Widget _darkDatePickerTheme(BuildContext context, Widget? child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: _focusFlowBlue,
          onPrimary: Colors.white,
          surface: OceanTheme.card,
          onSurface: AppColors.textPrimary,
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: OceanTheme.card,
        ),
      ),
      child: child!,
    );
  }
}
