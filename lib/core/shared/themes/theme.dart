import 'package:flutter/material.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/shared/themes/app_bar_theme.dart';
import 'package:sampriti/core/shared/themes/elevated_button_theme.dart';
import 'package:sampriti/core/shared/themes/input_decoration_theme.dart';
import 'package:sampriti/core/shared/themes/outline_button_theme.dart';

ThemeData theme = ThemeData(
  scaffoldBackgroundColor: AppColors.background,
  brightness: Brightness.light,
  primaryColor: AppColors.primary,
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    surface: AppColors.card,
    onSurface: AppColors.textPrimary,
  ),
  appBarTheme: appBarTheme,
  elevatedButtonTheme: elevatedButtonTheme,
  outlinedButtonTheme: outlinedButtonTheme,
  inputDecorationTheme: inputDecorationTheme,
);
