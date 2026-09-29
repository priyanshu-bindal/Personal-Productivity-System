import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Translucent Liquid Glass Secondary Button V2.
/// Primarily used for third-party authentication like "Continue with Google".
/// Features:
/// - 52px height & 14px border radius
/// - Translucent deep navy surface
/// - Subtle blue-gray glass border
/// - Micro-scale press response (1.0 → 0.98 → 1.0, 120ms easeOutCubic)
class LiquidGlassSecondaryButtonV2 extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;
  final bool isLoading;

  const LiquidGlassSecondaryButtonV2({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.isLoading = false,
  });

  /// Convenient factory constructor for the standard "Continue with Google" action
  factory LiquidGlassSecondaryButtonV2.google({
    Key? key,
    required VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return LiquidGlassSecondaryButtonV2(
      key: key,
      label: 'Continue with Google',
      onTap: onTap,
      isLoading: isLoading,
      icon: const _GoogleIcon(),
    );
  }

  @override
  State<LiquidGlassSecondaryButtonV2> createState() =>
      _LiquidGlassSecondaryButtonV2State();
}

class _LiquidGlassSecondaryButtonV2State
    extends State<LiquidGlassSecondaryButtonV2> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.isLoading || widget.onTap == null) return;
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
    final scale = _isPressed ? 0.98 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onTap: widget.isLoading ? null : widget.onTap,
        child: Container(
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFF0C1424).withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: const Color(0xFF1D2B44),
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x35000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF94A3B8)),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            widget.icon!,
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.label,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 14.0,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFE2E8F0),
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Custom-painted vector Google 'G' icon
class _GoogleIcon extends StatelessWidget {
  const _GoogleIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
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
    final double h = size.height;

    // Draw Google 4-color 'G'
    final Paint redPaint = Paint()..color = const Color(0xFFEA4335);
    final Paint bluePaint = Paint()..color = const Color(0xFF4285F4);
    final Paint yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final Paint greenPaint = Paint()..color = const Color(0xFF34A853);

    final Rect rect = Rect.fromLTWH(0, 0, w, h);
    const double strokeWidth = 3.4;

    // Red top arc
    final Paint arcPaintRed = Paint()
      ..color = redPaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect.deflate(strokeWidth / 2), 3.14 * 1.15, 3.14 * 0.70, false, arcPaintRed);

    // Yellow left arc
    final Paint arcPaintYellow = Paint()
      ..color = yellowPaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect.deflate(strokeWidth / 2), 3.14 * 0.75, 3.14 * 0.40, false, arcPaintYellow);

    // Green bottom arc
    final Paint arcPaintGreen = Paint()
      ..color = greenPaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect.deflate(strokeWidth / 2), 3.14 * 0.15, 3.14 * 0.60, false, arcPaintGreen);

    // Blue right arm & horizontal bar
    final Paint arcPaintBlue = Paint()
      ..color = bluePaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect.deflate(strokeWidth / 2), -3.14 * 0.20, 3.14 * 0.35, false, arcPaintBlue);

    // Horizontal bar
    final Paint barPaint = Paint()
      ..color = bluePaint.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.48, h * 0.50),
      Offset(w * 0.92, h * 0.50),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
