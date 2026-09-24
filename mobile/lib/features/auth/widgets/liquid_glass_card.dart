import 'dart:ui';
import 'package:flutter/material.dart';
import 'liquid_theme.dart';

/// Reusable Liquid Glass Card Component
/// Conforms to Section 5 & 7 of the FocusFlow Liquid Glass Design System:
/// - Transparent dark navy glass (rgba(255,255,255,0.08) over #06142B)
/// - 1px translucent border (rgba(255,255,255,0.18))
/// - 28–30px radius
/// - Subtle shadow and blue/cyan edge glow
/// - Single efficient BackdropFilter
class LiquidGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;
  final bool enableBlur;

  const LiquidGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(26.0),
    this.borderRadius = 28.0,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            LiquidTheme.cyan.withValues(alpha: 0.40), // Cyan top rim highlight
            LiquidTheme.glassBorder, // rgba(255, 255, 255, 0.18)
            LiquidTheme.violet.withValues(alpha: 0.14), // Subtle violet reflection
            LiquidTheme.cyan.withValues(alpha: 0.25),
          ],
          stops: const [0.0, 0.35, 0.75, 1.0],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.0), // 1px translucent glass border
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: LiquidTheme.secondaryBackground.withValues(alpha: 0.65), // #06142B
            borderRadius: BorderRadius.circular(borderRadius - 1.0),
          ),
          child: child,
        ),
      ),
    );

    if (enableBlur) {
      cardContent = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: cardContent,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          // Soft volumetric cyan/blue edge glow
          BoxShadow(
            color: LiquidTheme.primary.withValues(alpha: 0.12),
            blurRadius: 36,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
          // Subtle depth shadow
          const BoxShadow(
            color: Color(0x66000000),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: cardContent,
    );
  }
}
