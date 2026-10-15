import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/animation/tab_activation_scope.dart';
import '../../core/theme/oled_theme.dart';
import '../../core/widgets/animated_card.dart';
import '../../core/widgets/custom_bottom_sheet.dart';
import '../../core/widgets/micro_interactions/animated_consistency_bar.dart';
import '../../core/widgets/micro_interactions/branded_refresh_indicator.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/traffic_loader.dart';
import '../../models/skill.dart';
import '../../providers/skills_provider.dart';
import '../../routes/scaffold_with_nav_bar.dart';
import 'add_skill_sheet.dart';

class SkillsScreen extends ConsumerWidget {
  const SkillsScreen({super.key});

  void _openAddSkillModal(BuildContext context, WidgetRef ref) async {
    final result = await CustomBottomSheet.show<Map<String, dynamic>>(
      context: context,
      title: 'Add New Skill',
      subtitle: 'Define a skill area you want to master',
      child: const AddSkillSheet(),
    );

    if (result != null) {
      ref.read(skillsProvider.notifier).createSkill(
            name: result['name'] as String,
            category: result['category'] as String,
            level: result['level'] as String,
            sessionDuration: result['sessionDuration'] as int,
            preferredDays: result['preferredDays'] as List<String>,
          );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);
    final skills = skillsAsync.value ?? [];

    final totalHours = skills.fold<double>(0.0, (sum, s) => sum + s.learningHours);
    final avgConsistency = skills.isNotEmpty
        ? (skills.fold<int>(0, (sum, s) => sum + s.consistencyPct) / skills.length).round()
        : 0;

    final bottomClearance = math.max(110.0, getNavBarClearance(context));

    return TabCardScope(
      tabIndex: 1,
      child: Container(
        decoration: OledTheme.backgroundDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: BrandedRefreshIndicator(
            onRefresh: () async {
              await ref.read(skillsProvider.notifier).fetchSkills(forceRefresh: true);
            },
            color: OledTheme.cyan,
            backgroundColor: OledTheme.card,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // App Bar Header
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'My Skills',
                                style: TextStyle(
                                  color: OledTheme.textPrimary,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${skills.length} active learning areas',
                                style: const TextStyle(
                                  color: OledTheme.textSecondary,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        PressableScale(
                          onTap: () => _openAddSkillModal(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: OledTheme.cardElevated,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: OledTheme.cyan.withValues(alpha: 0.4),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: OledTheme.cyan.withValues(alpha: 0.15),
                                  blurRadius: 12,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(LucideIcons.plus, color: OledTheme.cyan, size: 17),
                                SizedBox(width: 6),
                                Text(
                                  'Add Skill',
                                  style: TextStyle(
                                    color: OledTheme.textPrimary,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Overview Stats Bar (When skills are present)
                if (skills.isNotEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                    sliver: SliverToBoxAdapter(
                      child: AnimatedCard(
                        index: 0,
                        margin: EdgeInsets.zero,
                        padding: EdgeInsets.zero,
                        backgroundColor: Colors.transparent,
                        border: Border.all(color: Colors.transparent, width: 0),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: OledTheme.card,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: OledTheme.border, width: 1),
                          ),
                          child: Row(
                            children: [
                              // 1. Total Skills
                              Expanded(
                                child: _SkillMetricItem(
                                  label: 'SKILLS',
                                  value: '${skills.length}',
                                  color: OledTheme.cyan,
                                ),
                              ),
                              Container(width: 1, height: 32, color: OledTheme.border),
                              // 2. Practiced Hours
                              Expanded(
                                child: _SkillMetricItem(
                                  label: 'HOURS',
                                  value: '${totalHours.toStringAsFixed(1)}h',
                                  color: OledTheme.violet,
                                ),
                              ),
                              Container(width: 1, height: 32, color: OledTheme.border),
                              // 3. Avg Consistency
                              Expanded(
                                child: _SkillMetricItem(
                                  label: 'CONSISTENCY',
                                  value: '$avgConsistency%',
                                  color: OledTheme.emerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Content Body
                if (skillsAsync.isLoading && skills.isEmpty)
                  const SliverFillRemaining(
                    child: Center(child: TrafficLoader(message: 'Loading skills...')),
                  )
                else if (skills.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: OledTheme.card,
                                shape: BoxShape.circle,
                                border: Border.all(color: OledTheme.border),
                              ),
                              child: const Icon(LucideIcons.bookOpen, size: 44, color: OledTheme.textMuted),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'No skills created yet',
                              style: TextStyle(
                                color: OledTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Add your first skill to start tracking consistent learning sessions.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: OledTheme.textSecondary,
                                fontSize: 13.5,
                              ),
                            ),
                            const SizedBox(height: 24),
                            PressableScale(
                              onTap: () => _openAddSkillModal(context, ref),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                                decoration: BoxDecoration(
                                  color: OledTheme.cardElevated,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: OledTheme.cyan.withValues(alpha: 0.45),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: OledTheme.cyan.withValues(alpha: 0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(LucideIcons.plus, color: OledTheme.cyan, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Add Skill Now',
                                      style: TextStyle(
                                        color: OledTheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, bottomClearance),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final skill = skills[index];
                          return _SkillCard(
                            skill: skill,
                            index: index + 1,
                            onTap: () => context.push('/skills/${skill.id}'),
                          );
                        },
                        childCount: skills.length,
                      ),
                    ),
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

class _SkillMetricItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SkillMetricItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: const TextStyle(
            color: OledTheme.textMuted,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _SkillCard extends StatefulWidget {
  final Skill skill;
  final int index;
  final VoidCallback onTap;

  const _SkillCard({
    required this.skill,
    required this.index,
    required this.onTap,
  });

  @override
  State<_SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends State<_SkillCard> {
  bool _isNavigating = false;

  void _handleTap() {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);
    widget.onTap();
    // Reset after the transition completes so back-navigation works.
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _isNavigating = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final accent = OledTheme.getCategoryAccent(widget.skill.category, widget.skill.name);
    final icon = OledTheme.getCategoryIcon(widget.skill.category, widget.skill.name);

    return AnimatedCard(
      index: widget.index,
      onTap: _handleTap,
      backgroundColor: OledTheme.card,
      border: Border.all(color: OledTheme.border, width: 1.1),
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Category Icon, Name, Category badge, Level
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Icon(icon, color: accent, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.skill.name,
                      style: const TextStyle(
                        color: OledTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.25),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            widget.skill.category,
                            style: TextStyle(
                              color: accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: OledTheme.subtleSurface,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: OledTheme.border,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            widget.skill.level,
                            style: const TextStyle(
                              color: OledTheme.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: OledTheme.textMuted, size: 18),
            ],
          ),
          const SizedBox(height: 16),

          // Target & Learning Hours
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Target: ${widget.skill.weeklyTarget} sessions / week (${widget.skill.sessionDuration}m)',
                style: const TextStyle(
                  color: OledTheme.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: OledTheme.cardElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: OledTheme.border),
                ),
                child: Text(
                  '${widget.skill.learningHours}h practiced',
                  style: TextStyle(
                    color: accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Animated Consistency & Streak Progress Bar
          AnimatedConsistencyBar(
            percentage: widget.skill.consistencyPct,
            accentColor: accent,
            index: widget.index,
            streakDays: widget.skill.streak,
          ),
        ],
      ),
    );
  }
}
