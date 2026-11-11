import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_motion.dart';
import '../../core/theme/oled_theme.dart';
import 'widgets/auth_background_v2.dart';
import 'widgets/auth_logo_v2.dart';
import 'widgets/forgot_password_content_v2.dart';
import 'widgets/login_content_v2.dart';
import 'widgets/signup_content_v2.dart';

/// Modes handled by the single auth screen.
enum AuthModeV2 { login, register, forgotPassword }

/// Sign in / Sign up / Reset password — one persistent screen.
///
/// - Static OLED background, no per-frame painting.
/// - Sign in ⇄ Sign up via an iOS segmented control; forms slide in the
///   direction of travel while the container height morphs smoothly.
/// - Reset password slides in as a sub-step with its own back control.
/// - Staggered entrance; every animation is transform/opacity only.
class AuthFlowV2Screen extends ConsumerStatefulWidget {
  final AuthModeV2 initialMode;

  const AuthFlowV2Screen({super.key, this.initialMode = AuthModeV2.login});

  @override
  ConsumerState<AuthFlowV2Screen> createState() => _AuthFlowV2ScreenState();
}

class _AuthFlowV2ScreenState extends ConsumerState<AuthFlowV2Screen>
    with SingleTickerProviderStateMixin {
  late AuthModeV2 _mode;
  int _direction = 1;
  final _sharedEmailController = TextEditingController();

  late final AnimationController _entrance;
  late final List<Animation<double>> _stagger;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    _entrance = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _stagger = List.generate(4, (i) {
      final start = i * 0.12;
      return CurvedAnimation(
        parent: _entrance,
        curve: Interval(start, (start + 0.6).clamp(0.0, 1.0), curve: AppMotion.enter),
      );
    });
    _entrance.forward();
  }

  @override
  void dispose() {
    _entrance.dispose();
    _sharedEmailController.dispose();
    super.dispose();
  }

  void _switchMode(AuthModeV2 next) {
    if (_mode == next) return;
    FocusScope.of(context).unfocus();
    HapticFeedback.selectionClick();
    setState(() {
      _direction = next.index > _mode.index ? 1 : -1;
      _mode = next;
    });
  }

  Widget _enter(int i, Widget child) {
    final a = _stagger[i];
    return FadeTransition(
      opacity: a,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(a),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _mode == AuthModeV2.login,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _switchMode(AuthModeV2.login);
      },
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: Colors.black,
        ),
        child: Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Stack(
              children: [
                const Positioned.fill(child: AuthBackgroundV2()),
                SafeArea(
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: constraints.maxHeight),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 440),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _enter(0, const Align(
                                    alignment: Alignment.centerLeft,
                                    child: AuthLogoV2(),
                                  )),
                                  SizedBox(height: (constraints.maxHeight * 0.06).clamp(24.0, 56.0)),
                                  _enter(1, _buildSegment()),
                                  _enter(2, _buildForm()),
                                  const SizedBox(height: 28),
                                  _enter(3, _buildFooter()),
                                ],
                              ),
                            ),
                          ),
                        ),
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
  }

  Widget _buildSegment() {
    final visible = _mode != AuthModeV2.forgotPassword;
    return AnimatedSize(
      duration: AppMotion.standard,
      curve: AppMotion.enter,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: AppMotion.fast,
        opacity: visible ? 1 : 0,
        child: visible
            ? Padding(
                padding: const EdgeInsets.only(bottom: 30),
                child: _AuthSegmentedControl(
                  selected: _mode == AuthModeV2.register ? 1 : 0,
                  labels: const ['Sign in', 'Sign up'],
                  onChanged: (i) => _switchMode(i == 0 ? AuthModeV2.login : AuthModeV2.register),
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    );
  }

  Widget _buildForm() {
    final dir = _direction.toDouble();
    return AnimatedSize(
      duration: AppMotion.emphasized,
      curve: AppMotion.enter,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppMotion.emphasized,
        reverseDuration: AppMotion.fast,
        switchInCurve: AppMotion.enter,
        switchOutCurve: Curves.easeIn,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, animation) {
          final incoming = child.key == ValueKey<AuthModeV2>(_mode);
          final offset = Tween<Offset>(
            begin: Offset((incoming ? 0.08 : -0.05) * dir, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<AuthModeV2>(_mode),
          child: _content(_mode),
        ),
      ),
    );
  }

  Widget _content(AuthModeV2 mode) {
    switch (mode) {
      case AuthModeV2.login:
        return LoginContentV2(
          emailController: _sharedEmailController,
          onSwitchToSignUp: () => _switchMode(AuthModeV2.register),
          onSwitchToForgotPassword: () => _switchMode(AuthModeV2.forgotPassword),
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

  Widget _buildFooter() {
    return Text(
      'Stay focused. Keep growing.',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(fontSize: 12, color: OledTheme.textMuted),
    );
  }
}

/// iOS-style segmented control with a sliding thumb.
class _AuthSegmentedControl extends StatelessWidget {
  final int selected;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  const _AuthSegmentedControl({
    required this.selected,
    required this.labels,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF111114),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF1F1F23)),
      ),
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / labels.length;
          return Stack(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(end: selected.toDouble()),
                duration: AppMotion.emphasized,
                curve: AppMotion.enter,
                builder: (context, v, child) =>
                    Transform.translate(offset: Offset(v * w, 0), child: child),
                child: Container(
                  width: w,
                  height: c.maxHeight,
                  decoration: BoxDecoration(
                    color: const Color(0xFF232328),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x14FFFFFF), width: 0.6),
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < labels.length; i++)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: i == selected,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => onChanged(i),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: AppMotion.fast,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: i == selected
                                    ? OledTheme.textPrimary
                                    : OledTheme.textMuted,
                              ),
                              child: Text(labels[i]),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
