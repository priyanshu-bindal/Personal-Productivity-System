import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Centralized Liquid Glass Design System Tokens & Typography
/// Conforms strictly to the Dark Liquid Glass specification:
/// - Blue/Violet/White visual language
/// - NO CYAN (cyan aliases mapped to secondary blue/ice white)
/// - Space Grotesk for brand, titles, buttons
/// - Inter for inputs, labels, small text
class LiquidTheme {
  // ─── Color System (Official Tokens) ───────────────────────────
  static const Color background = Color(0xFF020617); // #020617 Dark Navy / Black
  static const Color backgroundDeep = Color(0xFF030712); // #030712 Deep Black
  static const Color backgroundSpace = Color(0xFF050B18); // #050B18 Midnight Space
  static const Color secondaryBackground = Color(0xFF0A1223); // #0A1223 Dark Blue Base

  // Accents (Strictly Blue & Violet — NO CYAN)
  static const Color primary = Color(0xFF2F6BFF); // #2F6BFF Primary Accent Blue
  static const Color secondaryBlue = Color(0xFF4F7CFF); // #4F7CFF Secondary Blue
  static const Color violet = Color(0xFF7C6CFF); // #7C6CFF Subtle Violet
  static const Color secondaryAccent = Color(0xFF7C6CFF);
  static const Color accent = Color(0xFF2F6BFF);
  static const Color iceBlue = Color(0xFF9DB8FF); // Soft blue highlight
  static const Color highlight = Color(0xFF9DB8FF);
  static const Color cyan = Color(0xFF4F7CFF); // Mapped to secondary blue to eliminate cyan

  // Glass tokens
  static const Color glassSurface = Color(0xB80A1223); // rgba(10, 18, 35, 0.78)
  static const Color glassInputSurface = Color(0xA60F172A); // rgba(15, 23, 42, 0.65)
  static const Color glassBorder = Color(0x1F7896D2); // rgba(120, 150, 210, 0.12)
  static const Color border = Color(0xFF26334A); // #26334A
  static const Color borderFocused = Color(0xFF2F6BFF); // #2F6BFF

  // Typography tokens
  static const Color textPrimary = Color(0xFFF8FAFC); // #F8FAFC Primary Light
  static const Color textSecondary = Color(0xFFA7B3C7); // #A7B3C7 Secondary Cool Gray
  static const Color textMuted = Color(0xFF6F7C91); // #6F7C91 Muted Gray

  // Semantic tokens
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber
  static const Color error = Color(0xFFEF4444); // #EF4444 Subtle Red Border
  static const Color errorText = Color(0xFFF87171); // #F87171 Soft Red Text
  static const Color errorGlow = Color(0x33EF4444); // 20% Red Glow
  static const Color errorBg = Color(0x14EF4444); // 8% Red Background
  static const Color errorBorder = Color(0x4DEF4444); // 30% Red Border

  // Backward-compatibility aliases
  static const Color mainBackground = background;
  static const Color cardSurface = glassSurface;
  static const Color inputSurface = glassInputSurface;
  static const Color electricBlue = primary;
  static const Color deepBlue = secondaryBackground;
  static const Color darkBlue = secondaryBackground;
  static const Color borderDefault = border;

  // ─── Typography: Space Grotesk (Brand & Titles) ───────────────
  static TextStyle display({Color color = textPrimary}) => GoogleFonts.spaceGrotesk(
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.8,
        height: 1.15,
      );

  static TextStyle title({Color color = textPrimary}) => GoogleFonts.spaceGrotesk(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle loginTitle({Color color = textPrimary}) => GoogleFonts.spaceGrotesk(
        fontSize: 27,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: -0.4,
        height: 1.2,
      );

  static TextStyle heading({Color color = textPrimary}) => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: color,
        letterSpacing: -0.3,
        height: 1.25,
      );

  static TextStyle subtitle({
    double fontSize = 13.5,
    Color color = textSecondary,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  static TextStyle body({
    double fontSize = 15,
    Color color = textPrimary,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.45,
      );

  static TextStyle small({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w400,
    Color color = textSecondary,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        height: 1.4,
      );

  static TextStyle caption({Color color = textMuted}) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
        height: 1.35,
      );

  // Semantic UI helpers:
  static TextStyle logoTitle({
    double fontSize = 26,
    FontWeight fontWeight = FontWeight.w700,
  }) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: -0.5,
      );

  static TextStyle logoSubtitle({double fontSize = 12.5}) => GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: textSecondary,
        letterSpacing: 0.6,
      );

  static TextStyle heroHeading({double fontSize = 32}) => GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: textPrimary,
        letterSpacing: -0.6,
        height: 1.15,
      );

  static TextStyle pageTitle({double fontSize = 27}) => loginTitle();

  static TextStyle inputText({double fontSize = 15}) => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: textPrimary,
      );

  static TextStyle inputLabel({double fontSize = 14}) => GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w400,
        color: textMuted,
      );

  static TextStyle buttonText({double fontSize = 15.5}) => GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: textPrimary,
        letterSpacing: 0.2,
      );

  static TextStyle linkText({double fontSize = 13.5, bool bold = false}) =>
      GoogleFonts.spaceGrotesk(
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w600 : FontWeight.w500,
        color: secondaryBlue,
      );

  static TextStyle cardTitle({double fontSize = 15}) => GoogleFonts.spaceGrotesk(
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
