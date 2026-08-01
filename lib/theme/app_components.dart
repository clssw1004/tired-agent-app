import 'package:flutter/material.dart';

import 'package:tired_agent_app/widgets/agent_card/contract.dart';
import 'package:tired_agent_app/widgets/agent_card/neon_agent_card.dart';
import 'package:tired_agent_app/widgets/agent_card/material_agent_card.dart';
import 'package:tired_agent_app/widgets/agent_card/geek_agent_card.dart';
import 'package:tired_agent_app/widgets/command_preview/contract.dart';
import 'package:tired_agent_app/widgets/command_preview/geek_command_preview.dart';
import 'package:tired_agent_app/widgets/command_preview/material_command_preview.dart';
import 'package:tired_agent_app/widgets/command_preview/neon_command_preview.dart';
import 'package:tired_agent_app/widgets/dialog/contract.dart';
import 'package:tired_agent_app/widgets/dialog/geek_dialog.dart';
import 'package:tired_agent_app/widgets/dialog/material_dialog.dart';
import 'package:tired_agent_app/widgets/dialog/neon_dialog.dart';
import 'package:tired_agent_app/widgets/input_decoration/contract.dart';
import 'package:tired_agent_app/widgets/input_decoration/geek_input_decoration.dart';
import 'package:tired_agent_app/widgets/input_decoration/material_input_decoration.dart';
import 'package:tired_agent_app/widgets/input_decoration/neon_input_decoration.dart';
import 'package:tired_agent_app/widgets/loading/contract.dart';
import 'package:tired_agent_app/widgets/loading/geek_loading.dart';
import 'package:tired_agent_app/widgets/loading/material_loading.dart';
import 'package:tired_agent_app/widgets/loading/neon_loading.dart';
import 'package:tired_agent_app/widgets/manager_card/contract.dart';
import 'package:tired_agent_app/widgets/manager_card/neon_manager_card.dart';
import 'package:tired_agent_app/widgets/manager_card/material_manager_card.dart';
import 'package:tired_agent_app/widgets/manager_card/geek_manager_card.dart';
import 'package:tired_agent_app/widgets/section_header/contract.dart';
import 'package:tired_agent_app/widgets/section_header/geek_section_header.dart';
import 'package:tired_agent_app/widgets/section_header/material_section_header.dart';
import 'package:tired_agent_app/widgets/section_header/neon_section_header.dart';
import 'package:tired_agent_app/widgets/session_card/contract.dart';
import 'package:tired_agent_app/widgets/session_card/neon_session_card.dart';
import 'package:tired_agent_app/widgets/session_card/material_session_card.dart';
import 'package:tired_agent_app/widgets/session_card/geek_session_card.dart';
import 'package:tired_agent_app/widgets/settings_tile/contract.dart';
import 'package:tired_agent_app/widgets/settings_tile/geek_settings_tile.dart';
import 'package:tired_agent_app/widgets/settings_tile/material_settings_tile.dart';
import 'package:tired_agent_app/widgets/settings_tile/neon_settings_tile.dart';

/// 按风格分发组件的工厂（ThemeExtension 载体）。
///
/// 每份主题注册一套 [AppComponents]（如 [neon] / [geek] / [material]），
/// 页面通过 `context.appComponents.buildXxx(context, data)` 获取组件，
/// 事件副作用由页面构造 data 时注入，组件只负责布局与交互触发方式。
///
/// 后期其它组件纳入：在此加可空字段 + 解析 getter + `buildXxx` 入口即可。
class AppComponents extends ThemeExtension<AppComponents> {
  /// 各风格组件实现；某风格未实现某组件时为 null → 沿 [base] 链回落，最终到系统默认。
  final SessionCardContract? sessionCard;
  final ManagerCardContract? managerCard;
  final AgentCardContract? agentCard;
  final DialogContract? dialog;
  final SectionHeaderContract? sectionHeader;
  final LoadingContract? loading;
  final CommandPreviewContract? commandPreview;
  final InputDecorationContract? inputDecoration;
  final SettingsTileContract? settingsTile;

  /// 增强来源：该风格基于哪个底层风格做增强。未实现组件沿此链逐级回落。
  /// 例：新风格只实现 sessionCard 并 `base: geek` → manager/agent 回落 geek。
  final AppComponents? base;

  const AppComponents({
    this.sessionCard,
    this.managerCard,
    this.agentCard,
    this.dialog,
    this.sectionHeader,
    this.loading,
    this.commandPreview,
    this.inputDecoration,
    this.settingsTile,
    this.base,
  });

  /// 系统默认兜底（链终点）：全量实现、无 base（neon 最完整且基于主题色）。
  static const AppComponents systemFallback = AppComponents.neon;

  static const AppComponents neon = AppComponents(
    sessionCard: NeonSessionCard(),
    managerCard: NeonManagerCard(),
    agentCard: NeonAgentCard(),
    dialog: NeonDialogImpl(),
    sectionHeader: NeonSectionHeader(),
    loading: NeonLoadingImpl(),
    commandPreview: NeonCommandPreview(),
    inputDecoration: NeonInputDecorationImpl(),
    settingsTile: NeonSettingsTile(),
  );

  static const AppComponents geek = AppComponents(
    sessionCard: GeekSessionCard(),
    managerCard: GeekManagerCard(),
    agentCard: GeekAgentCard(),
    dialog: GeekDialogImpl(),
    sectionHeader: GeekSectionHeader(),
    loading: GeekLoadingImpl(),
    commandPreview: GeekCommandPreview(),
    inputDecoration: GeekInputDecorationImpl(),
    settingsTile: GeekSettingsTile(),
  );

