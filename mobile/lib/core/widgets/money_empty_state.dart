import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class MoneyEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;
  final Color accentColor;
  final double minHeight;
  final bool showGrid;

  const MoneyEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.accentColor = AppColors.primary,
    this.minHeight = 180.0,
    this.showGrid = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: minHeight),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Faint Background Chart/Grid Lines
          if (showGrid)
            Positioned.fill(
              child: CustomPaint(
                painter: _FaintGridPainter(
                  gridColor: AppColors.border.withValues(alpha: 0.3),
                ),
              ),
            ),

          // Main Empty State Content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Subtle Circular Icon Container (48-56px) with Accent Glow
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withValues(alpha: 0.12),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.28),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.12),
                      blurRadius: 16,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 12),

              // Title
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyStrong.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),

              // Description Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  description,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySecondary.copyWith(
                    color: AppColors.textDim,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ),

              // Optional CTA
              if (action != null) ...[
                const SizedBox(height: 16),
                action!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _FaintGridPainter extends CustomPainter {
  final Color gridColor;

  _FaintGridPainter({required this.gridColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    const spacing = 20.0;

    // Horizontal faint grid lines
    for (double y = spacing; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Vertical faint grid lines
    for (double x = spacing; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
