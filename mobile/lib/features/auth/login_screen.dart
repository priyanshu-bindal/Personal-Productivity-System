import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/utils/error_formatter.dart';
import '../../providers/auth_provider.dart';
import 'widgets/liquid_theme.dart';
import 'widgets/liquid_background.dart';
import 'widgets/liquid_glass_card.dart';
import 'widgets/liquid_glass_input.dart';
import 'widgets/liquid_glass_button.dart';
import 'widgets/focusflow_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  String? _emailError;
  String? _passwordError;
  String? _generalError;
  bool _isSuccess = false;
  bool _isNavigating = false;

  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideIn;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );
    _slideIn = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fadeController.dispose();
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
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: LiquidTheme.mainBackground, // #020817 Deep Midnight Navy
      body: Stack(
        children: [
          // Continuous animated liquid background
          Positioned.fill(
            child: LiquidBackground(reducedMotion: reducedMotion),
          ),

          // Responsive scrollable content
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.scale(
                    scale: 0.96 + (0.04 * _slideIn.value),
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - _slideIn.value)),
                      child: child,
                    ),
                  ),
                );
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 24.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Brand Logo with glowing liquid icon & Aurellis handwritten wordmark
                          const FocusFlowLogo(
                            size: 64,
                            useAurellis: true,
                            showSubtitle: false,
                          ),
                          const SizedBox(height: 30),

                          // Liquid Glass Card
                          LiquidGlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26.0,
                              vertical: 30.0,
                            ),
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
                                  const SizedBox(height: 8),
                                  Text(
                                    'Stay focused. Keep growing.',
                                    textAlign: TextAlign.center,
                                    style: LiquidTheme.subtitle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 28),

                                  if (_generalError != null) ...[
                                    _ErrorBanner(message: _generalError!),
                                    const SizedBox(height: 16),
                                  ],

                                  // Email Pill Field
                                  LiquidGlassInput(
                                    controller: _emailController,
                                    label: 'Email address',
                                    prefixIcon: LucideIcons.mail,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    errorText: _emailError,
                                    onChanged: (_) {
                                      if (_emailError != null) {
                                        setState(() => _emailError = null);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  // Password Pill Field
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
                                        _obscurePassword
                                            ? LucideIcons.eyeOff
                                            : LucideIcons.eye,
                                        color: LiquidTheme.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword = !_obscurePassword,
                                      ),
                                    ),
                                    onChanged: (_) {
                                      if (_passwordError != null) {
                                        setState(() => _passwordError = null);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),

                                  // Forgot Password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        if (_isNavigating) return;
                                        _isNavigating = true;
                                        FocusScope.of(context).unfocus();
                                        context
                                            .push('/forgot-password')
                                            .then((_) {
                                          if (mounted) _isNavigating = false;
                                        });
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Forgot password?',
                                        style: LiquidTheme.linkText(fontSize: 13),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 28),

                                  // Sign In Primary Button
                                  LiquidGlassButton(
                                    label: 'Sign In',
                                    icon: Icons.arrow_forward,
                                    isLoading: isLoading,
                                    isSuccess: _isSuccess,
                                    onTap: _handleLogin,
                                  ),
                                  const SizedBox(height: 28),

                                  // Sign Up Navigation
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        "Don't have an account? ",
                                        style: LiquidTheme.subtitle(
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (_isNavigating) return;
                                          _isNavigating = true;
                                          FocusScope.of(context).unfocus();
                                          context
                                              .push('/register')
                                              .then((_) {
                                            if (mounted) _isNavigating = false;
                                          });
                                        },
                                        child: Text(
                                          'Sign Up',
                                          style: LiquidTheme.linkText(
                                            fontSize: 13.5,
                                            bold: true,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ─── Error Banner ─────────────────────────────────────────────
class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: LiquidTheme.errorBg,              // rgba(255,107,157,0.08)
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: LiquidTheme.errorBorder,        // rgba(255,107,157,0.25)
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: LiquidTheme.errorGlow.withValues(alpha: 0.10),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.alertTriangle,
            color: LiquidTheme.errorText,  // #FF9FBC soft pink
            size: 15,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: LiquidTheme.small(fontSize: 13).copyWith(
                color: LiquidTheme.errorText,  // #FF9FBC
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
