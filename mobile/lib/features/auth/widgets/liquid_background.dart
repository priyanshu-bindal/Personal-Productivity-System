import 'package:flutter/material.dart';
import 'liquid_auth_background.dart';

/// Backward-compatibility wrapper for [LiquidAuthBackground].
/// Guarantees that any route or shell using [LiquidBackground] automatically
/// uses the Dark Liquid Glass background with NO CYAN.
class LiquidBackground extends StatelessWidget {
  final bool reducedMotion;

  const LiquidBackground({
    super.key,
    this.reducedMotion = false,
  });

  @override
  Widget build(BuildContext context) {
    return LiquidAuthBackground(reducedMotion: reducedMotion);
  }
}
