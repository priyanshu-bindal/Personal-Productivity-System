import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ocean_theme.dart';
import '../../../core/theme/oled_theme.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../providers/money_provider.dart';

/// Interactive Month Selector Bar for the Money Overview screen.
/// Provides previous/next navigation, quick jump to current month,
/// and a full month/year modal picker.
class MonthSelectorBar extends ConsumerWidget {
  const MonthSelectorBar({super.key});

  void _showMonthPicker(BuildContext context, WidgetRef ref, DateTime currentSelected) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _MonthYearPickerSheet(initialMonth: currentSelected),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(selectedMoneyMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;
    final isFutureMonth = selectedMonth.year > now.year ||
        (selectedMonth.year == now.year && selectedMonth.month > now.month);

    final monthName = DateFormat('MMMM yyyy').format(selectedMonth);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: OceanTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentMonth
              ? OledTheme.electricBlue.withValues(alpha: 0.35)
              : AppColors.border,
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x30000000),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Month Button
          PressableScale(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(selectedMoneyMonthProvider.notifier).state =
                  DateTime(selectedMonth.year, selectedMonth.month - 1, 1);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: OceanTheme.bg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.chevronLeft,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ),

          // Center: Tappable Month Display & Badge
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showMonthPicker(context, ref, selectedMonth);
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      LucideIcons.calendar,
                      size: 15,
                      color: isCurrentMonth ? OledTheme.electricBlue : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: Text(
                          monthName,
                          key: ValueKey(monthName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Current / Future Status Badge
                    if (isCurrentMonth)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: OledTheme.emerald.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: OledTheme.emerald.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'CURRENT',
                          style: TextStyle(
                            color: OledTheme.emerald,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else if (isFutureMonth)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: OledTheme.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: OledTheme.amber.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: const Text(
                          'FUTURE',
                          style: TextStyle(
                            color: OledTheme.amber,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    const SizedBox(width: 4),
                    const Icon(
                      LucideIcons.chevronDown,
                      color: AppColors.textDim,
                      size: 13,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Jump to This Month (only shown if not in current month)
          if (!isCurrentMonth)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: PressableScale(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(selectedMoneyMonthProvider.notifier).state =
                      DateTime(now.year, now.month, 1);
                },
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 9),
                  decoration: BoxDecoration(
                    color: OledTheme.electricBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: OledTheme.electricBlue.withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(LucideIcons.rotateCcw, color: OledTheme.electricBlue, size: 12),
                      SizedBox(width: 4),
                      Text(
                        'Today',
                        style: TextStyle(
                          color: OledTheme.electricBlue,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Next Month Button
          PressableScale(
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(selectedMoneyMonthProvider.notifier).state =
                  DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: OceanTheme.bg.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
              ),
              child: const Center(
                child: Icon(
                  LucideIcons.chevronRight,
                  color: AppColors.textPrimary,
                  size: 18,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal Bottom Sheet allowing quick jumping to any Month & Year.
class _MonthYearPickerSheet extends ConsumerStatefulWidget {
  final DateTime initialMonth;

  const _MonthYearPickerSheet({required this.initialMonth});

  @override
  ConsumerState<_MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends ConsumerState<_MonthYearPickerSheet> {
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialMonth.year;
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  @override
  Widget build(BuildContext context) {
    final expenses = ref.watch(expensesProvider).value ?? [];
    final currentSelected = ref.watch(selectedMoneyMonthProvider);
    final now = DateTime.now();

    // Collect months in _selectedYear that have logged expenses
    final monthsWithData = <int>{};
    final yearPrefix = '$_selectedYear-';
    for (final e in expenses) {
      if (e.deletedAt != null) continue;
      if (e.expenseDate.startsWith(yearPrefix)) {
        try {
          final parts = e.expenseDate.split('-');
          if (parts.length >= 2) {
            final m = int.tryParse(parts[1]);
            if (m != null) monthsWithData.add(m);
          }
        } catch (_) {}
      }
    }

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        MediaQuery.of(context).padding.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1018),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: Color(0xFF202B38), width: 1.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF202B38),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header with Year Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SELECT MONTH',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.chevronLeft, size: 18),
                    color: AppColors.textPrimary,
                    onPressed: () => setState(() => _selectedYear--),
                    visualDensity: VisualDensity.compact,
                  ),
                  Text(
                    '$_selectedYear',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.chevronRight, size: 18),
                    color: AppColors.textPrimary,
                    onPressed: () => setState(() => _selectedYear++),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3x4 Month Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 12,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 2.1,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final monthNum = index + 1;
              final isChosen = currentSelected.year == _selectedYear &&
                  currentSelected.month == monthNum;
              final isTodayMonth =
                  now.year == _selectedYear && now.month == monthNum;
              final hasData = monthsWithData.contains(monthNum);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ref.read(selectedMoneyMonthProvider.notifier).state =
                      DateTime(_selectedYear, monthNum, 1);
                  Navigator.of(context).pop();
                },
                behavior: HitTestBehavior.opaque,
                child: Container(
                  decoration: BoxDecoration(
                    color: isChosen
                        ? OledTheme.electricBlue.withValues(alpha: 0.18)
                        : (isTodayMonth
                            ? OledTheme.cardElevated
                            : const Color(0xFF05070B)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isChosen
                          ? OledTheme.electricBlue
                          : (isTodayMonth
                              ? OledTheme.emerald.withValues(alpha: 0.5)
                              : const Color(0xFF151E2B)),
                      width: isChosen ? 1.5 : 1,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _months[index],
                            style: TextStyle(
                              color: isChosen
                                  ? OledTheme.electricBlue
                                  : AppColors.textPrimary,
                              fontSize: 13.5,
                              fontWeight:
                                  isChosen ? FontWeight.w800 : FontWeight.w600,
                            ),
                          ),
                          if (hasData) ...[
                            const SizedBox(width: 5),
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: OledTheme.cyan,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),

          // Return to Current Month Action
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                ref.read(selectedMoneyMonthProvider.notifier).state =
                    DateTime(now.year, now.month, 1);
                Navigator.of(context).pop();
              },
              icon: const Icon(LucideIcons.calendarCheck, size: 16),
              label: const Text('Jump to Current Month'),
              style: TextButton.styleFrom(
                foregroundColor: OledTheme.electricBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
