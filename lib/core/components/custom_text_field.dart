import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/config/colors.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hintText,
    this.isRequired = false,
    this.showRequiredIndicator = true,
    this.keyboardType = TextInputType.text,
    this.suffixText,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.validationLabel,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.validator,
    this.obscureText = false,
    this.textInputAction,
    this.focusNode,
    this.errorText,
    this.labelActionText,
    this.onLabelActionTap,
  });

  final String label;
  final String? hintText;
  final TextEditingController controller;
  final bool isRequired;
  final bool showRequiredIndicator;
  final String? suffixText;
  final TextInputType keyboardType;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final String? validationLabel;
  final ValueChanged<String>? onChanged;
  final List<List<dynamic>>? prefixIcon;
  final List<List<dynamic>>? suffixIcon;
  final VoidCallback? onSuffixTap;
  final FormFieldValidator? validator;
  final bool obscureText;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final String? errorText;
  final String? labelActionText;
  final VoidCallback? onLabelActionTap;

  @override
  Widget build(BuildContext context) {
    final effectiveHint = hintText?.isNotEmpty == true ? hintText : label;
    final showAction = labelActionText != null && onLabelActionTap != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (isRequired && showRequiredIndicator)
                    const Text(
                      ' *',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              if (showAction)
                GestureDetector(
                  onTap: onLabelActionTap,
                  child: Text(
                    labelActionText!,
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        if (label.isNotEmpty) const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          focusNode: focusNode,
          textInputAction: textInputAction,
          onTap: onTap,
          onChanged: onChanged,
          obscureText: obscureText,
          maxLines: maxLines,
          validator: isRequired
              ? validator ??
                    (value) {
                      final vLabel = validationLabel ?? label;
                      if (value == null || value.trim().isEmpty) {
                        final fieldName = '${vLabel[0].toUpperCase()}${vLabel.substring(1).toLowerCase()}';
                        return '$fieldName is required';
                      }
                      return null;
                    }
              : null,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: effectiveHint,
            suffixText: suffixText,
            errorText: errorText,
            border: const OutlineInputBorder(),
            prefixIcon: prefixIcon != null
                ? Padding(
                    padding: const EdgeInsets.all(12),
                    child: HugeIcon(
                      size: 20,
                      icon: prefixIcon!,
                      color: AppColors.textSecondary,
                    ),
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? GestureDetector(
                    onTap: onSuffixTap,
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: HugeIcon(
                        size: 20,
                        icon: suffixIcon!,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// A search-specific text field with a filled card background,
/// rounded corners, search icon prefix, and dynamic clear button.
class CustomSearchTextField extends StatefulWidget {
  const CustomSearchTextField({
    super.key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.focusNode,
    this.textInputAction = TextInputAction.search,
    this.readOnly = false,
    this.onTap,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final bool readOnly;
  final VoidCallback? onTap;

  @override
  State<CustomSearchTextField> createState() => _CustomSearchTextFieldState();
}

class _CustomSearchTextFieldState extends State<CustomSearchTextField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    // Rebuild to show/hide clear button
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = widget.controller.text.isNotEmpty;

    return TextField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      textInputAction: widget.textInputAction,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        hintText: widget.hintText,
        hintStyle: GoogleFonts.poppins(
          color: AppColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Padding(
          padding: EdgeInsets.all(12),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedSearch01,
            color: AppColors.textSecondary,
            size: 20,
          ),
        ),
        suffixIcon: hasText
            ? IconButton(
                onPressed: () {
                  widget.controller.clear();
                  widget.onChanged?.call('');
                },
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              )
            : null,
        filled: true,
        fillColor: AppColors.card,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.grey.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.grey.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
    );
  }
}
