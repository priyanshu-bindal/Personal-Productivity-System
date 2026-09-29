import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/utils/error_formatter.dart';
import '../../../providers/auth_provider.dart';
import 'glass_auth_field_v2.dart';
import 'liquid_glass_primary_button_v2.dart';


/// Compact, premium Login content for AuthFlowV2Screen.
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




  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          'Welcome Back',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFF8FAFC),
            letterSpacing: -0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Sign in to continue to FocusFlow',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: const Color(0xFF8291A7),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),

        // General Error Banner (if any)
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: _generalError != null
              ? Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0x18FF5C68),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0x35FF5C68),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.alertTriangle,
                        color: Color(0xFFFF5C68),
                        size: 15,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _generalError!,
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFFFF5C68),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),

        // Email Field
        GlassAuthFieldV2(
          controller: widget.emailController,
          label: 'Email address',
          hintText: 'Enter your email',
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
        const SizedBox(height: 10),

        // Password Field
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

        // Forgot Password Link
        Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                FocusScope.of(context).unfocus();
                widget.onSwitchToForgotPassword();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2F6BFF),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Primary Sign In Button
        LiquidGlassPrimaryButtonV2(
          label: 'Sign In',
          isLoading: isLoading,
          onTap: _handleLogin,
        ),
        const SizedBox(height: 16),


        // Switch to Sign Up Prompt
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              "Don't have an account?",
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: const Color(0xFF8291A7),
              ),
            ),
            const SizedBox(width: 4),
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(4),
                onTap: () {
                  FocusScope.of(context).unfocus();
                  widget.onSwitchToSignUp();
                },
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                  child: Text(
                    'Sign Up',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2F6BFF),
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
