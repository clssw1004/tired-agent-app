import 'package:flutter/material.dart';

import 'package:tired_agent_app/widgets/agent_card/contract.dart';
import 'package:tired_agent_app/widgets/agent_card/neon_agent_card.dart';
import 'package:tired_agent_app/widgets/agent_card/material_agent_card.dart';
import 'package:tired_agent_app/widgets/agent_card/geek_agent_card.dart';
import 'package:tired_agent_app/widgets/manager_card/contract.dart';
import 'package:tired_agent_app/widgets/manager_card/neon_manager_card.dart';
import 'package:tired_agent_app/widgets/manager_card/material_manager_card.dart';
import 'package:tired_agent_app/widgets/manager_card/geek_manager_card.dart';
import 'package:tired_agent_app/widgets/session_card/contract.dart';
import 'package:tired_agent_app/widgets/session_card/neon_session_card.dart';
import 'package:tired_agent_app/widgets/session_card/material_session_card.dart';
import 'package:tired_agent_app/widgets/session_card/geek_session_card.dart';

/// 按风格分发组件的工厂（ThemeExtension 载体）。
///
/// 每份主题注册一套 [AppComponents]（如 [neon] / [geek]），
/// 页面通过 `context.appComponents.buildXxxCard(context, data)` 获取组件，
/// 事件副作用由页面构造 data 时注入，组件只负责布局与交互触发方式。
///
/// 后期其它组件纳入：在此加可空字段 + 解析 getter + `buildXxx` 入口即可。
class AppComponents extends ThemeExtension<AppComponents> {
  /// 各风格组件实现；某风格未实现某组件时为 null → 沿 [base] 链回落，最终到系统默认。
  final SessionCardContract? sessionCard;
  final ManagerCardContract? managerCard;
  final AgentCardContract? agentCard;

  /// 增强来源：该风格基于哪个底层风格做增强。未实现组件沿此链逐级回落。
  /// 例：新风格只实现 sessionCard 并 `base: geek` → manager/agent 回落 geek。
  final AppComponents? base;

  const AppComponents({this.sessionCard, this.managerCard, this.agentCard, this.base});

  /// 系统默认兜底（链终点）：全量实现、无 base（neon 最完整且基于主题色）。
  static const AppComponents systemFallback = AppComponents.neon;

  static const AppComponents neon = AppComponents(
    sessionCard: NeonSessionCard(),
    managerCard: NeonManagerCard(),
    agentCard: NeonAgentCard(),
  );

  static const AppComponents geek = AppComponents(
    sessionCard: GeekSessionCard(),
    managerCard: GeekManagerCard(),
    agentCard: GeekAgentCard(),
  );

  /// Material Design 3 风格 — 原生 M3 组件。
  static const AppComponents material = AppComponents(
    sessionCard: MD3SessionCard(),
    managerCard: MD3ManagerCard(),
    agentCard: MD3AgentCard(),
  );

  // 基于某风格增强的新风格（示例）：只实现部分，未实现回落 base（此处 geek）
  // static const AppComponents geekEnhanced = AppComponents(
  //   sessionCard: XxxSessionCard(),
  //   base: geek,
  // );

  /// 第一层兜底：沿 [base] 链向上找第一个非空实现；走完仍为空则第二层系统默认。
  SessionCardContract get sessionCardOrFallback {
    AppComponents? c = this;
    while (c != null) {
      if (c.sessionCard != null) return c.sessionCard!;
      c = c.base;
    }
    return systemFallback.sessionCard!; // 保险，理论不可达
  }

  ManagerCardContract get managerCardOrFallback {
    AppComponents? c = this;
    while (c != null) {
      if (c.managerCard != null) return c.managerCard!;
      c = c.base;
    }
    return systemFallback.managerCard!;
  }

  AgentCardContract get agentCardOrFallback {
    AppComponents? c = this;
    while (c != null) {
      if (c.agentCard != null) return c.agentCard!;
      c = c.base;
    }
    return systemFallback.agentCard!;
  }

  /// 统一渲染入口：页面只用它，不接触可空字段、不写空断言。
  Widget buildSessionCard(BuildContext context, SessionCardData data) =>
      sessionCardOrFallback.build(context, data);

  Widget buildManagerCard(BuildContext context, ManagerCardData data) =>
      managerCardOrFallback.build(context, data);

  Widget buildAgentCard(BuildContext context, AgentCardData data) =>
      agentCardOrFallback.build(context, data);

  @override
  AppComponents copyWith({
    SessionCardContract? sessionCard,
    ManagerCardContract? managerCard,
    AgentCardContract? agentCard,
    AppComponents? base,
  }) =>
      AppComponents(
        sessionCard: sessionCard ?? this.sessionCard,
        managerCard: managerCard ?? this.managerCard,
        agentCard: agentCard ?? this.agentCard,
        base: base ?? this.base,
      );

  @override
  AppComponents lerp(ThemeExtension<AppComponents>? other, double t) =>
      other is! AppComponents
          ? this
          : AppComponents(
              sessionCard: t < 0.5 ? sessionCard : other.sessionCard,
              managerCard: t < 0.5 ? managerCard : other.managerCard,
              agentCard: t < 0.5 ? agentCard : other.agentCard,
              base: t < 0.5 ? base : other.base,
            );
}

extension BuildContextAppComponents on BuildContext {
  /// 主题未注册 AppComponents → 返回系统默认，不空断言，保证页面正常渲染。
  AppComponents get appComponents =>
      Theme.of(this).extension<AppComponents>() ?? AppComponents.systemFallback;
}
