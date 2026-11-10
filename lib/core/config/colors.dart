import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ------------------- Backgrounds -------------------
  static const Color background = Color(0xFFF7F5F0);
  static const Color surface = Color(0xFFFFFFFF);

  static const Color appBar = background;
  static const Color bottomNavBar = background;

  // ------------------- Cards -------------------
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardAlt = Color(0xFFFDFBF7);

  // ------------------- Primary Theme Colors (Sampriti Crimson / Maroon) -------------------
  static const Color primary = Color(0xFF8A0A14);          // Deep Crimson Red
  static const Color primaryLight = Color(0xFFA81926);     // Light Crimson
  static const Color primaryLight2 = Color(0xFFF8E9E9);    // Soft Burgundy Tint
  static const Color primaryDark = Color(0xFF640710);      // Deep Shadow Burgundy

  // ------------------- Typography Colors -------------------
  static const Color textPrimary = Color(0xFF16213A);
  static const Color textSecondary = Color(0xFF59647A);
  static const Color textLight = Color(0xFF9EABB8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFFFFFFFF);

  // ------------------- Accent / Branding (Gold / Olive) -------------------
  static const Color accent = Color(0xFF8A6A00);           // Sampriti Golden Olive
  static const Color accentDark = Color(0xFF6E5400);       // Darker Gold
  static const Color accentLight = Color(0xFFFBF1D6);      // Soft Gold Tint
  static const Color accentYellow = Color(0xFFC9A227);     // Rich Gold Highlight
  static const Color labelGreen = Color(0xFF059669);

  // ------------------- Neutral Colors -------------------
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color greyLight = Color(0xFFF1F5F9);
  static const Color grey = Color(0xFFE2E8F0);
  static const Color greyDark = Color(0xFF94A3B8);

  // ------------------- Status Colors -------------------
  static const Color success = Color(0xFF10B981);   // Emerald Green
  static const Color error = Color(0xFFE8192C);     // Brand Red
  static const Color warning = Color(0xFFFF9600);   // Amber Orange
  static const Color info = Color(0xFF3B82F6);      // Blue
  static const Color blue = Color(0xFF3B82F6);
  static const Color border = Color(0xFFE2E8F0);

  // ------------------- Transparency / Overlays -------------------
  static const Color primaryTransparent = Color(0x801E3A5F);
  static const Color secondaryTransparent = Color(0x8010B981);
  static const Color cardOverlay = Color(0x11000000);

  // ------------------- Form / Inputs -------------------
  static const Color inputBorder = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);
  static const Color inputBorderFocused = primary;
}