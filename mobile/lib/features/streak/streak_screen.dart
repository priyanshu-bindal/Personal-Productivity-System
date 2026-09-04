import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/lottie_fire.dart';
import '../../providers/sessions_provider.dart';
import '../../providers/streak_provider.dart';

class StreakScreen extends ConsumerWidget {
  const StreakScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final sessions = ref.watch(sessionsProvider).value ?? [];
    final dayData = ref
        .read(streakProvider.notifier)
        .computeLastNDays(sessions, n: 7);

    return Container(
      decoration: AppColors.backgroundGradientDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── App Bar ──────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.cardHi,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Text(
                        'Learning Streak',
                        style: AppTextStyles.displayTitle,
                      ),
                    ],
                  ),
                ),

                // ── Hero Fire Section ─────────────────────────────────────
                Center(
                  child: Column(
                    children: [
                      const SizedBox(height: 12),

                      // Soft radial gradient behind the Lottie fire
                      Container(
                        width: 170,
                        height: 170,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Color(0x3300E5A0), // Primary accent #00E5A0 low-opacity
                              Color(0x1200E5A0),
                              Colors.transparent,
                            ],
                            stops: [0.0, 0.55, 1.0],
                          ),
                        ),
                        child: const Center(
                          child: LottieFire(size: 130),
                        ),
                      )
                          .animate()
                          .scale(
                            begin: const Offset(0.75, 0.75),
                            end: const Offset(1.0, 1.0),
                            duration: 500.ms,
                            curve: Curves.easeOutBack,
                          ),

                      const SizedBox(height: 16),

                      // Large Streak Number with heavy visual weight
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${streak.currentStreak}',
                          style: AppTextStyles.displayHero.copyWith(
                            fontSize: 88,
                            fontWeight: FontWeight.w900,
                            color: AppColors.amber,
                            height: 1,
                            letterSpacing: -4,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 450.ms, delay: 150.ms)
                          .slideY(begin: 0.2, end: 0, duration: 450.ms, curve: Curves.easeOut),

                      const SizedBox(height: 6),

                      // Secondary line label
                      Text(
                        streak.currentStreak == 1 ? 'Day Streak 🔥' : 'Days Streak 🔥',
                        style: AppTextStyles.bodyStrong.copyWith(color: AppColors.textSecondary),
                      ).animate().fadeIn(duration: 400.ms, delay: 250.ms),

                      const SizedBox(height: 6),

                      // Motivational subtitle
                      Text(
                        streak.currentStreak == 0
                            ? 'Complete today\'s sessions to light your streak!'
                            : 'Keep the momentum going — don\'t break the chain!',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondary,
                      ).animate().fadeIn(duration: 400.ms, delay: 350.ms),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),

                // ── Stats Cards ───────────────────────────────────────────
                Row(
                  children: [
                    _StatCard(
                      emoji: '🏆',
                      label: 'Longest Streak',
                      value: '${streak.longestStreak}',
                      unit: streak.longestStreak == 1 ? 'Day' : 'Days',
                      accentColor: AppColors.primary, // #00E5A0
                    ),
                    const SizedBox(width: 12),
                    _StatCard(
                      emoji: '📅',
                      label: 'Last Active',
                      value: streak.lastStreakDate != null
                          ? _formatDate(streak.lastStreakDate!)
                          : '—',
                      unit: '',
                      accentColor: AppColors.secondary, // #3B82F6
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 400.ms)
                    .slideY(begin: 0.2, end: 0, duration: 400.ms),

                const SizedBox(height: 24),

                // ── 7-Day Tracker Card ────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardHi,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LAST 7 DAYS',
                        style: AppTextStyles.sectionLabel,
                      ),
                      const SizedBox(height: 20),

                      // Day columns
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(7, (i) {
                          final d = dayData[i];
                          final labelIdx = d.date.weekday - 1;
                          final labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                          return _DayColumn(
                            label: labels[labelIdx],
                            hasScheduled: d.hasScheduled,
                            allCompleted: d.allCompleted,
                            isToday: i == 6,
                            animDelay: (i * 50).ms,
                          );
                        }),
                      ),

                      const SizedBox(height: 20),

                      // Legend
                      const Row(
                        children: [
                          _LegendDot(color: AppColors.primary, label: 'Completed'),
                          SizedBox(width: 14),
                          _LegendDot(color: AppColors.coralRed, label: 'Missed'),
                          SizedBox(width: 14),
                          _LegendDot(color: AppColors.textMuted, label: 'Pending'),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 500.ms)
                    .slideY(begin: 0.2, end: 0, duration: 400.ms),

                const SizedBox(height: 24),

                // ── Motivational Insight Card ──────────────────────────────
                _MotivationalCard(streak: streak.currentStreak)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 600.ms)
                    .slideY(begin: 0.2, end: 0, duration: 400.ms),
              ],
            ),
          ),
        ),
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

