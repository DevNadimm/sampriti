import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sampriti/core/config/app_config.dart';
import 'package:sampriti/core/config/assets.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/logger/app_logger.dart';
import 'package:sampriti/core/services/app_preferences.dart';
import 'package:sampriti/core/utils/enums/error_type.dart';

class ErrorStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? icon;
  final String? buttonText;
  final ErrorType? errorType;
  final VoidCallback? onRetry;

  const ErrorStateWidget({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.buttonText,
    this.errorType = ErrorType.unknown,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, String> getMessage() {
      final Map<String, String> messageMap = {};

      switch (errorType) {
        case ErrorType.network:
          messageMap['title'] = 'ইন্টারনেট সংযোগ নেই';
          messageMap['message'] = 'অনুগ্রহ করে আপনার ইন্টারনেট সংযোগ চেক করে পুনরায় চেষ্টা করুন।';
          break;

        case ErrorType.server:
          messageMap['title'] = 'সার্ভার সমস্যা';
          messageMap['message'] = 'সার্ভারের সাথে যোগাযোগ করতে সমস্যা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন।';
          break;

        case ErrorType.notFound:
          messageMap['title'] = 'কোনো তথ্য পাওয়া যায়নি';
          messageMap['message'] = 'অনুরোধকৃত তথ্যটি পাওয়া যায়নি বা মুছে ফেলা হয়েছে।';
          break;

        case ErrorType.botProtection:
          messageMap['title'] = 'অ্যাক্সেস সাময়িক স্থগিত';
          messageMap['message'] = 'নিরাপত্তার স্বার্থে অনুরোধটি ব্লক করা হয়েছে। অনুগ্রহ করে যোগাযোগ করুন।';
          break;

        case ErrorType.unknown:
        default:
          messageMap['title'] = 'ত্রুটি দেখা দিয়েছে';
          messageMap['message'] = 'ডাটা লোড করতে সমস্যা হয়েছে। অনুগ্রহ করে আবার চেষ্টা করুন।';
      }

      if (title != null && title!.isNotEmpty) {
        messageMap['title'] = title!;
      }

      if (message != null && message!.isNotEmpty) {
        messageMap['message'] = message!;
      }

      return messageMap;
    }

    final resolvedMessage = getMessage();
    final isBotProtection = errorType == ErrorType.botProtection;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon ?? _loadErrorImage(),
            const SizedBox(height: 16),

            Text(
              resolvedMessage['title']!,
              style: GoogleFonts.notoSansBengali(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              resolvedMessage['message']!,
              style: GoogleFonts.notoSansBengali(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            if (isBotProtection) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final userName = await AppPreferences.getUserName();
                  final memberNo = await AppPreferences.getMemberNo();

                  final supportMessage = '''
আসসালামু আলাইকুম,

${AppConfig.appName} অ্যাপে আমার সংযোগ সমস্যা হচ্ছে।

• নাম: $userName
• শেয়ার নং: $memberNo
• App Version: ${AppConfig.appVersion}

সহায়তা কামনা করছি।
''';

                  final uri = Uri.parse(AppConfig.supportWhatsAppUrl(supportMessage));
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    AppLogger.d('Error launching support URL: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedCustomerSupport, size: 20, color: Colors.white),
                label: Text(
                  'সাপোর্টে যোগাযোগ করুন',
                  style: GoogleFonts.notoSansBengali(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ] else if (onRetry != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                icon: const HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 18, color: Colors.white),
                label: Text(
                  buttonText ?? 'পুনরায় চেষ্টা করুন',
                  style: GoogleFonts.notoSansBengali(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getIconName() {
    if (errorType == ErrorType.network) return Assets.networkError;
    if (errorType == ErrorType.server) return Assets.serverError;
    if (errorType == ErrorType.botProtection) return Assets.serverError;
    if (errorType == ErrorType.notFound) return Assets.notFoundError;
    return Assets.error;
  }

  Widget _loadErrorImage() {
    try {
      return Image.asset(_getIconName(), height: 96, width: 96);
    } catch (_) {
      return const HugeIcon(icon: HugeIcons.strokeRoundedWifi01, size: 64, color: AppColors.error);
    }
  }
}
