import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/back_button.dart';
import 'package:sampriti/core/components/custom_container.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';
import 'package:sampriti/features/setup/data/models/sector_model.dart';
import 'package:sampriti/features/setup/presentation/pages/projects_page.dart';
import 'package:sampriti/features/setup/presentation/pages/sectors_page.dart';

class SetupHubPage extends StatelessWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const SetupHubPage());

  const SetupHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const CustomBackButton(),
        title: Text(
          'সেটআপ হাব (Setup)',
          style: GoogleFonts.notoSansBengali(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: GradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro Banner (RentBook Navy Gradient Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const HugeIcon(
                            icon: HugeIcons.strokeRoundedSettings02,
                            size: 20,
                            color: AppColors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'কনফিগারেশন হাব',
                          style: GoogleFonts.notoSansBengali(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'প্রকল্প ও আয়-ব্যয়ের খাতসমূহ',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'এখানে আপনি ইনভেস্টমেন্ট প্রজেক্ট তৈরি ও শেয়ারহোল্ডার যুক্ত করতে পারবেন এবং স্বয়ংক্রিয় ও কাস্টম খাতসমূহ পরিচালনা করতে পারবেন।',
                      style: GoogleFonts.notoSansBengali(
                        fontSize: 12.5,
                        color: AppColors.white.withValues(alpha: 0.82),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'সেটআপ মডিউলসমূহ',
                style: GoogleFonts.notoSansBengali(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),

              // 1. Projects Hub Card
              _buildFeatureCard(
                icon: HugeIcons.strokeRoundedBriefcase02,
                iconColor: AppColors.primary,
                title: 'ইনভেস্টমেন্ট প্রকল্প',
                subtitle: 'কোন খাতে ইনভেস্ট হচ্ছে, প্রকল্পের বিবরণ ও সংশ্লিষ্ট শেয়ারহোল্ডার নির্বাচন।',
                onTap: () => Navigator.push(context, ProjectsPage.route()),
              ),

              // 2. Income Sectors Hub Card
              _buildFeatureCard(
                icon: HugeIcons.strokeRoundedArrowDownLeft01,
                iconColor: AppColors.success,
                title: 'আয়ের খাত',
                subtitle: 'প্রতিষ্ঠানের যাবতীয় আয় ও জমার প্রধান উৎস/খাতসমূহের তালিকা ও ব্যবস্থাপনা।',
                onTap: () => Navigator.push(
                  context,
                  SectorsPage.route(type: SectorType.income),
                ),
              ),

              // 3. Expense Sectors Hub Card
              _buildFeatureCard(
                icon: HugeIcons.strokeRoundedArrowUpRight01,
                iconColor: AppColors.error,
                title: 'ব্যয়ের খাত',
                subtitle: 'নিয়মিত খরচ, অফিস ব্যয় ও বিনিয়োগের খাতসমূহের তালিকা ও ব্যবস্থাপনা।',
                onTap: () => Navigator.push(
                  context,
                  SectorsPage.route(type: SectorType.expense),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required List<List<dynamic>> icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return CustomContainer(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: HugeIcon(
              icon: icon,
              size: 22,
              color: iconColor,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: GoogleFonts.notoSansBengali(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const HugeIcon(
            icon: HugeIcons.strokeRoundedArrowRight01,
            size: 20,
            color: AppColors.textLight,
          ),
        ],
      ),
    );
  }
}
