import 'package:flutter/material.dart';

/// Centralized OLED Design System Tokens for FocusFlow
/// Near-black true OLED foundation with a balanced, semantic multi-accent palette.
class OledTheme {
  // ── Background Surfaces ───────────────────────────────────────────────────
  static const Color bg = Color(0xFF000000);              // #000000 True OLED Black
  static const Color bgSecondary = Color(0xFF05070B);     // #05070B Deep Navy-Black
  static const Color card = Color(0xFF0B1018);             // #0B1018 Primary Card
  static const Color cardElevated = Color(0xFF111824);     // #111824 Elevated Surface
  static const Color subtleSurface = Color(0xFF151E2B);    // #151E2B Subtle Interactive Surface

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color border = Color(0xFF202B38);           // #202B38 Restrained Card Border
  static const Color borderSubtle = Color(0x28202B38);
  static const Color borderHighlight = Color(0xFF2C3B4E);

  // ── Typography ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF4F7FB);      // #F4F7FB High Contrast White
  static const Color textSecondary = Color(0xFF96A3B5);    // #96A3B5 Cool Medium Slate
  static const Color textMuted = Color(0xFF657286);        // #657286 Subtle Label Text

  // ── Multi-Accent Semantic Palette ─────────────────────────────────────────
  static const Color emerald = Color(0xFF20D6A1);          // #20D6A1 Completed, success, positive
  static const Color cyan = Color(0xFF35D9F8);             // #35D9F8 Learning & skills
  static const Color violet = Color(0xFFA78BFA);           // #A78BFA Insights, analytics, highlights
  static const Color coral = Color(0xFFFF7D87);            // #FF7D87 Missed sessions, errors
  static const Color amber = Color(0xFFFFC66D);            // #FFC66D Streaks, goals, reminders
  static const Color electricBlue = Color(0xFF5B8CFF);     // #5B8CFF Navigation active & emphasis
  static const Color pink = Color(0xFFF472B6);             // #F472B6 Secondary accent highlights

  // ── Background Atmospheric Gradient ───────────────────────────────────────
  static const BoxDecoration backgroundDecoration = BoxDecoration(
    color: bg,
    gradient: LinearGradient(
      colors: [bgSecondary, bg],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ),
  );

  // ── Category Accent Helper ────────────────────────────────────────────────
  static Color getCategoryAccent(String? category, String? name) {
    final cat = (category ?? '').toLowerCase();
    final n = (name ?? '').toLowerCase();

    if (cat.contains('health') || cat.contains('fitness') || n.contains('gym') || n.contains('workout')) {
      return emerald;
    }
    if (cat.contains('language') || n.contains('vocab') || n.contains('english')) {
      return violet;
    }
    if (cat.contains('technical') || cat.contains('tech') || n.contains('tech')) {
      return cyan;
    }
    if (n.contains('dsa') || cat.contains('algorithm') || cat.contains('problem')) {
      return amber;
    }
    if (cat.contains('programming') || cat.contains('dev') || n.contains('flutter') || n.contains('dart')) {
      return electricBlue;
    }
    return cyan;
  }

  // ── Category Icon Helper ──────────────────────────────────────────────────
  static IconData getCategoryIcon(String? category, String? name) {
    final cat = (category ?? '').toLowerCase();
    final n = (name ?? '').toLowerCase();

    if (cat.contains('health') || cat.contains('fitness') || n.contains('gym') || n.contains('workout')) {
      return Icons.fitness_center_rounded;
    }
    if (cat.contains('language') || n.contains('vocab') || n.contains('english')) {
      return Icons.translate_rounded;
    }
    if (cat.contains('technical') || cat.contains('tech') || n.contains('tech')) {
      return Icons.memory_rounded;
    }
    if (n.contains('dsa') || cat.contains('algorithm')) {
      return Icons.account_tree_rounded;
    }
    if (cat.contains('programming') || n.contains('code') || n.contains('java') || n.contains('c++')) {
      return Icons.code_rounded;
    }
    return Icons.auto_stories_rounded;
  }
}
