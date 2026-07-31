import 'package:flutter/material.dart';
import 'package:tired_agent_app/widgets/loading/contract.dart';

/// Material Design 3 风格加载指示：原生 [CircularProgressIndicator]。
class MaterialLoadingImpl extends LoadingContract {
  const MaterialLoadingImpl();

  @override
  Widget build(
    BuildContext context, {
    double size = 24,
    Color? color,
    LoadingMode mode = LoadingMode.spinner,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation(
          color ?? Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
