import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TimeFormatter {
  TimeFormatter._();

  static DateTime? _parse12h(String value) {
    try {
      return DateFormat('h:mm a').parse(value);
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parse24h(String value) {
    try {
      return DateFormat('HH:mm').parse(value);
    } catch (_) {
      return null;
    }
  }

  /// "8:00 AM" → "08:00"
  static String to24Hour(String time12h) {
    final date = _parse12h(time12h);
    if (date == null) return time12h;

    return DateFormat('HH:mm').format(date);
  }

  /// "13:45" → "1:45 PM"
  static String to12Hour(String time24h) {
    final date = _parse24h(time24h);
    if (date == null) return time24h;

    return DateFormat('h:mm a').format(date);
  }
}

extension TimeOfDayX on TimeOfDay {
  /// TimeOfDay → "HH:mm" string.
  /// e.g. TimeOfDay(hour: 9, minute: 5) → "09:05"
  String toHHmm() {
    final h = hour.toString().padLeft(2, '0');
    final m = minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
