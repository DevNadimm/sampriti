import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/info_row.dart';
import 'package:sampriti/core/components/member_avatar.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/services/pdf_document_service.dart';
import 'package:sampriti/core/shared/pages/pdf_preview_page.dart';
import 'package:sampriti/core/shared/widgets/app_confirmation_dialog.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/error_state_widget.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:sampriti/features/documents/presentation/pages/share_certificate_page.dart';
import 'package:sampriti/features/documents/presentation/pages/shareholder_doc_page.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/models/nominee_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';
import 'package:sampriti/features/members/presentation/bloc/member_bloc.dart';
import 'package:sampriti/features/members/presentation/pages/add_edit_nominee_page.dart';
import 'package:sampriti/features/members/presentation/pages/add_member_page.dart';

class MemberDetailsPage extends StatefulWidget {
  final String memberNo;

  static Route route({required String memberNo}) => MaterialPageRoute(
        builder: (_) => MemberDetailsPage(memberNo: memberNo),
      );

  const MemberDetailsPage({super.key, required this.memberNo});

  @override
  State<MemberDetailsPage> createState() => _MemberDetailsPageState();
}

class _MemberDetailsPageState extends State<MemberDetailsPage> {
  MemberModel? _member;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMember();
  }

  Future<void> _loadMember() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final m = await MembersRepo.getMemberByNo(widget.memberNo);
      if (mounted) {
        setState(() {
          _member = m;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthBloc>().state is AuthAuthenticated &&
        (context.read<AuthBloc>().state as AuthAuthenticated).session.isAdmin;

    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'সদস্য বিবরণী',
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
                size: 20,
                color: AppColors.primary,
              ),
              tooltip: 'PDF ডাউনলোড ও প্রিন্ট',
              onSelected: (val) {
                if (val == 'cert') {
                  Navigator.push(
                    context,
                    PdfPreviewPage.route(
                      title: 'শেয়ার সনদপত্র (${_member!.no})',
                      pdfFileName: 'sampriti-share-certificate-${_member!.no}.pdf',
                      buildPdf: () => PdfDocumentService.generateShareCertificate(_member!),
                    ),
                  );
                } else if (val == 'share') {
                  Navigator.push(
                    context,
                    PdfPreviewPage.route(
                      title: 'শেয়ার আবেদন ফরম (${_member!.no})',
                      pdfFileName: 'sampriti-share-form-${_member!.no}.pdf',
                      buildPdf: () => PdfDocumentService.generateShareholderForm(_member!),
                    ),
                  );
                } else if (val == 'nominee') {
                  Navigator.push(
                    context,
                    PdfPreviewPage.route(
                      title: 'নমিনী ফরম (${_member!.no})',
                      pdfFileName: 'sampriti-nominee-form-${_member!.no}.pdf',
                      buildPdf: () => PdfDocumentService.generateNomineeForm(_member!),
                    ),
                  );
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'cert',
                  child: Row(
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedAward02, size: 18, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text('শেয়ার সনদপত্র PDF', style: GoogleFonts.notoSansBengali(fontSize: 13)),
                    ],
                  ),
                ),
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
                      const HugeIcon(icon: HugeIcons.strokeRoundedUserMultiple, size: 18, color: AppColors.labelGreen),
                      const SizedBox(width: 8),
                      Text('নমিনী ফরম PDF', style: GoogleFonts.notoSansBengali(fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          if (isAdmin && _member != null) ...[
            IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedEdit02, size: 20, color: AppColors.primary),
              onPressed: () {
                Navigator.push(context, AddMemberPage.route(member: _member)).then((_) {
                  _loadMember();
                });
              },
            ),
            IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 20, color: AppColors.error),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ],
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: Loader())
            : _errorMessage != null
                ? ErrorStateWidget(
                    message: _errorMessage,
                    onRetry: _loadMember,
                  )
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
                          const HugeIcon(
                            icon: HugeIcons.strokeRoundedLock,
                            size: 48,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isAdmin ? 'সদস্য তথ্য পাওয়া যায়নি' : 'এই সদস্যের তথ্য দেখার অনুমতি নেই',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            isAdmin
                                ? 'শেয়ার নং ${widget.memberNo} এর কোনো রেকর্ড নেই।'
                                : 'শেয়ারহোল্ডার হিসেবে আপনি শুধুমাত্র আপনার নিজস্ব প্রোফাইল দেখতে পারবেন।',
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
                        _buildProfileHeader(_member!, isAdmin),
                        const SizedBox(height: 16),
                        _buildActionRow(context, _member!, isAdmin),
                        const SizedBox(height: 20),
                        _buildInfoCard('ব্যক্তিগত ও যোগাযোগ তথ্য', [
                          InfoRow(label: 'পিতা', value: _member!.father.isNotEmpty ? _member!.father : '—'),
                          InfoRow(label: 'মাতা', value: _member!.mother.isNotEmpty ? _member!.mother : '—'),
                          InfoRow(label: 'স্বামী/স্ত্রী', value: _member!.spouse.isNotEmpty ? _member!.spouse : '—'),
                          InfoRow(label: 'জাতীয় পরিচয়পত্র (NID)', value: _member!.nid.isNotEmpty ? _member!.nid : '—'),
                          InfoRow(label: 'জন্ম তারিখ', value: _member!.uiBirth.isNotEmpty ? _member!.uiBirth : '—'),
                          InfoRow(label: 'পেশা', value: _member!.job.isNotEmpty ? _member!.job : '—'),
                          InfoRow(label: 'মোবাইল', value: _member!.mobile.isNotEmpty ? _member!.mobile : '—'),
                          InfoRow(label: 'বর্তমান ও স্থায়ী ঠিকানা', value: _member!.address.isNotEmpty ? _member!.address : '—'),
                          if (isAdmin)
                            InfoRow(
                              label: 'লগইন পিন (PIN)',
                              value: _member!.plainPin != null && _member!.plainPin!.isNotEmpty
                                  ? _member!.plainPin!
                                  : (_member!.pin != null && _member!.pin!.isNotEmpty ? 'সক্রিয় (এনক্রিপ্টেড)' : 'সেট করা নেই'),
                            ),
                        ]),
                        const SizedBox(height: 20),
                        _buildNomineesSection(_member!.nominees, isAdmin),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildProfileHeader(MemberModel m, bool isAdmin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          MemberAvatar(
            photo: m.photo,
            fallbackText: m.no,
            width: 84,
            height: 104,
            isCircle: false,
            borderRadius: 12,
            border: Border.all(
              color: AppColors.accent,
              width: 2.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            m.nameEn.isNotEmpty ? m.nameEn : m.displayName,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            alignment: WrapAlignment.center,
            children: [
              _buildPill('শেয়ার সংখ্যা: ${m.shares} টি', AppColors.primary),
              if (m.founder) _buildPill('প্রতিষ্ঠাতা সদস্য', AppColors.accent),
              if (m.labor) _buildPill('শ্রমদাতা সদস্য', AppColors.success),
              if (isAdmin)
                _buildPill(
                  m.plainPin != null && m.plainPin!.isNotEmpty
                      ? 'পিন: ${m.plainPin}'
                      : (m.pin != null && m.pin!.isNotEmpty ? 'পিন সক্রিয়' : 'পিন সেট নেই'),
                  (m.pin != null && m.pin!.isNotEmpty) ? AppColors.success : AppColors.error,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context, MemberModel m, bool isAdmin) {
    return Row(
      children: [
        Expanded(
          child: SpringButton(
            onPressed: () {
              Navigator.push(context, ShareCertificatePage.route(memberNo: m.no));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedDiploma, size: 16, color: AppColors.white),
                const SizedBox(width: 6),
                Text(
                  'সার্টিফিকেট',
                  style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SpringButton(
            onPressed: () {
              Navigator.push(context, ShareholderDocPage.route(memberNo: m.no));
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HugeIcon(icon: HugeIcons.strokeRoundedFile02, size: 16, color: AppColors.white),
                const SizedBox(width: 6),
                Text(
                  'আবেদন ফরম',
                  style: GoogleFonts.notoSansBengali(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        if (isAdmin) ...[
          const SizedBox(width: 8),
          Tooltip(
            message: 'লগইন পিন নির্ধারণ / পরিবর্তন',
            child: SpringButton(
              width: 50,
              height: 50,
              onPressed: () => _showPinDialog(context, m),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedLockPassword,
                  size: 20,
                  color: AppColors.white,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSansBengali(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildNomineesSection(List<NomineeModel> nominees, bool isAdmin) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'মনোনীত নমিনী বিবরণী (${nominees.length} জন)',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (isAdmin)
                TextButton.icon(
                  onPressed: () => _openNomineePage(),
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedAddCircleHalfDot, size: 16, color: AppColors.primary),
                  label: Text(
                    'নমিনী যোগ',
                    style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (nominees.isEmpty)
            Text(
              'কোনো নমিনী যোগ করা হয়নি',
              style: GoogleFonts.notoSansBengali(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: nominees.length,
              separatorBuilder: (_, _) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final n = nominees[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MemberAvatar(
                      photo: n.photo,
                      fallbackText: n.name.isNotEmpty ? n.name[0] : 'ন',
                      width: 48,
                      height: 58,
                      isCircle: false,
                      borderRadius: 6,
                      border: Border.all(color: AppColors.border),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${index + 1}. ${n.name}',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'অংশ: ${n.share}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'সম্পর্ক: ${n.relation.isNotEmpty ? n.relation : "—"} | মোবাইল: ${n.mobile.isNotEmpty ? n.mobile : "—"}',
                            style: GoogleFonts.notoSansBengali(fontSize: 12, color: AppColors.textSecondary),
                          ),
                          if (n.nid.isNotEmpty || n.birth.isNotEmpty)
                            Text(
                              [
                                if (n.nid.isNotEmpty) 'NID: ${n.nid}',
                                if (n.uiBirth.isNotEmpty) 'জন্ম: ${n.uiBirth}',
                              ].join(' | '),
                              style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                    if (isAdmin) ...[
                      IconButton(
                        icon: const HugeIcon(icon: HugeIcons.strokeRoundedEdit02, size: 16, color: AppColors.primary),
                        tooltip: 'সম্পাদনা করুন',
                        onPressed: () => _openNomineePage(editIndex: index),
                      ),
                      IconButton(
                        icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 16, color: AppColors.error),
                        tooltip: 'মুছে ফেলুন',
                        onPressed: () => _confirmDeleteNominee(index),
                      ),
                    ],
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Future<void> _openNomineePage({int? editIndex}) async {
    if (_member == null) return;
    final existing = editIndex != null && editIndex < _member!.nominees.length
        ? _member!.nominees[editIndex]
        : null;

    final result = await Navigator.push<NomineeModel>(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditNomineePage(
          nominee: existing,
          editIndex: editIndex,
        ),
      ),
    );

    if (result != null && mounted) {
      final updatedNominees = List<NomineeModel>.from(_member!.nominees);
      if (editIndex == null) {
        updatedNominees.add(result);
      } else {
        updatedNominees[editIndex] = result;
      }
      final updatedMember = _member!.copyWith(nominees: updatedNominees);
      try {
        await MembersRepo.saveMember(updatedMember);
        if (mounted) {
          context.read<MemberBloc>().add(MemberFetchRequested());
          AppNotifier.showSuccessSnackBar(context, 'নমিনী সফলভাবে সংরক্ষিত হয়েছে');
          setState(() {
            _member = updatedMember;
          });
        }
      } catch (e) {
        if (mounted) {
          AppNotifier.showErrorSnackBar(context, 'সংরক্ষণ ব্যর্থ: $e');
        }
      }
    }
  }

  void _confirmDeleteNominee(int index) {
    if (_member == null || index >= _member!.nominees.length) return;
    final nominee = _member!.nominees[index];
    showDialog(
      context: context,
      builder: (_) => AppConfirmationDialog(
        title: 'নমিনী অপসারণ নিশ্চিতকরণ',
        message: 'আপনি কি নিশ্চিত যে নমিনী "${nominee.name}"-কে তালিকা থেকে মুছে ফেলতে চান?',
        confirmText: 'মুছে ফেলুন',
        onConfirm: () async {
          Navigator.pop(context); // Close confirmation
          final updatedNominees = List<NomineeModel>.from(_member!.nominees)..removeAt(index);
          final updatedMember = _member!.copyWith(nominees: updatedNominees);
          try {
            await MembersRepo.saveMember(updatedMember);
            if (mounted) {
              context.read<MemberBloc>().add(MemberFetchRequested());
              AppNotifier.showSuccessSnackBar(context, 'নমিনী মুছে ফেলা হয়েছে');
              setState(() {
                _member = updatedMember;
              });
            }
          } catch (e) {
            if (mounted) {
              AppNotifier.showErrorSnackBar(context, 'ব্যর্থ: $e');
            }
          }
        },
      ),
    );
  }

  Widget _buildPill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansBengali(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  void _showPinDialog(BuildContext context, MemberModel m) {
    final pinController = TextEditingController(text: m.plainPin ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'লগইন পিন নির্ধারণ / পরিবর্তন',
          style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'সদস্য: ${m.displayName} (${m.no})\nবর্তমান পিন: ${m.plainPin ?? (m.pin != null ? "সক্রিয় (এনক্রিপ্টেড)" : "সেট করা নেই")}',
              style: GoogleFonts.notoSansBengali(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'নতুন পিন (৪-৬ ডিজিট)',
              controller: pinController,
              keyboardType: TextInputType.number,
              hintText: 'যেমন: 1234',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('বাতিল'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final newPin = pinController.text.trim();
              if (newPin.length < 4 || newPin.length > 6 || int.tryParse(newPin) == null) {
                AppNotifier.showErrorSnackBar(ctx, '৪ থেকে ৬ ডিজিটের সংখ্যাসূচক পিন দিন');
                return;
              }
              context.read<MemberBloc>().add(MemberSetPinRequested(no: m.no, newPin: newPin));
              Navigator.pop(ctx);
              AppNotifier.showSuccessSnackBar(context, 'পিন সফলভাবে আপডেট হয়েছে');
              _loadMember();
            },
            child: const Text('সংরক্ষণ করুন', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AppConfirmationDialog(
        title: 'সদস্য অপসারণ নিশ্চিতকরণ',
        message: 'আপনি কি নিশ্চিত যে ${_member!.displayName} (${_member!.no}) কে মুছে ফেলতে চান?',
        confirmText: 'মুছে ফেলুন',
        onConfirm: () {
          context.read<MemberBloc>().add(MemberDeleteRequested(_member!.no));
          Navigator.pop(context); // Pop dialog
          Navigator.pop(context); // Pop details page
        },
      ),
    );
  }
}
