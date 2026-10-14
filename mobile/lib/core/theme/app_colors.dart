import 'package:flutter/material.dart';
import 'oled_theme.dart';

class AppColors {
  // ── True OLED Black & Surfaces ────────────────────────────────────────────
  static const Color background = OledTheme.bg;
  static const Color backgroundGradientTop = OledTheme.bgSecondary;
  static const Color backgroundGradientBottom = OledTheme.bg;

  static const Color surface = OledTheme.subtleSurface;
  static const Color surfaceElevated = OledTheme.cardElevated;
  static const Color card = OledTheme.card;
  static const Color cardHi = OledTheme.cardElevated;
  static const Color cardElevated = OledTheme.cardElevated;
  static const Color cardHover = OledTheme.subtleSurface;

  static const Color border = OledTheme.border;
  static const Color borderActive = OledTheme.electricBlue;
  static const Color borderSubtle = OledTheme.borderSubtle;
  static const Color input = OledTheme.card;

  static const Color textPrimary = OledTheme.textPrimary;
  static const Color textSecondary = OledTheme.textSecondary;
  static const Color textDim = OledTheme.textSecondary;
  static const Color textMuted = OledTheme.textMuted;
  static const Color textFaint = OledTheme.textMuted;

  // ─── Liquid Glass Design System Tokens ─────────────────────────
  static const Color liquidBackground = Color(0xFF020817); // #020817 Deep Midnight Navy
  static const Color liquidSecondaryBg = Color(0xFF06142B); // #06142B Dark Blue
  static const Color liquidPrimary = Color(0xFF168BFF); // #168BFF Electric Blue
  static const Color liquidCyan = Color(0xFF20D9FF); // #20D9FF Cyan
  static const Color liquidViolet = Color(0xFF6C5CE7); // #6C5CE7 Liquid Violet
  static const Color liquidIceBlue = Color(0xFF8BE8FF); // #8BE8FF Ice Blue
  static const Color liquidTextPrimary = Color(0xFFF5F9FF); // #F5F9FF Almost White
  static const Color liquidTextSecondary = Color(0xFFA8B7CC); // #A8B7CC Cool Gray
  static const Color liquidSuccess = Color(0xFF35E0B5); // #35E0B5 Aqua Green
  static const Color liquidWarning = Color(0xFFFFC857); // #FFC857 Soft Amber
  static const Color liquidError = Color(0xFFFF5C7A); // #FF5C7A Coral Red

  static const Color liquidGlass = Color(0x14FFFFFF); // rgba(255,255,255,0.08)
  static const Color liquidGlassStrong = Color(0x1FFFFFFF); // rgba(255,255,255,0.12)
  static const Color liquidGlassBorder = Color(0x2EFFFFFF); // rgba(255,255,255,0.18)

  // Primary Accent — Emerald #20D6A1
  static const Color primary = OledTheme.emerald;
  static const Color primaryBright = Color(0xFF38EFBC);
  static const Color primaryDark = Color(0xFF0B4634);
  static const Color primaryHover = Color(0xFF38EFBC);
  static const Color primaryGlow = Color(0x2E20D6A1);
  static const Color primaryGlowSoft = Color(0x2620D6A1);
  static const Color primaryBg = Color(0xFF0D2820);
  static const Color primaryForeground = OledTheme.bg;

  // Secondary Accent — Electric Blue #5B8CFF
  static const Color secondary = OledTheme.electricBlue;
  static const Color blue = OledTheme.electricBlue;
  static const Color blueHighlight = Color(0xFF7FA7FF);
  static const Color blueDim = Color(0xFF122347);
  static const Color secondaryBg = Color(0xFF122347);
  static const Color secondaryForeground = OledTheme.textPrimary;

  // Amber (Streaks #FFC66D)
  static const Color amber = OledTheme.amber;
  static const Color accentAmber = OledTheme.amber;
  static const Color streak = OledTheme.amber;

  // Session Card Colors
  static const Color activeCardBg = Color(0xFF0D2820);
  static const Color activeCardBorder = OledTheme.emerald;
  static const Color completedCardBg = OledTheme.card;
  static const Color completedCardBorder = OledTheme.border;

  // Status & Semantic Colors
  static const Color success = OledTheme.emerald;
  static const Color successBg = Color(0x2420D6A1);
  static const Color warning = OledTheme.amber;
  static const Color error = OledTheme.coral;
  static const Color errorBg = Color(0x24FF7D87);
  static const Color errorBorder = Color(0x59FF7D87);
  static const Color coralRed = OledTheme.coral;
  static const Color info = OledTheme.cyan;
  static const Color infoBg = Color(0x2435D9F8);

  static const Color accentEmerald = OledTheme.emerald;
  static const Color accentRose = OledTheme.coral;
  static const Color accentCoral = OledTheme.coral;
  static const Color accentBlue = OledTheme.electricBlue;
  static const Color accentPurple = OledTheme.violet;
  static const Color accentViolet = OledTheme.violet;
  static const Color accentCyan = OledTheme.cyan;
  static const Color accentPink = OledTheme.pink;

  static const BoxDecoration backgroundGradientDecoration =
      OledTheme.backgroundDecoration;
}
