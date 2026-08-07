import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/theme.dart';

/// 主题对比度回归防线：关键色对必须达到 WCAG 阈值
/// （正文/交互 4.5:1，状态图形 3:1），防止未来调色板回归。
void main() {
  final themes = {
    'neon-light': buildNeonLightTheme(),
    'neon-dark': buildNeonDarkTheme(),
    'geek-light': buildGeekLightTheme(),
    'geek-dark': buildGeekDarkTheme(),
    'md3-light': buildMd3LightTheme(),
    'md3-dark': buildMd3DarkTheme(),
  };

  double contrast(Color fg, Color bg) {
    double lum(Color c) {
      double f(double v) => v <= 0.04045
          ? v / 12.92
          : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      final r = f(c.r), g = f(c.g), b = f(c.b);
      return 0.2126 * r + 0.7152 * g + 0.0722 * b;
    }

    final l1 = lum(fg), l2 = lum(bg);
    final hi = l1 > l2 ? l1 : l2, lo = l1 > l2 ? l2 : l1;
    return (hi + 0.05) / (lo + 0.05);
  }

  themes.forEach((name, theme) {
    final scheme = theme.colorScheme;
    final c = theme.appColors;

    group('$name 对比度', () {
      // 文字/交互前景 ≥ 4.5:1
      test('onPrimary 对 primary', () {
        expect(
          contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('onSecondary 对 secondary', () {
        expect(
          contrast(scheme.onSecondary, scheme.secondary),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('onError 对 error', () {
        expect(
          contrast(scheme.onError, scheme.error),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('text 对 background', () {
        expect(contrast(c.text, c.background), greaterThanOrEqualTo(4.5));
      });
      test('textSecondary 对 background', () {
        expect(
          contrast(c.textSecondary, c.background),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('textSecondary 对 surface', () {
        expect(contrast(c.textSecondary, c.surface), greaterThanOrEqualTo(4.5));
      });
      test('primary 对 background', () {
        expect(contrast(c.primary, c.background), greaterThanOrEqualTo(4.5));
      });
      test('primary 对 surfaceAlt（按钮前景）', () {
        expect(contrast(c.primary, c.surfaceAlt), greaterThanOrEqualTo(4.5));
      });
      test('danger 对 surface（删除文字）', () {
        expect(contrast(c.danger, c.surface), greaterThanOrEqualTo(4.5));
      });

      // 状态图形 ≥ 3:1
      test('success 对 background', () {
        expect(contrast(c.success, c.background), greaterThanOrEqualTo(3.0));
      });
      test('warning 对 background', () {
        expect(contrast(c.warning, c.background), greaterThanOrEqualTo(3.0));
      });
    });
  });
}
