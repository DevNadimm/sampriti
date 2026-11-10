import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sampriti/core/config/colors.dart';

class SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? shadowColor;
  final Color? borderColor;
  final double depth;
  final BorderRadius borderRadius;
  final double? width;
  final double height;
  final bool isOutlined;

  const SpringButton({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.shadowColor,
    this.borderColor,
    this.depth = 4.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.width,
    this.height = 50.0,
    this.isOutlined = false,
  });

  /// Factory constructor for outlined variant
  const SpringButton.outlined({
    super.key,
    required this.child,
    this.onPressed,
    this.backgroundColor,
    this.shadowColor,
    this.borderColor,
    this.depth = 4.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.width,
    this.height = 50.0,
  }) : isOutlined = true;

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = true);
      HapticFeedback.lightImpact();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    if (widget.onPressed != null) {
      setState(() => _isPressed = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null;

    // --- Color resolution ---
    final Color resolvedBorderColor = isDisabled
        ? AppColors.greyDark
        : (widget.borderColor ?? AppColors.primary);

    final Color resolvedFaceColor = isDisabled
        ? AppColors.grey
        : widget.isOutlined
        ? (widget.backgroundColor ?? AppColors.surface)
        : (widget.backgroundColor ?? AppColors.primary);

    final Color resolvedShadowColor = isDisabled
        ? AppColors.greyDark.withValues(alpha: 0.4)
        : (widget.shadowColor ??
              (widget.isOutlined
                  ? resolvedBorderColor
                  : AppColors.primaryDark));

    final Color resolvedTextColor = isDisabled
        ? AppColors.textLight
        : widget.isOutlined
        ? resolvedBorderColor
        : AppColors.textOnPrimary;

    final double activeDepth = isDisabled ? 0.0 : widget.depth;
    final double translation = _isPressed ? activeDepth : 0.0;

    // Border for outlined variant
    final Border? faceBorder = widget.isOutlined
        ? Border.all(color: resolvedBorderColor, width: 2.0)
        : null;

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: SizedBox(
        width: widget.width,
        height: widget.height + activeDepth,
        child: Stack(
          children: [
            // 1. Bottom shadow layer (solid 3D base)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              top: activeDepth,
              child: Container(
                decoration: BoxDecoration(
                  color: resolvedShadowColor,
                  borderRadius: widget.borderRadius,
                  // For outlined: the shadow is the border color
                  border: widget.isOutlined
                      ? Border.all(color: resolvedBorderColor, width: 2.0)
                      : null,
                ),
              ),
            ),

            // 2. Animated button face
            AnimatedPositioned(
              duration: const Duration(milliseconds: 60),
              curve: Curves.easeOutQuad,
              left: 0,
              right: 0,
              top: translation,
              bottom: activeDepth - translation,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: resolvedFaceColor,
                  borderRadius: widget.borderRadius,
                  border: faceBorder,
                ),
                child: DefaultTextStyle(
                  style: GoogleFonts.notoSansBengali(
                    color: resolvedTextColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                  ),
                  child: IconTheme.merge(
                    data: IconThemeData(
                      color: resolvedTextColor,
                      size: 19,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

