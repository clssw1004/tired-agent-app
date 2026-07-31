import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/types.dart';

/// Session 卡片的功能插槽：业务数据 + 业务回调（副作用由页面注入）。
///
/// 组件只负责布局与交互触发方式（点击 / 长按 / 按钮 / 滑动删除），
/// 触发后调用对应回调，回调的具体动作（跳转、调接口、刷新）由业务方定义。
class SessionCardData {
  const SessionCardData({
    required this.session,
    required this.onTap,
    this.onKill,
    this.onDelete,
    this.onResume,
    this.onPin,
    this.isPinned = false,
  });

  final Session session;

  /// 整卡点击 → 业务：跳转会话。
  final VoidCallback onTap;

  /// kill 入口 → 业务：调用 kill 接口。
  final VoidCallback? onKill;

  /// 删除入口 → 业务：调用删除接口 + 刷新列表。
  final VoidCallback? onDelete;

  /// 恢复入口 → 业务：恢复已退出会话。
  final VoidCallback? onResume;

  /// 置顶入口 → 业务：切换置顶状态。
  final VoidCallback? onPin;

  final bool isPinned;
}

/// Session 卡片的风格契约：各风格实现继承并定义自身布局与交互触发方式。
abstract class SessionCardContract {
  const SessionCardContract();

  Widget build(BuildContext context, SessionCardData data);
}
