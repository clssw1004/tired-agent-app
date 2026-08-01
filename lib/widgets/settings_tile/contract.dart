import 'package:flutter/material.dart';

/// 设置列表项数据：支持单选（selected）、导航（navigation）、信息（value）三种形态。
class SettingsTileData {
  final String label;
  final String? value;
  final bool selected;
  final VoidCallback? onTap;
  final bool navigation;

  const SettingsTileData({
    required this.label,
    this.value,
    this.selected = false,
    this.onTap,
    this.navigation = false,
  });
}

/// 设置列表项契约：各风格实现定义设置页 tile 的视觉形态。
abstract class SettingsTileContract {
  const SettingsTileContract();

  Widget build(BuildContext context, SettingsTileData data);
}
