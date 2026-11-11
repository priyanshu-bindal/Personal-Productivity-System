import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/oled_theme.dart';

/// iOS large-title style heading used at the top of each auth form.
class AuthHeadingV2 extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? leading;

  const AuthHeadingV2({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading!, const SizedBox(height: 18)],
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: OledTheme.textPrimary,
            letterSpacing: -0.9,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: OledTheme.textSecondary,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

/// Small rounded icon tile used by the reset-password flow.
class AuthIconTileV2 extends StatelessWidget {
  final IconData icon;
  final Color color;
  const AuthIconTileV2({super.key, required this.icon, this.color = OledTheme.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Icon(icon, size: 22, color: color),
    );
  }
}
