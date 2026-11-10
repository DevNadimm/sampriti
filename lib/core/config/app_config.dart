class AppConfig {
  AppConfig._();

  static const String appName = "সম্প্রীতি";
  static const String appFullName = "সম্প্রীতি ইনভেস্টমেন্ট ফোরাম";
  static const String appFullNameEn = "Sampriti Investment Forum";
  static const String appSlogan = "We build our nation by building ourselves";
  static const String establishedYear = "২০১১";
  static const String orgAddress = "নোয়াপাড়া আইডিয়াল স্কুল, রাউজান, চট্টগ্রাম-৪৩৪৬";
  static const String appVersion = "1.0.0";
  static const String appSubtitle = "সমবায় ও বিনিয়োগ ব্যবস্থাপনা";

  /// URLs
  static const String websiteUrl = "https://sampriti.org";
  static const String termsUrl = "$websiteUrl/terms";
  static const String privacyUrl = "$websiteUrl/privacy";

  /// Support
  static const String supportPhone = "+8801700000000";

  /// Developer / Engineering Credits
  static const String developerName = "ThinkCodify";
  static const String developerTagline = "কারিগরি পরিচালনায় ThinkCodify";
  static const String developerTaglineEn = "Developed by ThinkCodify";
  static const String developerWebsite = "https://thinkcodify.com";

  static String supportWhatsAppUrl([String? message]) {
    if (message == null || message.isEmpty) {
      return "https://wa.me/$supportPhone";
    }

    return "https://wa.me/$supportPhone?text=${Uri.encodeComponent(message)}";
  }
}
