import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/oled_theme.dart';

/// Premium animated success overlay dialog for FocusFlow.
///
/// Features:
/// - Compact, centered modal surface on true OLED-black background (#0B1018 surface)
/// - Custom-painted checkmark inside a circular stroke container with smooth drawing animation
/// - Delicate scale-up and fade-in entry with emerald/cyan glow effect
/// - Typography: "Cache Cleared Successfully" with subtitle "Your app is refreshed and ready."
/// - Duration ~600ms entrance animation, pauses, then smoothly fades out and dismisses
/// - Subtle haptic feedback on success
/// - Respects reduced-motion accessibility settings
class PremiumSuccessOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final Duration autoDismissDelay;
  final VoidCallback? onDismissed;

  const PremiumSuccessOverlay({
    super.key,
    this.title = 'Cache Cleared Successfully',
    this.subtitle = 'Your app is refreshed and ready.',
    this.autoDismissDelay = const Duration(milliseconds: 1800),
    this.onDismissed,
  });

  /// Static helper to show the overlay using a modal route.
  /// Prevents stacking duplicate overlays via an active flag.
  static bool _isShowing = false;

  static Future<void> show({
    required BuildContext context,
    String title = 'Cache Cleared Successfully',
    String subtitle = 'Your app is refreshed and ready.',
    Duration autoDismissDelay = const Duration(milliseconds: 1800),
  }) async {
    if (_isShowing) return;
    _isShowing = true;

    try {
      await showGeneralDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Success',
        barrierColor: Colors.black.withValues(alpha: 0.65),
        transitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (dialogContext, animation, secondaryAnimation) {
          return PremiumSuccessOverlay(
            title: title,
            subtitle: subtitle,
            autoDismissDelay: autoDismissDelay,
          );
        },
        transitionBuilder: (context, animation, secondaryAnimation, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curve,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1.0).animate(curve),
              child: child,
            ),
          );
        },
      );
    } finally {
      _isShowing = false;
    }
  }

  @override
  State<PremiumSuccessOverlay> createState() => _PremiumSuccessOverlayState();
}

class _PremiumSuccessOverlayState extends State<PremiumSuccessOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Staged entrance animations
  late final Animation<double> _cardScale;
  late final Animation<double> _cardOpacity;
  late final Animation<double> _circleProgress;
  late final Animation<double> _checkProgress;
  late final Animation<double> _glowOpacity;
  late final Animation<double> _textOpacity;
  late final Animation<Offset> _textSlide;

  Timer? _dismissTimer;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();

    // 650 ms total entrance sequence
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // Card scale 0.88 -> 1.0
    _cardScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
      ),
    );

    // Card fade in
    _cardOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    // Circle stroke draws (0.15 -> 0.60)
    _circleProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
      ),
    );

    // Checkmark draws (0.45 -> 0.90)
    _checkProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.95, curve: Curves.easeOutCubic),
      ),
    );

    // Emerald/Cyan glow breath (0.40 -> 1.0)
    _glowOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.85, curve: Curves.easeOut),
      ),
    );

    // Text fade in (0.35 -> 0.85)
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
      ),
    );

    // Text subtle slide up
    _textSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.20),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // Trigger subtle haptic feedback
    HapticFeedback.lightImpact();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion) {
      _controller.value = 1.0;
    } else if (!_controller.isAnimating && !_controller.isCompleted) {
      _controller.forward();
    }

    _scheduleDismissal();
  }

  void _scheduleDismissal() {
    _dismissTimer?.cancel();
    _dismissTimer = Timer(widget.autoDismissDelay, _handleDismiss);
  }

  void _handleDismiss() {
    if (_dismissed || !mounted) return;
    _dismissed = true;
    final nav = Navigator.maybeOf(context, rootNavigator: true);
    if (nav != null && nav.canPop()) {
      nav.pop();
    }
    widget.onDismissed?.call();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const emeraldAccent = OledTheme.emerald;
    const cardBg = OledTheme.cardElevated;
    const cardBorder = OledTheme.border;

    return PopScope(
      canPop: _dismissed, // Disallow dismissing early by back gesture to keep animation pristine
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _cardOpacity.value,
                child: Transform.scale(
                  scale: _cardScale.value,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 340),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 28,
                    ),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: cardBorder, width: 1.2),
                      boxShadow: [
                        // Ambient black shadow
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.65),
                          blurRadius: 36,
                          offset: const Offset(0, 14),
                        ),
                        // Gentle emerald/cyan glow
                        BoxShadow(
                          color: Colors.transparent,
                          blurRadius: 32,
                          spreadRadius: 2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Animated Success Circle with Checkmark
                        SizedBox(
                          width: 68,
                          height: 68,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Pulsing soft glow background circle
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: emeraldAccent.withValues(
                                    alpha: 0.12 * _glowOpacity.value,
                                  ),
                                ),
                              ),
                              // Drawn circular border + drawn checkmark
                              CustomPaint(
                                size: const Size(64, 64),
                                painter: _CircleAndCheckPainter(
                                  circleProgress: _circleProgress.value,
                                  checkProgress: _checkProgress.value,
                                  strokeColor: emeraldAccent,
                                  trackColor: cardBorder,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Title: Cache Cleared Successfully
                        FadeTransition(
                          opacity: _textOpacity,
                          child: SlideTransition(
                            position: _textSlide,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.w700,
                                    color: OledTheme.textPrimary,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Subtitle: Your app is refreshed and ready.
                                Text(
                                  widget.subtitle,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w400,
                                    color: OledTheme.textSecondary,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws both the circular boundary ring and the checkmark stroke.
class _CircleAndCheckPainter extends CustomPainter {
  final double circleProgress;
  final double checkProgress;
  final Color strokeColor;
  final Color trackColor;

  const _CircleAndCheckPainter({
    required this.circleProgress,
    required this.checkProgress,
    required this.strokeColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3.0;

    // 1. Draw subtle background track circle
    final trackPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4;
    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw animated outer circle stroke from top (-pi / 2)
    if (circleProgress > 0.0) {
      final circlePaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * math.pi * circleProgress;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        sweepAngle,
        false,
        circlePaint,
      );
    }

    // 3. Draw animated checkmark stroke
    if (checkProgress > 0.0) {
      final checkPaint = Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final start = Offset(size.width * 0.30, size.height * 0.50);
      final pivot = Offset(size.width * 0.45, size.height * 0.65);
      final end = Offset(size.width * 0.72, size.height * 0.36);

      final leg1Length = (pivot - start).distance;
      final leg2Length = (end - pivot).distance;
      final totalLength = leg1Length + leg2Length;
      final currentDistance = totalLength * checkProgress;

      final path = Path()..moveTo(start.dx, start.dy);

      if (currentDistance <= leg1Length) {
        final legProgress = currentDistance / leg1Length;
        final currentPivot = Offset.lerp(start, pivot, legProgress)!;
        path.lineTo(currentPivot.dx, currentPivot.dy);
      } else {
        path.lineTo(pivot.dx, pivot.dy);
        final leg2Progress = (currentDistance - leg1Length) / leg2Length;
        final currentEnd = Offset.lerp(pivot, end, leg2Progress)!;
        path.lineTo(currentEnd.dx, currentEnd.dy);
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CircleAndCheckPainter oldDelegate) {
    return oldDelegate.circleProgress != circleProgress ||
        oldDelegate.checkProgress != checkProgress ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.trackColor != trackColor;
  }
}
