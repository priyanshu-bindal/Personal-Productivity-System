import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/oled_theme.dart';
import '../../core/widgets/animated_card.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../models/learning_session.dart';
import '../../providers/sessions_provider.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _selectedWeekMonday;
  late DateTime _currentMonth;
  bool _isMonthlyView = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedWeekMonday = _getMonday(now);
    _currentMonth = DateTime(now.year, now.month, 1);
  }

  DateTime _getMonday(DateTime d) {
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));
  }

  void _previousPeriod() {
    setState(() {
      if (_isMonthlyView) {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
      } else {
        _selectedWeekMonday = _selectedWeekMonday.subtract(const Duration(days: 7));
      }
    });
  }

  void _nextPeriod() {
    setState(() {
      if (_isMonthlyView) {
        _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
      } else {
        _selectedWeekMonday = _selectedWeekMonday.add(const Duration(days: 7));
      }
    });
  }

  void _goToToday() {
    final now = DateTime.now();
    setState(() {
      _selectedDate = DateTime(now.year, now.month, now.day);
      _selectedWeekMonday = _getMonday(now);
      _currentMonth = DateTime(now.year, now.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsProvider);
    final allSessions = sessionsAsync.value ?? [];

    final weekDays = List.generate(7, (i) => _selectedWeekMonday.add(Duration(days: i)));
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    return Container(
      decoration: OledTheme.backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            // Bottom padding 110 prevents content from hiding behind floating nav
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header & View Toggle ──────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Schedule',
                          style: TextStyle(
                            color: OledTheme.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Practice calendar & completions',
                          style: TextStyle(
                            color: OledTheme.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    // Toggle Pill
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: OledTheme.cardElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: OledTheme.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _isMonthlyView = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: !_isMonthlyView ? OledTheme.electricBlue : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                'Week',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: !_isMonthlyView ? Colors.white : OledTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => setState(() => _isMonthlyView = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _isMonthlyView ? OledTheme.electricBlue : Colors.transparent,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                'Month',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _isMonthlyView ? Colors.white : OledTheme.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // ── Period Navigation Bar ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: OledTheme.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: OledTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.chevronLeft, color: OledTheme.textPrimary, size: 20),
                        onPressed: _previousPeriod,
                      ),
                      PressableScale(
                        onTap: _goToToday,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: OledTheme.cardElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: OledTheme.borderSubtle),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _isMonthlyView
                                    ? DateFormat('MMMM yyyy').format(_currentMonth)
                                    : '${DateFormat('MMM d').format(weekDays.first)} – ${DateFormat('MMM d, yyyy').format(weekDays.last)}',
                                style: const TextStyle(
                                  color: OledTheme.textPrimary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: OledTheme.cyan.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Today',
                                  style: TextStyle(
                                    color: OledTheme.cyan,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(LucideIcons.chevronRight, color: OledTheme.textPrimary, size: 20),
                        onPressed: _nextPeriod,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // ── VIEW MODES ────────────────────────────────────────────────
                if (!_isMonthlyView) ...[
                  // ── WEEK VIEW ───────────────────────────────────────────────
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 7,
                    itemBuilder: (context, index) {
                      final dayDate = weekDays[index];
                      final dayIso = DateFormat('yyyy-MM-dd').format(dayDate);
                      final isToday = dayIso == todayStr;

                      final daySessions = allSessions.where((s) => s.scheduledDate == dayIso).toList();
                      final completedCount = daySessions.where((s) => s.status == 'completed').length;

                      return AnimatedCard(
                        index: index,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        backgroundColor: isToday
                            ? OledTheme.cardElevated
                            : OledTheme.card,
                        border: Border.all(
                          color: isToday
                              ? OledTheme.cyan.withValues(alpha: 0.5)
                              : OledTheme.border,
                          width: isToday ? 1.3 : 1.0,
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
                                      style: TextStyle(
                                        color: isToday ? OledTheme.cyan : OledTheme.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMMM d').format(dayDate),
                                      style: const TextStyle(
                                        color: OledTheme.textSecondary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isToday)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: OledTheme.cyan.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: OledTheme.cyan.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Text(
                                      'TODAY',
                                      style: TextStyle(
                                        color: OledTheme.cyan,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  )
                                else if (daySessions.isNotEmpty)
                                  Text(
                                    '$completedCount/${daySessions.length} done',
                                    style: TextStyle(
                                      color: completedCount == daySessions.length
                                          ? OledTheme.emerald
                                          : OledTheme.textMuted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (daySessions.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 4),
                                child: Text(
                                  'Rest day • No sessions scheduled',
                                  style: TextStyle(
                                    color: OledTheme.textMuted,
                                    fontSize: 12.5,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: daySessions.map((session) {
                                  return _CalendarSessionRow(
                                    session: session,
                                    dayIso: dayIso,
                                    todayStr: todayStr,
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ] else ...[
                  // ── MONTH VIEW ──────────────────────────────────────────────
                  _MonthCalendarView(
                    currentMonth: _currentMonth,
                    selectedDate: _selectedDate,
                    todayStr: todayStr,
                    allSessions: allSessions,
                    onSelectDate: (d) => setState(() => _selectedDate = d),
                  ),
                  const SizedBox(height: 16),

                  // ── SELECTED DAY SESSIONS DETAIL CARD ───────────────────────
                  _SelectedDayDetailCard(
                    date: _selectedDate,
                    sessions: allSessions.where((s) => s.scheduledDate == selectedDateStr).toList(),
                    todayStr: todayStr,
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

// ─── Week View Calendar Session Row ──────────────────────────────────────────
class _CalendarSessionRow extends StatelessWidget {
  final LearningSession session;
  final String dayIso;
  final String todayStr;

  const _CalendarSessionRow({
    required this.session,
    required this.dayIso,
    required this.todayStr,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = session.status == 'completed';
    final isMissed = session.status == 'planned' && dayIso.compareTo(todayStr) < 0;
    final isSkipped = session.status == 'skipped';

    Color statusColor = OledTheme.amber;
    String statusText = 'Scheduled';
    IconData statusIcon = LucideIcons.clock;

    if (isDone) {
      statusColor = OledTheme.emerald;
      statusText = 'Completed';
      statusIcon = LucideIcons.checkCircle2;
    } else if (isSkipped) {
      statusColor = OledTheme.textMuted;
      statusText = 'Skipped';
      statusIcon = LucideIcons.minusCircle;
    } else if (isMissed) {
      statusColor = OledTheme.coral;
      statusText = 'Missed';
      statusIcon = LucideIcons.xCircle;
    }

    final accent = OledTheme.getCategoryAccent(null, session.skillName);
    final catIcon = OledTheme.getCategoryIcon(null, session.skillName);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: OledTheme.cardElevated.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDone
              ? OledTheme.emerald.withValues(alpha: 0.2)
              : OledTheme.borderSubtle,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(catIcon, color: accent, size: 16),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    session.skillName ?? 'Skill Practice',
                    style: const TextStyle(
                      color: OledTheme.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${session.plannedDuration}m',
                  style: const TextStyle(
                    color: OledTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.25),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, color: statusColor, size: 11),
                const SizedBox(width: 4),
                Text(
                  statusText,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dynamic Month Calendar Grid View ────────────────────────────────────────
class _MonthCalendarView extends StatelessWidget {
  final DateTime currentMonth;
  final DateTime selectedDate;
  final String todayStr;
  final List<LearningSession> allSessions;
  final ValueChanged<DateTime> onSelectDate;

  const _MonthCalendarView({
    required this.currentMonth,
    required this.selectedDate,
    required this.todayStr,
    required this.allSessions,
    required this.onSelectDate,
  });

  @override
  Widget build(BuildContext context) {
    // 1st day of month
    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    // Number of days in month
    final daysInMonth = DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    // Weekday offset (Monday = 1 -> offset 0, Sunday = 7 -> offset 6)
    final startOffset = firstDayOfMonth.weekday - 1;
    // Total cells: padded to full weeks (multiples of 7)
    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    final selectedIso = DateFormat('yyyy-MM-dd').format(selectedDate);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OledTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OledTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekday Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map((d) {
              return SizedBox(
                width: 36,
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: OledTheme.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: OledTheme.border),
          const SizedBox(height: 12),

          // Dynamic Calendar Days Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8,
              crossAxisSpacing: 6,
              childAspectRatio: 0.95,
            ),
            itemCount: totalCells,
            itemBuilder: (context, index) {
              final dayNumber = index - startOffset + 1;
              final isCurrentMonth = dayNumber >= 1 && dayNumber <= daysInMonth;

              if (!isCurrentMonth) {
                return const SizedBox.shrink();
              }

              final cellDate = DateTime(currentMonth.year, currentMonth.month, dayNumber);
              final cellIso = DateFormat('yyyy-MM-dd').format(cellDate);
              final isToday = cellIso == todayStr;
              final isSelected = cellIso == selectedIso;

              final daySessions = allSessions.where((s) => s.scheduledDate == cellIso).toList();
              final hasCompleted = daySessions.any((s) => s.status == 'completed');
              final hasPlanned = daySessions.any((s) => s.status == 'planned');
              final isMissed = cellIso.compareTo(todayStr) < 0 && hasPlanned;

              return PressableScale(
                onTap: () => onSelectDate(cellDate),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? OledTheme.electricBlue.withValues(alpha: 0.22)
                        : (isToday ? OledTheme.cyan.withValues(alpha: 0.10) : OledTheme.cardElevated),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? OledTheme.electricBlue
                          : (isToday ? OledTheme.cyan.withValues(alpha: 0.5) : OledTheme.borderSubtle),
                      width: isSelected || isToday ? 1.4 : 1.0,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isToday || isSelected || hasCompleted
                              ? FontWeight.w800
                              : FontWeight.w500,
                          color: isSelected
                              ? OledTheme.textPrimary
                              : (isToday ? OledTheme.cyan : OledTheme.textPrimary),
                        ),
                      ),
                      const SizedBox(height: 3),
                      // Dot Indicators for Day Status
                      if (daySessions.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 5,
                              height: 5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: hasCompleted
                                    ? OledTheme.emerald
                                    : (isMissed ? OledTheme.coral : OledTheme.amber),
                              ),
                            ),
                          ],
                        )
                      else
                        const SizedBox(height: 5),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Selected Day Detail Card ────────────────────────────────────────────────
class _SelectedDayDetailCard extends StatelessWidget {
  final DateTime date;
  final List<LearningSession> sessions;
  final String todayStr;

  const _SelectedDayDetailCard({
    required this.date,
    required this.sessions,
    required this.todayStr,
  });

  @override
  Widget build(BuildContext context) {
    final dayIso = DateFormat('yyyy-MM-dd').format(date);
    final dateDisplay = DateFormat('EEEE, MMMM d').format(date);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: OledTheme.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: OledTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateDisplay,
                style: const TextStyle(
                  color: OledTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: OledTheme.cardElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: OledTheme.border),
                ),
                child: Text(
                  '${sessions.length} session${sessions.length == 1 ? '' : 's'}',
                  style: const TextStyle(
                    color: OledTheme.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No sessions scheduled for this day.',
                style: TextStyle(
                  color: OledTheme.textMuted,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Column(
              children: sessions.map((session) {
                return _CalendarSessionRow(
                  session: session,
                  dayIso: dayIso,
                  todayStr: todayStr,
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
