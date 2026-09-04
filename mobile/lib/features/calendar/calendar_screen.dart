import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_card.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../providers/sessions_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedWeekMonday;
  bool _isMonthlyView = false;

  @override
  void initState() {
    super.initState();
    _selectedWeekMonday = _getMonday(DateTime.now());
  }

  DateTime _getMonday(DateTime d) {
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
  }

  void _previousWeek() {
    setState(() {
      _selectedWeekMonday = _selectedWeekMonday.subtract(const Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _selectedWeekMonday = _selectedWeekMonday.add(const Duration(days: 7));
    });
  }

  void _goToToday() {
    setState(() {
      _selectedWeekMonday = _getMonday(DateTime.now());
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final allSessions = sessionsAsync.value ?? [];

    final weekDays = List.generate(7, (i) => _selectedWeekMonday.add(Duration(days: i)));
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    return Container(
      decoration: AppColors.backgroundGradientDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header & Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text('Learning Calendar', style: AppTextStyles.displayTitle),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _isMonthlyView = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: !_isMonthlyView ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Week',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: !_isMonthlyView ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => setState(() => _isMonthlyView = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: _isMonthlyView ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Month',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _isMonthlyView ? Colors.white : AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Visualize practice schedule & completion history',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 24),

              // Week Navigation Bar
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(LucideIcons.chevronLeft, color: AppColors.textPrimary, size: 20),
                      onPressed: _previousWeek,
                    ),
                    PressableScale(
                      onTap: _goToToday,
                      child: Text(
                        '${DateFormat('MMM d').format(weekDays.first)} – ${DateFormat('MMM d, yyyy').format(weekDays.last)}',
                        style: AppTextStyles.bodyStrong,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.chevronRight, color: AppColors.textPrimary, size: 20),
                      onPressed: _nextWeek,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (!_isMonthlyView) ...[
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final dayDate = weekDays[index];
                    final dayIso = DateFormat('yyyy-MM-dd').format(dayDate);
                    final isToday = dayIso == todayStr;

                    final daySessions = allSessions.where((s) => s.scheduledDate == dayIso).toList();

                    return AnimatedCard(
                      index: index,
                      backgroundColor: isToday
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : AppColors.card,
                      border: Border.all(
                        color: isToday ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    DateFormat('EEE').format(dayDate).toUpperCase(),
                                    style: AppTextStyles.bodyStrong.copyWith(
                                      color: isToday ? AppColors.primary : AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat('MMM d').format(dayDate),
                                    style: AppTextStyles.bodySecondary,
                                  ),
                                ],
                              ),
                              if (isToday)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'TODAY',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (daySessions.isEmpty)
                            Text(
                              'Rest day • No sessions scheduled',
                              style: AppTextStyles.labelSmall.copyWith(fontStyle: FontStyle.italic),
                            )
                          else
                            Column(
                              children: daySessions.map((session) {
                                final isDone = session.status == 'completed';
                                final isMissed = session.status == 'planned' && dayIso.compareTo(todayStr) < 0;
                                final isSkipped = session.status == 'skipped';

                                Color statusColor = AppColors.accentAmber;
                                String statusText = 'Scheduled';

                                if (isDone) {
                                  statusColor = AppColors.primary;
                                  statusText = 'Completed';
                                } else if (isSkipped) {
                                  statusColor = AppColors.textMuted;
                                  statusText = 'Skipped';
                                } else if (isMissed) {
                                  statusColor = AppColors.accentRose;
                                  statusText = 'Missed';
                                }

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            isDone ? LucideIcons.checkCircle : (isMissed ? LucideIcons.xCircle : LucideIcons.clock),
                                            color: statusColor,
                                            size: 16,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            session.skillName ?? 'Skill Practice',
                                            style: AppTextStyles.bodySecondary.copyWith(
                                              color: AppColors.textPrimary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            '(${session.plannedDuration}m)',
                                            style: AppTextStyles.labelSmall,
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          statusText,
                                          style: AppTextStyles.labelSmall.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: statusColor,
                                          ),
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
                  },
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM yyyy').format(_selectedWeekMonday),
                        style: AppTextStyles.headingMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((d) {
                          return Text(
                            d,
                            style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.bold),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: 28,
                        itemBuilder: (context, index) {
                          final day = _selectedWeekMonday.add(Duration(days: index - 7));
                          final dayIso = DateFormat('yyyy-MM-dd').format(day);
                          final hasCompleted = allSessions.any((s) => s.scheduledDate == dayIso && s.status == 'completed');

                          return Container(
                            decoration: BoxDecoration(
                              color: hasCompleted
                                  ? AppColors.primary.withValues(alpha: 0.25)
                                  : AppColors.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: dayIso == todayStr ? AppColors.primary : AppColors.border,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '${day.day}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  fontWeight: hasCompleted ? FontWeight.bold : FontWeight.normal,
                                  color: hasCompleted ? AppColors.primary : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }
}
