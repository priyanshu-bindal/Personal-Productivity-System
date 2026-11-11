import 'dart:async';
import 'package:flutter/material.dart';
import '../animation/tab_activation_scope.dart';
import '../theme/app_colors.dart';

class AnimatedCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? border;
  final int index;
  final bool animateEntrance;

  const AnimatedCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.index = 0,
    this.animateEntrance = true,
  });

  @override
  State<AnimatedCard> createState() => AnimatedCardState();
}

class AnimatedCardState extends State<AnimatedCard>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @visibleForTesting
  AnimationController? get controller => _controller;

  late final Animation<double> _curvedAnim;
  Timer? _staggerTimer;
  int? _lastTick;
  bool _hasStandaloneRun = false;

  @override
  void initState() {
    super.initState();
    if (widget.animateEntrance) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 260),
      );
      _curvedAnim = CurvedAnimation(
        parent: _controller!,
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.animateEntrance || _controller == null) return;

    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (disableAnimations) {
      _staggerTimer?.cancel();
      _staggerTimer = null;
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
          _playEntrance();
        }
      } else {
        // Tab became inactive: cancel pending timer and reset controller
        _staggerTimer?.cancel();
        _staggerTimer = null;
        if (_controller!.isAnimating) {
          _controller!.stop();
        }
        _controller!.value = 0.0;
      }
    } else {
      // Standalone or un-scoped context (e.g. modal sheets or isolated widget tests)
      if (!_hasStandaloneRun) {
        _hasStandaloneRun = true;
        _playEntrance();
      }
    }
  }

  void _playEntrance() {
    _staggerTimer?.cancel();
    _staggerTimer = null;
    if (_controller == null) return;

    final delayMs = (widget.index * 28).clamp(0, 160);
    _controller!.value = 0.0;

    if (delayMs > 0) {
      _staggerTimer = Timer(Duration(milliseconds: delayMs), () {
        if (mounted && _controller != null) {
          _controller!.forward(from: 0.0);
        }
      });
    } else {
      _controller!.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _staggerTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMargin = widget.margin ?? const EdgeInsets.only(bottom: 12);
    final effectivePadding = widget.padding ?? const EdgeInsets.all(16);
    final baseBgColor = widget.backgroundColor ?? AppColors.card;
    final baseBorder = widget.border ?? Border.all(color: AppColors.border, width: 1);

    Widget card = _PressableCard(
      padding: effectivePadding,
      backgroundColor: baseBgColor,
      border: baseBorder,
      onTap: widget.onTap,
      child: widget.child,
    );

    if (_controller != null) {
      card = AnimatedBuilder(
        animation: _curvedAnim,
        builder: (context, childWidget) {
          final t = _curvedAnim.value;
          final opacity = t.clamp(0.0, 1.0);
          final translateY = 12.0 * (1.0 - t);
          final scale = 0.98 + 0.02 * t;

          return Transform.translate(
            offset: Offset(0, translateY),
            child: Transform.scale(
              scale: scale,
              child: Opacity(
                opacity: opacity,
                child: childWidget,
              ),
            ),
          );
        },
        child: card,
      );
    }

    return Padding(
      padding: effectiveMargin,
      child: card,
    );
  }
}

class _PressableCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color backgroundColor;
  final Border border;
  final VoidCallback? onTap;

  const _PressableCard({
    required this.child,
    required this.padding,
    required this.backgroundColor,
    required this.border,
    this.onTap,
  });

  @override
  State<_PressableCard> createState() => _PressableCardState();
}

class _PressableCardState extends State<_PressableCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final pressedBg = Color.alphaBlend(
      AppColors.primary.withValues(alpha: 0.07),
      widget.backgroundColor,
    );

    Widget content = AnimatedScale(
      scale: _isPressed ? 0.98 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        padding: widget.padding,
        decoration: BoxDecoration(
          color: _isPressed ? pressedBg : widget.backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: _isPressed
              ? Border.all(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  width: 1.2,
                )
              : widget.border,
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: Colors.transparent,
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: widget.child,
      ),
    );

    if (widget.onTap != null) {
      return GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: content,
      );
    }

    return content;
  }
}
