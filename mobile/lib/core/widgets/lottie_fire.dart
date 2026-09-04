import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieFire extends StatefulWidget {
  final double size;
  final AnimationController? controller;

  const LottieFire({
    super.key,
    this.size = 120,
    this.controller,
  });

  @override
  State<LottieFire> createState() => _LottieFireState();
}

class _LottieFireState extends State<LottieFire> with SingleTickerProviderStateMixin {
  late final AnimationController _fallbackController;
  bool _useJsonFallback = false;

  AnimationController get _effectiveController =>
      widget.controller ?? _fallbackController;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _fallbackController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600),
      )..repeat();
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _fallbackController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useJsonFallback) {
      return Lottie.asset(
        'assets/animations/Fire.json',
        controller: _effectiveController,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.contain,
        onLoaded: (composition) {
          if (widget.controller == null && _fallbackController.duration != composition.duration) {
            _fallbackController.duration = composition.duration;
            _fallbackController.repeat();
          }
        },
        errorBuilder: (context, error, stackTrace) {
          return SizedBox(
            width: widget.size,
            height: widget.size,
          );
        },
      );
    }

    return Lottie.asset(
      'assets/animations/Fire.lottie',
      controller: _effectiveController,
      width: widget.size,
      height: widget.size,
      fit: BoxFit.contain,
      onLoaded: (composition) {
        if (widget.controller == null && _fallbackController.duration != composition.duration) {
          _fallbackController.duration = composition.duration;
          _fallbackController.repeat();
        }
      },
      errorBuilder: (context, error, stackTrace) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !_useJsonFallback) {
            setState(() {
              _useJsonFallback = true;
            });
          }
        });
        return Lottie.asset(
          'assets/animations/Fire.json',
          controller: _effectiveController,
          width: widget.size,
          height: widget.size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              width: widget.size,
              height: widget.size,
            );
          },
        );
      },
    );
  }
}
