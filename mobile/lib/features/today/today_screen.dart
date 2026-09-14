import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/ocean_theme.dart';
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

    final skills = skillsAsync.value ?? [];

    // Determine whether to show an inline profile error banner.
    final bool showProfileError =
        profileAsync.hasError && !profileAsync.hasValue;

    return Container(
      decoration: OceanTheme.backgroundGradientDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: BrandedRefreshIndicator(
            onRefresh: () async {
              ref.read(profileProvider.notifier).fetchProfile();
              await ref.read(sessionsProvider.notifier).fetchSessions();
              await ref.read(skillsProvider.notifier).fetchSkills();
            },
            color: OceanTheme.primary,
            backgroundColor: OceanTheme.card,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getGreeting()}, $userName',
                            style: AppTextStyles.displayTitle,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateStr,
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ),
                      // Top Right: Streak Button + Gradient Avatar Circle (#00E5A0 -> #3B82F6)
                      Row(
                        children: [
                          const StreakButton(),
                          const SizedBox(width: 10),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [OceanTheme.primary, OceanTheme.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x3300E5A0),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                                style: AppTextStyles.bodyStrong.copyWith(color: OceanTheme.bg),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Profile error banner ──────────────────────────────────
                  // Shown only when profile fetch fails AND no cached data
                  // exists. Does NOT crash the screen — rest of UI still works.
                  if (showProfileError)
                    _ProfileErrorBanner(
                      error: profileAsync.error!,
                      onRetry: () =>
                          ref.read(profileProvider.notifier).fetchProfile(),
                    ),
                  if (showProfileError) const SizedBox(height: 16),

                  // Today Total Completed Time Hero Card (Stopwatch Icon #3B82F6 on #132038)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: OceanTheme.cardHi,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: OceanTheme.border, width: 1),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: OceanTheme.secondaryDim, // #132038
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            LucideIcons.timer,
                            color: OceanTheme.secondary, // #3B82F6
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '$todayCompletedMinutes mins completed today',
                                  style: AppTextStyles.cardHeadline,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                todaySessions.isEmpty
                                    ? 'No scheduled sessions today'
                                    : '${todaySessions.where((s) => s.status == "completed").length} of ${todaySessions.length} sessions done',
                                style: AppTextStyles.bodySecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // TODAY'S LEARNING SESSIONS SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "TODAY'S LEARNING SESSIONS",
                        style: AppTextStyles.sectionLabel,
                      ),
                      if (sessionsAsync.isLoading)
                        const TrafficLoader(size: 6),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (todaySessions.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: OceanTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: OceanTheme.border),
                      ),
                      child: Column(
                        children: [
                          const Icon(LucideIcons.calendarCheck, size: 36, color: OceanTheme.textFaint),
                          const SizedBox(height: 12),
                          Text(
                            'No learning sessions scheduled for today.',
                            style: AppTextStyles.bodySecondary,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enjoy your break or create a new skill schedule!',
                            style: AppTextStyles.labelSmall,
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

                  // SKILLS OVERVIEW SECTION
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "SKILLS OVERVIEW",
                        style: AppTextStyles.sectionLabel,
                      ),
                      TextButton(
                        onPressed: () => context.go('/skills'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          children: [
                            Text(
                              'View All Skills',
                              style: AppTextStyles.bodySecondary.copyWith(
                                color: OceanTheme.secondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(LucideIcons.arrowRight, size: 14, color: OceanTheme.secondary),
                          ],
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
                        color: OceanTheme.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: OceanTheme.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'No skills created yet',
                            style: TextStyle(color: OceanTheme.textDim, fontSize: 14),
                          ),
                          ElevatedButton.icon(
                            onPressed: () => context.go('/skills'),
                            icon: const Icon(LucideIcons.plus, size: 16),
                            label: const Text('Add Skill'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: OceanTheme.primary,
                              foregroundColor: OceanTheme.bg,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
      ),
    );
  }
}

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
  final double progress; // 0.0 → 1.0, driven by the confetti AnimationController
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
    final dotRadius = 3.0 * (1 - progress * 0.6); // dots shrink slightly as they fly out

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
    OceanTheme.primary,
    OceanTheme.secondary,
    OceanTheme.amber,
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
        opacity: showDone ? 0.85 : 1.0,
        child: AnimatedCard(
          index: widget.index,
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          backgroundColor: OceanTheme.card,
          border: Border.all(
            color: showDone ? OceanTheme.secondary.withValues(alpha: 0.25) : OceanTheme.border,
            width: 1.2,
          ),
          child: Row(
            children: [
              // ── Icon box with confetti overlay ─────────────────────────
              SizedBox(
                width: 44,
                height: 44,
                child: Stack(
                  clipBehavior: Clip.none, // lets confetti paint outside the 44x44 box
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
                        color: showDone ? OceanTheme.secondaryDim : OceanTheme.primaryDim,
                        borderRadius: BorderRadius.circular(12),
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
                            color: showDone ? OceanTheme.secondary : OceanTheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // ── Session info ─────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.session.skillName ?? 'Skill Practice', style: AppTextStyles.bodyStrong),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: showDone ? OceanTheme.secondary : OceanTheme.primary,
                          ),
                          child: Text('${widget.session.plannedDuration} minutes'),
                        ),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: showDone ? OceanTheme.secondary : OceanTheme.primary,
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text('•'),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                          child: AnimatedDefaultTextStyle(
                            key: ValueKey(showDone),
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOutCubic,
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: showDone ? OceanTheme.secondary : OceanTheme.primary,
                            ),
                            child: Text(showDone ? 'Completed' : 'Scheduled'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // ── Complete button / Done badge ───────────────────────────────
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
                    ? Row(
                        key: const ValueKey('done'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.check, color: OceanTheme.secondary, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            'Done',
                            style: AppTextStyles.bodySecondary.copyWith(
                              color: OceanTheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : PressableScale(
                        key: const ValueKey('complete'),
                        onTap: _handleComplete,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: OceanTheme.primary,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(color: Color(0x3300E5A0), blurRadius: 10, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Text('Complete', style: AppTextStyles.buttonText),
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
    return AnimatedCard(
      index: index,
      onTap: onTap,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      backgroundColor: OceanTheme.card,
      border: Border.all(color: OceanTheme.border, width: 1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Category, Chevron
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                skill.name,
                style: AppTextStyles.bodyStrong,
              ),
              const Icon(
                LucideIcons.chevronRight,
                color: OceanTheme.textFaint,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            skill.category,
            style: AppTextStyles.labelSmall,
          ),
          const SizedBox(height: 14),

          // Metrics Row: Consistency on Left, Streak on Right (Amber #FFB020)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consistency: ${skill.consistencyPct}%',
                style: AppTextStyles.bodySecondary,
              ),
              Row(
                children: [
                  const Text('🔥 ', style: TextStyle(fontSize: 13)),
                  Text(
                    '${skill.streak} day streak',
                    style: AppTextStyles.bodySecondary.copyWith(
                      color: OceanTheme.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar: Blue fill #3B82F6 on track #132038
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: (skill.consistencyPct / 100).clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: OceanTheme.cardHi, // #132038
              valueColor: const AlwaysStoppedAnimation<Color>(OceanTheme.secondary), // #3B82F6 Blue fill
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Error Banner ─────────────────────────────────────────────────────
// Shown inside TodayScreen when profileProvider is in error state.
// Friendly — no raw PostgrestException text is displayed to the user.

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
              foregroundColor: OceanTheme.primary,
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
