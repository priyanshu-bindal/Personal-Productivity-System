import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ocean_theme.dart';
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
    final summary = ref.watch(moneySummaryProvider);
    final expensesAsync = ref.watch(expensesProvider);
    final expenses = expensesAsync.value ?? [];
    final hasOptimistic = expenses.any((e) => e.isOptimistic);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

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
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasOptimistic
                                ? AppColors.accentAmber
                                : AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'THIS MONTH\'S SPENDING',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                      ],
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
                const SizedBox(height: 14),

                // Focal Animated Amount
                AnimatedBalanceTicker(
                  amount: summary.monthTotal,
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.8,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 20),

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
                      Expanded(
                        child: _MetricItem(
                          icon: LucideIcons.calendar,
                          iconColor: AppColors.primary,
                          label: "Today's Outflow",
                          value: currency.format(summary.todayTotal),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: AppColors.border.withValues(alpha: 0.7),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: _MetricItem(
                            icon: LucideIcons.trendingUp,
                            iconColor: AppColors.secondary,
                            label: 'Daily Average',
                            value: currency.format(summary.avgDaily),
                          ),
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 28,
                        color: AppColors.border.withValues(alpha: 0.7),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: _MetricItem(
                            icon: LucideIcons.pieChart,
                            iconColor: AppColors.accentAmber,
                            label: 'Top Category',
                            value: summary.highestCategory,
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
}

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _MetricItem({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
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
      ],
    );
  }
}
