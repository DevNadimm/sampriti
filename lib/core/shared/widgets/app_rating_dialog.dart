import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/config/colors.dart';

class AppRatingDialog extends StatelessWidget {
  final VoidCallback onRate;
  final VoidCallback onRemindLater;
  final VoidCallback onDoNotAskAgain;
  final bool isManual;

  const AppRatingDialog({
    super.key,
    required this.onRate,
    required this.onRemindLater,
    required this.onDoNotAskAgain,
    this.isManual = false,
  });

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onRate,
    required VoidCallback onRemindLater,
    required VoidCallback onDoNotAskAgain,
    bool isManual = false,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AppRatingDialog(
        onRate: onRate,
        onRemindLater: onRemindLater,
        onDoNotAskAgain: onDoNotAskAgain,
        isManual: isManual,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative Star Badge
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentYellow.withValues(alpha: 0.2),
                    AppColors.primary.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accentYellow.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
              child: const Center(
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedStar,
                  size: 38,
                  color: AppColors.accentYellow,
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Title
            Text(
              'আপনার অভিজ্ঞতা কেমন?',
              style: GoogleFonts.notoSansBengali(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Subtitle
            Text(
              'সম্প্রীতি ইনভেস্টমেন্ট ফোরাম অ্যাপটি আপনার কেমন লাগছে? গুগল প্লে স্টোরে আপনার ৫-স্টার রেটিং ও মতামত আমাদের অ্যাপটি আরও উন্নত করতে অনুপ্রাণিত করবে।',
              style: GoogleFonts.notoSansBengali(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // 5 Star Row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedStar,
                    size: 26,
                    color: AppColors.accentYellow,
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Primary Rate Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onRate();
                },
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedStar,
                  size: 20,
                  color: AppColors.white,
                ),
                label: Text(
                  '৫ স্টার রেটিং দিন',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Secondary Remind Later Button
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onRemindLater();
                },
                style: TextButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isManual ? 'বাতিল করুন' : 'পরে মনে করিয়ে দিন',
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),

            // Tertiary Do Not Ask Again (only on auto-prompts)
            if (!isManual) ...[
              const SizedBox(height: 4),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  onDoNotAskAgain();
                },
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'আর দেখাবেন না',
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textLight,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
