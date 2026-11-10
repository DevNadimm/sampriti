import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/config/colors.dart';

class RememberMeCheckbox extends StatelessWidget {
  final VoidCallback onPressed;
  final bool state;

  const RememberMeCheckbox({
    super.key,
    required this.onPressed,
    required this.state,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Row(
        children: [
          Container(
            height: 18,
            width: 18,
            decoration: BoxDecoration(
              color: state ? AppColors.primary : AppColors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppColors.inputBorder,
                width: state ? 0 : 1,
              ),
            ),
            child: state
                ? Padding(
                    padding: const EdgeInsets.all(1),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedTick02,
                      color: AppColors.white,
                      strokeWidth: 3,
                    ),
                  )
                : SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          Text(
            'Remember me',
            style: GoogleFonts.poppins(
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
