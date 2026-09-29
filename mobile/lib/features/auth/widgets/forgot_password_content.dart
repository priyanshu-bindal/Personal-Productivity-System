import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/error_formatter.dart';
import '../../../providers/auth_provider.dart';
import 'liquid_theme.dart';
import 'liquid_auth_field.dart';
import 'liquid_auth_button.dart';
import 'liquid_auth_link.dart';

/// Clean Forgot Password card content
class ForgotPasswordContent extends ConsumerStatefulWidget {
  final VoidCallback onBackToLogin;
  final TextEditingController emailController;

  const ForgotPasswordContent({
    super.key,
    required this.onBackToLogin,
    required this.emailController,
  });

  @override
  ConsumerState<ForgotPasswordContent> createState() =>
      _ForgotPasswordContentState();
}

class _ForgotPasswordContentState extends ConsumerState<ForgotPasswordContent> {
  bool _submitted = false;
  String? _emailError;

  bool _validateEmail() {
    final email = widget.emailController.text.trim();
    setState(() => _emailError = null);

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address.');
      return false;
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address.');
      return false;
    }
    return true;
  }

  Future<void> _handleReset() async {
    FocusScope.of(context).unfocus();
    if (!_validateEmail()) return;

    try {
      await ref
          .read(authControllerProvider.notifier)
          .resetPassword(widget.emailController.text.trim());
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) {
        setState(() => _emailError = ErrorFormatter.format(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    if (_submitted) {
      return _SuccessView(
        email: widget.emailController.text.trim(),
        onBack: widget.onBackToLogin,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Title & Subtitle ──────────────────────────────────────────
        Text(
          'Reset password',
          textAlign: TextAlign.center,
          style: LiquidTheme.loginTitle(color: LiquidTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          "Enter your email and we'll send you a reset link.",
          textAlign: TextAlign.center,
          style: LiquidTheme.subtitle(fontSize: 13.0),
        ),
        const SizedBox(height: 20),

        // ── Email Field ───────────────────────────────────────────────
        LiquidAuthTextField(
          controller: widget.emailController,
          label: 'Email address',
          hintText: 'Enter your email',
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
        const SizedBox(height: 18),

        // ── Send Reset Link Button ────────────────────────────────────
        LiquidAuthButton(
          label: 'Send reset link',
          isLoading: isLoading,
          onTap: _handleReset,
        ),
        const SizedBox(height: 16),

        // ── Back to Sign In Link ──────────────────────────────────────
        Center(
          child: LiquidAuthLink(
            text: 'Back to Sign In',
            bold: true,
            fontSize: 13.5,
            onTap: () {
              FocusScope.of(context).unfocus();
              widget.onBackToLogin();
            },
          ),
        ),
      ],
    );
  }
}

class _SuccessView extends StatelessWidget {
  final String email;
  final VoidCallback onBack;

  const _SuccessView({
    required this.email,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success Icon Circle (Blue / Soft Violet tint, NO CYAN)
        Center(
          child: Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: LiquidTheme.primary.withValues(alpha: 0.12),
              border: Border.all(
                color: LiquidTheme.primary.withValues(alpha: 0.40),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: LiquidTheme.primary.withValues(alpha: 0.20),
                  blurRadius: 16,
                ),
              ],
            ),
            child: const Icon(
              LucideIcons.mailCheck,
              size: 26,
              color: LiquidTheme.secondaryBlue,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: LiquidTheme.heading(color: LiquidTheme.textPrimary),
        ),
        const SizedBox(height: 6),
        Text(
          "We sent a password reset link to\n$email",
          textAlign: TextAlign.center,
          style: LiquidTheme.subtitle(fontSize: 13.0).copyWith(height: 1.4),
        ),
        const SizedBox(height: 22),

        LiquidAuthButton(
          label: 'Back to Sign In',
          onTap: onBack,
        ),
      ],
    );
  }
}
