import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/animated_card.dart';
import '../../core/widgets/custom_bottom_sheet.dart';
import '../../core/widgets/money_empty_state.dart';
import '../../core/widgets/traffic_loader.dart';
import '../../models/expense.dart';
import '../../providers/money_provider.dart';
import 'add_expense_sheet.dart';
import 'set_budget_sheet.dart';

class MoneyScreen extends ConsumerWidget {
  const MoneyScreen({super.key});

  void _openAddExpenseModal(BuildContext context, WidgetRef ref) async {
    final result = await CustomBottomSheet.show<Map<String, dynamic>>(
      context: context,
      title: 'Add New Expense',
      subtitle: 'Log your personal spending',
      child: const AddExpenseSheet(),
    );

    if (result != null) {
      ref.read(expensesProvider.notifier).addExpense(
            amount: result['amount'] as double,
            description: result['description'] as String,
            category: result['category'] as String,
            paymentMethod: result['paymentMethod'] as String,
            date: result['date'] as DateTime,
            note: result['note'] as String?,
          );
    }
  }

  void _openSetBudgetModal(BuildContext context, WidgetRef ref) async {
    final result = await CustomBottomSheet.show<Map<String, dynamic>>(
      context: context,
      title: 'Set Category Budget',
      subtitle: 'Limit monthly spending for a category',
      child: const SetBudgetSheet(),
    );

    if (result != null) {
      ref.read(budgetsProvider.notifier).setBudget(
            category: result['category'] as String,
            monthlyLimit: result['monthlyLimit'] as double,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Personal Expenses',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.plus, color: AppColors.primary),
              onPressed: () => _openAddExpenseModal(context, ref),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(48),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  color: AppColors.cardHi,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 10,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: AppColors.textPrimary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 13),
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Expenses'),
                  Tab(text: 'Categories'),
                  Tab(text: 'Budgets'),
                ],
              ),
            ),
          ),
        ),
        body: const SafeArea(
          child: TabBarView(
            physics: BouncingScrollPhysics(),
            children: [
              _OverviewTab(),
              _ExpensesTab(),
              _CategoriesTab(),
              _BudgetsTab(),
            ],
          ),
        ),
      ),
    );
  }
}

