import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'liquid_theme.dart';

/// Reusable Dark Liquid Glass Primary Action Button
///
/// Features:
/// - Primary Blue #2F6BFF with subtle linear depth gradient
/// - Consistent 52px height and 15px corner radius
/// - Smooth scale feedback on press (0.98, 120ms easeOutCubic) with light haptic feedback
/// - In-place loading state with a compact 20px spinner without altering dimensions or causing layout shift
/// - Duplicate taps safely guarded
class LiquidAuthButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool enabled;
  final double height;
  final double borderRadius;
  final IconData? icon;

  const LiquidAuthButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.enabled = true,
    this.height = 52.0,
    this.borderRadius = 15.0,
    this.icon,
  });

  @override
  State<LiquidAuthButton> createState() => _LiquidAuthButtonState();
}

class _LiquidAuthButtonState extends State<LiquidAuthButton> {
  bool _isPressed = false;

  bool get _isInteractive => widget.enabled && !widget.isLoading && widget.onTap != null;

  void _handleTapDown(TapDownDetails _) {
    if (!_isInteractive) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_isInteractive) return;
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (!_isInteractive) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: _isInteractive,
      label: widget.label,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.98 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              // Blue gradient: #3B76FF -> #2358DF (NO CYAN)
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.enabled
                    ? [
                        const Color(0xFF3872FF), // slightly brighter rim
                        const Color(0xFF245BE8), // deep vibrant core
                      ]
                    : [
                        const Color(0xFF1E3258),
                        const Color(0xFF15223C),
                      ],
              ),
              boxShadow: widget.enabled
                  ? [
                      // Subtle blue ambient elevation
                      BoxShadow(
                        color: LiquidTheme.primary.withValues(alpha: _isPressed ? 0.20 : 0.35),
                        blurRadius: _isPressed ? 12 : 20,
                        offset: const Offset(0, 4),
                      ),
                      // Soft depth shadow
                      const BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : const [],
              border: Border.all(
                color: const Color(0x33FFFFFF), // 1px subtle glass highlight
                width: 1.0,
              ),
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.label,
                          style: LiquidTheme.buttonText(fontSize: 15.5).copyWith(
                            fontWeight: FontWeight.w600,
                            color: widget.enabled
                                ? LiquidTheme.textPrimary
                                : LiquidTheme.textMuted,
                            letterSpacing: 0.2,
                          ),
                        ),
                        if (widget.icon != null) ...[
                          const SizedBox(width: 8),
                          Icon(
                            widget.icon,
                            size: 17,
                            color: widget.enabled
                                ? LiquidTheme.textPrimary
                                : LiquidTheme.textMuted,
                          ),
                        ],
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Backward compatibility adapter for LiquidGlassButton
class LiquidGlassButton extends StatelessWidget {
  final String? label;
  final String? text;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool showArrow;
  final bool isLoading;
  final bool isSuccess;
  final bool enabled;
  final double? width;
  final double height;
  final double borderRadius;

  const LiquidGlassButton({
    super.key,
    this.label,
    this.text,
    this.onTap,
    this.onPressed,
    this.icon,
    this.showArrow = true,
    this.isLoading = false,
    this.isSuccess = false,
    this.enabled = true,
    this.width,
    this.height = 52.0,
    this.borderRadius = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidAuthButton(
      label: label ?? text ?? '',
      onTap: onTap ?? onPressed,
      isLoading: isLoading,
      enabled: enabled,
      height: height,
      borderRadius: borderRadius,
      icon: icon,
    );
  }
}
