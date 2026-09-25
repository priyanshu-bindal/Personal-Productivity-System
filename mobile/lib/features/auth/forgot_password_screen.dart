import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/utils/error_formatter.dart';
import '../../providers/auth_provider.dart';
import 'widgets/liquid_theme.dart';
import 'widgets/liquid_glass_card.dart';
import 'widgets/liquid_glass_input.dart';
import 'widgets/liquid_glass_button.dart';
import 'widgets/focusflow_logo.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _submitted = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    final email = _emailController.text.trim();

    setState(() => _emailError = null);

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address.');
      return;
    }
    if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address.');
      return;
    }

    try {
      await ref.read(authControllerProvider.notifier).resetPassword(email);
      if (mounted) {
        setState(() => _submitted = true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _emailError = ErrorFormatter.format(e));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 20.0,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Glass back button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          context.pop();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: LiquidTheme.secondaryBackground
                                .withValues(alpha: 0.65),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: LiquidTheme.glassBorder,
                              width: 1.2,
                            ),
                          ),
                          child: const Icon(
                            LucideIcons.arrowLeft,
                            color: LiquidTheme.textPrimary,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Logo & LiquidGlassCard in RepaintBoundary
                    RepaintBoundary(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Brand Logo
                          const FocusFlowLogo(
                            size: 64,
                            showSubtitle: false,
                          ),
                          const SizedBox(height: 28),

                          // Liquid Glass Card
                          LiquidGlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26.0,
                              vertical: 30.0,
                            ),
                            child: _submitted
                                ? _SuccessContent(
                                    email: _emailController.text.trim(),
                                    onBack: () => context.pop(),
                                  )
                                : _FormContent(
                                    emailController: _emailController,
                                    emailError: _emailError,
                                    isLoading: isLoading,
                                    onEmailChanged: (_) {
                                      if (_emailError != null) {
                                        setState(() => _emailError = null);
                                      }
                                    },
                                    onSubmit: _handleReset,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Form Content ──────────────────────────────────────────────
class _FormContent extends StatelessWidget {
  final TextEditingController emailController;
  final String? emailError;
  final bool isLoading;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onSubmit;

  const _FormContent({
    required this.emailController,
    required this.emailError,
    required this.isLoading,
    required this.onEmailChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Title
        Text(
          'Reset Password',
          textAlign: TextAlign.center,
          style: LiquidTheme.loginTitle(),
        ),
        const SizedBox(height: 8),

        // Subtitle
        Text(
          'Enter your email address and we will send you instructions to reset your password.',
          textAlign: TextAlign.center,
          style: LiquidTheme.small(
            fontSize: 13.5,
            color: LiquidTheme.textSecondary,
          ).copyWith(height: 1.5),
        ),
        const SizedBox(height: 28),

        // Email Pill Input
        LiquidGlassInput(
          controller: emailController,
          label: 'Email Address',
          prefixIcon: LucideIcons.mail,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => onSubmit(),
          errorText: emailError,
          onChanged: onEmailChanged,
        ),
        const SizedBox(height: 28),

        // Send Instructions Liquid Button
        LiquidGlassButton(
          label: 'Send Instructions',
          isLoading: isLoading,
          icon: LucideIcons.send,
          onTap: onSubmit,
        ),
      ],
    );
  }
}

// ─── Success Content ───────────────────────────────────────────
class _SuccessContent extends StatelessWidget {
  final String email;
  final VoidCallback onBack;

  const _SuccessContent({required this.email, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Success glow icon
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: LiquidTheme.success.withValues(alpha: 0.12),
            border: Border.all(
              color: LiquidTheme.success.withValues(alpha: 0.40),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: LiquidTheme.success.withValues(alpha: 0.22),
                blurRadius: 18,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(
            LucideIcons.mailCheck,
            size: 28,
            color: LiquidTheme.success,
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style: LiquidTheme.heading(color: LiquidTheme.textPrimary)
              .copyWith(fontSize: 22),
        ),
        const SizedBox(height: 10),
        Text(
          'We sent password reset instructions to\n$email',
          textAlign: TextAlign.center,
          style: LiquidTheme.small(
            fontSize: 14,
            color: LiquidTheme.textSecondary,
          ).copyWith(height: 1.55),
        ),
        const SizedBox(height: 32),

        // Back to Sign In glass button
        LiquidGlassButton(
          label: 'Back to Sign In',
          icon: LucideIcons.arrowLeft,
          onTap: onBack,
        ),
      ],
    );
  }
}
