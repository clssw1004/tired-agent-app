import 'package:flutter/material.dart';

import 'package:tired_agent_app/widgets/settings_tile/contract.dart';

/// Material Design 3 风格设置项：原生 M3 ListTile，选中 primaryContainer 底 + check。
class MaterialSettingsTile extends SettingsTileContract {
  const MaterialSettingsTile();

  @override
  Widget build(BuildContext context, SettingsTileData data) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: data.onTap,
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minTileHeight: 44,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: data.selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      leading: data.selected
          ? Icon(Icons.check, size: 20, color: scheme.onPrimaryContainer)
          : null,
      title: Text(
        data.label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: data.selected ? scheme.onPrimaryContainer : scheme.onSurface,
        ),
      ),
      trailing: data.value != null
          ? Text(
              data.value!,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
            )
          : data.navigation
          ? Icon(Icons.chevron_right, size: 20, color: scheme.onSurfaceVariant)
          : null,
    );
  }
}
