import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/ocean_theme.dart';
import '../../core/widgets/custom_bottom_sheet.dart';
import '../../core/widgets/money_empty_state.dart';
import '../../models/expense.dart';
import '../../providers/money_provider.dart';
import 'add_expense_sheet.dart';
import 'set_budget_sheet.dart';
import 'widgets/financial_balance_card.dart';
import 'widgets/transaction_list_item.dart';

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _entranceController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  double? _lastAddedAmount;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: OceanTheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.center,
              labelPadding: const EdgeInsets.symmetric(horizontal: 14),
              indicator: BoxDecoration(
                color: OceanTheme.cardHi,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.6),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.16),
                    blurRadius: 8,
                  ),
                ],
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textDim,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
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
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: TabBarView(
              controller: _tabController,
              physics: const BouncingScrollPhysics(),
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

          // Daily Spending Trend Chart
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text(
                'SPENDING TREND (THIS MONTH)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDim,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            constraints: const BoxConstraints(minHeight: 180),
            decoration: BoxDecoration(
              color: OceanTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: summary.dailyChartData.isEmpty
                ? const MoneyEmptyState(
                    icon: LucideIcons.barChart3,
                    title: 'No spending trend yet',
                    description: 'Log your expenses to see daily spending patterns over time.',
                    accentColor: AppColors.primary,
                    minHeight: 180,
                  )
                : Container(
                    height: 180,
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                    child: LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: summary.dailyChartData.asMap().entries.map((e) {
                              return FlSpot(
                                e.key.toDouble(),
                                (e.value['amount'] as double),
                              );
                            }).toList(),
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: AppColors.primary,
                            barWidth: 2.8,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.primary.withValues(alpha: 0.22),
                                  AppColors.primary.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
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
                  onDelete: () {
                    ref.read(expensesProvider.notifier).deleteExpense(expense.id);
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
                final amt = item['amount'] as double;
                final pct = item['percentage'] as int;
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

// 2. EXPENSES TAB (FULL TRANSACTIONS)
class _ExpensesTab extends ConsumerWidget {
  final VoidCallback onAddTap;

  const _ExpensesTab({required this.onAddTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesProvider);
    final expenses = expensesAsync.value ?? [];
    final searchQuery = ref.watch(expenseSearchProvider);

    List<Expense> filtered = expenses;
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      filtered = filtered.where((e) {
        return e.description.toLowerCase().contains(q) ||
            e.category.toLowerCase().contains(q) ||
            (e.note ?? '').toLowerCase().contains(q);
      }).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: TextField(
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search expenses by description or category...',
              hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13),
              prefixIcon: const Icon(LucideIcons.search, color: AppColors.textDim, size: 18),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, color: AppColors.textDim, size: 16),
                      onPressed: () => ref.read(expenseSearchProvider.notifier).state = '',
                    )
                  : null,
              filled: true,
              fillColor: OceanTheme.card,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.6)),
              ),
            ),
            onChanged: (v) => ref.read(expenseSearchProvider.notifier).state = v,
          ),
        ),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            MoneyEmptyState(
                              icon: LucideIcons.receipt,
                              title: searchQuery.isNotEmpty
                                  ? 'No matching expenses'
                                  : 'No expenses logged yet',
                              description: searchQuery.isNotEmpty
                                  ? 'Try searching with a different keyword.'
                                  : 'Tap + Add Expense to track your spending.',
                              accentColor: AppColors.primary,
                              minHeight: 180,
                              showGrid: false,
                            ),
                            if (searchQuery.isEmpty) ...[
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: onAddTap,
                                icon: const Icon(LucideIcons.plus, size: 16),
                                label: const Text('Add Expense'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: OceanTheme.bg,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ],
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
                            try {
                              await ref.read(expensesProvider.notifier).deleteExpense(expense.id);
                            } catch (_) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Couldn't delete expense. Restored."),
                                    backgroundColor: AppColors.error,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
        ),
      ],
    );
  }
}

// 3. CATEGORIES TAB
class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: OceanTheme.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(catIcon, color: catColor, size: 18),
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
              Text(
                currency.format(amount),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
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
