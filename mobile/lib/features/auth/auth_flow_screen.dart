import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'widgets/liquid_theme.dart';
import 'widgets/liquid_auth_background.dart';
import 'widgets/liquid_auth_card.dart';
import 'widgets/liquid_auth_header.dart';
import 'widgets/login_content.dart';
import 'widgets/signup_content.dart';
import 'widgets/forgot_password_content.dart';

// ─── Auth Mode Enum ──────────────────────────────────────────────────────────
enum AuthMode {
  login,
  signup,
  forgotPassword,
}

// Backward compatibility alias for any existing code expecting AuthCardMode
typedef AuthCardMode = AuthMode;

/// Premium Dark Liquid Glass Authentication Screen
///
/// Features:
/// - One unified Auth Shell for Login, Sign Up, and Forgot Password
/// - Smooth App Open Entrance Animation (0ms → 800ms)
/// - Seamless in-place card height morphing via [AnimatedSize]
/// - Ultra-smooth subtle vertical micro-glide & fade via [AnimatedSwitcher] (NO horizontal page slide)
/// - Stationary Brand Header (logo never jumps or resets)
/// - Stable 100% continuous background animation
/// - Keyboard-safe layout with [SingleChildScrollView] and [LayoutBuilder]
class AuthFlowScreen extends ConsumerStatefulWidget {
  final AuthMode initialMode;

  const AuthFlowScreen({
    super.key,
    this.initialMode = AuthMode.login,
  });

  @override
  ConsumerState<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

/// Primary export alias
typedef AuthScreen = AuthFlowScreen;

class _AuthFlowScreenState extends ConsumerState<AuthFlowScreen>
    with SingleTickerProviderStateMixin {
  late AuthMode _currentMode;
  final TextEditingController _sharedEmailController = TextEditingController();

  // Entrance Animation Controller (800ms total)
  late final AnimationController _entranceController;

  // Staggered Entrance Animations:
  // 100ms - 400ms: Background atmosphere fade-in
  late final Animation<double> _atmosphereAnimation;
  // 150ms - 450ms: Logo fade-in & 12px upward emergence
  late final Animation<double> _logoOpacityAnimation;
  late final Animation<Offset> _logoSlideAnimation;
  // 380ms - 720ms: Card fade-in & 12px upward emergence
  late final Animation<double> _cardOpacityAnimation;
  late final Animation<Offset> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _atmosphereAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.12, 0.50, curve: Curves.easeOut),
    );

    _logoOpacityAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.18, 0.55, curve: Curves.easeOut),
    );
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08), // ~12px upward
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.18, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _cardOpacityAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.42, 0.88, curve: Curves.easeOut),
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05), // ~12px upward
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.42, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _sharedEmailController.dispose();
    super.dispose();
  }

  void _switchMode(AuthMode newMode) {
    if (_currentMode == newMode) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _currentMode = newMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return PopScope(
      canPop: _currentMode == AuthMode.login,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _switchMode(AuthMode.login);
        }
      },
      child: Scaffold(
        backgroundColor: LiquidTheme.background, // #020617
        body: Stack(
          children: [
            // ── Persistent Liquid Glass Background Layer ───────────────
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _atmosphereAnimation,
                builder: (context, _) {
                  return LiquidAuthBackground(
                    reducedMotion: reducedMotion,
                    atmosphericOpacity:
                        reducedMotion ? 1.0 : _atmosphereAnimation.value,
                  );
                },
              ),
            ),

            // ── Scrollable Foreground Shell ────────────────────────────
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  // Stationary proportional top padding so logo and card never jump
                  final double topSpacing =
                      (constraints.maxHeight * 0.018).clamp(4.0, 16.0);

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 6.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SizedBox(height: topSpacing),

                            // ── Stationary Brand Header (Logo + Wordmark) ──
                            if (reducedMotion)
                              const LiquidAuthHeader(logoSize: 46)
                            else
                              AnimatedBuilder(
                                animation: _entranceController,
                                builder: (context, child) {
                                  return FadeTransition(
                                    opacity: _logoOpacityAnimation,
                                    child: SlideTransition(
                                      position: _logoSlideAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: const LiquidAuthHeader(logoSize: 46),
                              ),

                            const SizedBox(height: 12),

                            // ── Persistent Liquid Glass Card Shell ───────
                            if (reducedMotion)
                              _buildCardContent()
                            else
                              AnimatedBuilder(
                                animation: _entranceController,
                                builder: (context, child) {
                                  return FadeTransition(
                                    opacity: _cardOpacityAnimation,
                                    child: SlideTransition(
                                      position: _cardSlideAnimation,
                                      child: child,
                                    ),
                                  );
                                },
                                child: _buildCardContent(),
                              ),

                            SizedBox(height: topSpacing),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardContent() {
    return LiquidAuthCard(
      borderRadius: 24.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) {
            return Stack(
              alignment: Alignment.topCenter,
              children: <Widget>[
                ...previousChildren,
                ?currentChild,
              ],
            );
          },
          transitionBuilder: (child, animation) {
            // Subtle 4px vertical micro-movement and fade (NO horizontal slide)
            final isIncoming = child.key == ValueKey<AuthMode>(_currentMode);
            final Offset startOffset = isIncoming
                ? const Offset(0, 0.02) // +4px gently fading in
                : const Offset(0, -0.02); // -4px gently fading out

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: startOffset,
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<AuthMode>(_currentMode),
            child: _contentForMode(_currentMode),
          ),
        ),
      ),
    );
  }

  Widget _contentForMode(AuthMode mode) {
    switch (mode) {
      case AuthMode.login:
        return LoginContent(
          emailController: _sharedEmailController,
          onSwitchToSignUp: () => _switchMode(AuthMode.signup),
          onSwitchToForgotPassword: () => _switchMode(AuthMode.forgotPassword),
        );
      case AuthMode.signup:
        return SignUpContent(
          emailController: _sharedEmailController,
          onSwitchToLogin: () => _switchMode(AuthMode.login),
        );
      case AuthMode.forgotPassword:
        return ForgotPasswordContent(
          emailController: _sharedEmailController,
          onBackToLogin: () => _switchMode(AuthMode.login),
        );
    }
  }
}
