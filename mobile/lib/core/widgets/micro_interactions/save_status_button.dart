import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../pressable_scale.dart';

enum SaveButtonState {
  idle,
  saving,
  success,
}

/// A premium CTA button that smoothly communicates state changes:
/// [SaveButtonState.idle] -> [SaveButtonState.saving] -> [SaveButtonState.success] -> [SaveButtonState.idle]
///
/// Features:
/// - Starts actual save operation immediately (no artificial delay)
/// - Shows saving spinner without layout jump
/// - Shows success badge with a subtle 1.0 -> 1.05 -> 1.0 scale-pop
/// - Reverts to idle on error to allow user to retry
/// - Prevents double-taps while in-flight
/// - Does not force auto-pop: sheet closure remains up to the caller
class SaveStatusButton extends StatefulWidget {
  final String label;
  final String savingLabel;
  final String successLabel;
  final FutureOr<void> Function() onSubmit;
  final IconData? icon;
  final IconData? successIcon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final BoxDecoration? decoration;
  final double height;
  final double? width;
  final bool enabled;

  const SaveStatusButton({
    super.key,
    required this.label,
    this.savingLabel = 'Saving...',
    this.successLabel = '✓ Saved',
    required this.onSubmit,
    this.icon,
    this.successIcon = LucideIcons.check,
    this.backgroundColor,
    this.foregroundColor,
    this.decoration,
    this.height = 50.0,
    this.width,
    this.enabled = true,
  });

  @override
  State<SaveStatusButton> createState() => _SaveStatusButtonState();
}

class _SaveStatusButtonState extends State<SaveStatusButton>
    with SingleTickerProviderStateMixin {
  SaveButtonState _state = SaveButtonState.idle;
  late final AnimationController _popController;
  late final Animation<double> _scaleAnimation;
  Timer? _resetTimer;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    // Subtle scale-pop: 1.0 -> 1.05 -> 1.0
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 60,
      ),
    ]).animate(_popController);
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    _popController.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (!widget.enabled || _state != SaveButtonState.idle) return;

    setState(() => _state = SaveButtonState.saving);

    try {
      await widget.onSubmit();

      if (!mounted) return;

      setState(() => _state = SaveButtonState.success);
      HapticFeedback.lightImpact();

      // Respect reduced motion
      final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (!reduceMotion) {
        _popController.forward(from: 0.0);
      }

      // Hold success state for ~500ms so user perceives it
      _resetTimer = Timer(const Duration(milliseconds: 550), () {
        if (mounted && _state == SaveButtonState.success) {
          setState(() => _state = SaveButtonState.idle);
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _state = SaveButtonState.idle);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fgColor = widget.foregroundColor ?? Colors.white;

    final defaultDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: const LinearGradient(
        colors: [
          Color(0xFF14C8A8),
          Color(0xFF0F9F86),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: 0.28),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );

    return ScaleTransition(
      scale: _scaleAnimation,
      child: PressableScale(
        onTap: (widget.enabled && _state == SaveButtonState.idle) ? _handleTap : null,
        child: Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: widget.decoration ??
              (widget.backgroundColor != null
                  ? BoxDecoration(
                      color: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(14),
                    )
                  : defaultDecoration),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(
                    scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildContent(fgColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color fgColor) {
    switch (_state) {
      case SaveButtonState.saving:
        return Row(
          key: const ValueKey('saving'),
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(fgColor),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              widget.savingLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: fgColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        );

      case SaveButtonState.success:
        return Row(
          key: const ValueKey('success'),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.successIcon != null) ...[
              Icon(widget.successIcon, color: fgColor, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              widget.successLabel,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: fgColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        );

      case SaveButtonState.idle:
        return Row(
          key: const ValueKey('idle'),
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.icon != null) ...[
              Icon(widget.icon, color: fgColor, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: fgColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        );
    }
  }
}
