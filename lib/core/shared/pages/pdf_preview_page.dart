import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/config/colors.dart';

class PdfPreviewPage extends StatefulWidget {
  final String title;
  final String pdfFileName;
  final Future<Uint8List> Function() buildPdf;

  static Route route({
    required String title,
    required String pdfFileName,
    required Future<Uint8List> Function() buildPdf,
  }) =>
      MaterialPageRoute(
        builder: (_) => PdfPreviewPage(
          title: title,
          pdfFileName: pdfFileName,
          buildPdf: buildPdf,
        ),
      );

  const PdfPreviewPage({
    super.key,
    required this.title,
    required this.pdfFileName,
    required this.buildPdf,
  });

  @override
  State<PdfPreviewPage> createState() => _PdfPreviewPageState();
}

class _PdfPreviewPageState extends State<PdfPreviewPage> {
  late Future<Uint8List> _pdfFuture;

  @override
  void initState() {
    super.initState();
    _pdfFuture = widget.buildPdf();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          widget.title,
          style: GoogleFonts.notoSansBengali(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        initialPageFormat: PdfPageFormat.a4,
        pageFormats: const {'A4': PdfPageFormat.a4},
        pdfFileName: widget.pdfFileName,
        build: (_) => _pdfFuture,
        onError: (context, error) => const Center(
          child: Text(
            'পিডিএফ লোড হতে সমস্যা হয়েছে',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        scrollViewDecoration: const BoxDecoration(
          color: AppColors.background,
        ),
        pdfPreviewPageDecoration: BoxDecoration(
          color: AppColors.white,
          border: Border.all(width: 1, color: AppColors.inputBorder),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        maxPageWidth: double.infinity,
      ),
    );
  }
}
