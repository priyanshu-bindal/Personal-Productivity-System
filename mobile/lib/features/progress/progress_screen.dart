import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/oled_theme.dart';
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
    final dayOfWeek = now.weekday; // 1 = Monday, 7 = Sunday
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
      final duration = s.actualDuration ?? s.plannedDuration;
      skillMinutesMap[sName] = (skillMinutesMap[sName] ?? 0) + duration;
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

    final maxVal = weeklyBarValues.reduce((a, b) => a > b ? a : b);
    final chartMaxY = maxVal > 0 ? math.max((maxVal * 1.25).ceilToDouble(), 2.0) : 3.0;

    return Container(
      decoration: OledTheme.backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            // Bottom padding 110 ensures clearance above the floating navbar
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────────────────
                const Text(
                  'Analytics',
                  style: TextStyle(
                    color: OledTheme.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Automated tracking of your learning habits',
                  style: TextStyle(
                    color: OledTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 22),

                // ── 4 Multi-Accent Metric Cards ──────────────────────────────
                const Text(
                  'WEEKLY SUMMARY',
                  style: TextStyle(
                    color: OledTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _OledProgressCard(
                        label: 'Sessions Done',
                        value: '$weeklyCompletedCount / $weeklyTotalPlanned',
                        icon: LucideIcons.checkSquare,
                        color: OledTheme.emerald,
                        index: 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OledProgressCard(
                        label: 'Learning Time',
                        value: '${weeklyHours}h ${weeklyMins}m',
                        icon: LucideIcons.clock,
                        color: OledTheme.cyan,
                        index: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _OledProgressCard(
                        label: 'Consistency',
                        value: '$weeklyConsistency%',
                        icon: LucideIcons.target,
                        color: OledTheme.violet,
                        index: 2,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _OledProgressCard(
                        label: 'Current Streak',
                        value: '$maxStreak Days',
                        icon: LucideIcons.flame,
                        color: OledTheme.amber,
                        index: 3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // ── Weekly Bar Chart (Fixed Capsule Track Architecture) ───────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'LEARNING ACTIVITY (HOURS)',
                      style: TextStyle(
                        color: OledTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                    Text(
                      'Max: ${chartMaxY.toInt()}h scale',
                      style: const TextStyle(
                        color: OledTheme.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 220,
                  padding: const EdgeInsets.fromLTRB(12, 20, 16, 14),
                  decoration: BoxDecoration(
                    color: OledTheme.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: OledTheme.border),
                  ),
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: chartMaxY,
                      minY: 0,
                      barTouchData: BarTouchData(
                        enabled: true,
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => OledTheme.cardElevated,
                          tooltipRoundedRadius: 10,
                          tooltipBorder: const BorderSide(color: OledTheme.borderHighlight),
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
                            final hrs = rod.toY;
                            final mins = (hrs * 60).round();
                            return BarTooltipItem(
                              '${days[groupIndex]}\n',
                              const TextStyle(
                                color: OledTheme.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                              children: [
                                TextSpan(
                                  text: mins > 0 ? '$mins mins focused' : '0 mins focused',
                                  style: TextStyle(
                                    color: mins > 0 ? OledTheme.cyan : OledTheme.textMuted,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            interval: chartMaxY > 2 ? 1 : 0.5,
                            getTitlesWidget: (val, meta) {
                              if (val == 0) return const SizedBox.shrink();
                              return Text(
                                '${val.toInt()}h',
                                style: const TextStyle(
                                  color: OledTheme.textMuted,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (value, meta) {
                              const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                              final idx = value.toInt();
                              if (idx >= 0 && idx < days.length) {
                                final isCur = idx == (dayOfWeek - 1);
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    days[idx],
                                    style: TextStyle(
                                      color: isCur ? OledTheme.cyan : OledTheme.textSecondary,
                                      fontSize: 11,
                                      fontWeight: isCur ? FontWeight.w800 : FontWeight.w600,
                                    ),
                                  ),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: chartMaxY > 2 ? 1 : 0.5,
                        getDrawingHorizontalLine: (val) {
                          return FlLine(
                            color: OledTheme.border.withValues(alpha: 0.4),
                            strokeWidth: 0.8,
                            dashArray: [4, 4],
                          );
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(7, (i) {
                        final isCurDay = i == (dayOfWeek - 1);
                        final val = weeklyBarValues[i];

                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: val,
                              // Elegant rounded capsule rods
                              width: 18,
                              borderRadius: BorderRadius.circular(6),
                              gradient: val > 0
                                  ? const LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                                        OledTheme.electricBlue,
                                        OledTheme.cyan,
                                      ],
                                    )
                                  : null,
                              color: val > 0 ? null : Colors.transparent,
                              // Capsule track background: prevents empty chart bug!
                              backDrawRodData: BackgroundBarChartRodData(
                                show: true,
                                toY: chartMaxY,
                                color: isCurDay
                                    ? OledTheme.subtleSurface
                                    : OledTheme.cardElevated.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // ── Monthly Overview ──────────────────────────────────────────
                const Text(
                  'MONTHLY OVERVIEW',
                  style: TextStyle(
                    color: OledTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: OledTheme.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: OledTheme.border),
                  ),
                  child: Column(
                    children: [
                      _MonthlyRow(
                        label: 'Total Sessions Completed',
                        value: '${monthCompleted.length} sessions',
                        icon: LucideIcons.checkCircle2,
                        accent: OledTheme.emerald,
                      ),
                      const SizedBox(height: 14),
                      Container(height: 1, color: OledTheme.border),
                      const SizedBox(height: 14),
                      _MonthlyRow(
                        label: 'Total Learning Hours',
                        value: '${monthHours}h',
                        icon: LucideIcons.clock,
                        accent: OledTheme.cyan,
                      ),
                      const SizedBox(height: 14),
                      Container(height: 1, color: OledTheme.border),
                      const SizedBox(height: 14),
                      _MonthlyRow(
                        label: 'Most Practiced Skill',
                        value: topSkillName,
                        icon: OledTheme.getCategoryIcon(null, topSkillName),
                        accent: OledTheme.getCategoryAccent(null, topSkillName),
                      ),
                      const SizedBox(height: 14),
                      Container(height: 1, color: OledTheme.border),
                      const SizedBox(height: 14),
                      _MonthlyRow(
                        label: 'Monthly Consistency Rate',
                        value: '$monthConsistency%',
                        icon: LucideIcons.target,
                        accent: OledTheme.violet,
                      ),
                    ],
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

// ─── OLED Multi-Accent Metric Card ───────────────────────────────────────────
class _OledProgressCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int index;

  const _OledProgressCard({
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
      padding: const EdgeInsets.all(16),
      backgroundColor: OledTheme.card,
      border: Border.all(color: OledTheme.border, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: color.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                color: OledTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: OledTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── OLED Monthly Row ────────────────────────────────────────────────────────
class _MonthlyRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  const _MonthlyRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: accent, size: 17),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: OledTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: const TextStyle(
            color: OledTheme.textPrimary,
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
