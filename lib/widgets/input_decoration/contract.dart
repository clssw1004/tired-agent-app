import 'package:flutter/material.dart';

/// 输入框装饰契约：各风格实现定义表单输入框的 [InputDecoration]。
abstract class InputDecorationContract {
  const InputDecorationContract();

  InputDecoration build(
    BuildContext context, {
    String? hint,
    String? prefixText,
  });
}
