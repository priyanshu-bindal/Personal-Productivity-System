import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Liquid Glass Design System Tokens & Typography
/// Provides unified colors, Inter typography scale, glass tokens, and spacing.
class LiquidTheme {
  // ─── Color System (Official Tokens) ───────────────────────────
  static const Color background = Color(0xFF020817); // #020817 Deep Midnight Navy
  static const Color secondaryBackground = Color(0xFF06142B); // #06142B Dark Blue
  static const Color primary = Color(0xFF168BFF); // #168BFF Electric Blue
  static const Color cyan = Color(0xFF20D9FF); // #20D9FF Cyan
  static const Color accent = Color(0xFF20D9FF); // Alias for cyan
  static const Color violet = Color(0xFF6C5CE7); // #6C5CE7 Liquid Violet
  static const Color secondaryAccent = Color(0xFF6C5CE7); // Alias for violet
  static const Color iceBlue = Color(0xFF8BE8FF); // #8BE8FF Ice Blue
  static const Color highlight = Color(0xFF8BE8FF); // Alias for iceBlue

  // Glass tokens
  static const Color glass = Color(0x14FFFFFF); // rgba(255, 255, 255, 0.08)
  static const Color glassStrong = Color(0x1FFFFFFF); // rgba(255, 255, 255, 0.12)
  static const Color glassBorder = Color(0x2EFFFFFF); // rgba(255, 255, 255, 0.18)

  // Typography tokens
  static const Color textPrimary = Color(0xFFF5F9FF); // #F5F9FF Almost White
  static const Color textSecondary = Color(0xFFA8B7CC); // #A8B7CC Cool Gray

  // Semantic tokens
  static const Color success = Color(0xFF35E0B5); // #35E0B5 Aqua Green
  static const Color warning = Color(0xFFFFC857); // #FFC857 Soft Amber

  // ─── Premium Soft Pink-Coral Error System ─────────────────────
  // Avoids harsh red; blends naturally with the blue/cyan Liquid Glass palette
  static const Color error = Color(0xFFFF6B9D);       // #FF6B9D — soft pink-coral border
  static const Color errorText = Color(0xFFFF9FBC);   // #FF9FBC — subtle pink for text
  static const Color errorGlow = Color(0xFFFF4D8D);   // #FF4D8D — deeper glow tint
  static const Color errorBg = Color(0x14FF6B9D);     // rgba(255, 107, 157, 0.08)
  static const Color errorBorder = Color(0x40FF6B9D); // rgba(255, 107, 157, 0.25)

  // Backward-compatibility aliases
  static const Color mainBackground = background;
  static const Color cardSurface = secondaryBackground;
  static const Color inputSurface = secondaryBackground;
  static const Color electricBlue = primary;
  static const Color deepBlue = secondaryBackground;
  static const Color darkBlue = secondaryBackground;
  static const Color glassSurface = glass;
  static const Color borderDefault = glassBorder;

  // ─── Typography: Inter (Unified System) ─────────────────────
  // Display: 40px / 700
  static TextStyle display({Color color = textPrimary}) => GoogleFonts.inter(
        fontSize: 40,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -1.0,
        height: 1.15,
      );

  // Title: 32px / 700
  static TextStyle title({Color color = textPrimary}) => GoogleFonts.inter(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.6,
        height: 1.2,
      );

  // Login Title: 30px / 700 / letter spacing -0.5
  static TextStyle loginTitle({Color color = textPrimary}) => GoogleFonts.inter(
        fontSize: 30,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
        height: 1.2,
      );

  // Heading: 24px / 600
  static TextStyle heading({Color color = textPrimary}) => GoogleFonts.inter(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.4,
        height: 1.25,
      );

  // Subtitle: 18px / 500
  static TextStyle subtitle({
    double fontSize = 18,
    Color color = textSecondary,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color,
        letterSpacing: -0.2,
        height: 1.45,
      );

  // Body: 16px / 400
  static TextStyle body({
    double fontSize = 16,
    Color color = textPrimary,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  // Small: 14px / 400–500
  static TextStyle small({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textSecondary,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: 1.4,
      );

  // Caption: 12px / 500
  static TextStyle caption({Color color = textSecondary}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color,
        height: 1.35,
      );

  // Semantic UI helpers:
  static TextStyle logoTitle({double fontSize = 28}) => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
      );

  static TextStyle logoSubtitle({double fontSize = 13}) => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.8,
      );

  static TextStyle heroHeading({double fontSize = 34}) => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        color: textPrimary,
        letterSpacing: -0.8,
        height: 1.15,
      );

  static TextStyle pageTitle({double fontSize = 30}) => loginTitle();

  static TextStyle inputText({double fontSize = 16}) => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle inputLabel({double fontSize = 14}) => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: textSecondary,
      );

  static TextStyle buttonText({double fontSize = 16}) => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle linkText({double fontSize = 14, bool bold = false}) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
        color: cyan,
      );

  static TextStyle cardTitle({double fontSize = 15}) => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      );

  static TextStyle cardSubtitle({double fontSize = 11.5}) => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: textSecondary,
        height: 1.35,
      );
}
