import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';

class ThemedText extends StatelessWidget {
  final String data;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fontFamily;

  const ThemedText(
    this.data, {
    super.key,
    this.fontSize,
    this.fontWeight,
    this.color,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.fontFamily,
  });

  factory ThemedText.body(String data, {Key? key, Color? color, int? maxLines, TextOverflow? overflow}) =>
      ThemedText(data, key: key, color: color ?? AppColors.text, fontSize: 14, maxLines: maxLines, overflow: overflow);

  factory ThemedText.small(String data, {Key? key, Color? color, int? maxLines, TextOverflow? overflow}) =>
      ThemedText(data, key: key, color: color ?? AppColors.textSecondary, fontSize: 12, maxLines: maxLines, overflow: overflow);

  factory ThemedText.title(String data, {Key? key, Color? color}) =>
      ThemedText(data, key: key, color: color ?? AppColors.text, fontSize: 16, fontWeight: FontWeight.w600);

  factory ThemedText.mono(String data, {Key? key, Color? color, int? maxLines, TextOverflow? overflow}) =>
      ThemedText(data, key: key, color: color ?? AppColors.textCode, fontSize: 12, fontFamily: 'monospace', maxLines: maxLines, overflow: overflow);

  factory ThemedText.label(String data, {Key? key, Color? color}) =>
      ThemedText(data, key: key, color: color ?? AppColors.textSecondary, fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w500);

  factory ThemedText.code(String data, {Key? key, Color? color}) =>
      ThemedText(data, key: key, color: color ?? AppColors.text, fontSize: 12, fontFamily: 'monospace');

  @override
  Widget build(BuildContext context) {
    return Text(
      data,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color ?? AppColors.text,
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight,
        fontFamily: fontFamily,
      ),
    );
  }
}
