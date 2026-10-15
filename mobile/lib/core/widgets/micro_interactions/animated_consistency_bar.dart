import 'dart:async';
import 'package:flutter/material.dart';

import '../../animation/tab_activation_scope.dart';
import '../../theme/oled_theme.dart';

/// Animated consistency progress indicator for skill cards.
/// - Smooth 420 ms easeOutCubic fill animation from 0% to the target consistency value
/// - Coordinates with TabActivationScope and TabCardScope so it replays smoothly on tab visit
/// - Animates the percentage text in sync with the progress line
/// - Bypasses animation when MediaQuery.disableAnimations is active
/// - Zero repaint or controller overhead when resting
class AnimatedConsistencyBar extends StatefulWidget {
  final int percentage; // 0 to 100
  final Color accentColor;
  final int index;
  final int streakDays;
  final bool showStreak;

  const AnimatedConsistencyBar({
    super.key,
    required this.percentage,
    required this.accentColor,
    this.index = 0,
    this.streakDays = 0,
    this.showStreak = true,
  });

  @override
  State<AnimatedConsistencyBar> createState() => _AnimatedConsistencyBarState();
}

class _AnimatedConsistencyBarState extends State<AnimatedConsistencyBar>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late final Animation<double> _curvedAnim;
  Timer? _staggerTimer;
  int? _lastTick;
  bool _hasStandaloneRun = false;

  int _fromPercentage = 0;
  int _toPercentage = 0;

  @override
  void initState() {
    super.initState();
    _fromPercentage = 0;
    _toPercentage = widget.percentage;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _curvedAnim = CurvedAnimation(
      parent: _controller!,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void didUpdateWidget(AnimatedConsistencyBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      final disableAnimations =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (disableAnimations) {
        _fromPercentage = widget.percentage;
        _toPercentage = widget.percentage;
        _controller?.value = 1.0;
        return;
      }

      // Smoothly transition from current displayed value to new value without resetting to 0
      final animProgress = _controller?.value ?? 1.0;
      final currentPercentage = (_fromPercentage +
              ((_toPercentage - _fromPercentage) * animProgress))
          .round()
          .clamp(0, 100);

      _fromPercentage = currentPercentage;
      _toPercentage = widget.percentage;
      _controller?.forward(from: 0.0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller == null) return;

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      _staggerTimer?.cancel();
      _staggerTimer = null;
      _fromPercentage = widget.percentage;
      _toPercentage = widget.percentage;
      _controller!.value = 1.0;
      return;
    }

    final tabScope = TabCardScope.of(context);
    final activationScope = TabActivationScope.of(context);

    if (tabScope != null && activationScope != null) {
      final isCurrentTabActive = tabScope.tabIndex == activationScope.activeTabIndex;
      final currentTick = activationScope.activationTick;

      if (isCurrentTabActive) {
        if (_lastTick != currentTick) {
          _lastTick = currentTick;
          _playFill();
        }
      } else {
        _staggerTimer?.cancel();
        _staggerTimer = null;
        if (_controller!.isAnimating) {
          _controller!.stop();
        }
        _controller!.value = 0.0;
      }
    } else {
      if (!_hasStandaloneRun) {
        _hasStandaloneRun = true;
        _playFill();
      }
    }
  }

  void _playFill() {
    _staggerTimer?.cancel();
    _staggerTimer = null;
    if (_controller == null) return;

    _fromPercentage = 0;
    _toPercentage = widget.percentage;

    // Slight delay so the card itself begins fading/sliding in first
    final delayMs = 60 + (widget.index * 28).clamp(0, 160);
    _controller!.value = 0.0;

    _staggerTimer = Timer(Duration(milliseconds: delayMs), () {
      if (mounted && _controller != null) {
        _controller!.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _staggerTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Consistency label + Animated % on left, Streak on right
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Text(
                  'Consistency',
                  style: TextStyle(
                    color: OledTheme.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                AnimatedBuilder(
                  animation: _curvedAnim,
                  builder: (context, _) {
                    final t = _curvedAnim.value.clamp(0.0, 1.0);
                    final currentVal = (t >= 1.0)
                        ? widget.percentage
                        : (_fromPercentage +
                                ((_toPercentage - _fromPercentage) * t))
                            .round()
                            .clamp(0, 100);
                    return Text(
                      '$currentVal%',
                      style: const TextStyle(
                        color: OledTheme.textPrimary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    );
                  },
                ),
              ],
            ),
            if (widget.showStreak)
              Row(
                children: [
                  const Text('🔥 ', style: TextStyle(fontSize: 12)),
                  Text(
                    '${widget.streakDays} day streak',
                    style: const TextStyle(
                      color: OledTheme.amber,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Animated progress line
        AnimatedBuilder(
          animation: _curvedAnim,
          builder: (context, _) {
            final t = _curvedAnim.value.clamp(0.0, 1.0);
            final currentPct = (t >= 1.0)
                ? widget.percentage
                : (_fromPercentage +
                        ((_toPercentage - _fromPercentage) * t))
                    .clamp(0, 100);
            final fill = (currentPct / 100.0).clamp(0.0, 1.0);

            return ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 5,
                child: LinearProgressIndicator(
                  value: fill,
                  minHeight: 5,
                  backgroundColor: OledTheme.cardElevated,
                  valueColor: AlwaysStoppedAnimation<Color>(widget.accentColor),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
