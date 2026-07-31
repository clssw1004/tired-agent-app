import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/loading/contract.dart';

/// 极简极客风格加载指示：等宽 `· · ·` 动画 dots。
class GeekLoadingImpl extends LoadingContract {
  const GeekLoadingImpl();

  @override
  Widget build(
    BuildContext context, {
    double size = 24,
    Color? color,
    LoadingMode mode = LoadingMode.spinner,
  }) {
    return _GeekDots(color: color ?? context.appColors.primary);
  }
}

class _GeekDots extends StatefulWidget {
  final Color color;

  const _GeekDots({required this.color});

  @override
  State<_GeekDots> createState() => _GeekDotsState();
}

class _GeekDotsState extends State<_GeekDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final count = (_controller.value * 4).floor() % 4 + 1;
        return ThemedText(
          '${'·' * count}${' ' * (4 - count)}',
          color: widget.color,
          fontSize: 16,
          fontFamily: 'monospace',
        );
      },
    );
  }
}