// 1. OVERVIEW TAB
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(moneySummaryProvider);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _MoneyStatCard(
                  label: "Today's Spending",
                  value: currency.format(summary.todayTotal),
                  icon: LucideIcons.calendar,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MoneyStatCard(
                  label: 'This Month',
                  value: currency.format(summary.monthTotal),
                  icon: LucideIcons.wallet,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MoneyStatCard(
                  label: 'Average Daily',
                  value: currency.format(summary.avgDaily),
                  icon: LucideIcons.trendingUp,
                  color: AppColors.accentCyan,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MoneyStatCard(
                  label: 'Highest Category',
                  value: summary.highestCategory,
                  icon: LucideIcons.pieChart,
                  color: AppColors.accentAmber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          const Text(
            'DAILY SPENDING TREND (THIS MONTH)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(minHeight: 180),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: summary.dailyChartData.isEmpty
                ? const MoneyEmptyState(
                    icon: LucideIcons.barChart3,
                    title: 'No spending data yet',
                    description: 'Start tracking your expenses to see your daily spending trends.',
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
                              return FlSpot(e.key.toDouble(), (e.value['amount'] as double));
                            }).toList(),
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primary.withValues(alpha: 0.15),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 28),

          const Text(
            'CATEGORY DISTRIBUTION',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          if (summary.categoryBreakdown.isEmpty)
            const MoneyEmptyState(
              icon: LucideIcons.pieChart,
              title: 'Your spending breakdown will appear here',
              description: 'Add your first expense and we\'ll automatically organize your spending by category.',
              accentColor: AppColors.secondary,
              minHeight: 160,
            )
          else
            Column(
              children: summary.categoryBreakdown.map((item) {
                final cat = item['category'] as String;
                final amt = item['amount'] as double;
                final pct = item['percentage'] as int;
                final catName = cat[0].toUpperCase() + cat.substring(1);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(catName, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                      Row(
                        children: [
                          Text('$pct%', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(width: 12),
                          Text(currency.format(amt), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ],
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

// 2. EXPENSES TAB
class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab();

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

    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: TextField(
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search expenses by description, category...',
              prefixIcon: const Icon(LucideIcons.search, color: AppColors.textMuted, size: 20),
              suffixIcon: searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(LucideIcons.x, color: AppColors.textMuted, size: 18),
                      onPressed: () => ref.read(expenseSearchProvider.notifier).state = '',
                    )
                  : null,
            ),
            onChanged: (v) => ref.read(expenseSearchProvider.notifier).state = v,
          ),
        ),
        Expanded(
          child: expensesAsync.isLoading && filtered.isEmpty
              ? const Center(child: TrafficLoader(message: 'Loading expenses...'))
              : filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: MoneyEmptyState(
                        icon: LucideIcons.receipt,
                        title: 'No expenses logged yet',
                        description: 'Log your spending to keep track of your personal budget.',
                        accentColor: AppColors.primary,
                        minHeight: 200,
                        showGrid: false,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final e = filtered[index];
                        final catName = e.category[0].toUpperCase() + e.category.substring(1);
                        final dateStr = DateFormat('MMM d, yyyy').format(DateTime.parse(e.expenseDate));

                        return AnimatedCard(
                          index: index,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accentRose.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(LucideIcons.arrowUpRight, color: AppColors.accentRose, size: 20),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.description,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '$catName • $dateStr',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    currency.format(e.amount),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.accentRose,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(LucideIcons.trash2, color: AppColors.textMuted, size: 16),
                                    onPressed: () {
                                      ref.read(expensesProvider.notifier).deleteExpense(e.id);
                                    },
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ],
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

// 3. CATEGORIES TAB
class _CategoriesTab extends ConsumerWidget {
  const _CategoriesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);
    final summary = ref.watch(moneySummaryProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: AppConstants.expenseCategories.length,
      itemBuilder: (context, index) {
        final catKey = AppConstants.expenseCategories[index];
        final catName = catKey[0].toUpperCase() + catKey.substring(1);

        final catItem = summary.categoryBreakdown
            .where((item) => (item['category'] as String).toLowerCase() == catKey)
            .firstOrNull;

        final amount = (catItem?['amount'] as num?)?.toDouble() ?? 0.0;
        final pct = (catItem?['percentage'] as num?)?.toInt() ?? 0;

        return AnimatedCard(
          index: index,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(LucideIcons.tag, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        catName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$pct% of month total',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                currency.format(amount),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
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
  const _BudgetsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final budgets = budgetsAsync.value ?? [];
    final summary = ref.watch(moneySummaryProvider);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MONTHLY BUDGET LIMITS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  final parent = context.findAncestorWidgetOfExactType<MoneyScreen>();
                  if (parent != null) {
                    parent._openSetBudgetModal(context, ref);
                  }
                },
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Set Budget'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
                    description: 'Set monthly spending limits for categories to manage your budget.',
                    accentColor: AppColors.secondary,
                    minHeight: 200,
                    showGrid: false,
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    final b = budgets[index];
                    final catName = b.category[0].toUpperCase() + b.category.substring(1);

                    final catItem = summary.categoryBreakdown
                        .where((item) => (item['category'] as String).toLowerCase() == b.category.toLowerCase())
                        .firstOrNull;
                    final spent = (catItem?['amount'] as num?)?.toDouble() ?? 0.0;
                    final pct = (spent / b.monthlyLimit * 100).clamp(0, 100).round();
                    final progressVal = (spent / b.monthlyLimit).clamp(0.0, 1.0);

                    return AnimatedCard(
                      index: index,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                catName,
                                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.trash2, color: AppColors.textMuted, size: 16),
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
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                              Text(
                                '${currency.format(b.monthlyLimit)} budget',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: progressVal,
                              minHeight: 8,
                              backgroundColor: AppColors.surface,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                pct > 90 ? AppColors.accentRose : (pct > 70 ? AppColors.accentAmber : AppColors.primary),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '$pct% used',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: pct > 90 ? AppColors.accentRose : AppColors.textSecondary,
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

class _MoneyStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MoneyStatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
