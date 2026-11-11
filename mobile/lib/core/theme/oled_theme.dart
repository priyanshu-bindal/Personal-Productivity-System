import 'package:flutter/material.dart';

/// Centralized OLED design tokens for FocusFlow.
///
/// Philosophy: true-black canvas, neutral graphite surfaces, hairline borders,
/// and a deliberately small accent palette. Accents are solid and readable —
/// never neon, never glowing.
class OledTheme {
  // ── Background Surfaces ───────────────────────────────────────────────────
  static const Color bg = Color(0xFF000000); // True OLED black
  static const Color bgSecondary = Color(0xFF000000);
  static const Color card = Color(0xFF0D0D0F); // Grouped surface
  static const Color cardElevated = Color(0xFF151518); // Raised surface
  static const Color subtleSurface = Color(0xFF1C1C20); // Controls / chips

  // ── Borders ───────────────────────────────────────────────────────────────
  static const Color border = Color(0xFF222226); // Hairline card border
  static const Color borderSubtle = Color(0x14FFFFFF);
  static const Color borderHighlight = Color(0xFF2E2E34);

  // ── Typography ────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF5F5F7);
  static const Color textSecondary = Color(0xFFA1A1AA);
  static const Color textMuted = Color(0xFF75757E);

  // ── Restrained Accent Palette ─────────────────────────────────────────────
  // One brand accent (blue) + semantic colors. Others are toned to sit quietly.
  static const Color accent = Color(0xFF4F8CFF); // Brand / interactive
  static const Color electricBlue = accent;
  static const Color emerald = Color(0xFF3DC787); // Success / completed
  static const Color amber = Color(0xFFF2B544); // Streaks / goals
  static const Color coral = Color(0xFFFF6B6B); // Errors / missed
  static const Color violet = Color(0xFF9D8CFF); // Insights (sparingly)
  static const Color cyan = Color(0xFF5AB0F0); // Learning (blue family)
  static const Color pink = Color(0xFFE38BB4); // Rare highlight

  // ── Glass (navbar / sidebar) ──────────────────────────────────────────────
  static const Color glassFill = Color(0xB8141416); // ~72% graphite
  static const Color glassFillOpaque = Color(0xF5121214); // Low-end fallback
  static const Color glassBorder = Color(0x1AFFFFFF);
  static const Color glassHighlight = Color(0x14FFFFFF);

  // ── Background ────────────────────────────────────────────────────────────
  static const BoxDecoration backgroundDecoration = BoxDecoration(color: bg);

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
