import 'package:flutter/material.dart';

/// CRT 扫描线效果 overlay。
/// 默认 [enabled] = false，需要在 Settings 中手动开启。
/// 使用 CustomPainter 绘制，无性能开销。
class ScanLines extends StatelessWidget {
  final double opacity;
  final bool enabled;

  const ScanLines({super.key, this.opacity = 0.03, this.enabled = false});

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    return IgnorePointer(
      child: Positioned.fill(
        child: CustomPaint(
          painter: _ScanLinePainter(opacity: opacity),
        ),
      ),
    );
  }
}

class _ScanLinePainter extends CustomPainter {
  final double opacity;

  _ScanLinePainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF).withAlpha((opacity * 255).toInt())
      ..strokeWidth = 0.5;

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanLinePainter old) => old.opacity != opacity;
}
