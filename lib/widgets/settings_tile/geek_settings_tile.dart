import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/settings_tile/contract.dart';

/// 极简极客风格设置项：等宽文字 + 1px 描边，选中 `*` 前缀 + 主色。
class GeekSettingsTile extends SettingsTileContract {
  const GeekSettingsTile();

  @override
  Widget build(BuildContext context, SettingsTileData data) {
    final c = context.appColors;
    final label = data.selected ? '* ${data.label}' : data.label;
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.three,
          vertical: AppSpacing.two,
        ),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.one),
          border: Border.all(
            color: data.selected ? c.primary.withAlpha(90) : c.border,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: ThemedText.mono(
                label,
                fontWeight: FontWeight.w600,
                color: data.selected ? c.primary : c.text,
              ),
            ),
            if (data.value != null)
              ThemedText.mono(data.value!, color: c.textSecondary)
            else if (data.navigation)
              ThemedText.mono('>', color: c.textSecondary)
            else if (data.onSwitchChanged != null)
              Switch(
                value: data.switchValue,
                onChanged: data.onSwitchChanged,
                activeThumbColor: c.primary,
                activeTrackColor: c.primary.withAlpha(60),
              ),
          ],
        ),
      ),
    );
  }
}
