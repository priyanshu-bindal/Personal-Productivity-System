import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'liquid_theme.dart';

/// FocusFlow Reusable Liquid Glass Primary Button
///
/// Exactly matches the visual language of the reference image:
/// - Pill-shaped horizontal button (height 58–64px, pill radius)
/// - Deep navy translucent glass base
/// - Luminous animated cyan/blue outer rim with violet accent
/// - Flowing liquid wave shape inside (organic cyan → electric blue → subtle violet)
/// - Top-left inner specular crescent reflection
/// - Soft outer cyan/blue breathing glow
/// - Embedded circular glass arrow bubble on the right with:
///   - Spherical lens specular reflection
///   - Luminous cyan/blue outer rim
///   - Custom rounded right arrow with soft glow
///   - Gentle floating/breathing animation (1.0 → 1.035)
///   - Smooth loading transition
/// - Responsive, 60fps performance isolated with RepaintBoundary
/// - Scaled press interaction (0.97) with light haptic feedback
class LiquidGlassPrimaryButton extends StatefulWidget {
  final String? label;
  final String? text;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool showArrow;
  final bool isLoading;
  final bool enabled;
  final double? width;
  final double height;
  final double borderRadius;

  const LiquidGlassPrimaryButton({
    super.key,
    this.label,
    this.text,
    this.onTap,
    this.onPressed,
    this.icon,
    this.showArrow = true,
    this.isLoading = false,
    this.enabled = true,
    this.width,
    this.height = 60.0,
    this.borderRadius = 30.0,
  }) : assert(
          label != null || text != null,
          'Either label or text must be provided',
        );

  @override
  State<LiquidGlassPrimaryButton> createState() =>
      _LiquidGlassPrimaryButtonState();
}

/// Backward compatibility alias so existing screens work without changes
typedef LiquidGlassButton = LiquidGlassPrimaryButton;

