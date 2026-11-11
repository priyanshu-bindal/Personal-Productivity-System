import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/oled_theme.dart';

/// Compact brand lockup: app-icon style mark + wordmark.
class AuthLogoV2 extends StatelessWidget {
  final double size;
  const AuthLogoV2({super.key, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: OledTheme.cardElevated,
            borderRadius: BorderRadius.circular(size * 0.28),
            border: Border.all(color: OledTheme.borderHighlight, width: 0.8),
          ),
          child: CustomPaint(painter: _FocusMarkPainter()),
        ),
        const SizedBox(width: 11),
        Text(
          'FocusFlow',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: OledTheme.textPrimary,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

/// Concentric "focus" rings with a solid accent core.
class _FocusMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.065
      ..color = const Color(0xFF3A3A42);
    canvas.drawCircle(c, r * 0.30, ring);
    ring.color = OledTheme.accent.withValues(alpha: 0.55);
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r * 0.30),
      -1.9,
      2.4,
      false,
      ring..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(c, r * 0.11, Paint()..color = OledTheme.accent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
