import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/ocean_theme.dart';
import '../../../core/widgets/pressable_scale.dart';
import '../../../core/widgets/trash_confirmation_overlay.dart';
import '../../../models/expense.dart';
import '../models/expense_filter_state.dart';
import '../services/money_pdf_export_service.dart';

/// Compact export configuration modal bottom sheet.
class MoneyPdfExportDialog extends StatefulWidget {
  final List<Expense> expenses;
  final ExpenseFilterState filterState;

  const MoneyPdfExportDialog({
    super.key,
    required this.expenses,
    required this.filterState,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Expense> expenses,
    required ExpenseFilterState filterState,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => MoneyPdfExportDialog(
        expenses: expenses,
        filterState: filterState,
      ),
    );
  }

  @override
  State<MoneyPdfExportDialog> createState() => _MoneyPdfExportDialogState();
}

class _MoneyPdfExportDialogState extends State<MoneyPdfExportDialog> {
  static const Color _focusFlowBlue = Color(0xFF2F6BFF);
  static const Color _cardBg = Color(0xFF0E1526);
  static const Color _borderIdle = Color(0xFF1B2B48);
  static const Color _textDim = Color(0xFF7E93A8);

  bool _isExporting = false;

  Future<void> _handleExport() async {
    if (_isExporting) return;
    setState(() => _isExporting = true);

    try {
      await MoneyPdfExportService.exportAndShareReport(
        expenses: widget.expenses,
        filterState: widget.filterState,
      );
      if (mounted) {
        Navigator.of(context).pop();
        TrashConfirmationOverlay.showSuccess(
          context: context,
          message: 'Report exported successfully',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isExporting = false);
        TrashConfirmationOverlay.showError(
          context: context,
          message: 'Failed to generate PDF. Please try again.',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final periodString = widget.filterState.getReportingPeriod(widget.expenses);
    final count = widget.expenses.length;
    final totalSpend = widget.expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final currency = NumberFormat.currency(symbol: '₹', decimalDigits: 0, locale: 'en_IN');

    return Container(
      decoration: const BoxDecoration(
        color: OceanTheme.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: _borderIdle, width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Grabber
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _borderIdle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _focusFlowBlue.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            LucideIcons.fileText,
                            color: _focusFlowBlue,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Export Financial Report',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(LucideIcons.x, color: _textDim, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Report Configuration Preview Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _borderIdle),
                ),
                child: Column(
                  children: [
                    _buildInfoRow('REPORTING PERIOD', periodString),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: _borderIdle, height: 1),
                    ),
                    _buildInfoRow('MATCHING TRANSACTIONS', '$count expenses'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Divider(color: _borderIdle, height: 1),
                    ),
                    _buildInfoRow('TOTAL SPENDING', currency.format(totalSpend)),
                    if (widget.filterState.hasActiveFilters) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(color: _borderIdle, height: 1),
                      ),
                      _buildInfoRow(
                        'ACTIVE FILTERS',
                        '${widget.filterState.activeFilterCount} active filters applied',
                        isHighlighted: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Export CTA Button
              PressableScale(
                scaleFactor: 0.98,
                onTap: _isExporting ? null : _handleExport,
                child: Container(
                  height: 50,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: _focusFlowBlue,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: _focusFlowBlue.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                LucideIcons.download,
                                color: Colors.white,
                                size: 17,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Generate & Share PDF',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textDim,
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: isHighlighted ? const Color(0xFF93C5FD) : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
