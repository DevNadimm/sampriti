import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_divider.dart';
import 'package:sampriti/core/components/info_row.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/assets.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/services/pdf_document_service.dart';
import 'package:sampriti/core/shared/pages/pdf_preview_page.dart';
import 'package:sampriti/core/shared/widgets/app_confirmation_dialog.dart';
import 'package:sampriti/core/shared/widgets/app_notifier.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';
import 'package:sampriti/features/transactions/presentation/bloc/transaction_bloc.dart';

class VoucherDetailsPage extends StatelessWidget {
  final TransactionModel transaction;
  final String? projectName; // optional display name; falls back to project id

  static Route route({required TransactionModel transaction, String? projectName}) => MaterialPageRoute(
        builder: (_) => VoucherDetailsPage(transaction: transaction, projectName: projectName),
      );

  const VoucherDetailsPage({super.key, required this.transaction, this.projectName});

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '৳ ${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).session
        : null;
    final isAdmin = session?.isAdmin ?? false;

    // Security Check: Shareholder can only inspect vouchers that belong to them
    final memberNo = session?.memberNo;
    final isOwner = transaction.member.isEmpty ||
        (memberNo != null &&
            memberNo.isNotEmpty &&
            transaction.member.toUpperCase() == memberNo.toUpperCase());

    if (!isAdmin && !isOwner) {
      return Scaffold(
        appBar: AppBar(
          leading: const CustomBackButton(),
          title: Text('ভাউচার রশিদ (${transaction.vno})'),
        ),
        body: GradientBackground(
          child: Center(
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const HugeIcon(
                    icon: HugeIcons.strokeRoundedAlert02,
                    size: 48,
                    color: AppColors.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'এই ভাউচার দেখার অনুমতি নেই',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'শেয়ারহোল্ডার হিসেবে আপনি শুধুমাত্র আপনার নিজস্ব লেনদেনের ভাউচার দেখতে পারবেন।',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final isPositive = transaction.isInflow;
    final themeColor = isPositive ? AppColors.success : (transaction.isOutflow ? AppColors.error : AppColors.accent);

    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'ভাউচার রশিদ (${transaction.vno})',
          style: GoogleFonts.notoSansBengali(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            icon: const HugeIcon(icon: HugeIcons.strokeRoundedPrinter, size: 20, color: AppColors.primary),
            tooltip: 'ভাউচার রসিদ PDF',
            onPressed: () => _openPdf(context),
          ),
          if (isAdmin)
            IconButton(
              icon: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 20, color: AppColors.error),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Voucher Receipt Container (Styled like an official paper slip)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header (Matching Share Form & Certificate official branding)
                    Image.asset(
                      Assets.logoBanner,
                      height: 44,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'অফিসিয়াল লেনদেন ভাউচার',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const CustomDivider(),
                    const SizedBox(height: 16),

                    // Key Details
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ভাউচার নম্বর',
                              style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              transaction.vno,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'তারিখ',
                              style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            Text(
                              transaction.uiDate,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Amount Display Box
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: themeColor.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'মোট টাকার পরিমাণ',
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatAmount(transaction.amount),
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: themeColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Structured Info
                    InfoRow(label: 'লেনদেনের ধরন', value: transaction.title),
                    if (transaction.sectorName.isNotEmpty)
                      InfoRow(label: 'খাত', value: transaction.sectorName),
                    if (transaction.project.isNotEmpty)
                      InfoRow(label: 'প্রকল্প', value: projectName ?? transaction.project),
                    if (transaction.member.isNotEmpty)
                      InfoRow(label: 'সংশ্লিষ্ট সদস্য', value: 'শেয়ার নং ${transaction.member}'),
                    InfoRow(
                      label: 'পরিশোধের মাধ্যম',
                      value: transaction.mode == 'bank'
                          ? 'ব্যাংক ট্রান্সফার'
                          : (transaction.mode == 'inst' ? 'প্রতিষ্ঠান সমন্বয়' : 'নগদ (Cash)'),
                    ),
                    if (transaction.acct.isNotEmpty)
                      InfoRow(label: 'ব্যাংক হিসাব', value: transaction.acct),
                    if (transaction.note.isNotEmpty)
                      InfoRow(label: 'বিবরণ ও মন্তব্য', value: transaction.note),

                    const SizedBox(height: 40),

                    // Signatures Line
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSignatureBox('আদায়কারী / প্রস্তুতকারী'),
                        _buildSignatureBox('হিসাবরক্ষক'),
                        _buildSignatureBox('অনুমোদনকারী'),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // PDF Action Button
              SpringButton(
                width: double.infinity,
                onPressed: () => _openPdf(context),
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
                      'ভাউচার রসিদ প্রিন্ট ও PDF ডাউনলোড',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  void _openPdf(BuildContext context) {
    Navigator.push(
      context,
      PdfPreviewPage.route(
        title: 'ভাউচার রসিদ (${transaction.vno})',
        pdfFileName: 'sampriti-voucher-${transaction.vno}.pdf',
        buildPdf: () => PdfDocumentService.generateVoucherPdf(transaction),
      ),
    );
  }

  Widget _buildSignatureBox(String label) {
    return Column(
      children: [
        Container(
          width: 90,
          height: 1,
          color: AppColors.border,
        ),
        const SizedBox(height: 6),
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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AppConfirmationDialog(
        title: 'ভাউচার অপসারণ',
        message: 'আপনি কি নিশ্চিত যে ভাউচার নং ${transaction.vno} স্থায়ীভাবে মুছে ফেলতে চান?',
        confirmText: 'মুছে ফেলুন',
        onConfirm: () {
          context.read<TransactionBloc>().add(TransactionDeleteRequested(transaction.id));
          Navigator.pop(context); // Pop dialog
          Navigator.pop(context); // Pop voucher details
          AppNotifier.showSuccessSnackBar(context, 'ভাউচার মুছে ফেলা হয়েছে');
        },
      ),
    );
  }
}
