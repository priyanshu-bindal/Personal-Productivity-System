import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/ocean_theme.dart';
import '../../core/widgets/custom_bottom_sheet.dart';
import '../../core/widgets/money_empty_state.dart';
import '../../providers/money_provider.dart';
import 'add_expense_sheet.dart';
import 'widgets/transaction_list_item.dart';

class CategoryTransactionsScreen extends ConsumerStatefulWidget {
  final String category;

  const CategoryTransactionsScreen({
    super.key,
    required this.category,
  });

  @override
  ConsumerState<CategoryTransactionsScreen> createState() =>
      _CategoryTransactionsScreenState();
}

class _CategoryTransactionsScreenState
    extends ConsumerState<CategoryTransactionsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final List<Animation<double>> _staggeredAnimations;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );

    // Pre-create staggered interval animations once in initState to avoid
    // allocating new CurvedAnimation and Interval objects during build ticks.
    _staggeredAnimations = List.generate(8, (index) {
      final start = (index * 0.06).clamp(0.0, 0.7);
      final end = (start + 0.35).clamp(0.0, 1.0);
      return CurvedAnimation(
        parent: _entranceController,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      );
    });

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _openAddExpenseModal(String normalizedCat) async {
    final catName = normalizedCat.isNotEmpty
        ? normalizedCat[0].toUpperCase() + normalizedCat.substring(1)
        : 'Expense';

    final messenger = ScaffoldMessenger.of(context);

    final result = await CustomBottomSheet.show<Map<String, dynamic>>(
      context: context,
      title: 'Add $catName Expense',
      subtitle: 'Log spending under $catName',
      child: AddExpenseSheet(initialCategory: normalizedCat),
    );

    if (result != null && mounted) {
      final amt = result['amount'] as double;
      final desc = result['description'] as String;
      final cat = result['category'] as String;
      final method = result['paymentMethod'] as String;
      final date = result['date'] as DateTime;
      final note = result['note'] as String?;

      try {
        await ref.read(expensesProvider.notifier).addExpense(
              amount: amt,
              description: desc,
              category: cat,
              paymentMethod: method,
              date: date,
              note: note,
            );
      } catch (e) {
        if (!mounted) return;
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Couldn't add expense. Please try again."),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildStaggeredItem(Widget child, int index) {
    // If the entrance animation has completed or the item is scrolled far down,
    // bypass the animation tree entirely for optimal 60/120 FPS scrolling.
    if (_entranceController.isCompleted ||
        index >= _staggeredAnimations.length) {
      return child;
    }

    final animation = _staggeredAnimations[index];
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, (1.0 - animation.value) * 14),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final normalizedCat =
        Uri.decodeComponent(widget.category).trim().toLowerCase();
    final catName = normalizedCat.isNotEmpty
        ? normalizedCat[0].toUpperCase() + normalizedCat.substring(1)
        : 'Category';
    final catColor = TransactionListItem.getCategoryColor(normalizedCat);
    final catIcon = TransactionListItem.getCategoryIcon(normalizedCat);
    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    final summary = ref.watch(moneySummaryProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final allExpenses = expensesAsync.value ?? [];

    // Filter transactions strictly for this category from existing provider state
    final categoryExpenses = allExpenses
        .where((e) => e.category.toLowerCase() == normalizedCat)
        .toList();

    // Sort by newest date first; for multiple transactions on the same date, sort by createdAt descending
    categoryExpenses.sort((a, b) {
      final dateComp = b.expenseDate.compareTo(a.expenseDate);
      if (dateComp != 0) return dateComp;
      return b.createdAt.compareTo(a.createdAt);
    });

    // Current month's spend and percentage for this category
    final catItem = summary.categoryBreakdown
        .where((item) =>
            (item['category'] as String).toLowerCase() == normalizedCat)
        .firstOrNull;
    final monthlySpend = (catItem?['amount'] as num?)?.toDouble() ?? 0.0;
    final monthlyPercentage = (catItem?['percentage'] as num?)?.toInt() ?? 0;

    return Scaffold(
      backgroundColor: OceanTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(
          catName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppColors.primary, size: 20),
            tooltip: 'Add $catName Expense',
            onPressed: () => _openAddExpenseModal(normalizedCat),
          ),
        ],
      ),
      body: Container(
        decoration: OceanTheme.backgroundGradientDecoration,
        child: SafeArea(
          top: false,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // 1. Header Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: OceanTheme.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          catColor.withValues(alpha: 0.14),
                          OceanTheme.card,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                        BoxShadow(
                          color: catColor.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Hero(
                              tag: 'category_icon_$normalizedCat',
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.16),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: catColor.withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                ),
                                child: Icon(catIcon, color: catColor, size: 24),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    catName,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: catColor.withValues(alpha: 0.15),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                          border: Border.all(
                                            color:
                                                catColor.withValues(alpha: 0.3),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          '$monthlyPercentage% of month total',
                                          style: TextStyle(
                                            color: catColor,
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${categoryExpenses.length} ${categoryExpenses.length == 1 ? 'transaction' : 'transactions'}',
                                        style: const TextStyle(
                                          color: AppColors.textDim,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 1,
                          color: AppColors.border.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            const Text(
                              'MONTHLY SPENDING',
                              style: TextStyle(
                                color: AppColors.textDim,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                            Text(
                              currency.format(monthlySpend),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Section Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TRANSACTIONS (${categoryExpenses.length})',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDim,
                          letterSpacing: 1.1,
                        ),
                      ),
                      if (categoryExpenses.isNotEmpty)
                        const Text(
                          'Newest first',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textDim,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // 3. Transactions List or Polished Empty State
              if (categoryExpenses.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
                    child: MoneyEmptyState(
                      icon: catIcon,
                      title: 'No $catName transactions yet',
                      description:
                          'Expenses logged under $catName will automatically appear here.',
                      accentColor: catColor,
                      minHeight: 200,
                      showGrid: false,
                      action: ElevatedButton.icon(
                        onPressed: () =>
                            _openAddExpenseModal(normalizedCat),
                        icon: const Icon(LucideIcons.plus, size: 16),
                        label: Text('Add $catName Expense'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: catColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList.builder(
                    itemCount: categoryExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = categoryExpenses[index];
                      final itemWidget = TransactionListItem(
                        key: ValueKey(expense.id),
                        expense: expense,
                        animateEntrance: expense.isOptimistic,
                        showNote: true,
                        onDelete: () async {
                          try {
                            await ref
                                .read(expensesProvider.notifier)
                                .deleteExpense(expense.id);
                          } catch (_) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text("Couldn't delete expense. Restored."),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                      );

                      return _buildStaggeredItem(itemWidget, index);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
