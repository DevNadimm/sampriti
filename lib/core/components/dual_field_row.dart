import 'package:flutter/material.dart';

class DualFieldRow extends StatelessWidget {
  final Widget firstField;
  final Widget lastField;
  final int? firstFlex;
  final int? lastFlex;

  const DualFieldRow({
    super.key,
    Widget? firstField,
    Widget? lastField,
    Widget? left,
    Widget? right,
    this.firstFlex,
    this.lastFlex,
  })  : firstField = firstField ?? left ?? const SizedBox(),
        lastField = lastField ?? right ?? const SizedBox();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: firstFlex ?? 1,
          child: firstField,
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: lastFlex ?? 1,
          child: lastField,
        ),
      ],
    );
  }
}
