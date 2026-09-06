import 'package:flutter/material.dart';
import 'ocean_theme.dart';

class AppColors {
  // Bioluminescent Ocean Palette Delegation
  static const Color background = OceanTheme.bg;
  static const Color backgroundGradientTop = OceanTheme.bgGradientTop;
  static const Color backgroundGradientBottom = OceanTheme.bg;

  static const Color surface = OceanTheme.card;
  static const Color surfaceElevated = OceanTheme.cardHi;
  static const Color card = OceanTheme.card;
  static const Color cardHi = OceanTheme.cardHi;
  static const Color cardElevated = OceanTheme.cardHi;
  static const Color cardHover = OceanTheme.cardHi;

  static const Color border = OceanTheme.border;
  static const Color borderActive = OceanTheme.primary;
  static const Color borderSubtle = OceanTheme.border;
  static const Color input = OceanTheme.card;

  static const Color textPrimary = OceanTheme.textPrimary;
  static const Color textSecondary = OceanTheme.textDim;
  static const Color textDim = OceanTheme.textDim;
  static const Color textMuted = OceanTheme.textFaint;
  static const Color textFaint = OceanTheme.textFaint;

  // Primary Accent — Premium Emerald-Teal #14C8A8
  static const Color primary = OceanTheme.primary;
  static const Color primaryBright = OceanTheme.primaryHover;
  static const Color primaryDark = OceanTheme.primaryDim;
  static const Color primaryHover = OceanTheme.primaryHover;
  // Soft glow: rgba(20, 200, 168, 0.18)
  static const Color primaryGlow = Color(0x2E14C8A8);
  // Subtle glow for box shadows: rgba(20,200,168,0.15)
  static const Color primaryGlowSoft = Color(0x2614C8A8);
  static const Color primaryBg = OceanTheme.primaryDim;
  static const Color primaryForeground = OceanTheme.bg;

  // Secondary Accent — Sapphire Blue #3B82F6
  static const Color secondary = OceanTheme.secondary;
  static const Color blue = OceanTheme.secondary;
  static const Color blueHighlight = OceanTheme.secondaryHighlight;
  static const Color blueDim = OceanTheme.secondaryDim;
  static const Color secondaryBg = OceanTheme.secondaryDim;
  static const Color secondaryForeground = OceanTheme.textPrimary;

  // Amber (Streaks #FFB020)
  static const Color amber = OceanTheme.amber;
  static const Color accentAmber = OceanTheme.amber;
  static const Color streak = OceanTheme.amber;

  // Session Card Colors
  static const Color activeCardBg = OceanTheme.primaryDim;
  static const Color activeCardBorder = OceanTheme.primary;
  static const Color completedCardBg = OceanTheme.card;
  static const Color completedCardBorder = OceanTheme.border;

  // Status & Semantic Colors
  static const Color success = OceanTheme.primary;
  static const Color successBg = OceanTheme.primaryDim;
  static const Color warning = OceanTheme.amber;
  static const Color error = Color(0xFFEF5B5B);
  static const Color errorBg = Color(0x1AEF5B5B);   // rgba(239,91,91,0.10)
  static const Color errorBorder = Color(0x59EF5B5B); // rgba(239,91,91,0.35)
  static const Color coralRed = Color(0xFFEF5B5B);
  static const Color info = OceanTheme.secondary;
  static const Color infoBg = OceanTheme.secondaryDim;

  static const Color accentEmerald = OceanTheme.primary;
  static const Color accentRose = Color(0xFFEF5B5B);
  static const Color accentBlue = OceanTheme.secondary;
  static const Color accentPurple = OceanTheme.secondary;
  static const Color accentCyan = OceanTheme.primary;

  static const BoxDecoration backgroundGradientDecoration =
      OceanTheme.backgroundGradientDecoration;
}
