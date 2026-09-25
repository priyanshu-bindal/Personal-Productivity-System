import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'widgets/liquid_theme.dart';
import 'widgets/liquid_glass_button.dart';
import 'widgets/focusflow_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fadeIn;
  late final Animation<double> _slideIn;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeIn = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideIn = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.1, 0.9, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
            child: AnimatedBuilder(
              animation: _fadeController,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeIn.value,
                  child: Transform.translate(
                    offset: Offset(0, 18 * (1 - _slideIn.value)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  // Center scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.025),

                          // Brand Logo with glowing liquid icon — Hero for shared transition
                          Hero(
                            tag: 'focusflow-brand',
                            flightShuttleBuilder: (
                              flightContext,
                              animation,
                              flightDirection,
                              fromHeroContext,
                              toHeroContext,
                            ) {
                              final Hero toHero = toHeroContext.widget as Hero;
                              return Center(
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: toHero.child,
                                ),
                              );
                            },
                            child: const FocusFlowLogo(size: 84),
                          ),

                          const SizedBox(height: 28),

                          // Hero Headline
                          Text(
                            'A Better You',
                            textAlign: TextAlign.center,
                            style: LiquidTheme.heroHeading(fontSize: 32),
                          ),
                          const SizedBox(height: 2),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                LiquidTheme.cyan,
                                LiquidTheme.electricBlue,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              'Every Day',
                              textAlign: TextAlign.center,
                              style: LiquidTheme.heroHeading(fontSize: 32),
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Subtitle
                          Text(
                            'Plan smarter, track your progress,\nand build the habits that matter.',
                            textAlign: TextAlign.center,
                            style: LiquidTheme.subtitle(fontSize: 14),
                          ),

                          const SizedBox(height: 32),

                          // 3 Liquid Glass Feature Cards (Plan, Track, Grow)
                          const _FeatureCardsRow(),

                          const SizedBox(height: 36),

                          // Primary Liquid Glass CTA
                          LiquidGlassButton(
                            label: 'Get Started',
                            icon: Icons.arrow_forward,
                            onTap: _navigateToLogin,
                          ),

                          // Generous bottom spacing without pagination dots
                          SizedBox(height: bottomPadding + 28),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}


// ─── Feature Cards Row ─────────────────────────────────────────
class _FeatureCardsRow extends StatefulWidget {
  const _FeatureCardsRow();

  @override
  State<_FeatureCardsRow> createState() => _FeatureCardsRowState();
}

class _FeatureCardsRowState extends State<_FeatureCardsRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _FeatureCard(
              index: 0,
              floatAnimation: reducedMotion ? null : _floatController,
              icon: Icons.calendar_month_rounded,
              title: 'Planner',
              subtitle: 'Plan your\nlearning days',
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _FeatureCard(
              index: 1,
              floatAnimation: reducedMotion ? null : _floatController,
              icon: LucideIcons.wallet,
              title: 'Money',
              subtitle: 'Track your\nspending',
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _FeatureCard(
              index: 2,
              floatAnimation: reducedMotion ? null : _floatController,
              icon: LucideIcons.messageCircle,
              title: 'Messages',
              subtitle: 'Stay in\nsync',
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatefulWidget {
  final int index;
  final Animation<double>? floatAnimation;
  final IconData icon;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.index,
    this.floatAnimation,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    Widget card = GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.975 : 1.0,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              // Deep 3D drop shadow
              BoxShadow(
                color: const Color(0x73000000),
                blurRadius: _isPressed ? 12 : 20,
                offset: Offset(0, _isPressed ? 4 : 8),
              ),
              // Soft volumetric cyan/blue edge glow
              BoxShadow(
                color: LiquidTheme.primary.withValues(alpha: _isPressed ? 0.08 : 0.16),
                blurRadius: _isPressed ? 12 : 18,
                spreadRadius: -2,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: LiquidTheme.cyan.withValues(alpha: _isPressed ? 0.05 : 0.12),
                blurRadius: _isPressed ? 8 : 12,
                spreadRadius: -4,
                offset: const Offset(0, 1),
              ),
            ],
            // 3D Luminous Liquid Glass rim
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                LiquidTheme.cyan.withValues(alpha: _isPressed ? 0.65 : 0.50),
                LiquidTheme.iceBlue.withValues(alpha: 0.28),
                LiquidTheme.violet.withValues(alpha: 0.18),
                LiquidTheme.primary.withValues(alpha: 0.32),
              ],
              stops: const [0.0, 0.35, 0.70, 1.0],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(1.2), // 1.2px luminous rim
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20.8),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Stack(
                  children: [
                    // Layer 1: Translucent navy glass background
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xB306142B), // ~70% #06142B
                              Color(0xCC030E24), // ~80% deep navy
                              Color(0xE6020818), // ~90% dark midnight navy at bottom
                            ],
                            stops: [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Layer 2: Subtle radial cyan-blue glow near upper area
                    Positioned(
                      top: -16,
                      left: 0,
                      right: 0,
                      height: 75,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              LiquidTheme.cyan.withValues(alpha: 0.20),
                              LiquidTheme.primary.withValues(alpha: 0.08),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.50, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Layer 3 & 4: Top-left highlight & curved diagonal glass reflection
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GlassReflectionPainter(isPressed: _isPressed),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16.0,
                        horizontal: 6.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Floating 3D glass icon container
                          _FloatingGlassIcon(icon: widget.icon),
                          const SizedBox(height: 10),
                          // Title: Space Grotesk Bold
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: LiquidTheme.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Subtitle: Space Grotesk
                          Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w400,
                              color: LiquidTheme.textSecondary,
                              height: 1.32,
                            ),
                          ),
                        ],
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

    if (widget.floatAnimation != null) {
      return AnimatedBuilder(
        animation: widget.floatAnimation!,
        builder: (context, child) {
          // Different phase offset for each card for organic floating
          final double t = (widget.floatAnimation!.value + (widget.index * 0.33)) * 2 * math.pi;
          final double floatY = math.sin(t) * 2.2;
          return Transform.translate(
            offset: Offset(0, floatY),
            child: child,
          );
        },
        child: card,
      );
    }

    return card;
  }
}

