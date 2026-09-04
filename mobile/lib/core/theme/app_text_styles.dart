import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ocean_theme.dart';

/// App-wide Centralized Typography System
/// Headings, Screen Titles, Big Numeric Stats: Space Grotesk
/// Body, UI Elements, Labels, Buttons: Inter
class AppTextStyles {
  /// Screen titles like "Good afternoon, MR" (Space Grotesk, 22px, weight 600)
  static TextStyle get displayTitle => GoogleFonts.spaceGrotesk(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: OceanTheme.textPrimary,
        letterSpacing: -0.5,
        height: 1.3,
      );

  /// Large hero streak / numerical stats (Space Grotesk, 52px, weight 700)
  static TextStyle get displayHero => GoogleFonts.spaceGrotesk(
        fontSize: 52,
        fontWeight: FontWeight.w700,
        color: OceanTheme.textPrimary,
        letterSpacing: -1.0,
        height: 1.1,
      );

  /// Card headline for big stats like "120 mins completed today" (Space Grotesk, 17px, weight 600)
  static TextStyle get cardHeadline => GoogleFonts.spaceGrotesk(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: OceanTheme.textPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      );

  /// Medium section title / card sub-heading (Space Grotesk, 18px, weight 600)
  static TextStyle get headingMedium => GoogleFonts.spaceGrotesk(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: OceanTheme.textPrimary,
        letterSpacing: -0.3,
        height: 1.3,
      );

  /// Section headers like "SKILLS OVERVIEW" (Inter, 12px, weight 500, letter-spacing 0.04em)
  static TextStyle get sectionLabel => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: OceanTheme.textFaint,
        letterSpacing: 0.48, // 0.04em
        height: 1.35,
      );

  /// Item names like "DSA", "Python" (Inter, 15px, weight 600)
  static TextStyle get bodyStrong => GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: OceanTheme.textPrimary,
        height: 1.35,
      );

  /// Standard body text (Inter, 14px, weight 400)
  static TextStyle get bodyMedium => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: OceanTheme.textPrimary,
        height: 1.35,
      );

  /// Meta text like "60 minutes • Completed" (Inter, 13px, weight 500)
  static TextStyle get bodySecondary => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: OceanTheme.textDim,
        height: 1.35,
      );

  /// Tags, percentages, small stats (Inter, 11.5px, weight 500)
  static TextStyle get labelSmall => GoogleFonts.inter(
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        color: OceanTheme.textFaint,
        height: 1.35,
      );

  /// Button text labels (Inter, 13px, weight 700)
  static TextStyle get buttonText => GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: OceanTheme.bg,
        height: 1.2,
      );

  // Backward-compatibility bridges mapped to the system scale
  static TextStyle get displayLarge => displayHero;
  static TextStyle get displayMedium => displayTitle;
  static TextStyle get headingLarge => displayTitle;
  static TextStyle get bodyLarge => bodyStrong;
  static TextStyle get bodySmall => bodySecondary;
  static TextStyle get label => labelSmall;
  static TextStyle get sectionHeader => sectionLabel;
}
