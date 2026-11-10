import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampriti/core/components/custom_cached_image.dart';
import 'package:sampriti/core/config/colors.dart';

class MemberAvatar extends StatelessWidget {
  final String? photo;
  final String fallbackText;
  final double size;
  final double? width;
  final double? height;
  final double borderRadius;
  final bool isCircle;
  final Border? border;

  const MemberAvatar({
    super.key,
    required this.photo,
    required this.fallbackText,
    this.size = 50,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.isCircle = true,
    this.border,
  });

  double get effectiveWidth => width ?? size;
  double get effectiveHeight => height ?? size;

  Uint8List? _decodeBase64(String raw) {
    try {
      final clean = raw.contains(',') ? raw.split(',').last : raw;
      return base64Decode(clean.trim());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final photoStr = photo?.trim() ?? '';
    final isBase64 = photoStr.startsWith('data:image') || (photoStr.length > 200 && !photoStr.startsWith('http'));
    final isUrl = photoStr.startsWith('http://') || photoStr.startsWith('https://');

    Widget imageContent;

    if (isBase64) {
      final bytes = _decodeBase64(photoStr);
      if (bytes != null) {
        imageContent = Image.memory(
          bytes,
          width: effectiveWidth,
          height: effectiveHeight,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        );
      } else {
        imageContent = _buildFallback();
      }
    } else if (isUrl) {
      imageContent = CustomCachedImage(
        imageUrl: photoStr,
        width: effectiveWidth,
        height: effectiveHeight,
        fit: BoxFit.cover,
        isCircle: isCircle,
        borderRadius: borderRadius,
        useShimmer: true,
        errorWidget: (context, url, error) => _buildFallback(),
      );
    } else {
      imageContent = _buildFallback();
    }

    return Container(
      width: effectiveWidth,
      height: effectiveHeight,
      decoration: BoxDecoration(
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius),
        border: border,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isCircle ? (effectiveWidth / 2) : borderRadius),
        child: imageContent,
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: effectiveWidth,
      height: effectiveHeight,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          fallbackText.isNotEmpty ? fallbackText : 'স',
          style: GoogleFonts.poppins(
            fontSize: (effectiveWidth < effectiveHeight ? effectiveWidth : effectiveHeight) * 0.36,
            fontWeight: FontWeight.w700,
            color: AppColors.white,
          ),
        ),
      ),
    );
  }
}
