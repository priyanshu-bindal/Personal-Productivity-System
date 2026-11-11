import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/oled_theme.dart';
import '../../providers/streak_provider.dart';

/// Compact, static OLED streak indicator for the top-right app header.
/// Replaces the heavy Lottie animation with an instant-rendering, high-performance
/// vector flame icon and streak count, preserving full streak data and navigation.
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
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();

    // Gentle scale bounce when streak increments
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.96), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.96, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic));

    // Number count-up animation
    _numberController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
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
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) return;
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

    final targetStreak = streak.currentStreak;
    if (_displayedStreak != targetStreak && !streak.justIncremented) {
      _displayedStreak = targetStreak;
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        HapticFeedback.selectionClick();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: _isPressed ? 0.94 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutCubic,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: OledTheme.cardElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: OledTheme.amber.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.transparent,
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  LucideIcons.flame,
                  size: 19,
                  color: OledTheme.amber,
                ),
                const SizedBox(width: 6),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: OledTheme.amber,
                        letterSpacing: -0.2,
                        height: 1.1,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
