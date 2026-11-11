import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_motion.dart';
import '../../../core/theme/oled_theme.dart';
import '../../../core/utils/error_formatter.dart';
import '../../../providers/auth_provider.dart';
import 'auth_heading_v2.dart';
import 'glass_auth_field_v2.dart';
import 'liquid_glass_primary_button_v2.dart';

final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

/// Reset-password flow: request form → "check your inbox" confirmation.
class ForgotPasswordContentV2 extends ConsumerStatefulWidget {
  final TextEditingController emailController;
  final VoidCallback onBackToLogin;

  const ForgotPasswordContentV2({
    super.key,
    required this.emailController,
    required this.onBackToLogin,
  });

  @override
  ConsumerState<ForgotPasswordContentV2> createState() => _ForgotPasswordContentV2State();
}

class _ForgotPasswordContentV2State extends ConsumerState<ForgotPasswordContentV2> {
  bool _submitted = false;
  String? _emailError;
  int _cooldown = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool _validateEmail() {
    final email = widget.emailController.text.trim();
    String? error;
    if (email.isEmpty) {
      error = 'Please enter your email address.';
    } else if (!_emailRegex.hasMatch(email)) {
      error = 'Please enter a valid email address.';
    }
    setState(() => _emailError = error);
    return error == null;
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _cooldown = 30);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _cooldown--);
      if (_cooldown <= 0) t.cancel();
    });
  }

  Future<void> _handleReset() async {
    FocusScope.of(context).unfocus();
    if (!_validateEmail()) return;

    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(widget.emailController.text.trim());
      if (!mounted) return;
      setState(() => _submitted = true);
      _startCooldown();
    } catch (e) {
      if (mounted) setState(() => _emailError = ErrorFormatter.format(e));
    }
  }

  Widget _backButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          FocusScope.of(context).unfocus();
          widget.onBackToLogin();
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.chevronLeft, size: 18, color: OledTheme.accent),
            Text(
              'Sign in',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: OledTheme.accent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isLoading) {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _backButton(),
        const SizedBox(height: 22),
        const Align(
          alignment: Alignment.centerLeft,
          child: AuthIconTileV2(icon: LucideIcons.keyRound),
        ),
        const SizedBox(height: 18),
        const AuthHeadingV2(
          title: 'Reset password',
          subtitle: "Enter the email you signed up with and we'll send you a secure reset link.",
        ),
        GlassAuthFieldV2(
          controller: widget.emailController,
          label: 'Email',
          hintText: 'you@example.com',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email],
          errorText: _emailError,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          onSubmitted: (_) => _handleReset(),
        ),
        const SizedBox(height: 24),
        LiquidGlassPrimaryButtonV2(
          label: 'Send reset link',
          isLoading: isLoading,
          onTap: _handleReset,
        ),
      ],
    );
  }

  Widget _buildSuccess(bool isLoading) {
    final email = widget.emailController.text.trim();
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _backButton(),
        const SizedBox(height: 22),
        const Align(
          alignment: Alignment.centerLeft,
          child: AuthIconTileV2(icon: LucideIcons.mailCheck, color: OledTheme.emerald),
        ),
        const SizedBox(height: 18),
        AuthHeadingV2(
          title: 'Check your inbox',
          subtitle: 'We sent a password reset link to $email. '
              'It may take a minute to arrive.',
        ),
        LiquidGlassPrimaryButtonV2(
          label: 'Back to sign in',
          onTap: widget.onBackToLogin,
        ),
        const SizedBox(height: 10),
        Center(
          child: AnimatedSwitcher(
            duration: AppMotion.fast,
            child: _cooldown > 0
                ? Padding(
                    key: const ValueKey('cooldown'),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      'Resend available in ${_cooldown}s',
                      style: GoogleFonts.inter(fontSize: 13, color: OledTheme.textMuted),
                    ),
                  )
                : AuthTextLink(
                    key: const ValueKey('resend'),
                    label: isLoading ? 'Sending…' : "Didn't get it? Resend",
                    onTap: isLoading ? () {} : _handleReset,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;
    return AnimatedSwitcher(
      duration: AppMotion.standard,
      switchInCurve: AppMotion.enter,
      switchOutCurve: Curves.easeIn,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.topCenter,
        children: [...previous, ?current],
      ),
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero).animate(a),
          child: child,
        ),
      ),
      child: _submitted ? _buildSuccess(isLoading) : _buildForm(isLoading),
    );
  }
}
