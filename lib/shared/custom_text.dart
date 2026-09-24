import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  const CustomText({
    super.key,
    required this.text,
    required this.color,
    required this.size,
    this.weight,
    this.align,
    this.maxLines,
    this.overflow,
    required,
  });
  final String text;
  final Color color;
  final double size;
  final FontWeight? weight;
  final TextAlign? align;

  /// Caps the line count. [overflow] defaults to ellipsis once a cap is set.
  /// Needed where a long Arabic subject name shares a narrow grid cell.
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : null),
      style: TextStyle(fontSize: size, color: color, fontWeight: weight),
    );
  }
}
