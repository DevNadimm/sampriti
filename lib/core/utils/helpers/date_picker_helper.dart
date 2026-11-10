import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/utils/helpers/date_formatter.dart';

class DatePickerHelper {
  DatePickerHelper._();

  /// Opens themed date picker and sets formatted date into controller.
  /// Default format is 'dd/MM/yyyy' for UI display.
  static Future<DateTime?> show({
    required BuildContext context,
    required TextEditingController controller,
    DateTime? firstDate,
    DateTime? lastDate,
    DateTime? initialDate,
    String format = 'dd/MM/yyyy',
    bool isBirthDate = false,
  }) async {
    final now = DateTime.now();

    // Try parsing existing controller text using DateFormatter
    DateTime? parsedInitial;
    if (controller.text.trim().isNotEmpty) {
      parsedInitial = DateFormatter.parse(controller.text.trim());
    }

    final effectiveFirst = firstDate ?? (isBirthDate ? DateTime(1920) : DateTime(now.year - 15));
    final effectiveLast = lastDate ?? (isBirthDate ? now : DateTime(now.year + 10));

    DateTime effectiveInitial = initialDate ?? parsedInitial ?? (isBirthDate ? DateTime(1995, 1, 1) : now);
    if (effectiveInitial.isBefore(effectiveFirst)) {
      effectiveInitial = effectiveFirst;
    } else if (effectiveInitial.isAfter(effectiveLast)) {
      effectiveInitial = effectiveLast;
    }

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: effectiveInitial,
      firstDate: effectiveFirst,
      lastDate: effectiveLast,
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      controller.text = DateFormat(format).format(pickedDate);
    }
    return pickedDate;
  }
}
