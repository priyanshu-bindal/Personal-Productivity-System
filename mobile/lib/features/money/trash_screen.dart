import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/ocean_theme.dart';
import '../../core/widgets/micro_interactions/animated_delete.dart';
import '../../core/widgets/money_empty_state.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/trash_confirmation_overlay.dart';
import '../../models/expense.dart';
import '../../providers/money_provider.dart';
import '../../providers/trash_provider.dart';
import 'widgets/transaction_list_item.dart';

class TrashScreen extends ConsumerStatefulWidget {
  const TrashScreen({super.key});

  /// Computes human-friendly remaining time text based on exact UTC expiration timestamp.
  static String formatRemainingTime(DateTime deletedAt) {
    final nowUtc = DateTime.now().toUtc();
    final expirationUtc = deletedAt.toUtc().add(const Duration(days: 30));
    final remaining = expirationUtc.difference(nowUtc);

    if (remaining.isNegative) {
      return 'Expiring soon';
    } else if (remaining.inDays > 1) {
      return 'Deletes in ${remaining.inDays} days';
    } else if (remaining.inDays == 1) {
      return 'Deletes in 1 day';
    } else if (remaining.inHours > 0) {
      return 'Deletes in ${remaining.inHours} hours';
    } else if (remaining.inMinutes > 0) {
      return 'Deletes in ${remaining.inMinutes} mins';
    } else {
      return 'Expiring soon';
    }
  }

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entranceController;

  final Set<String> _processingRestoreIds = {};
  final Set<String> _processingDeleteIds = {};
  final Map<String, Expense> _animatingOutItems = {};
  final Map<String, AnimatedDeleteController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();

