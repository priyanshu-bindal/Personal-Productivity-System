import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/animated_card.dart';
import '../../core/widgets/custom_bottom_sheet.dart';
import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/traffic_loader.dart';
import '../../models/skill.dart';
import '../../providers/skills_provider.dart';
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

    return Container(
      decoration: AppColors.backgroundGradientDecoration,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: () async {
              await ref.read(skillsProvider.notifier).fetchSkills();
            },
            color: AppColors.primary,
            backgroundColor: AppColors.card,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // App Bar Header
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('My Skills', style: AppTextStyles.displayTitle),
                              const SizedBox(height: 4),
                              Text(
                                '${skills.length} active learning areas',
                                style: AppTextStyles.bodySecondary,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        PressableScale(
                          onTap: () => _openAddSkillModal(context, ref),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.primaryGlow,
                                  blurRadius: 10,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.plus, color: Colors.white, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Add Skill',
                                  style: AppTextStyles.buttonText.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
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
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.border),
                              ),
                              child: const Icon(LucideIcons.bookOpen, size: 48, color: AppColors.textMuted),
                            ),
                            const SizedBox(height: 20),
                            Text('No skills created yet', style: AppTextStyles.headingMedium),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first skill to start tracking consistent learning sessions.',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.bodySecondary,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _openAddSkillModal(context, ref),
                              icon: const Icon(LucideIcons.plus, size: 18),
                              label: const Text('Add Skill Now'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final skill = skills[index];
                          return _SkillCard(
                            skill: skill,
                            index: index,
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
    );
  }
}

class _SkillCard extends StatelessWidget {
  final Skill skill;
  final int index;
  final VoidCallback onTap;

  const _SkillCard({
    required this.skill,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedCard(
      index: index,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Category, Level
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.code2, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(skill.name, style: AppTextStyles.bodyStrong),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(skill.category, style: AppTextStyles.bodySecondary),
                        const SizedBox(width: 8),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: AppColors.textMuted,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(skill.level, style: AppTextStyles.labelSmall),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: AppColors.textMuted, size: 20),
            ],
          ),
          const SizedBox(height: 16),

          // Practice Target & Days Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Target: ${skill.weeklyTarget} sessions / week (${skill.sessionDuration}m)',
                  style: AppTextStyles.bodySecondary,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${skill.learningHours}h practiced',
                style: AppTextStyles.bodySecondary.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Automated Consistency Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('Consistency', style: AppTextStyles.labelSmall),
                      const SizedBox(width: 8),
                      Text(
                        '${skill.consistencyPct}%',
                        style: AppTextStyles.bodySecondary.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '🔥 ${skill.streak} day streak',
                    style: AppTextStyles.bodySecondary.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (skill.consistencyPct / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: AppColors.blueDim,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.blue),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
