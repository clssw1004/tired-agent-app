// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TiredAgent';

  @override
  String get navManagers => 'Managers';

  @override
  String get navSessions => 'Sessions';

  @override
  String get navSettings => 'Settings';

  @override
  String get managersTitle => 'Managers';

  @override
  String get managersWelcome => 'Welcome to tiredAgent';

  @override
  String get managersWelcomeDesc =>
      'Add a Manager server to manage your agents and sessions.';

  @override
  String get managersAdd => 'Add Manager';

  @override
  String get managersConnect => 'Connect';

  @override
  String get managersAdded => 'Manager added';

  @override
  String get managersReconnect => 'Reconnect';

  @override
  String get managersReconnected => 'reconnected';

  @override
  String get managersReconnectFailed => 'Reconnect failed';

  @override
  String get managersRemove => 'Remove';

  @override
  String managersRemoveTitle(String name) {
    return 'Remove \"$name\"?';
  }

  @override
  String get managersRemoveDesc =>
      'This will delete the manager profile and its saved token. You can re-add it later.';

  @override
  String get managersSessionExpired =>
      'Session expired. Enter the API token to reconnect.';

  @override
  String get managersAccessToken => 'Access Token';

  @override
  String get statusConnected => 'Connected';

  @override
  String get statusConnecting => 'Connecting…';

  @override
  String get statusError => 'Error';

  @override
  String get statusDisconnected => 'Disconnected';

  @override
  String get timeSecondsAgo => 's ago';

  @override
  String get timeMinutesAgo => 'm ago';

  @override
  String get timeHoursAgo => 'h ago';

  @override
  String get timeDaysAgo => 'd ago';

  @override
  String get agentAddTitle => 'Add Agent';

  @override
  String get agentRegister => 'Register';

  @override
  String agentAdded(String name) {
    return 'Agent $name added';
  }

  @override
  String agentAddFailed(String error) {
    return 'Failed to add agent: $error';
  }

  @override
  String agentRemoveTitle(String name) {
    return 'Remove agent \"$name\"?';
  }

  @override
  String get agentRemoveDesc =>
      'Unregisters the agent and removes its sessions. You can re-add it later.';

  @override
  String agentRemoved(String name) {
    return 'Agent $name removed';
  }

  @override
  String agentRemoveFailed(String error) {
    return 'Failed to remove agent: $error';
  }

  @override
  String get agentNoAgents => 'No Agents';

  @override
  String get agentNoAgentsDesc =>
      'Register an agent to start creating sessions';

  @override
  String get agentManagerNotFound => 'Manager not found';

  @override
  String get agentRetry => 'Retry';

  @override
  String get agentRemoveTooltip => 'Remove agent';

  @override
  String get agentAddTooltip => 'Add Agent';

  @override
  String get sessionsFilterAll => 'All';

  @override
  String get sessionsFilterRunning => 'Running';

  @override
  String get sessionsFilterExited => 'Exited';

  @override
  String get sessionsNewTooltip => 'New Session';

  @override
  String get sessionsKillTitle => 'Kill this session?';

  @override
  String get sessionsKillDesc =>
      'The running process will be terminated and removed from the list.';

  @override
  String get sessionsKillBtn => 'Kill';

  @override
  String get sessionsDeleteTitle => 'Delete session log?';

  @override
  String get sessionsDeleteDesc =>
      'Removes the database row and the on-disk output log. Cannot be undone.';

  @override
  String get sessionsDeleteBtn => 'Delete';

  @override
  String get sessionsConfirm => 'Confirm';

  @override
  String get sessionsPruneTitle => 'Clean stale sessions?';

  @override
  String get sessionsPruneDesc =>
      'Drops all sessions that have been inactive for more than 24 hours.';

  @override
  String get sessionsPruneBtn => 'Prune';

  @override
  String sessionsPruned(int count) {
    return 'Pruned $count session(s)';
  }

  @override
  String get sessionsEmpty => 'No sessions';

  @override
  String get sessionsLoading => 'Loading…';

  @override
  String get sessionsPinTitle => 'Pin Session';

  @override
  String get sessionsPinLabel => 'Display label';

  @override
  String get sessionsPinned => 'Session pinned';

  @override
  String get sessionsUnpinned => 'Session unpinned';

  @override
  String get sessionsNotConnected => 'Not connected';

  @override
  String get sessionsManagerNotFound => 'Manager not found';

  @override
  String sessionsCount(int count) {
    return '$count session(s)';
  }

  @override
  String get sessionTitle => 'Session';

  @override
  String get sessionKillTitle => 'Kill this session?';

  @override
  String get sessionKillDesc => 'The running process will be terminated.';

  @override
  String get sessionKillBtn => 'Kill';

  @override
  String sessionKillFailed(String error) {
    return 'Kill failed: $error';
  }

  @override
  String get sessionDeleteTitle => 'Delete session log?';

  @override
  String get sessionDeleteDesc =>
      'Removes the database row and the on-disk output log. Cannot be undone.';

  @override
  String get sessionDeleteBtn => 'Delete';

  @override
  String sessionDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

  @override
  String get sessionKillTooltip => 'Kill session';

  @override
  String get sessionDeleteTooltip => 'Delete session';

  @override
  String get sessionReconnectTooltip => 'Reconnect';

  @override
  String get sessionNotConnected => 'Manager not connected';

  @override
  String get sessionNotFound => 'Session not found';

  @override
  String get createTitle => 'NEW SESSION';

  @override
  String get createPreset => 'Preset';

  @override
  String get createPreview => 'Preview';

  @override
  String get createCommand => 'Command';

  @override
  String get createArguments => 'Arguments';

  @override
  String get createOptions => 'Options';

  @override
  String get createSessionLabel => 'Session label';

  @override
  String get createWorkingDir => 'Working directory';

  @override
  String get createCancel => 'CANCEL';

  @override
  String get createLaunch => 'LAUNCH';

  @override
  String get createSave => 'SAVE';

  @override
  String get createSaveAsPreset => 'Save as preset';

  @override
  String get createPresetName => 'Preset name';

  @override
  String get createSelectPreset => 'SELECT PRESET';

  @override
  String get createHomeDir => 'Agent home directory';

  @override
  String get createAutoLabel => 'Auto-generated if empty';

  @override
  String get createTerminalSizeHint =>
      'Terminal size auto-matches after session starts';

  @override
  String get createNotConnected => 'Not connected';

  @override
  String get createSectionRecent => 'Recent';

  @override
  String get createSectionCustom => 'Custom';

  @override
  String get createArgsHint => '--no-input  --verbose';

  @override
  String get createOptionsCancel => 'Cancel';

  @override
  String get createOptionsApply => 'Apply';

  @override
  String get pinnedTitle => 'Sessions';

  @override
  String get pinnedEmpty => 'No pinned sessions';

  @override
  String get pinnedEmptyDesc =>
      'Click 📌 in agent\'s session list\nto pin frequently used sessions here';

  @override
  String get pinnedUnpinTitle => 'Unpin session?';

  @override
  String pinnedUnpinDesc(String label) {
    return 'Remove \"$label\" from pinned sessions?';
  }

  @override
  String get pinnedUnpin => 'Unpin';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsApp => 'App';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeSystem => 'System';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get pinLabel => 'Pin';

  @override
  String get unpinLabel => 'Unpin';

  @override
  String get reconnectLabel => 'Reconnect';

  @override
  String get removeLabel => 'Remove';

  @override
  String get labelName => 'Label';

  @override
  String get labelUrl => 'URL';

  @override
  String get labelToken => 'Token';

  @override
  String get labelAgentName => 'Agent Name';

  @override
  String get labelAgentUrl => 'Agent URL';

  @override
  String get labelAgentToken => 'Agent Token';

  @override
  String get statusRunning => 'Running';

  @override
  String get statusStarting => 'Starting';

  @override
  String get statusExited => 'Exited';
}
