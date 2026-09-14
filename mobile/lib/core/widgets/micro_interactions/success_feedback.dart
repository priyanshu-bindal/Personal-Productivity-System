import 'package:flutter/material.dart';
import '../../theme/ocean_theme.dart';
import 'animated_checkmark.dart';

/// A subtle, premium success feedback badge featuring fade + scale + checkmark stroke animation.
///
/// Designed for low-effort, non-intrusive feedback like:
/// "✓ Saved", "✓ Added", "✓ Updated", "✓ Completed", "✓ Rescheduled".
class SuccessFeedback extends StatelessWidget {
  final String message;
  final TextStyle? style;
  final Color? backgroundColor;
  final Color? color;
  final double checkSize;
  final EdgeInsetsGeometry padding;
  final BorderRadius? borderRadius;

  const SuccessFeedback({
    super.key,
    required this.message,
    this.style,
    this.backgroundColor,
    this.color,
    this.checkSize = 16.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = color ?? OceanTheme.primary;
    final bg = backgroundColor ?? accentColor.withValues(alpha: 0.15);
    final radius = borderRadius ?? BorderRadius.circular(20);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.85 + (value * 0.15),
            child: child,
          ),
        );
      },
      child: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: radius,
          border: Border.all(
            color: accentColor.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedCheckmark(
              size: checkSize,
              color: accentColor,
              strokeWidth: 2.2,
            ),
            const SizedBox(width: 6),
            Text(
              message,
              style: style ??
                  TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                    letterSpacing: 0.2,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
