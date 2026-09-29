import 'dart:ui';
import 'package:flutter/material.dart';

/// Premium iOS-inspired Liquid Glass Card V2.
/// Features:
/// - Controlled hardware-accelerated BackdropFilter blur
/// - Translucent deep navy surface with subtle depth
/// - Elegant multi-layer soft shadows for elevation
/// - Thin, low-opacity blue-gray border with subtle top-edge reflection
/// - Zero cyan, zero neon, perfectly rounded corners
class LiquidGlassAuthCardV2 extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  const LiquidGlassAuthCardV2({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        // Multi-layered soft shadows for authentic floating glass depth
        boxShadow: const [
          BoxShadow(
            color: Color(0x8A000000), // Rich dark drop shadow
            blurRadius: 40,
            spreadRadius: 0,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Color(0x162F6BFF), // Very subtle ambient blue depth
            blurRadius: 32,
            spreadRadius: -4,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18.0, sigmaY: 18.0),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: radius,
              // Translucent deep navy glass gradient
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0D1629).withValues(alpha: 0.82), // subtle light catch top-left
                  const Color(0xFF090E1B).withValues(alpha: 0.85), // deep navy body
                  const Color(0xFF060A14).withValues(alpha: 0.88), // anchored bottom-right
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              // Thin low-opacity blue-gray perimeter border with subtle top highlight
              border: Border.all(
                color: const Color(0xFF1E2D48).withValues(alpha: 0.65),
                width: 1.0,
              ),
            ),
            child: Stack(
              children: [
                // Subtle inner top specular reflection line
                Positioned(
                  top: 0,
                  left: 24,
                  right: 24,
                  height: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          const Color(0xFF4F83FF).withValues(alpha: 0.28),
                          const Color(0xFFFFFFFF).withValues(alpha: 0.15),
                          const Color(0xFF4F83FF).withValues(alpha: 0.28),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.25, 0.50, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),

                // Card Content
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
