import 'package:flutter/material.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';
import 'package:sampriti/core/components/option_picker_bottom_sheet.dart';
import 'package:sampriti/core/components/searchable_option_picker_bottom_sheet.dart';

class OptionPickerBottomSheetHelper {
  OptionPickerBottomSheetHelper._();

  static Future<void> show({
    required BuildContext context,
    required List<String> options,
    required TextEditingController controller,
    required String title,
    ValueChanged<String>? onSelect,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          child: SafeArea(
            child: OptionPickerBottomSheet(
              options: options,
              controller: controller,
              title: title,
              onOptionPicked: (option) {
                controller.text = option;
                onSelect?.call(option);
                Navigator.pop(context);
              },
            ),
          ),
        );
      },
    );
  }

  static Future<void> showSearchable({
    required BuildContext context,
    required List<String> options,
    required TextEditingController controller,
    required String title,
    ValueChanged<String>? onSelect,
  }) async {
    await showMaterialModalBottomSheet(
      context: context,
      expand: false,
      useRootNavigator: false,
      isDismissible: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SearchableOptionPickerBottomSheet(
          options: options,
          controller: controller,
          title: title,
          onOptionPicked: (option) {
            controller.text = option;
            onSelect?.call(option);
            Navigator.pop(context);
          },
        );
      },
    );
  }
}
