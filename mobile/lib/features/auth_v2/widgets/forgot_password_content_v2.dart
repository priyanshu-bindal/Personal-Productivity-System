import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/utils/error_formatter.dart';
import '../../../providers/auth_provider.dart';
import 'glass_auth_field_v2.dart';
import 'liquid_glass_primary_button_v2.dart';

/// Compact, premium Forgot Password card content for AuthFlowV2Screen.
class ForgotPasswordContentV2 extends ConsumerStatefulWidget {
  final TextEditingController emailController;
  final VoidCallback onBackToLogin;

  const ForgotPasswordContentV2({
    super.key,
    required this.emailController,
    required this.onBackToLogin,
  });

  @override
  ConsumerState<ForgotPasswordContentV2> createState() =>
      _ForgotPasswordContentV2State();
}

class _ForgotPasswordContentV2State
    extends ConsumerState<ForgotPasswordContentV2> {
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

  Widget _buildForm(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title & Subtitle
        Text(
          'Reset Password',
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
          'Enter your email to receive a password reset link.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 13.0,
            color: const Color(0xFF8291A7),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 14),

        // Email Field
        GlassAuthFieldV2(
          controller: widget.emailController,
          label: 'Email address',
          hintText: 'name@example.com',
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
        const SizedBox(height: 12),

        // Send Reset Link Button
        LiquidGlassPrimaryButtonV2(
          label: 'Send Reset Link',
          isLoading: isLoading,
          onTap: _handleReset,
        ),
        const SizedBox(height: 10),

        // Back to Sign In Link
        Center(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () {
                FocusScope.of(context).unfocus();
                widget.onBackToLogin();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  'Back to Sign In',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF2F6BFF),
                  ),
                ),
              ),
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
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _submitted
          ? _SuccessViewV2(
              key: const ValueKey('success'),
              email: widget.emailController.text.trim(),
              onBack: widget.onBackToLogin,
            )
          : KeyedSubtree(
              key: const ValueKey('form'),
              child: _buildForm(isLoading),
            ),
    );
  }
}

class _SuccessViewV2 extends StatefulWidget {
  final String email;
  final VoidCallback onBack;

  const _SuccessViewV2({
    super.key,
    required this.email,
    required this.onBack,
  });

  @override
  State<_SuccessViewV2> createState() => _SuccessViewV2State();
}

class _SuccessViewV2State extends State<_SuccessViewV2>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconFade;
  late final Animation<double> _contentFade;
  late final Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _iconScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.75, curve: Curves.easeOutBack),
      ),
    );

    _iconFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _contentFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    );

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success Icon Circle (Electric Blue Glass, zero cyan)
        Center(
          child: FadeTransition(
            opacity: _iconFade,
            child: ScaleTransition(
              scale: _iconScale,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF2F6BFF).withValues(alpha: 0.12),
                  border: Border.all(
                    color: const Color(0xFF2F6BFF).withValues(alpha: 0.40),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2F6BFF).withValues(alpha: 0.22),
                      blurRadius: 18,
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.mailCheck,
                  size: 26,
                  color: Color(0xFF5B8CFF),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),

        FadeTransition(
          opacity: _contentFade,
          child: SlideTransition(
            position: _contentSlide,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Check your inbox',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "We sent a password reset link to\n${widget.email}",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13.0,
                    color: const Color(0xFF8291A7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),

                LiquidGlassPrimaryButtonV2(
                  label: 'Back to Sign In',
                  onTap: widget.onBack,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
