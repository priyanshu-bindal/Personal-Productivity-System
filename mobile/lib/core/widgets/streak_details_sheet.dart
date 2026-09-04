import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/sessions_provider.dart';
import '../../providers/streak_provider.dart';

class StreakDetailsSheet extends ConsumerWidget {
  const StreakDetailsSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final sessions = ref.watch(sessionsProvider).value ?? [];

    final dayData = ref
        .read(streakProvider.notifier)
        .computeLastNDays(sessions, n: 7);

    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0E1526),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: Color(0xFF1C2C46), width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Title row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A1A00),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF3D2800)),
                ),
                child: const Text('🔥', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${streak.currentStreak} Day Streak',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'Keep learning consistently!',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats row
          Row(
            children: [
              _StatTile(
                icon: '🏆',
                label: 'Longest Streak',
                value: '${streak.longestStreak} Days',
              ),
              const SizedBox(width: 12),
              _StatTile(
                icon: '📅',
                label: 'Last Active',
                value: streak.lastStreakDate != null
                    ? _formatDate(streak.lastStreakDate!)
                    : '—',
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 7-day grid header
          const Text(
            'LAST 7 DAYS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textMuted,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 12),

          // Day labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final d = dayData[i];
              // Use weekday index for label (Mon=0…Sun=6)
              final labelIdx = d.date.weekday - 1; // weekday: Mon=1…Sun=7
              return SizedBox(
                width: 40,
                child: Column(
                  children: [
                    Text(
                      dayLabels[labelIdx],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _DayDot(
                      hasScheduled: d.hasScheduled,
                      allCompleted: d.allCompleted,
                      isToday: i == 6,
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // Legend
          Row(
            children: [
              _LegendItem(color: AppColors.primary, label: 'Completed'),
              const SizedBox(width: 16),
              _LegendItem(color: AppColors.textMuted, label: 'No sessions / Pending'),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return DateFormat('MMM d').format(dt);
    } catch (_) {
      return isoDate;
    }
  }
}

class _StatTile extends StatelessWidget {
  final String icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayDot extends StatelessWidget {
  final bool hasScheduled;
  final bool allCompleted;
  final bool isToday;

  const _DayDot({
    required this.hasScheduled,
    required this.allCompleted,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final Color bgColor;
    final Widget child;

    if (allCompleted) {
      bgColor = AppColors.primary.withValues(alpha: 0.2);
      child = const Text('✓', style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.bold));
    } else {
      bgColor = AppColors.surface;
      child = Text('·', style: TextStyle(fontSize: 18, color: hasScheduled ? AppColors.accentRose.withValues(alpha: 0.7) : AppColors.textMuted));
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: isToday ? AppColors.primary : AppColors.border,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Center(child: child),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}

/// Shows the streak details bottom sheet.
void showStreakDetails(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const StreakDetailsSheet(),
  );
}
