import 'package:intl/intl.dart';

class HelperFunctions {
  HelperFunctions._();

  static final NumberFormat _bdTakaFormat = NumberFormat.decimalPattern('en');

  static String toBengaliDigits(String input) {
    return input;
  }

  static String toEnglishDigits(String input) {
    return input;
  }

  static String toBengaliDigitsIfBn(String input) {
    return input;
  }

  static String formatTaka(num? amount, {bool forceEnglish = true}) {
    if (amount == null) return '0';
    return _bdTakaFormat.format(amount);
  }

  static String formatTakaWithSymbol(num? amount) {
    if (amount == null) return '৳0';
    return '৳${_bdTakaFormat.format(amount)}';
  }

  static String capitalize(String? input) {
    if (input == null || input.isEmpty) return '';
    return input[0].toUpperCase() + input.substring(1).toLowerCase();
  }

  static String padNumber(int number) {
    return number.toString().padLeft(2, '0');
  }

  static String formatCompact(num? value) {
    if (value == null) return '0';
    String formatted;
    if (value >= 10000000) {
      formatted = '${(value / 10000000).toStringAsFixed(value % 10000000 == 0 ? 0 : 1)}Cr';
    } else if (value >= 100000) {
      formatted = '${(value / 100000).toStringAsFixed(value % 100000 == 0 ? 0 : 1)}L';
    } else if (value >= 1000) {
      formatted = '${(value / 1000).toStringAsFixed(value % 1000 == 0 ? 0 : 1)}K';
    } else {
      formatted = value.toStringAsFixed(0);
    }
    return formatted;
  }

  static String combineInfo(
    List<String?> parts, {
    String separator = ' • ',
    String fallback = '',
  }) {
    final filtered = parts.where((part) => part != null && part.trim().isNotEmpty).map((part) => part!.trim()).toList();
    return filtered.isEmpty ? fallback : filtered.join(separator);
  }
}
