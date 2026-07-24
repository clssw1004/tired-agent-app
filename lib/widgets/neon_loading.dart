import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

enum NeonLoadingMode { spinner, pulse, dots }

/// 霓虹风格加载指示器。
class NeonLoading extends StatefulWidget {
  final NeonLoadingMode mode;
  final double size;
  final Color color;

  const NeonLoading({
    super.key,
    this.mode = NeonLoadingMode.spinner,
    this.size = 24,
    this.color = AppColors.primary,
  });

  @override
  State<NeonLoading> createState() => _NeonLoadingState();
}

class _NeonLoadingState extends State<NeonLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (widget.mode) {
      NeonLoadingMode.spinner => _buildSpinner(),
      NeonLoadingMode.pulse => _buildPulse(),
      NeonLoadingMode.dots => _buildDots(),
    };
  }

  Widget _buildSpinner() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Transform.rotate(
        angle: _controller.value * 2 * pi,
        child: child,
      ),
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(widget.color),
        ),
      ),
    );
  }

  Widget _buildPulse() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (_controller.value * 3 + i) % 3;
          final opacity = sin(phase * pi).clamp(0.3, 1.0);
          return Padding(
            padding: EdgeInsets.only(right: i < 2 ? 4 : 0),
            child: Container(
              width: widget.size * 0.35,
              height: widget.size * 0.35,
              decoration: BoxDecoration(
                color: widget.color.withAlpha((opacity * 255).toInt()),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: widget.color.withAlpha(60), blurRadius: 4, spreadRadius: 0),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDots() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) {
        final count = (_controller.value * 8).floor() % 4 + 1;
        return ThemedText.mono(
          '${'·' * count}${' ' * (4 - count)}',
          color: widget.color,
        );
      },
    );
  }
}
