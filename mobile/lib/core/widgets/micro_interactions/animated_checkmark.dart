import 'package:flutter/material.dart';
import '../../theme/ocean_theme.dart';

/// A standalone animated checkmark that draws its stroke with a [CustomPainter].
class AnimatedCheckmark extends StatefulWidget {
  final double size;
  final Color? color;
  final double strokeWidth;
  final Duration duration;
  final Curve curve;
  final bool autoStart;

  const AnimatedCheckmark({
    super.key,
    this.size = 24.0,
    this.color,
    this.strokeWidth = 2.5,
    this.duration = const Duration(milliseconds: 260),
    this.curve = Curves.easeOutCubic,
    this.autoStart = true,
  });

  @override
  State<AnimatedCheckmark> createState() => _AnimatedCheckmarkState();
}

class _AnimatedCheckmarkState extends State<AnimatedCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );
  }

  bool _hasStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.autoStart && !_hasStarted) {
      _hasStarted = true;
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _controller.value = 1.0;
      } else {
        _controller.forward();
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
    final effectiveColor = widget.color ?? OceanTheme.primary;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CheckStrokePainter(
            progress: _animation.value,
            color: effectiveColor,
            strokeWidth: widget.strokeWidth,
          ),
        );
      },
    );
  }
}

class _CheckStrokePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _CheckStrokePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    final start = Offset(size.width * 0.22, size.height * 0.52);
    final pivot = Offset(size.width * 0.42, size.height * 0.72);
    final end = Offset(size.width * 0.78, size.height * 0.32);

    path.moveTo(start.dx, start.dy);

    final leg1Length = (pivot - start).distance;
    final leg2Length = (end - pivot).distance;
    final totalLength = leg1Length + leg2Length;
    final currentDistance = totalLength * progress;

    if (currentDistance <= leg1Length) {
      final legProgress = currentDistance / leg1Length;
      final currentPivot = Offset.lerp(start, pivot, legProgress)!;
      path.lineTo(currentPivot.dx, currentPivot.dy);
    } else {
      path.lineTo(pivot.dx, pivot.dy);
      final leg2Progress = (currentDistance - leg1Length) / leg2Length;
      final currentEnd = Offset.lerp(pivot, end, leg2Progress)!;
      path.lineTo(currentEnd.dx, currentEnd.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckStrokePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
