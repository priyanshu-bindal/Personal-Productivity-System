import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/widgets/pressable_scale.dart';
import '../../core/widgets/trash_confirmation_overlay.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/profile_provider.dart';
import '../../services/supabase_service.dart';
import 'services/pdf_export_service.dart';

// ─── COLOR SYSTEM TOKENS ───────────────────────────────────────────────────────
// True OLED dark productivity palette (~90% black/navy, ~10% blue/cyan accents)
class _SettingsColors {
  static const Color background = Color(0xFF000000);   // true OLED black
  static const Color card = Color(0xFF080D17);          // deep navy card
  static const Color surface = Color(0xFF0B1220);       // secondary surface
  static const Color pressed = Color(0xFF101A2D);       // pressed/selected state
  static const Color border = Color(0xFF162640);        // subtle border
  static const Color primaryBlue = Color(0xFF2F6BFF);   // primary accent
  static const Color cyanAccent = Color(0xFF19BDB3);    // restrained cyan (NOT neon)
  static const Color textPrimary = Color(0xFFF1F5F9);   // primary text
  static const Color textSecondary = Color(0xFF8291A7); // secondary text
  static const Color textMuted = Color(0xFF64748B);     // muted/placeholder text
  static const Color destructive = Color(0xFFFF5C68);   // error/danger
  static const Color destructiveBg = Color(0x12FF5C68); // subtle red bg
  static const Color destructiveBorder = Color(0x30FF5C68); // subtle red border
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);
    final profile = profileAsync.value;

    return Scaffold(
      backgroundColor: _SettingsColors.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AppBar(
          backgroundColor: _SettingsColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Center(
              child: PressableScale(
                scaleFactor: 0.94,
                onTap: () => context.pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _SettingsColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _SettingsColors.border),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.arrowLeft,
                    color: _SettingsColors.textPrimary,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
          title: Text(
            'Settings',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: _SettingsColors.textPrimary,
              letterSpacing: -0.4,
            ),
          ),
          centerTitle: false,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Pending Account Deletion Warning Banner (if scheduled)
              if (profile?.hasPendingDeletion == true) ...[
                _PendingDeletionBanner(profile: profile!),
                const SizedBox(height: 16),
              ],

              // 1. ACCOUNT SECTION
              const _SectionLabel(label: 'ACCOUNT'),
              const SizedBox(height: 10),
              _AccountCard(profile: profile),

              const SizedBox(height: 20),

              // 2. PRACTICE PREFERENCES SECTION
              const _SectionLabel(label: 'PRACTICE PREFERENCES'),
              const SizedBox(height: 10),
              _PracticePreferencesCard(profile: profile),

              const SizedBox(height: 20),

              // 3. NOTIFICATIONS SECTION
              const _SectionLabel(label: 'NOTIFICATIONS'),
              const SizedBox(height: 10),
              _NotificationsCard(profile: profile),

              const SizedBox(height: 20),

              // 4. DATA & PRIVACY SECTION
              const _SectionLabel(label: 'DATA & PRIVACY'),
              const SizedBox(height: 10),
              const _DataAndPrivacyCard(),

              const SizedBox(height: 20),

              // 5. DANGER ZONE SECTION
              const _SectionLabel(
                label: 'DANGER ZONE',
                color: _SettingsColors.destructive,
              ),
              const SizedBox(height: 10),
              _DangerZoneCard(profile: profile),

              const SizedBox(height: 20),

              // 6. ABOUT SECTION
              const _SectionLabel(label: 'ABOUT'),
              const SizedBox(height: 10),
              const _AboutCard(),

              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── SECTION LABEL ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color? color;

  const _SectionLabel({required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: color ?? _SettingsColors.textSecondary,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

// ─── PENDING DELETION BANNER ──────────────────────────────────────────────────

class _PendingDeletionBanner extends ConsumerStatefulWidget {
  final UserProfile profile;

  const _PendingDeletionBanner({required this.profile});

  @override
  ConsumerState<_PendingDeletionBanner> createState() =>
      _PendingDeletionBannerState();
}

class _PendingDeletionBannerState
    extends ConsumerState<_PendingDeletionBanner> {
  bool _cancelling = false;

  Future<void> _handleCancel() async {
    setState(() => _cancelling = true);
    try {
      await ref.read(profileProvider.notifier).cancelDeletion();
      if (mounted) {
        TrashConfirmationOverlay.showSuccess(
          context: context,
          message: 'Account deletion canceled',
          icon: LucideIcons.checkCircle2,
          iconColor: _SettingsColors.primaryBlue,
        );
      }
    } catch (e) {
      if (mounted) {
        TrashConfirmationOverlay.showError(
          context: context,
          message: "Couldn't cancel deletion. Please try again.",
        );
      }
    } finally {
      if (mounted) {
        setState(() => _cancelling = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = widget.profile.deletionScheduledFor != null
        ? DateFormat('MMM d, yyyy')
            .format(widget.profile.deletionScheduledFor!.toLocal())
        : 'in 15 days';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _SettingsColors.destructiveBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SettingsColors.destructiveBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _SettingsColors.destructive.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  LucideIcons.alertTriangle,
                  color: _SettingsColors.destructive,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Account deletion scheduled',
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: _SettingsColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your data will be permanently deleted on $dateStr',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: _SettingsColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: PressableScale(
              scaleFactor: 0.97,
              onTap: _cancelling ? null : _handleCancel,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: _SettingsColors.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _SettingsColors.border),
                ),
                alignment: Alignment.center,
                child: _cancelling
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: _SettingsColors.textPrimary,
                        ),
                      )
                    : Text(
                        'Cancel deletion',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _SettingsColors.textPrimary,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ACCOUNT CARD ─────────────────────────────────────────────────────────────

class _AccountCard extends ConsumerWidget {
  final UserProfile? profile;

  const _AccountCard({required this.profile});

  void _openEditProfileSheet(BuildContext context) {
    _SmoothAnimatedDialog.show(
      context: context,
      child: _EditProfileModal(profile: profile),
    );
  }

  void _openChangePasswordSheet(BuildContext context) {
    _SmoothAnimatedDialog.show(
      context: context,
      child: const _ChangePasswordModal(),
    );
  }

  void _openSignOutDialog(BuildContext context, WidgetRef ref) {
    _SmoothAnimatedDialog.show(
      context: context,
      child: _SignOutDialog(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fullName = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : 'FocusFlow User';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';
    final email = profile?.email ?? 'No email available';

    return Container(
      decoration: BoxDecoration(
        color: _SettingsColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SettingsColors.border, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          children: [
            // Top: Avatar + Name + Email + Edit Profile Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Circular Avatar with subtle blue/cyan outline (no neon)
                  PressableScale(
                    scaleFactor: 0.97,
                    onTap: () => _openEditProfileSheet(context),
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _SettingsColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _SettingsColors.primaryBlue.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initial,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: _SettingsColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  // Name & Email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _SettingsColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: _SettingsColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Edit Profile Button (clean dark navy with subtle blue border)
                  PressableScale(
                    scaleFactor: 0.95,
                    onTap: () => _openEditProfileSheet(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _SettingsColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _SettingsColors.primaryBlue.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.edit2,
                            size: 11,
                            color: _SettingsColors.textSecondary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Edit Profile',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: _SettingsColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: _SettingsColors.border),

            // Focus ID Section
            const Padding(
              padding: EdgeInsets.all(14),
              child: _FocusIdRow(),
            ),

            const Divider(height: 1, color: _SettingsColors.border),

            // Change Password Action Row
            _SettingsActionTile(
              icon: LucideIcons.keyRound,
              iconColor: _SettingsColors.primaryBlue,
              title: 'Change Password',
              titleColor: _SettingsColors.textPrimary,
              trailing: const Icon(
                LucideIcons.chevronRight,
                color: _SettingsColors.textSecondary,
                size: 16,
              ),
              onTap: () => _openChangePasswordSheet(context),
            ),

            const Divider(height: 1, color: _SettingsColors.border),

            // Sign Out Action Row
            _SettingsActionTile(
              icon: LucideIcons.logOut,
              iconColor: _SettingsColors.destructive,
              title: 'Sign Out',
              titleColor: _SettingsColors.destructive,
              onTap: () => _openSignOutDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FOCUS ID ROW ─────────────────────────────────────────────────────────────

class _FocusIdRow extends ConsumerStatefulWidget {
  const _FocusIdRow();

  @override
  ConsumerState<_FocusIdRow> createState() => _FocusIdRowState();
}

class _FocusIdRowState extends ConsumerState<_FocusIdRow> {
  bool _copied = false;

  void _copy(String shortId) {
    Clipboard.setData(ClipboardData(text: shortId));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatIdAsync = ref.watch(currentChatUserShortIdProvider);
    final chatId = chatIdAsync.value ?? '···';
    final canCopy = chatId != '···';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _SettingsColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _SettingsColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: _SettingsColors.primaryBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _SettingsColors.primaryBlue.withValues(alpha: 0.35),
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.hash,
              color: _SettingsColors.primaryBlue,
              size: 14,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR FOCUS ID',
                  style: GoogleFonts.spaceGrotesk(
                    color: _SettingsColors.textSecondary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '#$chatId',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBFDBFE),
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          PressableScale(
            scaleFactor: 0.94,
            onTap: canCopy ? () => _copy(chatId) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _copied
                    ? _SettingsColors.primaryBlue.withValues(alpha: 0.15)
                    : _SettingsColors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _copied
                      ? _SettingsColors.primaryBlue.withValues(alpha: 0.5)
                      : _SettingsColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _copied ? LucideIcons.check : LucideIcons.copy,
                      key: ValueKey<bool>(_copied),
                      size: 13,
                      color: _copied
                          ? _SettingsColors.primaryBlue
                          : _SettingsColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    _copied ? 'Copied' : 'Copy',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _copied
                          ? _SettingsColors.primaryBlue
                          : _SettingsColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PRACTICE PREFERENCES CARD ────────────────────────────────────────────────

class _PracticePreferencesCard extends ConsumerWidget {
  final UserProfile? profile;

  const _PracticePreferencesCard({required this.profile});

  void _openDurationSheet(BuildContext context, WidgetRef ref) {
    _SmoothAnimatedDialog.show(
      context: context,
      child: _DurationSelectorModal(
        currentDuration: profile?.defaultSessionDuration ?? 60,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duration = profile?.defaultSessionDuration ?? 60;

    return Container(
      decoration: BoxDecoration(
        color: _SettingsColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SettingsColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: PressableScale(
          scaleFactor: 0.99,
          duration: const Duration(milliseconds: 120),
          onTap: () => _openDurationSheet(context, ref),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openDurationSheet(context, ref),
              hoverColor: _SettingsColors.surface,
              splashColor: _SettingsColors.primaryBlue.withValues(alpha: 0.1),
              highlightColor: _SettingsColors.pressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _SettingsColors.surface,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _SettingsColors.border),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.clock,
                      color: _SettingsColors.primaryBlue,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Default Session Duration',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: _SettingsColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Target time for new focus sessions',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _SettingsColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Small selected pill
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _SettingsColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _SettingsColors.primaryBlue.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      '$duration mins',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _SettingsColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  }
}

// ─── DURATION SELECTOR MODAL ──────────────────────────────────────────────────

class _DurationSelectorModal extends ConsumerWidget {
  final int currentDuration;

  const _DurationSelectorModal({required this.currentDuration});

  static const List<int> durations = [30, 45, 60, 90, 120];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default Session Duration',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _SettingsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the baseline duration for practice sessions',
          style: GoogleFonts.inter(
              fontSize: 12.5, color: _SettingsColors.textSecondary),
        ),
        const SizedBox(height: 16),
        ...durations.map((duration) {
          final isSelected = duration == currentDuration;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref
                      .read(profileProvider.notifier)
                      .updatePreferences(defaultSessionDuration: duration);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? _SettingsColors.surface
                        : _SettingsColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? _SettingsColors.primaryBlue
                          : _SettingsColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$duration mins',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? _SettingsColors.textPrimary
                              : _SettingsColors.textSecondary,
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          LucideIcons.check,
                          color: _SettingsColors.primaryBlue,
                          size: 17,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ─── NOTIFICATIONS CARD ───────────────────────────────────────────────────────

class _NotificationsCard extends ConsumerWidget {
  final UserProfile? profile;

  const _NotificationsCard({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersEnabled = profile?.practiceReminders ?? true;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _SettingsColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SettingsColors.border, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _SettingsColors.surface,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _SettingsColors.border),
            ),
            alignment: Alignment.center,
            child: const Icon(
              LucideIcons.bell,
              color: _SettingsColors.primaryBlue,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Daily Practice Reminders',
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: _SettingsColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Receive a prompt to stay on streak',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: _SettingsColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: remindersEnabled,
            activeTrackColor: _SettingsColors.primaryBlue,
            activeThumbColor: Colors.white,
            inactiveTrackColor: _SettingsColors.surface,
            inactiveThumbColor: _SettingsColors.textMuted,
            trackOutlineColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return _SettingsColors.primaryBlue;
              }
              return _SettingsColors.border;
            }),
            onChanged: (val) {
              ref
                  .read(profileProvider.notifier)
                  .updatePreferences(practiceReminders: val);
            },
          ),
        ],
      ),
    );
  }
}

// ─── DATA & PRIVACY CARD ──────────────────────────────────────────────────────

class _DataAndPrivacyCard extends ConsumerStatefulWidget {
  const _DataAndPrivacyCard();

  @override
  ConsumerState<_DataAndPrivacyCard> createState() =>
      _DataAndPrivacyCardState();
}

class _DataAndPrivacyCardState extends ConsumerState<_DataAndPrivacyCard> {
  bool _isExporting = false;

  Future<void> _handlePdfExport() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      final profile = ref.read(profileProvider).value;
      final focusId = ref.read(currentChatUserShortIdProvider).value;

      await PdfExportService.exportAndShareData(
        profile: profile,
        focusId: focusId,
      );

      if (mounted) {
        TrashConfirmationOverlay.showSuccess(
          context: context,
          message: 'Personal data PDF exported successfully',
          icon: LucideIcons.check,
          iconColor: _SettingsColors.cyanAccent,
        );
      }
    } catch (e, stack) {
      debugPrint('PDF export technical error: $e\n$stack');
      if (mounted) {
        final message = e is PdfShareException
            ? "PDF created, but it couldn't be shared."
            : "Unable to export your data. Please try again.";
        TrashConfirmationOverlay.showError(
          context: context,
          message: message,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _SettingsColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SettingsColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          children: [
            // Export Personal Data as PDF (fills full width properly)
            _SettingsNavigationTile(
              icon: LucideIcons.fileDown,
              iconColor: _SettingsColors.cyanAccent,
              title: 'Export Personal Data',
              subtitle: 'Download your FocusFlow data as a PDF',
              trailing: _isExporting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _SettingsColors.cyanAccent,
                      ),
                    )
                  : const Icon(
                      LucideIcons.chevronRight,
                      color: _SettingsColors.textSecondary,
                      size: 16,
                    ),
              onTap: _handlePdfExport,
            ),
            const Divider(height: 1, color: _SettingsColors.border),
            // Trash (fills full width properly)
            _SettingsNavigationTile(
              icon: LucideIcons.trash2,
              iconColor: _SettingsColors.primaryBlue,
              title: 'Trash',
              subtitle: 'Restore deleted expenses',
              onTap: () => context.push('/money/trash'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── DANGER ZONE CARD ─────────────────────────────────────────────────────────

class _DangerZoneCard extends ConsumerWidget {
  final UserProfile? profile;

  const _DangerZoneCard({required this.profile});

  void _openDeleteAccountSafetyFlow(BuildContext context, WidgetRef ref) {
    _SmoothAnimatedDialog.show(
      context: context,
      child: _DeleteAccountModal(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: _SettingsColors.destructiveBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SettingsColors.destructiveBorder, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: PressableScale(
          scaleFactor: 0.99,
          duration: const Duration(milliseconds: 120),
          onTap: () => _openDeleteAccountSafetyFlow(context, ref),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _openDeleteAccountSafetyFlow(context, ref),
              hoverColor: _SettingsColors.destructive.withValues(alpha: 0.1),
              splashColor: _SettingsColors.destructive.withValues(alpha: 0.16),
              highlightColor: _SettingsColors.destructive.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _SettingsColors.destructive.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: _SettingsColors.destructive.withValues(alpha: 0.35),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        LucideIcons.userX,
                        color: _SettingsColors.destructive,
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delete Account',
                            style: GoogleFonts.inter(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: _SettingsColors.destructive,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Permanently delete your FocusFlow account',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: _SettingsColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      LucideIcons.chevronRight,
                      color: _SettingsColors.destructive,
                      size: 17,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ABOUT CARD ───────────────────────────────────────────────────────────────

class _AboutCard extends StatelessWidget {
  const _AboutCard();

  void _showPolicyDialog(BuildContext context, String title, String body) {
    _SmoothAnimatedDialog.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _SettingsColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Text(
                body,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: _SettingsColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerRight,
            child: PressableScale(
              scaleFactor: 0.96,
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: _SettingsColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _SettingsColors.border),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _SettingsColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _SettingsColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _SettingsColors.border, width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Column(
          children: [
            // App Name & Version
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _SettingsColors.surface,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _SettingsColors.border),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      LucideIcons.info,
                      color: _SettingsColors.primaryBlue,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FocusFlow',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: _SettingsColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Version 1.0.0',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _SettingsColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: _SettingsColors.border),
            // Privacy Policy
            _SettingsNavigationTile(
              icon: LucideIcons.shieldCheck,
              iconColor: _SettingsColors.cyanAccent,
              title: 'Privacy Policy',
              subtitle: 'Learn how your data is protected',
              onTap: () => _showPolicyDialog(
                context,
                'Privacy Policy',
                'FocusFlow is engineered with strict data ownership principles.\n\n'
                '1. Data Ownership: All skills, sessions, notes, and financial logs belong strictly to you.\n\n'
                '2. Security: Cloud synchronization is handled through encrypted connections with Supabase row-level security.\n\n'
                '3. No Profiling: FocusFlow never sells, shares, or monetizes personal activity or practice patterns.',
              ),
            ),
            const Divider(height: 1, color: _SettingsColors.border),
            // Terms of Service
            _SettingsNavigationTile(
              icon: LucideIcons.fileText,
              iconColor: _SettingsColors.primaryBlue,
              title: 'Terms of Service',
              subtitle: 'User agreement and service conditions',
              onTap: () => _showPolicyDialog(
                context,
                'Terms of Service',
                'Welcome to FocusFlow.\n\n'
                'By accessing or using FocusFlow, you agree to utilize the application for legitimate personal productivity and learning tracking.\n\n'
                '1. Account Responsibility: You are responsible for safeguarding your login credentials.\n\n'
                '2. Continuity: You may export or delete your personal data at any time via Settings.\n\n'
                '3. Availability: FocusFlow strives for reliable synchronization across devices.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── EDIT PROFILE MODAL ───────────────────────────────────────────────────────

class _EditProfileModal extends ConsumerStatefulWidget {
  final UserProfile? profile;

  const _EditProfileModal({required this.profile});

  @override
  ConsumerState<_EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends ConsumerState<_EditProfileModal> {
  late final TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.profile?.fullName ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(profileProvider.notifier)
          .updateProfile(fullName: newName);
      if (mounted) {
        Navigator.of(context).pop();
        TrashConfirmationOverlay.showSuccess(
          context: context,
          message: 'Profile updated',
          icon: LucideIcons.check,
          iconColor: _SettingsColors.primaryBlue,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        TrashConfirmationOverlay.showError(
          context: context,
          message: "Couldn't update profile: $e",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.profile?.email ?? 'No email available';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Edit Profile',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: _SettingsColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Update your public name and details',
          style: GoogleFonts.inter(
              fontSize: 12.5, color: _SettingsColors.textSecondary),
        ),
        const SizedBox(height: 20),

        // Full Name Field
        Text(
          'FULL NAME',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: _SettingsColors.textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _SettingsColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _SettingsColors.border),
          ),
          child: TextField(
            controller: _nameController,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _SettingsColors.textPrimary,
            ),
            decoration: const InputDecoration(
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
              hintText: 'Enter your name',
              hintStyle: TextStyle(color: _SettingsColors.textMuted),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Email Field (Read-only)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'EMAIL',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: _SettingsColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Read-only',
              style: GoogleFonts.inter(
                fontSize: 10,
                color: _SettingsColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _SettingsColors.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: _SettingsColors.border.withValues(alpha: 0.6)),
          ),
          child: Text(
            email,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: _SettingsColors.textSecondary,
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PressableScale(
              scaleFactor: 0.96,
              onTap: _isSaving ? null : () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: _SettingsColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _SettingsColors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _SettingsColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            PressableScale(
              scaleFactor: 0.96,
              onTap: _isSaving ? null : _handleSave,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: _isSaving
                      ? _SettingsColors.primaryBlue.withValues(alpha: 0.6)
                      : _SettingsColors.primaryBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── CHANGE PASSWORD MODAL ───────────────────────────────────────────────────

class _ChangePasswordModal extends StatefulWidget {
  const _ChangePasswordModal();

  @override
  State<_ChangePasswordModal> createState() => _ChangePasswordModalState();
}

class _ChangePasswordModalState extends State<_ChangePasswordModal> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _currentFocusNode = FocusNode();
  final FocusNode _newFocusNode = FocusNode();
  final FocusNode _confirmFocusNode = FocusNode();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isUpdating = false;

  bool _hasCurrentError = false;
  bool _hasNewError = false;
  bool _hasConfirmError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentFocusNode.addListener(_onFocusChange);
    _newFocusNode.addListener(_onFocusChange);
    _confirmFocusNode.addListener(_onFocusChange);

    _currentPasswordController.addListener(() {
      if (_hasCurrentError) setState(() => _hasCurrentError = false);
    });
    _newPasswordController.addListener(() {
      if (_hasNewError) setState(() => _hasNewError = false);
    });
    _confirmPasswordController.addListener(() {
      if (_hasConfirmError) setState(() => _hasConfirmError = false);
    });
  }

  void _onFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _currentFocusNode.removeListener(_onFocusChange);
    _newFocusNode.removeListener(_onFocusChange);
    _confirmFocusNode.removeListener(_onFocusChange);

    _currentFocusNode.dispose();
    _newFocusNode.dispose();
    _confirmFocusNode.dispose();

    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _hasCurrentError = currentPassword.isEmpty;
        _hasNewError = newPassword.isEmpty;
        _hasConfirmError = confirmPassword.isEmpty;
        _errorMessage = 'Please fill in all password fields.';
      });
      return;
    }

    if (newPassword.length < 6) {
      setState(() {
        _hasCurrentError = false;
        _hasNewError = true;
        _hasConfirmError = false;
        _errorMessage = 'New password must be at least 6 characters.';
      });
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() {
        _hasCurrentError = false;
        _hasNewError = false;
        _hasConfirmError = true;
        _errorMessage = 'New passwords do not match.';
      });
      return;
    }

    setState(() {
      _isUpdating = true;
      _hasCurrentError = false;
      _hasNewError = false;
      _hasConfirmError = false;
      _errorMessage = null;
    });

    try {
      final user = SupabaseService.currentUser;
      if (user?.email == null) {
        throw Exception('User email not found.');
      }

      // 1. Re-verify current credentials
      await SupabaseService.client.auth.signInWithPassword(
        email: user!.email!,
        password: currentPassword,
      );

      // 2. Update to new password securely
      await SupabaseService.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (mounted) {
        Navigator.of(context).pop();
        TrashConfirmationOverlay.showSuccess(
          context: context,
          message: 'Password updated successfully',
          icon: LucideIcons.check,
          iconColor: _SettingsColors.primaryBlue,
        );
      }
    } catch (e) {
      if (mounted) {
        final isInvalidCreds = e.toString().contains('Invalid login credentials');
        setState(() {
          _isUpdating = false;
          _hasCurrentError = isInvalidCreds;
          _hasNewError = false;
          _hasConfirmError = false;
          _errorMessage = isInvalidCreds
              ? 'Current password is incorrect.'
              : 'Failed to update password. Please check your credentials.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF0F1A30),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1B2D4D), width: 1),
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.keyRound,
                color: Color(0xFF2F6BFF),
                size: 17,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Change Password',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Enter your current password and choose a new one.',
          style: GoogleFonts.inter(
            fontSize: 12.5,
            color: _SettingsColors.textSecondary,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 14),

        // Animated Error Banner
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: _errorMessage != null
              ? Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _SettingsColors.destructiveBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _SettingsColors.destructiveBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.alertCircle,
                        color: _SettingsColors.destructive,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _SettingsColors.destructive,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Current Password Field
        _buildPasswordField(
          label: 'CURRENT PASSWORD',
          controller: _currentPasswordController,
          focusNode: _currentFocusNode,
          obscureText: _obscureCurrent,
          hasError: _hasCurrentError,
          onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
        ),
        const SizedBox(height: 13),

        // New Password Field
        _buildPasswordField(
          label: 'NEW PASSWORD',
          controller: _newPasswordController,
          focusNode: _newFocusNode,
          obscureText: _obscureNew,
          hasError: _hasNewError,
          onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 13),

        // Confirm New Password Field
        _buildPasswordField(
          label: 'CONFIRM NEW PASSWORD',
          controller: _confirmPasswordController,
          focusNode: _confirmFocusNode,
          obscureText: _obscureConfirm,
          hasError: _hasConfirmError,
          onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        const SizedBox(height: 22),

        // Bottom Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Cancel button
            PressableScale(
              scaleFactor: 0.98,
              duration: const Duration(milliseconds: 120),
              onTap: _isUpdating ? null : () => Navigator.of(context).pop(),
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: _SettingsColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _SettingsColors.border),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _SettingsColors.textSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            // Update Password button
            PressableScale(
              scaleFactor: _isUpdating ? 1.0 : 0.98,
              duration: const Duration(milliseconds: 120),
              onTap: _isUpdating ? null : _handleUpdatePassword,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: _isUpdating
                      ? const Color(0xFF2F6BFF).withValues(alpha: 0.65)
                      : const Color(0xFF2F6BFF),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: _isUpdating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Update Password',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool obscureText,
    required bool hasError,
    required VoidCallback onToggleObscure,
  }) {
    final isFocused = focusNode.hasFocus;

    final Color borderColor;
    final List<BoxShadow> shadows;

    if (isFocused) {
      borderColor = const Color(0xFF2F6BFF);
      shadows = const [
        BoxShadow(
          color: Color(0x242F6BFF),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ];
    } else if (hasError) {
      borderColor = _SettingsColors.destructive;
      shadows = const [
        BoxShadow(
          color: Color(0x18FF5C68),
          blurRadius: 6,
          spreadRadius: 0,
        ),
      ];
    } else {
      borderColor = _SettingsColors.border;
      shadows = const [];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _SettingsColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 48,
          decoration: BoxDecoration(
            color: _SettingsColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderColor, width: isFocused ? 1.2 : 1.0),
            boxShadow: shadows,
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscureText,
                  cursorColor: const Color(0xFF2F6BFF),
                  cursorWidth: 1.5,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: _SettingsColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    isDense: true,
                    hintText: '••••••••',
                    hintStyle: TextStyle(
                      color: _SettingsColors.textMuted,
                      letterSpacing: 2.0,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              // Dedicated compact trailing area with subtle vertical divider
              Container(
                width: 1,
                height: 20,
                color: _SettingsColors.border,
              ),
              PressableScale(
                scaleFactor: 0.92,
                duration: const Duration(milliseconds: 140),
                onTap: onToggleObscure,
                child: Container(
                  width: 44,
                  height: 48,
                  alignment: Alignment.center,
                  color: Colors.transparent,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 140),
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: Icon(
                      obscureText ? LucideIcons.eyeOff : LucideIcons.eye,
                      key: ValueKey<bool>(obscureText),
                      color: _SettingsColors.textSecondary,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── SIGN OUT CONFIRMATION DIALOG ─────────────────────────────────────────────

class _SignOutDialog extends StatefulWidget {
  final WidgetRef ref;

  const _SignOutDialog({required this.ref});

  @override
  State<_SignOutDialog> createState() => _SignOutDialogState();
}

class _SignOutDialogState extends State<_SignOutDialog> {
  bool _isSigningOut = false;

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);
    try {
      Navigator.of(context).pop();
      await widget.ref.read(authControllerProvider.notifier).signOut();
    } catch (_) {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _SettingsColors.destructive.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.logOut,
                color: _SettingsColors.destructive,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Sign out?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _SettingsColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "You'll need to sign in again to access FocusFlow.",
          style: GoogleFonts.inter(
            fontSize: 13.5,
            color: _SettingsColors.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: PressableScale(
                scaleFactor: 0.96,
                onTap: _isSigningOut ? null : () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _SettingsColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _SettingsColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _SettingsColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PressableScale(
                scaleFactor: 0.96,
                onTap: _isSigningOut ? null : _handleSignOut,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _SettingsColors.destructive,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: _isSigningOut
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Sign Out',
                          style: GoogleFonts.inter(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── DELETE ACCOUNT SAFETY FLOW MODAL ─────────────────────────────────────────

class _DeleteAccountModal extends StatefulWidget {
  final WidgetRef ref;

  const _DeleteAccountModal({required this.ref});

  @override
  State<_DeleteAccountModal> createState() => _DeleteAccountModalState();
}

class _DeleteAccountModalState extends State<_DeleteAccountModal> {
  final TextEditingController _confirmController = TextEditingController();
  bool _isScheduling = false;
  bool _isConfirmed = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() {
      final matches = _confirmController.text.trim() == 'DELETE';
      if (matches != _isConfirmed) {
        setState(() => _isConfirmed = matches);
      }
    });
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleScheduleDeletion() async {
    if (!_isConfirmed) return;
    setState(() => _isScheduling = true);

    try {
      await widget.ref.read(profileProvider.notifier).scheduleDeletion();
      if (mounted) {
        Navigator.of(context).pop();
        TrashConfirmationOverlay.showSuccess(
          context: context,
          message: 'Account deletion scheduled (15-day recovery window)',
          icon: LucideIcons.calendar,
          iconColor: _SettingsColors.destructive,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isScheduling = false);
        TrashConfirmationOverlay.showError(
          context: context,
          message: "Couldn't schedule deletion: $e",
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _SettingsColors.destructive.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                LucideIcons.alertTriangle,
                color: _SettingsColors.destructive,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Delete your account?',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: _SettingsColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Explanatory note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _SettingsColors.destructiveBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _SettingsColors.destructiveBorder),
          ),
          child: Text(
            'Your account will remain recoverable for 15 days. After that, it will be permanently deleted.',
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: _SettingsColors.textPrimary,
              height: 1.4,
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Data inventory explanation
        Text(
          'What happens after 15 days:',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _SettingsColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        const _DataBullet(
            text: 'Profile: Name, avatar, and personal preferences'),
        const _DataBullet(
            text: 'Skills: All skills, topics, and progress stats'),
        const _DataBullet(
            text: 'Learning Sessions: Complete practice history'),
        const _DataBullet(
            text: 'Expenses & Budgets: Financial entries and categories'),
        const _DataBullet(
            text: 'Notes & Goals: All written notes and task milestones'),

        const SizedBox(height: 16),

        // Confirmation instructions
        Text(
          'Type DELETE to confirm',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: _SettingsColors.textSecondary,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _SettingsColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _isConfirmed
                  ? _SettingsColors.destructive
                  : _SettingsColors.border,
            ),
          ),
          child: TextField(
            controller: _confirmController,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _SettingsColors.textPrimary,
              letterSpacing: 1.0,
            ),
            decoration: InputDecoration(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: InputBorder.none,
              hintText: 'DELETE',
              hintStyle: TextStyle(
                color: _SettingsColors.textMuted.withValues(alpha: 0.6),
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: PressableScale(
                scaleFactor: 0.96,
                onTap: _isScheduling ? null : () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _SettingsColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _SettingsColors.border),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _SettingsColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: PressableScale(
                scaleFactor: _isConfirmed ? 0.96 : 1.0,
                onTap: (_isConfirmed && !_isScheduling)
                    ? _handleScheduleDeletion
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: _isConfirmed
                        ? _SettingsColors.destructive
                        : _SettingsColors.destructive.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: _isScheduling
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Schedule Account Deletion',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: _isConfirmed
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DataBullet extends StatelessWidget {
  final String text;

  const _DataBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 8),
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: _SettingsColors.textSecondary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _SettingsColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── REUSABLE TILES & INTERACTIVE COMPONENTS ─────────────────────────────────

class _SettingsActionTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color titleColor;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.titleColor,
    this.trailing,
    required this.onTap,
  });

  @override
  State<_SettingsActionTile> createState() => _SettingsActionTileState();
}

class _SettingsActionTileState extends State<_SettingsActionTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleFactor: 0.99,
      duration: const Duration(milliseconds: 120),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _isPressed ? _SettingsColors.pressed : Colors.transparent,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onHighlightChanged: (val) => setState(() => _isPressed = val),
            onTap: widget.onTap,
            hoverColor: _SettingsColors.surface,
            splashColor: widget.iconColor.withValues(alpha: 0.12),
            highlightColor: _SettingsColors.pressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(widget.icon, color: widget.iconColor, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: GoogleFonts.inter(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: widget.titleColor,
                      ),
                    ),
                  ),
                  ?widget.trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsNavigationTile extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsNavigationTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    required this.onTap,
  });

  @override
  State<_SettingsNavigationTile> createState() =>
      _SettingsNavigationTileState();
}

class _SettingsNavigationTileState extends State<_SettingsNavigationTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      scaleFactor: 0.99,
      duration: const Duration(milliseconds: 120),
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        color: _isPressed ? _SettingsColors.pressed : Colors.transparent,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onHighlightChanged: (val) => setState(() => _isPressed = val),
            onTap: widget.onTap,
            hoverColor: _SettingsColors.surface,
            splashColor: _SettingsColors.primaryBlue.withValues(alpha: 0.1),
            highlightColor: _SettingsColors.pressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _SettingsColors.surface,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: _SettingsColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Icon(widget.icon, color: widget.iconColor, size: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: _SettingsColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: _SettingsColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  widget.trailing ??
                      const Icon(
                        LucideIcons.chevronRight,
                        color: _SettingsColors.textSecondary,
                        size: 16,
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

// ─── SMOOTH ANIMATED MODAL DIALOG ─────────────────────────────────────────────

class _SmoothAnimatedDialog {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 270),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, animation, secondaryAnimation, childWidget) {
        final isClosing = animation.status == AnimationStatus.reverse ||
            animation.status == AnimationStatus.dismissed;

        final dialogContent = Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
          elevation: 0,
          child: Container(
            constraints: const BoxConstraints(maxWidth: 440),
            decoration: BoxDecoration(
              color: _SettingsColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _SettingsColors.border, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x66000000),
                  blurRadius: 28,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: child,
                ),
              ),
            ),
          ),
        );

        if (isClosing) {
          final closeCurve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: closeCurve,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.96, end: 1.0).animate(closeCurve),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(closeCurve),
                child: dialogContent,
              ),
            ),
          );
        }

        final openCurve = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: openCurve,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.96, end: 1.0).animate(openCurve),
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(openCurve),
              child: dialogContent,
            ),
          ),
        );
      },
    );
  }
}
