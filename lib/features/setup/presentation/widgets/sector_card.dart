import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/custom_container.dart';
import 'package:sampriti/core/components/custom_divider.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/features/setup/data/models/sector_model.dart';

class SectorCard extends StatelessWidget {
  final SectorModel sector;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SectorCard({
    super.key,
    required this.sector,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = sector.type == SectorType.income;
    final primaryIconColor = isIncome ? AppColors.success : AppColors.error;

    return CustomContainer(
      margin: const EdgeInsets.symmetric(vertical: 6),
      onTap: sector.isSystem ? null : onEdit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Category Icon, Badges, Title, Action buttons
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryIconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: isIncome
                      ? HugeIcons.strokeRoundedArrowDownLeft01
                      : HugeIcons.strokeRoundedArrowUpRight01,
                  size: 22,
                  color: primaryIconColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: primaryIconColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            sector.typeTitle,
                            style: GoogleFonts.notoSansBengali(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: primaryIconColor,
                              height: 1,
                            ),
                          ),
                        ),
                        if (sector.isSystem) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'সিস্টেম',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                        if (!sector.isActive) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppColors.greyLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'নিষ্ক্রিয়',
                              style: GoogleFonts.notoSansBengali(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textLight,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 7),
                    Text(
                      sector.name,
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

              // Action Buttons: Only show for custom sectors (hidden if isSystem == true)
              if (!sector.isSystem) ...[
                const SizedBox(width: 6),
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
            ],
          ),

          // Description Row (if available)
          if (sector.description.isNotEmpty) ...[
            const SizedBox(height: 10),
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
                    sector.description,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          // Dotted Divider
          const SizedBox(height: 12),
          const CustomDivider.dotted(),
          const SizedBox(height: 12),

          // Bottom Stats Row (RentBook Style)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _StatItem(
                label: 'খাতের ধরন',
                value: sector.typeTitle,
                valueColor: primaryIconColor,
              ),
              Container(
                height: 20,
                width: 1,
                color: AppColors.divider,
              ),
              _StatItem(
                label: 'শ্রেণিবিভাগ',
                value: sector.isSystem ? 'সিস্টেম খাত' : 'কাস্টম খাত',
                valueColor: sector.isSystem ? AppColors.primary : AppColors.textPrimary,
              ),
              Container(
                height: 20,
                width: 1,
                color: AppColors.divider,
              ),
              _StatItem(
                label: 'অবস্থা',
                value: sector.isActive ? 'সক্রিয়' : 'নিষ্ক্রিয়',
                valueColor: sector.isActive ? AppColors.success : AppColors.textLight,
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
  final Color? valueColor;

  const _StatItem({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.notoSansBengali(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.notoSansBengali(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
