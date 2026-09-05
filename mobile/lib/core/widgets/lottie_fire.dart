import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieFire extends StatelessWidget {
  final double size;
  final AnimationController? controller;
  final bool repeat;
  final bool animate;

  const LottieFire({
    super.key,
    this.size = 120,
    this.controller,
    this.repeat = true,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Lottie.asset(
            'assets/animations/fire.json',
            controller: controller,
            repeat: repeat,
            animate: animate,
            width: size,
            height: size,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            onLoaded: (composition) {
              debugPrint('[LottieFire] Fire animation loaded successfully (${composition.duration})');
            },
            errorBuilder: (context, error, stackTrace) {
              debugPrint('[LottieFire ERROR] Failed to load assets/animations/fire.json: $error\n$stackTrace');
              return Icon(
                Icons.local_fire_department_rounded,
                size: size * 0.75,
                color: const Color(0xFFFFB020),
              );
            },
          ),
        ),
      ),
    );
  }
}
