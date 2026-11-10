import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/components/member_avatar.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/services/pdf_document_service.dart';
import 'package:sampriti/core/shared/pages/pdf_preview_page.dart';
import 'package:sampriti/core/shared/widgets/app_confirmation_dialog.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/empty_state_widget.dart';
import 'package:sampriti/core/shared/widgets/error_state_widget.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:sampriti/features/members/data/models/member_model.dart';
import 'package:sampriti/features/members/data/repos/members_repo.dart';
import 'package:sampriti/features/members/presentation/bloc/member_bloc.dart';
import 'package:sampriti/features/members/presentation/pages/add_member_page.dart';
import 'package:sampriti/features/members/presentation/pages/member_details_page.dart';

class MembersPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const MembersPage());

  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MemberBloc>().add(MemberFetchRequested());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AuthBloc>().state is AuthAuthenticated &&
        (context.read<AuthBloc>().state as AuthAuthenticated).session.isAdmin;

    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'সদস্য তালিকা (Members)',
          style: GoogleFonts.notoSansBengali(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          BlocBuilder<MemberBloc, MemberState>(
            builder: (context, state) {
              if (state is! MemberLoaded || state.allMembers.isEmpty) {
                return const SizedBox.shrink();
              }
              final members = state.allMembers;

              if (isAdmin) {
                return PopupMenuButton<String>(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedPrinter,
                    size: 22,
                    color: AppColors.primary,
                  ),
                  tooltip: 'PDF ডাউনলোড ও প্রিন্ট',
                  onSelected: (val) {
                    if (val == 'list') {
                      Navigator.push(
                        context,
                        PdfPreviewPage.route(
                          title: 'শেয়ারহোল্ডার তালিকা PDF',
                          pdfFileName: 'sampriti-shareholder-list.pdf',
                          buildPdf: () => PdfDocumentService.generateShareholderListPdf(members),
                        ),
                      );
                    } else if (val == 'pins') {
                      Navigator.push(
                        context,
                        PdfPreviewPage.route(
                          title: 'সদস্য লগইন পিন শিট PDF',
                          pdfFileName: 'sampriti-member-pins.pdf',
                          buildPdf: () => PdfDocumentService.generateMemberPinsPdf(members),
                        ),
                      );
                    } else if (val == 'generate_bulk') {
                      _handleBulkGeneratePins(context);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'list',
                      child: Row(
                        children: [
                          const HugeIcon(icon: HugeIcons.strokeRoundedUserMultiple, size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('শেয়ারহোল্ডার তালিকা PDF', style: GoogleFonts.notoSansBengali(fontSize: 13)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'pins',
                      child: Row(
                        children: [
                          const HugeIcon(icon: HugeIcons.strokeRoundedLockPassword, size: 18, color: AppColors.error),
                          const SizedBox(width: 8),
                          Text('সদস্য লগইন পিন শিট PDF', style: GoogleFonts.notoSansBengali(fontSize: 13)),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'generate_bulk',
                      child: Row(
                        children: [
                          const HugeIcon(icon: HugeIcons.strokeRoundedKey01, size: 18, color: AppColors.accent),
                          const SizedBox(width: 8),
                          Text('পিনবিহীন সদস্যদের পিন তৈরি', style: GoogleFonts.notoSansBengali(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedPrinter,
                  size: 22,
                  color: AppColors.primary,
                ),
                tooltip: 'শেয়ারহোল্ডার তালিকা PDF',
                onPressed: () {
                  Navigator.push(
                    context,
                    PdfPreviewPage.route(
                      title: 'শেয়ারহোল্ডার তালিকা PDF',
                      pdfFileName: 'sampriti-shareholder-list.pdf',
                      buildPdf: () => PdfDocumentService.generateShareholderListPdf(members),
                    ),
                  );
                },
              );
            },
          ),
          if (isAdmin)
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedUserAdd01,
                size: 22,
                color: AppColors.primary,
              ),
              onPressed: () {
                Navigator.push(context, AddMemberPage.route()).then((_) {
                  if (context.mounted) {
                    context.read<MemberBloc>().add(MemberFetchRequested());
                  }
                });
              },
            ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Search Bar & Summary
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: CustomTextField(
                label: 'সদস্য খুঁজুন',
                controller: _searchController,
                hintText: 'নাম, শেয়ার নং (S101), বা মোবাইল নম্বর...',
                suffixIcon: HugeIcons.strokeRoundedSearch01,
                onChanged: (val) {
                  context.read<MemberBloc>().add(MemberSearchRequested(val));
                },
              ),
            ),

            Expanded(
              child: BlocBuilder<MemberBloc, MemberState>(
                builder: (context, state) {
                  if (state is MemberLoading || state is MemberInitial) {
                    return const Center(child: Loader());
                  }

                  if (state is MemberFailure) {
                    return ErrorStateWidget(
                      message: state.message,
                      onRetry: () => context.read<MemberBloc>().add(MemberFetchRequested()),
                    );
                  }

                  if (state is MemberLoaded) {
                    final members = state.filteredMembers;
                    final totalShares = state.allMembers.fold<int>(0, (s, m) => s + m.shares);

                    return Column(
                      children: [
                        // Quick Metric Strip
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'মোট সদস্য: ${state.allMembers.length} জন',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  'সর্বমোট শেয়ার: $totalShares টি',
                                  style: GoogleFonts.notoSansBengali(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        if (members.isEmpty)
                          const Expanded(
                            child: EmptyStateWidget(
                              title: 'কোনো সদস্য পাওয়া যায়নি',
                              message: 'অনুসন্ধান ফিল্টার পরিবর্তন করে পুনরায় চেষ্টা করুন।',
                            ),
                          )
                        else
                          Expanded(
                            child: RefreshIndicator(
                              onRefresh: () async {
                                context.read<MemberBloc>().add(MemberFetchRequested());
                              },
                              color: AppColors.primary,
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                                itemCount: members.length,
                                separatorBuilder: (_, _) => const SizedBox(height: 10),
                                itemBuilder: (context, index) {
                                  final m = members[index];
                                  return _buildMemberCard(context, m);
                                },
                              ),
                            ),
                          ),
                      ],
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedUserAdd01, size: 20, color: AppColors.white),
              label: Text(
                'নতুন সদস্য',
                style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700),
              ),
              onPressed: () {
                Navigator.push(context, AddMemberPage.route()).then((_) {
                  if (context.mounted) {
                    context.read<MemberBloc>().add(MemberFetchRequested());
                  }
                });
              },
            )
          : null,
    );
  }

  Widget _buildMemberCard(BuildContext context, MemberModel m) {
    return InkWell(
      onTap: () {
        Navigator.push(context, MemberDetailsPage.route(memberNo: m.no)).then((_) {
          if (context.mounted) {
            context.read<MemberBloc>().add(MemberFetchRequested());
          }
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar or Share No Badge
            MemberAvatar(
              photo: m.photo,
              fallbackText: m.no,
              size: 50,
              isCircle: true,
              border: Border.all(
                color: AppColors.accentYellow.withValues(alpha: 0.6),
                width: 2,
              ),
            ),
            const SizedBox(width: 14),

            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          m.displayName,
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (m.nameEn.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${m.nameEn})',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const HugeIcon(icon: HugeIcons.strokeRoundedCall02, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        m.mobile.isNotEmpty ? m.mobile : 'মোবাইল নেই',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildBadge('${m.shares} টি শেয়ার', AppColors.primary),
                      if (m.founder) _buildBadge('প্রতিষ্ঠাতা', AppColors.accent),
                      if (m.labor) _buildBadge('শ্রমদাতা', AppColors.success),
                    ],
                  ),
                ],
              ),
            ),
            const HugeIcon(
              icon: HugeIcons.strokeRoundedArrowRight01,
              size: 20,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.notoSansBengali(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  void _handleBulkGeneratePins(BuildContext context) {
    AppConfirmationDialog.show(
      context,
      title: 'বাল্ক পিন তৈরি',
      message: 'যেসব সদস্যের কোনো লগইন পিন সেট করা নেই, তাদের সবার জন্য স্বয়ংক্রিয় ৪-ডিজিট পিন তৈরি করা হবে। আপনি কি এগিয়ে যেতে চান?',
      confirmText: 'পিন তৈরি করুন',
      cancelText: 'বাতিল',
      onConfirm: () async {
        Navigator.pop(context); // close dialog
        try {
          final count = await MembersRepo.generateBulkPins();
          if (context.mounted) {
            AppNotifier.showSuccessSnackBar(
              context,
              count > 0
                  ? '$count জন সদস্যের নতুন পিন সফলভাবে তৈরি করা হয়েছে'
                  : 'সকল সদস্যের পিন ইতিমধ্যে সেট করা আছে',
            );
            context.read<MemberBloc>().add(MemberFetchRequested());
          }
        } catch (e) {
          if (context.mounted) {
            AppNotifier.showErrorSnackBar(context, e.toString());
          }
        }
      },
    );
  }
}
