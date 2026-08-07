import 'package:flutter/material.dart';

import 'package:tired_agent_app/models/manager_connection.dart';

/// Manager 卡片的功能插槽：业务数据 + 业务回调（副作用由页面注入）。
class ManagerCardData {
  const ManagerCardData({required this.connection, this.onTap, this.onDelete});

  final ManagerConnection connection;

  /// 整卡点击 → 业务：跳转 manager 详情。
  final VoidCallback? onTap;

  /// 删除入口 → 业务：调用删除接口 + 刷新列表。
  final VoidCallback? onDelete;
}

/// Manager 卡片的风格契约：各风格实现继承并定义自身布局与交互触发方式。
abstract class ManagerCardContract {
  const ManagerCardContract();

  Widget build(BuildContext context, ManagerCardData data);
}
