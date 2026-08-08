import 'package:flutter/material.dart';

import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// Manager-Agent 分组视图的紧凑分组头。
///
/// 展示：折叠箭头 + manager 名称 + agent 数量 + 连接状态胶囊 + 「＋agent」 + 「详情→」。
/// 箭头+名称整块点击触发 [onToggle] 折叠/展开；「＋agent」/「详情→」为独立按钮。
class ManagerGroupHeader extends StatelessWidget {
  const ManagerGroupHeader({
    super.key,
    required this.connection,
    required this.collapsed,
    required this.agentCount,
    required this.onToggle,
    required this.onAddAgent,
    required this.onOpenDetail,
  });

  final ManagerConnection connection;
  final bool collapsed;
  final int agentCount;
  final VoidCallback onToggle;
  final VoidCallback onAddAgent;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final profile = connection.profile;
    final connStatus = connection.status;
    final connected = connStatus == ConnectionStatus.connected;

    // 状态色 + 文案（对齐 NeonManagerCard 的映射）。
    final (statusColor, statusLabel) = switch (connStatus) {
      ConnectionStatus.connected => (c.success, AppStrings.of.statusConnected),
      ConnectionStatus.connecting => (
        c.warning,
        AppStrings.of.statusConnecting,
      ),
      ConnectionStatus.error => (c.danger, AppStrings.of.statusError),
      ConnectionStatus.idle => (
        c.textSecondary,
        AppStrings.of.statusDisconnected,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.two),
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: Border.all(
            color: collapsed ? c.border.withAlpha(60) : c.primary.withAlpha(50),
            width: 0.5,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.two,
            AppSpacing.one,
            AppSpacing.two,
            AppSpacing.one,
          ),
          child: Row(
            children: [
              // ── 折叠箭头 + 名称（整块点击折叠/展开） ─────────
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: Row(
                    children: [
                      AnimatedRotation(
                        turns: collapsed ? 0 : 0.5,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          Icons.expand_more,
                          size: 20,
                          color: c.textSecondary,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.one),
                      Expanded(
                        child: ThemedText.body(
                          profile.name,
                          color: c.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // ── agent 数量 ──────────────────────────────────
              if (agentCount > 0) ...[
                const SizedBox(width: AppSpacing.two),
                ThemedText.mono(
                  AppStrings.of.homeAgentCount(agentCount),
                  color: c.textSecondary,
                ),
              ],
              // ── 状态胶囊 ─────────────────────────────────────
              const SizedBox(width: AppSpacing.two),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.two,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withAlpha(12),
                  borderRadius: BorderRadius.circular(AppSpacing.one),
                  border: Border.all(
                    color: statusColor.withAlpha(40),
                    width: 0.5,
                  ),
                ),
                child: ThemedText.label(statusLabel, color: statusColor),
              ),
              // ── ＋agent（未连接禁用） ───────────────────────
              IconButton(
                icon: Icon(
                  Icons.add,
                  size: 18,
                  color: connected ? c.primary : c.textSecondary.withAlpha(60),
                ),
                tooltip: AppStrings.of.agentAddTooltip,
                onPressed: connected ? onAddAgent : null,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
              // ── 详情→ ───────────────────────────────────────
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onOpenDetail,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.one,
                    vertical: AppSpacing.two,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ThemedText.label(
                        AppStrings.of.homeDetail,
                        color: c.primary,
                      ),
                      const SizedBox(width: 2),
                      Icon(Icons.chevron_right, size: 14, color: c.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
