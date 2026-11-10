import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampriti/core/components/spring_button.dart';
import 'package:sampriti/core/config/assets.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/widgets/gradient_background.dart';

class UnderDevelopmentPage extends StatelessWidget {
  static Route route() => MaterialPageRoute(builder: (_) => const UnderDevelopmentPage());

  const UnderDevelopmentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GradientBackground(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(Assets.development, height: 200),
              const SizedBox(height: 26),
              Text(
                'Feature Coming Soon!',
                style: GoogleFonts.poppins(
                  textStyle: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'This feature is currently being developed. We are improving your experience and will make it available soon.',
                style: GoogleFonts.poppins(
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SpringButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('GO BACK'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
