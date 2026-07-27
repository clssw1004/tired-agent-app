import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/themed_text.dart';

enum NeonLoadingMode { spinner, pulse, dots }

class NeonLoading extends StatefulWidget {
  final NeonLoadingMode mode;
  final double size;
  final Color color;

  NeonLoading({
    super.key,
    this.mode = NeonLoadingMode.spinner,
    this.size = 24,
    Color? color,
  }) : color = color ?? AppColors.dark.primary;

  @override
  State<NeonLoading> createState() => _NeonLoadingState();
}

class _NeonLoadingState extends State<NeonLoading>
    with SingleTickerProviderStateMixin {
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
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation(widget.color),
        backgroundColor: widget.color.withAlpha(20),
      ),
    );
  }

  Widget _buildPulse() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, _) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final phase = (_controller.value * 2 * 3.14159 + i * 2 * 3.14159 / 3) % (2 * 3.14159);
          final opacity = (phase < 3.14159 ? (phase / 3.14159) : 0).clamp(0.3, 1.0);
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
