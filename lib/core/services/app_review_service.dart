import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sampriti/core/config/app_config.dart';
import 'package:sampriti/core/shared/widgets/app_rating_dialog.dart';

class AppReviewService {
  AppReviewService._();

  static final InAppReview _inAppReview = InAppReview.instance;

  static const String _keyHasRated = 'app_has_rated';
  static const String _keyDoNotAsk = 'app_do_not_ask_rating';
  static const String _keyActionCount = 'app_action_count';
  static const String _keyLastPromptTime = 'app_last_rating_prompt_time';

  /// Share app download link via social media / messaging apps
  static Future<void> shareApp() async {
    final String shareMessage = '''
${AppConfig.appFullName}
শেয়ারহোল্ডার ও আর্থিক হিসাব-নিকাশ পরিচালনার আধুনিক সমবায় প্ল্যাটফর্ম।

গুগল প্লে স্টোর থেকে অ্যাপটি ডাউনলোড করুন:
${AppConfig.playStoreUrl}
'''.trim();

    try {
      await SharePlus.instance.share(
        ShareParams(
          text: shareMessage,
          subject: '${AppConfig.appFullName} মোবাইল অ্যাপ',
        ),
      );
    } catch (_) {
      // Fallback if Share fails
      final uri = Uri.parse(AppConfig.playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Trigger Play Store rating (In-App Review API with Play Store fallback)
  static Future<void> rateApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasRated, true);

    try {
      if (await _inAppReview.isAvailable()) {
        await _inAppReview.requestReview();
      } else {
        await openStoreListing();
      }
    } catch (_) {
      await openStoreListing();
    }
  }

  /// Open Play Store listing directly in Google Play app
  static Future<void> openStoreListing() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: 'com.thinkcodify.sampriti',
      );
    } catch (_) {
      final uri = Uri.parse(AppConfig.playStoreUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  /// Display rating dialog manually (e.g. when user clicks "রেটিং দিন")
  static void showManualRatingDialog(BuildContext context) {
    AppRatingDialog.show(
      context,
      isManual: true,
      onRate: () => rateApp(),
      onRemindLater: () {},
      onDoNotAskAgain: () {},
    );
  }

  /// Smart trigger: records user action and shows rating prompt when criteria are met
  static Future<void> recordActionAndPromptIfNeeded(
    BuildContext context, {
    int threshold = 3,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final bool hasRated = prefs.getBool(_keyHasRated) ?? false;
    if (hasRated) return;

    final bool doNotAsk = prefs.getBool(_keyDoNotAsk) ?? false;
    if (doNotAsk) return;

    final int lastPromptTime = prefs.getInt(_keyLastPromptTime) ?? 0;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    // Don't ask again within 4 days (4 * 24 * 60 * 60 * 1000 = 345,600,000 ms)
    if (nowMs - lastPromptTime < 345600000) return;

    int actionCount = (prefs.getInt(_keyActionCount) ?? 0) + 1;
    await prefs.setInt(_keyActionCount, actionCount);

    if (actionCount >= threshold) {
      if (!context.mounted) return;

      // Reset action counter and update prompt time
      await prefs.setInt(_keyActionCount, 0);
      await prefs.setInt(_keyLastPromptTime, nowMs);

      if (!context.mounted) return;

      AppRatingDialog.show(
        context,
        isManual: false,
        onRate: () => rateApp(),
        onRemindLater: () async {
          // Snooze by keeping last prompt time updated
          await prefs.setInt(_keyLastPromptTime, DateTime.now().millisecondsSinceEpoch);
        },
        onDoNotAskAgain: () async {
          await prefs.setBool(_keyDoNotAsk, true);
        },
      );
    }
  }
}
