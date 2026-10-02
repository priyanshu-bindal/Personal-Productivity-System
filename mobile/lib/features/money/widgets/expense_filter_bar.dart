import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
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

    // Advanced filters active count (excluding default 'All' date filter, which has its own quick chips)
    final hasAdvancedFilters = (filterState.category != null &&
            filterState.category!.isNotEmpty &&
            filterState.category != 'all') ||
        (filterState.paymentMethod != null &&
            filterState.paymentMethod!.isNotEmpty &&
            filterState.paymentMethod != 'all') ||
        (filterState.amountRange != AmountFilterRange.all) ||
        (filterState.dateFilter == QuickDateFilter.customRange);

    int advancedCount = 0;
    if (filterState.category != null &&
        filterState.category!.isNotEmpty &&
        filterState.category != 'all') {
      advancedCount++;
    }
    if (filterState.paymentMethod != null &&
        filterState.paymentMethod!.isNotEmpty &&
        filterState.paymentMethod != 'all') {
      advancedCount++;
    }
    if (filterState.amountRange != AmountFilterRange.all) {
      advancedCount++;
    }
    if (filterState.dateFilter == QuickDateFilter.customRange) {
      advancedCount++;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Compact Filters Row: [ Filter Button ] | [ All ] [ Today ] [ This Week ] [ This Month ] [ Last Month ]
        SizedBox(
          height: 36,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
              // 1. Advanced Filter Pill Button
              _buildAdvancedFilterButton(
                context: context,
                ref: ref,
                filterState: filterState,
                hasActive: hasAdvancedFilters,
                activeCount: advancedCount,
              ),

              const SizedBox(width: 8),
              // Subtle divider
              Container(
                width: 1,
                height: 18,
                margin: const EdgeInsets.symmetric(vertical: 9),
                color: _borderIdle,
              ),
              const SizedBox(width: 8),

              // 2. Quick Date Presets
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
              if (filterState.dateFilter == QuickDateFilter.customRange &&
                  filterState.customDateRange != null) ...[
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: filterState.dateFilterLabel,
                  icon: LucideIcons.calendar,
                  isActive: true,
                  onTap: () => _openAdvancedFilterSheet(context, ref, filterState),
                ),
              ],
            ],
            ),
          ),
        ),

        // Active Filter Summary & Clear All
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

  static Widget _buildAdvancedFilterButton({
    required BuildContext context,
    required WidgetRef ref,
    required ExpenseFilterState filterState,
    required bool hasActive,
    required int activeCount,
  }) {
    return PressableScale(
      scaleFactor: 0.96,
      onTap: () => _openAdvancedFilterSheet(context, ref, filterState),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: hasActive ? _focusFlowBlue.withValues(alpha: 0.18) : _cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasActive ? _focusFlowBlue : _borderIdle,
            width: 1,
          ),
          boxShadow: hasActive
              ? [
                  BoxShadow(
                    color: _focusFlowBlue.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.slidersHorizontal,
              size: 13,
              color: hasActive ? _focusFlowBlue : _textDim,
            ),
            const SizedBox(width: 6),
            Text(
              'Filter',
              style: TextStyle(
                color: hasActive ? Colors.white : AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: hasActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            if (hasActive) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: _focusFlowBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$activeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
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

  // ─── Premium Advanced Filter Bottom Sheet ────────────────────────
  static void _openAdvancedFilterSheet(
    BuildContext context,
    WidgetRef ref,
    ExpenseFilterState currentState,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _AdvancedFilterSheetContent(
          initialState: currentState,
          onApply: (newState) {
            ref.read(expenseFilterStateProvider.notifier).state = newState;
            Navigator.of(sheetContext).pop();
          },
          onReset: () {
            ref.read(expenseFilterStateProvider.notifier).state =
                currentState.reset();
            Navigator.of(sheetContext).pop();
          },
        );
      },
    );
  }
}

class _AdvancedFilterSheetContent extends StatefulWidget {
  final ExpenseFilterState initialState;
  final ValueChanged<ExpenseFilterState> onApply;
  final VoidCallback onReset;

  const _AdvancedFilterSheetContent({
    required this.initialState,
    required this.onApply,
    required this.onReset,
  });

  @override
  State<_AdvancedFilterSheetContent> createState() =>
      _AdvancedFilterSheetContentState();
}

class _AdvancedFilterSheetContentState
    extends State<_AdvancedFilterSheetContent> {
  static const Color _focusFlowBlue = Color(0xFF2F6BFF);
  static const Color _borderIdle = Color(0xFF1B2B48);
  static const Color _cardBg = Color(0xFF0E1526);
  static const Color _textDim = Color(0xFF7E93A8);

  late QuickDateFilter _dateFilter;
  late DateTimeRange? _customRange;
  late String? _category;
  late String? _paymentMethod;
  late AmountFilterRange _amountRange;

  @override
  void initState() {
    super.initState();
    _dateFilter = widget.initialState.dateFilter;
    _customRange = widget.initialState.customDateRange;
    _category = widget.initialState.category;
    _paymentMethod = widget.initialState.paymentMethod;
    _amountRange = widget.initialState.amountRange;
  }

  void _resetLocalFilters() {
    setState(() {
      _dateFilter = QuickDateFilter.all;
      _customRange = null;
      _category = null;
      _paymentMethod = null;
      _amountRange = AmountFilterRange.all;
    });
  }

  void _selectCustomDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      initialDateRange: _customRange ??
          DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _focusFlowBlue,
              onPrimary: Colors.white,
              surface: Color(0xFF0E1526),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateFilter = QuickDateFilter.customRange;
        _customRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0A1120),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF172A46), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sheet Grabber
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: _borderIdle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Filter Expenses',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.x,
                        size: 16,
                        color: _textDim,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(color: Color(0xFF172A46), height: 1),

            // Scrollable Filter Sections
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: DATE RANGE
                    _buildSectionHeader('DATE RANGE'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip(
                          label: 'All Time',
                          isSelected: _dateFilter == QuickDateFilter.all,
                          onTap: () => setState(() {
                            _dateFilter = QuickDateFilter.all;
                            _customRange = null;
                          }),
                        ),
                        _buildChoiceChip(
                          label: 'Today',
                          isSelected: _dateFilter == QuickDateFilter.today,
                          onTap: () => setState(() {
                            _dateFilter = QuickDateFilter.today;
                            _customRange = null;
                          }),
                        ),
                        _buildChoiceChip(
                          label: 'This Week',
                          isSelected: _dateFilter == QuickDateFilter.thisWeek,
                          onTap: () => setState(() {
                            _dateFilter = QuickDateFilter.thisWeek;
                            _customRange = null;
                          }),
                        ),
                        _buildChoiceChip(
                          label: 'This Month',
                          isSelected: _dateFilter == QuickDateFilter.thisMonth,
                          onTap: () => setState(() {
                            _dateFilter = QuickDateFilter.thisMonth;
                            _customRange = null;
                          }),
                        ),
                        _buildChoiceChip(
                          label: 'Last Month',
                          isSelected: _dateFilter == QuickDateFilter.lastMonth,
                          onTap: () => setState(() {
                            _dateFilter = QuickDateFilter.lastMonth;
                            _customRange = null;
                          }),
                        ),
                        _buildChoiceChip(
                          label: _dateFilter == QuickDateFilter.customRange &&
                                  _customRange != null
                              ? '${DateFormat('MMM d').format(_customRange!.start)} – ${DateFormat('MMM d').format(_customRange!.end)}'
                              : 'Custom Range...',
                          icon: LucideIcons.calendar,
                          isSelected: _dateFilter == QuickDateFilter.customRange,
                          onTap: _selectCustomDateRange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Section 2: CATEGORY
                    _buildSectionHeader('CATEGORY'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip(
                          label: 'All Categories',
                          icon: LucideIcons.tag,
                          isSelected: _category == null || _category == 'all',
                          onTap: () => setState(() => _category = null),
                        ),
                        ...[
                          'food',
                          'transport',
                          'shopping',
                          'bills',
                          'entertainment',
                          'health',
                          'other',
                        ].map((cat) {
                          final isSel = _category == cat;
                          final catName = cat[0].toUpperCase() + cat.substring(1);
                          return _buildChoiceChip(
                            label: catName,
                            icon: TransactionListItem.getCategoryIcon(cat),
                            isSelected: isSel,
                            onTap: () => setState(() => _category = cat),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Section 3: PAYMENT METHOD
                    _buildSectionHeader('PAYMENT METHOD'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip(
                          label: 'All Methods',
                          icon: LucideIcons.creditCard,
                          isSelected: _paymentMethod == null || _paymentMethod == 'all',
                          onTap: () => setState(() => _paymentMethod = null),
                        ),
                        ...[
                          'upi',
                          'credit_card',
                          'debit_card',
                          'cash',
                          'bank_transfer',
                        ].map((m) {
                          final isSel = _paymentMethod == m;
                          return _buildChoiceChip(
                            label: ExpenseFilterBar._formatPaymentMethodName(m),
                            isSelected: isSel,
                            onTap: () => setState(() => _paymentMethod = m),
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Section 4: AMOUNT RANGE
                    _buildSectionHeader('AMOUNT RANGE'),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildChoiceChip(
                          label: 'All Amounts',
                          isSelected: _amountRange == AmountFilterRange.all,
                          onTap: () => setState(
                              () => _amountRange = AmountFilterRange.all),
                        ),
                        _buildChoiceChip(
                          label: '< ₹500',
                          isSelected: _amountRange == AmountFilterRange.under500,
                          onTap: () => setState(
                              () => _amountRange = AmountFilterRange.under500),
                        ),
                        _buildChoiceChip(
                          label: '₹500 – ₹2,000',
                          isSelected:
                              _amountRange == AmountFilterRange.between500And2000,
                          onTap: () => setState(() => _amountRange =
                              AmountFilterRange.between500And2000),
                        ),
                        _buildChoiceChip(
                          label: '> ₹2,000',
                          isSelected: _amountRange == AmountFilterRange.above2000,
                          onTap: () => setState(
                              () => _amountRange = AmountFilterRange.above2000),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions Bar (Reset & Apply)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF080E1C),
                border: Border(
                  top: BorderSide(color: Color(0xFF172A46), width: 1),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: PressableScale(
                      scaleFactor: 0.96,
                      onTap: _resetLocalFilters,
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _borderIdle),
                        ),
                        child: const Text(
                          'Reset',
                          style: TextStyle(
                            color: _textDim,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: PressableScale(
                      scaleFactor: 0.96,
                      onTap: () {
                        final updated = widget.initialState.copyWith(
                          dateFilter: _dateFilter,
                          customDateRange: _customRange,
                          category: _category,
                          paymentMethod: _paymentMethod,
                          amountRange: _amountRange,
                          clearCustomDateRange:
                              _dateFilter != QuickDateFilter.customRange,
                        );
                        widget.onApply(updated);
                      },
                      child: Container(
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _focusFlowBlue,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _focusFlowBlue.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text(
                          'Apply Filters',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: _textDim,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _buildChoiceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return PressableScale(
      scaleFactor: 0.96,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _focusFlowBlue : _cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _focusFlowBlue : _borderIdle,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _focusFlowBlue.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
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
                color: isSelected ? Colors.white : _textDim,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
