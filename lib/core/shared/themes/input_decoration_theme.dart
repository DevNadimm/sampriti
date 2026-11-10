import 'package:flutter/material.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:google_fonts/google_fonts.dart';

InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
  errorMaxLines: 3,
  prefixIconColor: AppColors.textSecondary,
  suffixIconColor: AppColors.textSecondary,
  fillColor: AppColors.card,
  filled: true,
  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  labelStyle: const TextStyle().copyWith(fontSize: 14, color: AppColors.textSecondary),
  hintStyle: GoogleFonts.poppins(textStyle: const TextStyle().copyWith(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
  errorStyle: GoogleFonts.poppins(textStyle: const TextStyle().copyWith(fontStyle: FontStyle.normal)),
  floatingLabelStyle: const TextStyle().copyWith(
    color: Colors.black.withValues(alpha: 0.8),
  ),
  border: const OutlineInputBorder().copyWith(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(width: 1, color: AppColors.inputBorder),
  ),
  enabledBorder: const OutlineInputBorder().copyWith(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(width: 1, color: AppColors.inputBorder),
  ),
  focusedBorder: const OutlineInputBorder().copyWith(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(width: 1.4, color: AppColors.inputBorderFocused),
  ),
  errorBorder: const OutlineInputBorder().copyWith(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(width: 1, color: AppColors.error),
  ),
  focusedErrorBorder: const OutlineInputBorder().copyWith(
    borderRadius: BorderRadius.circular(12),
    borderSide: const BorderSide(width: 1.4, color: AppColors.warning),
  ),
);
