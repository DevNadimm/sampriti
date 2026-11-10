import 'package:flutter/material.dart';

class CustomIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget icon;
  final double size;
  final double iconSize;
  final Color backgroundColor;
  final Color? splashColor;
  final ShapeBorder shape;
  final EdgeInsetsGeometry padding;
  final String? tooltip;
  final bool enabled;

  const CustomIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 48,
    this.iconSize = 24,
    this.backgroundColor = Colors.white,
    this.splashColor,
    this.shape = const CircleBorder(),
    this.padding = const EdgeInsets.all(8),
    this.tooltip,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: backgroundColor,
      shape: shape,
      child: InkWell(
        customBorder: shape,
        splashColor: splashColor,
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: IconTheme.merge(
              data: IconThemeData(size: iconSize),
              child: icon,
            ),
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}
