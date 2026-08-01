import 'package:flutter/material.dart';

/// 主题无关的弹窗外壳：屏幕占比、Column stretch 撑满、maxWidth 三者集中一处。
/// 三风格 (neon/geek/material) 仅提供背景/边框/标题/按钮 widget，整体布局由本组件决定。
class StyledDialogBody extends StatelessWidget {
  final Widget title;
  final Widget content;
  final List<Widget> actions;
  final Color backgroundColor;
  final Color borderColor;
  final double borderRadius;
  final double maxWidth;
  final EdgeInsets? insetPadding;
  final EdgeInsets titlePadding;
  final EdgeInsets contentPadding;
  final EdgeInsets actionsPadding;
  final double maxContentHeight;
  final double actionSpacing;

  const StyledDialogBody({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    required this.backgroundColor,
    required this.borderColor,
    this.borderRadius = 12,
    required this.maxWidth,
    this.insetPadding,
    this.titlePadding = const EdgeInsets.fromLTRB(24, 16, 24, 12),
    this.contentPadding = const EdgeInsets.fromLTRB(24, 0, 24, 12),
    this.actionsPadding = const EdgeInsets.fromLTRB(24, 0, 24, 12),
    this.maxContentHeight = 480,
    this.actionSpacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding:
          insetPadding ??
          const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Container(
        constraints: BoxConstraints(maxWidth: maxWidth),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(padding: titlePadding, child: title),
            Flexible(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxContentHeight),
                child: SingleChildScrollView(
                  padding: contentPadding,
                  child: content,
                ),
              ),
            ),
            Padding(
              padding: actionsPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) SizedBox(width: actionSpacing),
                    actions[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}