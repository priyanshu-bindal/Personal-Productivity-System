import 'dart:async';
import 'package:flutter/material.dart';

/// Controller to trigger [AnimatedDelete] programmatically.
class AnimatedDeleteController {
  _AnimatedDeleteState? _state;

  void _attach(_AnimatedDeleteState state) => _state = state;
  void _detach() => _state = null;

  /// Starts the deletion collapse animation and subsequent callback.
  Future<void> delete() async {
    await _state?.triggerDelete();
  }

  /// Smoothly collapses the item (fade + scale + size transition).
  Future<void> collapse() async {
    await _state?.collapse();
  }

  /// Reverses the collapse animation if an operation failed.
  void reset() {
    _state?.reset();
  }
}

/// A wrapper widget that provides a smooth, premium collapse transition when an
/// item is deleted or removed, preventing abrupt visual disappearance in standard ListViews.
///
/// Animation steps:
/// 1. Enters deleting state (rejects further taps)
/// 2. Scale: 1.0 -> 0.97
/// 3. Opacity: 1.0 -> 0.0
/// 4. Height: full height -> 0 (via [SizeTransition])
/// 5. Calls [onDeleteConfirmed] once the animation completes (if provided)
class AnimatedDelete extends StatefulWidget {
  final Widget? child;
  final Widget Function(BuildContext context, VoidCallback startDelete)? builder;
  final FutureOr<void> Function()? onDeleteConfirmed;
  final AnimatedDeleteController? controller;
  final Duration duration;
  final Curve curve;
  final double scaleBegin;
  final double scaleEnd;

  const AnimatedDelete({
    super.key,
    required Widget this.child,
    this.onDeleteConfirmed,
    this.controller,
    this.duration = const Duration(milliseconds: 260),
    this.curve = Curves.easeOutCubic,
    this.scaleBegin = 1.0,
    this.scaleEnd = 0.97,
  }) : builder = null;

  const AnimatedDelete.builder({
    super.key,
    required Widget Function(BuildContext context, VoidCallback startDelete) this.builder,
    this.onDeleteConfirmed,
    this.controller,
    this.duration = const Duration(milliseconds: 260),
    this.curve = Curves.easeOutCubic,
    this.scaleBegin = 1.0,
    this.scaleEnd = 0.97,
  }) : child = null;

  /// Trigger deletion on the nearest enclosing [AnimatedDelete].
  static Future<void> trigger(BuildContext context) async {
    final state = context.findAncestorStateOfType<_AnimatedDeleteState>();
    if (state != null) {
      await state.triggerDelete();
    }
  }

  @override
  State<AnimatedDelete> createState() => _AnimatedDeleteState();
}

class _AnimatedDeleteState extends State<AnimatedDelete>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _sizeAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  bool _isDeleting = false;
  bool _hasTriggeredCallback = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(this);

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _sizeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: widget.curve),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: widget.scaleBegin, end: widget.scaleEnd).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void didUpdateWidget(covariant AnimatedDelete oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(this);
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _controller.dispose();
    super.dispose();
  }

  /// Collapses the item smoothly (fade + scale + size collapse).
  Future<void> collapse() async {
    if (!mounted) return;
    setState(() => _isDeleting = true);

    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!reduceMotion) {
      try {
        await _controller.forward().orCancel;
      } catch (_) {}
    } else {
      _controller.value = 1.0;
    }
  }

  /// Reverses the collapse animation if an operation failed.
  void reset() {
    if (!mounted) return;
    setState(() {
      _isDeleting = false;
      _hasTriggeredCallback = false;
    });
    _controller.reverse();
  }

  /// Triggers the collapse animation, then calls [widget.onDeleteConfirmed] (if provided).
  Future<void> triggerDelete() async {
    if (_isDeleting || _hasTriggeredCallback) return;

    if (!mounted) return;
    setState(() => _isDeleting = true);

    // Respect reduced motion accessibility
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (!reduceMotion) {
      try {
        await _controller.forward().orCancel;
      } catch (_) {
        // Handled if disposed during animation
      }
    } else {
      _controller.value = 1.0;
    }

    if (mounted && !_hasTriggeredCallback) {
      _hasTriggeredCallback = true;
      try {
        await widget.onDeleteConfirmed?.call();
      } catch (_) {
        // If the delete fails on provider side, reset visual state if still mounted
        if (mounted) {
          reset();
        }
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = widget.builder != null
        ? widget.builder!(context, () => triggerDelete())
        : widget.child!;

    return SizeTransition(
      sizeFactor: _sizeAnimation,
      axisAlignment: 0.0,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: IgnorePointer(
            ignoring: _isDeleting,
            child: content,
          ),
        ),
      ),
    );
  }
}
