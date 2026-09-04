import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TrafficLoader extends StatefulWidget {
  final double size;
  final String? message;

  const TrafficLoader({
    super.key,
    this.size = 12.0,
    this.message,
  });

  @override
  State<TrafficLoader> createState() => _TrafficLoaderState();
}

class _TrafficLoaderState extends State<TrafficLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = [
      AppColors.primary,
      AppColors.accentAmber,
      AppColors.secondary,
    ];

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final delay = index * 0.2;
                double value = (_controller.value - delay) % 1.0;
                if (value < 0) value += 1.0;

                final scale = 0.6 + 0.4 * (1.0 - (value * 2 - 1.0).abs());
                final opacity = 0.3 + 0.7 * (1.0 - (value * 2 - 1.0).abs());

                return Container(
                  margin: EdgeInsets.symmetric(horizontal: widget.size * 0.4),
                  width: widget.size,
                  height: widget.size,
                  transform: Matrix4.diagonal3Values(scale, scale, 1.0),
                  transformAlignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors[index].withValues(alpha: opacity),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors[index].withValues(alpha: opacity * 0.5),
                        blurRadius: widget.size * 0.8,
                        spreadRadius: widget.size * 0.2,
                      ),
                    ],
                  ),
                );
              }),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 16),
          Text(
            widget.message!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]
      ],
    );
  }
}

class FullScreenLoader extends StatelessWidget {
  final String? message;

  const FullScreenLoader({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: TrafficLoader(size: 14.0, message: message),
      ),
    );
  }
}
