import 'package:flutter/cupertino.dart';
import 'package:sampriti/core/components/custom_container.dart';
import 'package:sampriti/core/config/colors.dart';

class Loader extends StatelessWidget {
  final Color? color;
  final double? radius;
  final bool isShowContainer;

  const Loader({
    super.key,
    this.color,
    this.radius,
    this.isShowContainer = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: isShowContainer
          ? CustomContainer(
              padding: EdgeInsets.all(16),
              child: CupertinoActivityIndicator(
                radius: radius ?? 16,
                color: color ?? AppColors.textPrimary,
              ),
            )
          : CupertinoActivityIndicator(
              radius: radius ?? 16,
              color: color ?? AppColors.textPrimary,
            ),
    );
  }
}