// ─── Stat Card Widget ─────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String unit;
  final Color accentColor;

  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardHi,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: AppTextStyles.cardHeadline.copyWith(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: accentColor,
                      height: 1,
                      letterSpacing: -0.8,
                    ),
                  ),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      unit,
                      style: AppTextStyles.bodySecondary.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Day Column Widget ────────────────────────────────────────────────────────

class _DayColumn extends StatelessWidget {
  final String label;
  final bool hasScheduled;
  final bool allCompleted;
  final bool isToday;
  final Duration animDelay;

  const _DayColumn({
    required this.label,
    required this.hasScheduled,
    required this.allCompleted,
    required this.isToday,
    required this.animDelay,
  });

  @override
  Widget build(BuildContext context) {
    final Color indicatorBg;
    final Border? indicatorBorder;
    final Widget indicatorContent;

    if (allCompleted) {
      // Completed: filled #00E5A0
      indicatorBg = AppColors.primary;
      indicatorBorder = null;
      indicatorContent = Text(
        '✓',
        style: AppTextStyles.bodyStrong.copyWith(
          fontSize: 14,
          color: AppColors.primaryForeground,
          fontWeight: FontWeight.bold,
        ),
      );
    } else if (hasScheduled && !isToday) {
      // Missed: filled muted coral red #E55353
      indicatorBg = AppColors.coralRed;
      indicatorBorder = null;
      indicatorContent = Text(
        '×',
        style: AppTextStyles.bodyStrong.copyWith(
          fontSize: 16,
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      );
    } else {
      // Result-pending / future / rest: outlined faint
      indicatorBg = AppColors.card;
      indicatorBorder = Border.all(color: AppColors.border, width: 1);
      indicatorContent = Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          color: AppColors.textMuted,
          shape: BoxShape.circle,
        ),
      );
    }

    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.sectionLabel.copyWith(
            fontWeight: FontWeight.bold,
            color: isToday ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: indicatorBg,
            shape: BoxShape.circle,
            border: isToday
                ? Border.all(color: AppColors.primary, width: 2)
                : indicatorBorder,
            boxShadow: isToday
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Center(child: indicatorContent),
        ),
        if (isToday) ...[
          const SizedBox(height: 6),
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ],
    ).animate(delay: animDelay).fadeIn(duration: 350.ms).slideY(
          begin: 0.25,
          end: 0,
          duration: 350.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

// ─── Motivational Card ───────────────────────────────────────────────────────

class _MotivationalCard extends StatelessWidget {
  final int streak;
  const _MotivationalCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final String message;
    final String emoji;

    if (streak == 0) {
      message = 'Complete your daily learning goal to light your streak!';
      emoji = '🌱';
    } else if (streak < 3) {
      message = 'Great start! Keep going — consistency builds mastery.';
      emoji = '🌿';
    } else if (streak < 7) {
      message = 'You\'re building momentum. Don\'t break the chain!';
      emoji = '⚡';
    } else if (streak < 14) {
      message = 'One week of dedication! Your skills are growing rapidly.';
      emoji = '🏅';
    } else if (streak < 30) {
      message = 'Two weeks strong! You\'re in the top tier of consistent learners.';
      emoji = '🚀';
    } else {
      message = 'A full month of learning mastery. You are unstoppable!';
      emoji = '👑';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08), // Soft primary tint
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Legend Dot ──────────────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
