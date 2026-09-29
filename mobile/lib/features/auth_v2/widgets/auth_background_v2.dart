import 'package:flutter/material.dart';

/// Premium OLED/Navy background for Auth Flow V2.
/// Deep blacks, dark navy, and restrained ambient blue glow.
/// Strictly no cyan, teal, or neon effects.
class AuthBackgroundV2 extends StatelessWidget {
  const AuthBackgroundV2({super.key});

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base OLED Deep Background
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF000000), // OLED black top
                  Color(0xFF030712), // Deepest midnight navy
                  Color(0xFF060B18), // Deep navy
                  Color(0xFF02040A), // Black anchor bottom
                ],
                stops: [0.0, 0.35, 0.70, 1.0],
              ),
            ),
          ),

          // Upper Ambient Soft Blue Glow (Restrained #2F6BFF)
          Positioned(
            top: -120,
            left: -60,
            width: 380,
            height: 380,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF2F6BFF).withValues(alpha: 0.14),
                    const Color(0xFF1E40AF).withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Lower Right Soft Ambient Deep Navy/Blue Glow
          Positioned(
            bottom: -100,
            right: -80,
            width: 360,
            height: 360,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF1D4ED8).withValues(alpha: 0.12),
                    const Color(0xFF0F172A).withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.50, 1.0],
                ),
              ),
            ),
          ),

          // Subtle Center Depth Accent
          Positioned(
            top: 220,
            left: 40,
            right: 40,
            height: 300,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(160),
                gradient: RadialGradient(
                  radius: 0.85,
                  colors: [
                    const Color(0xFF1E3A8A).withValues(alpha: 0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
