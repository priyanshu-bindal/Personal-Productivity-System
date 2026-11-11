import 'package:flutter/material.dart';
import 'oled_theme.dart';

class AppColors {
  // ── True OLED Black & Surfaces ────────────────────────────────────────────
  static const Color background = OledTheme.bg;
  static const Color backgroundGradientTop = OledTheme.bg;
  static const Color backgroundGradientBottom = OledTheme.bg;

  static const Color surface = OledTheme.card;
  static const Color surfaceElevated = OledTheme.cardElevated;
  static const Color card = OledTheme.card;
  static const Color cardHi = OledTheme.cardElevated;
  static const Color cardElevated = OledTheme.cardElevated;
  static const Color cardHover = OledTheme.subtleSurface;

  static const Color border = OledTheme.border;
  static const Color borderActive = OledTheme.accent;
  static const Color borderSubtle = OledTheme.borderSubtle;
  static const Color input = OledTheme.card;

  static const Color textPrimary = OledTheme.textPrimary;
  static const Color textSecondary = OledTheme.textSecondary;
  static const Color textDim = OledTheme.textSecondary;
  static const Color textMuted = OledTheme.textMuted;
  static const Color textFaint = OledTheme.textMuted;

  // ── Legacy "liquid" tokens → neutral OLED equivalents ─────────────────────
  static const Color liquidBackground = OledTheme.bg;
  static const Color liquidSecondaryBg = OledTheme.card;
  static const Color liquidPrimary = OledTheme.accent;
  static const Color liquidCyan = OledTheme.cyan;
  static const Color liquidViolet = OledTheme.violet;
  static const Color liquidIceBlue = Color(0xFFB9D0FF);
  static const Color liquidTextPrimary = OledTheme.textPrimary;
  static const Color liquidTextSecondary = OledTheme.textSecondary;
  static const Color liquidSuccess = OledTheme.emerald;
  static const Color liquidWarning = OledTheme.amber;
  static const Color liquidError = OledTheme.coral;

  static const Color liquidGlass = Color(0x0FFFFFFF);
  static const Color liquidGlassStrong = Color(0x17FFFFFF);
  static const Color liquidGlassBorder = Color(0x1FFFFFFF);

  // ── Primary Accent — single brand blue ────────────────────────────────────
  static const Color primary = OledTheme.accent;
  static const Color primaryBright = Color(0xFF6B9EFF);
  static const Color primaryDark = Color(0xFF1B3463);
  static const Color primaryHover = Color(0xFF6B9EFF);
  static const Color primaryGlow = Color(0x1F4F8CFF);
  static const Color primaryGlowSoft = Color(0x144F8CFF);
  static const Color primaryBg = Color(0xFF0E1A2E);
  static const Color primaryForeground = Color(0xFFFFFFFF);

  // Secondary (same family, for compatibility)
  static const Color secondary = OledTheme.accent;
  static const Color blue = OledTheme.accent;
  static const Color blueHighlight = Color(0xFF7FA9FF);
  static const Color blueDim = Color(0xFF0E1A2E);
  static const Color secondaryBg = Color(0xFF0E1A2E);
  static const Color secondaryForeground = OledTheme.textPrimary;

  // Amber (Streaks)
  static const Color amber = OledTheme.amber;
  static const Color accentAmber = OledTheme.amber;
  static const Color streak = OledTheme.amber;

  // Session Card Colors
  static const Color activeCardBg = Color(0xFF0E1A2E);
  static const Color activeCardBorder = OledTheme.accent;
  static const Color completedCardBg = OledTheme.card;
  static const Color completedCardBorder = OledTheme.border;

  // Status & Semantic Colors
  static const Color success = OledTheme.emerald;
  static const Color successBg = Color(0x1F3DC787);
  static const Color warning = OledTheme.amber;
  static const Color error = OledTheme.coral;
  static const Color errorBg = Color(0x1FFF6B6B);
  static const Color errorBorder = Color(0x4DFF6B6B);
  static const Color coralRed = OledTheme.coral;
  static const Color info = OledTheme.accent;
  static const Color infoBg = Color(0x1F4F8CFF);

  static const Color accentEmerald = OledTheme.emerald;
  static const Color accentRose = OledTheme.coral;
  static const Color accentCoral = OledTheme.coral;
  static const Color accentBlue = OledTheme.accent;
  static const Color accentPurple = OledTheme.violet;
  static const Color accentViolet = OledTheme.violet;
  static const Color accentCyan = OledTheme.cyan;
  static const Color accentPink = OledTheme.pink;

  static const BoxDecoration backgroundGradientDecoration =
      OledTheme.backgroundDecoration;
}
