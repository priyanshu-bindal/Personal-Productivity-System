import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/custom_bottom_sheet.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/supabase_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _exportData(BuildContext context) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) return;

    try {
      final supabase = SupabaseService.client;
      final results = await Future.wait([
        supabase.from('skills').select('*').eq('user_id', userId),
        supabase.from('learning_sessions').select('*').eq('user_id', userId),
        supabase.from('notes').select('*').eq('user_id', userId),
        supabase.from('expenses').select('*').eq('user_id', userId),
        supabase.from('budgets').select('*').eq('user_id', userId),
      ]);

      final exportPayload = {
        'exportDate': DateTime.now().toIso8601String(),
        'userId': userId,
        'skills': results[0],
        'learningSessions': results[1],
        'notes': results[2],
        'expenses': results[3],
        'budgets': results[4],
      };

      final jsonStr = const JsonEncoder.withIndent('  ').convert(exportPayload);

      if (context.mounted) {
        CustomBottomSheet.show(
          context: context,
          title: 'Exported Data (JSON)',
          subtitle: 'Your personal FocusFlow records',
          child: Container(
            constraints: const BoxConstraints(maxHeight: 300),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                jsonStr,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _confirmDeleteAccount(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.card,
        title: const Text('Delete Account', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
        content: const Text(
          'Are you sure you want to permanently delete your FocusFlow account and all associated skills, sessions, notes, and financial records?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final userId = SupabaseService.currentUserId;
              if (userId != null) {
                final supabase = SupabaseService.client;
                await Future.wait([
                  supabase.from('skills').delete().eq('user_id', userId),
                  supabase.from('learning_sessions').delete().eq('user_id', userId),
                  supabase.from('notes').delete().eq('user_id', userId),
                  supabase.from('expenses').delete().eq('user_id', userId),
                  supabase.from('budgets').delete().eq('user_id', userId),
                  supabase.from('profiles').delete().eq('id', userId),
                ]);
                await ref.read(authControllerProvider.notifier).signOut();
              }
            },
            child: const Text('Delete Permanently', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ACCOUNT',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2),
              ),
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
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                          child: Text(
                            (profile?.fullName.isNotEmpty == true) ? profile!.fullName[0].toUpperCase() : 'U',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile?.fullName.isNotEmpty == true ? profile!.fullName : 'FocusFlow User',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                profile?.email ?? 'No email available',
                                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Consumer(
                      builder: (context, ref, _) {
                        final chatIdAsync = ref.watch(currentChatUserShortIdProvider);
                        final chatId = chatIdAsync.value ?? '···';

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0x14FFFFFF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0x26FFFFFF)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'YOUR FOCUS ID',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '#$chatId',
                                    style: const TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFBFDBFE),
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                icon: const Icon(LucideIcons.copy, color: Color(0xFF93C5FD), size: 16),
                                onPressed: chatId != '···'
                                    ? () {
                                        Clipboard.setData(ClipboardData(text: chatId));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Focus ID copied to clipboard'),
                                            behavior: SnackBarBehavior.floating,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );
                                      }
                                    : null,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(LucideIcons.logOut, color: AppColors.accentRose, size: 20),
                      title: const Text('Sign Out', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.w600)),
                      onTap: () {
                        ref.read(authControllerProvider.notifier).signOut();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'PRACTICE PREFERENCES',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2),
              ),
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
                        const Text('Default Session Duration', style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                        Text('${profile?.defaultSessionDuration ?? 60} mins', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'NOTIFICATIONS',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daily Practice Reminders', style: TextStyle(color: AppColors.textPrimary, fontSize: 15)),
                    Switch(
                      value: profile?.practiceReminders ?? true,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) {
                        ref.read(profileProvider.notifier).updatePreferences(practiceReminders: val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'DATA & PRIVACY',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListTile(
                  leading: const Icon(LucideIcons.download, color: AppColors.textSecondary, size: 20),
                  title: const Text('Export Personal Data', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                  subtitle: const Text('Export skills, sessions & expenses to JSON', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  onTap: () => _exportData(context),
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'DANGER ZONE',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.accentRose, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.accentRose.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentRose.withValues(alpha: 0.3)),
                ),
                child: ListTile(
                  leading: const Icon(LucideIcons.userX, color: AppColors.accentRose, size: 20),
                  title: const Text('Delete Account', style: TextStyle(color: AppColors.accentRose, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Permanently delete all your FocusFlow data', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  onTap: () => _confirmDeleteAccount(context, ref),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
