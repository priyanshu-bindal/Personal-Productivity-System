import 'package:flutter/material.dart';

/// A reusable, production-quality animated number counter widget.
///
/// Features:
/// - Smooth [Curves.easeOutCubic] transition over 300–500ms
/// - Only animates when the numeric [value] changes (does not restart on unrelated rebuilds)
/// - Respects tabular figures to avoid character-width wobbling
/// - Supports customizable [prefix], [suffix], and [fractionDigits]
/// - Respects reduced motion accessibility settings
class AnimatedNumber extends StatefulWidget {
  final num value;
  final String? prefix;
  final String? suffix;
  final int fractionDigits;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final bool animateInitial;

  const AnimatedNumber({
    super.key,
    required this.value,
    this.prefix,
    this.suffix,
    this.fractionDigits = 0,
    this.style,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.easeOutCubic,
    this.animateInitial = false,
  });

  @override
  State<AnimatedNumber> createState() => _AnimatedNumberState();
}

class _AnimatedNumberState extends State<AnimatedNumber> {
  late double _previousValue;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    _previousValue = widget.animateInitial ? 0.0 : widget.value.toDouble();
  }

  @override
  void didUpdateWidget(covariant AnimatedNumber oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previousValue = oldWidget.value.toDouble();
      _isFirstBuild = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    final startVal = (_isFirstBuild && !widget.animateInitial)
        ? widget.value.toDouble()
        : _previousValue;
    final endVal = widget.value.toDouble();

    final defaultStyle = widget.style ?? const TextStyle();
    final effectiveStyle = defaultStyle.copyWith(
      fontFeatures: [
        ...?defaultStyle.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );

    if (reduceMotion || startVal == endVal) {
      final formatted = widget.fractionDigits == 0
          ? endVal.round().toString()
          : endVal.toStringAsFixed(widget.fractionDigits);
      return Text(
        '${widget.prefix ?? ""}$formatted${widget.suffix ?? ""}',
        style: effectiveStyle,
      );
    }

    return TweenAnimationBuilder<double>(
      key: ValueKey('anim_num_${startVal}_$endVal'),
      tween: Tween<double>(begin: startVal, end: endVal),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, val, child) {
        final formatted = widget.fractionDigits == 0
            ? val.round().toString()
            : val.toStringAsFixed(widget.fractionDigits);
        return Text(
          '${widget.prefix ?? ""}$formatted${widget.suffix ?? ""}',
          style: effectiveStyle,
        );
      },
    );
  }
}
