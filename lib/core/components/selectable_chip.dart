import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/config/colors.dart';

enum SelectableChipVariant {
  /// Solid style with high-contrast white checkmark and text on primary fill
  solid,

  /// Modern subtle style with soft tinted background, primary border, and crisp icon badge
  subtle,
}

class SelectableChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final List<List<dynamic>>? icon;
  final IconData? iconData;
  final bool showCheckmark;
  final SelectableChipVariant variant;
  final double height;
  final EdgeInsetsGeometry padding;

  const SelectableChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onSelected,
    this.icon,
    this.iconData,
    this.showCheckmark = true,
    this.variant = SelectableChipVariant.subtle,
    this.height = 46,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  });

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor;
    final Color borderColor;
    final Color textColor;
    final List<BoxShadow>? shadows;

    if (variant == SelectableChipVariant.solid) {
      if (isSelected) {
        backgroundColor = AppColors.primary;
        borderColor = AppColors.primary;
        textColor = AppColors.white;
        shadows = [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ];
      } else {
        backgroundColor = AppColors.white;
        borderColor = AppColors.border;
        textColor = AppColors.textPrimary;
        shadows = [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ];
      }
    } else {
      // Subtle modern style (recommended for fintech forms)
      if (isSelected) {
        backgroundColor = AppColors.primary.withValues(alpha: 0.08);
        borderColor = AppColors.primary;
        textColor = AppColors.primary;
        shadows = [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ];
      } else {
        backgroundColor = AppColors.white;
        borderColor = AppColors.border;
        textColor = AppColors.textPrimary;
        shadows = null;
      }
    }

    // 1. Leading icon badge (Cash, Bank, Building, or Category)
    Widget? leadingIconWidget;
    if (icon != null) {
      leadingIconWidget = Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (variant == SelectableChipVariant.solid
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.primary)
              : AppColors.background,
          borderRadius: BorderRadius.circular(7),
        ),
        child: HugeIcon(
          icon: icon!,
          size: 15,
          color: isSelected
              ? Colors.white
              : AppColors.textSecondary,
        ),
      );
    } else if (iconData != null) {
      leadingIconWidget = Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? (variant == SelectableChipVariant.solid
                  ? Colors.white.withValues(alpha: 0.2)
                  : AppColors.primary)
              : AppColors.background,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          iconData,
          size: 15,
          color: isSelected
              ? Colors.white
              : AppColors.textSecondary,
        ),
      );
    } else if (showCheckmark && isSelected) {
      // When no custom icon is provided, the checkmark acts as the leading icon
      leadingIconWidget = Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: variant == SelectableChipVariant.solid
              ? Colors.white
              : AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          size: 13,
          color: variant == SelectableChipVariant.solid
              ? AppColors.primary
              : Colors.white,
        ),
      );
    }

    // 2. Trailing checkmark badge (shown when an icon is also present and selected)
    Widget? trailingCheckWidget;
    if ((icon != null || iconData != null) && showCheckmark && isSelected) {
      trailingCheckWidget = Container(
        width: 17,
        height: 17,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: variant == SelectableChipVariant.solid
              ? Colors.white
              : AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.check_rounded,
          size: 11,
          color: variant == SelectableChipVariant.solid
              ? AppColors.primary
              : Colors.white,
        ),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeInOut,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: isSelected ? 1.6 : 1.0,
        ),
        boxShadow: shadows,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onSelected,
          child: Padding(
            padding: padding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (leadingIconWidget != null) ...[
                  leadingIconWidget,
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.notoSansBengali(
                      fontSize: 12.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (trailingCheckWidget != null) ...[
                  const SizedBox(width: 6),
                  trailingCheckWidget,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
