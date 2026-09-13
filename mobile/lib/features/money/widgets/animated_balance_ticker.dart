import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AnimatedBalanceTicker extends StatefulWidget {
  final double amount;
  final TextStyle? style;
  final Duration duration;
  final Curve curve;
  final bool animateInitial;

  const AnimatedBalanceTicker({
    super.key,
    required this.amount,
    this.style,
    this.duration = const Duration(milliseconds: 550),
    this.curve = Curves.easeOutCubic,
    this.animateInitial = true,
  });

  @override
  State<AnimatedBalanceTicker> createState() => _AnimatedBalanceTickerState();
}

class _AnimatedBalanceTickerState extends State<AnimatedBalanceTicker> {
  late double _previousAmount;
  late final NumberFormat _formatter;
  bool _isFirstBuild = true;

  @override
  void initState() {
    super.initState();
    _formatter = NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 0,
      locale: 'en_IN',
    );
    _previousAmount = widget.animateInitial ? 0.0 : widget.amount;
  }

  @override
  void didUpdateWidget(covariant AnimatedBalanceTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.amount != widget.amount) {
      _previousAmount = oldWidget.amount;
      _isFirstBuild = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final startVal = _isFirstBuild && widget.animateInitial ? 0.0 : _previousAmount;
    final endVal = widget.amount;

    return TweenAnimationBuilder<double>(
      key: ValueKey('ticker_${startVal}_$endVal'),
      tween: Tween<double>(begin: startVal, end: endVal),
      duration: widget.duration,
      curve: widget.curve,
      builder: (context, value, child) {
        return Text(
          _formatter.format(value.round()),
          style: (widget.style ??
                  const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ))
              .copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        );
      },
    );
  }
}
