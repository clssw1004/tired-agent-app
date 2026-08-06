import 'package:tired_agent_app/utils/pty_keyboard_config.dart';
import 'package:tired_agent_app/utils/terminal_keys.dart';

/// All user-side keyboard preferences persisted to disk.
class PtyKeyboardPrefs {
  final List<PtyKeyboardScheme> schemes;

  /// Scheme id to fall back to when neither session assignment nor a
  /// command preset resolves. `null` means "let [PtyKeyboardConfig.fromCommand]
  /// decide on the fly".
  final String? defaultSchemeId;

  /// Per-session scheme overrides (client-side).
  final Map<String, String> sessionAssignments;

  const PtyKeyboardPrefs({
    required this.schemes,
    required this.defaultSchemeId,
    required this.sessionAssignments,
  });

  factory PtyKeyboardPrefs.empty() => const PtyKeyboardPrefs(
    schemes: [],
    defaultSchemeId: null,
    sessionAssignments: {},
  );

  PtyKeyboardPrefs copyWith({
    List<PtyKeyboardScheme>? schemes,
    String? defaultSchemeId,
    bool clearDefaultSchemeId = false,
    Map<String, String>? sessionAssignments,
  }) => PtyKeyboardPrefs(
    schemes: schemes ?? this.schemes,
    defaultSchemeId: clearDefaultSchemeId
        ? null
        : (defaultSchemeId ?? this.defaultSchemeId),
    sessionAssignments: sessionAssignments ?? this.sessionAssignments,
  );

  Map<String, dynamic> toJson() => {
    'schemes': schemes.map((s) => s.toJson()).toList(),
    'defaultSchemeId': defaultSchemeId,
    'sessionAssignments': sessionAssignments,
  };

  factory PtyKeyboardPrefs.fromJson(Map<String, dynamic> json) => PtyKeyboardPrefs(
    schemes: (json['schemes'] as List<dynamic>? ?? const [])
        .map((e) => PtyKeyboardScheme.fromJson(e as Map<String, dynamic>))
        .toList(),
    defaultSchemeId: json['defaultSchemeId'] as String?,
    sessionAssignments: ((json['sessionAssignments'] as Map<String, dynamic>?) ??
            const {})
        .map((k, v) => MapEntry(k, v as String)),
  );
}

/// A user-editable extended keyboard scheme.
///
/// A scheme holds the rows of keys for the virtual keyboard panel, and can be
/// based on (or reset to) one of the builtin presets via [basePresetId].
class PtyKeyboardScheme {
  /// Machine-friendly id.
  final String id;

  /// Human-readable name shown in pickers.
  final String name;

  /// Id of the builtin preset this scheme derives from (e.g. `"shell"`),
  /// or `null` for a fully custom scheme with no preset base.
  final String? basePresetId;

  /// Row definitions — each sub-list is one row of buttons.
  final List<List<TerminalKeyDef>> rows;

  const PtyKeyboardScheme({
    required this.id,
    required this.name,
    this.basePresetId,
    required this.rows,
  });

  /// Build a [PtyKeyboardConfig] for the keyboard panel from this scheme.
  PtyKeyboardConfig toConfig() => PtyKeyboardConfig(
    id: id,
    name: name,
    rows: rows,
  );

  /// Rebuild a scheme from a config, preserving the given id.
  factory PtyKeyboardScheme.fromConfig({
    required String id,
    required String name,
    required List<List<TerminalKeyDef>> rows,
    String? basePresetId,
  }) => PtyKeyboardScheme(
    id: id,
    name: name,
    basePresetId: basePresetId,
    rows: rows,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'basePresetId': basePresetId,
    'rows': rows
        .map(
          (row) => row.map((k) => k.toJson()).toList(),
        )
        .toList(),
  };

  factory PtyKeyboardScheme.fromJson(Map<String, dynamic> json) =>
      PtyKeyboardScheme(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        basePresetId: json['basePresetId'] as String?,
        rows: (json['rows'] as List<dynamic>? ?? const [])
            .map(
              (row) => (row as List<dynamic>)
                  .map(
                    (k) => TerminalKeyDef.fromJson(k as Map<String, dynamic>),
                  )
                  .toList(),
            )
            .toList(),
      );
}
