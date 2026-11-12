import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/custom_container.dart';
import 'package:sampriti/core/components/custom_divider.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/features/finance/data/models/bank_account_model.dart';

class BankCard extends StatelessWidget {
  final BankAccountModel account;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BankCard({
    super.key,
    required this.account,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '৳ ${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = account.isActive;
    final statusColor = isActive ? AppColors.success : AppColors.greyDark;

    return CustomContainer(
      margin: const EdgeInsets.symmetric(vertical: 6),
      onTap: onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Bank Icon, Status Badge, Bank Title, Action buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (isActive ? AppColors.primary : AppColors.greyDark).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedBank,
                  size: 22,
                  color: isActive ? AppColors.primary : AppColors.greyDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            account.statusTitle,
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: statusColor,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      account.bankName,
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Action Buttons
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedEdit02,
                  size: 18,
                  color: AppColors.primary,
                ),
                onPressed: onEdit,
                tooltip: 'এডিট করুন',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
                  size: 18,
                  color: AppColors.error,
                ),
                onPressed: onDelete,
                tooltip: 'মুছে ফেলুন',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),

          // Branch & Account No Row
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const HugeIcon(
                icon: HugeIcons.strokeRoundedCreditCard,
                size: 15,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${account.branch.isNotEmpty ? "${account.branch} • " : ""}হিসাব নং: ${account.accountNo}',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          // Note / Account Name (if provided)
          if (account.note.isNotEmpty || account.accountName.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    account.note.isNotEmpty ? account.note : account.accountName,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Dotted Divider
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: CustomDivider.dotted(),
          ),

          // Bottom Metrics
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  label: 'প্রারম্ভিক স্থিতি',
                  value: _formatAmount(account.initialBalance),
                  valueColor: AppColors.textSecondary,
                ),
              ),
              Container(
                height: 24,
                width: 1,
                color: AppColors.border,
              ),
              Expanded(
                child: _StatItem(
                  label: 'বর্তমান স্থিতি',
                  value: _formatAmount(account.currentBalance),
                  valueColor: AppColors.primary,
                  isBold: true,
                ),
              ),
              Container(
                height: 24,
                width: 1,
                color: AppColors.border,
              ),
              Expanded(
                child: _StatItem(
                  label: 'অবস্থা',
                  value: account.statusTitle,
                  valueColor: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  const _StatItem({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.notoSansBengali(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
