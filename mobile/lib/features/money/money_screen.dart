import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';


import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/ocean_theme.dart';
import '../../core/widgets/custom_bottom_sheet.dart';
import '../../core/widgets/money_empty_state.dart';
import '../../models/expense.dart';
import '../../providers/money_provider.dart';
import '../../providers/trash_provider.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/trash_confirmation_overlay.dart';
import 'add_expense_sheet.dart';
import 'category_transactions_screen.dart';
import 'models/expense_filter_state.dart';
import 'set_budget_sheet.dart';
import 'widgets/expense_filter_bar.dart';
import 'widgets/financial_balance_card.dart';
import 'widgets/money_pdf_export_dialog.dart';
import 'widgets/spending_trend_chart.dart';
import 'widgets/transaction_list_item.dart';

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  double? _lastAddedAmount;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      animationDuration: const Duration(milliseconds: 250),
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _openAddExpenseModal() async {
    final result = await CustomBottomSheet.show<Map<String, dynamic>>(
      context: context,
      title: 'Add Expense',
      subtitle: 'Log spending into your financial record',
      child: const AddExpenseSheet(),
    );

    // Ensure no focus restoration happens automatically after modal closes
    FocusManager.instance.primaryFocus?.unfocus();

    if (result != null && mounted) {
      final amt = result['amount'] as double;

      // 1. Immediately trigger the floating amount confirmation animation
      setState(() {
        _lastAddedAmount = amt;
      });

      // 2. Perform optimistic addition
      try {
        await ref.read(expensesProvider.notifier).addExpense(
              amount: amt,
              description: result['description'] as String,
              category: result['category'] as String,
              paymentMethod: result['paymentMethod'] as String,
              date: result['date'] as DateTime,
              note: result['note'] as String?,
            );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't add expense. Please try again."),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openSetBudgetModal() async {
    final result = await CustomBottomSheet.show<Map<String, dynamic>>(
      context: context,
      title: 'Set Category Budget',
      subtitle: 'Limit monthly spending for a category',
      child: const SetBudgetSheet(),
    );

    if (result != null) {
      try {
        await ref.read(budgetsProvider.notifier).setBudget(
              category: result['category'] as String,
              monthlyLimit: result['monthlyLimit'] as double,
            );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't set budget. Please try again."),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: OceanTheme.bg,
      appBar: AppBar(
        backgroundColor: OceanTheme.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Personal Finance',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 19,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: AppColors.textSecondary, size: 20),
            tooltip: 'Trash',
            onPressed: () => context.push('/money/trash'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _openAddExpenseModal,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(LucideIcons.plus, color: AppColors.primary, size: 15),
                    SizedBox(width: 4),
                    Text(
                      'Add',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _MoneyTabBar(controller: _tabController),
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: TabBarView(
              controller: _tabController,
              physics: const ClampingScrollPhysics(),
              children: [
                _KeepAliveTab(
                  child: _OverviewTab(
                    floatingAmount: _lastAddedAmount,
                    onFloatingComplete: () {
                      if (mounted) setState(() => _lastAddedAmount = null);
                    },
                    onAddTap: _openAddExpenseModal,
                    onSetBudgetTap: _openSetBudgetModal,
                    onViewAllExpensesTap: () => _tabController.animateTo(1),
                  ),
                ),
                _KeepAliveTab(
                  child: _ExpensesTab(
                    onAddTap: _openAddExpenseModal,
                  ),
                ),
                const _KeepAliveTab(
                  child: _CategoriesTab(),
                ),
                _KeepAliveTab(
                  child: _BudgetsTab(
                    onSetBudgetTap: _openSetBudgetModal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KeepAliveTab extends StatefulWidget {
  final Widget child;
  const _KeepAliveTab({required this.child});

  @override
  State<_KeepAliveTab> createState() => _KeepAliveTabState();
}

class _KeepAliveTabState extends State<_KeepAliveTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

// 1. OVERVIEW TAB
class _OverviewTab extends ConsumerWidget {
  final double? floatingAmount;
  final VoidCallback? onFloatingComplete;
  final VoidCallback onAddTap;
  final VoidCallback onSetBudgetTap;
  final VoidCallback onViewAllExpensesTap;

  const _OverviewTab({
    this.floatingAmount,
    this.onFloatingComplete,
    required this.onAddTap,
    required this.onSetBudgetTap,
    required this.onViewAllExpensesTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(moneySummaryProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final expenses = expensesAsync.value ?? [];
    final recentExpenses = expenses.take(3).toList();
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Financial Balance Card
          FinancialBalanceCard(
            floatingAmount: floatingAmount,
            onFloatingComplete: onFloatingComplete,
          ),
          const SizedBox(height: 16),

          // Primary Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onAddTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: OceanTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(LucideIcons.plusCircle, color: AppColors.primary, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Add Expense',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: onSetBudgetTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: OceanTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.secondary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(LucideIcons.target, color: AppColors.secondary, size: 16),
                        SizedBox(width: 8),
                        Text(
                          'Set Budget',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Premium Spending Trend Chart
          const SpendingTrendChart(),
          const SizedBox(height: 24),

          // Recent Activity Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RECENT TRANSACTIONS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDim,
                  letterSpacing: 1.1,
                ),
              ),
              if (expenses.isNotEmpty)
                InkWell(
                  onTap: onViewAllExpensesTap,
                  child: Row(
                    children: const [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(LucideIcons.chevronRight, color: AppColors.primary, size: 14),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (recentExpenses.isEmpty)
            const MoneyEmptyState(
              icon: LucideIcons.receipt,
              title: 'No expenses logged yet',
              description: 'Tap + Add to record your first personal expense.',
              accentColor: AppColors.primary,
              minHeight: 140,
            )
          else
            Column(
              children: recentExpenses.map((expense) {
                return TransactionListItem(
                  key: ValueKey(expense.id),
                  expense: expense,
                  animateEntrance: expense.isOptimistic,
                  onDelete: () async {
                    final deletedItem = expense;
                    try {
                      await ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                      ref.invalidate(trashedExpensesProvider);
                      if (context.mounted) {
                        TrashConfirmationOverlay.show(
                          context: context,
                          message: 'Moved to Trash',
                          onUndo: () async {
                            await ref.read(expensesProvider.notifier).restoreExpense(deletedItem);
                            ref.invalidate(trashedExpensesProvider);
                          },
                        );
                      }
                    } catch (_) {
                      if (context.mounted) {
                        TrashConfirmationOverlay.showError(
                          context: context,
                          message: "Couldn't delete expense. Restored.",
                        );
                      }
                    }
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 16),

          // Category Distribution Preview
          const Text(
            'CATEGORY BREAKDOWN',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textDim,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          if (summary.categoryBreakdown.isEmpty)
            const MoneyEmptyState(
              icon: LucideIcons.pieChart,
              title: 'No category breakdown',
              description: 'Expenses will automatically organize by category.',
              accentColor: AppColors.secondary,
              minHeight: 140,
            )
          else
            Column(
              children: summary.categoryBreakdown.take(4).map((item) {
                final cat = item['category'] as String;
                final amt = (item['amount'] as num).toDouble();
                final pct = (item['percentage'] as num).toInt();
                final catName = cat[0].toUpperCase() + cat.substring(1);
                final catColor = TransactionListItem.getCategoryColor(cat);
                final catIcon = TransactionListItem.getCategoryIcon(cat);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: OceanTheme.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(catIcon, color: catColor, size: 16),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  catName,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  currency.format(amt),
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: (pct / 100.0).clamp(0.0, 1.0),
                                minHeight: 4,
                                backgroundColor: OceanTheme.bg,
                                valueColor: AlwaysStoppedAnimation<Color>(catColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

// ─── Native Isolated Search Field ──────────────────────────────────────────
class _ExpensesSearchField extends ConsumerStatefulWidget {
  const _ExpensesSearchField();

  @override
  ConsumerState<_ExpensesSearchField> createState() => _ExpensesSearchFieldState();
}

class _ExpensesSearchFieldState extends ConsumerState<_ExpensesSearchField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(expenseSearchProvider));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_isFocused != _focusNode.hasFocus) {
      setState(() => _isFocused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(expenseSearchProvider, (prev, next) {
      if (_controller.text != next) {
        _controller.text = next;
      }
    });

    final hasText = _controller.text.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      height: 42,
      decoration: BoxDecoration(
        color: const Color(0xFF0E1526),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _isFocused ? const Color(0xFF2F6BFF) : const Color(0xFF1B2B48),
          width: _isFocused ? 1.2 : 1.0,
        ),
        boxShadow: _isFocused
            ? const [
                BoxShadow(
                  color: Color(0x332F6BFF),
                  blurRadius: 8,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 12, right: 8),
            child: Icon(LucideIcons.search, size: 16, color: Color(0xFF7E93A8)),
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(
                color: Color(0xFFF1F5F9),
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                hintText: 'Search expenses...',
                hintStyle: TextStyle(
                  color: Color(0xFF5A6F8A),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (val) {
                ref.read(expenseSearchProvider.notifier).state = val;
                setState(() {});
              },
            ),
          ),
          if (hasText)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _controller.clear();
                ref.read(expenseSearchProvider.notifier).state = '';
                setState(() {});
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Icon(LucideIcons.x, size: 14, color: Color(0xFF7E93A8)),
              ),
            ),
        ],
      ),
    );
  }
}

// 2. EXPENSES TAB (FULL TRANSACTIONS)
class _ExpensesTab extends ConsumerWidget {
  final VoidCallback onAddTap;

  const _ExpensesTab({required this.onAddTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final expenses = expensesAsync.value ?? [];
    final searchQuery = ref.watch(expenseSearchProvider);
    final filterState = ref.watch(expenseFilterStateProvider);

    // Apply quick filters and search query
    final filtered = filterState.apply(expenses, searchQuery: searchQuery);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          // 1. Search Bar and Export PDF Action Row
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
            child: Row(
              children: [
                const Expanded(
                  child: _ExpensesSearchField(),
                ),
                const SizedBox(width: 10),
                // Compact Export PDF Action Button
                PressableScale(
                  scaleFactor: 0.95,
                  onTap: () {
                    MoneyPdfExportDialog.show(
                      context,
                      expenses: filtered,
                      filterState: filterState,
                    );
                  },
                  child: Container(
                    height: 42,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E1526),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF1B2B48)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18000000),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(LucideIcons.fileDown, color: Color(0xFF2F6BFF), size: 15),
                        SizedBox(width: 6),
                        Text(
                          'Export PDF',
                          style: TextStyle(
                            color: Color(0xFF2F6BFF),
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Quick Filters Bar
          const ExpenseFilterBar(),
          const SizedBox(height: 8),

          // 3. Transactions List or Contextual Empty State
          Expanded(
            child: expensesAsync.isLoading && filtered.isEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    itemCount: 5,
                    itemBuilder: (context, index) => _SkeletonTransactionItem(),
                  )
                : filtered.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Center(
                          child: _buildContextualEmptyState(
                            context: context,
                            ref: ref,
                            expenses: expenses,
                            searchQuery: searchQuery,
                            filterState: filterState,
                            onAddTap: onAddTap,
                          ),
                        ),
                      )
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final expense = filtered[index];
                          return TransactionListItem(
                            key: ValueKey(expense.id),
                            expense: expense,
                            animateEntrance: expense.isOptimistic,
                            onDelete: () async {
                              final deletedItem = expense;
                              try {
                                await ref
                                    .read(expensesProvider.notifier)
                                    .deleteExpense(expense.id);
                                ref.invalidate(trashedExpensesProvider);
                                if (context.mounted) {
                                  TrashConfirmationOverlay.show(
                                    context: context,
                                    message: 'Moved to Trash',
                                    onUndo: () async {
                                      await ref
                                          .read(expensesProvider.notifier)
                                          .restoreExpense(deletedItem);
                                      ref.invalidate(trashedExpensesProvider);
                                    },
                                  );
                                }
                              } catch (_) {
                                if (context.mounted) {
                                  TrashConfirmationOverlay.showError(
                                    context: context,
                                    message: "Couldn't delete expense. Restored.",
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  /// Builds polished contextual empty states depending on user state.
  static Widget _buildContextualEmptyState({
    required BuildContext context,
    required WidgetRef ref,
    required List<Expense> expenses,
    required String searchQuery,
    required ExpenseFilterState filterState,
    required VoidCallback onAddTap,
  }) {
    // Situation 1: No expenses logged at all
    if (expenses.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MoneyEmptyState(
            icon: LucideIcons.receipt,
            title: 'No expenses yet',
            description:
                'Start tracking your spending to understand where your money goes.',
            accentColor: Color(0xFF2F6BFF),
            minHeight: 180,
            showGrid: false,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAddTap,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F6BFF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      );
    }

    // Situation 3: No expenses for selected date period (when only date filter is active)
    final hasAttributeFilters =
        (filterState.category != null && filterState.category != 'all') ||
            (filterState.paymentMethod != null &&
                filterState.paymentMethod != 'all') ||
            filterState.amountRange != AmountFilterRange.all ||
            searchQuery.trim().isNotEmpty;

    if (!hasAttributeFilters && filterState.dateFilter != QuickDateFilter.all) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MoneyEmptyState(
            icon: LucideIcons.calendarX,
            title: 'Nothing recorded here',
            description: 'No expenses were recorded for this period.',
            accentColor: Color(0xFF2F6BFF),
            minHeight: 180,
            showGrid: false,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onAddTap,
            icon: const Icon(LucideIcons.plus, size: 16),
            label: const Text('Add Expense'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2F6BFF),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      );
    }

    // Situation 2: No results after filtering / searching
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MoneyEmptyState(
          icon: LucideIcons.searchX,
          title: 'No matching expenses',
          description: 'Try changing your filters or date range.',
          accentColor: Color(0xFF2F6BFF),
          minHeight: 180,
          showGrid: false,
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            ref.read(expenseSearchProvider.notifier).state = '';
            ref.read(expenseFilterStateProvider.notifier).state =
                filterState.reset();
          },
          icon: const Icon(LucideIcons.rotateCcw, size: 16),
          label: const Text('Clear Filters'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2F6BFF),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ],
    );
  }
}

// 3. CATEGORIES TAB
class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  void _openCategoryTransactions(BuildContext context, String catKey) {
    try {
      context.push('/money/category/$catKey');
    } catch (_) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              CategoryTransactionsScreen(category: catKey),
          transitionsBuilder:
              (context, animation, secondaryAnimation, child) {
            final curved = CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
              reverseCurve: Curves.easeInCubic,
            );
            return FadeTransition(
              opacity:
                  Tween<double>(begin: 0.0, end: 1.0).animate(curved),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.06, 0),
                  end: Offset.zero,
                ).animate(curved),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 220),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    final summary = ref.watch(moneySummaryProvider);

    // Helper to look up the spent amount for a given category key.
    double amountFor(String catKey) {
      final item = summary.categoryBreakdown
          .where((i) => (i['category'] as String).toLowerCase() == catKey)
          .firstOrNull;
      return (item?['amount'] as num?)?.toDouble() ?? 0.0;
    }

    // Stable descending sort: categories with equal amounts preserve their
    // original AppConstants.expenseCategories order.
    final sortedCategories = AppConstants.expenseCategories
        .asMap()
        .entries
        .toList()
      ..sort((a, b) {
          final diff = amountFor(b.value).compareTo(amountFor(a.value));
          if (diff != 0) return diff; // different amounts: higher first
          return a.key.compareTo(b.key); // same amount: keep original index order
        });

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: sortedCategories.length,
      itemBuilder: (context, index) {
        final catKey = sortedCategories[index].value;
        final catName = catKey[0].toUpperCase() + catKey.substring(1);
        final catColor = TransactionListItem.getCategoryColor(catKey);
        final catIcon = TransactionListItem.getCategoryIcon(catKey);

        final catItem = summary.categoryBreakdown
            .where((item) => (item['category'] as String).toLowerCase() == catKey)
            .firstOrNull;

        final amount = (catItem?['amount'] as num?)?.toDouble() ?? 0.0;
        final pct = (catItem?['percentage'] as num?)?.toInt() ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: OceanTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => _openCategoryTransactions(context, catKey),
              splashColor: catColor.withValues(alpha: 0.12),
              highlightColor: catColor.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Hero(
                          tag: 'category_icon_$catKey',
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: catColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(catIcon, color: catColor, size: 18),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              catName,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$pct% of month total',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textDim,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currency.format(amount),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          LucideIcons.chevronRight,
                          color: AppColors.textFaint,
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// 4. BUDGETS TAB
class _BudgetsTab extends ConsumerWidget {
  final VoidCallback onSetBudgetTap;

  const _BudgetsTab({required this.onSetBudgetTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final budgets = budgetsAsync.value ?? [];
    final summary = ref.watch(moneySummaryProvider);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MONTHLY BUDGET LIMITS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDim,
                  letterSpacing: 1.1,
                ),
              ),
              ElevatedButton.icon(
                onPressed: onSetBudgetTap,
                icon: const Icon(LucideIcons.plus, size: 14),
                label: const Text('Set Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: OceanTheme.bg,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: budgets.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: MoneyEmptyState(
                    icon: LucideIcons.target,
                    title: 'No category budgets set',
                    description: 'Set monthly limits for categories to manage your personal budget.',
                    accentColor: AppColors.secondary,
                    minHeight: 200,
                    showGrid: false,
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final b = budgets[index];
                    final catName = b.category[0].toUpperCase() + b.category.substring(1);
                    final catColor = TransactionListItem.getCategoryColor(b.category);

                    final catItem = summary.categoryBreakdown
                        .where((item) =>
                            (item['category'] as String).toLowerCase() == b.category.toLowerCase())
                        .firstOrNull;
                    final spent = (catItem?['amount'] as num?)?.toDouble() ?? 0.0;
                    final pct = (spent / b.monthlyLimit * 100).clamp(0, 100).round();
                    final progressVal = (spent / b.monthlyLimit).clamp(0.0, 1.0);

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: OceanTheme.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                catName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, color: AppColors.textDim, size: 15),
                                onPressed: () {
                                  ref.read(budgetsProvider.notifier).deleteBudget(b.id);
                                },
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${currency.format(spent)} spent',
                                style: const TextStyle(fontSize: 13, color: AppColors.textDim),
                              ),
                              Text(
                                '${currency.format(b.monthlyLimit)} budget',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progressVal,
                              minHeight: 6,
                              backgroundColor: OceanTheme.bg,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pct > 90
                                    ? AppColors.accentRose
                                    : (pct > 70 ? AppColors.accentAmber : catColor),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$pct% used',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: pct > 90 ? AppColors.accentRose : AppColors.textDim,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Premium Money Tab Bar ──────────────────────────────────────────────────
// Uses a Stack + AnimatedPositioned sliding pill so there are ZERO rectangular
// artifacts and the indicator is always fully clipped by the outer capsule.
class _MoneyTabBar extends StatefulWidget {
  final TabController controller;

  const _MoneyTabBar({required this.controller});

  @override
  State<_MoneyTabBar> createState() => _MoneyTabBarState();
}

class _MoneyTabBarState extends State<_MoneyTabBar> {
  static const _tabs = ['Overview', 'Expenses', 'Categories', 'Budgets'];
  static const double _height = 40;
  static const double _pillVPad = 4;
  static const double _outerRadius = 24.0;
  static const double _pillRadius = 20.0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTabChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final tabWidth = totalWidth / _tabs.length;
                return SizedBox(
          height: _height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_outerRadius),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xE0080E1A),
                borderRadius: BorderRadius.circular(_outerRadius),
                border: Border.all(color: const Color(0xFF1A2E4A), width: 1),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x30000000),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedBuilder(
                animation: widget.controller.animation!,
                builder: (context, _) {
                  final anim = widget.controller.animation!.value;
                  final pillLeft = anim * tabWidth + _pillVPad;
                  final pillWidth = tabWidth - _pillVPad * 2;
                  return Stack(
                    children: [
                      // Sliding pill — lives inside the ClipRRect so always clipped
                      Positioned(
                        top: _pillVPad,
                        bottom: _pillVPad,
                        left: pillLeft,
                        width: pillWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0F1C36),
                            borderRadius: BorderRadius.circular(_pillRadius),
                            border: Border.all(
                              color: const Color(0xFF2F6BFF),
                              width: 1,
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x1F2F6BFF),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Tab labels
                      Row(
                        children: List.generate(_tabs.length, (i) {
                          // Compute interpolated selection weight for smooth colour transition
                          final distance = (anim - i).abs();
                          final weight = (1.0 - distance.clamp(0.0, 1.0));

                          final labelColor = Color.lerp(
                            const Color(0xFF7F91AA),
                            const Color(0xFFF1F5F9),
                            weight,
                          )!;
                          final fontWeight = weight > 0.5 ? FontWeight.w700 : FontWeight.w500;

                          return Expanded(
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.controller.animateTo(i),
                              child: Center(
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  style: TextStyle(
                                    color: labelColor,
                                    fontSize: 12.5,
                                    fontWeight: fontWeight,
                                    letterSpacing: -0.1,
                                  ),
                                  child: Text(
                                    _tabs[i],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SkeletonTransactionItem extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: OceanTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: OceanTheme.cardHi,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  decoration: BoxDecoration(
                    color: OceanTheme.cardHi,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 80,
                  height: 10,
                  decoration: BoxDecoration(
                    color: OceanTheme.cardHi,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 60,
            height: 16,
            decoration: BoxDecoration(
              color: OceanTheme.cardHi,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
