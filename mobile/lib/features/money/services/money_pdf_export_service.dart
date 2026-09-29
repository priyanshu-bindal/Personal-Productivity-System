import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../../models/expense.dart';
import '../models/expense_filter_state.dart';

/// Exception thrown when generating the Money PDF fails.
class MoneyPdfGenerationException implements Exception {
  final dynamic cause;
  MoneyPdfGenerationException(this.cause);
  @override
  String toString() => 'Unable to generate financial report PDF: $cause';
}

/// Dedicated, professional PDF report generator for FocusFlow Money.
///
/// Features:
/// - Financial summary cards (Total Spending, Transactions, Daily Avg, Top Category, Largest Expense)
/// - Category breakdown table with percentages
/// - Daily spending trend table
/// - Paginated transactions table with repeating headers
/// - Robust currency formatting
/// - Cross-platform sharing via [share_plus] + [path_provider]
class MoneyPdfExportService {
  // Palette (Clean executive light financial theme)
  static const PdfColor primaryNavy = PdfColor.fromInt(0xFF0B1222);
  static const PdfColor brandBlue = PdfColor.fromInt(0xFF2F6BFF);
  static const PdfColor borderGray = PdfColor.fromInt(0xFFD2D6DC);
  static const PdfColor textDark = PdfColor.fromInt(0xFF1E293B);
  static const PdfColor textMuted = PdfColor.fromInt(0xFF64748B);
  static const PdfColor tableHeaderBg = PdfColor.fromInt(0xFFF1F5F9);
  static const PdfColor tableAlternateBg = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor cardBg = PdfColor.fromInt(0xFFF8FAFC);

