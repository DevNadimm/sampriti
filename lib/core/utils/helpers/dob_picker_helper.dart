import 'package:flutter/cupertino.dart';
import 'package:sampriti/core/config/colors.dart';

class DOBPickerHelper {
  DOBPickerHelper._();

  /// Shows a Cupertino-style date picker inside a modal bottom popup.
  static Future<void> show({
    required BuildContext context,
    required Function(DateTime) onDateSelected,
    DateTime? initialDate,
  }) async {
    await showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 260,
        color: AppColors.white,
        child: CupertinoDatePicker(
          mode: CupertinoDatePickerMode.date,
          maximumDate: DateTime.now(),
          initialDateTime: initialDate ?? DateTime(2000),
          minimumYear: 1900,
          maximumYear: DateTime.now().year,
          onDateTimeChanged: (date) {
            onDateSelected.call(date);
          },
        ),
      ),
    );
  }
}
