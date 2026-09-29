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

/// Clean, compact Login card content
class LoginContent extends ConsumerStatefulWidget {
  final VoidCallback onSwitchToSignUp;
  final VoidCallback onSwitchToForgotPassword;
  final TextEditingController emailController;

  const LoginContent({
    super.key,
    required this.onSwitchToSignUp,
    required this.onSwitchToForgotPassword,
    required this.emailController,
  });

  @override
  ConsumerState<LoginContent> createState() => _LoginContentState();
}

class _LoginContentState extends ConsumerState<LoginContent> {
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();

  String? _emailError;
  String? _passwordError;
  String? _generalError;
  bool _isSuccess = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool _validate() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    bool isValid = true;
    final email = widget.emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address.');
      isValid = false;
    } else if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address.');
      isValid = false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter your password.');
      isValid = false;
    } else if (password.length < 6) {
      setState(
          () => _passwordError = 'Password must be at least 6 characters.');
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_validate()) return;
    if (_isSuccess) return;

    try {
      await ref.read(authControllerProvider.notifier).signIn(
            email: widget.emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        setState(() => _isSuccess = true);
        context.go('/today');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSuccess = false);
      final msg = ErrorFormatter.format(e);

      if (msg.toLowerCase().contains('incorrect') ||
          msg.toLowerCase().contains('invalid login credentials')) {
        setState(() => _passwordError = msg);
      } else {
        setState(() => _generalError = msg);
      }
    }
  }

  void _handleGoogleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Google authentication will be available soon.',
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
          'Welcome Back',
          textAlign: TextAlign.center,
          style: LiquidTheme.loginTitle(color: LiquidTheme.textPrimary),
        ),
        const SizedBox(height: 3),
        Text(
          'Sign in to continue to FocusFlow',
          textAlign: TextAlign.center,
          style: LiquidTheme.subtitle(fontSize: 13.0),
        ),
        const SizedBox(height: 14),

        // ── General Error Banner (Animated) ───────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: _generalError != null
              ? Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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

        // ── Email Field ───────────────────────────────────────────────
        LiquidAuthTextField(
          controller: widget.emailController,
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
          onSubmitted: (_) {
            _passwordFocusNode.requestFocus();
          },
        ),
        const SizedBox(height: 8),

        // ── Password Field ────────────────────────────────────────────
        LiquidAuthTextField(
          controller: _passwordController,
          focusNode: _passwordFocusNode,
          label: 'Password',
          hintText: 'Enter password',
          prefixIcon: LucideIcons.lock,
          isPassword: true,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          errorText: _passwordError,
          onChanged: (_) {
            if (_passwordError != null) setState(() => _passwordError = null);
          },
          onSubmitted: (_) => _handleLogin(),
        ),
        const SizedBox(height: 4),

        // ── Forgot Password Link ──────────────────────────────────────
        Align(
          alignment: Alignment.centerRight,
          child: LiquidAuthLink(
            text: 'Forgot password?',
            fontSize: 12.5,
            onTap: () {
              FocusScope.of(context).unfocus();
              widget.onSwitchToForgotPassword();
            },
          ),
        ),
        const SizedBox(height: 10),

        // ── Primary Sign In Button ────────────────────────────────────
        LiquidAuthButton(
          label: 'Sign In',
          isLoading: isLoading,
          onTap: _handleLogin,
        ),
        const SizedBox(height: 10),

        // ── Divider ───────────────────────────────────────────────────
        const LiquidAuthDivider(label: 'or'),
        const SizedBox(height: 10),

        // ── Continue with Google Button ───────────────────────────────
        LiquidAuthSecondaryButton.google(
          onTap: _handleGoogleSignIn,
        ),
        const SizedBox(height: 12),

        // ── Switch to Sign Up Prompt ──────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Don't have an account?",
              style: LiquidTheme.small(
                fontSize: 13.0,
                color: LiquidTheme.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
            LiquidAuthLink(
              text: 'Sign Up',
              bold: true,
              fontSize: 13.0,
              onTap: () {
                FocusScope.of(context).unfocus();
                widget.onSwitchToSignUp();
              },
            ),
          ],
        ),
      ],
    );
  }
}
