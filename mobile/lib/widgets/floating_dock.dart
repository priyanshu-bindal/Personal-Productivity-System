import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One tab in the dock.
class DockItem {
  const DockItem({
    required this.icon,
    required this.label,
    this.badge = false,
    this.actionOnly = false,
  });

  final IconData icon;
  final String label;
  final bool badge;
  final bool actionOnly;
}

/// Floating glass dock (inspired by Aceternity UI's floating-dock).
///
/// Press anywhere on the dock and drag your finger left/right to switch tabs.
/// Icons magnify near the finger and a pill indicator follows it.
class FloatingDock extends StatefulWidget {
  const FloatingDock({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onChanged,
    this.switchWhileDragging = true,
    this.accentColor = const Color(0xFF3B82F6),
  }) : assert(items.length >= 2);

  final List<DockItem> items;
  final int currentIndex;
  final ValueChanged<int> onChanged;

  /// true  -> the tab changes live while the finger moves.
  /// false -> the tab changes only when the finger is lifted.
  final bool switchWhileDragging;

  final Color accentColor;

  @override
  State<FloatingDock> createState() => _FloatingDockState();
}

class _FloatingDockState extends State<FloatingDock> {
  static const double _defaultItemWidth = 64;
  static const double _padH = 8;
  static const double _height = 64;
  static const double _maxScale = 1.35;

  bool _pressed = false;
  bool _dragged = false;
  bool _startedOnCurrent = false;
  double _focusX = 0; // finger x, local to the dock
  int _hoverIndex = 0;
  int _startIndex = 0;

  int get _count => widget.items.length;

  double _itemWidth(double maxAvailable) {
    if (_count == 0) return _defaultItemWidth;
    final available = maxAvailable - _padH * 2;
    return math.min(_defaultItemWidth, math.max(48.0, available / _count));
  }

  double _dockWidth(double itemWidth) => _count * itemWidth + _padH * 2;

  double _centerOf(int i, double itemWidth) => _padH + itemWidth * (i + 0.5);

  int _indexAt(double x, double itemWidth) =>
      ((x - _padH) / itemWidth).floor().clamp(0, _count - 1);

  void _handleDown(Offset p, double itemWidth, double dockWidth) {
    final x = p.dx.clamp(_padH, dockWidth - _padH).toDouble();
    final index = _indexAt(x, itemWidth);
    _startIndex = index;
    _hoverIndex = index;
    _dragged = false;
    _startedOnCurrent = index == widget.currentIndex;
    setState(() {
      _pressed = true;
      _focusX = x;
    });
    if (index != widget.currentIndex) {
      HapticFeedback.selectionClick();
      if (widget.switchWhileDragging && !widget.items[index].actionOnly) {
        widget.onChanged(index);
      }
    }
  }

  void _handleMove(Offset p, double itemWidth, double dockWidth) {
    final x = p.dx.clamp(_padH, dockWidth - _padH).toDouble();
    final index = _indexAt(x, itemWidth);
    if (index != _startIndex) {
      _dragged = true;
    }
    setState(() {
      _pressed = true;
      _focusX = x;
    });
    if (index != _hoverIndex) {
      _hoverIndex = index;
      HapticFeedback.selectionClick();
      if (widget.switchWhileDragging && !widget.items[index].actionOnly) {
        widget.onChanged(index);
      }
    }
  }

  void _handleEnd() {
    if (!_pressed) return;
    if (widget.items[_hoverIndex].actionOnly) {
      widget.onChanged(_hoverIndex);
    } else if (!widget.switchWhileDragging &&
        _hoverIndex != widget.currentIndex) {
      widget.onChanged(_hoverIndex);
    } else if (!_dragged && _startedOnCurrent) {
      // Tap on the currently selected tab
      widget.onChanged(_hoverIndex);
    }
    setState(() => _pressed = false);
  }

