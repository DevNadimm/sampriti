import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/config/colors.dart';

class InlineErrorWidget extends StatelessWidget {
  final String? message;

  const InlineErrorWidget(this.message, {super.key});

  @override
  Widget build(BuildContext context) {
    return message != null && message!.isNotEmpty
        ? Container(
            margin: EdgeInsets.only(top: 16),
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(width: 1, color: AppColors.error.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedAlertSquare,
                  color: AppColors.error,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message!,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      color: AppColors.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          )
        : SizedBox.shrink();
  }
}
