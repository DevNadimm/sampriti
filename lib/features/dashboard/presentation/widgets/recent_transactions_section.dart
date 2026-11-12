import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/custom_container.dart';
import 'package:sampriti/core/components/custom_divider.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/features/transactions/data/models/transaction_model.dart';
import 'package:sampriti/features/transactions/presentation/pages/voucher_details_page.dart';

class RecentTransactionsSection extends StatelessWidget {
  final List<TransactionModel> transactions;
  final VoidCallback? onSeeAll;

  const RecentTransactionsSection({
    super.key,
    required this.transactions,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomContainer(
        padding: transactions.isEmpty
            ? const EdgeInsets.fromLTRB(16, 16, 16, 16)
            : const EdgeInsets.fromLTRB(16, 16, 16, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'সাম্প্রতিক লেনদেন ও ভাউচার',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (onSeeAll != null)
                  GestureDetector(
                    onTap: onSeeAll,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      child: Text(
                        'সব দেখুন',
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'কোনো লেনদেন পাওয়া যায়নি',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...List.generate(transactions.length, (index) {
                final t = transactions[index];
                return _TransactionRow(
                  transaction: t,
                  isLast: index == transactions.length - 1,
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  final TransactionModel transaction;
  final bool isLast;

  const _TransactionRow({
    required this.transaction,
    this.isLast = false,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return formatter.format(amount.round());
  }

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final isIncome = t.isInflow;
    final color = isIncome ? AppColors.success : (t.isOutflow ? AppColors.error : AppColors.accent);

    return InkWell(
      onTap: () {
        Navigator.push(context, VoucherDetailsPage.route(transaction: t));
      },
      borderRadius: BorderRadius.circular(8),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: isIncome
                          ? HugeIcons.strokeRoundedArrowDownLeft01
                          : HugeIcons.strokeRoundedArrowUpRight01,
                      size: 20,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.title,
                        style: GoogleFonts.notoSansBengali(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.vno} · ${t.uiDate}${t.member.isNotEmpty ? " · ${t.member}" : ""}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${isIncome ? "+" : "-"} ৳ ${_formatAmount(t.amount)}',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (!isLast) const CustomDivider(),
        ],
      ),
    );
  }
}
