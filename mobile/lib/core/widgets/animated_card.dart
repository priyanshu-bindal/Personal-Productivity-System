import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';

class AnimatedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final int index;

  const AnimatedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.index = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveMargin = margin ?? const EdgeInsets.only(bottom: 12);
    final effectivePadding = padding ?? const EdgeInsets.all(16);
    final baseBgColor = backgroundColor ?? AppColors.card;
    final baseBorder = border ?? Border.all(color: AppColors.border, width: 1);

    Widget card = _PressableCard(
      padding: effectivePadding,
      backgroundColor: baseBgColor,
      border: baseBorder,
      onTap: onTap,
      child: child,
    );

    final animated = card
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: (index * 40).clamp(0, 300)),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.1,
          end: 0,
          duration: const Duration(milliseconds: 300),
          delay: Duration(milliseconds: (index * 40).clamp(0, 300)),
          curve: Curves.easeOutCubic,
        );

    return Padding(
      padding: effectiveMargin,
      child: animated,
    );
  }
}

class _PressableCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Border border;
  final VoidCallback? onTap;

  const _PressableCard({
    required this.child,
    required this.padding,
    required this.backgroundColor,
    required this.border,
    this.onTap,
  });

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final pressedBg = Color.alphaBlend(
      AppColors.primary.withValues(alpha: 0.07),
      widget.backgroundColor,
    );

    Widget content = AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _isPressed ? pressedBg : widget.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: _isPressed
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  width: 1.2,
                )
              : widget.border,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
