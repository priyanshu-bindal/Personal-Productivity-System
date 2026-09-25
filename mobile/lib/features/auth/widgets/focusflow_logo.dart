import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'liquid_theme.dart';

/// FocusFlow Brand Logo Component
///
/// Features:
/// - Custom painted liquid 'F' glyph with cyan/blue/violet glow
/// - Supports [useAurellis] for the handwritten "FocusFlow" brand name
/// - Gradient color treatment: soft white for "Focus" → luminous cyan/blue for "Flow"
/// - Subtle cyan/blue volumetric glow behind the brand name
/// - Responsive sizing without clipping
class FocusFlowLogo extends StatelessWidget {
  final double size;
  final bool showSubtitle;
  final bool showWordmark;
  final bool showGlyph;
  final bool useAurellis;
  final double? aurellisFontSize;
  final double? wordmarkFontSize;
  final FontWeight? wordmarkFontWeight;

  const FocusFlowLogo({
    super.key,
    this.size = 80.0,
    this.showSubtitle = true,
    this.showWordmark = true,
    this.showGlyph = true,
    this.useAurellis = false,
    this.aurellisFontSize,
    this.wordmarkFontSize,
    this.wordmarkFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double calculatedAurellisSize = aurellisFontSize ??
        (screenWidth * 0.12).clamp(42.0, 52.0);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
        // 1. Fluid 'F' Logo Emblem
        if (showGlyph) ...[
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _LogoPainter(),
            ),
          ),
        ],

        // 2. Wordmark (Aurellis handwritten or Inter classic)
        if (showWordmark) ...[
          SizedBox(height: showGlyph ? 16 : 0),
          if (useAurellis)
            _AurellisBrandWordmark(fontSize: calculatedAurellisSize)
          else
            RichText(
              text: TextSpan(
                style: LiquidTheme.logoTitle(
                  fontSize: wordmarkFontSize ?? (size * 0.38),
                  fontWeight: wordmarkFontWeight ?? FontWeight.w700,
                ),
                children: const [
                  TextSpan(
                    text: 'Focus',
                    style: TextStyle(color: LiquidTheme.textPrimary),
                  ),
                  TextSpan(
                    text: 'Flow',
                    style: TextStyle(
                      color: LiquidTheme.accent,
                      shadows: [
                        Shadow(
                          color: Color(0x6620D9FF),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],

        // 3. Optional Subtitle
        if (showSubtitle && showWordmark && !useAurellis) ...[
          const SizedBox(height: 6),
          Text(
            'Plan  •  Track  •  Grow',
            style: LiquidTheme.logoSubtitle(),
          ),
        ],
      ],
    ),
  );
}
}

/// Handwritten "FocusFlow" brand name rendered with the local Aurellis font
class _AurellisBrandWordmark extends StatelessWidget {
  final double fontSize;

  const _AurellisBrandWordmark({required this.fontSize});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient cyan/blue glow behind the wordmark
          Text(
            'FocusFlow',
            textAlign: TextAlign.center,
            style: GoogleFonts.spaceGrotesk(
              fontWeight: FontWeight.w700,
              fontSize: fontSize,
              letterSpacing: -0.5,
              color: Colors.transparent,
              shadows: [
                Shadow(
                  color: LiquidTheme.cyan.withValues(alpha: 0.42),
                  blurRadius: 24,
                  offset: const Offset(0, 2),
                ),
                Shadow(
                  color: LiquidTheme.primary.withValues(alpha: 0.30),
                  blurRadius: 36,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),

          // Luminous White → Cyan/Blue Gradient on the Aurellis font
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFFFFFF), // Soft pure white for "Focus"
                Color(0xFFE2F4FF), // Ice white transition
                Color(0xFF48D7FF), // Cyan emergence
                Color(0xFF20D9FF), // Luminous Cyan for "Flow"
                Color(0xFF168BFF), // Electric Blue tail
              ],
              stops: [0.0, 0.38, 0.58, 0.85, 1.0],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              'FocusFlow',
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: fontSize,
                letterSpacing: -0.5,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Volumetric glow
    final Paint glowPaint = Paint()
      ..color = LiquidTheme.primary.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(width * 0.5, height * 0.5), width * 0.42, glowPaint);

    final Rect rect = Rect.fromLTWH(0, 0, width, height);

    // Main liquid wave upper sweep
    final Path upperWave = Path();
    upperWave.moveTo(width * 0.22, height * 0.62);
    upperWave.cubicTo(
      width * 0.20, height * 0.32,
      width * 0.35, height * 0.12,
      width * 0.76, height * 0.14,
    );
    upperWave.cubicTo(
      width * 0.90, height * 0.15,
      width * 0.88, height * 0.28,
      width * 0.72, height * 0.34,
    );
    upperWave.cubicTo(
      width * 0.54, height * 0.40,
      width * 0.44, height * 0.48,
      width * 0.42, height * 0.62,
    );
    upperWave.close();

    final Paint upperPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          LiquidTheme.accent, // #20D9FF
          LiquidTheme.primary, // #168BFF
          LiquidTheme.secondaryBackground, // #06142B
        ],
        stops: [0.0, 0.55, 1.0],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(upperWave, upperPaint);

    // Lower fluid wing / droplet
    final Path lowerWing = Path();
    lowerWing.moveTo(width * 0.38, height * 0.46);
    lowerWing.cubicTo(
      width * 0.56, height * 0.42,
      width * 0.78, height * 0.50,
      width * 0.80, height * 0.68,
    );
    lowerWing.cubicTo(
      width * 0.78, height * 0.82,
      width * 0.52, height * 0.88,
      width * 0.36, height * 0.76,
    );
    lowerWing.cubicTo(
      width * 0.28, height * 0.70,
      width * 0.30, height * 0.52,
      width * 0.38, height * 0.46,
    );
    lowerWing.close();

    final Paint lowerPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          LiquidTheme.primary, // #168BFF
          LiquidTheme.accent, // #20D9FF
          LiquidTheme.secondaryAccent, // #6C5CE7 Liquid Violet
        ],
        stops: [0.0, 0.6, 1.0],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(rect)
      ..style = PaintingStyle.fill;

    canvas.drawPath(lowerWing, lowerPaint);

    // Highlight rim on upper curve
    final Path highlightPath = Path();
    highlightPath.moveTo(width * 0.28, height * 0.46);
    highlightPath.cubicTo(
      width * 0.32, height * 0.26,
      width * 0.45, height * 0.16,
      width * 0.74, height * 0.16,
    );

    final Paint rimHighlight = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0x00FFFFFF),
          LiquidTheme.highlight, // #8BE8FF
          LiquidTheme.accent, // #20D9FF
          Color(0x0020D9FF),
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(rect);

    canvas.drawPath(highlightPath, rimHighlight);

    // Inner bright glint
    final Paint glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(Offset(width * 0.66, height * 0.22), 2.2, glintPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
