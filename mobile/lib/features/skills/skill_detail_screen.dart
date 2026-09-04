import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/widgets/custom_bottom_sheet.dart';
import '../../models/skill.dart';
import '../../providers/skills_provider.dart';
import 'add_skill_sheet.dart';

class SkillDetailScreen extends ConsumerWidget {
  final String skillId;

  const SkillDetailScreen({super.key, required this.skillId});

  void _openEditModal(BuildContext context, WidgetRef ref, Skill skill) async {
    final result = await CustomBottomSheet.show<Map<String, dynamic>>(
      context: context,
      title: 'Edit Skill',
      subtitle: 'Update practice schedule and level',
      child: AddSkillSheet(
        existingSkillId: skill.id,
        initialName: skill.name,
        initialCategory: skill.category,
        initialLevel: skill.level,
        initialDuration: skill.sessionDuration,
        initialDays: skill.preferredDays,
      ),
    );

    if (result != null) {
      ref.read(skillsProvider.notifier).updateSkill(
            skill.id,
            name: result['name'] as String,
            category: result['category'] as String,
            level: result['level'] as String,
            sessionDuration: result['sessionDuration'] as int,
            preferredDays: result['preferredDays'] as List<String>,
          );
    }
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text('Delete Skill', style: AppTextStyles.headingMedium),
        content: Text(
          'Are you sure you want to delete this skill? All learning history will be deleted.',
          style: AppTextStyles.bodySecondary,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: AppTextStyles.bodySecondary.copyWith(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(skillsProvider.notifier).deleteSkill(skillId);
              if (context.mounted) context.pop();
            },
            child: Text('Delete', style: AppTextStyles.bodySecondary.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            )),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skillsAsync = ref.watch(skillsProvider);
    final skill = skillsAsync.value?.where((s) => s.id == skillId).firstOrNull;

    if (skill == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: Center(
          child: Text('Skill not found', style: AppTextStyles.bodySecondary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.edit3, color: AppColors.textSecondary),
            onPressed: () => _openEditModal(context, ref, skill),
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: AppColors.accentRose),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(skill.name, style: AppTextStyles.displayTitle),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            skill.level,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Category: ${skill.category}',
                      style: AppTextStyles.bodySecondary,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        _StatBox(
                          label: 'Consistency',
                          value: '${skill.consistencyPct}%',
                          icon: LucideIcons.target,
                          color: AppColors.blue,
                        ),
                        const SizedBox(width: 12),
                        _StatBox(
                          label: 'Streak',
                          value: '${skill.streak} Days',
                          icon: LucideIcons.flame,
                          color: AppColors.accentAmber,
                        ),
                        const SizedBox(width: 12),
                        _StatBox(
                          label: 'Practiced',
                          value: '${skill.learningHours}h',
                          icon: LucideIcons.clock,
                          color: AppColors.accentBlue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Text('PRACTICE SCHEDULE', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target Sessions:', style: AppTextStyles.bodySecondary),
                        Text(
                          '${skill.weeklyTarget} sessions / week',
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Planned Duration:', style: AppTextStyles.bodySecondary),
                        Text(
                          '${skill.sessionDuration} minutes per session',
                          style: AppTextStyles.bodySecondary.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Scheduled Days:', style: AppTextStyles.bodySecondary),
                        Wrap(
                          spacing: 4,
                          children: skill.preferredDays.map((day) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                day.substring(0, 3),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text('LEARNING HISTORY', style: AppTextStyles.sectionLabel),
              const SizedBox(height: 12),

              if (skill.sessions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text('No recorded sessions yet.', style: AppTextStyles.bodySecondary),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: skill.sessions.length,
                  itemBuilder: (context, index) {
                    final session = skill.sessions[index];
                    final dateFormatted = DateFormat('MMM d, yyyy').format(DateTime.parse(session.scheduledDate));
                    final isDone = session.status == 'completed';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isDone ? LucideIcons.checkCircle2 : LucideIcons.circle,
                                color: isDone ? AppColors.primary : AppColors.textMuted,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateFormatted,
                                    style: AppTextStyles.bodySecondary.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${session.actualDuration ?? session.plannedDuration} minutes',
                                    style: AppTextStyles.labelSmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDone ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surface,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              session.status.toUpperCase(),
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: isDone ? AppColors.primary : AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: AppTextStyles.bodyStrong,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: AppTextStyles.labelSmall),
          ],
        ),
      ),
    );
  }
}
