import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/types.dart';

/// Agent 卡片的功能插槽：业务数据 + 业务回调（副作用由页面注入）。
class AgentCardData {
  const AgentCardData({
    required this.agent,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final AgentInfo agent;

  /// 整卡点击 → 业务：跳转 agent 会话列表。
  final VoidCallback? onTap;

  /// 编辑入口 → 业务：打开编辑表单。
  final VoidCallback? onEdit;

  /// 删除入口 → 业务：调用删除接口 + 刷新列表。
  final VoidCallback? onDelete;
}

/// Agent 卡片的风格契约：各风格实现继承并定义自身布局与交互触发方式。
abstract class AgentCardContract {
  const AgentCardContract();

  Widget build(BuildContext context, AgentCardData data);
}
