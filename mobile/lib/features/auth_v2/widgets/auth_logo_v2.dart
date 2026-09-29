import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// FocusFlow Brand Header V2.
/// Features:
/// - Custom-painted fluid 'F' emblem in restrained electric blue & deep navy
/// - Space Grotesk typography: crisp white "Focus" + vibrant #2F6BFF "Flow"
/// - Elegant subtitle "Stay focused. Keep growing."
/// - Zero cyan, zero neon, zero green
class AuthLogoV2 extends StatelessWidget {
  final double glyphSize;
  final bool showSubtitle;

  const AuthLogoV2({
    super.key,
    this.glyphSize = 62.0,
    this.showSubtitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Fluid 'F' Logo Emblem
        SizedBox(
          width: glyphSize,
          height: glyphSize,
          child: CustomPaint(
            painter: _LogoGlyphPainterV2(),
          ),
        ),
        const SizedBox(height: 14),

        // Brand Wordmark in Space Grotesk (Prominent & Professional)
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: GoogleFonts.spaceGrotesk(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.8,
            ),
            children: const [
              TextSpan(
                text: 'Focus',
                style: TextStyle(
                  color: Color(0xFFF8FAFC), // crisp clean white
                ),
              ),
              TextSpan(
                text: 'Flow',
                style: TextStyle(
                  color: Color(0xFF2F6BFF), // FocusFlow primary blue
                  shadows: [
                    Shadow(
                      color: Color(0x662F6BFF), // subtle restrained blue glow
                      blurRadius: 18,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Subtitle
        if (showSubtitle) ...[
          const SizedBox(height: 5),
          Text(
            'Stay focused. Keep growing.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.0,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF8B9CB5), // readable muted blue-gray
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _LogoGlyphPainterV2 extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Ambient soft blue circular glow behind glyph
    final Paint glowPaint = Paint()
      ..color = const Color(0xFF2F6BFF).withValues(alpha: 0.22)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.40, glowPaint);

    final Rect rect = Rect.fromLTWH(0, 0, w, h);

    // Upper wave sweep
    final Path upperWave = Path();
    upperWave.moveTo(w * 0.22, h * 0.62);
    upperWave.cubicTo(
      w * 0.20, h * 0.32,
      w * 0.35, h * 0.12,
      w * 0.76, h * 0.14,
    );
    upperWave.cubicTo(
      w * 0.90, h * 0.15,
      w * 0.88, h * 0.28,
      w * 0.72, h * 0.34,
    );
    upperWave.cubicTo(
      w * 0.54, h * 0.40,
      w * 0.44, h * 0.48,
      w * 0.42, h * 0.62,
    );
    upperWave.close();

    final Paint upperPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF5B8CFF), // Lighter electric blue
          Color(0xFF2F6BFF), // Primary blue
          Color(0xFF0F1A30), // Deep navy
        ],
        stops: [0.0, 0.55, 1.0],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(upperWave, upperPaint);

    // Lower fluid wing
    final Path lowerWing = Path();
    lowerWing.moveTo(w * 0.38, h * 0.46);
    lowerWing.cubicTo(
      w * 0.56, h * 0.42,
      w * 0.78, h * 0.50,
      w * 0.80, h * 0.68,
    );
    lowerWing.cubicTo(
      w * 0.78, h * 0.82,
      w * 0.52, h * 0.88,
      w * 0.36, h * 0.76,
    );
    lowerWing.cubicTo(
      w * 0.28, h * 0.70,
      w * 0.30, h * 0.52,
      w * 0.38, h * 0.46,
    );
    lowerWing.close();

    final Paint lowerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF2F6BFF),
          Color(0xFF4376F0),
          Color(0xFF1D3570),
        ],
        stops: [0.0, 0.55, 1.0],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(lowerWing, lowerPaint);

    // Rim highlight on upper curve
    final Path highlightPath = Path();
    highlightPath.moveTo(w * 0.28, h * 0.46);
    highlightPath.cubicTo(
      w * 0.32, h * 0.26,
      w * 0.45, h * 0.16,
      w * 0.74, h * 0.16,
    );

    final Paint rimHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0x00FFFFFF),
          Color(0xFFD6E3FF),
          Color(0xFF4F83FF),
          Color(0x002F6BFF),
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(rect);

    canvas.drawPath(highlightPath, rimHighlight);

    // Inner bright glint
    final Paint glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
    canvas.drawCircle(Offset(w * 0.66, h * 0.22), 1.6, glintPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
