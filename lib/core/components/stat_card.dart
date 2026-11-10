import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/custom_container.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/utils/helpers/helper_functions.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final List<List<dynamic>> icon;
  final Color color;

  /// When true, renders [value] as-is (string). When false, pads as integer.
  final bool isRaw;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isRaw = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: CustomContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: HugeIcon(icon: icon, size: 16, color: color),
            ),
            const SizedBox(height: 10),
            Text(
              isRaw
                  ? value
                  : HelperFunctions.padNumber(int.tryParse(value) ?? 0),
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
