import 'package:flutter/material.dart';

class CustomText extends StatelessWidget {
  const CustomText({
    super.key,
    required this.text,
    required this.color,
    required this.size,
    this.weight,
    this.align,
    required,
  });
  final String text;
  final Color color;
  final double size;
  final FontWeight? weight;
  final TextAlign? align;
  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: align,
      style: TextStyle(fontSize: size, color: color, fontWeight: weight),
    );
  }
}
