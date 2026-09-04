import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_card.dart';
import '../../providers/sessions_provider.dart';
import '../../providers/skills_provider.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final skillsAsync = ref.watch(skillsProvider);

    final sessions = sessionsAsync.value ?? [];
    final skills = skillsAsync.value ?? [];

    final now = DateTime.now();

    // Weekly calculations (Monday to Sunday)
    final dayOfWeek = now.weekday;
    final monday = now.subtract(Duration(days: dayOfWeek - 1));
    final mondayStr = DateFormat('yyyy-MM-dd').format(monday);
    final sunday = monday.add(const Duration(days: 6));
    final sundayStr = DateFormat('yyyy-MM-dd').format(sunday);

    final thisWeekSessions = sessions
        .where((s) => s.scheduledDate.compareTo(mondayStr) >= 0 && s.scheduledDate.compareTo(sundayStr) <= 0)
        .toList();
    final weeklyCompletedCount = thisWeekSessions.where((s) => s.status == 'completed').length;
    final weeklyTotalPlanned = thisWeekSessions.length;

    final weeklyCompletedMinutes = thisWeekSessions
        .where((s) => s.status == 'completed')
        .fold<int>(0, (sum, s) => sum + (s.actualDuration ?? s.plannedDuration));

    final weeklyHours = weeklyCompletedMinutes ~/ 60;
    final weeklyMins = weeklyCompletedMinutes % 60;

    final weeklyConsistency = weeklyTotalPlanned > 0
        ? ((weeklyCompletedCount / weeklyTotalPlanned) * 100).round()
        : 100;

    int maxStreak = 0;
    for (final sk in skills) {
      if (sk.streak > maxStreak) maxStreak = sk.streak;
    }

    // Monthly overview
    final monthPrefix = DateFormat('yyyy-MM').format(now);
    final monthSessions = sessions.where((s) => s.scheduledDate.startsWith(monthPrefix)).toList();
    final monthCompleted = monthSessions.where((s) => s.status == 'completed').toList();
    final monthMinutes = monthCompleted.fold<int>(0, (sum, s) => sum + (s.actualDuration ?? s.plannedDuration));
    final monthHours = (monthMinutes / 60.0 * 10).round() / 10.0;

    final monthConsistency = monthSessions.isNotEmpty
        ? ((monthCompleted.length / monthSessions.length) * 100).round()
        : 100;

    final Map<String, int> skillMinutesMap = {};
    for (final s in monthCompleted) {
      final sName = s.skillName ?? 'Skill';
      skillMinutesMap[sName] = (skillMinutesMap[sName] ?? 0) + (s.actualDuration ?? s.plannedDuration);
    }
    String topSkillName = 'None';
    int topSkillMins = 0;
    skillMinutesMap.forEach((name, mins) {
      if (mins > topSkillMins) {
        topSkillMins = mins;
        topSkillName = name;
      }
    });

    final List<double> weeklyBarValues = List.generate(7, (i) {
      final dayDate = monday.add(Duration(days: i));
      final dayIso = DateFormat('yyyy-MM-dd').format(dayDate);
      final dayMins = sessions
          .where((s) => s.scheduledDate == dayIso && s.status == 'completed')
          .fold<int>(0, (sum, s) => sum + (s.actualDuration ?? s.plannedDuration));
      return dayMins / 60.0;
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Progress & Analytics', style: AppTextStyles.displayTitle),
              const SizedBox(height: 4),
              Text(
                'Automated real-time tracking of learning habits',
                style: AppTextStyles.bodySecondary,
              ),
              const SizedBox(height: 24),

              Text('WEEKLY SUMMARY', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _ProgressCard(
                      label: 'Sessions Done',
                      value: '$weeklyCompletedCount / ${weeklyTotalPlanned == 0 ? 0 : weeklyTotalPlanned}',
                      icon: LucideIcons.checkSquare,
                      color: AppColors.primary,
                      index: 0,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProgressCard(
                      label: 'Learning Time',
                      value: '${weeklyHours}h ${weeklyMins}m',
                      icon: LucideIcons.clock,
                      color: AppColors.accentBlue,
                      index: 1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ProgressCard(
                      label: 'Consistency',
                      value: '$weeklyConsistency%',
                      icon: LucideIcons.target,
                      color: AppColors.accentCyan,
                      index: 2,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ProgressCard(
                      label: 'Current Streak',
                      value: '$maxStreak Days',
                      icon: LucideIcons.flame,
                      color: AppColors.accentAmber,
                      index: 3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              Text('WEEKLY LEARNING ACTIVITY (HOURS)', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 12),
              Container(
                height: 200,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: (weeklyBarValues.reduce((a, b) => a > b ? a : b) + 1).ceilToDouble(),
                    barTouchData: BarTouchData(enabled: true),
                    titlesData: FlTitlesData(
                      show: true,
                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                            final idx = value.toInt();
                            if (idx >= 0 && idx < days.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Text(
                                  days[idx],
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                    ),
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(7, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: weeklyBarValues[i],
                            color: i == (dayOfWeek - 1) ? AppColors.blue : AppColors.blueDim,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              Text('MONTHLY OVERVIEW', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _MonthlyRow(label: 'Total Sessions Completed', value: '${monthCompleted.length} sessions'),
                    const Divider(height: 20),
                    _MonthlyRow(label: 'Total Learning Hours', value: '${monthHours}h'),
                    const Divider(height: 20),
                    _MonthlyRow(label: 'Most Practiced Skill', value: topSkillName),
                    const Divider(height: 20),
                    _MonthlyRow(label: 'Monthly Consistency Rate', value: '$monthConsistency%'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int index;

  const _ProgressCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      index: index,
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: AppTextStyles.cardHeadline),
          ),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

class _MonthlyRow extends StatelessWidget {
  final String label;
  final String value;

  const _MonthlyRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: AppTextStyles.bodySecondary),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: AppTextStyles.bodySecondary.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
