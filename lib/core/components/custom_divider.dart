import 'package:flutter/material.dart';
import 'package:sampriti/core/config/colors.dart';

class CustomDivider extends StatelessWidget {
  final double? height;
  final double? width;
  final double dashWidth;
  final double dashSpace;
  final bool _isDotted;

  const CustomDivider({
    super.key,
    this.height,
    this.width,
    this.dashWidth = 4,
    this.dashSpace = 4,
  }) : _isDotted = false;

  const CustomDivider.dotted({
    super.key,
    this.height,
    this.width,
    this.dashWidth = 4,
    this.dashSpace = 4,
  }) : _isDotted = true;

  @override
  Widget build(BuildContext context) {
    if (_isDotted) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = width ?? constraints.maxWidth;
          final dashCount = (maxWidth / (dashWidth + dashSpace)).floor();
          return SizedBox(
            width: maxWidth,
            child: Flex(
              direction: Axis.horizontal,
              children: List.generate(dashCount, (_) {
                return Padding(
                  padding: EdgeInsets.only(right: dashSpace),
                  child: SizedBox(
                    width: dashWidth,
                    height: height ?? 1,
                    child: const DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.divider),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      );
    }

    return Container(
      height: height ?? 1,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.divider.withValues(alpha: 0.1),
            AppColors.divider,
            AppColors.divider.withValues(alpha: 0.1),
          ],
        ),
      ),
    );
  }
}