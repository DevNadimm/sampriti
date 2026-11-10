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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'শেয়ার সনদপত্র',
          style: GoogleFonts.notoSansBengali(
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
              tooltip: 'প্রিন্ট / PDF প্রিভিউ',
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
                            'সার্টিফিকেট দেখার অনুমতি নেই',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'শেয়ারহোল্ডার শুধুমাত্র তার নিজস্ব শেয়ার সনদপত্র দেখতে পারবেন।',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.notoSansBengali(
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
                        // Royal Certificate Card
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
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                    letterSpacing: 2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    'শেয়ার সার্টিফিকেট (SHARE CERTIFICATE)',
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'সনদ নম্বর: CERT-${_member!.no}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                // Member Passport Photo
                                MemberAvatar(
                                  photo: _member!.photo,
                                  fallbackText: _member!.no,
                                  width: 85,
                                  height: 105,
                                  isCircle: false,
                                  borderRadius: 6,
                                  border: Border.all(
                                    color: AppColors.accentYellow.withValues(alpha: 0.8),
                                    width: 2,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  'এই মর্মে প্রত্যয়ন করা যাইতেছে যে,',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 13,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _member!.displayName,
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                if (_member!.nameEn.isNotEmpty) ...[
                                  Text(
                                    _member!.nameEn,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  child: Text(
                                    'সম্প্রীতি ইনভেস্টমেন্ট ফোরাম এর একজন সম্মানিত অংশীদার হিসেবে মোট ${_member!.shares} (এক) টি সাধারণ শেয়ারের স্বত্বাধিকারী। তাঁহার শেয়ার নম্বর ${_member!.no}। তিনি সংগঠনের সকল নিয়ম ও মুনাফা বণ্টনের আওতাভুক্ত।',
                                    style: GoogleFonts.notoSansBengali(
                                      fontSize: 13,
                                      height: 1.6,
                                      color: AppColors.textPrimary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                const SizedBox(height: 36),

                                // Signatures (Matching HTML spec: শেয়ার হোল্ডার, সাধারণ সম্পাদক, সভাপতি)
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    _buildSigBlock('শেয়ার হোল্ডার'),
                                    _buildSigBlock('সাধারণ সম্পাদক'),
                                    _buildSigBlock('সভাপতি'),
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
                                'প্রিন্ট ও PDF ডাউনলোড',
                                style: GoogleFonts.notoSansBengali(
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
        title: 'শেয়ার সনদপত্র (${_member!.no})',
        pdfFileName: 'sampriti-share-certificate-${_member!.no}.pdf',
        buildPdf: () => PdfDocumentService.generateShareCertificate(_member!),
      ),
    );
  }

  Widget _buildSigBlock(String title) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 1,
          color: AppColors.primary.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: GoogleFonts.notoSansBengali(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
