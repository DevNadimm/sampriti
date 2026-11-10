import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/config/colors.dart';

class PdfPreviewPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          title,
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
        pdfFileName: pdfFileName,
        build: (_) => buildPdf(),
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
