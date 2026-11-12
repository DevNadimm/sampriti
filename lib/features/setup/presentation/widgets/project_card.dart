import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/components/custom_container.dart';
import 'package:sampriti/core/components/custom_divider.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/features/setup/data/models/project_model.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ProjectCard({
    super.key,
    required this.project,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat('#,##,###');
    return '৳ ${formatter.format(amount.round())}';
  }

  @override
  Widget build(BuildContext context) {
    final isActive = project.isActive;
    final statusColor = isActive ? AppColors.success : AppColors.greyDark;

    return CustomContainer(
      margin: const EdgeInsets.symmetric(vertical: 6),
      onTap: onEdit,
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
                  color: (isActive ? AppColors.primary : AppColors.greyDark).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedBriefcase02,
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
                            project.statusTitle,
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
                      project.name,
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

          // Start Date Row
          if (project.startDate.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const HugeIcon(
                  icon: HugeIcons.strokeRoundedCalendar03,
                  size: 15,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'শুরুর তারিখ: ${project.uiStartDate}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],

          // Description Row (if available)
          if (project.description.isNotEmpty) ...[
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
                    project.description,
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
                label: 'বাজেট',
                value: project.budget > 0 ? _formatAmount(project.budget) : 'অনির্দিষ্ট',
                valueColor: AppColors.primaryDark,
              ),
              Container(
                height: 20,
                width: 1,
                color: AppColors.divider,
              ),
              _StatItem(
                label: 'শেয়ারহোল্ডার',
                value: project.memberNos.isEmpty ? '০ জন' : '${project.memberNos.length} জন',
                valueColor: AppColors.primary,
              ),
              Container(
                height: 20,
                width: 1,
                color: AppColors.divider,
              ),
              _StatItem(
                label: 'অবস্থা',
                value: project.statusTitle,
                valueColor: statusColor,
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
            style: GoogleFonts.poppins(
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