class _FloatingGlassIcon extends StatelessWidget {
  final IconData icon;

  const _FloatingGlassIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(13),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0x3820D9FF), // cyan glass highlight
            Color(0x24168BFF), // electric blue glass
            Color(0x4406142B), // dark navy depth
          ],
          stops: [0.0, 0.45, 1.0],
        ),
        border: Border.all(
          color: LiquidTheme.cyan.withValues(alpha: 0.38),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: LiquidTheme.cyan.withValues(alpha: 0.28),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
          const BoxShadow(
            color: Color(0x66000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Upper-left specular glint
          Positioned(
            top: 3,
            left: 4,
            child: Container(
              width: 14,
              height: 5,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.45),
                    Colors.white.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Icon(
            icon,
            size: 22,
            color: LiquidTheme.cyan,
            shadows: [
              Shadow(
                color: LiquidTheme.cyan.withValues(alpha: 0.65),
                blurRadius: 8,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GlassReflectionPainter extends CustomPainter {
  final bool isPressed;

  _GlassReflectionPainter({this.isPressed = false});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Subtle top-left crescent highlight
    final Path highlightPath = Path();
    highlightPath.moveTo(6, h * 0.42);
    highlightPath.cubicTo(6, 10, 10, 6, w * 0.58, 6);

    final Paint highlightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..shader = LinearGradient(
        begin: Alignment.bottomLeft,
        end: Alignment.topRight,
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: isPressed ? 0.50 : 0.35),
          LiquidTheme.cyan.withValues(alpha: isPressed ? 0.30 : 0.20),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 0.75, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(highlightPath, highlightPaint);

    // 2. Diagonal curved soft glass reflection sheen
    final Path sheenPath = Path();
    sheenPath.moveTo(0, h * 0.12);
    sheenPath.cubicTo(w * 0.30, h * 0.16, w * 0.65, h * 0.40, w, h * 0.44);
    sheenPath.lineTo(w, h * 0.22);
    sheenPath.cubicTo(w * 0.60, h * 0.16, w * 0.25, 0, 0, 0);
    sheenPath.close();

    final Paint sheenPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.08),
          LiquidTheme.cyan.withValues(alpha: 0.04),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    canvas.drawPath(sheenPath, sheenPaint);
  }

  @override
  bool shouldRepaint(covariant _GlassReflectionPainter oldDelegate) =>
      oldDelegate.isPressed != isPressed;
}
