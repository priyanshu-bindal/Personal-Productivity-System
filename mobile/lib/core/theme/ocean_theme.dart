import 'package:flutter/material.dart';
import 'oled_theme.dart';

/// Legacy palette name kept for existing screens.
/// Every value now resolves to the unified OLED design tokens.
class OceanTheme {
  static const Color bg = OledTheme.bg;
  static const Color bgGradientTop = OledTheme.bg;

  static const Color card = OledTheme.card;
  static const Color cardHi = OledTheme.cardElevated;

  static const Color border = OledTheme.border;

  static const Color textPrimary = OledTheme.textPrimary;
  static const Color textDim = OledTheme.textSecondary;
  static const Color textFaint = OledTheme.textMuted;

  static const Color primary = OledTheme.accent;
  static const Color primaryHover = Color(0xFF6B9EFF);
  static const Color primaryDim = Color(0xFF0E1A2E);

  static const Color secondary = OledTheme.accent;
  static const Color secondaryHighlight = Color(0xFF7FA9FF);
  static const Color secondaryDim = Color(0xFF0E1A2E);

  static const Color amber = OledTheme.amber;

  static const BoxDecoration backgroundGradientDecoration =
      BoxDecoration(color: OledTheme.bg);
}
