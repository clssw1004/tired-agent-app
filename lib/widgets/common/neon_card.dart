import 'package:flutter/material.dart';
import 'package:tired_agent_app/theme.dart';

/// Cyberpunk 风格暗色卡片容器。
/// 默认无边框（surface 背景），传入 [borderColor] 显示霓虹边框。
/// [glow] 为 true 时启用 boxShadow 发光效果。
class NeonCard extends StatelessWidget {
  final Widget child;
  final Color? borderColor;
  final bool glow;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;

  const NeonCard({
    super.key,
    required this.child,
    this.borderColor,
    this.glow = false,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.borderRadius = AppSpacing.two,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final hasBorder = borderColor != null;
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: c.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppSpacing.three),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(borderRadius),
              border: hasBorder
                  ? Border.all(color: borderColor!, width: 1)
                  : Border.all(color: c.border.withAlpha(60), width: 0.5),
              boxShadow: glow && hasBorder
                  ? [
                      BoxShadow(
                        color: borderColor!.withAlpha(40),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
