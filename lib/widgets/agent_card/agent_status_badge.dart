import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/utils/app_strings.dart';

/// Agent 状态文字标签（i18n）。
String agentStateLabel(AgentState s) => switch (s) {
  AgentState.online => AppStrings.of.agentStateOnline,
  AgentState.offline => AppStrings.of.agentStateOffline,
  AgentState.pending => AppStrings.of.agentStatePending,
};

/// Agent 在线/离线状态徽章：色点 + 文字标签，带浅色背景圆角胶囊。
///
/// 纯小圆点在手机上不够醒目（尤其离线/待定无法一眼区分），加文字标签后
/// 状态一目了然。[color] 由各风格卡片按自身配色方案提供（neon 用
/// AppColors，Material 用 ColorScheme）。
class AgentStatusBadge extends StatelessWidget {
  final Color color;
  final String label;

  /// 在线时给色点加光晕（neon 风格）。
  final bool glow;

  const AgentStatusBadge({
    super.key,
    required this.color,
    required this.label,
    this.glow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(70), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: glow
                  ? [BoxShadow(color: color.withAlpha(120), blurRadius: 4)]
                  : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
