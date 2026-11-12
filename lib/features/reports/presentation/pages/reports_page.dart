import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/period_filter_bar.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/services/pdf_document_service.dart';
import 'package:sampriti/core/shared/pages/pdf_preview_page.dart';
import 'package:sampriti/core/shared/widgets/error_state_widget.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/core/shared/widgets/loader.dart';
import 'package:sampriti/features/reports/data/models/financial_report_model.dart';
import 'package:sampriti/features/reports/data/models/report_period.dart';
import 'package:sampriti/features/reports/data/repos/report_repo.dart';
import 'package:sampriti/features/transactions/presentation/pages/transactions_page.dart';

class ReportsPage extends StatefulWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const ReportsPage());

  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  ReportPeriod _period = ReportPeriod.preset(ReportPeriodPreset.thisYear);
  FinancialReportModel? _report;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final r = await ReportRepo.buildFinancialReport(_period);
      if (mounted) {
        setState(() {
          _report = r;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  String _fmt(double v) => '৳ ${NumberFormat('#,##,###').format(v.round())}';

  void _onPeriod(ReportPeriod p) {
    setState(() => _period = p);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'আর্থিক প্রতিবেদন',
          style: GoogleFonts.notoSansBengali(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          if (r != null)
            IconButton(
              tooltip: 'প্রতিবেদন PDF',
              icon: const Icon(Icons.print_outlined, color: AppColors.primary),
              onPressed: () {
                Navigator.push(
                  context,
                  PdfPreviewPage.route(
                    title: 'আর্থিক প্রতিবেদন PDF',
                    pdfFileName: 'sampriti-financial-report.pdf',
                    buildPdf: () => PdfDocumentService.generateDetailedFinancialReportPdf(r),
                  ),
                );
              },
            ),
        ],
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: Loader())
            : _error != null
                ? ErrorStateWidget(message: _error!, onRetry: _load)
                : r == null
                    ? const SizedBox()
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        children: [
                          PeriodFilterBar(value: _period, onChanged: _onPeriod),
                          const SizedBox(height: 14),
                          _buildSummary(r),
                          const SizedBox(height: 14),
                          _section('নগদ ও ব্যাংক', [
                            for (final f in r.funds)
                              _fundTile(f),
                            _line('মোট তহবিল (সমাপনী)', _fmt(r.closingFunds), bold: true),
                          ]),
                          const SizedBox(height: 14),
                          _section('Monthly Trend', [
                            if (r.months.isEmpty)
                              _line('এই সময়কালে কোনো লেনদেন নেই', '—'),
                            for (final m in r.months) _monthTile(m, r),
                          ]),
                          const SizedBox(height: 14),
                          _section('প্রকল্পভিত্তিক', [
                            if (r.projects.isEmpty)
                              _line('কোনো প্রকল্প নেই', '—'),
                            for (final p in r.projects) _projectTile(p),
                          ]),
                          const SizedBox(height: 14),
                          _section('খাতভিত্তিক আয়', [
                            if (r.incomeSectors.isEmpty) _line('কোনো আয় নেই', '—'),
                            for (final s in r.incomeSectors)
                              _sectorTile(s.name, s.amount, s.count, s.percent, AppColors.success),
                          ]),
                          const SizedBox(height: 14),
                          _section('খাতভিত্তিক ব্যয়', [
                            if (r.expenseSectors.isEmpty) _line('কোনো ব্যয় নেই', '—'),
                            for (final s in r.expenseSectors)
                              _sectorTile(s.name, s.amount, s.count, s.percent, AppColors.error),
                          ]),
                          const SizedBox(height: 14),
                          _section('সদস্যভিত্তিক', [
                            if (r.members.isEmpty) _line('কোনো সদস্য নেই', '—'),
                            for (final m in r.members) _memberTile(m),
                          ]),
                          const SizedBox(height: 20),
                        ],
                      ),
      ),
    );
  }

  Widget _buildSummary(FinancialReportModel r) {
    final net = r.netResult;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(children: [
            _cell('আয়', _fmt(r.totalIncome), AppColors.success),
            _cell('ব্যয়', _fmt(r.totalExpense), AppColors.error),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            _cell('মুনাফা বণ্টন', _fmt(r.totalPayout), AppColors.accent),
            _cell('নিট ফলাফল', _fmt(net), net >= 0 ? AppColors.primary : AppColors.error),
          ]),
          const SizedBox(height: 10),
          Text(
            'ভাউচার: ${r.voucherCount} টি  •  স্থানান্তর: ${r.transferCount} টি  •  প্রারম্ভিক তহবিল: ${_fmt(r.openingFunds)}',
            style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _cell(String label, String value, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary)),
            Text(value, style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.notoSansBengali(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.notoSansBengali(
                fontSize: 12.5,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _fundTile(FundRow f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line(f.name, _fmt(f.closing), bold: true),
          Text(
            'শুরু ${_fmt(f.opening)}  •  জমা ${_fmt(f.inflow)}  •  উত্তোলন ${_fmt(f.outflow)}',
            style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _monthTile(MonthRow m, FinancialReportModel r) {
    final maxV = r.months
        .map((x) => [x.income, x.expense, x.payout].reduce((a, b) => a > b ? a : b))
        .fold<double>(0, (a, b) => a > b ? a : b);
    double frac(double v) => maxV > 0 ? (v / maxV).clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(m.label, style: GoogleFonts.notoSansBengali(fontSize: 12.5, fontWeight: FontWeight.w600)),
              Text(
                'নিট ${_fmt(m.net)}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: m.net >= 0 ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _bar(frac(m.income), AppColors.success),
          const SizedBox(height: 3),
          _bar(frac(m.expense), AppColors.error),
          const SizedBox(height: 3),
          _bar(frac(m.payout), AppColors.accent),
        ],
      ),
    );
  }

  Widget _bar(double fraction, Color color) {
    return LayoutBuilder(builder: (context, c) {
      return Container(
        height: 6,
        width: c.maxWidth,
        decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(3)),
        alignment: Alignment.centerLeft,
        child: Container(
          height: 6,
          width: c.maxWidth * fraction,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
      );
    });
  }

  Widget _projectTile(ProjectRow p) {
    final used = (p.budgetUsedPercent / 100).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line('${p.name}${p.isActive ? '' : ' (সমাপ্ত)'}', '${p.memberCount} জন সদস্য', bold: true),
          if (p.budget > 0) ...[
            const SizedBox(height: 4),
            _bar(used.toDouble(), AppColors.primary),
            Text(
              'বাজেট ${_fmt(p.budget)}  •  ব্যবহার ${p.budgetUsedPercent.toStringAsFixed(0)}%',
              style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            'আয় ${_fmt(p.income)}  •  ব্যয় ${_fmt(p.expense)}  •  নিট ${_fmt(p.net)}',
            style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: AppColors.textPrimary),
          ),
          Text(
            'বণ্টিত ${_fmt(p.payout)}  •  সদস্য বিনিয়োগ ${_fmt(p.memberInvestment)}',
            style: GoogleFonts.notoSansBengali(fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _sectorTile(String name, double amount, int count, double percent, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _line('$name ($count টি)', _fmt(amount)),
          _bar((percent / 100).clamp(0.0, 1.0), color),
          Text(
            '${percent.toStringAsFixed(1)}%',
            style: GoogleFonts.poppins(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _memberTile(MemberRow m) {
    return InkWell(
      onTap: () => Navigator.push(context, TransactionsPage.route(memberNo: m.no)),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _line('${m.no} · ${m.name}  (${m.policyLabel})', _fmt(m.netCapital), bold: true),
            Text(
              'বিনিয়োগ ${_fmt(m.investment)}  •  মুনাফা ${_fmt(m.profitReceived)}  •  মূলধন ফেরত ${_fmt(m.capitalReturn)}',
              style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
