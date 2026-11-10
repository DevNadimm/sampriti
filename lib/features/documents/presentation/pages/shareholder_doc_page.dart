import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/info_row.dart';
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

class ShareholderDocPage extends StatefulWidget {
  final String memberNo;

  static Route route({required String memberNo}) => MaterialPageRoute(
        builder: (_) => ShareholderDocPage(memberNo: memberNo),
      );

  const ShareholderDocPage({super.key, required this.memberNo});

  @override
  State<ShareholderDocPage> createState() => _ShareholderDocPageState();
}

class _ShareholderDocPageState extends State<ShareholderDocPage> {
  MemberModel? _member;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
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
          'শেয়ার আবেদন ও প্রত্যয়ন পত্র',
          style: GoogleFonts.notoSansBengali(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_member != null)
            PopupMenuButton<String>(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPrinter,
                size: 22,
                color: AppColors.primary,
              ),
              tooltip: 'PDF ডাউনলোড ও প্রিন্ট',
              onSelected: (val) {
                if (val == 'share') {
                  _openShareFormPdf();
                } else if (val == 'nominee') {
                  _openNomineeFormPdf();
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedFile01, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('শেয়ার আবেদন ফরম PDF', style: GoogleFonts.notoSansBengali(fontSize: 13)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'nominee',
                  child: Row(
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedUserMultiple, size: 18, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text('নমিনী ফরম PDF', style: GoogleFonts.notoSansBengali(fontSize: 13)),
                    ],
                  ),
                ),
              ],
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
                            'আবেদন ফরম দেখার অনুমতি নেই',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'শেয়ারহোল্ডার শুধুমাত্র তার নিজস্ব আবেদন ও প্রত্যয়ন ফরম দেখতে পারবেন।',
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
                        // Official Document Slip
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.04),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Organization Header
                              Center(
                                child: Column(
                                  children: [
                                    Image.asset(
                                      Assets.logoBanner,
                                      height: 42,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      'সদস্যপদ আবেদন ও নমিনী প্রত্যয়ন পত্র',
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'শেয়ার নং: ${_member!.no}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              const Divider(height: 1),
                              const SizedBox(height: 16),

                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '১. আবেদনকারীর ব্যক্তিগত বিবরণ',
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'শেয়ারহোল্ডার প্রোফাইল ও পরিচিতি',
                                          style: GoogleFonts.notoSansBengali(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  MemberAvatar(
                                    photo: _member!.photo,
                                    fallbackText: _member!.no,
                                    width: 70,
                                    height: 88,
                                    isCircle: false,
                                    borderRadius: 6,
                                    border: Border.all(
                                      color: AppColors.border,
                                      width: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              InfoRow(label: 'আবেদনকারীর নাম (বাংলায়)', value: _member!.displayName),
                              if (_member!.nameEn.isNotEmpty)
                                InfoRow(label: 'Name in English', value: _member!.nameEn),
                              InfoRow(label: 'পিতার নাম', value: _member!.father.isNotEmpty ? _member!.father : '—'),
                              InfoRow(label: 'মাতার নাম', value: _member!.mother.isNotEmpty ? _member!.mother : '—'),
                              InfoRow(label: 'স্বামী / স্ত্রীর নাম', value: _member!.spouse.isNotEmpty ? _member!.spouse : '—'),
                              InfoRow(label: 'জাতীয় পরিচয়পত্র নম্বর (NID)', value: _member!.nid.isNotEmpty ? _member!.nid : '—'),
                              InfoRow(label: 'জন্ম তারিখ', value: _member!.uiBirth.isNotEmpty ? _member!.uiBirth : '—'),
                              InfoRow(label: 'পেশা', value: _member!.job.isNotEmpty ? _member!.job : '—'),
                              InfoRow(label: 'মোবাইল নম্বর', value: _member!.mobile.isNotEmpty ? _member!.mobile : '—'),
                              InfoRow(label: 'ঠিকানা', value: _member!.address.isNotEmpty ? _member!.address : '—'),
                              InfoRow(label: 'শেয়ার সংখ্যা', value: '${_member!.shares} টি'),

                              const SizedBox(height: 20),
                              Text(
                                '২. মনোনীত নমিনীগণের বিবরণ',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (_member!.nominees.isEmpty)
                                Text(
                                  'কোনো নমিনী রেকর্ড করা হয়নি',
                                  style: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.textSecondary),
                                )
                              else
                                ..._member!.nominees.asMap().entries.map((entry) {
                                  final i = entry.key + 1;
                                  final n = entry.value;
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.border.withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$i. ${n.name} (${n.relation}) - প্রাপ্যাংশ: ${n.share}%',
                                                  style: GoogleFonts.notoSansBengali(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                if (n.mobile.isNotEmpty || n.nid.isNotEmpty || n.birth.isNotEmpty)
                                                  Text(
                                                    [
                                                      if (n.mobile.isNotEmpty) 'মোবাইল: ${n.mobile}',
                                                      if (n.nid.isNotEmpty) 'NID: ${n.nid}',
                                                      if (n.uiBirth.isNotEmpty) 'জন্ম: ${n.uiBirth}',
                                                    ].join(' | '),
                                                    style: GoogleFonts.poppins(
                                                      fontSize: 11,
                                                      color: AppColors.textSecondary,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (n.photo != null && n.photo!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8),
                                              child: MemberAvatar(
                                                photo: n.photo,
                                                fallbackText: 'নমিনী',
                                                width: 45,
                                                height: 55,
                                                isCircle: false,
                                                borderRadius: 4,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                              const SizedBox(height: 20),
                              Text(
                                '৩. আবেদনকারীর ঘোষণা ও অঙ্গীকার',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'আমি এই মর্মে অঙ্গীকার করিতেছি যে, উপরোক্ত বিবরণী সম্পূর্ণ সত্য ও সঠিক। আমি সম্প্রীতি ইনভেস্টমেন্ট ফোরামের গঠনতন্ত্র, নীতিমালা ও শৃঙ্খলা মানিয়া চলিব এবং সংগঠনের সার্বিক কল্যাণে সর্বদা সচেষ্ট থাকিব।',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 12,
                                  height: 1.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 48),

                              // Signature blocks
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildSignatureLine('আবেদনকারীর স্বাক্ষর'),
                                  _buildSignatureLine('যাচাইকারী'),
                                  _buildSignatureLine('সভাপতির স্বাক্ষর'),
                                ],
                              ),
                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // PDF Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: SpringButton(
                                onPressed: _openShareFormPdf,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const HugeIcon(
                                      icon: HugeIcons.strokeRoundedFile01,
                                      size: 18,
                                      color: AppColors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'শেয়ার আবেদন PDF',
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: SpringButton(
                                onPressed: _openNomineeFormPdf,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const HugeIcon(
                                      icon: HugeIcons.strokeRoundedUserMultiple,
                                      size: 18,
                                      color: AppColors.white,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'নমিনী ফরম PDF',
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
      ),
    );
  }

  void _openShareFormPdf() {
    if (_member == null) return;
    Navigator.push(
      context,
      PdfPreviewPage.route(
        title: 'শেয়ার আবেদন ফরম (${_member!.no})',
        pdfFileName: 'sampriti-share-form-${_member!.no}.pdf',
        buildPdf: () => PdfDocumentService.generateShareholderForm(_member!),
      ),
    );
  }

  void _openNomineeFormPdf() {
    if (_member == null) return;
    Navigator.push(
      context,
      PdfPreviewPage.route(
        title: 'নমিনী ফরম (${_member!.no})',
        pdfFileName: 'sampriti-nominee-form-${_member!.no}.pdf',
        buildPdf: () => PdfDocumentService.generateNomineeForm(_member!),
      ),
    );
  }

  Widget _buildSignatureLine(String label) {
    return Column(
      children: [
        Container(
          width: 85,
          height: 1,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.notoSansBengali(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
