import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampriti/core/config/assets.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:sampriti/core/config/messages.dart';

class EmptyStateWidget extends StatelessWidget {
  final String? title;
  final String? message;
  final Widget? icon;
  final bool isCenter;

  const EmptyStateWidget({
    super.key,
    this.title,
    this.message,
    this.icon,
    this.isCenter = true,
  });

  @override
  Widget build(BuildContext context) {
    return isCenter ? Center(child: _content()) : _content();
  }

  Widget _content() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon ?? _loadEmptyImage(),
          const SizedBox(height: 14),
          Text(
            title ?? AppMessages.emptyTitle,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            message ?? AppMessages.emptyMessage,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppColors.textLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _loadEmptyImage() {
    return Image.asset(Assets.noContent, height: 100, width: 100);
  }
}
