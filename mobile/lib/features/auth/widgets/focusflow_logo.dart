import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'liquid_theme.dart';

/// FocusFlow Brand Logo Component (Dark Liquid Glass / No Cyan)
///
/// Features:
/// - Custom painted liquid 'F' glyph with blue/violet glow (NO CYAN)
/// - Supports [useAurellis] for the handwritten "FocusFlow" brand name
/// - Gradient color treatment: soft white for "Focus" → electric blue for "Flow"
/// - Subtle blue volumetric glow behind the brand name
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
        (screenWidth * 0.12).clamp(40.0, 50.0);

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

          // 2. Wordmark (Space Grotesk classic or Aurellis handwritten)
          if (showWordmark) ...[
            SizedBox(height: showGlyph ? 14 : 0),
            if (useAurellis)
              _AurellisBrandWordmark(fontSize: calculatedAurellisSize)
            else
              RichText(
                text: TextSpan(
                  style: LiquidTheme.logoTitle(
                    fontSize: wordmarkFontSize ?? (size * 0.42),
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
                        color: LiquidTheme.secondaryBlue,
                        shadows: [
                          Shadow(
                            color: Color(0x662F6BFF), // subtle blue glow, NO cyan
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
            const SizedBox(height: 5),
            Text(
              'Stay focused. Keep growing.',
              style: LiquidTheme.logoSubtitle(),
            ),
          ],
        ],
      ),
    );
  }
}

/// Brand Wordmark with subtle blue/violet ambient glow (NO CYAN)
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
          // Ambient blue glow behind wordmark
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
                  color: LiquidTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 2),
                ),
                Shadow(
                  color: LiquidTheme.violet.withValues(alpha: 0.20),
                  blurRadius: 28,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
          ),

          // Luminous White → Electric Blue Gradient
          ShaderMask(
            blendMode: BlendMode.srcIn,
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFFFFFF), // Soft pure white for "Focus"
                Color(0xFFEDF2FF), // Ice blue transition
                Color(0xFF6B93FF), // Soft blue emergence
                Color(0xFF2F6BFF), // Primary blue for "Flow"
              ],
              stops: [0.0, 0.42, 0.70, 1.0],
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

    // Volumetric blue glow
    final Paint glowPaint = Paint()
      ..color = LiquidTheme.primary.withValues(alpha: 0.28)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(Offset(width * 0.5, height * 0.5), width * 0.40, glowPaint);

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
          LiquidTheme.secondaryBlue, // #4F7CFF
          LiquidTheme.primary, // #2F6BFF
          LiquidTheme.secondaryBackground, // #0A1223
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
          LiquidTheme.primary, // #2F6BFF
          LiquidTheme.secondaryBlue, // #4F7CFF
          LiquidTheme.violet, // #7C6CFF
        ],
        stops: [0.0, 0.55, 1.0],
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
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..shader = const LinearGradient(
        colors: [
          Color(0x00FFFFFF),
          LiquidTheme.iceBlue, // #9DB8FF
          LiquidTheme.secondaryBlue, // #4F7CFF
          Color(0x004F7CFF),
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
      ).createShader(rect);

    canvas.drawPath(highlightPath, rimHighlight);

    // Inner bright glint
    final Paint glintPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    canvas.drawCircle(Offset(width * 0.66, height * 0.22), 2.0, glintPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
