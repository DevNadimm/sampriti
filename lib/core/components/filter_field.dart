import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampriti/core/config/colors.dart';

class FilterField extends StatelessWidget {
  final Widget leading;
  final String label;
  final String? value;
  final Widget? trailing;
  final VoidCallback onTap;

  const FilterField({
    super.key,
    required this.leading,
    required this.label,
    this.value,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.isNotEmpty;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 1, color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      color: hasValue
                          ? AppColors.textLight
                          : AppColors.textSecondary,
                      fontWeight: hasValue ? FontWeight.w400 : FontWeight.w500,
                      fontSize: hasValue ? 12 : 15,
                      height: 1,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasValue)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        value!,
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                          height: 1,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
  }
}
