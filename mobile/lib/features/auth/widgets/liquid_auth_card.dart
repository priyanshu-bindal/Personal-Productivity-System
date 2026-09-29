import 'dart:ui';
import 'package:flutter/material.dart';

/// Reusable Liquid Glass Authentication Card
///
/// Visual Characteristics:
/// - Dark navy translucent glass surface: rgba(10, 18, 35, 0.80)
/// - Highly readable contrast with foreground text
/// - Subtle 12px blur filter
/// - 1px low-opacity blue-gray border: rgba(120, 150, 210, 0.14) with subtle gradient
/// - Soft shadow depth with no harsh or neon outlines
/// - Consistent 24px corner radius
class LiquidAuthCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool enableBlur;

  const LiquidAuthCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 22.0, vertical: 22.0),
    this.borderRadius = 24.0,
    this.enableBlur = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardBody = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xCC0A1223), // rgba(10, 18, 35, 0.80)
        borderRadius: BorderRadius.circular(borderRadius - 1.0),
      ),
      child: child,
    );

    if (enableBlur) {
      cardBody = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius - 1.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
          child: cardBody,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        // 1px Subtle gradient border (blue-gray / soft violet tint, NO cyan)
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x287896D2), // rgba(120, 150, 210, 0.16)
            Color(0x147896D2), // rgba(120, 150, 210, 0.08)
            Color(0x1F7C6CFF), // subtle violet reflection
            Color(0x147896D2),
          ],
          stops: [0.0, 0.40, 0.75, 1.0],
        ),
        boxShadow: const [
          // Soft ambient dark shadow
          BoxShadow(
            color: Color(0x73000000), // ~45% black shadow
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
          // Extremely subtle blue volumetric depth
          BoxShadow(
            color: Color(0x102F6BFF), // ~6% subtle blue depth
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(1.0), // 1px low-opacity border
        child: cardBody,
      ),
    );
  }
}

/// Backward compatibility alias so existing screens and tests work seamlessly
typedef LiquidGlassCard = LiquidAuthCard;
