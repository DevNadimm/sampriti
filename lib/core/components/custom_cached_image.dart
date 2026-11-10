import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/config/assets.dart';
import 'package:sampriti/core/config/colors.dart';
import 'package:shimmer/shimmer.dart';

enum PlaceholderSize { small, medium, large, extraLarge }

class CustomCachedImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final String errorAsset;
  final List<List<dynamic>>? errorIcon;
  final Color? errorIconColor;
  final double aspectRatio;
  final Color backgroundColor;
  final PlaceholderSize placeholderSize;
  final double borderRadius;
  final bool isCircle;
  final bool useShimmer;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;
  final Widget Function(BuildContext, String)? placeholder;

  const CustomCachedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.errorAsset = Assets.noImage,
    this.errorIcon,
    this.errorIconColor,
    this.aspectRatio = 16 / 9,
    this.backgroundColor = AppColors.card,
    this.placeholderSize = PlaceholderSize.medium,
    this.borderRadius = 12.0,
    this.isCircle = false,
    this.useShimmer = true,
    this.errorWidget,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final double radius = isCircle ? ((width ?? height ?? 40) / 2) : borderRadius;

    if (imageUrl.trim().isEmpty) {
      if (errorWidget != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: errorWidget!(context, '', null),
        );
      }
      return _buildPlaceholderOrError(
        asset: errorAsset,
        screenWidth: screenWidth,
        radius: radius,
      );
    }

    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl.trim(),
      fit: fit,
      width: width,
      height: height,
      imageBuilder: (context, imageProvider) => ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image(
          image: imageProvider,
          fit: fit,
          width: width,
          height: height,
        ),
      ),
      placeholder: placeholder ??
          (context, url) => useShimmer
              ? _buildShimmer(screenWidth, radius)
              : Container(
                  width: width,
                  height: height,
                  color: backgroundColor,
                ),
      errorWidget: errorWidget ??
          (context, url, error) => _buildPlaceholderOrError(
                asset: errorAsset,
                screenWidth: screenWidth,
                radius: radius,
              ),
    );

    if (width == null && height == null) {
      return AspectRatio(aspectRatio: aspectRatio, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildShimmer(double screenWidth, double radius) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Shimmer.fromColors(
        baseColor: AppColors.grey.withValues(alpha: 0.3),
        highlightColor: AppColors.cardAlt,
        child: Container(
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          color: backgroundColor,
        ),
      ),
    );
  }

  Widget _buildPlaceholderOrError({
    required String asset,
    required double screenWidth,
    required double radius,
  }) {
    double size;
    switch (placeholderSize) {
      case PlaceholderSize.small:
        size = screenWidth * 0.05;
        break;
      case PlaceholderSize.medium:
        size = screenWidth * 0.1;
        break;
      case PlaceholderSize.large:
        size = screenWidth * 0.2;
        break;
      case PlaceholderSize.extraLarge:
        size = screenWidth * 0.3;
        break;
    }

    return Container(
      width: width ?? double.infinity,
      height: height ?? double.infinity,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(
        child: errorIcon != null
            ? HugeIcon(
                icon: errorIcon!,
                size: size,
                color: errorIconColor ?? AppColors.primary,
              )
            : Image.asset(
                asset,
                fit: BoxFit.contain,
                width: size,
                height: size,
              ),
      ),
    );
  }
}
