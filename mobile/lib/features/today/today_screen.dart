import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_text_styles.dart';
import '../../core/theme/ocean_theme.dart';
import '../../core/widgets/animated_card.dart';
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

    return Container(
      decoration: OceanTheme.backgroundGradientDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
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

class _TodaySessionCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isCompleted = session.status == 'completed';

    return AnimatedCard(
      index: index,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      backgroundColor: OceanTheme.card,
      border: Border.all(
        color: OceanTheme.border,
        width: 1.2,
      ),
      child: Row(
        children: [
          // Icon Container:
          // Completed: Icon #3B82F6 (Blue) on #132038 container
          // Active/Scheduled: Icon #00E5A0 (Green) on #0A2E24 container
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCompleted ? OceanTheme.secondaryDim : OceanTheme.primaryDim,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                isCompleted ? LucideIcons.check : LucideIcons.bookOpen,
                color: isCompleted ? OceanTheme.secondary : OceanTheme.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Session Info:
          // Completed text: Blue #3B82F6
          // Scheduled text: Green #00E5A0
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.skillName ?? 'Skill Practice',
                  style: AppTextStyles.bodyStrong,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${session.plannedDuration} minutes',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: isCompleted ? OceanTheme.secondary : OceanTheme.primary,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Text(
                        '•',
                        style: AppTextStyles.bodySecondary.copyWith(
                          color: isCompleted ? OceanTheme.secondary : OceanTheme.primary,
                        ),
                      ),
                    ),
                    Text(
                      isCompleted ? 'Completed' : 'Scheduled',
                      style: AppTextStyles.bodySecondary.copyWith(
                        color: isCompleted ? OceanTheme.secondary : OceanTheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Right Status / Action:
          // Completed: "✓ Done" in Blue #3B82F6
          // Active/Scheduled: "Complete" button solid Green #00E5A0 fill, dark text #06090F
          if (isCompleted)
            Row(
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
          else
            PressableScale(
              onTap: onComplete,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: OceanTheme.primary, // #00E5A0
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3300E5A0),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Complete',
                  style: AppTextStyles.buttonText,
                ),
              ),
            ),
        ],
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
