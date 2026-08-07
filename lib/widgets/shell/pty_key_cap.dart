import 'package:flutter/material.dart';

import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';

/// The visual "key cap" for a single virtual keyboard button.
///
/// This is the single source of truth for how a [TerminalKeyDef] is drawn,
/// shared by the PTY keyboard panel and the scheme editor preview so the
/// editor is WYSIWYG with the live panel.
///
/// Modifier keys (Ctrl / Alt / Shift) get a per-key accent color. When [lit]
/// is true the cap is highlighted with [litColor] — the panel lights active
/// modifiers, the editor lights the selected key.
class PtyKeyCap extends StatelessWidget {
  const PtyKeyCap({
    super.key,
    required this.keyDef,
    this.onTap,
    this.lit = false,
    this.litColor,
    this.height = 30,
  });

  /// The key definition to render.
  final TerminalKeyDef keyDef;

  /// Tap handler. `null` renders the key as untappable.
  final VoidCallback? onTap;

  /// Whether the cap is highlighted (active modifier / editor selection).
  final bool lit;

  /// Accent color used when [lit]. Falls back to the modifier accent.
  final Color? litColor;

  /// Cap height (matches the PTY panel).
  final double height;

  /// Whether [k] is an arrow key — those get a larger label.
  static bool _isArrow(TerminalKeyDef k) =>
      k.id == 'up' || k.id == 'down' || k.id == 'left' || k.id == 'right';

  /// Per-modifier accent color, matching the PTY panel.
  Color _accent(AppColors c) => switch (keyDef.id) {
    'ctrl' => c.primary,
    'alt' => c.secondary,
    'shift' => c.warning,
    _ => c.primary,
  };

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final accent = litColor ?? _accent(c);
    final isArrow = _isArrow(keyDef);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1.5),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: lit ? accent.withAlpha(25) : c.surfaceAlt,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: lit ? accent : c.border.withAlpha(100),
              width: lit ? 1.0 : 0.5,
            ),
            boxShadow: lit
                ? [
                    BoxShadow(
                      color: accent.withAlpha(50),
                      blurRadius: 4,
                      spreadRadius: 0.5,
                    ),
                  ]
                : null,
          ),
          child: keyDef.icon != null
              ? Icon(keyDef.icon, size: 16, color: c.textCode)
              : Text(
                  keyDef.label,
                  style: TextStyle(
                    fontSize: isArrow ? 14 : 10,
                    fontWeight: lit
                        ? FontWeight.bold
                        : (isArrow ? FontWeight.w300 : FontWeight.w500),
                    color: lit ? accent : c.textCode,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      ),
    );
  }
}
