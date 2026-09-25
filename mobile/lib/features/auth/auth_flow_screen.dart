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

// ─── Card Mode Enum ──────────────────────────────────────────────────────────
enum AuthCardMode { login, register, forgotPassword }

// ─── AuthFlowScreen ──────────────────────────────────────────────────────────
/// Single persistent screen that swaps Login / Register / ForgotPassword cards
/// in-place via AnimatedSwitcher (no route navigation between cards).
/// The FocusFlowLogo is wrapped in a Hero so it transitions smoothly from
/// OnboardingScreen.
class AuthFlowScreen extends ConsumerStatefulWidget {
  const AuthFlowScreen({super.key});

  @override
  ConsumerState<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends ConsumerState<AuthFlowScreen> {
  AuthCardMode _mode = AuthCardMode.login;

  void _switchMode(AuthCardMode mode) {
    if (_mode == mode) return;
    setState(() => _mode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Only allow system back when already on the login card
      canPop: _mode == AuthCardMode.login,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          // Back pressed from register or forgotPassword → return to login card
          _switchMode(AuthCardMode.login);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 16.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Brand logo — Hero so it flies in from OnboardingScreen
                          RepaintBoundary(
                            child: Hero(
                              tag: 'focusflow-brand',
                              flightShuttleBuilder: (
                                flightContext,
                                animation,
                                flightDirection,
                                fromHeroContext,
                                toHeroContext,
                              ) {
                                final Hero toHero = toHeroContext.widget as Hero;
                                return Center(
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: toHero.child,
                                  ),
                                );
                              },
                              child: const FocusFlowLogo(
                                size: 52,
                                wordmarkFontSize: 28,
                                wordmarkFontWeight: FontWeight.bold,
                                showSubtitle: false,
                                useAurellis: false,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Card region: AnimatedSize + AnimatedSwitcher for seamless
                          // height changes and cross-fade + subtle slide when mode changes.
                          RepaintBoundary(
                            child: AnimatedSize(
                              duration: const Duration(milliseconds: 280),
                              curve: Curves.easeInOutCubic,
                              alignment: Alignment.topCenter,
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 240),
                                transitionBuilder: (child, animation) {
                                  final fadeAnimation = CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOut,
                                  );
                                  final slideAnimation = Tween<Offset>(
                                    begin: const Offset(0, 0.04),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ));
                                  return FadeTransition(
                                    opacity: fadeAnimation,
                                    child: SlideTransition(
                                      position: slideAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: KeyedSubtree(
                                  key: ValueKey(_mode),
                                  child: _cardForMode(_mode),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _cardForMode(AuthCardMode mode) {
    switch (mode) {
      case AuthCardMode.login:
        return _LoginCardContent(onSwitchMode: _switchMode);
      case AuthCardMode.register:
        return _RegisterCardContent(onSwitchMode: _switchMode);
      case AuthCardMode.forgotPassword:
        return _ForgotPasswordCardContent(onSwitchMode: _switchMode);
    }
  }
}

// ─── Shared Error Banner ─────────────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: LiquidTheme.errorBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LiquidTheme.errorBorder, width: 1),
        boxShadow: [
          BoxShadow(
            color: LiquidTheme.errorGlow.withValues(alpha: 0.10),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.alertTriangle,
            color: LiquidTheme.errorText,
            size: 15,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: LiquidTheme.small(fontSize: 13).copyWith(
                color: LiquidTheme.errorText,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Glass Back Button ───────────────────────────────────────────────────────
class _GlassBackButton extends StatelessWidget {
  final VoidCallback onTap;
  const _GlassBackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: LiquidTheme.secondaryBackground.withValues(alpha: 0.65),
            shape: BoxShape.circle,
            border: Border.all(color: LiquidTheme.glassBorder, width: 1.2),
          ),
          child: const Icon(
            LucideIcons.arrowLeft,
            color: LiquidTheme.textPrimary,
            size: 18,
          ),
        ),
      ),
    );
  }
}

// ─── Login Card Content ──────────────────────────────────────────────────────
class _LoginCardContent extends ConsumerStatefulWidget {
  final void Function(AuthCardMode) onSwitchMode;
  const _LoginCardContent({required this.onSwitchMode});

  @override
  ConsumerState<_LoginCardContent> createState() => _LoginCardContentState();
}

class _LoginCardContentState extends ConsumerState<_LoginCardContent> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;
  String? _generalError;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    bool valid = true;
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address.');
      valid = false;
    } else if (!RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email)) {
      setState(() => _emailError = 'Please enter a valid email address.');
      valid = false;
    }

    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter your password.');
      valid = false;
    } else if (password.length < 6) {
      setState(() =>
          _passwordError = 'Password must contain at least 6 characters.');
      valid = false;
    }

    return valid;
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_validateFields()) return;
    if (_isSuccess) return;

    try {
      await ref.read(authControllerProvider.notifier).signIn(
            email: _emailController.text.trim(),
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

      if (msg.toLowerCase().contains('incorrect email or password')) {
        setState(() => _passwordError = msg);
      } else {
        setState(() => _generalError = msg);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return LiquidGlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome Back',
              textAlign: TextAlign.center,
              style: LiquidTheme.loginTitle(),
            ),
            const SizedBox(height: 4),
            Text(
              'Stay focused. Keep growing.',
              textAlign: TextAlign.center,
              style: LiquidTheme.subtitle(fontSize: 14),
            ),
            const SizedBox(height: 16),

            if (_generalError != null) ...[
              _ErrorBanner(message: _generalError!),
              const SizedBox(height: 10),
            ],

            LiquidGlassInput(
              controller: _emailController,
              label: 'Email address',
              prefixIcon: LucideIcons.mail,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              errorText: _emailError,
              onChanged: (_) {
                if (_emailError != null) setState(() => _emailError = null);
              },
            ),
            const SizedBox(height: 10),

            LiquidGlassInput(
              controller: _passwordController,
              label: 'Password',
              prefixIcon: LucideIcons.lock,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              errorText: _passwordError,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                  color: LiquidTheme.textSecondary,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
              onChanged: (_) {
                if (_passwordError != null) setState(() => _passwordError = null);
              },
            ),
            const SizedBox(height: 8),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  widget.onSwitchMode(AuthCardMode.forgotPassword);
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Forgot password?',
                  style: LiquidTheme.linkText(fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: 16),

            LiquidGlassButton(
              label: 'Sign In',
              icon: Icons.arrow_forward,
              isLoading: isLoading,
              isSuccess: _isSuccess,
              onTap: _handleLogin,
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Don't have an account? ",
                  style: LiquidTheme.subtitle(fontSize: 13.5),
                ),
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).unfocus();
                    widget.onSwitchMode(AuthCardMode.register);
                  },
                  child: Text(
                    'Sign Up',
                    style: LiquidTheme.linkText(fontSize: 13.5, bold: true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Register Card Content ───────────────────────────────────────────────────
class _RegisterCardContent extends ConsumerStatefulWidget {
  final void Function(AuthCardMode) onSwitchMode;
  const _RegisterCardContent({required this.onSwitchMode});

  @override
  ConsumerState<_RegisterCardContent> createState() =>
      _RegisterCardContentState();
}

class _RegisterCardContentState extends ConsumerState<_RegisterCardContent> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
  String? _generalError;
  bool _isSuccess = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
          .hasMatch(email);

  bool _validateFields() {
    setState(() {
      _nameError = null;
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
      _generalError = null;
    });

    bool valid = true;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (name.isEmpty) {
      setState(() => _nameError = 'Please enter your name.');
      valid = false;
    }
    if (email.isEmpty) {
      setState(() => _emailError = 'Please enter your email address.');
      valid = false;
    } else if (!_isValidEmail(email)) {
      setState(() => _emailError = 'Please enter a valid email address.');
      valid = false;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Please enter a password.');
      valid = false;
    } else if (password.length < 6) {
      setState(
          () => _passwordError = 'Password must contain at least 6 characters.');
      valid = false;
    }
    if (confirm.isEmpty) {
      setState(() => _confirmError = 'Please confirm your password.');
      valid = false;
    } else if (password != confirm) {
      setState(() => _confirmError = 'Passwords do not match.');
      valid = false;
    }

    return valid;
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_validateFields()) return;
    if (_isSuccess) return;

    try {
      final res = await ref.read(authControllerProvider.notifier).signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
            fullName: _nameController.text.trim(),
          );

      if (!mounted) return;

      if (res.session == null && res.user != null) {
        context.go('/email-verification', extra: _emailController.text.trim());
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

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back to login
        _GlassBackButton(
          onTap: () {
            FocusScope.of(context).unfocus();
            widget.onSwitchMode(AuthCardMode.login);
          },
        ),
        const SizedBox(height: 10),

        LiquidGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: LiquidTheme.heading(
                    color: LiquidTheme.textPrimary,
                  ).copyWith(fontSize: 25),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start building skills with consistency today',
                  textAlign: TextAlign.center,
                  style: LiquidTheme.small(
                    fontSize: 13.0,
                    color: LiquidTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),

                if (_generalError != null) ...[
                  _ErrorBanner(message: _generalError!),
                  const SizedBox(height: 10),
                ],

                LiquidGlassInput(
                  controller: _nameController,
                  label: 'Full Name',
                  prefixIcon: LucideIcons.user,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  errorText: _nameError,
                  onChanged: (_) {
                    if (_nameError != null) setState(() => _nameError = null);
                  },
                ),
                const SizedBox(height: 9),

                LiquidGlassInput(
                  controller: _emailController,
                  label: 'Email address',
                  prefixIcon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText: _emailError,
                  onChanged: (_) {
                    if (_emailError != null) setState(() => _emailError = null);
                  },
                ),
                const SizedBox(height: 9),

                LiquidGlassInput(
                  controller: _passwordController,
                  label: 'Password',
                  prefixIcon: LucideIcons.lock,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? LucideIcons.eyeOff : LucideIcons.eye,
                      color: LiquidTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  onChanged: (_) {
                    if (_passwordError != null) {
                      setState(() => _passwordError = null);
                    }
                  },
                ),
                const SizedBox(height: 9),

                LiquidGlassInput(
                  controller: _confirmController,
                  label: 'Confirm password',
                  prefixIcon: LucideIcons.lock,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  errorText: _confirmError,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirm ? LucideIcons.eyeOff : LucideIcons.eye,
                      color: LiquidTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  onChanged: (_) {
                    if (_confirmError != null) {
                      setState(() => _confirmError = null);
                    }
                  },
                ),
                const SizedBox(height: 16),

                LiquidGlassButton(
                  label: 'Create Account',
                  icon: Icons.arrow_forward,
                  isLoading: isLoading,
                  isSuccess: _isSuccess,
                  onTap: _handleRegister,
                ),
                const SizedBox(height: 14),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: LiquidTheme.subtitle(fontSize: 13.5),
                    ),
                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).unfocus();
                        widget.onSwitchMode(AuthCardMode.login);
                      },
                      child: Text(
                        'Sign In',
                        style:
                            LiquidTheme.linkText(fontSize: 13.5, bold: true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Forgot Password Card Content ────────────────────────────────────────────
class _ForgotPasswordCardContent extends ConsumerStatefulWidget {
  final void Function(AuthCardMode) onSwitchMode;
  const _ForgotPasswordCardContent({required this.onSwitchMode});

  @override
  ConsumerState<_ForgotPasswordCardContent> createState() =>
      _ForgotPasswordCardContentState();
}

class _ForgotPasswordCardContentState
    extends ConsumerState<_ForgotPasswordCardContent> {
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
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (mounted) setState(() => _emailError = ErrorFormatter.format(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GlassBackButton(
          onTap: () {
            FocusScope.of(context).unfocus();
            widget.onSwitchMode(AuthCardMode.login);
          },
        ),
        const SizedBox(height: 10),

        LiquidGlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: _submitted
              ? _ForgotSuccessContent(
                  email: _emailController.text.trim(),
                  onBack: () => widget.onSwitchMode(AuthCardMode.login),
                )
              : _ForgotFormContent(
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
    );
  }
}

// ─── Forgot Password: Form Content ───────────────────────────────────────────
class _ForgotFormContent extends StatelessWidget {
  final TextEditingController emailController;
  final String? emailError;
  final bool isLoading;
  final ValueChanged<String> onEmailChanged;
  final VoidCallback onSubmit;

  const _ForgotFormContent({
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
        Text(
          'Reset Password',
          textAlign: TextAlign.center,
          style: LiquidTheme.loginTitle(),
        ),
        const SizedBox(height: 6),
        Text(
          'Enter your email address and we will send you instructions to reset your password.',
          textAlign: TextAlign.center,
          style: LiquidTheme.small(
            fontSize: 13.0,
            color: LiquidTheme.textSecondary,
          ).copyWith(height: 1.4),
        ),
        const SizedBox(height: 16),

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
        const SizedBox(height: 16),

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

// ─── Forgot Password: Success Content ────────────────────────────────────────
class _ForgotSuccessContent extends StatelessWidget {
  final String email;
  final VoidCallback onBack;

  const _ForgotSuccessContent({required this.email, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
        const SizedBox(height: 18),

        Text(
          'Check your inbox',
          textAlign: TextAlign.center,
          style:
              LiquidTheme.heading(color: LiquidTheme.textPrimary).copyWith(fontSize: 22),
        ),
        const SizedBox(height: 8),
        Text(
          'We sent password reset instructions to\n$email',
          textAlign: TextAlign.center,
          style: LiquidTheme.small(
            fontSize: 14,
            color: LiquidTheme.textSecondary,
          ).copyWith(height: 1.55),
        ),
        const SizedBox(height: 28),

        LiquidGlassButton(
          label: 'Back to Sign In',
          icon: LucideIcons.arrowLeft,
          onTap: onBack,
        ),
      ],
    );
  }
}
