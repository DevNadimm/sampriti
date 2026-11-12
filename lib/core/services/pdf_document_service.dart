import 'dart:convert';
import 'package:bangla_pdf/bangla_pdf.dart' as bp;
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:sampriti/core/config/app_config.dart';
import 'package:sampriti/core/config/assets.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';
import 'package:sampriti/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:sampriti/features/meetings/data/models/meeting_model.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/reports/data/models/financial_report_model.dart';
import 'package:sampriti/features/reports/data/models/report_period.dart';
import 'package:sampriti/features/reports/data/models/ledger_report.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';

class PdfDocumentService {
  PdfDocumentService._();

  static const _maroon = PdfColor.fromInt(0xFF8A0A14);
  static const _maroonDark = PdfColor.fromInt(0xFF640710);
  static const _gold = PdfColor.fromInt(0xFFC9A227);
  static const _goldDark = PdfColor.fromInt(0xFF8A6A00);
  static const _ink = PdfColor.fromInt(0xFF16213A);
  static const _muted = PdfColor.fromInt(0xFF59647A);
  static const _rule = PdfColor.fromInt(0xFFE2E8F0);
  static const _cream = PdfColor.fromInt(0xFFFFFDF7);
  static const _white = PdfColors.white;
  static const _success = PdfColor.fromInt(0xFF059669);
  static const _error = PdfColor.fromInt(0xFFE8192C);

  static pw.Font? _bengaliBase;
  static pw.Font? _bengaliBold;
  static pw.Font? _robotoBase;
  static pw.Font? _robotoBold;
  static pw.Font? _robotoItalic;
  static Uint8List? _logoBytes;

  static Future<void> _initResources() async {
    _bengaliBase ??= await PdfGoogleFonts.notoSansBengaliRegular();
    _bengaliBold ??= await PdfGoogleFonts.notoSansBengaliBold();
    _robotoBase ??= await PdfGoogleFonts.robotoRegular();
    _robotoBold ??= await PdfGoogleFonts.robotoBold();
    _robotoItalic ??= await PdfGoogleFonts.robotoItalic();

    if (_logoBytes == null) {
      try {
        final data = await rootBundle.load(Assets.logoBanner);
        _logoBytes = data.buffer.asUint8List();
      } catch (_) {}
    }
  }

  static pw.ThemeData _getTheme() {
    return pw.ThemeData.withFont(
      base: _bengaliBase,
      bold: _bengaliBold,
      fontFallback: [
        ?_bengaliBase,
        ?_robotoBase,
        ?_bengaliBold,
        ?_robotoBold,
      ],
    );
  }

  static pw.MemoryImage? _parseImage(String? photo) {
    if (photo == null || photo.trim().isEmpty) return null;
    try {
      String clean = photo.trim();
      if (clean.contains(',')) {
        clean = clean.split(',').last;
      }
      final bytes = base64Decode(clean);
      if (bytes.isNotEmpty) {
        return pw.MemoryImage(bytes);
      }
    } catch (_) {}
    return null;
  }

  static String _formatAmount(num? amount) {
    if (amount == null) return '0';
    final formatter = NumberFormat('#,##,###');
    return formatter.format(amount.round());
  }

  static String _getModeTitle(String mode) {
    switch (mode) {
      case 'bank':
        return 'ব্যাংক হিসাব (Bank)';
      case 'cash':
        return 'নগদ ক্যাশ (Cash)';
      case 'inst':
        return 'প্রতিষ্ঠান সরাসরি';
      default:
        return mode;
    }
  }
  static pw.Widget _text(
    String text, {
    pw.TextStyle? style,
    pw.TextAlign? textAlign,
    int? maxLines,
    pw.TextOverflow? overflow,
    double? fontSize,
    pw.FontWeight? fontWeight,
    PdfColor? color,
    pw.TextDirection? textDirection,
    bool? softWrap,
    double textScaleFactor = 1.0,
  }) {
    return bp.Text(
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      fontSize: fontSize ?? style?.fontSize ?? 10,
      fontWeight: fontWeight ?? style?.fontWeight ?? pw.FontWeight.normal,
      color: color ?? style?.color ?? _ink,
      textDirection: textDirection,
      softWrap: softWrap,
      textScaleFactor: textScaleFactor,
    );
  }

