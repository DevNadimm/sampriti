import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:google_fonts/google_fonts.dart';

AppBarTheme appBarTheme = AppBarTheme(
  backgroundColor: AppColors.background,
  foregroundColor: AppColors.textPrimary,
  scrolledUnderElevation: 0,
  elevation: 0,
  centerTitle: true,
  systemOverlayStyle: const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ),
  titleTextStyle: GoogleFonts.poppins(
    textStyle: const TextStyle(
      fontSize: 20,
      color: AppColors.textPrimary,
      fontWeight: FontWeight.w800,
    ),
  )
);
