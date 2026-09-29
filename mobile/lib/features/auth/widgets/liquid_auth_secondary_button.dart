import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'liquid_theme.dart';

/// Reusable Dark Liquid Glass Secondary Button (e.g. Google Sign-In)
///
/// Features:
/// - Dark glass surface: rgba(20, 30, 52, 0.55)
/// - Height: 50–52px, Radius: 15px
/// - 1px subtle border (#26334A)
/// - Authentic multi-color or monochrome Google "G" emblem
/// - Smooth scale interaction (0.98 on press, 120ms)
class LiquidAuthSecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final Widget? leading;
  final double height;
  final double borderRadius;

  const LiquidAuthSecondaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.isLoading = false,
    this.leading,
    this.height = 50.0,
    this.borderRadius = 15.0,
  });

  /// Factory constructor for "Continue with Google" button
  factory LiquidAuthSecondaryButton.google({
    Key? key,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return LiquidAuthSecondaryButton(
      key: key,
      label: 'Continue with Google',
      onTap: onTap,
      isLoading: isLoading,
      leading: const _GoogleLogoEmblem(size: 19),
    );
  }

  @override
  State<LiquidAuthSecondaryButton> createState() =>
      _LiquidAuthSecondaryButtonState();
}

class _LiquidAuthSecondaryButtonState extends State<LiquidAuthSecondaryButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.isLoading || widget.onTap == null) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.isLoading || widget.onTap == null) return;
    setState(() => _isPressed = false);
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    if (widget.isLoading || widget.onTap == null) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: !widget.isLoading && widget.onTap != null,
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
          child: Container(
            height: widget.height,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _isPressed
                  ? const Color(0x9917243B) // slightly lighter on press
                  : const Color(0x66101B2E), // dark translucent glass
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color: _isPressed
                    ? const Color(0x3D7896D2)
                    : LiquidTheme.border,
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x2E000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          LiquidTheme.textSecondary,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.leading != null) ...[
                          widget.leading!,
                          const SizedBox(width: 10),
                        ],
                        Text(
                          widget.label,
                          style: LiquidTheme.buttonText(fontSize: 14.5).copyWith(
                            fontWeight: FontWeight.w500,
                            color: LiquidTheme.textPrimary,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Crisp, pixel-perfect Google "G" emblem drawn directly with CustomPainter
class _GoogleLogoEmblem extends StatelessWidget {
  final double size;

  const _GoogleLogoEmblem({this.size = 18});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double r = w / 2;
    final Offset center = Offset(r, r);

    // Official Google 4-color palette
    const Color gBlue = Color(0xFF4285F4);
    const Color gRed = Color(0xFFEA4335);
    const Color gYellow = Color(0xFFFBBC05);
    const Color gGreen = Color(0xFF34A853);

    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22
      ..strokeCap = StrokeCap.butt;

    final Rect rect = Rect.fromCircle(center: center, radius: r - (w * 0.11));

    // Blue arc (top-right down to right)
    paint.color = gBlue;
    canvas.drawArc(rect, -0.6, 1.2, false, paint);

    // Green arc (bottom-right around bottom)
    paint.color = gGreen;
    canvas.drawArc(rect, 0.6, 1.6, false, paint);

    // Yellow arc (bottom-left around left)
    paint.color = gYellow;
    canvas.drawArc(rect, 2.2, 1.4, false, paint);

    // Red arc (top-left around top)
    paint.color = gRed;
    canvas.drawArc(rect, 3.6, 1.5, false, paint);

    // Blue center horizontal crossbar
    final Paint crossbar = Paint()
      ..color = gBlue
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(r - 1.0, r - (w * 0.11), r + 1.0, w * 0.22),
      crossbar,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
