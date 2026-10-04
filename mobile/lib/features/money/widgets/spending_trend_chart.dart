import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models/expense.dart';
import '../../../providers/money_provider.dart';

// ─── Period enum ────────────────────────────────────────────────────────────

enum _TrendPeriod {
  week('7D', 7),
  month('1M', 30),
  threeMonths('3M', 90),
  year('1Y', 365);

  final String label;
  final int days;
  const _TrendPeriod(this.label, this.days);
}

// ─── Data point ──────────────────────────────────────────────────────────────

class _ChartPoint {
  final String label;   // x-axis label
  final String tooltip; // full tooltip label (date/week/month)
  final double amount;
  _ChartPoint(this.label, this.tooltip, this.amount);
}

// ─── Main widget ─────────────────────────────────────────────────────────────

class SpendingTrendChart extends ConsumerStatefulWidget {
  const SpendingTrendChart({super.key});

  @override
  ConsumerState<SpendingTrendChart> createState() => _SpendingTrendChartState();
}

class _SpendingTrendChartState extends ConsumerState<SpendingTrendChart>
    with TickerProviderStateMixin {
  _TrendPeriod _period = _TrendPeriod.week;

  // Line-draw entrance animation
  late AnimationController _lineController;
  late Animation<double> _lineAnim;

  // Tooltip state
  int? _selectedIndex;

  // Track previous expense count so we re-animate on new data
  int _lastExpenseCount = -1;

  @override
  void initState() {
    super.initState();

    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _lineAnim = CurvedAnimation(
      parent: _lineController,
      curve: Curves.easeOutCubic,
    );

    // Defer first play to after the first frame so fl_chart is laid out
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _lineController.forward();
    });
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  // ─── Data computation ────────────────────────────────────────────────────

  List<_ChartPoint> _computePoints(List<Expense> expenses) {
    final now = DateTime.now();

    switch (_period) {
      case _TrendPeriod.week:
        return _dailyPoints(expenses, now, 7, DateFormat('E'));

      case _TrendPeriod.month:
        return _dailyPoints(expenses, now, 30, DateFormat('d'));

      case _TrendPeriod.threeMonths:
        return _weeklyPoints(expenses, now, 12);

      case _TrendPeriod.year:
        return _monthlyPoints(expenses, now, 12);
    }
  }

  List<_ChartPoint> _dailyPoints(
    List<Expense> expenses,
    DateTime now,
    int count,
    DateFormat fmt,
  ) {
    final totals = <String, double>{};
    for (final e in expenses) {
      totals[e.expenseDate] = (totals[e.expenseDate] ?? 0) + e.amount;
    }
    final points = <_ChartPoint>[];
    for (int i = count - 1; i >= 0; i--) {
      final d = now.subtract(Duration(days: i));
      final key = DateFormat('yyyy-MM-dd').format(d);
      points.add(_ChartPoint(
        fmt.format(d),
        DateFormat('d MMM').format(d),
        totals[key] ?? 0.0,
      ));
    }
    return points;
  }

  List<_ChartPoint> _weeklyPoints(
      List<Expense> expenses, DateTime now, int weeks) {
    final points = <_ChartPoint>[];
    for (int w = weeks - 1; w >= 0; w--) {
      final weekEnd = now.subtract(Duration(days: w * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      double total = 0;
      for (final e in expenses) {
        final d = DateTime.parse(e.expenseDate);
        if (!d.isBefore(weekStart) && !d.isAfter(weekEnd)) {
          total += e.amount;
        }
      }
      points.add(_ChartPoint(
        DateFormat('d/M').format(weekStart),
        'Week of ${DateFormat('d MMM').format(weekStart)}',
        total,
      ));
    }
    return points;
  }

  List<_ChartPoint> _monthlyPoints(
      List<Expense> expenses, DateTime now, int months) {
    final points = <_ChartPoint>[];
    for (int m = months - 1; m >= 0; m--) {
      final month = DateTime(now.year, now.month - m, 1);
      final prefix = DateFormat('yyyy-MM').format(month);
      double total = 0;
      for (final e in expenses) {
        if (e.expenseDate.startsWith(prefix)) total += e.amount;
      }
      points.add(_ChartPoint(
        DateFormat('MMM').format(month),
        DateFormat('MMMM yyyy').format(month),
        total,
      ));
    }
    return points;
  }

  // ─── Period change ────────────────────────────────────────────────────────

  void _selectPeriod(_TrendPeriod p) {
    if (p == _period) return;
    setState(() {
      _period = p;
      _selectedIndex = null;
    });
    _lineController
      ..reset()
      ..forward();
  }

  // ─── Formatting ───────────────────────────────────────────────────────────

  String _formatAmount(double v) =>
      '₹${NumberFormat('#,##,###').format(v.round())}';

  String _formatAxisAmount(double v) {
    if (v >= 100000) return '₹${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '₹${(v / 1000).toStringAsFixed(0)}K';
    return '₹${v.round()}';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final expensesAsync = ref.watch(expensesProvider);
    final expenses = expensesAsync.value ?? [];

    // Re-trigger entrance animation when new expenses arrive
    if (expenses.length != _lastExpenseCount && _lastExpenseCount != -1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _lineController
            ..reset()
            ..forward();
        }
      });
    }
    _lastExpenseCount = expenses.length;

    final points = _computePoints(expenses);
    final hasData = points.any((p) => p.amount > 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(points, hasData),
        const SizedBox(height: 10),
        _buildChartCard(points, hasData),
      ],
    );
  }

  Widget _buildHeader(List<_ChartPoint> points, bool hasData) {
    // Compute total for selected period to show in header
    final total = points.fold(0.0, (s, p) => s + p.amount);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SPENDING TREND',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDim,
                  letterSpacing: 1.1,
                ),
              ),
              if (hasData) ...[
                const SizedBox(height: 2),
                Text(
                  _formatAmount(total),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(
          width: 128,
          child: _PeriodSelector(
            selected: _period,
            onSelect: _selectPeriod,
          ),
        ),
      ],
    );
  }

  Widget _buildChartCard(List<_ChartPoint> points, bool hasData) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060D1A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF1A2D4A),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF168BFF).withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
          const BoxShadow(
            color: Color(0x28000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: hasData
            ? _buildChart(points)
            : _buildEmptyState(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 230,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF168BFF).withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFF168BFF).withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.show_chart_rounded,
              color: Color(0xFF168BFF),
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No spending data yet',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your spending trend will appear here\nas you add expenses.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textDim,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(List<_ChartPoint> points) {
    final maxY = points.fold(0.0, (m, p) => math.max(m, p.amount));
    final chartMaxY = maxY > 0 ? maxY * 1.30 : 100.0;

    // Decide how many x-axis labels to show (avoid overlap)
    final labelInterval = _xLabelInterval(points.length);

    return AnimatedBuilder(
      animation: _lineAnim,
      builder: (context, _) {
        final animValue = _lineAnim.value;

        // Build animated spots
        final spots = <FlSpot>[];
        final n = points.length;
        for (int i = 0; i < n; i++) {
          final rawAmt = points[i].amount;
          final segStart = n > 1 ? (i / (n - 0.5)) * 0.65 : 0.0;
          final segProgress =
              ((animValue - segStart) / 0.35).clamp(0.0, 1.0);
          final curved = Curves.easeOutCubic.transform(segProgress);
          spots.add(FlSpot(i.toDouble(), rawAmt * curved));
        }

        return GestureDetector(
          // Allow tap-to-dismiss tooltip
          onTap: () => setState(() => _selectedIndex = null),
          child: Container(
            height: 240,
            padding: const EdgeInsets.fromLTRB(0, 20, 12, 4),
            child: LineChart(
              duration: Duration.zero,
              LineChartData(
                minY: 0,
                maxY: chartMaxY,
                clipData: const FlClipData.all(),

                // ── Grid ──────────────────────────────────────────────
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: chartMaxY / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: const Color(0xFF1A2D4A).withValues(alpha: 0.9),
                    strokeWidth: 0.7,
                    dashArray: [3, 8],
                  ),
                ),

                // ── Axes ──────────────────────────────────────────────
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 46,
                      interval: chartMaxY / 4,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Text(
                            _formatAxisAmount(value),
                            style: const TextStyle(
                              fontSize: 9,
                              color: Color(0xFF3D5470),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 26,
                      interval: labelInterval.toDouble(),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 ||
                            idx >= points.length ||
                            value != value.roundToDouble() ||
                            idx % labelInterval != 0) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            points[idx].label,
                            style: const TextStyle(
                              fontSize: 9.5,
                              color: Color(0xFF4C637A),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                borderData: FlBorderData(show: false),

                // ── Line ──────────────────────────────────────────────
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    color: const Color(0xFF168BFF),
                    barWidth: 2.2,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, pct, bar, index) {
                        final isSelected = index == _selectedIndex;
                        final segStart = points.length > 1
                            ? (index / (points.length - 0.5)) * 0.65
                            : 0.0;
                        final dotProgress =
                            ((animValue - segStart) / 0.35)
                                .clamp(0.0, 1.0);

                        if (isSelected) {
                          return _GlowDotPainter(
                            radius: 5.5,
                            color: const Color(0xFF168BFF),
                            glowColor: const Color(0xFF168BFF)
                                .withValues(alpha: 0.4),
                            strokeColor: const Color(0xFF060D1A),
                            strokeWidth: 1.8,
                          );
                        }
                        // Tiny dot that fades in with the line
                        return FlDotCirclePainter(
                          radius: 2.2 * dotProgress,
                          color: const Color(0xFF168BFF)
                              .withValues(alpha: 0.7 * dotProgress),
                          strokeWidth: 1.2,
                          strokeColor: const Color(0xFF060D1A),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF168BFF)
                              .withValues(alpha: 0.18 * animValue),
                          const Color(0xFF20D9FF)
                              .withValues(alpha: 0.04 * animValue),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.45, 1.0],
                      ),
                    ),
                  ),
                ],

                // ── Touch / tooltip ───────────────────────────────────
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchSpotThreshold: 24,
                  touchCallback: (event, response) {
                    if (event is FlTapUpEvent ||
                        event is FlPanUpdateEvent ||
                        event is FlLongPressMoveUpdate) {
                      final idx = response
                          ?.lineBarSpots?.first.x
                          .toInt();
                      if (idx != null &&
                          idx >= 0 &&
                          idx < points.length) {
                        if (_selectedIndex != idx) {
                          setState(() => _selectedIndex = idx);
                        }
                      }
                    }
                  },
                  getTouchedSpotIndicator: (barData, spotIndexes) {
                    return spotIndexes.map((i) {
                      return TouchedSpotIndicatorData(
                        FlLine(
                          color: const Color(0xFF168BFF)
                              .withValues(alpha: 0.35),
                          strokeWidth: 1.0,
                          dashArray: [3, 6],
                        ),
                        const FlDotData(show: false),
                      );
                    }).toList();
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => const Color(0xFF0C1A30),
                    tooltipRoundedRadius: 10,
                    tooltipBorder: const BorderSide(
                      color: Color(0x80168BFF),
                      width: 1,
                    ),
                    tooltipPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final idx = spot.x.toInt();
                        final pt = (idx >= 0 && idx < points.length)
                            ? points[idx]
                            : null;
                        if (pt == null) return null;
                        return LineTooltipItem(
                          '${pt.tooltip}\n',
                          const TextStyle(
                            color: Color(0xFF7BA4C4),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                          ),
                          children: [
                            TextSpan(
                              text: _formatAmount(pt.amount),
                              style: const TextStyle(
                                color: Color(0xFFE8F4FF),
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  int _xLabelInterval(int count) {
    if (count <= 7) return 1;
    if (count <= 14) return 2;
    if (count <= 30) return 5;
    return (count / 6).ceil();
  }
}

// ─── Period selector pill ─────────────────────────────────────────────────────

class _PeriodSelector extends StatefulWidget {
  final _TrendPeriod selected;
  final void Function(_TrendPeriod) onSelect;

  const _PeriodSelector({
    required this.selected,
    required this.onSelect,
  });

  @override
  State<_PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<_PeriodSelector>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<double> _slideAnim;
  int _fromIndex = 0;
  int _toIndex = 0;

  static const _periods = _TrendPeriod.values;

  @override
  void initState() {
    super.initState();
    _fromIndex = _toIndex = _periods.indexOf(widget.selected);
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 250));
    _slideAnim = CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic);
    _ac.value = 1.0;
  }

  @override
  void didUpdateWidget(_PeriodSelector old) {
    super.didUpdateWidget(old);
    final newIdx = _periods.indexOf(widget.selected);
    if (newIdx != _toIndex) {
      _fromIndex = _toIndex;
      _toIndex = newIdx;
      _ac
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final n = _periods.length;
      const pillH = 28.0;
      // Subtract border pixels (1px each side = 2px) so inner Row fits perfectly
      final availW = constraints.maxWidth.isFinite ? constraints.maxWidth : 128.0;
      final innerW = availW - 2.0;
      final pillW = (innerW / n).floorToDouble();
      final totalW = pillW * n + 2.0;

      return Container(
        width: totalW,
        height: pillH,
        decoration: BoxDecoration(
          color: const Color(0xFF080F1E),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFF1A2D4A)),
        ),
        child: AnimatedBuilder(
          animation: _slideAnim,
          builder: (context, child) {
            final x = (_fromIndex + (_toIndex - _fromIndex) * _slideAnim.value) * pillW;
            return Stack(
              children: [
                // Sliding highlight
                Positioned(
                  left: x,
                  top: 0,
                  width: pillW,
                  height: pillH,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0E4FA8), Color(0xFF0B3A7A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF168BFF).withValues(alpha: 0.35),
                          blurRadius: 8,
                          spreadRadius: -2,
                        ),
                      ],
                    ),
                  ),
                ),
                // Labels row
                Row(
                  children: _periods.asMap().entries.map((e) {
                    final isSelected = e.key == _toIndex;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onSelect(e.value),
                      child: SizedBox(
                        width: pillW,
                        height: pillH,
                        child: Center(
                          child: Text(
                            e.value.label,
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected
                                  ? const Color(0xFFE0EEFF)
                                  : const Color(0xFF3D5470),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      );
    });
  }
}

// ─── Custom glow dot painter ──────────────────────────────────────────────────

class _GlowDotPainter extends FlDotPainter {
  final double radius;
  final Color color;
  final Color glowColor;
  final Color strokeColor;
  final double strokeWidth;

  _GlowDotPainter({
    required this.radius,
    required this.color,
    required this.glowColor,
    required this.strokeColor,
    required this.strokeWidth,
  });

  @override
  void draw(Canvas canvas, FlSpot spot, Offset center) {
    // Outer glow ring
    final glowPaint = Paint()
      ..color = glowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(center, radius + 4, glowPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, strokePaint);

    // Fill
    final fillPaint = Paint()..color = color;
    canvas.drawCircle(center, radius - strokeWidth / 2, fillPaint);
  }

  @override
  Size getSize(FlSpot spot) => Size(radius * 4, radius * 4);

  @override
  FlDotPainter lerp(FlDotPainter a, FlDotPainter b, double t) => b;

  @override
  Color get mainColor => color;

  @override
  List<Object?> get props => [radius, color, glowColor, strokeColor, strokeWidth];
}
