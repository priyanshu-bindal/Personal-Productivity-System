import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/ocean_theme.dart';
import '../pressable_scale.dart';

/// A standalone micro-interaction button for `+` actions (FABs or icon buttons).
///
/// Transitions smoothly:
/// `+` -> [RotationTransition + FadeTransition] -> `✓`
/// Holds the success checkmark for 400–600ms, then returns cleanly to `+`.
/// Prevents double-taps while the action or success animation is running.
class AnimatedAddButton extends StatefulWidget {
  final FutureOr<void> Function() onPressed;
  final double size;
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? successBackgroundColor;
  final Color? successIconColor;
  final String? tooltip;
  final BoxShape shape;
  final BorderRadius? borderRadius;
  final BoxBorder? border;

  const AnimatedAddButton({
    super.key,
    required this.onPressed,
    this.size = 52.0,
    this.iconSize = 22.0,
    this.backgroundColor,
    this.iconColor,
    this.successBackgroundColor,
    this.successIconColor,
    this.tooltip,
    this.shape = BoxShape.circle,
    this.borderRadius,
    this.border,
  });

  @override
  State<AnimatedAddButton> createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<AnimatedAddButton> {
  bool _isRunning = false;
  bool _showSuccess = false;
  Timer? _revertTimer;

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  Future<void> _handlePress() async {
    if (_isRunning || _showSuccess) return;

    setState(() => _isRunning = true);

    try {
      await widget.onPressed();

      if (!mounted) return;

      HapticFeedback.lightImpact();
      setState(() {
        _isRunning = false;
        _showSuccess = true;
      });

      _revertTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() => _showSuccess = false);
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _isRunning = false;
          _showSuccess = false;
        });
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final defaultBg = widget.backgroundColor ?? OceanTheme.primary;
    final defaultSuccessBg = widget.successBackgroundColor ?? OceanTheme.secondary;
    final defaultIconCol = widget.iconColor ?? Colors.white;
    final defaultSuccessIconCol = widget.successIconColor ?? Colors.white;

    final currentBg = _showSuccess ? defaultSuccessBg : defaultBg;
    final currentIconCol = _showSuccess ? defaultSuccessIconCol : defaultIconCol;

    final buttonWidget = PressableScale(
      onTap: (_isRunning || _showSuccess) ? null : _handlePress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: currentBg,
          shape: widget.shape,
          borderRadius: widget.shape == BoxShape.circle
              ? null
              : (widget.borderRadius ?? BorderRadius.circular(14)),
          border: widget.border,
          boxShadow: [
            BoxShadow(
              color: currentBg.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              return RotationTransition(
                turns: Tween<double>(begin: -0.25, end: 0.0).animate(animation),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: _showSuccess
                ? Icon(
                    LucideIcons.check,
                    key: const ValueKey('add_btn_check'),
                    color: currentIconCol,
                    size: widget.iconSize,
                  )
                : Icon(
                    LucideIcons.plus,
                    key: const ValueKey('add_btn_plus'),
                    color: currentIconCol,
                    size: widget.iconSize,
                  ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: buttonWidget,
      );
    }

    return buttonWidget;
  }
}
