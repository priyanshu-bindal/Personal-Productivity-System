import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium iOS-inspired Liquid Glass Primary Button V2.
/// Features:
/// - Exact 54px height & 15px border radius
/// - #2F6BFF deep blue glass gradient with restrained luminous depth
/// - Subtle top specular reflection line
/// - Restrained soft blue shadow (zero excessive neon)
/// - White Space Grotesk w700 typography
/// - Micro-scale press response (1.0 → 0.98 → 1.0, 120ms easeOutCubic, no bounce) with light haptic feedback
/// - Loading state preserves exact button dimensions and blocks duplicate taps
class LiquidGlassPrimaryButtonV2 extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final IconData? icon;

  const LiquidGlassPrimaryButtonV2({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.icon,
  });

  @override
  State<LiquidGlassPrimaryButtonV2> createState() =>
      _LiquidGlassPrimaryButtonV2State();
}

class _LiquidGlassPrimaryButtonV2State
    extends State<LiquidGlassPrimaryButtonV2> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.isLoading || widget.onTap == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.isLoading || widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    if (widget.isLoading || widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onTap == null && !widget.isLoading;
    final scale = _isPressed ? 0.98 : 1.0;

    return Semantics(
      button: true,
      enabled: !isDisabled,
      label: widget.label,
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        child: GestureDetector(
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: widget.isLoading ? null : widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
          height: 54, // Consistent 54px height across all states
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            // Restrained soft blue elevation glow
            boxShadow: isDisabled
                ? null
                : const [
                    BoxShadow(
                      color: Color(0x382F6BFF), // Soft blue glow
                      blurRadius: 20,
                      spreadRadius: -2,
                      offset: Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
            // Deep glass blue gradient
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDisabled
                  ? [
                      const Color(0xFF1E293B),
                      const Color(0xFF0F172A),
                    ]
                  : [
                      const Color(0xFF3D7FFF), // Luminous top catch
                      const Color(0xFF2F6BFF), // FocusFlow primary blue
                      const Color(0xFF1E58E8), // Rich bottom anchor
                    ],
            ),
            // Subtle top highlight reflection border
            border: Border.all(
              color: isDisabled
                  ? const Color(0xFF334155)
                  : const Color(0xFF6B9CFF).withValues(alpha: 0.50),
              width: 1.0,
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Subtle top internal specular highlight line
              if (!isDisabled)
                Positioned(
                  top: 0,
                  left: 20,
                  right: 20,
                  height: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.40),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

              // Button Content: Loading spinner or Label + Icon
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: widget.isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (widget.icon != null) ...[
                                Icon(
                                  widget.icon,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                widget.label,
                                style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
