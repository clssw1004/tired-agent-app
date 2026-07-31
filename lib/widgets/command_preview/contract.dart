import 'package:flutter/material.dart';

/// 命令预览契约：各风格实现定义创建会话的命令预览视觉。
abstract class CommandPreviewContract {
  const CommandPreviewContract();

  Widget build(
    BuildContext context, {
    required String cmd,
    required String commandLine,
    Widget? actions,
  });
}
