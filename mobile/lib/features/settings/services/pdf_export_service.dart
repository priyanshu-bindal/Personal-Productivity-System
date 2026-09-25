import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../models/user_profile.dart';
import '../../../services/supabase_service.dart';

/// Exception thrown when generating the PDF fails.
class PdfGenerationException implements Exception {
  final dynamic cause;
  PdfGenerationException(this.cause);
  @override
  String toString() => 'Unable to export your data. Please try again.';
}

/// Exception thrown when the PDF is created but cannot be shared.
class PdfShareException implements Exception {
  final dynamic cause;
  PdfShareException(this.cause);
  @override
  String toString() => "PDF created, but it couldn't be shared.";
}

/// Professional PDF document generator for FocusFlow personal data export.
///
/// Uses [share_plus] + [path_provider] for cross-platform sharing:
/// - Android / iOS  → native system share sheet
/// - Windows / macOS / Linux → file save dialog / system share
/// - Web → browser file download
///
/// This avoids [Printing.sharePdf] which requires native Android/iOS
/// platform channels and throws MissingPluginException on desktop/web.
class PdfExportService {
  // ─── Color palette (light PDF — works well on white paper) ───────────────
  static const primaryNavy = PdfColor.fromInt(0xFF0B1222);
  static const accentTeal = PdfColor.fromInt(0xFF19BDB3);
  static const borderGray = PdfColor.fromInt(0xFFD2D6DC);
  static const textDark = PdfColor.fromInt(0xFF1E293B);
  static const textMuted = PdfColor.fromInt(0xFF64748B);
  static const tableHeaderBg = PdfColor.fromInt(0xFFF1F5F9);
  static const tableAlternateBg = PdfColor.fromInt(0xFFF8FAFC);

  /// Generates the personal data PDF and opens the system share/save UI.
  ///
  /// Throws if the user is not authenticated or PDF generation fails.
  /// Callers should handle exceptions and show user-friendly messages.
  static Future<void> exportAndShareData({
    required UserProfile? profile,
    required String? focusId,
  }) async {
    final userId = SupabaseService.currentUserId;
    if (userId == null) {
      throw Exception('User is not authenticated.');
    }

    final supabase = SupabaseService.client;

    final List<dynamic> results;
    try {
      // Fetch all user-owned records concurrently
      results = await Future.wait([
        supabase
            .from('skills')
            .select('name, category, level, progress, weekly_target')
            .eq('user_id', userId),
        supabase
            .from('learning_sessions')
            .select('duration_minutes, practiced_at, notes, skill_id')
            .eq('user_id', userId)
            .order('practiced_at', ascending: false)
            .limit(100),
        supabase
            .from('expenses')
            .select('amount, description, category, payment_method, expense_date')
            .eq('user_id', userId)
            .order('expense_date', ascending: false)
            .limit(100),
        supabase
            .from('budgets')
            .select('category, monthly_limit')
            .eq('user_id', userId),
        supabase
            .from('notes')
            .select('title, content, tags, created_at')
            .eq('user_id', userId)
            .order('created_at', ascending: false)
            .limit(50),
      ]);
    } catch (e) {
      throw PdfGenerationException(e);
    }

    final skills = List<Map<String, dynamic>>.from(results[0]);
    final sessions = List<Map<String, dynamic>>.from(results[1]);
    final expenses = List<Map<String, dynamic>>.from(results[2]);
    final budgets = List<Map<String, dynamic>>.from(results[3]);
    final notes = List<Map<String, dynamic>>.from(results[4]);

    final pdf = pw.Document(
      title: 'FocusFlow Personal Data Export',
      author: 'FocusFlow',
    );

    final exportDate =
        DateFormat('MMMM d, yyyy • h:mm a').format(DateTime.now());
    final currencyFormat =
        NumberFormat.currency(symbol: 'Rs. ', decimalDigits: 2);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                bottom: pw.BorderSide(color: borderGray, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'FocusFlow • Personal Records Report',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: textMuted,
                ),
              ),
              pw.Text(
                exportDate,
                style: const pw.TextStyle(fontSize: 9, color: textMuted),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 16),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border:
                pw.Border(top: pw.BorderSide(color: borderGray, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Confidential • FocusFlow User Data Export',
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
          // ── Document Hero Header ──────────────────────────────────────
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
                      'FocusFlow Personal Data Export',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Verified snapshot of all account records and metrics',
                      style: const pw.TextStyle(
                        color: accentTeal,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0x2219BDB3),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(
                    'FOCUS ID: #${focusId ?? "N/A"}',
                    style: pw.TextStyle(
                      color: accentTeal,
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // ── 1. Account Profile Summary ────────────────────────────────
          _buildSectionHeader('1. Account Profile Overview', accentTeal),
          pw.SizedBox(height: 8),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: borderGray, width: 0.8),
              borderRadius: pw.BorderRadius.circular(6),
            ),
            child: pw.Column(
              children: [
                _buildKeyValueRow(
                    'Full Name',
                    profile?.fullName.isNotEmpty == true
                        ? profile!.fullName
                        : 'FocusFlow User'),
                pw.Divider(color: borderGray, thickness: 0.5, height: 12),
                _buildKeyValueRow(
                    'Email Address', profile?.email ?? 'N/A'),
                pw.Divider(color: borderGray, thickness: 0.5, height: 12),
                _buildKeyValueRow('Focus ID', '#${focusId ?? "N/A"}'),
                pw.Divider(color: borderGray, thickness: 0.5, height: 12),
                _buildKeyValueRow('Current Practice Streak',
                    '${profile?.currentStreak ?? 0} days'),
                pw.Divider(color: borderGray, thickness: 0.5, height: 12),
                _buildKeyValueRow('Longest Practice Streak',
                    '${profile?.longestStreak ?? 0} days'),
                pw.Divider(color: borderGray, thickness: 0.5, height: 12),
                _buildKeyValueRow('Default Session Duration',
                    '${profile?.defaultSessionDuration ?? 60} minutes'),
                pw.Divider(color: borderGray, thickness: 0.5, height: 12),
                _buildKeyValueRow('Daily Reminders Enabled',
                    profile?.practiceReminders == true ? 'Yes' : 'No'),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // ── 2. Skills & Goals ─────────────────────────────────────────
          _buildSectionHeader(
              '2. Skills & Learning Objectives (${skills.length})',
              accentTeal),
          pw.SizedBox(height: 8),
          if (skills.isEmpty)
            _buildEmptyState('No skills currently recorded in profile.')
          else
            pw.Table(
              border: pw.TableBorder.all(color: borderGray, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(2),
                4: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: tableHeaderBg),
                  children: [
                    _buildTableCell('Skill Name', isHeader: true),
                    _buildTableCell('Category', isHeader: true),
                    _buildTableCell('Level', isHeader: true),
                    _buildTableCell('Progress', isHeader: true),
                    _buildTableCell('Target/Wk', isHeader: true),
                  ],
                ),
                ...skills.asMap().entries.map((entry) {
                  final s = entry.value;
                  final isEven = entry.key % 2 == 0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color:
                          isEven ? PdfColors.white : tableAlternateBg,
                    ),
                    children: [
                      _buildTableCell(s['name']?.toString() ?? '-'),
                      _buildTableCell(
                          s['category']?.toString() ?? '-'),
                      _buildTableCell(s['level']?.toString() ?? '-'),
                      _buildTableCell('${s['progress'] ?? 0}%'),
                      _buildTableCell(
                          '${s['weekly_target'] ?? 0} mins'),
                    ],
                  );
                }),
              ],
            ),

