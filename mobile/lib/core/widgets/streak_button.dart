import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'lottie_fire.dart';
import '../../providers/streak_provider.dart';

class StreakButton extends ConsumerStatefulWidget {
  const StreakButton({super.key});

  @override
  ConsumerState<StreakButton> createState() => _StreakButtonState();
}

class _StreakButtonState extends ConsumerState<StreakButton>
    with TickerProviderStateMixin {
  late final AnimationController _scaleController;
  late final AnimationController _numberController;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _numberAnim;

  int _displayedStreak = 0;
  bool _wasIncremented = false;

  @override
  void initState() {
    super.initState();

    // Slight scale bounce when streak increments
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.28), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.28, end: 0.94), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOut));

    // Number count-up animation
    _numberController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _numberAnim = CurvedAnimation(
      parent: _numberController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  void _playIncrement(int newStreak) {
    _scaleController.forward(from: 0);
    _numberController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final streak = ref.watch(streakProvider);

    // Detect streak increment
    if (streak.justIncremented && !_wasIncremented) {
      _wasIncremented = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _playIncrement(streak.currentStreak);
      });
    } else if (!streak.justIncremented) {
      _wasIncremented = false;
    }

    // Update displayed number
    final targetStreak = streak.currentStreak;
    if (_displayedStreak != targetStreak && !streak.justIncremented) {
      _displayedStreak = targetStreak;
    }

    return GestureDetector(
      onTap: () => context.push('/streak'),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: _GlassCircle(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LottieFire(size: 28),
              const SizedBox(height: 2),
              // Animated streak count
              AnimatedBuilder(
                animation: _numberAnim,
                builder: (context, _) {
                  final displayed = streak.justIncremented
                      ? ((_displayedStreak) +
                              (_numberAnim.value * 1).round())
                          .clamp(0, targetStreak)
                      : targetStreak;
                  return Text(
                    '$displayed',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB020),
                      height: 1,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassCircle extends StatelessWidget {
  final Widget child;
  const _GlassCircle({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0E1526).withValues(alpha: 0.85),
            border: Border.all(
              color: const Color(0xFF1C2C46),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFB020).withValues(alpha: 0.08),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}
