import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ocean_theme.dart';
import '../../../core/widgets/micro_interactions/animated_delete.dart';
import '../../../models/expense.dart';

class TransactionListItem extends StatelessWidget {
  final Expense expense;
  final VoidCallback? onDelete;
  final bool animateEntrance;
  final bool showNote;

  const TransactionListItem({
    super.key,
    required this.expense,
    this.onDelete,
    this.animateEntrance = false,
    this.showNote = true,
  });

  static IconData getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return LucideIcons.utensils;
      case 'transport':
        return LucideIcons.car;
      case 'shopping':
        return LucideIcons.shoppingBag;
      case 'education':
        return LucideIcons.bookOpen;
      case 'entertainment':
        return LucideIcons.film;
      case 'bills':
        return LucideIcons.receipt;
      case 'health':
        return LucideIcons.heartPulse;
      case 'travel':
        return LucideIcons.plane;
      case 'personal':
        return LucideIcons.user;
      case 'subscriptions':
        return LucideIcons.repeat;
      case 'family':
        return LucideIcons.users;
      default:
        return LucideIcons.tag;
    }
  }

  static Color getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return AppColors.accentAmber;
      case 'transport':
        return AppColors.secondary;
      case 'shopping':
        return const Color(0xFFEC4899);
      case 'education':
        return AppColors.primary;
      case 'entertainment':
        return const Color(0xFFA855F7);
      case 'bills':
        return AppColors.accentRose;
      case 'health':
        return const Color(0xFF10B981);
      case 'travel':
        return const Color(0xFF06B6D4);
      case 'personal':
        return const Color(0xFF8B5CF6);
      case 'subscriptions':
        return const Color(0xFFF97316);
      case 'family':
        return const Color(0xFF14B8A6);
      default:
        return AppColors.textDim;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');
    final catColor = getCategoryColor(expense.category);
    final catIcon = getCategoryIcon(expense.category);
    final catName = expense.category.isNotEmpty
        ? expense.category[0].toUpperCase() + expense.category.substring(1)
        : 'Expense';

    // Date formatting: "Today, 8:30 PM", "Yesterday", or "Sep 12, 2026"
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    String dateDisplay;
    if (expense.expenseDate == todayStr) {
      dateDisplay = 'Today';
    } else if (expense.expenseDate == yesterdayStr) {
      dateDisplay = 'Yesterday';
    } else {
      try {
        final parsed = DateTime.parse(expense.expenseDate);
        dateDisplay = DateFormat('MMM d, yyyy').format(parsed);
      } catch (_) {
        dateDisplay = expense.expenseDate;
      }
    }

    Widget buildBody(VoidCallback? handleDelete) {
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: OceanTheme.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: expense.isOptimistic
                ? AppColors.primary.withValues(alpha: 0.35)
                : AppColors.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  // Category Icon with subtle tinted background
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: catColor.withValues(alpha: 0.25),
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Icon(catIcon, color: catColor, size: 20),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title & Category/Date Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                expense.description,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (expense.isOptimistic) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accentAmber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: AppColors.accentAmber.withValues(alpha: 0.35),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 8,
                                      height: 8,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          AppColors.accentAmber,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Processing',
                                      style: TextStyle(
                                        color: AppColors.accentAmber,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Text(
                              catName,
                              style: TextStyle(
                                color: catColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Text(
                              ' • ',
                              style: TextStyle(
                                color: AppColors.textDim,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              dateDisplay,
                              style: const TextStyle(
                                color: AppColors.textDim,
                                fontSize: 12,
                              ),
                            ),
                            if (expense.paymentMethod.isNotEmpty &&
                                expense.paymentMethod != 'other') ...[
                              const Text(
                                ' • ',
                                style: TextStyle(
                                  color: AppColors.textDim,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                expense.paymentMethod.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.textFaint,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (showNote &&
                            expense.note != null &&
                            expense.note!.trim().isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.stickyNote,
                                size: 11,
                                color: AppColors.textDim,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  expense.note!.trim(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.textDim,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Amount & Delete Button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '-${currency.format(expense.amount)}',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (onDelete != null && !expense.isOptimistic) ...[
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(
                            LucideIcons.trash2,
                            color: AppColors.textDim,
                            size: 15,
                          ),
                          splashRadius: 18,
                          visualDensity: VisualDensity.compact,
                          onPressed: handleDelete,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    Widget childWidget;
    if (onDelete != null && !expense.isOptimistic) {
      childWidget = AnimatedDelete.builder(
        onDeleteConfirmed: () async => onDelete?.call(),
        builder: (context, startDelete) => buildBody(startDelete),
      );
    } else {
      childWidget = buildBody(onDelete);
    }

    if (animateEntrance) {
      return TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value,
            child: Transform.translate(
              offset: Offset(0, (1.0 - value) * 12),
              child: child,
            ),
          );
        },
        child: childWidget,
      );
    }

    return childWidget;
  }
}
