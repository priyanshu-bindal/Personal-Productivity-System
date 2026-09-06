import 'package:flutter/material.dart';

/// Centralized Bioluminescent Ocean Theme Palette
class OceanTheme {
  // Base Backgrounds (True OLED Black)
  static const Color bg = Color(0xFF000000);
  static const Color bgGradientTop = Color(0xFF050C18);

  // Cards & Surfaces
  static const Color card = Color(0xFF0E1526);
  static const Color cardHi = Color(0xFF132038);

  // Borders
  static const Color border = Color(0xFF1C2C46);

  // Typography
  static const Color textPrimary = Color(0xFFEAF2F5);
  static const Color textDim = Color(0xFF7E93A8);
  static const Color textFaint = Color(0xFF4C5E70);

  // Primary Accent — Premium Emerald-Teal #14C8A8
  // Less neon, more sophisticated, consistent throughout app
  static const Color primary = Color(0xFF14C8A8);
  static const Color primaryHover = Color(0xFF20D6B5);
  static const Color primaryDim = Color(0xFF0A2E2A);

  // Secondary Accent — Sapphire Blue #3B82F6
  static const Color secondary = Color(0xFF3B82F6);
  static const Color secondaryHighlight = Color(0xFF60A5FA);
  static const Color secondaryDim = Color(0xFF13284A);

  // Amber (Streaks / Highlights Only)
  static const Color amber = Color(0xFFFFB020);

  // Background Gradient (OLED Black base with subtle deep top glow)
  static const BoxDecoration backgroundGradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      colors: [bgGradientTop, bg],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );
}