    // Ensure entering TrashScreen reads fresh state from Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(trashedExpensesProvider.notifier).fetchTrashed();
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _controllers.clear();
    super.dispose();
  }

  String _formatExpenseDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM d, yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _confirmPermanentDelete(Expense expense) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: OceanTheme.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Delete permanently?',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        content: const Text(
          'This expense will be permanently removed and cannot be restored.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error.withValues(alpha: 0.15),
              foregroundColor: AppColors.error,
              elevation: 0,
              side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _permanentlyDeleteExpense(expense);
            },
            child: const Text(
              'Delete Permanently',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _permanentlyDeleteExpense(Expense expense) async {
    if (_processingRestoreIds.contains(expense.id) ||
        _processingDeleteIds.contains(expense.id)) {
      return;
    }

    setState(() {
      _processingDeleteIds.add(expense.id);
      _animatingOutItems[expense.id] = expense;
    });

    try {
      // 1. Smoothly collapse card out (fade + shrink 1.0 -> 0.97 + vertical collapse)
      await _controllers[expense.id]?.collapse();

      // 2. Perform permanent delete in Supabase
      await ref
          .read(trashedExpensesProvider.notifier)
          .permanentlyDelete(expense.id);

      if (mounted) {
        setState(() {
          _animatingOutItems.remove(expense.id);
          _processingDeleteIds.remove(expense.id);
        });
        TrashConfirmationOverlay.showSuccess(
          context: context,
          message: 'Expense permanently deleted',
          icon: LucideIcons.trash2,
          iconColor: AppColors.error,
        );
      }
    } catch (_) {
      if (mounted) {
        _controllers[expense.id]?.reset();
        setState(() {
          _animatingOutItems.remove(expense.id);
          _processingDeleteIds.remove(expense.id);
        });
        TrashConfirmationOverlay.showError(
          context: context,
          message: "Couldn't delete expense. Please try again.",
        );
      }
    }
  }

  Future<void> _restoreExpense(Expense expense) async {
    if (_processingRestoreIds.contains(expense.id) ||
        _processingDeleteIds.contains(expense.id)) {
      return;
    }

    // 1. Enter processing state and subtly highlight card
    setState(() {
      _processingRestoreIds.add(expense.id);
      _animatingOutItems[expense.id] = expense;
    });

    try {
      // 2. Immediate asynchronous restore in Supabase (no artificial delay)
      await ref.read(trashedExpensesProvider.notifier).restore(expense);
      // Synchronize active expenses provider
      await ref.read(expensesProvider.notifier).fetchExpenses();

      // 3. Smooth collapse animation (opacity 1 -> 0, scale 1.0 -> 0.97, height collapse)
      if (mounted) {
        await _controllers[expense.id]?.collapse();
        if (mounted) {
          setState(() {
            _animatingOutItems.remove(expense.id);
            _processingRestoreIds.remove(expense.id);
          });
          TrashConfirmationOverlay.showSuccess(
            context: context,
            message: 'Expense restored',
          );
        }
      }
    } catch (_) {
      if (mounted) {
        _controllers[expense.id]?.reset();
        setState(() {
          _animatingOutItems.remove(expense.id);
          _processingRestoreIds.remove(expense.id);
        });
        TrashConfirmationOverlay.showError(
          context: context,
          message: "Couldn't restore expense. Please try again.",
        );
      }
    }
  }

  Widget _buildHeaderSummary(List<Expense> trashedList) {
    final count = trashedList.length;
    final total = trashedList.fold<double>(0, (sum, e) => sum + e.amount);
    final currencyFmt = NumberFormat('#,##0.00');
    final countStr = count == 1 ? '1 deleted expense' : '$count items';
    final summaryText = '$countStr • ₹${currencyFmt.format(total)}';

    return FadeTransition(
      opacity: _entranceController,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: OceanTheme.card.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.info, size: 14, color: AppColors.textDim),
            const SizedBox(width: 8),
            Text(
              summaryText,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent(Expense expense) {
    final catColor = TransactionListItem.getCategoryColor(expense.category);
    final catIcon = TransactionListItem.getCategoryIcon(expense.category);
    final currencyFmt = NumberFormat('#,##0.00');
    final remainingText = expense.deletedAt != null
        ? TrashScreen.formatRemainingTime(expense.deletedAt!)
        : 'Deletes in 30 days';

    final deletedDateStr = expense.deletedAt != null
        ? DateFormat('MMM d, yyyy').format(expense.deletedAt!.toLocal())
        : 'Recently';

    final expenseDateStr = _formatExpenseDate(expense.expenseDate);

    final isRestoringThis = _processingRestoreIds.contains(expense.id);
    final isDeletingThis = _processingDeleteIds.contains(expense.id);
    final isItemBusy = isRestoringThis || isDeletingThis;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: OceanTheme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRestoringThis
              ? AppColors.primary.withValues(alpha: 0.55)
              : isDeletingThis
                  ? AppColors.error.withValues(alpha: 0.5)
                  : AppColors.border,
          width: isItemBusy ? 1.2 : 1.0,
        ),
        boxShadow: isRestoringThis
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Category icon, Description, Amount
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: catColor.withValues(alpha: 0.28),
                      width: 1,
                    ),
                  ),
                  child: Icon(catIcon, color: catColor, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.description,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${expense.category.toUpperCase()} • ${expense.paymentMethod.replaceAll('_', ' ').toUpperCase()} • $expenseDateStr',
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹${currencyFmt.format(expense.amount)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 12),

            // Bottom Row: Remaining time & Deleted date on left, Action Buttons on right
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Column: Badge and full Deleted date without truncation
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Remaining time badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.warning.withValues(alpha: 0.28),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.clock,
                              color: AppColors.warning,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              remainingText,
                              style: const TextStyle(
                                color: AppColors.warning,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Deleted $deletedDateStr',
                        style: const TextStyle(
                          color: AppColors.textDim,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Restore action button
                PressableScale(
                  scaleFactor: 0.94,
                  onTap: isItemBusy ? null : () => _restoreExpense(expense),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(
                        alpha: isRestoringThis ? 0.22 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primary.withValues(
                          alpha: isRestoringThis ? 0.6 : 0.3,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isRestoringThis) ...[
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            'Restoring...',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ] else ...[
                          const Icon(
                            LucideIcons.rotateCcw,
                            color: AppColors.primary,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Restore',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Permanent delete action button
                PressableScale(
                  scaleFactor: 0.94,
                  onTap: isItemBusy ? null : () => _confirmPermanentDelete(expense),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(
                        alpha: isDeletingThis ? 0.2 : 0.1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.error.withValues(
                          alpha: isDeletingThis ? 0.5 : 0.3,
                        ),
                      ),
                    ),
                    child: isDeletingThis
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.8,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.error,
                              ),
                            ),
                          )
                        : const Icon(
                            LucideIcons.trash2,
                            color: AppColors.error,
                            size: 14,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStaggeredItem(Widget child, int index) {
    if (index >= 8) {
      return child;
    }
    final start = (index * 0.05).clamp(0.0, 0.6);
    final end = (start + 0.35).clamp(0.0, 1.0);
    final anim = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: anim,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(anim),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trashAsync = ref.watch(trashedExpensesProvider);

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Trash',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: -0.2,
              ),
            ),
            SizedBox(height: 1),
            Text(
              'Deleted expenses are kept for 30 days',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: trashAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 36),
                  const SizedBox(height: 12),
                  const Text(
                    "Couldn't load Trash",
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    err.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () => ref.read(trashedExpensesProvider.notifier).fetchTrashed(),
                    icon: const Icon(LucideIcons.refreshCw, size: 16),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (trashedList) {
            final displayedList = <Expense>[];
            final seenIds = <String>{};

            for (final e in trashedList) {
              displayedList.add(e);
              seenIds.add(e.id);
            }
            for (final entry in _animatingOutItems.entries) {
              if (!seenIds.contains(entry.key)) {
                displayedList.add(entry.value);
                seenIds.add(entry.key);
              }
            }

            if (displayedList.isEmpty) {
              return FadeTransition(
                opacity: _entranceController,
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: MoneyEmptyState(
                      icon: LucideIcons.trash2,
                      title: 'Trash is empty',
                      description: 'Deleted expenses will stay here for 30 days before being permanently removed.',
                      accentColor: AppColors.textMuted,
                      minHeight: 180,
                    ),
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSummary(displayedList),
                Expanded(
                  child: RefreshIndicator(
                    color: AppColors.primary,
                    backgroundColor: OceanTheme.card,
                    onRefresh: () async {
                      await ref.read(trashedExpensesProvider.notifier).fetchTrashed();
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: displayedList.length,
                      itemBuilder: (context, index) {
                        final expense = displayedList[index];
                        final controller = _controllers.putIfAbsent(
                          expense.id,
                          () => AnimatedDeleteController(),
                        );

                        final cardWidget = AnimatedDelete(
                          key: ValueKey(expense.id),
                          controller: controller,
                          duration: const Duration(milliseconds: 270),
                          curve: Curves.easeOutCubic,
                          scaleEnd: 0.97,
                          child: _buildCardContent(expense),
                        );

                        return _buildStaggeredItem(cardWidget, index);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
