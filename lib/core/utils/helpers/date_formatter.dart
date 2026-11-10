import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static DateTime? parse(dynamic value) {
    try {
      if (value == null) return null;
      if (value is DateTime) return value;

      if (value.runtimeType.toString() == 'Timestamp') {
        try {
          return (value as dynamic).toDate();
        } catch (_) {}
      }

      final str = value.toString().trim();
      if (str.isEmpty || str == '—' || str == '-' || str == 'null') return null;

      final iso = DateTime.tryParse(str);
      if (iso != null) return iso.toLocal();

      const formats = [
        'dd/MM/yyyy', // 02/02/2026
        'dd-MM-yyyy', // 02-02-2026
        'yyyy-MM-dd', // 2026-02-02
        'yyyy/MM/dd', // 2026/02/02
        'dd MMM, yyyy', // 07 Apr, 2026
        'dd MMMM, yyyy', // 07 April, 2026
        'EEE, dd MMM', // Thu, 02 Apr  (no year — limited use)
      ];

      for (final fmt in formats) {
        try {
          return DateFormat(fmt).parseLoose(str).toLocal();
        } catch (_) {}
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  /// UI display alias for ddMMyyyy (e.g. 02/02/2026)
  static String toUi(dynamic value) => ddMMyyyy(value);

  /// DB storage alias for yyyyMMdd (e.g. 2026-02-02)
  static String toDb(dynamic value) => yyyyMMdd(value);

  /// 20 September, 2025
  static String readable(dynamic value, {bool isShortMonth = false, bool forceEnglish = false}) {
    if (value == null) return '';
    final str = value.toString().trim();
    if (str.isEmpty || str == '—' || str == 'null') return '';
    final date = parse(value);
    if (date == null) return str;
    return DateFormat(
      isShortMonth ? 'dd MMM, yyyy' : 'dd MMMM, yyyy',
      forceEnglish ? 'en' : null,
    ).format(date);
  }

  /// 20 September, 2025 01:51 AM
  static String readableWithTime(dynamic value) {
    if (value == null) return '';
    final str = value.toString().trim();
    if (str.isEmpty || str == '—' || str == 'null') return '';
    final date = parse(value);
    if (date == null) return str;
    return DateFormat('dd MMMM, yyyy hh:mm a').format(date);
  }

  static String readableWithTime12(dynamic value) {
    if (value == null || value.toString().trim().isEmpty || value.toString().trim() == 'null') {
      return '';
    }

    try {
      final date = DateFormat('yyyy-MM-dd hh:mm a').parse(value.toString());
      return DateFormat('dd MMMM, yyyy hh:mm a').format(date);
    } catch (_) {
      return value.toString();
    }
  }

  /// 20/09/2025 (dd/MM/yyyy)
  static String ddMMyyyy(dynamic value) {
    if (value == null) return '';
    final str = value.toString().trim();
    if (str.isEmpty || str == '—' || str == 'null') return '';
    final date = parse(value);
    if (date == null) return str;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  /// 2025-09-20 (yyyy-MM-dd) — always ASCII digits (safe for DB & API calls)
  static String yyyyMMdd(dynamic value) {
    if (value == null) return '';
    final str = value.toString().trim();
    if (str.isEmpty || str == '—' || str == 'null') return '';
    final date = parse(value);
    if (date == null) return str;
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Thu, 02 Apr
  static String eeeddMMM(dynamic value) {
    if (value == null) return '';
    final str = value.toString().trim();
    if (str.isEmpty || str == '—' || str == 'null') return '';
    final date = parse(value);
    if (date == null) return str;
    return DateFormat('EEE, dd MMM').format(date);
  }

  /// FEB
  static String monthShort(String yearMonth) {
    try {
      final date = DateTime.parse('$yearMonth-01');
      return DateFormat('MMM').format(date).toUpperCase();
    } catch (_) {
      return yearMonth;
    }
  }

  /// January 2025
  static String monthYear(dynamic value, {bool? isShortMonth}) {
    if (value == null) return '';

    final str = value.toString().trim();

    try {
      DateTime? date;

      if (RegExp(r'^\d{4}-\d{2}$').hasMatch(str)) {
        date = DateTime.parse('$str-01');
      } else {
        date = parse(value);
      }

      if (date == null) return str;

      return DateFormat(
        isShortMonth == true ? 'MMM yyyy' : 'MMMM yyyy',
      ).format(date);
    } catch (_) {
      return str;
    }
  }

  static String monthToYearMonth(dynamic value) {
    if (value == null) return '';

    final str = value.toString().trim();

    try {
      if (RegExp(r'^\d{4}-\d{2}$').hasMatch(str)) {
        return str;
      }

      try {
        final date = DateFormat('MMMM yyyy').parseLoose(str);
        return DateFormat('yyyy-MM', 'en').format(date);
      } catch (_) {}

      try {
        final date = DateFormat('MMM yyyy').parseLoose(str);
        return DateFormat('yyyy-MM', 'en').format(date);
      } catch (_) {}

      return str;
    } catch (_) {
      return str;
    }
  }
}
