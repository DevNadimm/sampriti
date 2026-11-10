import 'package:flutter/material.dart';
import 'package:sampriti/core/config/colors.dart';

class CustomContainer extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry? borderRadius;
  final Color? color;
  final Color? borderColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;

  const CustomContainer({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.onTap,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.borderColor,
    this.gradient,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        width: width,
        padding: padding ?? const EdgeInsets.all(16),
        margin: margin,
        decoration: BoxDecoration(
          color: color ?? AppColors.card,
          gradient: gradient,
          borderRadius: borderRadius ?? const BorderRadius.all(Radius.circular(16)),
          border: Border.all(width: 1, color: borderColor ?? AppColors.inputBorder),
          boxShadow:
              boxShadow ??
              [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.01),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
        ),
        child: child,
      ),
    );
  }
}