          pw.SizedBox(height: 24),

          // ── 3. Practice Sessions ──────────────────────────────────────
          _buildSectionHeader(
              '3. Focus & Practice Sessions Log (${sessions.length})',
              accentTeal),
          pw.SizedBox(height: 8),
          if (sessions.isEmpty)
            _buildEmptyState('No practice sessions logged yet.')
          else
            pw.Table(
              border: pw.TableBorder.all(color: borderGray, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2.5),
                1: pw.FlexColumnWidth(1.5),
                2: pw.FlexColumnWidth(4),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: tableHeaderBg),
                  children: [
                    _buildTableCell('Date & Time', isHeader: true),
                    _buildTableCell('Duration', isHeader: true),
                    _buildTableCell('Session Notes', isHeader: true),
                  ],
                ),
                ...sessions.asMap().entries.map((entry) {
                  final s = entry.value;
                  final isEven = entry.key % 2 == 0;
                  final dtStr = s['practiced_at'] != null
                      ? DateFormat('yyyy-MM-dd HH:mm').format(
                          DateTime.parse(s['practiced_at'].toString()))
                      : '-';
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color:
                          isEven ? PdfColors.white : tableAlternateBg,
                    ),
                    children: [
                      _buildTableCell(dtStr),
                      _buildTableCell(
                          '${s['duration_minutes'] ?? 0} mins'),
                      _buildTableCell(
                          s['notes']?.toString() ?? '-'),
                    ],
                  );
                }),
              ],
            ),

          pw.SizedBox(height: 24),

          // ── 4. Expenses & Finance ─────────────────────────────────────
          _buildSectionHeader(
              '4. Expenses & Personal Finance Records (${expenses.length})',
              accentTeal),
          pw.SizedBox(height: 8),
          if (expenses.isEmpty)
            _buildEmptyState('No financial expenses recorded.')
          else
            pw.Table(
              border: pw.TableBorder.all(color: borderGray, width: 0.5),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(3),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(2),
                4: pw.FlexColumnWidth(2),
              },
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: tableHeaderBg),
                  children: [
                    _buildTableCell('Date', isHeader: true),
                    _buildTableCell('Description', isHeader: true),
                    _buildTableCell('Category', isHeader: true),
                    _buildTableCell('Method', isHeader: true),
                    _buildTableCell('Amount', isHeader: true),
                  ],
                ),
                ...expenses.asMap().entries.map((entry) {
                  final e = entry.value;
                  final isEven = entry.key % 2 == 0;
                  final amt =
                      (e['amount'] as num?)?.toDouble() ?? 0.0;
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color:
                          isEven ? PdfColors.white : tableAlternateBg,
                    ),
                    children: [
                      _buildTableCell(
                          e['expense_date']?.toString() ?? '-'),
                      _buildTableCell(
                          e['description']?.toString() ?? '-'),
                      _buildTableCell(
                          e['category']?.toString() ?? '-'),
                      _buildTableCell(
                          e['payment_method']?.toString() ?? '-'),
                      _buildTableCell(currencyFormat.format(amt)),
                    ],
                  );
                }),
              ],
            ),

          if (budgets.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            _buildSectionHeader(
                'Monthly Category Budgets', accentTeal,
                fontSize: 11),
            pw.SizedBox(height: 6),
            pw.Table(
              border: pw.TableBorder.all(color: borderGray, width: 0.5),
              children: [
                pw.TableRow(
                  decoration:
                      const pw.BoxDecoration(color: tableHeaderBg),
                  children: [
                    _buildTableCell('Category', isHeader: true),
                    _buildTableCell('Monthly Limit', isHeader: true),
                  ],
                ),
                ...budgets.map((b) => pw.TableRow(
                      children: [
                        _buildTableCell(
                            b['category']?.toString() ?? '-'),
                        _buildTableCell(currencyFormat.format(
                            (b['monthly_limit'] as num?)
                                    ?.toDouble() ??
                                0.0)),
                      ],
                    )),
              ],
            ),
          ],

          if (notes.isNotEmpty) ...[
            pw.SizedBox(height: 24),
            _buildSectionHeader(
                '5. Personal Notes (${notes.length})', accentTeal),
            pw.SizedBox(height: 8),
            ...notes.map((note) => pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 8),
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: tableAlternateBg,
                    border: pw.Border.all(color: borderGray, width: 0.5),
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment:
                            pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            note['title']?.toString() ??
                                'Untitled Note',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 10,
                              color: textDark,
                            ),
                          ),
                          if (note['created_at'] != null)
                            pw.Text(
                              DateFormat('yyyy-MM-dd').format(
                                  DateTime.parse(
                                      note['created_at'].toString())),
                              style: const pw.TextStyle(
                                  fontSize: 8, color: textMuted),
                            ),
                        ],
                      ),
                      if (note['content'] != null &&
                          note['content']
                              .toString()
                              .isNotEmpty) ...[
                        pw.SizedBox(height: 4),
                        pw.Text(
                          note['content'].toString(),
                          style: const pw.TextStyle(
                              fontSize: 8.5, color: textDark),
                          maxLines: 4,
                        ),
                      ],
                    ],
                  ),
                )),
          ],
        ],
      ),
    );

    // ── Save and share using cross-platform share_plus ────────────────────
    final Uint8List pdfBytes;
    try {
      pdfBytes = await pdf.save();
    } catch (e) {
      throw PdfGenerationException(e);
    }

    final filename =
        'FocusFlow_Export_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';

    // Write to a temporary file then share via the system share sheet.
    // This works on Android, iOS, Windows, macOS, Linux, and Web.
    try {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(pdfBytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/pdf')],
          subject: 'FocusFlow Personal Data Export',
        ),
      );
    } catch (e) {
      throw PdfShareException(e);
    }
  }

  // ── PDF builder helpers ───────────────────────────────────────────────────

  static pw.Widget _buildSectionHeader(
    String title,
    PdfColor accentColor, {
    double fontSize = 13,
  }) {
    return pw.Row(
      children: [
        pw.Container(
          width: 3.5,
          height: fontSize + 1,
          color: accentColor,
          margin: const pw.EdgeInsets.only(right: 6),
        ),
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF0B1222),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildKeyValueRow(String key, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          key,
          style: const pw.TextStyle(
            fontSize: 9.5,
            color: PdfColor.fromInt(0xFF64748B),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: const PdfColor.fromInt(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 8.5 : 8,
          fontWeight:
              isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader
              ? const PdfColor.fromInt(0xFF0B1222)
              : const PdfColor.fromInt(0xFF334155),
        ),
      ),
    );
  }

  static pw.Widget _buildEmptyState(String message) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfExportService.tableAlternateBg,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfExportService.borderGray),
      ),
      alignment: pw.Alignment.center,
      child: pw.Text(
        message,
        style: pw.TextStyle(
          fontSize: 9,
          color: PdfExportService.textMuted,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }
}
