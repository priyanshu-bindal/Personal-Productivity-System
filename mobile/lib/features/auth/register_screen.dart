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

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Inline errors
  String? _nameError;
  String? _emailError;
  String? _passwordError;
  String? _confirmError;
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
      duration: const Duration(milliseconds: 600),
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$')
        .hasMatch(email);
  }

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
        // Email confirmation required
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
      } else if (msg.toLowerCase().contains('connect') ||
          msg.toLowerCase().contains('internet')) {
        setState(() => _generalError = msg);
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
      backgroundColor: LiquidTheme.background,
      body: Stack(
        children: [
          // Same animated liquid background
          Positioned.fill(
            child: LiquidBackground(reducedMotion: reducedMotion),
          ),

          // Main Responsive Scroll View
          SafeArea(
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.scale(
                    scale: 0.97 + (0.03 * _slideIn.value),
                    child: Transform.translate(
                      offset: Offset(0, 15 * (1 - _slideIn.value)),
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
                        vertical: 16.0,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top Bar: Back Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: GestureDetector(
                              onTap: () {
                                if (_isNavigating) return;
                                _isNavigating = true;
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
                          const SizedBox(height: 12),

                          // Brand Logo
                          const FocusFlowLogo(
                            size: 64,
                            showSubtitle: false,
                          ),
                          const SizedBox(height: 24),

                          // Liquid Glass Card
                          LiquidGlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 26.0,
                              vertical: 28.0,
                            ),
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
                                    ).copyWith(fontSize: 26),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Start building skills with consistency today',
                                    textAlign: TextAlign.center,
                                    style: LiquidTheme.small(
                                      fontSize: 13.5,
                                      color: LiquidTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 26),

                                  // General error banner
                                  if (_generalError != null) ...[
                                    _ErrorBanner(message: _generalError!),
                                    const SizedBox(height: 16),
                                  ],

                                  // Full Name
                                  LiquidGlassInput(
                                    controller: _nameController,
                                    label: 'Full Name',
                                    prefixIcon: LucideIcons.user,
                                    textCapitalization: TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    errorText: _nameError,
                                    onChanged: (_) {
                                      if (_nameError != null) {
                                        setState(() => _nameError = null);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 14),

                                  // Email Address
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
                                  const SizedBox(height: 14),

                                  // Password
                                  LiquidGlassInput(
                                    controller: _passwordController,
                                    label: 'Password',
                                    prefixIcon: LucideIcons.lock,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.next,
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
                                  const SizedBox(height: 14),

                                  // Confirm Password
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
                                        _obscureConfirm
                                            ? LucideIcons.eyeOff
                                            : LucideIcons.eye,
                                        color: LiquidTheme.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscureConfirm = !_obscureConfirm,
                                      ),
                                    ),
                                    onChanged: (_) {
                                      if (_confirmError != null) {
                                        setState(() => _confirmError = null);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 28),

                                  // Primary Create Account Button
                                  LiquidGlassButton(
                                    label: 'Create Account',
                                    icon: Icons.arrow_forward,
                                    isLoading: isLoading,
                                    isSuccess: _isSuccess,
                                    onTap: _handleRegister,
                                  ),
                                  const SizedBox(height: 24),

                                  // Bottom: Already have an account? Sign In
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Already have an account? ',
                                        style: LiquidTheme.subtitle(
                                          fontSize: 13.5,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () {
                                          if (_isNavigating) return;
                                          _isNavigating = true;
                                          FocusScope.of(context).unfocus();
                                          context.pop();
                                        },
                                        child: Text(
                                          'Sign In',
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: LiquidTheme.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LiquidTheme.errorBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            LucideIcons.alertTriangle,
            color: LiquidTheme.error,
            size: 16,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: LiquidTheme.subtitle(fontSize: 13).copyWith(
                color: LiquidTheme.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}