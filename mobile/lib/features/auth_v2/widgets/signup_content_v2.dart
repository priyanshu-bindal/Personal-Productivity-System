import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

/// Create-account form.
class SignUpContentV2 extends ConsumerStatefulWidget {
  final TextEditingController emailController;
  final VoidCallback onSwitchToLogin;

  const SignUpContentV2({
    super.key,
    required this.emailController,
    required this.onSwitchToLogin,
  });

  @override
  ConsumerState<SignUpContentV2> createState() => _SignUpContentV2State();
}

class _SignUpContentV2State extends ConsumerState<SignUpContentV2> {
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

  bool _validate() {
    final name = _nameController.text.trim();
    final email = widget.emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    String? nameError, emailError, passwordError, confirmError;
    if (name.isEmpty) nameError = 'Please enter your full name.';
    if (email.isEmpty) {
      emailError = 'Please enter your email address.';
    } else if (!_emailRegex.hasMatch(email)) {
      emailError = 'Please enter a valid email address.';
    }
    if (password.isEmpty) {
      passwordError = 'Please enter a password.';
    } else if (password.length < 6) {
      passwordError = 'Password must be at least 6 characters.';
    }
    if (confirm.isEmpty) {
      confirmError = 'Please confirm your password.';
    } else if (password != confirm) {
      confirmError = 'Passwords do not match.';
    }

    setState(() {
      _nameError = nameError;
      _emailError = emailError;
      _passwordError = passwordError;
      _confirmError = confirmError;
      _generalError = null;
    });
    return nameError == null &&
        emailError == null &&
        passwordError == null &&
        confirmError == null;
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_validate() || _isSuccess) return;

    try {
      final res = await ref.read(authControllerProvider.notifier).signUp(
            email: widget.emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );
      if (!mounted) return;
      if (res.session == null && res.user != null) {
        context.go('/email-verification', extra: widget.emailController.text.trim());
      } else {
        setState(() => _isSuccess = true);
        context.go('/today');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = ErrorFormatter.format(e);
      final lower = msg.toLowerCase();
      setState(() {
        _isSuccess = false;
        if (lower.contains('already exists') || lower.contains('already registered')) {
          _emailError = msg;
        } else {
          _generalError = msg;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return AutofillGroup(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const AuthHeadingV2(
            title: 'Create your account',
            subtitle: 'Build steady habits, one focused session at a time.',
          ),
          AuthErrorBanner(message: _generalError),
          GlassAuthFieldV2(
            controller: _nameController,
            label: 'Full name',
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
          const SizedBox(height: 16),
          GlassAuthFieldV2(
            controller: widget.emailController,
            focusNode: _emailFocusNode,
            label: 'Email',
            hintText: 'you@example.com',
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
          const SizedBox(height: 16),
          GlassAuthFieldV2(
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
          _PasswordStrength(controller: _passwordController),
          const SizedBox(height: 16),
          GlassAuthFieldV2(
            controller: _confirmController,
            focusNode: _confirmFocusNode,
            label: 'Confirm password',
            hintText: 'Repeat password',
            prefixIcon: LucideIcons.shieldCheck,
            isPassword: true,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            errorText: _confirmError,
            onChanged: (_) {
              if (_confirmError != null) setState(() => _confirmError = null);
            },
            onSubmitted: (_) => _handleRegister(),
          ),
          const SizedBox(height: 26),
          LiquidGlassPrimaryButtonV2(
            label: 'Create account',
            isLoading: isLoading,
            onTap: _handleRegister,
          ),
          const SizedBox(height: 14),
          Text(
            'By continuing you agree to the Terms of Service and Privacy Policy.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: OledTheme.textMuted,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Four-segment strength meter that fills as the password improves.
class _PasswordStrength extends StatelessWidget {
  final TextEditingController controller;
  const _PasswordStrength({required this.controller});

  static int _score(String p) {
    if (p.isEmpty) return 0;
    var s = 0;
    if (p.length >= 6) s++;
    if (p.length >= 10) s++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) s++;
    if (RegExp(r'[0-9]').hasMatch(p) && RegExp(r'[^A-Za-z0-9]').hasMatch(p)) s++;
    return s.clamp(1, 4);
  }

  static const _labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];
  static const _colors = [
    OledTheme.border,
    OledTheme.coral,
    OledTheme.amber,
    OledTheme.accent,
    OledTheme.emerald,
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final score = _score(value.text);
        return AnimatedSize(
          duration: AppMotion.fast,
          curve: AppMotion.standardCurve,
          alignment: Alignment.topCenter,
          child: score == 0
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 10, left: 2, right: 2),
                  child: Row(
                    children: [
                      for (var i = 1; i <= 4; i++) ...[
                        Expanded(
                          child: AnimatedContainer(
                            duration: AppMotion.standard,
                            curve: AppMotion.standardCurve,
                            height: 3.5,
                            decoration: BoxDecoration(
                              color: i <= score ? _colors[score] : const Color(0xFF1F1F23),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 5),
                      ],
                      const SizedBox(width: 4),
                      SizedBox(
                        width: 46,
                        child: Text(
                          _labels[score],
                          textAlign: TextAlign.right,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _colors[score],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