class _LiquidGlassPrimaryButtonState extends State<LiquidGlassPrimaryButton>
    with TickerProviderStateMixin {
  // Controller 1: Drives ambient liquid waves, rim shimmer, and light sweep (4.5s seamless loop)
  late final AnimationController _liquidController;

  // Controller 2: Drives the subtle arrow bubble breathing & arrow nudge (2.0s loop)
  late final AnimationController _bubbleController;
  late final Animation<double> _bubbleScaleAnim;
  late final Animation<double> _arrowNudgeAnim;

  bool _isPressed = false;

  String get _buttonText => widget.label ?? widget.text ?? '';
  VoidCallback? get _callback => widget.enabled ? (widget.onTap ?? widget.onPressed) : null;
  bool get _isInteractive => _callback != null && !widget.isLoading && widget.enabled;

  @override
  void initState() {
    super.initState();

    // 4.5s smooth loop for liquid flow and surface light sweep
    _liquidController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4500),
    )..repeat();

    // 2.0s breathing animation for arrow bubble
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _bubbleScaleAnim = Tween<double>(begin: 1.0, end: 1.035).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeInOut),
    );

    _arrowNudgeAnim = Tween<double>(begin: 0.0, end: 1.5).animate(
      CurvedAnimation(parent: _bubbleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _liquidController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (!_isInteractive) return;
    HapticFeedback.lightImpact();
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (!_isInteractive) return;
    setState(() => _isPressed = false);
    _callback?.call();
  }

  void _handleTapCancel() {
    if (!_isInteractive) return;
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final double radius = widget.borderRadius;
    final double btnHeight = widget.height;
    final bool hasBubble = widget.showArrow || widget.icon != null;

    return Semantics(
      button: true,
      enabled: _isInteractive,
      label: _buttonText,
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : 1.0,
          duration: const Duration(milliseconds: 130),
          curve: Curves.easeOutCubic,
          child: Opacity(
            opacity: widget.enabled ? 1.0 : 0.55,
            child: AnimatedBuilder(
              animation: _liquidController,
              builder: (context, staticChild) {
                // Subtle breathing glow (alpha 0.32 → 0.46)
                final double glowPhase = math.sin(_liquidController.value * 2 * math.pi);
                final double glowAlpha = _isPressed ? 0.22 : (0.34 + 0.12 * glowPhase);

                return Container(
                  width: widget.width ?? double.infinity,
                  height: btnHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      // Soft cyan/electric blue outer glow halo
                      BoxShadow(
                        color: LiquidTheme.primary.withValues(alpha: glowAlpha),
                        blurRadius: _isPressed ? 18 : 30,
                        spreadRadius: _isPressed ? 0 : 2,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: LiquidTheme.cyan.withValues(alpha: glowAlpha * 0.65),
                        blurRadius: _isPressed ? 10 : 16,
                        spreadRadius: -2,
                        offset: const Offset(0, 0),
                      ),
                      // Depth shadow underneath
                      const BoxShadow(
                        color: Color(0x66000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: staticChild,
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: Stack(
                  children: [
                    // ── Layer 1: Dark Navy Translucent Glass Base ───
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF030D1E), // Deep midnight navy
                              Color(0xFF061530), // Royal navy depth
                              Color(0xFF030A18), // Dark midnight
                            ],
                            stops: [0.0, 0.5, 1.0],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),

                    // ── Layer 2: Animated Liquid Waves & Light Sweep ─
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _liquidController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _LiquidGlassWavePainter(
                                progress: _liquidController.value,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // ── Layer 3: Luminous Outer Rim (Cyan/Blue/Violet)
                    Positioned.fill(
                      child: RepaintBoundary(
                        child: AnimatedBuilder(
                          animation: _liquidController,
                          builder: (context, _) {
                            return CustomPaint(
                              painter: _LiquidRimPainter(
                                radius: radius,
                                progress: _liquidController.value,
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                    // ── Layer 4: Interactive Content (Label & Arrow) ─
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(
                          children: [
                            // Left spacer to optically balance the text when arrow bubble is present
                            if (hasBubble)
                              const SizedBox(width: 48)
                            else
                              const SizedBox(width: 16),

                            // Centered button label
                            Expanded(
                              child: Text(
                                _buttonText,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: LiquidTheme.buttonText(fontSize: 16.5).copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: LiquidTheme.textPrimary,
                                  letterSpacing: 0.25,
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x99000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 1.5),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Embedded Circular Glass Arrow Bubble on the right
                            if (hasBubble)
                              AnimatedBuilder(
                                animation: _bubbleScaleAnim,
                                builder: (context, _) {
                                  final double currentScale =
                                      _isPressed ? 0.95 : _bubbleScaleAnim.value;
                                  return Transform.scale(
                                    scale: currentScale,
                                    child: _EmbeddedGlassBubble(
                                      btnHeight: btnHeight,
                                      icon: widget.icon,
                                      isLoading: widget.isLoading,
                                      arrowNudge: _arrowNudgeAnim.value,
                                    ),
                                  );
                                },
                              )
                            else
                              const SizedBox(width: 16),
                          ],
                        ),
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

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: LIQUID WAVE & SURFACE LIGHT SWEEP
// ─────────────────────────────────────────────────────────────────────────────
class _LiquidGlassWavePainter extends CustomPainter {
  final double progress; // 0.0 → 1.0

  _LiquidGlassWavePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double t = progress * 2 * math.pi;

    // ── 1. Left Bulb Glowing Liquid Volume ──────────────────────────────────
    // The reference image features a prominent, glowing cyan-blue bulb of liquid
    // anchored in the left curve of the pill.
    final Path leftBulbPath = Path();
    final double bulbW = w * 0.44;
    final double waveWave = math.sin(t) * 3.5;

    leftBulbPath.moveTo(0, h * 0.15);
    leftBulbPath.cubicTo(
      w * 0.08,
      h * 0.05 + waveWave,
      w * 0.22,
      h * 0.22 - waveWave * 0.5,
      bulbW,
      h * 0.72 + waveWave,
    );
    leftBulbPath.lineTo(w * 0.15, h);
    leftBulbPath.lineTo(0, h);
    leftBulbPath.close();

    final Paint leftBulbPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.85, -0.2),
        radius: 1.15,
        colors: const [
          Color(0xB220D9FF), // Bright glowing Cyan #20D9FF (~70%)
          Color(0x8C168BFF), // Electric Blue #168BFF (~55%)
          Color(0x3306142B), // Deep Dark Blue fade
          Color(0x0006142B),
        ],
        stops: const [0.0, 0.42, 0.80, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, bulbW * 1.2, h));

    canvas.drawPath(leftBulbPath, leftBulbPaint);

    // ── 2. Flowing S-Curve Liquid Ribbon (Sweeps Across Button) ──────────────
    // Liquid ribbon flows across the bottom-center and sweeps beneath the bubble.
    final Path ribbonPath = Path();
    final double waveY1 = math.sin(t) * 2.8;
    final double waveY2 = math.cos(t * 0.9) * 2.5;

    ribbonPath.moveTo(0, h * 0.52);
    ribbonPath.cubicTo(
      w * 0.25,
      h * 0.35 + waveY1,
      w * 0.45,
      h * 0.78 + waveY2,
      w * 0.72,
      h * 0.70 + waveY1 * 0.5,
    );
    ribbonPath.cubicTo(
      w * 0.85,
      h * 0.65 - waveY2 * 0.5,
      w * 0.94,
      h * 0.40,
      w,
      h * 0.55,
    );
    ribbonPath.lineTo(w, h);
    ribbonPath.lineTo(0, h);
    ribbonPath.close();

    final Paint ribbonPaint = Paint()
      ..shader = LinearGradient(
        colors: const [
          Color(0x99168BFF), // Electric Blue
          Color(0x6620D9FF), // Cyan crest
          Color(0x33168BFF), // Semi-dark center
          Color(0x886C5CE7), // Liquid Violet reflection under bubble!
          Color(0x5520D9FF), // Cyan edge
        ],
        stops: const [0.0, 0.25, 0.55, 0.84, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(ribbonPath, ribbonPaint);

    // ── 3. Glowing Luminous Wave Crest (Meniscus Surface Line) ──────────────
    // The crisp, bright meniscus line that gives the liquid glass 3D definition.
    final Path crestPath = Path();
    crestPath.moveTo(0, h * 0.52);
    crestPath.cubicTo(
      w * 0.25,
      h * 0.35 + waveY1,
      w * 0.45,
      h * 0.78 + waveY2,
      w * 0.72,
      h * 0.70 + waveY1 * 0.5,
    );
    crestPath.cubicTo(
      w * 0.85,
      h * 0.65 - waveY2 * 0.5,
      w * 0.94,
      h * 0.40,
      w,
      h * 0.55,
    );

    // Soft cyan bloom along crest
    final Paint crestGlowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
      ..shader = LinearGradient(
        colors: const [
          Color(0xAA20D9FF),
          Color(0xEE8BE8FF),
          Color(0x88168BFF),
          Color(0x996C5CE7),
          Color(0x006C5CE7),
        ],
        stops: const [0.0, 0.30, 0.65, 0.90, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(crestPath, crestGlowPaint);

    // Crisp white/cyan core crest stroke
    final Paint crestCorePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = LinearGradient(
        colors: const [
          Color(0xCCFFFFFF),
          Color(0xFF8BE8FF),
          Color(0x8820D9FF),
          Color(0xAA6C5CE7),
          Color(0x006C5CE7),
        ],
        stops: const [0.0, 0.28, 0.60, 0.88, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(crestPath, crestCorePaint);

    // ── 4. Upper-Left Glass Specular Crescent ──────────────────────────────
    // Highlight along the inner curve of the top-left pill cap
    final Path specularPath = Path();
    specularPath.moveTo(w * 0.04, h * 0.50);
    specularPath.cubicTo(
      w * 0.05,
      h * 0.12,
      w * 0.14,
      h * 0.08,
      w * 0.32,
      h * 0.08,
    );

    final Paint specularPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2)
      ..shader = const LinearGradient(
        colors: [
          Color(0x00FFFFFF),
          Color(0xE6FFFFFF), // Crisp specular white
          Color(0x8020D9FF), // Soft cyan tail
          Color(0x0020D9FF),
        ],
        stops: [0.0, 0.35, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w * 0.35, h * 0.5));

    canvas.drawPath(specularPath, specularPaint);

    // ── 5. Glossy Light Sweep Across Surface ────────────────────────────────
    // Subtle sheen of light traveling across curved glass
    final double sweepX = -w * 0.4 + (w * 1.8) * progress;
    final Rect sweepRect = Rect.fromLTWH(sweepX, 0, w * 0.35, h);

    final Paint sweepPaint = Paint()
      ..shader = LinearGradient(
        colors: const [
          Color(0x00FFFFFF),
          Color(0x18FFFFFF), // Very subtle soft sheen (~10%)
          Color(0x288BE8FF), // Ice blue tint (~16%)
          Color(0x00FFFFFF),
        ],
        stops: const [0.0, 0.40, 0.60, 1.0],
        transform: const GradientRotation(math.pi / 6), // 30 degrees angle
      ).createShader(sweepRect);

    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(sweepRect, sweepPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _LiquidGlassWavePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: LUMINOUS OUTER RIM WITH ANIMATED HIGHLIGHTS
// ─────────────────────────────────────────────────────────────────────────────
class _LiquidRimPainter extends CustomPainter {
  final double radius;
  final double progress;

  _LiquidRimPainter({required this.radius, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0.7, 0.7, size.width - 1.4, size.height - 1.4),
      Radius.circular(radius - 0.7),
    );

    // Animated phase offset for dynamic rim highlight
    final double phase = progress * 2 * math.pi;
    final double cyanPulse = 0.5 + 0.5 * math.sin(phase);

    // Outer luminous border gradient matching the reference:
    // - Top: bright cyan → ice blue
    // - Bottom-left: electric blue
    // - Bottom-right (under arrow): glowing violet & cyan reflection
    final Paint borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..shader = SweepGradient(
        center: Alignment.center,
        colors: [
          Color.lerp(LiquidTheme.cyan, LiquidTheme.iceBlue, cyanPulse)!, // Top-left cyan
          LiquidTheme.primary,                                           // Electric Blue
          LiquidTheme.violet,                                            // Liquid Violet under bubble
          LiquidTheme.cyan,                                              // Bright bottom-right rim
          LiquidTheme.primary,
          LiquidTheme.cyan,
        ],
        stops: const [0.0, 0.28, 0.58, 0.78, 0.92, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rrect.outerRect);

    canvas.drawRRect(rrect, borderPaint);

    // Subtle top-edge 1.0px specular sheen
    final Path topSheen = Path();
    topSheen.moveTo(size.width * 0.12, 1.2);
    topSheen.lineTo(size.width * 0.88, 1.2);

    final Paint topSheenPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..shader = const LinearGradient(
        colors: [
          Color(0x00FFFFFF),
          Color(0x77FFFFFF),
          Color(0x448BE8FF),
          Color(0x00FFFFFF),
        ],
        stops: [0.0, 0.35, 0.70, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 2));

    canvas.drawPath(topSheen, topSheenPaint);
  }

  @override
  bool shouldRepaint(covariant _LiquidRimPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// EMBEDDED CIRCULAR GLASS ARROW BUBBLE
// ─────────────────────────────────────────────────────────────────────────────
class _EmbeddedGlassBubble extends StatelessWidget {
  final double btnHeight;
  final IconData? icon;
  final bool isLoading;
  final double arrowNudge;

  const _EmbeddedGlassBubble({
    required this.btnHeight,
    this.icon,
    required this.isLoading,
    required this.arrowNudge,
  });

  @override
  Widget build(BuildContext context) {
    // Bubble diameter proportional to button height (~44px inside 60px)
    final double diameter = math.min(46.0, btnHeight - 14.0);

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Soft outer radial glow around the circular bubble
        boxShadow: [
          BoxShadow(
            color: LiquidTheme.cyan.withValues(alpha: 0.38),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
          BoxShadow(
            color: LiquidTheme.primary.withValues(alpha: 0.28),
            blurRadius: 18,
            spreadRadius: 2,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glass bubble body & outer rim
          CustomPaint(
            size: Size(diameter, diameter),
            painter: _GlassBubblePainter(),
          ),

          // Loading state or Arrow icon
          if (isLoading)
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(LiquidTheme.cyan),
              ),
            )
          else if (icon != null)
            Transform.translate(
              offset: Offset(arrowNudge * 0.5, 0),
              child: Icon(
                icon,
                size: 20,
                color: LiquidTheme.textPrimary,
                shadows: [
                  Shadow(
                    color: LiquidTheme.cyan.withValues(alpha: 0.65),
                    blurRadius: 8,
                  ),
                ],
              ),
            )
          else
            // Custom rounded right arrow matching the reference image exactly
            Transform.translate(
              offset: Offset(arrowNudge, 0),
              child: CustomPaint(
                size: const Size(20, 16),
                painter: _GlowingRoundedArrowPainter(),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: GLASS BUBBLE (LENS REFLECTION & LUMINOUS RIM)
// ─────────────────────────────────────────────────────────────────────────────
class _GlassBubblePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double r = size.width / 2;
    final Offset center = Offset(r, r);

    // 1. Semi-transparent dark blue glass fill
    final Paint fillPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.3),
        radius: 0.95,
        colors: const [
          Color(0x40168BFF), // Translucent cyan-blue
          Color(0x220A234A), // Dark blue glass interior
          Color(0x55030E22), // Rim depth
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawCircle(center, r - 0.8, fillPaint);

    // 2. Luminous cyan/blue outer rim stroke
    final Paint rimPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..shader = const SweepGradient(
        colors: [
          Color(0xFFFFFFFF), // Specular highlight at top-left
          Color(0xFF20D9FF), // Bright Cyan
          Color(0xFF168BFF), // Electric Blue
          Color(0xFF8BE8FF), // Ice blue
          Color(0xFF20D9FF),
          Color(0xFFFFFFFF),
        ],
        stops: [0.0, 0.25, 0.55, 0.80, 0.95, 1.0],
        transform: GradientRotation(-math.pi * 0.75),
      ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawCircle(center, r - 0.7, rimPaint);

    // 3. Spherical Glass Lens Highlight (Upper Crescent Reflection)
    final Rect lensRect = Rect.fromCenter(
      center: Offset(r, r * 0.62),
      width: r * 1.4,
      height: r * 0.85,
    );

    final Paint lensPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.6),
        radius: 0.8,
        colors: const [
          Color(0x80FFFFFF), // Bright specular center
          Color(0x338BE8FF),
          Color(0x00FFFFFF),
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(lensRect);

    canvas.save();
    canvas.clipPath(Path()..addOval(Rect.fromCircle(center: center, radius: r - 1.5)));
    canvas.drawOval(lensRect, lensPaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GlassBubblePainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CUSTOM PAINTER: GLOWING ROUNDED RIGHT ARROW (─►)
// ─────────────────────────────────────────────────────────────────────────────
class _GlowingRoundedArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double cy = h / 2;

    // Arrow geometry: horizontal stem with rounded chevron head
    final Path arrowPath = Path();

    // Stem: (w * 0.15, cy) to (w * 0.82, cy)
    arrowPath.moveTo(w * 0.15, cy);
    arrowPath.lineTo(w * 0.82, cy);

    // Upper chevron arm
    arrowPath.moveTo(w * 0.52, cy - h * 0.38);
    arrowPath.lineTo(w * 0.85, cy);

    // Lower chevron arm
    arrowPath.lineTo(w * 0.52, cy + h * 0.38);

    // 1. Soft Cyan Glow underneath arrow
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5)
      ..color = LiquidTheme.cyan.withValues(alpha: 0.85);

    canvas.drawPath(arrowPath, glowPaint);

    // 2. Pure White Core Arrow Stroke
    final Paint corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = const Color(0xFFFFFFFF);

    canvas.drawPath(arrowPath, corePaint);
  }

  @override
  bool shouldRepaint(covariant _GlowingRoundedArrowPainter oldDelegate) => false;
}
