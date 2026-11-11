import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/utils/error_formatter.dart';
import '../../../providers/auth_provider.dart';
import 'auth_heading_v2.dart';
import 'glass_auth_field_v2.dart';
import 'liquid_glass_primary_button_v2.dart';

final _emailRegex = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');

/// Sign-in form.
class LoginContentV2 extends ConsumerStatefulWidget {
  final TextEditingController emailController;
  final VoidCallback onSwitchToSignUp;
  final VoidCallback onSwitchToForgotPassword;

  const LoginContentV2({
    super.key,
    required this.emailController,
    required this.onSwitchToSignUp,
    required this.onSwitchToForgotPassword,
  });

  @override
  ConsumerState<LoginContentV2> createState() => _LoginContentV2State();
}

class _LoginContentV2State extends ConsumerState<LoginContentV2> {
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
    final email = widget.emailController.text.trim();
    final password = _passwordController.text;
    String? emailError;
    String? passwordError;

    if (email.isEmpty) {
      emailError = 'Please enter your email address.';
    } else if (!_emailRegex.hasMatch(email)) {
      emailError = 'Please enter a valid email address.';
    }

    if (password.isEmpty) {
      passwordError = 'Please enter your password.';
    } else if (password.length < 6) {
      passwordError = 'Password must be at least 6 characters.';
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _generalError = null;
    });
    return emailError == null && passwordError == null;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_validate() || _isSuccess) return;

    try {
      await ref.read(authControllerProvider.notifier).signIn(
            email: widget.emailController.text.trim(),
            password: _passwordController.text,
          );
      if (mounted) {
        setState(() => _isSuccess = true);
        TextInput.finishAutofillContext();
        context.go('/today');
      }
    } catch (e) {
      if (!mounted) return;
      final msg = ErrorFormatter.format(e);
      final lower = msg.toLowerCase();
      setState(() {
        _isSuccess = false;
        if (lower.contains('incorrect') || lower.contains('invalid login credentials')) {
          _passwordError = msg;
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
            title: 'Welcome back',
            subtitle: 'Sign in to pick up right where you left off.',
          ),
          AuthErrorBanner(message: _generalError),
          GlassAuthFieldV2(
            controller: widget.emailController,
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
            hintText: 'Enter your password',
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
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: AuthTextLink(
              label: 'Forgot password?',
              fontSize: 13,
              onTap: widget.onSwitchToForgotPassword,
            ),
          ),
          const SizedBox(height: 18),
          LiquidGlassPrimaryButtonV2(
            label: 'Sign in',
            isLoading: isLoading,
            onTap: _handleLogin,
          ),
        ],
      ),
    );
  }
}