  void _handleCancel() {
    if (!_pressed) return;
    setState(() => _pressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final moveDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 110);
    final fadeDuration =
        reduceMotion ? Duration.zero : const Duration(milliseconds: 180);

    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;

        // On small screens (< 360), reduce outer padding from 16 to 8 to avoid overflow
        final sideMargin = screenWidth < 360 ? 8.0 : 16.0;
        final availableWidth = screenWidth - sideMargin * 2;
        final itemWidth = _itemWidth(availableWidth);
        final dockWidth = _dockWidth(itemWidth);
        final pillWidth = math.min(56.0, itemWidth - 8);
        const pillHeight = 48.0;

        final highlighted = _pressed ? _hoverIndex : widget.currentIndex;
        final clampedCurrentIndex = widget.currentIndex.clamp(0, _count - 1);
        final targetX =
            _pressed ? _focusX : _centerOf(clampedCurrentIndex, itemWidth);

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(sideMargin, 0, sideMargin, 12),
            child: Align(
              alignment: Alignment.bottomCenter,
              heightFactor: 1,
              child: SizedBox(
                width: dockWidth,
                height: _height,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: (e) =>
                      _handleDown(e.localPosition, itemWidth, dockWidth),
                  onPointerMove: (e) =>
                      _handleMove(e.localPosition, itemWidth, dockWidth),
                  onPointerUp: (_) => _handleEnd(),
                  onPointerCancel: (_) => _handleCancel(),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(_height / 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(90),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(_height / 2),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0x99101624), // dark glass
                            borderRadius: BorderRadius.circular(_height / 2),
                            border: Border.all(color: const Color(0x1AFFFFFF)),
                          ),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween<double>(end: targetX),
                            duration: moveDuration,
                            curve: Curves.easeOutCubic,
                            builder: (context, fx, _) {
                              return TweenAnimationBuilder<double>(
                                tween: Tween<double>(end: _pressed ? 1.0 : 0.0),
                                duration: fadeDuration,
                                curve: Curves.easeOut,
                                builder: (context, strength, _) {
                                  final pillLeft = (fx - pillWidth / 2)
                                      .clamp(4.0, dockWidth - 4 - pillWidth)
                                      .toDouble();
                                  return Stack(
                                    children: [
                                      // Sliding indicator that follows the finger.
                                      Positioned(
                                        left: pillLeft,
                                        top: (_height - pillHeight) / 2,
                                        width: pillWidth,
                                        height: pillHeight,
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            color:
                                                widget.accentColor.withAlpha(46),
                                            borderRadius:
                                                BorderRadius.circular(24),
                                            border: Border.all(
                                              color: widget.accentColor
                                                  .withAlpha(89),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: widget.accentColor
                                                    .withAlpha(
                                                        (70 * strength).round()),
                                                blurRadius: 16,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: _padH),
                                        child: Row(
                                          children: [
                                            for (int i = 0; i < _count; i++)
                                              _buildItem(
                                                i: i,
                                                fx: fx,
                                                strength: strength,
                                                highlighted: highlighted,
                                                itemWidth: itemWidth,
                                                reduceMotion: reduceMotion,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildItem({
    required int i,
    required double fx,
    required double strength,
    required int highlighted,
    required double itemWidth,
    required bool reduceMotion,
  }) {
    final item = widget.items[i];
    final active = i == highlighted;

    // Gaussian falloff: the closer the finger, the bigger the icon.
    final d = (fx - _centerOf(i, itemWidth)) / (itemWidth * 0.85);
    final scale = reduceMotion
        ? 1.0
        : (1 + (_maxScale - 1) * strength * math.exp(-d * d));

    final color = active ? widget.accentColor : Colors.white.withAlpha(150);

    return SizedBox(
      width: itemWidth,
      height: _height,
      child: Semantics(
        button: true,
        selected: active,
        label: item.label,
        onTap: () => widget.onChanged(i),
        excludeSemantics: true,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.translate(
              offset: Offset(0, -(scale - 1) * 16),
              child: Transform.scale(
                scale: scale,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(item.icon, size: 24, color: color),
                    if (item.badge)
                      Positioned(
                        top: -1,
                        right: -3,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5252),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 10,
                height: 1.2,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
