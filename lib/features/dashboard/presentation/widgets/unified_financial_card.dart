import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/features/dashboard/data/models/dashboard_summary_model.dart';

class UnifiedFinancialCard extends StatefulWidget {
  final DashboardSummaryModel summary;
  final bool isShareholder;

  const UnifiedFinancialCard({
    super.key,
    required this.summary,
    required this.isShareholder,
  });

  @override
  State<UnifiedFinancialCard> createState() => _UnifiedFinancialCardState();
}

class _UnifiedFinancialCardState extends State<UnifiedFinancialCard> {
  bool _showSecondTab = false;

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '৳ ${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    final isFirstTab = !_showSecondTab;

    final gradientColors = widget.isShareholder
        ? (isFirstTab
            ? [const Color(0xFF640710), AppColors.primary]
            : [const Color(0xFF8A6A00), const Color(0xFFA88200)])
        : (isFirstTab
            ? [const Color(0xFF640710), AppColors.primary]
            : [const Color(0xFF7A1D25), const Color(0xFF9E2A34)]);

    final borderColor = widget.isShareholder
        ? (isFirstTab ? AppColors.primaryDark : const Color(0xFF6E5400))
        : (isFirstTab ? AppColors.primaryDark : const Color(0xFF520F16));

    final tab1Label = widget.isShareholder ? 'আমার বিনিয়োগ' : 'তহবিল ও ব্যালেন্স';
    final tab2Label = widget.isShareholder ? 'আমার লভ্যাংশ' : 'বিনিয়োগ ও মুনাফা';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        padding: const EdgeInsets.all(16),
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(width: 4, color: borderColor)),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Smooth Segmented Toggle from rent_book
            Container(
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    alignment: isFirstTab ? Alignment.centerLeft : Alignment.centerRight,
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.fastOutSlowIn,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      heightFactor: 1.0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.black.withValues(alpha: 0.08),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _showSecondTab = false),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: GoogleFonts.notoSansBengali(
                                color: isFirstTab ? AppColors.primaryDark : AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              child: Text(tab1Label),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => _showSecondTab = true),
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 300),
                              style: GoogleFonts.notoSansBengali(
                                color: !isFirstTab ? AppColors.primaryDark : AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                              child: Text(tab2Label),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Animated Content
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: widget.isShareholder
                  ? (isFirstTab ? _buildShareholderInvestmentTab() : _buildShareholderDividendTab())
                  : (isFirstTab ? _buildAdminFundsTab() : _buildAdminInvestmentTab()),
            ),
          ],
        ),
      ),
    );
  }

  // --- Admin Tabs ---
  Widget _buildAdminFundsTab() {
    final s = widget.summary;
    return Column(
      key: const ValueKey<String>('admin_funds'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'সংগঠনের মোট নগদ ও ব্যাংক তহবিল',
          style: GoogleFonts.notoSansBengali(
            color: AppColors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatAmount(s.totalFunds),
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SubStatChip(
                label: 'ক্যাশ ব্যালেন্স',
                amount: _formatAmount(s.cashBalance),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SubStatChip(
                label: 'ব্যাংক ব্যালেন্স',
                amount: _formatAmount(s.bankBalance),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminInvestmentTab() {
    final s = widget.summary;
    return Column(
      key: const ValueKey<String>('admin_invest'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'বণ্টনযোগ্য নিট লভ্যাংশ',
          style: GoogleFonts.notoSansBengali(
            color: AppColors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatAmount(s.distributableProfit),
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SubStatChip(
                label: 'মোট বিনিয়োগ',
                amount: _formatAmount(s.totalInvestment),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SubStatChip(
                label: 'বকেয়া লভ্যাংশ',
                amount: _formatAmount(s.pendingPayout),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _SubStatChip(
                label: 'লোন বকেয়া',
                amount: _formatAmount(s.loanOutstanding),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- Shareholder Tabs ---
  Widget _buildShareholderInvestmentTab() {
    final s = widget.summary;
    return Column(
      key: const ValueKey<String>('shareholder_invest'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'আমার সর্বমোট বিনিয়োগ',
          style: GoogleFonts.notoSansBengali(
            color: AppColors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatAmount(s.myTotalInvestment),
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SubStatChip(
                label: 'শেয়ার সংখ্যা',
                amount: '${s.myShares} টি',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SubStatChip(
                label: 'শেয়ার নং',
                amount: s.memberNo ?? '—',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildShareholderDividendTab() {
    final s = widget.summary;
    return Column(
      key: const ValueKey<String>('shareholder_dividend'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'আমার বকেয়া লভ্যাংশ',
          style: GoogleFonts.notoSansBengali(
            color: AppColors.white.withValues(alpha: 0.9),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _formatAmount(s.myProfitRemaining),
          style: GoogleFonts.poppins(
            color: AppColors.white,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SubStatChip(
                label: 'মোট প্রাপ্য',
                amount: _formatAmount(s.myProfitDue),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SubStatChip(
                label: 'প্রাপ্ত লভ্যাংশ',
                amount: _formatAmount(s.myProfitPaid),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubStatChip extends StatelessWidget {
  final String label;
  final String amount;

  const _SubStatChip({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansBengali(
              color: AppColors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            amount,
            style: GoogleFonts.poppins(
              color: AppColors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
