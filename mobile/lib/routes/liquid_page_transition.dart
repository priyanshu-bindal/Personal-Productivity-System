import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// FocusFlow Liquid Page Transitions
///
/// Implements cohesive, cinematic Liquid Glass transitions across:
/// - Login ↔ Sign Up (subtle horizontal glide + scale + depth parallax)
/// - Login ↔ Forgot Password (horizontal slide + fade)
/// - Successful Login / Sign Up → Main App (dissolve + gentle upward emergence)
class LiquidPageTransition {
  LiquidPageTransition._();

  /// Primary Auth Screen (Login)
  ///
  /// - Forward entrance: subtle fade + vertical float (400ms easeOutCubic)
  /// - Outgoing when subscreen (Sign Up / Forgot Password) pushes over it:
  ///   - translateX: 0 → -12px
  ///   - scale: 1.0 → 0.99
  ///   - opacity: 1.0 → 0.0
  /// - Outgoing when entering Main App (/today):
  ///   - translateY: 0 → -8px
  ///   - scale: 1.0 → 0.985
  ///   - opacity: 1.0 → 0.0
  static CustomTransitionPage<T> authMainScreen<T>({
    required LocalKey key,
    required Widget child,
    bool? isHeadingToMainApp,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 380),
      reverseTransitionDuration: const Duration(milliseconds: 340),
      transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
        final enterCurved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInOutCubic,
        );

        final secondaryCurved = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInOutCubic,
        );

        // Determine if outgoing towards Main App or towards an Auth Sub-screen once per build
        bool headingToMainApp = isHeadingToMainApp ?? false;
        if (isHeadingToMainApp == null) {
          try {
            final targetPath = GoRouterState.of(context).uri.path;
            headingToMainApp = targetPath.startsWith('/today') ||
                targetPath.startsWith('/skills') ||
                targetPath.startsWith('/calendar') ||
                targetPath.startsWith('/progress') ||
                targetPath.startsWith('/money');
          } catch (_) {}
        }

        final secondaryFade = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(secondaryCurved);

        return FadeTransition(
          opacity: secondaryFade,
          child: AnimatedBuilder(
            animation: secondaryCurved,
            builder: (context, staticChild) {
              if (secondaryCurved.value == 0.0) {
                return staticChild!;
              }

              if (headingToMainApp) {
                // Outgoing toward Main App: translateY 0 → -8px, scale 1.0 → 0.985
                final double translateY = -8.0 * secondaryCurved.value;
                final double scale = 1.0 - (0.015 * secondaryCurved.value);

                return Transform.translate(
                  offset: Offset(0, translateY),
                  child: Transform.scale(
                    scale: scale,
                    child: staticChild,
                  ),
                );
              } else {
                // Outgoing toward Sign Up / Forgot Password: translateX 0 → -12px, scale 1.0 → 0.99
                final double translateX = -12.0 * secondaryCurved.value;
                final double scale = 1.0 - (0.010 * secondaryCurved.value);

                return Transform.translate(
                  offset: Offset(translateX, 0),
                  child: Transform.scale(
                    scale: scale,
                    child: staticChild,
                  ),
                );
              }
            },
            child: FadeTransition(
              opacity: enterCurved,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.03),
                  end: Offset.zero,
                ).animate(enterCurved),
                child: AnimatedBuilder(
                  animation: enterCurved,
                  builder: (context, innerChild) {
                    final double scale = 0.985 + (0.015 * enterCurved.value);
                    return Transform.scale(
                      scale: scale,
                      child: innerChild,
                    );
                  },
                  child: pageChild,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Auth Sub-Screens (Sign Up / Forgot Password)
  ///
  /// - Forward entrance (from Login):
  ///   - translateX: +20px → 0
  ///   - scale: 0.985 → 1.0
  ///   - opacity: 0 → 1
  ///   - Duration: 340ms, easeOutCubic
  /// - Reverse exit (back to Login):
  ///   - translateX: 0 → +20px
  ///   - scale: 1.0 → 0.985
  ///   - opacity: 1 → 0
  ///   - Duration: 320ms, easeInOutCubic
  /// - Outgoing when advancing to Main App (/today):
  ///   - translateY: 0 → -8px, scale: 1.0 → 0.985, opacity: 1 → 0
  static CustomTransitionPage<T> authSubScreen<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 340),
      reverseTransitionDuration: const Duration(milliseconds: 320),
      transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
        final enterCurved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInOutCubic,
        );

        final secondaryCurved = CurvedAnimation(
          parent: secondaryAnimation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInOutCubic,
        );

        final secondaryFade = Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).animate(secondaryCurved);

        return FadeTransition(
          opacity: secondaryFade,
          child: AnimatedBuilder(
            animation: secondaryCurved,
            builder: (context, staticChild) {
              if (secondaryCurved.value == 0.0) {
                return staticChild!;
              }

              // When navigating directly from Sign Up into Main App on account creation
              final double translateY = -8.0 * secondaryCurved.value;
              final double scale = 1.0 - (0.015 * secondaryCurved.value);

              return Transform.translate(
                offset: Offset(0, translateY),
                child: Transform.scale(
                  scale: scale,
                  child: staticChild,
                ),
              );
            },
            child: FadeTransition(
              opacity: enterCurved,
              child: AnimatedBuilder(
                animation: enterCurved,
                builder: (context, innerChild) {
                  final double translateX = 20.0 * (1.0 - enterCurved.value);
                  final double scale = 0.985 + (0.015 * enterCurved.value);

                  return Transform.translate(
                    offset: Offset(translateX, 0),
                    child: Transform.scale(
                      scale: scale,
                      child: innerChild,
                    ),
                  );
                },
                child: pageChild,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Main App Navigation Shell (Today / Dashboard entrance)
  ///
  /// - Smoothly emerges when authentication succeeds:
  ///   - translateY: 12px → 0
  ///   - scale: 0.985 → 1.0
  ///   - opacity: 0 → 1
  ///   - Duration: 500ms, easeOutCubic
  static CustomTransitionPage<T> appShell<T>({
    required LocalKey key,
    required Widget child,
  }) {
    return CustomTransitionPage<T>(
      key: key,
      child: child,
      transitionDuration: const Duration(milliseconds: 500),
      transitionsBuilder: (context, animation, secondaryAnimation, pageChild) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );

        return FadeTransition(
          opacity: curved,
          child: AnimatedBuilder(
            animation: curved,
            builder: (context, staticChild) {
              final double translateY = 12.0 * (1.0 - curved.value);
              final double scale = 0.985 + (0.015 * curved.value);

              return Transform.translate(
                offset: Offset(0, translateY),
                child: Transform.scale(
                  scale: scale,
                  child: staticChild,
                ),
              );
            },
            child: pageChild,
          ),
        );
      },
    );
  }
}
