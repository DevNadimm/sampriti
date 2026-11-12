import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/config/colors.dart';

/// Cash in hand, shown with the same structure as a bank account card.
class CashCard extends StatelessWidget {
  final double opening;
  final double inflow;
  final double outflow;
  final double balance;
  final VoidCallback? onEdit;

  const CashCard({
    super.key,
    required this.opening,
    required this.inflow,
    required this.outflow,
    required this.balance,
    this.onEdit,
  });

  String _fmt(double v) => '৳ ${NumberFormat('#,##,###').format(v.round())}';

  Widget _stat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.notoSansBengali(fontSize: 11, color: AppColors.textSecondary)),
          Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'নগদ (হাতে)',
                  style: GoogleFonts.notoSansBengali(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  tooltip: 'প্রারম্ভিক স্থিতি পরিবর্তন',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primary),
                  onPressed: onEdit,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat('প্রারম্ভিক স্থিতি', _fmt(opening), AppColors.textPrimary),
              _stat('জমা', _fmt(inflow), AppColors.success),
              _stat('উত্তোলন', _fmt(outflow), AppColors.error),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _stat('বর্তমান স্থিতি', _fmt(balance), balance >= 0 ? AppColors.primary : AppColors.error),
            ],
          ),
        ],
      ),
    );
  }
}