  /// Generates the financial report PDF and opens the system share sheet.
  static Future<void> exportAndShareReport({
    required List<Expense> expenses,
    required ExpenseFilterState filterState,
  }) async {
    try {
      final pdf = pw.Document(
        title: 'FocusFlow Money Report',
        author: 'FocusFlow',
      );

      // Attempt to load Inter font for Unicode support; fall back to standard Helvetica
      pw.Font? regularFont;
      pw.Font? boldFont;
      String currencySymbol = 'Rs. ';

      try {
        regularFont = await PdfGoogleFonts.interRegular();
        boldFont = await PdfGoogleFonts.interBold();
        currencySymbol = '₹';
      } catch (_) {
        // Offline or test environment fallback
        regularFont = null;
        boldFont = null;
        currencySymbol = 'Rs. ';
      }

      final currencyFormat = NumberFormat.currency(
        symbol: '$currencySymbol ',
        decimalDigits: 2,
      );

      final compactCurrencyFormat = NumberFormat.currency(
        symbol: currencySymbol,
        decimalDigits: 0,
      );

      final exportDate =
          DateFormat('MMMM d, yyyy • h:mm a').format(DateTime.now());
      final reportingPeriod = filterState.getReportingPeriod(expenses);

      // ── Calculate Summary Metrics ──────────────────────────────────────
      double totalSpend = 0.0;
      double largestExpenseAmount = 0.0;
      String largestExpenseDesc = 'None';
      final Map<String, double> categorySums = {};
      final Map<String, double> dailySums = {};

      for (final e in expenses) {
        totalSpend += e.amount;
        if (e.amount > largestExpenseAmount) {
          largestExpenseAmount = e.amount;
          largestExpenseDesc = e.description;
        }
        categorySums[e.category] = (categorySums[e.category] ?? 0.0) + e.amount;
        dailySums[e.expenseDate] = (dailySums[e.expenseDate] ?? 0.0) + e.amount;
      }

      final transactionCount = expenses.length;

      // Calculate days in period for daily average
      int daysInPeriod = dailySums.isNotEmpty ? dailySums.length : 1;
      final avgDaily = totalSpend / (daysInPeriod > 0 ? daysInPeriod : 1);

      // Top category
      String topCategoryName = 'None';
      double topCategoryAmount = 0.0;
      categorySums.forEach((cat, amt) {
        if (amt > topCategoryAmount) {
          topCategoryAmount = amt;
          topCategoryName = cat.isNotEmpty
              ? cat[0].toUpperCase() + cat.substring(1)
              : 'None';
        }
      });

      // Category breakdown sorted descending
      final sortedCategories = categorySums.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Daily trend sorted chronologically
      final sortedDailyEntries = dailySums.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      // ── Build Document ────────────────────────────────────────────────
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          theme: regularFont != null && boldFont != null
              ? pw.ThemeData.withFont(base: regularFont, bold: boldFont)
              : null,
          header: (context) => pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 14),
            padding: const pw.EdgeInsets.only(bottom: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: borderGray, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'FocusFlow — Financial & Spending Report',
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: textMuted,
                  ),
                ),
                pw.Text(
                  exportDate,
                  style: const pw.TextStyle(fontSize: 8.5, color: textMuted),
                ),
              ],
            ),
          ),
          footer: (context) => pw.Container(
            margin: const pw.EdgeInsets.only(top: 14),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: borderGray, width: 0.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Confidential • FocusFlow Personal Finance',
                  style: const pw.TextStyle(fontSize: 8, color: textMuted),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: textMuted),
                ),
              ],
            ),
          ),
          build: (context) => [
            // ── 1. Document Hero Header ─────────────────────────────────
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: primaryNavy,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'FocusFlow — Money Report',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Reporting period: $reportingPeriod',
                        style: const pw.TextStyle(
                          color: PdfColor.fromInt(0xFF93C5FD),
                          fontSize: 10,
                        ),
                      ),
                      if (filterState.hasActiveFilters) ...[
                        pw.SizedBox(height: 3),
                        pw.Text(
                          'Filters applied: ${_buildActiveFiltersString(filterState)}',
                          style: const pw.TextStyle(
                            color: PdfColor.fromInt(0xFFCBD5E1),
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: brandBlue,
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Text(
                      '$transactionCount Transactions',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 18),

            // ── 2. Executive Financial Summary Cards Strip ──────────────
            pw.Row(
              children: [
                _buildSummaryMetricBox(
                  title: 'Total Spending',
                  value: currencyFormat.format(totalSpend),
                  accentColor: brandBlue,
                ),
                pw.SizedBox(width: 8),
                _buildSummaryMetricBox(
                  title: 'Daily Average',
                  value: compactCurrencyFormat.format(avgDaily),
                  accentColor: const PdfColor.fromInt(0xFF059669),
                ),
                pw.SizedBox(width: 8),
                _buildSummaryMetricBox(
                  title: 'Top Category',
                  value: topCategoryName,
                  subtitle: compactCurrencyFormat.format(topCategoryAmount),
                  accentColor: const PdfColor.fromInt(0xFFD97706),
                ),
                pw.SizedBox(width: 8),
                _buildSummaryMetricBox(
                  title: 'Largest Expense',
                  value: compactCurrencyFormat.format(largestExpenseAmount),
                  subtitle: largestExpenseDesc,
                  accentColor: const PdfColor.fromInt(0xFFDC2626),
                ),
              ],
            ),
            pw.SizedBox(height: 20),

            // ── 3. Category Breakdown Table ─────────────────────────────
            _buildSectionHeader('Category Breakdown'),
            pw.SizedBox(height: 8),
            if (sortedCategories.isEmpty)
              _buildEmptyState('No category spending recorded for this period.')
            else
              pw.Table(
                border: pw.TableBorder.all(color: borderGray, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: tableHeaderBg),
                    children: [
                      _buildTableCell('Category', isHeader: true),
                      _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                      _buildTableCell('% of Total', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  ...sortedCategories.map((entry) {
                    final catName = entry.key[0].toUpperCase() + entry.key.substring(1);
                    final pct = totalSpend > 0 ? (entry.value / totalSpend * 100) : 0.0;
                    return pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.white),
                      children: [
                        _buildTableCell(catName),
                        _buildTableCell(currencyFormat.format(entry.value),
                            align: pw.TextAlign.right),
                        _buildTableCell('${pct.toStringAsFixed(1)}%',
                            align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
            pw.SizedBox(height: 20),

            // ── 4. Daily Spending Trend ─────────────────────────────────
            if (sortedDailyEntries.isNotEmpty && sortedDailyEntries.length <= 31) ...[
              _buildSectionHeader('Spending Trend (${sortedDailyEntries.length} Active Days)'),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: borderGray, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(2),
                  2: pw.FlexColumnWidth(3),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: tableHeaderBg),
                    children: [
                      _buildTableCell('Date', isHeader: true),
                      _buildTableCell('Day', isHeader: true),
                      _buildTableCell('Daily Total', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  ...sortedDailyEntries.map((entry) {
                    String dayLabel = '-';
                    try {
                      final parsed = DateTime.parse(entry.key);
                      dayLabel = DateFormat('EEEE').format(parsed);
                    } catch (_) {}
                    return pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.white),
                      children: [
                        _buildTableCell(entry.key),
                        _buildTableCell(dayLabel),
                        _buildTableCell(currencyFormat.format(entry.value),
                            align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 20),
            ],

            // ── 5. Detailed Transactions Table (With repeating header) ──
            _buildSectionHeader('Transactions ($transactionCount)'),
            pw.SizedBox(height: 8),
            if (expenses.isEmpty)
              _buildEmptyState('No transactions match the selected filters.')
            else
              pw.Table(
                border: pw.TableBorder.all(color: borderGray, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(1.8),
                  1: pw.FlexColumnWidth(3.4),
                  2: pw.FlexColumnWidth(1.8),
                  3: pw.FlexColumnWidth(1.8),
                  4: pw.FlexColumnWidth(2.0),
                },
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: tableHeaderBg),
                    children: [
                      _buildTableCell('Date', isHeader: true),
                      _buildTableCell('Description', isHeader: true),
                      _buildTableCell('Category', isHeader: true),
                      _buildTableCell('Method', isHeader: true),
                      _buildTableCell('Amount', isHeader: true, align: pw.TextAlign.right),
                    ],
                  ),
                  ...expenses.asMap().entries.map((entry) {
                    final e = entry.value;
                    final isEven = entry.key % 2 == 0;
                    final catName = e.category.isNotEmpty
                        ? e.category[0].toUpperCase() + e.category.substring(1)
                        : '-';
                    final method = _formatPaymentMethod(e.paymentMethod);

                    return pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: isEven ? PdfColors.white : tableAlternateBg,
                      ),
                      children: [
                        _buildTableCell(e.expenseDate),
                        _buildTableCell(e.description),
                        _buildTableCell(catName),
                        _buildTableCell(method),
                        _buildTableCell(currencyFormat.format(e.amount),
                            align: pw.TextAlign.right,
                            isBold: true),
                      ],
                    );
                  }),
                ],
              ),
          ],
        ),
      );

      // Save PDF to temp directory
      final bytes = await pdf.save();
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${tempDir.path}/FocusFlow_Money_Report_$dateStr.pdf');
      await file.writeAsBytes(bytes);

      // Share via cross-platform share_plus
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'FocusFlow Money Report - $reportingPeriod',
          text: 'FocusFlow Personal Finance Report ($reportingPeriod)',
        ),
      );
    } catch (e) {
      throw MoneyPdfGenerationException(e);
    }
  }

  static pw.Widget _buildSummaryMetricBox({
    required String title,
    required String value,
    String? subtitle,
    required PdfColor accentColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: pw.BoxDecoration(
          color: cardBg,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: borderGray, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 7.5,
                color: textMuted,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              maxLines: 1,
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
            ),
            if (subtitle != null) ...[
              pw.SizedBox(height: 2),
              pw.Text(
                subtitle,
                maxLines: 1,
                style: const pw.TextStyle(
                  fontSize: 7.5,
                  color: textDark,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 4),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: brandBlue, width: 1.5),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: pw.FontWeight.bold,
          color: primaryNavy,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isHeader = false,
    bool isBold = false,
    pw.TextAlign align = pw.TextAlign.left,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: pw.Text(
        text,
        textAlign: align,
        maxLines: 2,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight: isHeader || isBold
              ? pw.FontWeight.bold
              : pw.FontWeight.normal,
          color: isHeader ? primaryNavy : textDark,
        ),
      ),
    );
  }

  static pw.Widget _buildEmptyState(String message) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: tableAlternateBg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: borderGray, width: 0.5),
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        message,
        style: pw.TextStyle(
          fontSize: 8.5,
          color: textMuted,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  static String _buildActiveFiltersString(ExpenseFilterState state) {
    final parts = <String>[];
    if (state.category != null && state.category != 'all') {
      parts.add('Category: ${state.category}');
    }
    if (state.paymentMethod != null && state.paymentMethod != 'all') {
      parts.add('Method: ${_formatPaymentMethod(state.paymentMethod!)}');
    }
    if (state.amountRange != AmountFilterRange.all) {
      parts.add('Amount: ${state.amountFilterLabel}');
    }
    return parts.join(' • ');
  }

  static String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case 'upi':
        return 'UPI';
      case 'cash':
        return 'Cash';
      case 'debit_card':
        return 'Debit Card';
      case 'credit_card':
        return 'Credit Card';
      case 'bank_transfer':
        return 'Bank Transfer';
      default:
        return 'Other';
    }
  }
}
