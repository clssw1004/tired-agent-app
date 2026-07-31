import 'package:flutter/material.dart';

/// 加载指示样式模式。
enum LoadingMode { spinner, pulse, dots }

/// 加载指示契约：各风格实现定义加载态视觉。
abstract class LoadingContract {
  const LoadingContract();

  Widget build(
    BuildContext context, {
    double size = 24,
    Color? color,
    LoadingMode mode = LoadingMode.spinner,
  });
}
