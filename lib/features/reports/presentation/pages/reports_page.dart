import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/info_row.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/services/pdf_document_service.dart';
import 'package:sampriti/core/shared/pages/pdf_preview_page.dart';
import 'package:sampriti/core/shared/widgets/error_state_widget.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/features/dashboard/data/models/dashboard_summary_model.dart';
import 'package:sampriti/features/dashboard/data/repos/dashboard_repo.dart';

class ReportsPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const ReportsPage());

  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DashboardSummaryModel? _summary;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final s = await DashboardRepo.getDashboardSummary();
      if (mounted) {
        setState(() {
          _summary = s;
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

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '৳ ${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'আর্থিক প্রতিবেদন ও অডিট রিপোর্ট',
          style: GoogleFonts.notoSansBengali(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (_summary != null)
            IconButton(
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedPrinter,
                size: 20,
                color: AppColors.primary,
              ),
              tooltip: 'প্রতিবেদন PDF',
              onPressed: _openPdf,
            ),
        ],
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: Loader())
            : _errorMessage != null
                ? ErrorStateWidget(
                    message: _errorMessage,
                    onRetry: _loadData,
                  )
                : _summary == null
                    ? const SizedBox()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Report Header Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'সম্প্রীতি ইনভেস্টমেন্ট ফোরাম',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'সার্বিক আর্থিক বিবরণী ও পুঞ্জীভূত স্থিতিপত্র',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'সর্বমোট পুঞ্জীভূত তহবিল (মোট তারল্য)',
                                      style: GoogleFonts.notoSansBengali(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatAmount(_summary!.totalFunds),
                                      style: GoogleFonts.poppins(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Balance Breakdown
                        _buildSectionCard('আর্থিক তারল্য ও স্থিতি', [
                          InfoRow(label: 'ব্যাংক হিসাবসমূহের স্থিতি', value: _formatAmount(_summary!.bankBalance)),
                          InfoRow(label: 'ক্যাশ ইন হ্যান্ড (হাতে নগদ)', value: _formatAmount(_summary!.cashBalance)),
                          InfoRow(label: 'মোট সংগৃহীত বিনিয়োগ', value: _formatAmount(_summary!.totalInvestment)),
                        ]),
                        const SizedBox(height: 16),

                        // Institutional Investments
                        _buildSectionCard('প্রতিষ্ঠানে বিনিয়োগ ও লোন', [
                          InfoRow(label: 'প্রতিষ্ঠানে মোট বিনিয়োগ', value: _formatAmount(_summary!.institutionInvestment)),
                          InfoRow(label: 'প্রতিষ্ঠানকে প্রদত্ত লোন স্থিতি', value: _formatAmount(_summary!.loanOutstanding)),
                          InfoRow(label: 'ভর্তুকি ও অনুদান', value: _formatAmount(_summary!.totalSubsidy)),
                        ]),
                        const SizedBox(height: 16),

                        // Profit & Dividend Payouts
                        _buildSectionCard('আয়, ব্যয় ও লভ্যাংশ বণ্টন', [
                          InfoRow(label: 'প্রতিষ্ঠানের লভ্যাংশ আয়', value: _formatAmount(_summary!.institutionIncome)),
                          InfoRow(label: 'ডোনেশন আয়', value: _formatAmount(_summary!.totalDonation)),
                          InfoRow(label: 'মোট ব্যয় ও খরচ', value: _formatAmount(_summary!.totalExpense)),
                          InfoRow(label: 'বণ্টনযোগ্য নিট মুনাফা', value: _formatAmount(_summary!.distributableProfit)),
                          InfoRow(label: 'পরিশোধিত মোট লভ্যাংশ', value: _formatAmount(_summary!.totalPayout)),
                          InfoRow(label: 'বকেয়া লভ্যাংশ', value: _formatAmount(_summary!.pendingPayout)),
                        ]),
                        const SizedBox(height: 20),

                        // PDF Action Button
                        SpringButton(
                          width: double.infinity,
                          onPressed: _openPdf,
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
                                'আর্থিক প্রতিবেদন PDF ডাউনলোড ও প্রিন্ট',
                                style: GoogleFonts.notoSansBengali(
                                  fontSize: 14,
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

  void _openPdf() {
    if (_summary == null) return;
    Navigator.push(
      context,
      PdfPreviewPage.route(
        title: 'আর্থিক প্রতিবেদন PDF',
        pdfFileName: 'sampriti-financial-report.pdf',
        buildPdf: () => PdfDocumentService.generateFinancialReportPdf(_summary!),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> children) {
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
}
