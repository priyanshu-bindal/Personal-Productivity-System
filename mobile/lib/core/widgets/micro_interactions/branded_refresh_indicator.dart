import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/ocean_theme.dart';
import 'animated_checkmark.dart';

enum _RefreshState {
  idle,
  pulling,
  refreshing,
  completed,
  error,
}

/// FocusFlow-branded refresh indicator with premium micro-interactions:
/// - During pull: 0° -> 180° rotation corresponding to pull progress
/// - When triggered: continuous 360° smooth rotation loop during real async refresh
/// - When finished: displays `✓ Updated` briefly, then collapses naturally
/// - On error: displays appropriate error feedback without faking success
/// - Uses standard Flutter scroll notifications without custom gesture recognizers
class BrandedRefreshIndicator extends StatefulWidget {
  final Future<void> Function() onRefresh;
  final Widget child;
  final double threshold;
  final Color? color;
  final Color? backgroundColor;

  const BrandedRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.threshold = 72.0,
    this.color,
    this.backgroundColor,
  });

  @override
  State<BrandedRefreshIndicator> createState() => _BrandedRefreshIndicatorState();
}

class _BrandedRefreshIndicatorState extends State<BrandedRefreshIndicator>
    with TickerProviderStateMixin {
  _RefreshState _state = _RefreshState.idle;
  double _pullDistance = 0.0;

  late final AnimationController _spinController;
  late final AnimationController _heightController;
  late Animation<double> _heightAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _heightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _heightAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(_heightController);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (_state == _RefreshState.refreshing ||
        _state == _RefreshState.completed ||
        _state == _RefreshState.error) {
      return false;
    }

    if (notification is ScrollUpdateNotification) {
      if (notification.metrics.extentBefore == 0.0 &&
          notification.scrollDelta != null &&
          notification.scrollDelta! < 0) {
        setState(() {
          _pullDistance = (_pullDistance + -notification.scrollDelta!)
              .clamp(0.0, widget.threshold * 1.5);
          _state = _RefreshState.pulling;
        });
      } else if (notification.scrollDelta != null &&
          notification.scrollDelta! > 0 &&
          _pullDistance > 0) {
        setState(() {
          _pullDistance = (_pullDistance - notification.scrollDelta!)
              .clamp(0.0, widget.threshold * 1.5);
          if (_pullDistance == 0) _state = _RefreshState.idle;
        });
      }
    } else if (notification is OverscrollNotification) {
      if (notification.overscroll < 0) {
        setState(() {
          _pullDistance = (_pullDistance + -notification.overscroll)
              .clamp(0.0, widget.threshold * 1.5);
          _state = _RefreshState.pulling;
        });
      }
    } else if (notification is ScrollEndNotification) {
      if (_pullDistance >= widget.threshold && _state == _RefreshState.pulling) {
        _triggerRefresh();
      } else if (_pullDistance > 0 && _state == _RefreshState.pulling) {
        _collapse();
      }
    }

    return false;
  }

  Future<void> _triggerRefresh() async {
    setState(() {
      _state = _RefreshState.refreshing;
      _pullDistance = widget.threshold;
    });

    HapticFeedback.lightImpact();
    _spinController.repeat();

    try {
      await widget.onRefresh();

      if (!mounted) return;

      _spinController.stop();
      setState(() => _state = _RefreshState.completed);

      await Future.delayed(const Duration(milliseconds: 550));
    } catch (_) {
      if (!mounted) return;
      _spinController.stop();
      setState(() => _state = _RefreshState.error);
      await Future.delayed(const Duration(milliseconds: 650));
    } finally {
      if (mounted) {
        _collapse();
      }
    }
  }

  void _collapse() {
    _heightAnimation = Tween<double>(
      begin: _pullDistance,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _heightController,
      curve: Curves.easeOutCubic,
    ));

    _heightController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _pullDistance = 0.0;
          _state = _RefreshState.idle;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_pullDistance / widget.threshold).clamp(0.0, 1.0);
    final accentCol = widget.color ?? OceanTheme.primary;
    final bgCol = widget.backgroundColor ?? OceanTheme.card;

    final displayHeight = _heightController.isAnimating
        ? _heightAnimation.value
        : _pullDistance;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: Column(
        children: [
          ClipRect(
            child: SizedBox(
              height: displayHeight,
              child: Center(
                child: Opacity(
                  opacity: progress,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: bgCol,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _state == _RefreshState.error
                            ? AppColors.error.withValues(alpha: 0.5)
                            : accentCol.withValues(alpha: 0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: _buildIndicatorContent(progress, accentCol),
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }

  Widget _buildIndicatorContent(double progress, Color accentCol) {
    switch (_state) {
      case _RefreshState.completed:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedCheckmark(
              size: 16,
              color: accentCol,
              strokeWidth: 2.2,
            ),
            const SizedBox(width: 6),
            Text(
              'Updated',
              style: TextStyle(
                color: accentCol,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );

      case _RefreshState.error:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(LucideIcons.alertCircle, color: AppColors.error, size: 16),
            SizedBox(width: 6),
            Text(
              'Sync Failed',
              style: TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );

      case _RefreshState.refreshing:
        return RotationTransition(
          turns: _spinController,
          child: Icon(LucideIcons.refreshCw, color: accentCol, size: 18),
        );

      case _RefreshState.pulling:
      case _RefreshState.idle:
        // 0° -> 180° rotation corresponding to pull progress
        return Transform.rotate(
          angle: progress * 3.14159,
          child: Icon(
            LucideIcons.arrowDown,
            color: accentCol,
            size: 18,
          ),
        );
    }
  }
}
