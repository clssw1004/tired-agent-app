/// Trigger point for session enhancements.
enum EnhancementPoint {
  /// After user selects a working directory.
  directorySelected,

  /// Before session spec is submitted.
  beforeSubmit,
}

/// Activation condition for an enhancement.
class EnhancementActivation {
  /// Activate when preset.id matches one of these.
  final List<String> presetIds;

  /// Activate when cmd matches this pattern.
  final Pattern? commandPattern;

  const EnhancementActivation({this.presetIds = const [], this.commandPattern});

  bool matches(String cmd, String? presetId) {
    if (presetId != null && presetIds.contains(presetId)) return true;
    if (commandPattern != null && commandPattern!.matchAsPrefix(cmd) != null) {
      return true;
    }
    return false;
  }
}
