import 'package:flutter/material.dart';

/// 节标题风格契约：各风格实现定义分区标题的视觉（neon 发光竖条 / geek 等宽 / material 标题）。
abstract class SectionHeaderContract {
  const SectionHeaderContract();

  Widget build(BuildContext context, String label, {Color? color});
}