  /// Material Design 3 风格 — 原生 M3 组件。
  static const AppComponents material = AppComponents(
    sessionCard: MD3SessionCard(),
    managerCard: MD3ManagerCard(),
    agentCard: MD3AgentCard(),
    dialog: MaterialDialogImpl(),
    sectionHeader: MaterialSectionHeader(),
    loading: MaterialLoadingImpl(),
    commandPreview: MaterialCommandPreview(),
    inputDecoration: MaterialInputDecorationImpl(),
    settingsTile: MaterialSettingsTile(),
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
    return systemFallback.sessionCard!;
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

  DialogContract get dialogOrFallback {
    AppComponents? c = this;
    while (c != null) {
      if (c.dialog != null) return c.dialog!;
      c = c.base;
    }
    return systemFallback.dialog!;
  }

  SectionHeaderContract get sectionHeaderOrFallback {
    AppComponents? c = this;
    while (c != null) {
      if (c.sectionHeader != null) return c.sectionHeader!;
      c = c.base;
    }
    return systemFallback.sectionHeader!;
  }

  LoadingContract get loadingOrFallback {
    AppComponents? c = this;
    while (c != null) {
      if (c.loading != null) return c.loading!;
      c = c.base;
    }
    return systemFallback.loading!;
  }

  CommandPreviewContract get commandPreviewOrFallback {
    AppComponents? c = this;
    while (c != null) {
      if (c.commandPreview != null) return c.commandPreview!;
      c = c.base;
    }
    return systemFallback.commandPreview!;
  }

  InputDecorationContract get inputDecorationOrFallback {
    AppComponents? c = this;
    while (c != null) {
      if (c.inputDecoration != null) return c.inputDecoration!;
      c = c.base;
    }
    return systemFallback.inputDecoration!;
  }

  SettingsTileContract get settingsTileOrFallback {
    AppComponents? c = this;
    while (c != null) {
      if (c.settingsTile != null) return c.settingsTile!;
      c = c.base;
    }
    return systemFallback.settingsTile!;
  }

  /// 统一渲染入口：页面只用它，不接触可空字段、不写空断言。
  Widget buildSessionCard(BuildContext context, SessionCardData data) =>
      sessionCardOrFallback.build(context, data);

  Widget buildManagerCard(BuildContext context, ManagerCardData data) =>
      managerCardOrFallback.build(context, data);

  Widget buildAgentCard(BuildContext context, AgentCardData data) =>
      agentCardOrFallback.build(context, data);

  Widget buildSectionHeader(BuildContext context, String label, {Color? color}) =>
      sectionHeaderOrFallback.build(context, label, color: color);

  Widget buildLoading(
    BuildContext context, {
    double size = 24,
    Color? color,
    LoadingMode mode = LoadingMode.spinner,
  }) =>
      loadingOrFallback.build(context, size: size, color: color, mode: mode);

  Widget buildCommandPreview(
    BuildContext context, {
    required String cmd,
    required String commandLine,
    Widget? actions,
  }) =>
      commandPreviewOrFallback.build(
        context,
        cmd: cmd,
        commandLine: commandLine,
        actions: actions,
      );

  InputDecoration buildInputDecoration(
    BuildContext context, {
    String? label,
    String? hint,
    String? prefixText,
  }) =>
      inputDecorationOrFallback.build(
        context,
        label: label,
        hint: hint,
        prefixText: prefixText,
      );

  Widget buildSettingsTile(BuildContext context, SettingsTileData data) =>
      settingsTileOrFallback.build(context, data);

  @override
  AppComponents copyWith({
    SessionCardContract? sessionCard,
    ManagerCardContract? managerCard,
    AgentCardContract? agentCard,
    DialogContract? dialog,
    SectionHeaderContract? sectionHeader,
    LoadingContract? loading,
    CommandPreviewContract? commandPreview,
    InputDecorationContract? inputDecoration,
    SettingsTileContract? settingsTile,
    AppComponents? base,
  }) =>
      AppComponents(
        sessionCard: sessionCard ?? this.sessionCard,
        managerCard: managerCard ?? this.managerCard,
        agentCard: agentCard ?? this.agentCard,
        dialog: dialog ?? this.dialog,
        sectionHeader: sectionHeader ?? this.sectionHeader,
        loading: loading ?? this.loading,
        commandPreview: commandPreview ?? this.commandPreview,
        inputDecoration: inputDecoration ?? this.inputDecoration,
        settingsTile: settingsTile ?? this.settingsTile,
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
              dialog: t < 0.5 ? dialog : other.dialog,
              sectionHeader: t < 0.5 ? sectionHeader : other.sectionHeader,
              loading: t < 0.5 ? loading : other.loading,
              commandPreview: t < 0.5 ? commandPreview : other.commandPreview,
              inputDecoration: t < 0.5 ? inputDecoration : other.inputDecoration,
              settingsTile: t < 0.5 ? settingsTile : other.settingsTile,
              base: t < 0.5 ? base : other.base,
            );
}

extension BuildContextAppComponents on BuildContext {
  /// 主题未注册 AppComponents → 返回系统默认，不空断言，保证页面正常渲染。
  AppComponents get appComponents =>
      Theme.of(this).extension<AppComponents>() ?? AppComponents.systemFallback;
}
