import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';

/// 主题感知的文本组件 — 颜色从 [ThemeData] 中解析。
///
/// 工厂构造方法不再设置默认颜色，改为在 [build] 中通过
/// `Theme.of(context).appColors` 获取。
class ThemedText extends StatelessWidget {
  final String data;
  final double? fontSize;
  final FontWeight? fontWeight;
  final Color? color;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fontFamily;
  final double? height;

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
    this.height,
  });

  factory ThemedText.body(
    String data, {
    Key? key,
    Color? color,
    int? maxLines,
    TextOverflow? overflow,
  }) => ThemedText(
    data,
    key: key,
    color: color,
    fontSize: 14,
    maxLines: maxLines,
    overflow: overflow,
  );

  factory ThemedText.small(
    String data, {
    Key? key,
    Color? color,
    int? maxLines,
    TextOverflow? overflow,
  }) => ThemedText(
    data,
    key: key,
    color: color,
    fontSize: 12,
    maxLines: maxLines,
    overflow: overflow,
  );

  factory ThemedText.title(
    String data, {
    Key? key,
    Color? color,
    int? maxLines,
    TextOverflow? overflow,
  }) => ThemedText(
    data,
    key: key,
    color: color,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    maxLines: maxLines,
    overflow: overflow,
  );

  factory ThemedText.mono(
    String data, {
    Key? key,
    Color? color,
    int? maxLines,
    TextOverflow? overflow,
    double? fontSize,
    FontWeight? fontWeight,
    double? height,
  }) => ThemedText(
    data,
    key: key,
    color: color,
    fontSize: fontSize ?? 12,
    fontFamily: 'monospace',
    fontWeight: fontWeight,
    height: height,
    maxLines: maxLines,
    overflow: overflow,
  );

  factory ThemedText.label(String data, {Key? key, Color? color}) => ThemedText(
    data,
    key: key,
    color: color,
    fontSize: 11,
    fontFamily: 'monospace',
    fontWeight: FontWeight.w500,
  );

  factory ThemedText.code(String data, {Key? key, Color? color}) => ThemedText(
    data,
    key: key,
    color: color,
    fontSize: 12,
    fontFamily: 'monospace',
  );

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Text(
      data,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: TextStyle(
        color: color ?? c.text,
        fontSize: fontSize ?? 14,
        fontWeight: fontWeight,
        fontFamily: fontFamily,
        height: height,
      ),
    );
  }
}
