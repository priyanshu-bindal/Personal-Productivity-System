import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ocean_theme.dart';
import '../../../core/theme/oled_theme.dart';
import '../../../providers/money_provider.dart';
import 'animated_balance_ticker.dart';
import 'floating_amount_indicator.dart';

class FinancialBalanceCard extends ConsumerWidget {
  final double? floatingAmount;
  final VoidCallback? onFloatingComplete;

  const FinancialBalanceCard({
    super.key,
    this.floatingAmount,
    this.onFloatingComplete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analytics = ref.watch(monthlyAnalyticsProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final expenses = expensesAsync.value ?? [];
    final hasOptimistic = expenses.any((e) => e.isOptimistic);
    final currency =
        NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    // Title based on month context
    final String cardTitle;
    if (analytics.isCurrentMonth) {
      cardTitle = "THIS MONTH'S SPENDING";
    } else if (analytics.isFutureMonth) {
      final monthName =
          DateFormat('MMMM yyyy').format(analytics.selectedMonth).toUpperCase();
      cardTitle = "$monthName • FUTURE BUDGET";
    } else {
      final monthName =
          DateFormat('MMMM yyyy').format(analytics.selectedMonth).toUpperCase();
      cardTitle = "$monthName SPENDING";
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: OceanTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasOptimistic
              ? AppColors.primary.withValues(alpha: 0.45)
              : AppColors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
          if (hasOptimistic)
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            OceanTheme.cardHi.withValues(alpha: 0.95),
            OceanTheme.card,
          ],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Label & Status Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: hasOptimistic
                                  ? AppColors.accentAmber
                                  : (analytics.isCurrentMonth
                                      ? OledTheme.electricBlue
                                      : OledTheme.violet),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 200),
                              child: Text(
                                cardTitle,
                                key: ValueKey(cardTitle),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: hasOptimistic
                          ? Row(
                              key: const ValueKey('syncing'),
                              children: [
                                SizedBox(
                                  width: 11,
                                  height: 11,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.8,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.accentAmber.withValues(alpha: 0.8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Syncing...',
                                  style: TextStyle(
                                    color: AppColors.accentAmber,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              key: const ValueKey('confirmed'),
                              children: const [
                                Icon(
                                  LucideIcons.check,
                                  color: AppColors.primary,
                                  size: 13,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Updated',
                                  style: TextStyle(
                                    color: AppColors.textDim,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Focal Animated Amount
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedBalanceTicker(
                      amount: analytics.totalExpense,
                      style: const TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.8,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Month-over-Month Comparison Pill
                _buildComparisonPill(analytics, currency),
                const SizedBox(height: 18),

                // Supporting Financial Metrics Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: OceanTheme.bg.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.border.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Metric 1: Daily Average
                      Expanded(
                        child: _MetricItem(
                          icon: LucideIcons.trendingUp,
                          iconColor: OledTheme.cyan,
                          label: 'Daily Average',
                          value: currency.format(analytics.avgDailySpending),
                          sublabel: analytics.isFutureMonth
                              ? '0 days'
                              : (analytics.isCurrentMonth
                                  ? 'Day ${analytics.elapsedDays} of ${analytics.daysInMonth}'
                                  : 'Full ${analytics.daysInMonth} days'),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppColors.border.withValues(alpha: 0.7),
                      ),
                      // Metric 2: Transactions
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: _MetricItem(
                            icon: LucideIcons.receipt,
                            iconColor: OledTheme.violet,
                            label: 'Transactions',
                            value: '${analytics.transactionCount}',
                            sublabel: 'expenses logged',
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 32,
                        color: AppColors.border.withValues(alpha: 0.7),
                      ),
                      // Metric 3: Top Category
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: _MetricItem(
                            icon: LucideIcons.pieChart,
                            iconColor: OledTheme.amber,
                            label: 'Top Category',
                            value: analytics.highestCategory,
                            sublabel: analytics.highestCategoryAmount > 0
                                ? currency.format(analytics.highestCategoryAmount)
                                : 'No spending',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Floating Amount Confirmation Pill
          if (floatingAmount != null && floatingAmount! > 0)
            Positioned(
              top: 14,
              right: 20,
              child: FloatingAmountIndicator(
                amount: floatingAmount!,
                isExpense: true,
                onComplete: onFloatingComplete,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonPill(MonthlyAnalytics analytics, NumberFormat currency) {
    if (analytics.isFutureMonth) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: OledTheme.amber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: OledTheme.amber.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: const Text(
          'Future Month • No actual spending recorded',
          style: TextStyle(
            color: OledTheme.amber,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (!analytics.hasPreviousMonthData && analytics.previousMonthTotal == 0) {
      if (analytics.totalExpense == 0) {
        return const SizedBox.shrink();
      }
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.textDim.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'First recorded spending period',
          style: TextStyle(
            color: AppColors.textDim,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final diff = analytics.differenceFromPreviousMonth;
    final pct = analytics.percentageChangeFromPreviousMonth.abs().toStringAsFixed(1);
    final isIncrease = diff > 0;
    final isDecrease = diff < 0;

    final Color badgeColor;
    final IconData icon;
    final String text;

    if (isIncrease) {
      badgeColor = OledTheme.coral;
      icon = LucideIcons.trendingUp;
      text = '+${currency.format(diff.abs())} (+$pct%) vs last month';
    } else if (isDecrease) {
      badgeColor = OledTheme.emerald;
      icon = LucideIcons.trendingDown;
      text = '-${currency.format(diff.abs())} (-$pct%) vs last month';
    } else {
      badgeColor = AppColors.textDim;
      icon = LucideIcons.minus;
      text = 'Same as previous month';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: badgeColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? sublabel;

  const _MetricItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: iconColor),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (sublabel != null) ...[
          const SizedBox(height: 1),
          Text(
            sublabel!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textDim,
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }
}
