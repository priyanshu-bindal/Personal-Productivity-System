import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/ocean_theme.dart';

/// A premium checkbox that draws the checkmark stroke progressively from 0% to 100%
/// with a smooth background fill crossfade and scale-in rather than popping instantly.
class AnimatedCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final Color? activeColor;
  final Color? checkColor;
  final Color? borderColor;
  final double size;
  final double strokeWidth;
  final BorderRadius? borderRadius;
  final bool enabled;

  const AnimatedCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.checkColor,
    this.borderColor,
    this.size = 22.0,
    this.strokeWidth = 2.4,
    this.borderRadius,
    this.enabled = true,
  });

  @override
  State<AnimatedCheckbox> createState() => _AnimatedCheckboxState();
}

class _AnimatedCheckboxState extends State<AnimatedCheckbox>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: widget.value ? 1.0 : 0.0,
    );

    _checkAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void didUpdateWidget(covariant AnimatedCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _controller.value = widget.value ? 1.0 : 0.0;
      } else {
        if (widget.value) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.enabled || widget.onChanged == null) return;
    HapticFeedback.lightImpact();
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final activeCol = widget.activeColor ?? OceanTheme.primary;
    final checkCol = widget.checkColor ?? OceanTheme.bg;
    final borderCol = widget.borderColor ?? AppColors.border;
    final radius = widget.borderRadius ?? BorderRadius.circular(6);

    return GestureDetector(
      onTap: widget.enabled ? _handleTap : null,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final progress = _checkAnimation.value;
          final scale = widget.value ? _scaleAnimation.value : 1.0;

          final currentBg = Color.lerp(
            Colors.transparent,
            activeCol,
            progress,
          )!;

          final currentBorder = Color.lerp(
            borderCol,
            activeCol,
            progress,
          )!;

          return Transform.scale(
            scale: scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: currentBg,
                borderRadius: radius,
                border: Border.all(
                  color: currentBorder,
                  width: 1.5,
                ),
              ),
              child: progress > 0.0
                  ? CustomPaint(
                      painter: _CheckmarkPainter(
                        progress: progress,
                        color: checkCol,
                        strokeWidth: widget.strokeWidth,
                      ),
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  const _CheckmarkPainter({
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
    // Normalized checkmark coordinates
    // Start: (0.24 * w, 0.52 * h)
    // Pivot: (0.44 * w, 0.72 * h)
    // End:   (0.76 * w, 0.32 * h)
    final start = Offset(size.width * 0.24, size.height * 0.52);
    final pivot = Offset(size.width * 0.44, size.height * 0.72);
    final end = Offset(size.width * 0.76, size.height * 0.32);

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
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}
