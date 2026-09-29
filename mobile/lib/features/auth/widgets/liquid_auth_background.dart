import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'liquid_theme.dart';

/// Reusable Dark Liquid Glass Background Component
///
/// Features:
/// - Very dark navy/black base (#020617)
/// - Extremely subtle, slow atmospheric gradients/blobs in Blue & Violet (NO CYAN)
/// - Smooth 14-second drifting loop (ease-in-out reverse)
/// - Isolated in a [RepaintBoundary] so text fields and cards never rebuild on animation frames
class LiquidAuthBackground extends StatefulWidget {
  final bool reducedMotion;
  final double atmosphericOpacity;

  const LiquidAuthBackground({
    super.key,
    this.reducedMotion = false,
    this.atmosphericOpacity = 1.0,
  });

  @override
  State<LiquidAuthBackground> createState() => _LiquidAuthBackgroundState();
}

class _LiquidAuthBackgroundState extends State<LiquidAuthBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    if (!widget.reducedMotion) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(LiquidAuthBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion != oldWidget.reducedMotion) {
      if (widget.reducedMotion) {
        _controller.stop();
      } else {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: LiquidTheme.background, // #020617
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              size: Size.infinite,
              painter: _LiquidAtmospherePainter(
                progress: _controller.value,
                atmosphericOpacity: widget.atmosphericOpacity,
                reducedMotion: widget.reducedMotion,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LiquidAtmospherePainter extends CustomPainter {
  final double progress;
  final double atmosphericOpacity;
  final bool reducedMotion;

  _LiquidAtmospherePainter({
    required this.progress,
    required this.atmosphericOpacity,
    required this.reducedMotion,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (atmosphericOpacity <= 0.0) return;

    final double w = size.width;
    final double h = size.height;
    final double t = (reducedMotion ? 0.5 : progress) * math.pi;

    // ── 1. Top Deep Blue Ambient Glow ─────────────────────────────
    // Subtle breathing displacement
    final double dx1 = math.sin(t) * 35;
    final double dy1 = math.cos(t * 0.8) * 25;
    final Offset center1 = Offset(w * 0.25 + dx1, h * 0.15 + dy1);
    final double radius1 = w * 0.75;

    final Paint glow1 = Paint()
      ..shader = RadialGradient(
        colors: [
          LiquidTheme.primary.withValues(alpha: 0.12 * atmosphericOpacity), // #2F6BFF
          LiquidTheme.secondaryBlue.withValues(alpha: 0.05 * atmosphericOpacity), // #4F7CFF
          const Color(0x00020617),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center1, radius: radius1));
    canvas.drawCircle(center1, radius1, glow1);

    // ── 2. Center-Right Subtle Violet Atmospheric Nebula ──────────
    final double dx2 = math.cos(t * 0.9) * 40;
    final double dy2 = math.sin(t * 1.1) * 30;
    final Offset center2 = Offset(w * 0.80 + dx2, h * 0.45 + dy2);
    final double radius2 = w * 0.80;

    final Paint glow2 = Paint()
      ..shader = RadialGradient(
        colors: [
          LiquidTheme.violet.withValues(alpha: 0.09 * atmosphericOpacity), // #7C6CFF
          LiquidTheme.primary.withValues(alpha: 0.03 * atmosphericOpacity),
          const Color(0x00020617),
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(center: center2, radius: radius2));
    canvas.drawCircle(center2, radius2, glow2);

    // ── 3. Bottom Subtle Deep Navy/Blue Glow ──────────────────────
    final double dx3 = math.sin(t * 0.7) * 25;
    final Offset center3 = Offset(w * 0.5 + dx3, h * 0.88);
    final double radius3 = w * 0.70;

    final Paint glow3 = Paint()
      ..shader = RadialGradient(
        colors: [
          LiquidTheme.secondaryBlue.withValues(alpha: 0.07 * atmosphericOpacity),
          const Color(0x00020617),
        ],
        stops: const [0.0, 0.70],
      ).createShader(Rect.fromCircle(center: center3, radius: radius3));
    canvas.drawCircle(center3, radius3, glow3);
  }

  @override
  bool shouldRepaint(covariant _LiquidAtmospherePainter oldDelegate) {
    if (reducedMotion) {
      return oldDelegate.atmosphericOpacity != atmosphericOpacity;
    }
    return oldDelegate.progress != progress ||
        oldDelegate.atmosphericOpacity != atmosphericOpacity;
  }
}
