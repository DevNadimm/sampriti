import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/custom_text_field.dart';
import 'package:sampriti/core/utils/helpers/option_picker_bottom_sheet_helper.dart';

class CustomDropdownField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final List<String> options;
  final String? hintText;
  final bool isRequired;
  final bool isSearchable;
  final ValueChanged<String>? onChanged;
  final String? sheetTitle;
  final FormFieldValidator? validator;

  const CustomDropdownField({
    super.key,
    required this.label,
    required this.controller,
    required this.options,
    this.hintText,
    this.isRequired = false,
    this.isSearchable = false,
    this.onChanged,
    this.sheetTitle,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return CustomTextField(
      label: label,
      controller: controller,
      readOnly: true,
      isRequired: isRequired,
      hintText: hintText ?? '$label নির্বাচন করুন',
      suffixIcon: HugeIcons.strokeRoundedArrowDown01,
      validator: validator,
      onTap: () {
        if (options.isEmpty) return;
        final title = sheetTitle ?? label;
        if (isSearchable) {
          OptionPickerBottomSheetHelper.showSearchable(
            context: context,
            options: options,
            controller: controller,
            title: title,
            onSelect: onChanged,
          );
        } else {
          OptionPickerBottomSheetHelper.show(
            context: context,
            options: options,
            controller: controller,
            title: title,
            onSelect: onChanged,
          );
        }
      },
    );
  }
}
