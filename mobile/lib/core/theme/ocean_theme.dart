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

  // Primary Accent (Green / Success / Active Tab / Completed Sessions)
  static const Color primary = Color(0xFF00E5A0);
  static const Color primaryDim = Color(0xFF0A2E24);

  // Secondary Accent (Blue / Scheduled / Active Sessions)
  static const Color secondary = Color(0xFF3B82F6);
  static const Color secondaryDim = Color(0xFF132038);

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
