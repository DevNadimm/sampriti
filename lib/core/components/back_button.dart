import 'package:flutter/material.dart' hide BackButton;
import 'package:hugeicons/hugeicons.dart';
import 'package:sampriti/core/components/custom_icon_button.dart';

class CustomBackButton extends StatelessWidget {
  final VoidCallback? onBack;

  const CustomBackButton({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: CustomIconButton(
        icon: const HugeIcon(icon: HugeIcons.strokeRoundedArrowLeft02),
        onTap: onBack ?? () => Navigator.pop(context),
      ),
    );
  }
}

class BackButton extends CustomBackButton {
  const BackButton({super.key, super.onBack});
}
