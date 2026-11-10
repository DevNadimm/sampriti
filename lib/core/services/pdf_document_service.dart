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
import 'package:sampriti/features/members/data/models/member_model.dart';
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
  static Uint8List? _logoBytes;

  static Future<void> _initResources() async {
    _bengaliBase ??= await PdfGoogleFonts.notoSansBengaliRegular();
    _bengaliBold ??= await PdfGoogleFonts.notoSansBengaliBold();
    _robotoBase ??= await PdfGoogleFonts.robotoRegular();
    _robotoBold ??= await PdfGoogleFonts.robotoBold();

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
      ],
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
  // 1. SHARE CERTIFICATE
  // ==========================================
  static Future<Uint8List> generateShareCertificate(MemberModel member) async {
    await _initResources();
    final doc = pw.Document(theme: _getTheme());
    final photo = _parseImage(member.photo);

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (context) {
          return pw.Container(
            decoration: pw.BoxDecoration(
              color: _cream,
              border: pw.Border.all(color: _maroon, width: 2.5),
            ),
            padding: const pw.EdgeInsets.all(6),
            child: pw.Container(
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _gold, width: 1.0),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Unified Header
                  _headerBlock(
                    title: 'শেয়ার সনদপত্র',
                    leftMetaLabel: 'সনদ নং :',
                    leftMetaValue: 'CERT-${member.no}',
                    metaLabel: 'শেয়ার নং :',
                    metaValue: member.no,
                  ),
                  pw.SizedBox(height: 10),

                  // Member Photo Frame
                  pw.Container(
                    width: 78,
                    height: 96,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _gold, width: 1.5),
                      color: _white,
                    ),
                    child: photo != null
                        ? pw.Image(photo, fit: pw.BoxFit.cover)
                        : pw.Center(
                            child: _text(
                              member.no,
                              style: pw.TextStyle(
                                fontSize: 13,
                                fontWeight: pw.FontWeight.bold,
                                color: _muted,
                              ),
                            ),
                          ),
                  ),
                  pw.SizedBox(height: 12),

                  // Official Bengali Statement
                  _text(
                    'এই মর্মে প্রত্যয়ন করা যাইতেছে যে,',
                    style: const pw.TextStyle(fontSize: 10, color: _muted),
                  ),
                  pw.SizedBox(height: 4),
                  _text(
                    member.displayName,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: _maroonDark,
                    ),
                  ),
                  if (member.nameEn.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    _text(
                      member.nameEn,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _muted,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 10),

                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 16),
                    child: _text(
                      '“সম্প্রীতি” সংগঠনের একজন নিবন্ধিত শেয়ারহোল্ডার এবং নিম্নে উল্লিখিত শেয়ারের ধারক। পিতা: ${member.father.isNotEmpty ? member.father : "—"}, মাতা: ${member.mother.isNotEmpty ? member.mother : "—"}, ঠিকানা: ${member.address.isNotEmpty ? member.address : "—"}। মোট শেয়ার সংখ্যা: ${member.shares} টি। তিনি সংগঠনের সকল নিয়ম ও নীতিমালার আওতাভুক্ত।',
                      textAlign: pw.TextAlign.center,
                      style: const pw.TextStyle(fontSize: 9.5, lineSpacing: 1.45, color: _ink),
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  _text(
                    'শেয়ার নম্বর: ${member.no}',
                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: _muted),
                  ),
                  pw.SizedBox(height: 24),

                  // Signatures Block (Matching HTML spec: শেয়ার হোল্ডার, সাধারণ সম্পাদক, সভাপতি)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Column(
                        children: [
                          pw.Container(width: 120, height: 0.75, color: _muted),
                          pw.SizedBox(height: 4),
                          _text('শেয়ার হোল্ডার\n(স্বাক্ষর)', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8, color: _ink)),
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
              buildVoucherRow('লেনদেনের ধরন', trx.typeTitle),
              if (trx.member.isNotEmpty)
                buildVoucherRow('সদস্য', memberName != null && memberName.isNotEmpty ? '$memberName (${trx.member})' : trx.member),
              if (trx.inst.isNotEmpty)
                buildVoucherRow('প্রতিষ্ঠান', instName != null && instName.isNotEmpty ? instName : trx.inst),
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
                buildStatCell('প্রতিষ্ঠানে মোট বিনিয়োগ', summary.institutionInvestment),
                buildStatCell('লোন বকেয়া', summary.loanOutstanding, color: _error),
                buildStatCell('প্রতিষ্ঠান থেকে আয়', summary.institutionIncome, color: _success),
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
                buildStatCell('মোট অনুদান/ডোনেশন', summary.totalDonation),
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
                final target = t.member.isNotEmpty ? t.member : t.inst.isNotEmpty ? t.inst : '—';
                return [
                  t.vno,
                  DateFormatter.ddMMyyyy(t.date),
                  t.typeTitle,
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
              final target = t.member.isNotEmpty ? t.member : t.inst.isNotEmpty ? t.inst : '—';
              final isPos = t.sign > 0;
              final prefix = isPos ? '+৳ ' : t.sign < 0 ? '-৳ ' : '৳ ';
              return [
                t.vno,
                DateFormatter.ddMMyyyy(t.date),
                t.typeTitle,
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
