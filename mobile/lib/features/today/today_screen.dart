import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/widgets/animated_card.dart';
import '../../core/widgets/micro_interactions/branded_refresh_indicator.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/streak_button.dart';
import '../../core/widgets/traffic_loader.dart';
import '../../models/learning_session.dart';
import '../../models/skill.dart';
import '../../providers/profile_provider.dart';
import '../../providers/sessions_provider.dart';
import '../../providers/skills_provider.dart';
import '../../providers/streak_provider.dart';

// ── Design System Tokens for Today Screen ──────────────────────────────────
class _TodayPalette {
  static const Color oledBg = Color(0xFF030508);
  static const Color surfaceDark = Color(0xFF0B1222);
  static const Color surfaceElevated = Color(0xFF0E1729);
  static const Color border = Color(0xFF172642);
  static const Color borderHighlight = Color(0xFF1E3256);

  static const Color blueSoft = Color(0xFF4D7CFF);
  static const Color blueElectric = Color(0xFF3B82F6);
  static const Color violet = Color(0xFF8B7CFF);
  static const Color successTeal = Color(0xFF19D3C5);
  static const Color streakAmber = Color(0xFFF59E0B);

  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF8A9AB2);
  static const Color textMuted = Color(0xFF5A6E87);
}

Color _getSkillAccentColor(String name, String category) {
  final lowerName = name.toLowerCase();
  if (lowerName.contains('java') && !lowerName.contains('script')) {
    return _TodayPalette.blueElectric; // Java -> blue
  }
  if (lowerName.contains('c++') || lowerName.contains('cpp')) {
    return _TodayPalette.violet; // C++ -> violet
  }
  if (lowerName.contains('flutter') || lowerName.contains('dart')) {
    return _TodayPalette.successTeal; // Flutter -> teal
  }
  if (lowerName.contains('python')) {
    return const Color(0xFF38BDF8); // Sky blue
  }
  if (lowerName.contains('react') || lowerName.contains('web') || lowerName.contains('js')) {
    return const Color(0xFF60A5FA); // Light blue
  }
  if (lowerName.contains('rust') || lowerName.contains('swift')) {
    return const Color(0xFFF472B6); // Rose
  }
  if (lowerName.contains('design') || lowerName.contains('ui')) {
    return const Color(0xFFC084FC); // Purple
  }
  const palette = [
    Color(0xFF38BDF8),
    Color(0xFF818CF8),
    Color(0xFF8B7CFF),
    Color(0xFF34D399),
    Color(0xFFF472B6),
    Color(0xFF4D7CFF),
  ];
  final hash = name.codeUnits.fold<int>(0, (prev, curr) => prev + curr);
  return palette[hash % palette.length];
}

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final sessionsAsync = ref.watch(sessionsProvider);
    final skillsAsync = ref.watch(skillsProvider);

    // Bootstrap streak from profile when profile first loads
    ref.listen(profileProvider, (prev, next) {
      if (next.hasValue && next.value != null) {
        ref.read(streakProvider.notifier).syncFromProfile();
      }
    });

    final userName = profileAsync.value?.fullName.split(' ').first ?? 'Friend';
    final dateStr = DateFormat('EEEE, MMMM d').format(DateTime.now());
    final todayIsoDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final sessions = sessionsAsync.value ?? [];
    final todaySessions = sessions.where((s) => s.scheduledDate == todayIsoDate).toList();

    // Total minutes completed today
    final todayCompletedMinutes = todaySessions
        .where((s) => s.status == 'completed')
        .fold<int>(0, (sum, s) => sum + (s.actualDuration ?? s.plannedDuration));

    final completedCount = todaySessions.where((s) => s.status == 'completed').length;
    final totalCount = todaySessions.length;

    final skills = skillsAsync.value ?? [];

    // Determine whether to show an inline profile error banner.
    final bool showProfileError = profileAsync.hasError && !profileAsync.hasValue;

    return Scaffold(
      backgroundColor: _TodayPalette.oledBg,
      body: Stack(
        children: [
          // ── Ambient background light behind header ─────────────────────────
          Positioned(
            top: -50,
            left: 20,
            right: 20,
            height: 220,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _TodayPalette.blueElectric.withValues(alpha: 0.09),
                      _TodayPalette.violet.withValues(alpha: 0.04),
                      Colors.transparent,
                    ],
                    radius: 0.85,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: BrandedRefreshIndicator(
              onRefresh: () async {
                ref.read(profileProvider.notifier).fetchProfile();
                await ref.read(sessionsProvider.notifier).fetchSessions();
                await ref.read(skillsProvider.notifier).fetchSkills();
              },
              color: _TodayPalette.blueElectric,
              backgroundColor: _TodayPalette.surfaceDark,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                // Bottom padding of 110 ensures content is fully visible above floating navbar
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header: Greeting, Date, Streak & Profile ───────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getGreeting()}, $userName',
                                style: const TextStyle(
                                  color: _TodayPalette.textPrimary,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.5,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                dateStr,
                                style: const TextStyle(
                                  color: _TodayPalette.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Top Right Controls: Streak Button + Glass Avatar
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const StreakButton(),
                            const SizedBox(width: 10),
                            PressableScale(
                              onTap: () => context.push('/settings'),
                              child: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _TodayPalette.surfaceElevated,
                                  border: Border.all(
                                    color: _TodayPalette.borderHighlight,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _TodayPalette.blueElectric.withValues(alpha: 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: LinearGradient(
                                        colors: [
                                          _TodayPalette.blueElectric.withValues(alpha: 0.25),
                                          _TodayPalette.violet.withValues(alpha: 0.20),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                        style: const TextStyle(
                                          color: _TodayPalette.textPrimary,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ── Profile error banner ────────────────────────────────
                    if (showProfileError)
                      _ProfileErrorBanner(
                        error: profileAsync.error!,
                        onRetry: () => ref.read(profileProvider.notifier).fetchProfile(),
                      ),
                    if (showProfileError) const SizedBox(height: 16),

                    // ── Today's Progress Card ───────────────────────────────
                    _TodayProgressHeroCard(
                      completedMinutes: todayCompletedMinutes,
                      completedSessions: completedCount,
                      totalSessions: totalCount,
                    ),
                    const SizedBox(height: 28),

                    // ── TODAY'S LEARNING SESSIONS SECTION ───────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Text(
                              "TODAY'S LEARNING SESSIONS",
                              style: TextStyle(
                                color: _TodayPalette.textSecondary,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                            if (todaySessions.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _TodayPalette.surfaceElevated,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: _TodayPalette.border,
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  '$completedCount/$totalCount',
                                  style: const TextStyle(
                                    color: _TodayPalette.blueSoft,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (sessionsAsync.isLoading)
                          const TrafficLoader(size: 6),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (todaySessions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                        decoration: BoxDecoration(
                          color: _TodayPalette.surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _TodayPalette.border, width: 1),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x30000000),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _TodayPalette.surfaceElevated,
                                border: Border.all(color: _TodayPalette.border),
                              ),
                              child: const Icon(
                                LucideIcons.calendarCheck,
                                size: 22,
                                color: _TodayPalette.blueSoft,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No learning sessions scheduled for today.',
                              style: TextStyle(
                                color: _TodayPalette.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Enjoy your break or create a new skill schedule!',
                              style: TextStyle(
                                color: _TodayPalette.textSecondary,
                                fontSize: 12.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: todaySessions.length,
                        itemBuilder: (context, index) {
                          final session = todaySessions[index];
                          return _TodaySessionCard(
                            key: ValueKey(session.id),
                            session: session,
                            index: index,
                            onComplete: () {
                              ref.read(sessionsProvider.notifier).completeSession(session.id);
                            },
                          );
                        },
                      ),

                    const SizedBox(height: 32),

                    // ── SKILLS OVERVIEW SECTION ─────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "SKILLS OVERVIEW",
                          style: TextStyle(
                            color: _TodayPalette.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.1,
                          ),
                        ),
                        PressableScale(
                          onTap: () => context.go('/skills'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _TodayPalette.surfaceElevated.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _TodayPalette.border,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'View All Skills',
                                  style: TextStyle(
                                    color: _TodayPalette.blueSoft,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  LucideIcons.arrowRight,
                                  size: 13,
                                  color: _TodayPalette.blueSoft,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (skills.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _TodayPalette.surfaceDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _TodayPalette.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'No skills created yet',
                              style: TextStyle(
                                color: _TodayPalette.textSecondary,
                                fontSize: 14,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: () => context.go('/skills'),
                              icon: const Icon(LucideIcons.plus, size: 15),
                              label: const Text('Add Skill'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _TodayPalette.blueElectric,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: skills.take(3).length,
                        itemBuilder: (context, index) {
                          final skill = skills[index];
                          return _SkillOverviewCompactCard(
                            skill: skill,
                            index: index,
                            onTap: () => context.push('/skills/${skill.id}'),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Today's Progress Hero Card ─────────────────────────────────────────────
class _TodayProgressHeroCard extends StatefulWidget {
  final int completedMinutes;
  final int completedSessions;
  final int totalSessions;

  const _TodayProgressHeroCard({
    required this.completedMinutes,
    required this.completedSessions,
    required this.totalSessions,
  });

  @override
  State<_TodayProgressHeroCard> createState() => _TodayProgressHeroCardState();
}

class _TodayProgressHeroCardState extends State<_TodayProgressHeroCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _progressAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void didUpdateWidget(covariant _TodayProgressHeroCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.completedSessions != widget.completedSessions ||
        oldWidget.totalSessions != widget.totalSessions) {
      _animController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progressFraction = widget.totalSessions > 0
        ? (widget.completedSessions / widget.totalSessions).clamp(0.0, 1.0)
        : (widget.completedMinutes > 0 ? 1.0 : 0.0);
    final pctText = '${(progressFraction * 100).round()}%';

    return Container(
      decoration: BoxDecoration(
        color: _TodayPalette.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _TodayPalette.border,
          width: 1,
        ),
        boxShadow: [
          const BoxShadow(
            color: Color(0x50000000),
            blurRadius: 22,
            offset: Offset(0, 8),
          ),
          BoxShadow(
            color: _TodayPalette.blueElectric.withValues(alpha: 0.08),
            blurRadius: 18,
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Top subtle highlight line for glass depth
            Positioned(
              top: 0,
              left: 24,
              right: 24,
              height: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.0),
                      Colors.white.withValues(alpha: 0.08),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Modern Glass Icon Box
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: _TodayPalette.surfaceElevated,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: _TodayPalette.blueElectric.withValues(alpha: 0.25),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _TodayPalette.blueElectric.withValues(alpha: 0.15),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            LucideIcons.timer,
                            color: _TodayPalette.blueSoft,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Text metrics
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  Text(
                                    '${widget.completedMinutes}',
                                    style: const TextStyle(
                                      color: _TodayPalette.textPrimary,
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  const Text(
                                    'mins completed today',
                                    style: TextStyle(
                                      color: _TodayPalette.textSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.totalSessions == 0
                                  ? 'No scheduled sessions today'
                                  : '${widget.completedSessions} of ${widget.totalSessions} sessions done',
                              style: const TextStyle(
                                color: _TodayPalette.textSecondary,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Animated Progress Line / Bar
                  const SizedBox(height: 18),
                  AnimatedBuilder(
                    animation: _progressAnim,
                    builder: (context, _) {
                      final currentProgress = progressFraction * _progressAnim.value;
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Daily Goal Progress',
                                style: TextStyle(
                                  color: _TodayPalette.textSecondary,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                pctText,
                                style: TextStyle(
                                  color: currentProgress >= 1.0
                                      ? _TodayPalette.successTeal
                                      : _TodayPalette.blueSoft,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Stack(
                            children: [
                              // Background track
                              Container(
                                height: 6,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: _TodayPalette.surfaceElevated,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              // Animated progress fill
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final fillWidth = constraints.maxWidth * currentProgress;
                                  return Container(
                                    height: 6,
                                    width: fillWidth,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      gradient: LinearGradient(
                                        colors: [
                                          _TodayPalette.blueElectric,
                                          currentProgress >= 1.0
                                              ? _TodayPalette.successTeal
                                              : _TodayPalette.violet,
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: _TodayPalette.blueElectric.withValues(alpha: 0.35),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Today's Session Card ───────────────────────────────────────────────────
class _TodaySessionCard extends StatefulWidget {
  final LearningSession session;
  final int index;
  final VoidCallback onComplete;

  const _TodaySessionCard({
    super.key,
    required this.session,
    required this.index,
    required this.onComplete,
  });

  @override
  State<_TodaySessionCard> createState() => _TodaySessionCardState();
}

class _ConfettiPainter extends CustomPainter {
  final double progress;
  final List<Color> colors;

  _ConfettiPainter({required this.progress, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final center = Offset(size.width / 2, size.height / 2);
    const dotCount = 8;
    const maxDistance = 26.0;

    final distance = progress * maxDistance;
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final dotRadius = 3.0 * (1 - progress * 0.6);

    for (int i = 0; i < dotCount; i++) {
      final angle = (i / dotCount) * 2 * math.pi;
      final offset = Offset(math.cos(angle) * distance, math.sin(angle) * distance);
      final paint = Paint()
        ..color = colors[i % colors.length].withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center + offset, dotRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => oldDelegate.progress != progress;
}

class _TodaySessionCardState extends State<_TodaySessionCard>
    with TickerProviderStateMixin {
  bool _isProcessing = false;

  late final AnimationController _popController;
  late final Animation<double> _popScale;
  late final AnimationController _confettiController;

  static const List<Color> _confettiColors = [
    _TodayPalette.blueElectric,
    _TodayPalette.violet,
    _TodayPalette.successTeal,
    _TodayPalette.streakAmber,
  ];

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _popScale = TweenSequence<double>([
      TweenSequenceItem(
        weight: 35,
        tween: Tween(begin: 1.0, end: 1.035).chain(CurveTween(curve: Curves.easeOut)),
      ),
      TweenSequenceItem(
        weight: 65,
        tween: Tween(begin: 1.035, end: 1.0).chain(CurveTween(curve: Curves.easeOutBack)),
      ),
    ]).animate(_popController);

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void didUpdateWidget(covariant _TodaySessionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.status != widget.session.status) {
      if (_isProcessing) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  void dispose() {
    _popController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _handleComplete() {
    if (_isProcessing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isProcessing = true);
    _popController.forward(from: 0);
    _confettiController.forward(from: 0);
    widget.onComplete();
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.session.status == 'completed';
    final showDone = isCompleted || _isProcessing;

    return ScaleTransition(
      scale: _popScale,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOut,
        opacity: showDone ? 0.90 : 1.0,
        child: AnimatedCard(
          index: widget.index,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          backgroundColor: _TodayPalette.surfaceDark,
          border: Border.all(
            color: showDone
                ? _TodayPalette.blueElectric.withValues(alpha: 0.35)
                : _TodayPalette.border,
            width: 1.2,
          ),
          child: Row(
            children: [
              // Icon box with confetti overlay
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: -12,
                      top: -12,
                      child: AnimatedBuilder(
                        animation: _confettiController,
                        builder: (context, _) => CustomPaint(
                          size: const Size(68, 68),
                          painter: _ConfettiPainter(
                            progress: _confettiController.value,
                            colors: _confettiColors,
                          ),
                        ),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOutCubic,
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: showDone
                            ? _TodayPalette.surfaceElevated
                            : _TodayPalette.blueElectric.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: showDone
                              ? _TodayPalette.blueElectric.withValues(alpha: 0.4)
                              : _TodayPalette.borderHighlight,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          switchInCurve: Curves.easeOutBack,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) => ScaleTransition(
                            scale: animation,
                            child: RotationTransition(
                              turns: Tween<double>(begin: 0.12, end: 0).animate(animation),
                              child: FadeTransition(opacity: animation, child: child),
                            ),
                          ),
                          child: Icon(
                            showDone ? LucideIcons.check : LucideIcons.bookOpen,
                            key: ValueKey(showDone),
                            color: showDone ? _TodayPalette.successTeal : _TodayPalette.blueSoft,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Session title and duration info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.session.skillName ?? 'Skill Practice',
                      style: const TextStyle(
                        color: _TodayPalette.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${widget.session.plannedDuration} minutes',
                          style: const TextStyle(
                            color: _TodayPalette.textSecondary,
                            fontSize: 12.5,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '•',
                            style: TextStyle(
                              color: _TodayPalette.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            showDone ? 'Completed' : 'Scheduled',
                            key: ValueKey(showDone),
                            style: TextStyle(
                              color: showDone
                                  ? _TodayPalette.successTeal
                                  : _TodayPalette.blueSoft,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Complete button or Done badge
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 360),
                switchInCurve: Curves.easeOutBack,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.82, end: 1.0).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  ),
                ),
                child: showDone
                    ? Container(
                        key: const ValueKey('done'),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _TodayPalette.surfaceElevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _TodayPalette.blueElectric.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(LucideIcons.check, color: _TodayPalette.successTeal, size: 15),
                            SizedBox(width: 5),
                            Text(
                              'Done',
                              style: TextStyle(
                                color: _TodayPalette.successTeal,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : PressableScale(
                        key: const ValueKey('complete'),
                        onTap: _handleComplete,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                _TodayPalette.blueElectric,
                                _TodayPalette.blueSoft,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: _TodayPalette.blueElectric.withValues(alpha: 0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Complete',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Skill Overview Compact Card with Harmonic Accent Colors ─────────────────
class _SkillOverviewCompactCard extends StatelessWidget {
  final Skill skill;
  final int index;
  final VoidCallback onTap;

  const _SkillOverviewCompactCard({
    required this.skill,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = _getSkillAccentColor(skill.name, skill.category);

    return AnimatedCard(
      index: index,
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      backgroundColor: _TodayPalette.surfaceDark,
      border: Border.all(color: _TodayPalette.border, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Category Badge, Chevron
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: const TextStyle(
                        color: _TodayPalette.textPrimary,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        skill.category,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                color: _TodayPalette.textSecondary.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metrics Row: Consistency on Left, Streak on Right (Amber)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consistency: ${skill.consistencyPct}%',
                style: const TextStyle(
                  color: _TodayPalette.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Row(
                children: [
                  const Text('🔥 ', style: TextStyle(fontSize: 13)),
                  Text(
                    '${skill.streak} day streak',
                    style: const TextStyle(
                      color: _TodayPalette.streakAmber,
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar: Colored by skill accent
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (skill.consistencyPct / 100).clamp(0.0, 1.0),
              minHeight: 4.5,
              backgroundColor: _TodayPalette.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Error Banner ───────────────────────────────────────────────────
class _ProfileErrorBanner extends StatelessWidget {
  const _ProfileErrorBanner({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  String get _friendlyMessage {
    final e = error;
    if (e is PostgrestException) {
      if (e.code == 'PGRST303' ||
          e.message.toLowerCase().contains('jwt issued at future')) {
        return 'Your session is being refreshed. Tap Retry to try again.';
      }
      if (e.code == 'PGRST401' || e.message.toLowerCase().contains('permission')) {
        return 'Permission error loading your profile. Please sign out and back in.';
      }
    }
    return 'Unable to load your profile. Check your connection and tap Retry.';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1012),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66EF4444), width: 1),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _friendlyMessage,
              style: const TextStyle(color: Color(0xFFFFB3B3), fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: _TodayPalette.blueSoft,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
