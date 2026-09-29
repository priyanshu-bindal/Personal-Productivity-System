import 'package:flutter/material.dart';
import 'focusflow_logo.dart';

/// Stationary Brand Header for Authentication
///
/// Features:
/// - Hero animation with tag 'focusflow-brand' for smooth transition from Onboarding
/// - Stationary layout position above the authentication card
/// - Clean fluid logo icon and typography
class LiquidAuthHeader extends StatelessWidget {
  final double logoSize;

  const LiquidAuthHeader({
    super.key,
    this.logoSize = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
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
        child: FocusFlowLogo(
          size: logoSize,
          wordmarkFontSize: 26,
          wordmarkFontWeight: FontWeight.w700,
          showSubtitle: true,
          useAurellis: false,
        ),
      ),
    );
  }
}
