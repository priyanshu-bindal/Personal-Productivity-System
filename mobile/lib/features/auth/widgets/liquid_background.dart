import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'liquid_theme.dart';

class LiquidBackground extends StatefulWidget {
  final bool reducedMotion;

  const LiquidBackground({
    super.key,
    this.reducedMotion = false,
  });

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    );

    if (!widget.reducedMotion) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(LiquidBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reducedMotion != oldWidget.reducedMotion) {
      if (widget.reducedMotion) {
        _controller.stop();
      } else {
        _controller.repeat();
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
      color: LiquidTheme.mainBackground, // #020817 Deep Midnight Navy
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              size: Size.infinite,
              painter: _LiquidPainter(_controller.value, widget.reducedMotion),
            );
          },
        ),
      ),
    );
  }
}

class _LiquidPainter extends CustomPainter {
  final double animationValue;
  final bool reducedMotion;

  _LiquidPainter(this.animationValue, this.reducedMotion);

  @override
  void paint(Canvas canvas, Size size) {
    // Derive t from global millisecond phase so all auth screens (Login, Sign Up,
    // Forgot Password) share the exact same continuous bubble and liquid ribbon positions.
    // This completely eliminates jumps or restarts from frame 0 during page transitions.
    final double globalPhase = (DateTime.now().millisecondsSinceEpoch % 60000) / 60000.0;
    final t = (reducedMotion ? 0.0 : globalPhase) * 2 * math.pi;

    _drawRibbons(canvas, size, t);
    _drawParticles(canvas, size, t);
    _drawBubbles(canvas, size, t);
  }

  void _drawRibbons(Canvas canvas, Size size, double t) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path1 = Path();
    final h = size.height;
    final w = size.width;

    final r1T = t * (60 / 21);
    final r2T = t * (60 / 23);

    path1.moveTo(0, h * 0.4 + math.sin(r1T) * 50);
    path1.quadraticBezierTo(
      w * 0.3, h * 0.2 + math.cos(r1T * 1.2) * 80,
      w * 0.6, h * 0.5 + math.sin(r1T * 0.8) * 60,
    );
    path1.quadraticBezierTo(
      w * 0.9, h * 0.8 + math.cos(r1T * 1.5) * 40,
      w, h * 0.6 + math.sin(r1T) * 50,
    );
    path1.lineTo(w, h);
    path1.lineTo(0, h);
    path1.close();

    paint.shader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        LiquidTheme.primary.withValues(alpha: 0.16),
        LiquidTheme.secondaryBackground.withValues(alpha: 0.10),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(path1, paint);

    final path2 = Path();
    path2.moveTo(0, h * 0.6 + math.cos(r2T) * 40);
    path2.quadraticBezierTo(
      w * 0.4, h * 0.8 + math.sin(r2T * 1.1) * 70,
      w, h * 0.4 + math.cos(r2T * 0.9) * 50,
    );
    path2.lineTo(w, h);
    path2.lineTo(0, h);
    path2.close();

    paint.shader = LinearGradient(
      begin: Alignment.bottomLeft,
      end: Alignment.topRight,
      colors: [
        LiquidTheme.accent.withValues(alpha: 0.16),
        const Color(0x0020D9FF),
      ],
    ).createShader(Rect.fromLTWH(0, 0, w, h));
    paint.blendMode = BlendMode.screen;
    canvas.drawPath(path2, paint);
    paint.blendMode = BlendMode.srcOver;
  }

  void _drawBubbles(Canvas canvas, Size size, double t) {
    _drawGlassBubble(
      canvas,
      Offset(
        size.width * 0.2 + math.sin(t * (60 / 8)) * 30,
        size.height * 0.3 + math.cos(t * (60 / 8)) * 40,
      ),
      size.width * 0.25,
      t * (60 / 8),
    );

    _drawGlassBubble(
      canvas,
      Offset(
        size.width * 0.85 + math.cos(t * (60 / 11)) * 20,
        size.height * 0.7 + math.sin(t * (60 / 11)) * 50,
      ),
      size.width * 0.3,
      t * (60 / 11),
    );

    _drawGlassBubble(
      canvas,
      Offset(
        size.width * 0.1 + math.sin(t * (60 / 13)) * 40,
        size.height * 0.85 + math.cos(t * (60 / 13)) * 20,
      ),
      size.width * 0.18,
      t * (60 / 13),
    );

    final pulse = 1.0 + 0.05 * math.sin(t * (60 / 17));
    _drawGlassBubble(
      canvas,
      Offset(
        size.width * 0.7 + math.cos(t * (60 / 17)) * 25,
        size.height * 0.15 + math.sin(t * (60 / 17)) * 25,
      ),
      size.width * 0.15 * pulse,
      t * (60 / 17),
    );
  }

  void _drawGlassBubble(Canvas canvas, Offset center, double radius, double t) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = RadialGradient(
        center: const Alignment(-0.2, -0.2),
        radius: 1.0,
        colors: [
          LiquidTheme.accent.withValues(alpha: 0.12),
          LiquidTheme.primary.withValues(alpha: 0.06),
          const Color(0x00168BFF),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, fillPaint);

    final rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0,
        endAngle: math.pi * 2,
        transform: GradientRotation(t * 0.5),
        colors: [
          LiquidTheme.highlight, // #8BE8FF
          const Color(0x008BE8FF),
          LiquidTheme.secondaryAccent.withValues(alpha: 0.4), // #6C5CE7
          LiquidTheme.primary.withValues(alpha: 0.2), // #168BFF
          LiquidTheme.accent, // #20D9FF
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius, rimPaint);

    final highlightPath = Path();
    highlightPath.addOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.4, center.dy - radius * 0.4),
        width: radius * 0.6,
        height: radius * 0.3,
      ),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-math.pi / 4);
    canvas.translate(-center.dx, -center.dy);

    final highlightPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x59FFFFFF),
          Color(0x00FFFFFF),
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(center.dx - radius * 0.4, center.dy - radius * 0.4),
        width: radius * 0.6,
        height: radius * 0.3,
      ));

    canvas.drawPath(highlightPath, highlightPaint);
    canvas.restore();
  }

  void _drawParticles(Canvas canvas, Size size, double t) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);

    for (int i = 0; i < 20; i++) {
      final period = 7 + (i % 5);
      final pT = t * (60 / period);

      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final amplitudeX = 10.0 + random.nextDouble() * 20;
      final amplitudeY = 10.0 + random.nextDouble() * 20;
      final pRadius = 1.0 + random.nextDouble() * 3.0;

      final x = baseX + math.sin(pT + i) * amplitudeX;
      final y = baseY + math.cos(pT * 0.8 + i) * amplitudeY;

      final opacity = (0.3 + 0.3 * math.sin(pT * 1.5 + i)).clamp(0.0, 1.0);

      paint.color = (i % 2 == 0 ? LiquidTheme.accent : LiquidTheme.highlight)
          .withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), pRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LiquidPainter oldDelegate) {
    if (reducedMotion) return false;
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.reducedMotion != reducedMotion;
  }
}
