import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';

/// Shared motion tokens.
///
/// Every animated surface in the app (tabs, sidebar, sheets, forms, auth)
/// pulls its timing from here so the whole app moves with one rhythm.
///
/// Performance notes — all transitions built on these tokens animate only
/// `transform` and `opacity` of small layers, which the raster thread can do
/// cheaply even on low-end GPUs. Nothing here triggers layout per frame.
class AppMotion {
  AppMotion._();

  // ── Durations ─────────────────────────────────────────────────────────────
  static const Duration instant = Duration(milliseconds: 110);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 280);
  static const Duration emphasized = Duration(milliseconds: 360);
  static const Duration sheetOpen = Duration(milliseconds: 380);
  static const Duration sheetClose = Duration(milliseconds: 260);

  // ── Curves ────────────────────────────────────────────────────────────────
  /// iOS-like decelerate: quick start, long gentle settle. No overshoot.
  static const Curve enter = Cubic(0.32, 0.72, 0.0, 1.0);

  /// Used as `reverseCurve` — starts promptly and settles softly at rest.
  static final Curve exit = const Cubic(0.32, 0.72, 0.0, 1.0).flipped;

  /// Small UI state changes (pills, toggles, colors).
  static const Curve standardCurve = Cubic(0.2, 0.0, 0.0, 1.0);

  /// Press feedback.
  static const Curve press = Curves.easeOutCubic;

  /// Convenience for `CurvedAnimation(parent, curve: enter, reverseCurve: exit)`.
  static CurvedAnimation curved(Animation<double> parent) =>
      CurvedAnimation(parent: parent, curve: enter, reverseCurve: exit);

  static const AnimationStyle sheetStyle = AnimationStyle(
    duration: sheetOpen,
    reverseDuration: sheetClose,
    curve: enter,
  );
}
