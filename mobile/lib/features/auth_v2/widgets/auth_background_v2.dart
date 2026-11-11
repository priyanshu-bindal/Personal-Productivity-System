import 'package:flutter/material.dart';

/// Static OLED backdrop for the auth screens: pure black with a very faint
/// neutral lift at the top so the page has depth without any glow.
/// Painted once and cached — zero per-frame cost.
class AuthBackgroundV2 extends StatelessWidget {
  const AuthBackgroundV2({super.key});

  @override
  Widget build(BuildContext context) {
    return const RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          gradient: RadialGradient(
            center: Alignment(0, -1.25),
            radius: 1.1,
            colors: [Color(0xFF12151C), Color(0xFF000000)],
            stops: [0.0, 1.0],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}
