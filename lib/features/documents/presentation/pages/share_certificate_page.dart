import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/member_avatar.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/assets.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/services/pdf_document_service.dart';
import 'package:sampriti/core/shared/pages/pdf_preview_page.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';

class ShareCertificatePage extends StatefulWidget {
  final String memberNo;

  static Route route({required String memberNo}) => MaterialPageRoute(
        builder: (_) => ShareCertificatePage(memberNo: memberNo),
      );

  const ShareCertificatePage({super.key, required this.memberNo});

  @override
  State<ShareCertificatePage> createState() => _ShareCertificatePageState();
}

class _ShareCertificatePageState extends State<ShareCertificatePage> {
  MemberModel? _member;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final m = await MembersRepo.getMemberByNo(widget.memberNo);
    if (mounted) {
      setState(() {
        _member = m;
        _isLoading = false;
      });
    }
  }

  String _numberToWord(int n) {
    const words = ['', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten'];
    if (n > 0 && n < words.length) return words[n];
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'Share Certificate',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_member != null)
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPrinter,
                size: 22,
                color: AppColors.primary,
              ),
              tooltip: 'Print / PDF Preview',
              onPressed: _openPdfPreview,
            ),
        ],
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: Loader())
            : _member == null
                ? Center(
                    child: Container(
                      margin: const EdgeInsets.all(24),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 48, color: AppColors.error),
                          const SizedBox(height: 16),
                          Text(
                            'Certificate Access Restricted',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Only authenticated shareholders may view their own certificate.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Royal Certificate Card (All English)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFDF7), // Soft cream parchment tone
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.accentYellow,
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                            ),
                            child: Column(
                              children: [
                                // Logo / Banner Emblem
                                Image.asset(
                                  Assets.logoBanner,
                                  height: 48,
                                  fit: BoxFit.contain,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'SAMPRITI INVESTMENT FORUM',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'SHARE CERTIFICATE',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Certificate No: CERT-${_member!.no}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Member Passport Photo
                                MemberAvatar(
                                  photo: _member!.photo,
                                  fallbackText: _member!.no,
                                  width: 88,
                                  height: 110,
                                  isCircle: false,
                                  borderRadius: 6,
                                  border: Border.all(
                                    color: AppColors.accentYellow.withValues(alpha: 0.8),
                                    width: 2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'This is to certify that',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Single English Name (Large & Prominent)
                                Text(
                                  _member!.nameEn.isNotEmpty ? _member!.nameEn : _member!.displayName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 14),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'is a bonafide registered shareholder of Sampriti Investment Forum, holding ${_member!.shares} (${_numberToWord(_member!.shares)}) ordinary share(s) under Share No. ${_member!.no}. The shareholder is entitled to all rights, privileges, and dividend distributions in accordance with the constitution and regulations of the forum.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      height: 1.6,
                                      color: AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 36),

                                // Signatures (Shareholder, General Secretary, President)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSigBlock('Shareholder'),
                                    _buildSigBlock('General Secretary'),
                                    _buildSigBlock('President'),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // PDF Action Button
                        SpringButton(
                          width: double.infinity,
                          onPressed: _openPdfPreview,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const HugeIcon(
                                icon: HugeIcons.strokeRoundedPrinter,
                                size: 20,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Print & Download PDF',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
      ),
    );
  }

  void _openPdfPreview() {
    if (_member == null) return;
    Navigator.push(
      context,
      PdfPreviewPage.route(
        title: 'Share Certificate (${_member!.no})',
        pdfFileName: 'sampriti-share-certificate-${_member!.no}.pdf',
        buildPdf: () => PdfDocumentService.generateShareCertificate(_member!),
      ),
    );
  }

  Widget _buildSigBlock(String title) {
    return Column(
      children: [
        Container(
          width: 95,
          height: 1,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
