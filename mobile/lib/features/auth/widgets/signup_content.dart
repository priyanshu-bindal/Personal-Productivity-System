import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/utils/error_formatter.dart';
import '../../../providers/auth_provider.dart';
import 'liquid_theme.dart';
import 'liquid_auth_field.dart';
import 'liquid_auth_button.dart';
import 'liquid_auth_secondary_button.dart';
import 'liquid_auth_link.dart';

/// Clean, compact Sign Up card content
class SignUpContent extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToLogin;
  final TextEditingController emailController;

  const SignUpContent({
    super.key,
    required this.onSwitchToLogin,
    required this.emailController,
  });

  @override
  ConsumerState<SignUpContent> createState() => _SignUpContentState();
}

class _SignUpContentState extends ConsumerState<SignUpContent> {
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmFocusNode = FocusNode();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _generalError;
  bool _isSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmFocusNode.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(email);

  bool _validate() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
      _generalError = null;
    });

    bool isValid = true;
    final name = _nameController.text.trim();
    final email = widget.emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter your full name.');
      isValid = false;
    }

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address.');
      isValid = false;
    } else if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email address.');
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter a password.');
      isValid = false;
    } else if (password.length < 6) {
      setState(
          () => _passwordError = 'Password must be at least 6 characters.');
      isValid = false;
    }

    if (confirm.isEmpty) {
      setState(() => _confirmError = 'Please confirm your password.');
      isValid = false;
    } else if (password != confirm) {
      setState(() => _confirmError = 'Passwords do not match.');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    if (_isSuccess) return;

    try {
      final res = await ref.read(authControllerProvider.notifier).signUp(
            email: widget.emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );

      if (!mounted) return;

      if (res.session == null && res.user != null) {
        context.go('/email-verification',
            extra: widget.emailController.text.trim());
      } else {
        setState(() => _isSuccess = true);
        context.go('/today');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSuccess = false);
      final msg = ErrorFormatter.format(e);

      if (msg.toLowerCase().contains('already exists') ||
          msg.toLowerCase().contains('already registered')) {
        setState(() => _emailError = msg);
      } else {
        setState(() => _generalError = msg);
      }
    }
  }

  void _handleGoogleSignUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Google registration will be available soon.',
          style: LiquidTheme.small(color: LiquidTheme.textPrimary),
        ),
        backgroundColor: LiquidTheme.secondaryBackground,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: LiquidTheme.border),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Title & Subtitle ──────────────────────────────────────────
        Text(
          'Create Account',
          textAlign: TextAlign.center,
          style: LiquidTheme.loginTitle(color: LiquidTheme.textPrimary),
        ),
        const SizedBox(height: 4),
        Text(
          'Start building better habits with FocusFlow.',
          textAlign: TextAlign.center,
          style: LiquidTheme.subtitle(fontSize: 13.0),
        ),
        const SizedBox(height: 16),

        // ── General Error Banner (Animated) ───────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: _generalError != null
              ? Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: LiquidTheme.errorBg,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: LiquidTheme.errorBorder, width: 1),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.alertTriangle,
                        color: LiquidTheme.errorText,
                        size: 15,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _generalError!,
                          style:
                              LiquidTheme.small(fontSize: 12.5).copyWith(
                            color: LiquidTheme.errorText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // ── Full Name Field ───────────────────────────────────────────
        LiquidAuthTextField(
          controller: _nameController,
          label: 'Full Name',
          hintText: 'Your name',
          prefixIcon: LucideIcons.user,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.name],
          errorText: _nameError,
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          onSubmitted: (_) => _emailFocusNode.requestFocus(),
        ),
        const SizedBox(height: 9),

        // ── Email Field ───────────────────────────────────────────────
        LiquidAuthTextField(
          controller: widget.emailController,
          focusNode: _emailFocusNode,
          label: 'Email address',
          hintText: 'name@example.com',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          errorText: _emailError,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
          onSubmitted: (_) => _passwordFocusNode.requestFocus(),
        ),
        const SizedBox(height: 9),

        // ── Password Field ────────────────────────────────────────────
        LiquidAuthTextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: 'Password',
          hintText: 'At least 6 characters',
          prefixIcon: LucideIcons.lock,
          isPassword: true,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _passwordError,
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
          onSubmitted: (_) => _confirmFocusNode.requestFocus(),
        ),
        const SizedBox(height: 9),

        // ── Confirm Password Field ────────────────────────────────────
        LiquidAuthTextField(
          controller: _confirmController,
          focusNode: _confirmFocusNode,
          label: 'Confirm Password',
          hintText: 'Repeat password',
          prefixIcon: LucideIcons.lock,
          isPassword: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.newPassword],
          errorText: _confirmError,
          onChanged: (_) {
            if (_confirmError != null) setState(() => _confirmError = null);
          },
          onSubmitted: (_) => _handleRegister(),
        ),
        const SizedBox(height: 16),

        // ── Create Account Button ─────────────────────────────────────
        LiquidAuthButton(
          label: 'Create Account',
          isLoading: isLoading,
          onTap: _handleRegister,
        ),
        const SizedBox(height: 12),

        // ── Divider ───────────────────────────────────────────────────
        const LiquidAuthDivider(label: 'or'),
        const SizedBox(height: 12),

        // ── Continue with Google ──────────────────────────────────────
        LiquidAuthSecondaryButton.google(
          onTap: _handleGoogleSignUp,
        ),
        const SizedBox(height: 14),

        // ── Switch to Sign In Prompt ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Already have an account?',
              style: LiquidTheme.small(
                fontSize: 13.0,
                color: LiquidTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            LiquidAuthLink(
              text: 'Sign In',
              bold: true,
              fontSize: 13.0,
              onTap: () {
                FocusScope.of(context).unfocus();
                widget.onSwitchToLogin();
              },
            ),
          ],
        ),
      ],
    );
  }
}