  static pw.Widget _buildTable({
    required List<String> headers,
    required List<List<String>> data,
    Map<int, pw.TableColumnWidth>? columnWidths,
    pw.TextStyle? headerStyle,
    pw.BoxDecoration? headerDecoration,
    pw.TextStyle? cellStyle,
    pw.Alignment cellAlignment = pw.Alignment.centerLeft,
    pw.EdgeInsets cellPadding = const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    Map<int, pw.Alignment>? columnAlignments,
    bool alternateRowColors = true,
    List<String>? footerRow,
  }) {
    return pw.Table(
      columnWidths: columnWidths,
      defaultVerticalAlignment: pw.TableCellVerticalAlignment.middle,
      children: [
        pw.TableRow(
          decoration: headerDecoration ?? const pw.BoxDecoration(color: _maroon),
          children: headers.asMap().entries.map((e) {
            final colIdx = e.key;
            final text = e.value;
            final align = columnAlignments?[colIdx] ?? cellAlignment;
            return pw.Padding(
              padding: cellPadding,
              child: pw.Align(
                alignment: align,
                child: _text(
                  text,
                  style: headerStyle ?? pw.TextStyle(
                    fontSize: 7.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _white,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        ...data.asMap().entries.map((rowEntry) {
          final rowIdx = rowEntry.key;
          final rowData = rowEntry.value;
          final isEven = rowIdx % 2 == 0;
          return pw.TableRow(
            decoration: alternateRowColors && !isEven
                ? const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFBF1D6))
                : null,
            children: rowData.asMap().entries.map((cellEntry) {
              final colIdx = cellEntry.key;
              final text = cellEntry.value;
              final align = columnAlignments?[colIdx] ?? cellAlignment;
              return pw.Padding(
                padding: cellPadding,
                child: pw.Align(
                  alignment: align,
                  child: _text(
                    text,
                    style: cellStyle ?? const pw.TextStyle(fontSize: 7, color: _ink),
                  ),
                ),
              );
            }).toList(),
          );
        }),
        if (footerRow != null)
          pw.TableRow(
            decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFFFFDF7)),
            children: footerRow.asMap().entries.map((cellEntry) {
              final colIdx = cellEntry.key;
              final align = columnAlignments?[colIdx] ?? cellAlignment;
              return pw.Padding(
                padding: cellPadding,
                child: pw.Align(
                  alignment: align,
                  child: _text(
                    cellEntry.value,
                    style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _ink),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  /// Bordered stat box: muted label, bold value. Shared by the report and ledger PDFs.
  static pw.Widget _statCell(String label, num val, {PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: _rule, width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _text(label, style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
          pw.SizedBox(height: 2),
          _text(
            '৳ ${_formatAmount(val)}',
            style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: color ?? _ink),
          ),
        ],
      ),
    );
  }

  /// Signature line row with one labelled block per name.
  static pw.Widget _signatureRow(List<String> labels) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: labels
          .map((l) => pw.Column(
                children: [
                  pw.SizedBox(height: 28),
                  pw.Container(width: 110, height: 0.75, color: _ink),
                  pw.SizedBox(height: 4),
                  _text(l, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                ],
              ))
          .toList(),
    );
  }

  static pw.TableRow _buildTableRow(String sl, String label, String value) {
    return pw.TableRow(
      decoration: const pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.5)),
      ),
      children: [
        if (sl.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
            child: _text(
              sl,
              style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _ink),
              textAlign: pw.TextAlign.center,
            ),
          )
        else
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
            child: pw.SizedBox(width: 14),
          ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3.5),
          child: _text(
            label,
            style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _ink),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3.5),
          child: _text(
            ':',
            style: const pw.TextStyle(fontSize: 8.5, color: _muted),
            textAlign: pw.TextAlign.center,
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3.5),
          child: _text(
            value.isNotEmpty ? value : '—',
            style: pw.TextStyle(fontSize: 8.5, color: _ink),
          ),
        ),
      ],
    );
  }

  static pw.Widget _headerBlock({
    required String title,
    String? metaLabel,
    String? metaValue,
    String? leftMetaLabel,
    String? leftMetaValue,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        // 1. Centered Official Logo Banner
        if (_logoBytes != null)
          pw.Center(
            child: pw.Image(
              pw.MemoryImage(_logoBytes!),
              height: 44,
              fit: pw.BoxFit.contain,
            ),
          )
        else
          pw.Center(
            child: _text(
              AppConfig.appFullName,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: _maroon,
              ),
            ),
          ),
        pw.SizedBox(height: 5),

        // 2. Motto/Slogan in Maroon Badge (Direct Clean Rounded Border)
        pw.Center(
          child: pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 3),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: _maroon, width: 1.0),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              color: _white,
            ),
            child: _text(
              AppConfig.appSlogan,
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                color: _maroon,
              ),
            ),
          ),
        ),
        pw.SizedBox(height: 4),

        // 3. Organization Establishment & Address Line
        pw.Center(
          child: _text(
            'স্থাপিত: ${AppConfig.establishedYear} | ঠিকানা: ${AppConfig.orgAddress}',
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
        ),
        pw.SizedBox(height: 8),

        // 4. Centered Title Badge in Gold Border + Left/Right Meta
        pw.Container(
          width: double.infinity,
          child: pw.Stack(
            alignment: pw.Alignment.center,
            children: [
              // Left Meta (if any, e.g. সনদ নং : [ CERT-S102 ])
              if (leftMetaLabel != null && leftMetaValue != null)
                pw.Align(
                  alignment: pw.Alignment.centerLeft,
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      _text(
                        leftMetaLabel,
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFF718096), width: 0.9),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                          color: _white,
                        ),
                        child: _text(
                          leftMetaValue,
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Centered Document Title Badge (Direct Clean Rounded Border)
              pw.Align(
                alignment: pw.Alignment.center,
                child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _goldDark, width: 1.2),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                    color: _white,
                  ),
                  child: _text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                      color: _goldDark,
                    ),
                  ),
                ),
              ),

              // Right Meta (e.g. শেয়ার নং : [ S102 ])
              if (metaLabel != null && metaValue != null)
                pw.Align(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      _text(
                        metaLabel,
                        style: pw.TextStyle(
                          fontSize: 8.5,
                          fontWeight: pw.FontWeight.bold,
                          color: _ink,
                        ),
                      ),
                      pw.SizedBox(width: 4),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 2.5),
                        decoration: pw.BoxDecoration(
                          border: pw.Border.all(color: const PdfColor.fromInt(0xFF718096), width: 0.9),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
                          color: _white,
                        ),
                        child: _text(
                          metaValue,
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            color: _ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        pw.SizedBox(height: 10),
      ],
    );
  }



  // ==========================================
  // 1. SHARE CERTIFICATE (100% English & Large Royal Typography)
  // ==========================================
  static Future<Uint8List> generateShareCertificate(MemberModel member) async {
    await _initResources();
    final doc = pw.Document(theme: _getTheme());
    final photo = _parseImage(member.photo);

    // Single English recipient name (no duplicate dual lines)
    final recipientName = member.nameEn.trim().isNotEmpty ? member.nameEn.trim() : member.displayName;

    String numberToWord(int n) {
      const words = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten'];
      if (n > 0 && n < words.length) return words[n];
      return '$n';
    }

    final shareWord = numberToWord(member.shares);
    final sharesText = member.shares == 1
        ? '1 ($shareWord) Ordinary Share'
        : '${member.shares} ($shareWord) Ordinary Shares';

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: _cream,
              border: pw.Border.all(color: _maroon, width: 3.0),
            ),
            padding: const pw.EdgeInsets.all(6),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _gold, width: 1.5),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Top Organization Header Block
                  pw.Column(
                    children: [
                      if (_logoBytes != null)
                        pw.Center(
                          child: pw.Image(
                            pw.MemoryImage(_logoBytes!),
                            height: 48,
                            fit: pw.BoxFit.contain,
                          ),
                        ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'SAMPRITI INVESTMENT FORUM',
                        style: pw.TextStyle(
                          font: _robotoBold,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: _maroonDark,
                          letterSpacing: 2.0,
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 5),
                        decoration: const pw.BoxDecoration(
                          color: _maroon,
                          borderRadius: pw.BorderRadius.all(pw.Radius.circular(16)),
                        ),
                        child: pw.Text(
                          'SHARE CERTIFICATE',
                          style: pw.TextStyle(
                            font: _robotoBold,
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: _white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                      pw.SizedBox(height: 12),
                      pw.Text(
                        'Certificate No: CERT-${member.no}',
                        style: pw.TextStyle(
                          font: _robotoBold,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: _muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),

                  // Member Photo Frame (Large & Prestigious)
                  pw.Container(
                    width: 95,
                    height: 120,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _gold, width: 2.0),
                      color: _white,
                    ),
                    child: photo != null
                        ? pw.Image(photo, fit: pw.BoxFit.cover)
                        : pw.Center(
                            child: pw.Text(
                              member.no,
                              style: pw.TextStyle(
                                font: _robotoBold,
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: _muted,
                              ),
                            ),
                          ),
                  ),

                  // Preamble & Recipient Name
                  pw.Column(
                    children: [
                      pw.Text(
                        'This is to certify that',
                        style: pw.TextStyle(
                          font: _robotoItalic ?? _robotoBase,
                          fontSize: 14,
                          fontStyle: pw.FontStyle.italic,
                          color: _muted,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      // Single English Name (Prominent & Large)
                      pw.Text(
                        recipientName.toUpperCase(),
                        textAlign: pw.TextAlign.center,
                        style: pw.TextStyle(
                          font: _robotoBold,
                          fontSize: 26,
                          fontWeight: pw.FontWeight.bold,
                          color: _maroonDark,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        width: 220,
                        height: 1.5,
                        color: _gold,
                      ),
                    ],
                  ),

                  // Certificate Body Statement (Large & Readable)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16),
                    child: pw.Text(
                      'is a bonafide registered shareholder of Sampriti Investment Forum, holding $sharesText under Share No. ${member.no}. The shareholder is entitled to all rights, privileges, and dividend distributions in accordance with the constitution and regulations of the forum.',
                      textAlign: pw.TextAlign.center,
                      style: pw.TextStyle(
                        font: _robotoBase,
                        fontSize: 14,
                        lineSpacing: 1.6,
                        color: _ink,
                      ),
                    ),
                  ),

                  // Share Details Badge
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _goldDark, width: 1.0),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      color: _white,
                    ),
                    child: pw.Text(
                      'Share No: ${member.no}  |  Shares Held: ${member.shares}',
                      style: pw.TextStyle(
                        font: _robotoBold,
                        fontSize: 11.5,
                        fontWeight: pw.FontWeight.bold,
                        color: _goldDark,
                      ),
                    ),
                  ),

                  // Signatures Block (Shareholder, General Secretary, President)
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Column(
                          children: [
                            pw.Container(width: 130, height: 1.0, color: _ink),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'Shareholder',
                              style: pw.TextStyle(
                                font: _robotoBold,
                                fontSize: 11.5,
                                fontWeight: pw.FontWeight.bold,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Container(width: 130, height: 1.0, color: _ink),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'General Secretary',
                              style: pw.TextStyle(
                                font: _robotoBold,
                                fontSize: 11.5,
                                fontWeight: pw.FontWeight.bold,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                        pw.Column(
                          children: [
                            pw.Container(width: 130, height: 1.0, color: _ink),
                            pw.SizedBox(height: 6),
                            pw.Text(
                              'President',
                              style: pw.TextStyle(
                                font: _robotoBold,
                                fontSize: 11.5,
                                fontWeight: pw.FontWeight.bold,
                                color: _ink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    return doc.save();
  }

  // ==========================================
  // 2. SHAREHOLDER APPLICATION FORM
  // ==========================================
  static Future<Uint8List> generateShareholderForm(MemberModel member) async {
    await _initResources();
    final doc = pw.Document(theme: _getTheme());
    final photo = _parseImage(member.photo);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _headerBlock(
                title: 'শেয়ার ফরম',
                metaLabel: 'শেয়ার নং :',
                metaValue: member.no,
              ),

              // 1. সদস্যের তথ্য Section Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
                decoration: const pw.BoxDecoration(
                  color: _maroon,
                  borderRadius: pw.BorderRadius.only(
                    topRight: pw.Radius.circular(10),
                    bottomRight: pw.Radius.circular(4),
                  ),
                ),
                child: _text(
                  '১. সদস্যের তথ্য',
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _white),
                ),
              ),
              pw.SizedBox(height: 6),

              // Table + Photo Row
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Table(
                      border: pw.TableBorder.all(color: _rule, width: 0.6),
                      columnWidths: const {
                        0: pw.FixedColumnWidth(20),
                        1: pw.FixedColumnWidth(110),
                        2: pw.FixedColumnWidth(12),
                        3: pw.FlexColumnWidth(),
                      },
                      children: [
                        _buildTableRow('১', 'এক নাম (বাংলা)', member.nameBn),
                        if (member.nameEn.isNotEmpty)
                          _buildTableRow('', '(ইংরেজি)', member.nameEn),
                        _buildTableRow('২', 'পিতার নাম', member.father),
                        _buildTableRow('৩', 'মাতার নাম', member.mother),
                        if (member.spouse.isNotEmpty)
                          _buildTableRow('৪', 'স্ত্রীর নাম', member.spouse),
                        _buildTableRow('৫', 'এন আই ডি নাম্বার, জন্ম তারিখ', '${member.nid.isNotEmpty ? member.nid : "—"}, ${member.birth.isNotEmpty ? DateFormatter.ddMMyyyy(member.birth) : "—"}'),
                        _buildTableRow('৬', 'ঠিকানা', member.address),
                        _buildTableRow('৭', 'পেশা', member.job),
                        _buildTableRow('৮', 'মোবাইল নম্বর', member.mobile),
                        _buildTableRow('৯', 'শেয়ার সংখ্যা', '${member.shares} টি'),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Container(
                    width: 84,
                    height: 106,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _maroon, width: 1.2),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                      color: _white,
                    ),
                    child: photo != null
                        ? pw.ClipRRect(
                            horizontalRadius: 3,
                            verticalRadius: 3,
                            child: pw.Image(photo, fit: pw.BoxFit.cover),
                          )
                        : pw.Center(
                            child: _text(
                              'ছবি সংযুক্ত\nকরুন',
                              textAlign: pw.TextAlign.center,
                              style: const pw.TextStyle(fontSize: 8, color: _muted),
                            ),
                          ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),

              // 2. নমিনির তথ্য Section Header
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 3.5),
                decoration: const pw.BoxDecoration(
                  color: _goldDark,
                  borderRadius: pw.BorderRadius.only(
                    topRight: pw.Radius.circular(10),
                    bottomRight: pw.Radius.circular(4),
                  ),
                ),
                child: _text(
                  '২. নমিনির তথ্য',
                  style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _white),
                ),
              ),
              pw.SizedBox(height: 6),

              if (member.nominees.isNotEmpty)
                _buildTable(
                  headers: ['ক্র.', 'নমিনির নাম', 'সম্পর্ক', 'অংশ (%)', 'মোবাইল', 'NID / জন্ম নিবন্ধন'],
                  data: member.nominees.asMap().entries.map((e) => [
                    '${e.key + 1}',
                    e.value.name,
                    e.value.relation.isNotEmpty ? e.value.relation : '—',
                    '${e.value.share}%',
                    e.value.mobile.isNotEmpty ? e.value.mobile : '—',
                    e.value.nid.isNotEmpty ? e.value.nid : e.value.birth.isNotEmpty ? DateFormatter.ddMMyyyy(e.value.birth) : '—',
                  ]).toList(),
                  columnWidths: const {
                    0: pw.FixedColumnWidth(24),
                    1: pw.FlexColumnWidth(2.5),
                    2: pw.FlexColumnWidth(1.5),
                    3: pw.FixedColumnWidth(48),
                    4: pw.FlexColumnWidth(2),
                    5: pw.FlexColumnWidth(2),
                  },
                )
              else
                _text('কোনো নমিনী মনোনীত করা হয়নি।', style: const pw.TextStyle(fontSize: 8.5, color: _muted)),

              pw.SizedBox(height: 10),

              // Declaration: শেয়ার হোল্ডারের ঘোষণা (Matching HTML spec)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: _cream,
                  border: pw.Border.all(color: _gold, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _text(
                      'শেয়ার হোল্ডারের ঘোষণা :',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _maroon),
                    ),
                    pw.SizedBox(height: 3),
                    _text(
                      '১. আমি, নিম্নস্বাক্ষরকারী, “সম্প্রীতি” সংগঠনের সদস্য হিসেবে যোগদান করতে ইচ্ছুক।\n'
                      '২. আমি সংগঠনের উদ্দেশ্য ও নীতিমালার সাথে একমত এবং সংগঠনের সকল নিয়ম-কানুন মেনে চলার অঙ্গীকার করছি।\n'
                      '৩. আমি প্রতিশ্রুতি দিচ্ছি যে, সংগঠনের নিয়ম-কানুন বা সিদ্ধান্তের কোনো আমি মানতে বাধ্য হলে, এবং সংগঠনের সর্বোচ্চ সিদ্ধান্ত, সাধারণ সভা/নির্বাহী কমিটির যে কোনো সিদ্ধান্ত আমি বিনা আপত্তিতে মেনে নিতে বাধ্য থাকব।\n'
                      '৪. এছাড়া, আমার মনোনীত নমিনি সম্পর্কে প্রদত্ত তথ্য সঠিক এবং সত্য বলে ঘোষণা করছি।',
                      style: const pw.TextStyle(fontSize: 7.2, lineSpacing: 1.25, color: _ink),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures (Matching HTML spec: আবেদনকারী, সাধারণ সম্পাদক, সভাপতি)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 0.75, color: _muted),
                      pw.SizedBox(height: 4),
                      _text('আবেদনকারী\n(স্বাক্ষর)', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 0.75, color: _muted),
                      pw.SizedBox(height: 4),
                      _text('সাধারণ সম্পাদক\n(স্বাক্ষর)', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 0.75, color: _muted),
                      pw.SizedBox(height: 4),
                      _text('সভাপতি\n(স্বাক্ষর)', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ==========================================
  // 3. NOMINEE NOMINATION FORM
  // ==========================================
  static Future<Uint8List> generateNomineeForm(MemberModel member) async {
    await _initResources();
    final doc = pw.Document(theme: _getTheme());

    final validNominees = member.nominees.where((n) => n.name.trim().isNotEmpty).toList();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _headerBlock(
                title: 'নমিনী ফরম',
                metaLabel: 'শেয়ার নং :',
                metaValue: member.no,
              ),
              pw.SizedBox(height: 8),

              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: _cream,
                  border: pw.Border.all(color: _maroon, width: 0.75),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _text('শেয়ারহোল্ডার সদস্য: ${member.displayName}',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _maroon)),
                    _text('শেয়ার সংখ্যা: ${member.shares} টি',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _ink)),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              _text(
                'আমার অবর্তমানে সম্প্রীতি ইনভেস্টমেন্ট ফোরামে আমার জমাকৃত শেয়ার মূলধন ও মুনাফা প্রাপ্তির জন্য নিম্নলিখিত ব্যক্তি/ব্যক্তিবর্গকে নমিনী হিসেবে মনোনীত করিলাম:',
                style: const pw.TextStyle(fontSize: 8.5, lineSpacing: 1.4, color: _muted),
              ),
              pw.SizedBox(height: 12),

              if (validNominees.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  alignment: pw.Alignment.center,
                  child: _text('কোনো নমিনীর তথ্য পাওয়া যায়নি।',
                      style: const pw.TextStyle(fontSize: 9, color: _muted)),
                )
              else
                ...validNominees.asMap().entries.map((entry) {
                  final idx = entry.key + 1;
                  final n = entry.value;
                  final nPhoto = _parseImage(n.photo);

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 12),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _rule, width: 1),
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                    ),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Nominee Photo
                        pw.Container(
                          width: 60,
                          height: 75,
                          margin: const pw.EdgeInsets.only(right: 12),
                          decoration: pw.BoxDecoration(
                            border: pw.Border.all(color: _maroon, width: 1),
                            color: _white,
                          ),
                          child: nPhoto != null
                              ? pw.Image(nPhoto, fit: pw.BoxFit.cover)
                              : pw.Center(
                                  child: _text(
                                    'নমিনী ছবি',
                                    style: const pw.TextStyle(fontSize: 7, color: _muted),
                                  ),
                                ),
                        ),
                        // Details
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  _text(
                                    'নমিনী $idx: ${n.name}',
                                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _maroon),
                                  ),
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: const pw.BoxDecoration(
                                      color: _goldDark,
                                      borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
                                    ),
                                    child: _text(
                                      'অংশ: ${n.share}%',
                                      style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: _white),
                                    ),
                                  ),
                                ],
                              ),
                              pw.SizedBox(height: 4),
                              _text('সম্পর্ক: ${n.relation.isNotEmpty ? n.relation : "—"}',
                                  style: const pw.TextStyle(fontSize: 8.5, color: _ink)),
                              _text('এনআইডি / জন্ম নিবন্ধন: ${n.nid.isNotEmpty ? n.nid : "—"}',
                                  style: const pw.TextStyle(fontSize: 8.5, color: _ink)),
                              _text('জন্ম তারিখ: ${n.birth.isNotEmpty ? DateFormatter.ddMMyyyy(n.birth) : "—"}',
                                  style: const pw.TextStyle(fontSize: 8.5, color: _ink)),
                              _text('মোবাইল নম্বর: ${n.mobile.isNotEmpty ? n.mobile : "—"}',
                                  style: const pw.TextStyle(fontSize: 8.5, color: _ink)),
                              if (n.address.isNotEmpty)
                                _text('ঠিকানা: ${n.address}',
                                    style: const pw.TextStyle(fontSize: 8.5, color: _ink)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),

              pw.Spacer(),

              // Declaration: শেয়ার হোল্ডারের ঘোষণা (Matching HTML spec)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(6),
                decoration: pw.BoxDecoration(
                  color: _cream,
                  border: pw.Border.all(color: _gold, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _text(
                      'শেয়ার হোল্ডারের ঘোষণা :',
                      style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _maroon),
                    ),
                    pw.SizedBox(height: 3),
                    _text(
                      '১. আমি, নিম্নস্বাক্ষরকারী, “সম্প্রীতি” সংগঠনের সদস্য হিসেবে সংগঠনের সকল নিয়ম-কানুন ও নীতিমালা মেনে চলার অঙ্গীকার করছি।\n'
                      '২. সংগঠনের সর্বোচ্চ সিদ্ধান্ত, সাধারণ সভা/নির্বাহী কমিটির যে কোনো সিদ্ধান্ত আমি বিনা আপত্তিতে মেনে নিতে বাধ্য থাকব।',
                      style: const pw.TextStyle(fontSize: 7.5, lineSpacing: 1.3, color: _ink),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures (Matching HTML spec: আবেদনকারী / শেয়ার হোল্ডার, সাধারণ সম্পাদক, সভাপতি)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 0.75, color: _muted),
                      pw.SizedBox(height: 4),
                      _text('আবেদনকারী / শেয়ার হোল্ডার\n(স্বাক্ষর)',
                          textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 0.75, color: _muted),
                      pw.SizedBox(height: 4),
                      _text('সাধারণ সম্পাদক\n(স্বাক্ষর)',
                          textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 0.75, color: _muted),
                      pw.SizedBox(height: 4),
                      _text('সভাপতি\n(স্বাক্ষর)',
                          textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ==========================================
  // 4. VOUCHER / RECEIPT SLIP
  // ==========================================
  static Future<Uint8List> generateVoucherPdf(
    TransactionModel trx, {
    String? memberName,
    String? instName,
    String? bankName,
  }) async {
    await _initResources();
    final doc = pw.Document(theme: _getTheme());

    final isReceipt = trx.sign > 0;
    final isPayout = trx.sign < 0;
    final badgeColor = isReceipt ? _success : isPayout ? _maroon : _goldDark;

    pw.Widget buildVoucherRow(String label, String value) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: const pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: _rule, width: 0.5)),
        ),
        child: pw.Row(
          children: [
            pw.SizedBox(
              width: 130,
              child: _text(label, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _muted)),
            ),
            _text(':  ', style: const pw.TextStyle(fontSize: 9, color: _muted)),
            pw.Expanded(
              child: _text(value, style: const pw.TextStyle(fontSize: 9, color: _ink)),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _headerBlock(
                title: isReceipt ? 'প্রাপ্তি ভাউচার' : isPayout ? 'পরিশোধ ভাউচার' : 'স্থানান্তর ভাউচার',
                metaLabel: 'ভাউচার নং :',
                metaValue: trx.vno,
              ),
              pw.SizedBox(height: 8),

              // Transaction Mode & Date Bar
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: pw.BoxDecoration(
                  color: _cream,
                  border: pw.Border.all(color: badgeColor, width: 0.8),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    _text('লেনদেনের মাধ্যম: ${_getModeTitle(trx.mode)}',
                        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: badgeColor)),
                    _text('তারিখ: ${DateFormatter.ddMMyyyy(trx.date)}',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _ink)),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // Table Content
              buildVoucherRow('লেনদেনের ধরন', trx.title),
              if (trx.sectorName.isNotEmpty)
                buildVoucherRow('খাত', trx.sectorName),
              if (trx.project.isNotEmpty)
                buildVoucherRow('প্রকল্প', trx.project),
              if (trx.member.isNotEmpty)
                buildVoucherRow('সদস্য', memberName != null && memberName.isNotEmpty ? '$memberName (${trx.member})' : trx.member),
              buildVoucherRow('পরিশোধের মাধ্যম', _getModeTitle(trx.mode)),
              if (trx.acct.isNotEmpty)
                buildVoucherRow('ব্যাংক / হিসাব নং', bankName != null && bankName.isNotEmpty ? bankName : trx.acct),
              if (trx.note.isNotEmpty)
                buildVoucherRow('বিবরণ / মন্তব্য', trx.note),

              pw.SizedBox(height: 16),

              // Amount Highlight Box
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: pw.BoxDecoration(
                  color: _cream,
                  border: pw.Border.all(color: _gold, width: 1.5),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _text('মোট টাকার পরিমাণ (Amount)',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _muted)),
                        pw.SizedBox(height: 2),
                        _text(
                          'কথায়: ${_formatAmount(trx.amount)} টাকা মাত্র',
                          style: const pw.TextStyle(fontSize: 8.5, color: _ink),
                        ),
                      ],
                    ),
                    _text(
                      '৳ ${_formatAmount(trx.amount)}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // Signatures (Matching HTML spec: প্রস্তুতকারী, সাধারণ সম্পাদক, সভাপতি)
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 0.75, color: _muted),
                      pw.SizedBox(height: 4),
                      _text('প্রস্তুতকারী\n(স্বাক্ষর)',
                          textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 0.75, color: _muted),
                      pw.SizedBox(height: 4),
                      _text('সাধারণ সম্পাদক\n(স্বাক্ষর)',
                          textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(width: 120, height: 0.75, color: _muted),
                      pw.SizedBox(height: 4),
                      _text('সভাপতি\n(স্বাক্ষর)',
                          textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ==========================================
  // 5. FINANCIAL AUDIT & ACCOUNTS SUMMARY REPORT
  // ==========================================
  static Future<Uint8List> generateFinancialReportPdf(
    DashboardSummaryModel summary, {
    String? title,
  }) async {
    await _initResources();
    final doc = pw.Document(theme: _getTheme());
    final nowStr = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    pw.Widget buildStatCell(String label, num val, {PdfColor? color}) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(6),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _rule, width: 0.75),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _text(label, style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
            pw.SizedBox(height: 2),
            _text(
              '৳ ${_formatAmount(val)}',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: color ?? _ink,
              ),
            ),
          ],
        ),
      );
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        header: (context) => pw.Column(
          children: [
            _headerBlock(
              title: title ?? 'আর্থিক বিবরণী প্রতিবেদন',
              metaLabel: 'তারিখ :',
              metaValue: nowStr,
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _text('মুদ্রণের সময়: $nowStr', style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
                _text('পৃষ্ঠা ${context.pageNumber} / ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: _rule, thickness: 0.75),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: _rule, thickness: 0.75),
            pw.SizedBox(height: 4),
            _text(
              'এই প্রতিবেদনটি সম্প্রীতি সফটওয়্যার সিস্টেম দ্বারা স্বয়ংক্রিয়ভাবে প্রস্তুতকৃত।',
              style: const pw.TextStyle(fontSize: 7, color: _muted),
            ),
          ],
        ),
        build: (context) => [
          // Section 1: Overview
          _text('১. সংগঠনের বর্তমান আর্থিক অবস্থা',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _maroon)),
          pw.SizedBox(height: 6),

          pw.Table(
            children: [
              pw.TableRow(children: [
                buildStatCell('সদস্যদের মোট বিনিয়োগ', summary.totalInvestment, color: _maroon),
                buildStatCell('ব্যাংক ব্যালেন্স', summary.bankBalance, color: _success),
                buildStatCell('নগদ ক্যাশ (হাতে)', summary.cashBalance, color: _success),
                buildStatCell('সর্বমোট তহবিল', summary.totalFunds, color: _success),
              ]),
              pw.TableRow(children: [
                buildStatCell('প্রকল্পে মোট ব্যয়', summary.projectExpense),
                buildStatCell('শেয়ারহোল্ডারকে মূলধন ফেরত', summary.capitalReturn, color: _error),
                buildStatCell('প্রকল্প থেকে আয়', summary.projectIncome, color: _success),
                buildStatCell('বণ্টনকৃত মুনাফা', summary.totalPayout, color: _maroon),
              ]),
            ],
          ),
          pw.SizedBox(height: 14),

          // Section 2: Expense & Donation Breakdown
          _text('২. অন্যান্য ব্যয় ও বণ্টন স্থিতি',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _maroon)),
          pw.SizedBox(height: 6),

          pw.Table(
            children: [
              pw.TableRow(children: [
                buildStatCell('মোট ডোনেশন ব্যয়', summary.donationExpense),
                buildStatCell('মোট ব্যয়/খরচ', summary.totalExpense, color: _error),
                buildStatCell('বণ্টনযোগ্য অবশিষ্ট মুনাফা', summary.distributableProfit, color: _goldDark),
                buildStatCell('বকেয়া মুনাফা পাওনা', summary.pendingPayout, color: _error),
              ]),
            ],
          ),
          pw.SizedBox(height: 14),

          // Section 3: Recent Transactions
          if (summary.recentTransactions.isNotEmpty) ...[
            _text('৩. সাম্প্রতিক লেনদেন বিবরণী',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _maroon)),
            pw.SizedBox(height: 6),
            _buildTable(
              headers: ['ভাউচার নং', 'তারিখ', 'লেনদেনের ধরন', 'সদস্য/প্রতিষ্ঠান', 'মাধ্যম', 'টাকার পরিমাণ'],
              data: summary.recentTransactions.take(15).map((t) {
                final target = t.member.isNotEmpty ? t.member : t.project.isNotEmpty ? t.project : '—';
                return [
                  t.vno,
                  DateFormatter.ddMMyyyy(t.date),
                  t.title,
                  target,
                  _getModeTitle(t.mode),
                  '৳ ${_formatAmount(t.amount)}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _white),
              headerDecoration: const pw.BoxDecoration(color: _maroon),
              cellStyle: const pw.TextStyle(fontSize: 7, color: _ink),
              cellAlignment: pw.Alignment.centerLeft,
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
            ),
          ],
          pw.SizedBox(height: 20),

          // Signatures (Matching HTML spec: অর্থ সম্পাদক, সাধারণ সম্পাদক, সভাপতি)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 120, height: 0.75, color: _muted),
                  pw.SizedBox(height: 4),
                  _text('অর্থ সম্পাদক\n(স্বাক্ষর)', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 120, height: 0.75, color: _muted),
                  pw.SizedBox(height: 4),
                  _text('সাধারণ সম্পাদক\n(স্বাক্ষর)', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 120, height: 0.75, color: _muted),
                  pw.SizedBox(height: 4),
                  _text('সভাপতি\n(স্বাক্ষর)', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ==========================================
  // 6. SHAREHOLDER LIST DIRECTORY
  // ==========================================
  static Future<Uint8List> generateShareholderListPdf(List<MemberModel> members) async {
    await _initResources();
    final doc = pw.Document(theme: _getTheme());
    final nowStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (context) => pw.Column(
          children: [
            _headerBlock(
              title: 'শেয়ারহোল্ডার তালিকা',
              metaLabel: 'মোট সদস্য :',
              metaValue: '${members.length} জন',
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _text('তারিখ: $nowStr', style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
                _text('পৃষ্ঠা ${context.pageNumber} / ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: _rule, thickness: 0.75),
            pw.SizedBox(height: 6),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: _rule, thickness: 0.75),
            pw.SizedBox(height: 4),
            _text('সম্প্রীতি ইনভেস্টমেন্ট ফোরাম • সর্বস্বত্ব সংরক্ষিত',
                style: const pw.TextStyle(fontSize: 7, color: _muted)),
          ],
        ),
        build: (context) => [
          _buildTable(
            headers: ['ক্র.', 'শেয়ার নং', 'সদস্যের নাম', 'পিতার নাম', 'মোবাইল', 'শেয়ার', 'পেশা'],
            data: members.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final m = entry.value;
              return [
                '$idx',
                m.no,
                m.displayName,
                m.father.isNotEmpty ? m.father : '—',
                m.mobile.isNotEmpty ? m.mobile : '—',
                '${m.shares} টি',
                m.job.isNotEmpty ? m.job : '—',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _white),
            headerDecoration: const pw.BoxDecoration(color: _maroon),
            cellStyle: const pw.TextStyle(fontSize: 7, color: _ink),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ==========================================
  // 7. MEMBER LOGIN PIN SHEET (ADMIN ONLY)
  // ==========================================
  static Future<Uint8List> generateMemberPinsPdf(List<MemberModel> members) async {
    await _initResources();
    final doc = pw.Document(theme: _getTheme());
    final nowStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        header: (context) => pw.Column(
          children: [
            _headerBlock(
              title: 'সদস্য পিন শিট (গোপনীয়)',
              metaLabel: 'তারিখ :',
              metaValue: nowStr,
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _text('তারিখ: $nowStr', style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
                _text('পৃষ্ঠা ${context.pageNumber} / ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: _rule, thickness: 0.75),
            pw.SizedBox(height: 6),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: _rule, thickness: 0.75),
            pw.SizedBox(height: 4),
            _text('সতর্কতা: এই তালিকাটি অত্যন্ত গোপনীয়। কোনো অননুমোদিত ব্যক্তির নিকট হস্তান্তর করিবেন না।',
                style: const pw.TextStyle(fontSize: 7, color: _error)),
          ],
        ),
        build: (context) => [
          _buildTable(
            headers: ['ক্রমিক', 'শেয়ার নম্বর', 'সদস্যের নাম', 'মোবাইল নম্বর', 'লগইন পিন (PIN)'],
            data: members.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final m = entry.value;
              final pinDisplay = (m.plainPin != null && m.plainPin!.isNotEmpty)
                  ? m.plainPin!
                  : ((m.pin != null && m.pin!.isNotEmpty) ? 'সেট আছে' : 'সেট নেই');
              return [
                '$idx',
                m.no,
                m.displayName,
                m.mobile.isNotEmpty ? m.mobile : '—',
                pinDisplay,
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _white),
            headerDecoration: const pw.BoxDecoration(color: _maroon),
            cellStyle: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: _ink),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          ),
          pw.SizedBox(height: 24),

          // Signatures (Matching HTML spec)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                children: [
                  pw.Container(width: 120, height: 0.75, color: _muted),
                  pw.SizedBox(height: 4),
                  _text('প্রস্তুতকারী\n(স্বাক্ষর)', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 120, height: 0.75, color: _muted),
                  pw.SizedBox(height: 4),
                  _text('সাধারণ সম্পাদক\n(স্বাক্ষর)', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                ],
              ),
              pw.Column(
                children: [
                  pw.Container(width: 120, height: 0.75, color: _muted),
                  pw.SizedBox(height: 4),
                  _text('সভাপতি\n(স্বাক্ষর)', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ==========================================
  // 8. TRANSACTION LEDGER REPORT
  // ==========================================
  /// Meeting resolution sheet (মিটিং রেজুলেশন): info, agenda-wise decisions, extra decisions,
  /// attendance with signatures, closing statement, president signature.
  static Future<Uint8List> generateMeetingResolutionPdf(MeetingModel m) async {
    await _initResources();
    final doc = pw.Document(theme: _getTheme());
    final nowStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    pw.Widget infoLine(String label, String value) => pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 2),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.SizedBox(
                width: 90,
                child: _text(label, style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _maroon)),
              ),
              pw.Expanded(
                child: _text(value.isEmpty ? '—' : value, style: const pw.TextStyle(fontSize: 9.5, color: _ink)),
              ),
            ],
          ),
        );

    pw.Widget section(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12, bottom: 5),
          child: _text(t, style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: _maroon)),
        );

    final typeLine = [MeetingType.monthly, MeetingType.emergency, MeetingType.agm]
        .map((t) => '[${m.type == t ? 'x' : ' '}] ${MeetingType.label(t)}')
        .join('    ');

    final agendaRows = [
      for (var i = 0; i < m.agendas.length; i++)
        [
          bnDigits('${i + 1}'),
          m.agendas[i],
          i < m.agendaDecisions.length && m.agendaDecisions[i].isNotEmpty ? m.agendaDecisions[i] : '—',
        ],
    ];

    final attRows = [
      for (var i = 0; i < m.attendance.length; i++)
        [
          bnDigits('${i + 1}'),
          m.attendance[i].name,
          m.attendance[i].designation.isEmpty ? '—' : m.attendance[i].designation,
          m.attendance[i].present ? 'উপস্থিত' : 'অনুপস্থিত',
          m.attendance[i].signature,
        ],
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 30),
        header: (context) => pw.Column(
          children: [
            _headerBlock(title: 'মিটিং রেজুলেশন', metaLabel: 'তারিখ :', metaValue: nowStr),
            pw.SizedBox(height: 6),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _text('সম্প্রীতি — মিটিং রেজুলেশন নথিপত্র', style: const pw.TextStyle(fontSize: 7, color: _muted)),
            _text('পৃষ্ঠা ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 7, color: _muted)),
          ],
        ),
        build: (context) => [
          // 1. Meeting info
          section('১. সভার ধরণ ও বিবরণ'),
          _text(typeLine, style: const pw.TextStyle(fontSize: 9, color: _ink)),
          pw.SizedBox(height: 4),
          infoLine('তারিখ', m.uiDate),
          infoLine('সময়', m.time),
          infoLine('স্থান', m.place),
          infoLine('সভাপতিত্বে', m.presiding),
          infoLine('সভার উদ্দেশ্য', m.purpose),

          // 2. Agenda + decisions
          section('২. সভার এজেন্ডা ও গৃহীত সিদ্ধান্তসমূহ'),
          _buildTable(
            headers: ['ক্রমিক', 'এজেন্ডা', 'গৃহীত সিদ্ধান্ত'],
            data: agendaRows,
            columnWidths: const {
              0: pw.FixedColumnWidth(40),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(3),
            },
            cellStyle: const pw.TextStyle(fontSize: 8, color: _ink),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          ),

          // 3. Extra decisions
          if (m.extraDecisions.isNotEmpty) ...[
            section('৩. অতিরিক্ত সিদ্ধান্তসমূহ'),
            for (var i = 0; i < m.extraDecisions.length; i++)
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 3),
                child: _text('${bnDigits('${i + 1}')}. ${m.extraDecisions[i]}',
                    style: const pw.TextStyle(fontSize: 9, color: _ink)),
              ),
          ],

          // 4. Attendance
          section('৪. উপস্থিতি ও স্বাক্ষর'),
          _buildTable(
            headers: ['ক্রমিক', 'সদস্যের নাম', 'পদবী', 'উপস্থিতি', 'স্বাক্ষর'],
            data: attRows,
            columnWidths: const {
              0: pw.FixedColumnWidth(40),
              1: pw.FlexColumnWidth(2),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(1.4),
              4: pw.FlexColumnWidth(2),
            },
            cellStyle: const pw.TextStyle(fontSize: 8, color: _ink),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
            footerRow: ['মোট উপস্থিত', '', '', '${bnDigits('${m.presentCount}')} জন', ''],
          ),

          // 5. Closing
          section('৫. সমাপ্তি ঘোষণা'),
          _text(m.closing.isEmpty ? _defaultMeetingClosing : m.closing,
              style: const pw.TextStyle(fontSize: 9, color: _ink)),

          // 6. President signature
          pw.SizedBox(height: 36),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Column(
              children: [
                pw.Container(width: 150, height: 0.75, color: _ink),
                pw.SizedBox(height: 4),
                _text('সভাপতি', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _ink)),
                _text('সম্প্রীতি', style: const pw.TextStyle(fontSize: 8, color: _muted)),
              ],
            ),
          ),
        ],
      ),
    );

    return doc.save();
  }

  static const String _defaultMeetingClosing =
      'সভায় আর কোনো আলোচনা না থাকায় সভাপতি মহোদয় উপস্থিত সকলকে ধন্যবাদ জানিয়ে সভার সমাপ্তি ঘোষণা করেন।';

  /// Detailed financial report for one period: summary, funds, monthly trend, projects,
  /// sectors, members. Portrait A4 with compact tables.
  static Future<Uint8List> generateDetailedFinancialReportPdf(FinancialReportModel r) async {
    await _initResources();
    final doc = pw.Document(theme: _getTheme());
    final nowStr = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());

    pw.Widget sectionTitle(String t) => pw.Padding(
          padding: const pw.EdgeInsets.only(top: 12, bottom: 5),
          child: _text(t, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: _maroon)),
        );

    pw.Widget table(List<String> h, List<List<String>> d, {List<String>? foot, Map<int, pw.Alignment>? align}) {
      final cols = <int, pw.TableColumnWidth>{
        for (var i = 0; i < h.length; i++) i: const pw.FlexColumnWidth(1),
      };
      return _buildTable(
        headers: h,
        data: d,
        columnWidths: cols,
        columnAlignments: align,
        cellStyle: const pw.TextStyle(fontSize: 7, color: _ink),
        footerRow: foot,
      );
    }

    String amt(double v) => _formatAmount(v);
    final right = <int, pw.Alignment>{
      for (var i = 1; i < 12; i++) i: pw.Alignment.centerRight,
    };

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        header: (context) => pw.Column(
          children: [
            _headerBlock(title: 'আর্থিক বিবরণী প্রতিবেদন', metaLabel: 'তারিখ :', metaValue: nowStr),
            pw.SizedBox(height: 4),
            _text('সময়কাল: ${r.period.label}', style: const pw.TextStyle(fontSize: 8, color: _muted)),
            pw.SizedBox(height: 6),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _text('সম্প্রীতি ইনভেস্টমেন্ট ফোরাম • সর্বস্বত্ব সংরক্ষিত',
                style: const pw.TextStyle(fontSize: 7, color: _muted)),
            _text('পৃষ্ঠা ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 7, color: _muted)),
          ],
        ),
        build: (context) => [
          pw.Table(children: [
            pw.TableRow(children: [
              _statCell('মোট আয়', r.totalIncome, color: _success),
              _statCell('মোট ব্যয়', r.totalExpense, color: _error),
              _statCell('মুনাফা বণ্টন', r.totalPayout, color: _maroon),
              _statCell('নিট ফলাফল', r.netResult, color: _goldDark),
            ]),
            pw.TableRow(children: [
              _statCell('প্রারম্ভিক তহবিল', r.openingFunds),
              _statCell('সমাপনী তহবিল', r.closingFunds, color: _success),
              _statCell('ভাউচার সংখ্যা', r.voucherCount),
              _statCell('ব্যাংক স্থানান্তর', r.transferCount),
            ]),
          ]),

          sectionTitle('১. নগদ ও ব্যাংক'),
          table(
            ['হিসাব', 'শুরুর স্থিতি', 'জমা', 'উত্তোলন', 'সমাপনী স্থিতি'],
            [for (final f in r.funds) [f.name, amt(f.opening), amt(f.inflow), amt(f.outflow), amt(f.closing)]],
            foot: ['মোট', amt(r.openingFunds), amt(r.funds.fold(0.0, (s, f) => s + f.inflow)),
                amt(r.funds.fold(0.0, (s, f) => s + f.outflow)), amt(r.closingFunds)],
            align: right,
          ),

          sectionTitle('২. Monthly Trend'),
          table(
            ['মাস', 'আয়', 'ব্যয়', 'মুনাফা বণ্টন', 'নিট'],
            [for (final m in r.months) [m.label, amt(m.income), amt(m.expense), amt(m.payout), amt(m.net)]],
            foot: [
              'মোট',
              amt(r.totalIncome),
              amt(r.totalExpense),
              amt(r.totalPayout),
              amt(r.netResult),
            ],
            align: right,
          ),

          sectionTitle('৩. প্রকল্পভিত্তিক'),
          table(
            ['প্রকল্প', 'অবস্থা', 'বাজেট', 'আয়', 'ব্যয়', 'নিট', 'বণ্টিত', 'সদস্য বিনিয়োগ', 'সদস্য'],
            [
              for (final p in r.projects)
                [
                  p.name,
                  p.isActive ? 'চলমান' : 'সমাপ্ত',
                  p.budget > 0 ? amt(p.budget) : '—',
                  amt(p.income),
                  amt(p.expense),
                  amt(p.net),
                  amt(p.payout),
                  amt(p.memberInvestment),
                  '${p.memberCount}',
                ],
            ],
            align: right,
          ),

          sectionTitle('৪. খাতভিত্তিক আয়'),
          table(
            ['খাত', 'ভাউচার', 'টাকা', '%'],
            [for (final s in r.incomeSectors) [s.name, '${s.count}', amt(s.amount), '${s.percent.toStringAsFixed(1)}%']],
            align: right,
          ),

          sectionTitle('৫. খাতভিত্তিক ব্যয়'),
          table(
            ['খাত', 'ভাউচার', 'টাকা', '%'],
            [for (final s in r.expenseSectors) [s.name, '${s.count}', amt(s.amount), '${s.percent.toStringAsFixed(1)}%']],
            align: right,
          ),

          sectionTitle('৬. সদস্যভিত্তিক'),
          table(
            ['শেয়ার নং', 'নাম', 'শেয়ার', 'নীতিমালা', 'বিনিয়োগ', 'মুনাফা', 'মূলধন ফেরত', 'নিট মূলধন'],
            [
              for (final m in r.members)
                [
                  m.no,
                  m.name,
                  '${m.shares}',
                  m.policyLabel,
                  amt(m.investment),
                  amt(m.profitReceived),
                  amt(m.capitalReturn),
                  amt(m.netCapital),
                ],
            ],
            align: right,
          ),

          pw.SizedBox(height: 22),
          _signatureRow(['অর্থ সম্পাদক', 'সাধারণ সম্পাদক', 'সভাপতি']),
        ],
      ),
    );

    return doc.save();
  }

  /// Detailed ledger (landscape): in/out columns, running balance, totals, signatures.
  /// Member statement mode when [member] is given and the ledger is in member mode.
  static Future<Uint8List> generateDetailedLedgerPdf(
    LedgerReport ledger, {
    required String title,
    required String periodLabel,
    String? filterLabel,
    Map<String, String> projectNames = const {},
    MemberModel? member,
  }) async {
    await _initResources();
    final doc = pw.Document(theme: _getTheme());
    final nowStr = DateFormat('dd/MM/yyyy hh:mm a').format(DateTime.now());
    final isMember = ledger.memberMode;
    final showBal = ledger.showBalance;

    final headers = <String>[
      'ভাউচার',
      'তারিখ',
      'বিবরণ',
      'খাত',
      'প্রকল্প / সদস্য',
      'মাধ্যম',
      (isMember ? 'বিনিয়োগ' : 'আয়'),
      (isMember ? 'প্রাপ্তি' : 'ব্যয়'),
      if (showBal) (isMember ? 'মূলধন স্থিতি' : 'চলমান স্থিতি'),
    ];

    final data = ledger.rows.map((r) {
      final t = r.trx;
      final party = t.member.isNotEmpty
          ? t.member
          : (t.project.isNotEmpty ? (projectNames[t.project] ?? t.project) : '—');
      final desc = t.note.isNotEmpty ? t.note : t.title;
      String amt(double v) => v == 0 ? '—' : _formatAmount(v);
      return <String>[
        t.vno,
        DateFormatter.ddMMyyyy(t.date),
        desc,
        t.sectorName.isEmpty ? '—' : t.sectorName,
        party,
        _getModeTitle(t.mode),
        amt(r.inAmount),
        amt(r.outAmount),
        if (showBal) (r.balance == null ? '—' : _formatAmount(r.balance!)),
      ];
    }).toList();

    final widths = <double>[1.1, 1.0, 2.4, 1.6, 1.6, 1.4, 1.1, 1.1, 1.3];
    final columnWidths = <int, pw.TableColumnWidth>{
      for (var i = 0; i < headers.length; i++) i: pw.FlexColumnWidth(widths[i]),
    };
    final rightCols = <int, pw.Alignment>{
      6: pw.Alignment.centerRight,
      7: pw.Alignment.centerRight,
      8: pw.Alignment.centerRight,
    };
    final footer = <String>[
      'মোট',
      '',
      '',
      '',
      '',
      '',
      _formatAmount(ledger.totalIn),
      _formatAmount(ledger.totalOut),
      if (showBal) '',
    ];

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        header: (context) => pw.Column(
          children: [
            _headerBlock(title: title, metaLabel: 'তারিখ :', metaValue: nowStr),
            pw.SizedBox(height: 4),
            _text(
              'সময়কাল: $periodLabel${filterLabel == null ? '' : '  •  ফিল্টার: $filterLabel'}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pw.SizedBox(height: 6),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            _text('সম্প্রীতি ইনভেস্টমেন্ট ফোরাম • সর্বস্বত্ব সংরক্ষিত',
                style: const pw.TextStyle(fontSize: 7, color: _muted)),
            _text('পৃষ্ঠা ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 7, color: _muted)),
          ],
        ),
        build: (context) => [
          if (isMember && member != null)
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              margin: const pw.EdgeInsets.only(bottom: 10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _rule, width: 0.5),
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: _text(
                'সদস্য: ${member.displayName}  •  শেয়ার নং: ${member.no}  •  শেয়ার: ${member.shares} টি'
                '${member.founder || member.labor ? '  •  ${[if (member.founder) 'প্রতিষ্ঠাতা', if (member.labor) 'শ্রমদাতা'].join(', ')}' : ''}',
                style: const pw.TextStyle(fontSize: 9, color: _ink),
              ),
            ),
          pw.Table(
            children: [
              pw.TableRow(children: [
                _statCell('শুরুর স্থিতি', ledger.opening),
                _statCell(isMember ? 'মোট বিনিয়োগ' : 'মোট আয়', ledger.totalIn, color: _success),
                _statCell(isMember ? 'মোট প্রাপ্তি' : 'মোট ব্যয়', ledger.totalOut, color: _error),
                _statCell('শেষ স্থিতি', ledger.closing, color: _maroon),
              ]),
            ],
          ),
          pw.SizedBox(height: 6),
          _text(
            'মুনাফা বণ্টন: ${_formatAmount(ledger.totalPayout)}'
            '${isMember ? '  •  মূলধন ফেরত: ${_formatAmount(ledger.totalCapitalReturn)}' : ''}'
            '  •  ব্যাংক স্থানান্তর: ${ledger.transferCount} টি',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
          pw.SizedBox(height: 8),
          _buildTable(
            headers: headers,
            data: data,
            columnWidths: columnWidths,
            columnAlignments: rightCols,
            cellStyle: const pw.TextStyle(fontSize: 7, color: _ink),
            footerRow: footer,
          ),
          pw.SizedBox(height: 16),
          _signatureRow(['প্রস্তুতকারী', 'সাধারণ সম্পাদক', 'সভাপতি']),
        ],
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> generateLedgerPdf(
    List<TransactionModel> transactions, {
    String? title,
  }) async {
    await _initResources();
    final doc = pw.Document(theme: _getTheme());
    final nowStr = DateFormat('dd/MM/yyyy').format(DateTime.now());

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (context) => pw.Column(
          children: [
            _headerBlock(
              title: title ?? 'লেনদেন খতিয়ান',
              metaLabel: 'তারিখ :',
              metaValue: nowStr,
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                _text('মোট লেনদেন: ${transactions.length}টি  •  তারিখ: $nowStr',
                    style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
                _text('পৃষ্ঠা ${context.pageNumber} / ${context.pagesCount}',
                    style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
              ],
            ),
            pw.SizedBox(height: 6),
            pw.Divider(color: _rule, thickness: 0.75),
            pw.SizedBox(height: 6),
          ],
        ),
        footer: (context) => pw.Column(
          children: [
            pw.Divider(color: _rule, thickness: 0.75),
            pw.SizedBox(height: 4),
            _text('সম্প্রীতি ইনভেস্টমেন্ট ফোরাম • সর্বস্বত্ব সংরক্ষিত',
                style: const pw.TextStyle(fontSize: 7, color: _muted)),
          ],
        ),
        build: (context) => [
          _buildTable(
            headers: ['ভাউচার', 'তারিখ', 'লেনদেনের ধরন', 'সদস্য/প্রতিষ্ঠান', 'মাধ্যম', 'পরিমাণ'],
            data: transactions.map((t) {
              final target = t.member.isNotEmpty ? t.member : t.project.isNotEmpty ? t.project : '—';
              final isPos = t.sign > 0;
              final prefix = isPos ? '+৳ ' : t.sign < 0 ? '-৳ ' : '৳ ';
              return [
                t.vno,
                DateFormatter.ddMMyyyy(t.date),
                t.title,
                target,
                _getModeTitle(t.mode),
                '$prefix${_formatAmount(t.amount)}',
              ];
            }).toList(),
            headerStyle: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: _white),
            headerDecoration: const pw.BoxDecoration(color: _maroon),
            cellStyle: const pw.TextStyle(fontSize: 7, color: _ink),
            cellAlignment: pw.Alignment.centerLeft,
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          ),
        ],
      ),
    );

    return doc.save();
  }
}
