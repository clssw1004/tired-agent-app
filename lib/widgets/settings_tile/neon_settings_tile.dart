import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';
import 'package:tired_agent_app/widgets/settings_tile/contract.dart';

/// 赛博朋克风格设置项：surface 底 + 语义色描边，选中主色高亮 + check。
class NeonSettingsTile extends SettingsTileContract {
  const NeonSettingsTile();

  @override
  Widget build(BuildContext context, SettingsTileData data) {
    final c = context.appColors;
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.three,
          vertical: AppSpacing.two,
        ),
        decoration: BoxDecoration(
          color: data.selected ? c.primary.withAlpha(10) : c.surface,
          borderRadius: BorderRadius.circular(AppSpacing.two),
          border: Border.all(
            color: data.selected
                ? c.primary.withAlpha(60)
                : c.border.withAlpha(40),
            width: data.selected ? 1 : 0.5,
          ),
        ),
        child: Row(
          children: [
            ThemedText.body(
              data.label,
              color: data.selected ? c.primary : c.text,
            ),
            const Spacer(),
            if (data.value != null)
              ThemedText(
                data.value!,
                color: c.text,
                fontSize: 12,
                textAlign: TextAlign.end,
              )
            else if (data.selected)
              Icon(Icons.check, size: 18, color: c.primary)
            else if (data.navigation)
              Icon(Icons.chevron_right, size: 18, color: c.textSecondary)
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
