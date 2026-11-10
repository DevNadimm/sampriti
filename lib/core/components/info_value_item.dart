import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampriti/core/config/colors.dart';

class InfoValueItem extends StatelessWidget {
  final String label;
  final String value;
  final double? labelSize;
  final double? valueSize;

  const InfoValueItem({
    super.key,
    required this.label,
    required this.value,
    this.labelSize = 16,
    this.valueSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: valueSize,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
