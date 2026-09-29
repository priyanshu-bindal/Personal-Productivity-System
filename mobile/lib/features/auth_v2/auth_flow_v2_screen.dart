import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'widgets/auth_background_v2.dart';
import 'widgets/auth_logo_v2.dart';
import 'widgets/liquid_glass_auth_card_v2.dart';
import 'widgets/login_content_v2.dart';
import 'widgets/signup_content_v2.dart';
import 'widgets/forgot_password_content_v2.dart';

/// Available modes for the single-shell Auth Flow V2
enum AuthModeV2 {
  login,
  register,
  forgotPassword,
}

/// Premium iOS-inspired Liquid Glass Authentication Screen V2.
///
/// Features:
/// - One unified, persistent screen with zero page transitions between modes
/// - Stable background atmosphere and stationary brand logo
/// - Smooth opening animation (fade + scale 0.96→1.0 + subtle upward micro-glide, 350ms easeOutCubic)
/// - Seamless card height morphing via [AnimatedSize]
/// - Ultra-smooth content switching via [AnimatedSwitcher] (fade + subtle scale + micro vertical movement)
/// - Single unified input fields with #2F6BFF focus states (no cyan/green)
/// - 60fps performance with RepaintBoundary and static BackdropFilter
class AuthFlowV2Screen extends ConsumerStatefulWidget {
  final AuthModeV2 initialMode;

  const AuthFlowV2Screen({
    super.key,
    this.initialMode = AuthModeV2.login,
  });

  @override
  ConsumerState<AuthFlowV2Screen> createState() => _AuthFlowV2ScreenState();
}

class _AuthFlowV2ScreenState extends ConsumerState<AuthFlowV2Screen>
    with SingleTickerProviderStateMixin {
  late AuthModeV2 _currentMode;
  final TextEditingController _sharedEmailController = TextEditingController();

  // Screen Entrance Animation Controller (350ms duration)
  late final AnimationController _entranceController;
  late final Animation<double> _bgFadeAnimation;
  late final Animation<double> _logoFadeAnimation;
  late final Animation<Offset> _logoSlideAnimation;
  late final Animation<double> _cardFadeAnimation;
  late final Animation<double> _cardScaleAnimation;
  late final Animation<Offset> _cardSlideAnimation;

  @override
  void initState() {
    super.initState();
    _currentMode = widget.initialMode;

    // 350ms smooth opening animation without bounce or overshoot
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _bgFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    );

    // Logo fade + subtle upward micro-glide
    _logoFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
    );
    _logoSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05), // ~10px upward
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // Card fade + scale 0.96 -> 1.0 + vertical movement ~8px -> 0
    _cardFadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
    );
    _cardScaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );
    _cardSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.025), // ~8px upward
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
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

  void _switchMode(AuthModeV2 newMode) {
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
      canPop: _currentMode == AuthModeV2.login,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          _switchMode(AuthModeV2.login);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF000000), // Pure OLED black
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // ── 1. Stable Persistent Dark OLED/Navy Background ─────────
              Positioned.fill(
                child: reducedMotion
                    ? const AuthBackgroundV2()
                    : FadeTransition(
                        opacity: _bgFadeAnimation,
                        child: const AuthBackgroundV2(),
                      ),
              ),

              // ── 2. Keyboard-Safe Foreground Shell ───────────────────────
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Proportional top spacing to fit standard ~800dp mobile screens
                    final double topSpacing =
                        (constraints.maxHeight * 0.045).clamp(16.0, 44.0);
                    final double cardSpacing =
                        (constraints.maxHeight * 0.025).clamp(18.0, 28.0);
                    final double bottomSpacing =
                        (constraints.maxHeight * 0.03).clamp(12.0, 28.0);

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 8.0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: topSpacing),

                              // ── Stationary Brand Logo (Top Prominent) ──
                              if (reducedMotion)
                                const AuthLogoV2()
                              else
                                FadeTransition(
                                  opacity: _logoFadeAnimation,
                                  child: SlideTransition(
                                    position: _logoSlideAnimation,
                                    child: const AuthLogoV2(),
                                  ),
                                ),

                              SizedBox(height: cardSpacing),

                              // ── Persistent Liquid Glass Card Shell ─────
                              if (reducedMotion)
                                _buildCard()
                              else
                                FadeTransition(
                                  opacity: _cardFadeAnimation,
                                  child: ScaleTransition(
                                    scale: _cardScaleAnimation,
                                    child: SlideTransition(
                                      position: _cardSlideAnimation,
                                      child: _buildCard(),
                                    ),
                                  ),
                                ),

                              SizedBox(height: bottomSpacing),
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
      ),
    );
  }

  Widget _buildCard() {
    return LiquidGlassAuthCardV2(
      borderRadius: 24.0,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
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
            final isIncoming =
                child.key == ValueKey<AuthModeV2>(_currentMode);

            // Subtle vertical micro-movement (~5px) + subtle scale (0.98→1.0)
            final startOffset = isIncoming
                ? const Offset(0, 0.02)
                : const Offset(0, -0.015);

            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.98,
                  end: 1.0,
                ).animate(animation),
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: startOffset,
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
            );
          },
          child: KeyedSubtree(
            key: ValueKey<AuthModeV2>(_currentMode),
            child: _buildContentForMode(_currentMode),
          ),
        ),
      ),
    );
  }

  Widget _buildContentForMode(AuthModeV2 mode) {
    switch (mode) {
      case AuthModeV2.login:
        return LoginContentV2(
          emailController: _sharedEmailController,
          onSwitchToSignUp: () => _switchMode(AuthModeV2.register),
          onSwitchToForgotPassword: () =>
              _switchMode(AuthModeV2.forgotPassword),
        );
      case AuthModeV2.register:
        return SignUpContentV2(
          emailController: _sharedEmailController,
          onSwitchToLogin: () => _switchMode(AuthModeV2.login),
        );
      case AuthModeV2.forgotPassword:
        return ForgotPasswordContentV2(
          emailController: _sharedEmailController,
          onBackToLogin: () => _switchMode(AuthModeV2.login),
        );
    }
  }
}
