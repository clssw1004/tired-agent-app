import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// Application title
  ///
  /// In en, this message translates to:
  /// **'TiredAgent'**
  String get appTitle;

  /// No description provided for @navManagers.
  ///
  /// In en, this message translates to:
  /// **'Managers'**
  String get navManagers;

  /// No description provided for @navSessions.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get navSessions;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @managersTitle.
  ///
  /// In en, this message translates to:
  /// **'Managers'**
  String get managersTitle;

  /// No description provided for @managersWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to tiredAgent'**
  String get managersWelcome;

  /// No description provided for @managersWelcomeDesc.
  ///
  /// In en, this message translates to:
  /// **'Add a Manager server to manage your agents and sessions.'**
  String get managersWelcomeDesc;

  /// No description provided for @managersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Manager'**
  String get managersAdd;

  /// No description provided for @managersConnect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get managersConnect;

  /// No description provided for @managersAdded.
  ///
  /// In en, this message translates to:
  /// **'Manager added'**
  String get managersAdded;

  /// No description provided for @managersReconnect.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get managersReconnect;

  /// No description provided for @managersReconnected.
  ///
  /// In en, this message translates to:
  /// **'reconnected'**
  String get managersReconnected;

  /// No description provided for @managersReconnectFailed.
  ///
  /// In en, this message translates to:
  /// **'Reconnect failed'**
  String get managersReconnectFailed;

  /// No description provided for @managersRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get managersRemove;

  /// No description provided for @managersRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\"?'**
  String managersRemoveTitle(String name);

  /// No description provided for @managersRemoveDesc.
  ///
  /// In en, this message translates to:
  /// **'This will delete the manager profile and its saved token. You can re-add it later.'**
  String get managersRemoveDesc;

  /// No description provided for @managersSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Enter the API token to reconnect.'**
  String get managersSessionExpired;

  /// No description provided for @managersAccessToken.
  ///
  /// In en, this message translates to:
  /// **'Access Token'**
  String get managersAccessToken;

  /// No description provided for @statusConnected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get statusConnected;

  /// No description provided for @statusConnecting.
  ///
  /// In en, this message translates to:
  /// **'Connecting…'**
  String get statusConnecting;

  /// No description provided for @statusError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get statusError;

  /// No description provided for @statusDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get statusDisconnected;

  /// No description provided for @timeSecondsAgo.
  ///
  /// In en, this message translates to:
  /// **'s ago'**
  String get timeSecondsAgo;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'m ago'**
  String get timeMinutesAgo;

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'h ago'**
  String get timeHoursAgo;

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'d ago'**
  String get timeDaysAgo;

  /// No description provided for @agentAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Agent'**
  String get agentAddTitle;

  /// No description provided for @agentRegister.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get agentRegister;

  /// No description provided for @agentAdded.
  ///
  /// In en, this message translates to:
  /// **'Agent {name} added'**
  String agentAdded(String name);

  /// No description provided for @agentAddFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to add agent: {error}'**
  String agentAddFailed(String error);

  /// No description provided for @agentRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove agent \"{name}\"?'**
  String agentRemoveTitle(String name);

  /// No description provided for @agentRemoveDesc.
  ///
  /// In en, this message translates to:
  /// **'Unregisters the agent and removes its sessions. You can re-add it later.'**
  String get agentRemoveDesc;

  /// No description provided for @agentRemoved.
  ///
  /// In en, this message translates to:
  /// **'Agent {name} removed'**
  String agentRemoved(String name);

  /// No description provided for @agentRemoveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove agent: {error}'**
  String agentRemoveFailed(String error);

  /// No description provided for @agentNoAgents.
  ///
  /// In en, this message translates to:
  /// **'No Agents'**
  String get agentNoAgents;

  /// No description provided for @agentNoAgentsDesc.
  ///
  /// In en, this message translates to:
  /// **'Register an agent to start creating sessions'**
  String get agentNoAgentsDesc;

  /// No description provided for @agentManagerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Manager not found'**
  String get agentManagerNotFound;

  /// No description provided for @agentRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get agentRetry;

  /// No description provided for @agentRemoveTooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove agent'**
  String get agentRemoveTooltip;

  /// No description provided for @agentAddTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add Agent'**
  String get agentAddTooltip;

  /// No description provided for @sessionsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get sessionsFilterAll;

  /// No description provided for @sessionsFilterRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get sessionsFilterRunning;

  /// No description provided for @sessionsFilterExited.
  ///
  /// In en, this message translates to:
  /// **'Exited'**
  String get sessionsFilterExited;

  /// No description provided for @sessionsNewTooltip.
  ///
  /// In en, this message translates to:
  /// **'New Session'**
  String get sessionsNewTooltip;

  /// No description provided for @sessionsKillTitle.
  ///
  /// In en, this message translates to:
  /// **'Kill this session?'**
  String get sessionsKillTitle;

  /// No description provided for @sessionsKillDesc.
  ///
  /// In en, this message translates to:
  /// **'The running process will be terminated and removed from the list.'**
  String get sessionsKillDesc;

  /// No description provided for @sessionsKillBtn.
  ///
  /// In en, this message translates to:
  /// **'Kill'**
  String get sessionsKillBtn;

  /// No description provided for @sessionsDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete session log?'**
  String get sessionsDeleteTitle;

  /// No description provided for @sessionsDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Removes the database row and the on-disk output log. Cannot be undone.'**
  String get sessionsDeleteDesc;

  /// No description provided for @sessionsDeleteBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get sessionsDeleteBtn;

  /// No description provided for @sessionsConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get sessionsConfirm;

  /// No description provided for @sessionsPruneTitle.
  ///
  /// In en, this message translates to:
  /// **'Clean stale sessions?'**
  String get sessionsPruneTitle;

  /// No description provided for @sessionsPruneDesc.
  ///
  /// In en, this message translates to:
  /// **'Drops all sessions that have been inactive for more than 24 hours.'**
  String get sessionsPruneDesc;

  /// No description provided for @sessionsPruneBtn.
  ///
  /// In en, this message translates to:
  /// **'Prune'**
  String get sessionsPruneBtn;

  /// No description provided for @sessionsPruned.
  ///
  /// In en, this message translates to:
  /// **'Pruned {count} session(s)'**
  String sessionsPruned(int count);

  /// No description provided for @sessionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No sessions'**
  String get sessionsEmpty;

  /// No description provided for @sessionsLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get sessionsLoading;

  /// No description provided for @sessionsPinTitle.
  ///
  /// In en, this message translates to:
  /// **'Pin Session'**
  String get sessionsPinTitle;

  /// No description provided for @sessionsPinLabel.
  ///
  /// In en, this message translates to:
  /// **'Display label'**
  String get sessionsPinLabel;

  /// No description provided for @sessionsPinned.
  ///
  /// In en, this message translates to:
  /// **'Session pinned'**
  String get sessionsPinned;

  /// No description provided for @sessionsUnpinned.
  ///
  /// In en, this message translates to:
  /// **'Session unpinned'**
  String get sessionsUnpinned;

  /// No description provided for @sessionsNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get sessionsNotConnected;

  /// No description provided for @sessionsManagerNotFound.
  ///
  /// In en, this message translates to:
  /// **'Manager not found'**
  String get sessionsManagerNotFound;

  /// No description provided for @sessionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} session(s)'**
  String sessionsCount(int count);

  /// No description provided for @sessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Session'**
  String get sessionTitle;

  /// No description provided for @sessionKillTitle.
  ///
  /// In en, this message translates to:
  /// **'Kill this session?'**
  String get sessionKillTitle;

  /// No description provided for @sessionKillDesc.
  ///
  /// In en, this message translates to:
  /// **'The running process will be terminated.'**
  String get sessionKillDesc;

  /// No description provided for @sessionKillBtn.
  ///
  /// In en, this message translates to:
  /// **'Kill'**
  String get sessionKillBtn;

  /// No description provided for @sessionKillFailed.
  ///
  /// In en, this message translates to:
  /// **'Kill failed: {error}'**
  String sessionKillFailed(String error);

  /// No description provided for @sessionDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete session log?'**
  String get sessionDeleteTitle;

  /// No description provided for @sessionDeleteDesc.
  ///
  /// In en, this message translates to:
  /// **'Removes the database row and the on-disk output log. Cannot be undone.'**
  String get sessionDeleteDesc;

  /// No description provided for @sessionDeleteBtn.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get sessionDeleteBtn;

  /// No description provided for @sessionDeleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed: {error}'**
  String sessionDeleteFailed(String error);

  /// No description provided for @sessionKillTooltip.
  ///
  /// In en, this message translates to:
  /// **'Kill session'**
  String get sessionKillTooltip;

  /// No description provided for @sessionDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete session'**
  String get sessionDeleteTooltip;

  /// No description provided for @sessionReconnectTooltip.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get sessionReconnectTooltip;

  /// No description provided for @sessionNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Manager not connected'**
  String get sessionNotConnected;

  /// No description provided for @sessionNotFound.
  ///
  /// In en, this message translates to:
  /// **'Session not found'**
  String get sessionNotFound;

  /// No description provided for @createTitle.
  ///
  /// In en, this message translates to:
  /// **'NEW SESSION'**
  String get createTitle;

  /// No description provided for @createPreset.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get createPreset;

  /// No description provided for @createPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get createPreview;

  /// No description provided for @createCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get createCommand;

  /// No description provided for @createArguments.
  ///
  /// In en, this message translates to:
  /// **'Arguments'**
  String get createArguments;

  /// No description provided for @createOptions.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get createOptions;

  /// No description provided for @createSessionLabel.
  ///
  /// In en, this message translates to:
  /// **'Session label'**
  String get createSessionLabel;

  /// No description provided for @createWorkingDir.
  ///
  /// In en, this message translates to:
  /// **'Working directory'**
  String get createWorkingDir;

  /// No description provided for @createCancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get createCancel;

  /// No description provided for @createLaunch.
  ///
  /// In en, this message translates to:
  /// **'LAUNCH'**
  String get createLaunch;

  /// No description provided for @createSave.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get createSave;

  /// No description provided for @createSaveAsPreset.
  ///
  /// In en, this message translates to:
  /// **'Save as preset'**
  String get createSaveAsPreset;

  /// No description provided for @createPresetName.
  ///
  /// In en, this message translates to:
  /// **'Preset name'**
  String get createPresetName;

  /// No description provided for @createSelectPreset.
  ///
  /// In en, this message translates to:
  /// **'SELECT PRESET'**
  String get createSelectPreset;

  /// No description provided for @createHomeDir.
  ///
  /// In en, this message translates to:
  /// **'Agent home directory'**
  String get createHomeDir;

  /// No description provided for @createAutoLabel.
  ///
  /// In en, this message translates to:
  /// **'Auto-generated if empty'**
  String get createAutoLabel;

  /// No description provided for @createTerminalSizeHint.
  ///
  /// In en, this message translates to:
  /// **'Terminal size auto-matches after session starts'**
  String get createTerminalSizeHint;

  /// No description provided for @createNotConnected.
  ///
  /// In en, this message translates to:
  /// **'Not connected'**
  String get createNotConnected;

  /// No description provided for @createSectionRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get createSectionRecent;

  /// No description provided for @createSectionCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get createSectionCustom;

  /// No description provided for @createArgsHint.
  ///
  /// In en, this message translates to:
  /// **'--no-input  --verbose'**
  String get createArgsHint;

  /// No description provided for @createOptionsCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get createOptionsCancel;

  /// No description provided for @createOptionsApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get createOptionsApply;

  /// No description provided for @pinnedTitle.
  ///
  /// In en, this message translates to:
  /// **'Sessions'**
  String get pinnedTitle;

  /// No description provided for @pinnedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No pinned sessions'**
  String get pinnedEmpty;

  /// No description provided for @pinnedEmptyDesc.
  ///
  /// In en, this message translates to:
  /// **'Click 📌 in agent\'\'s session list\nto pin frequently used sessions here'**
  String get pinnedEmptyDesc;

  /// No description provided for @pinnedUnpinTitle.
  ///
  /// In en, this message translates to:
  /// **'Unpin session?'**
  String get pinnedUnpinTitle;

  /// No description provided for @pinnedUnpinDesc.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{label}\" from pinned sessions?'**
  String pinnedUnpinDesc(String label);

  /// No description provided for @pinnedUnpin.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get pinnedUnpin;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @settingsApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsApp;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get settingsThemeSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageZh.
  ///
  /// In en, this message translates to:
  /// **'中文'**
  String get settingsLanguageZh;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @pinLabel.
  ///
  /// In en, this message translates to:
  /// **'Pin'**
  String get pinLabel;

  /// No description provided for @unpinLabel.
  ///
  /// In en, this message translates to:
  /// **'Unpin'**
  String get unpinLabel;

  /// No description provided for @reconnectLabel.
  ///
  /// In en, this message translates to:
  /// **'Reconnect'**
  String get reconnectLabel;

  /// No description provided for @removeLabel.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get removeLabel;

  /// No description provided for @labelName.
  ///
  /// In en, this message translates to:
  /// **'Label'**
  String get labelName;

  /// No description provided for @labelUrl.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get labelUrl;

  /// No description provided for @labelToken.
  ///
  /// In en, this message translates to:
  /// **'Token'**
  String get labelToken;

  /// No description provided for @labelAgentName.
  ///
  /// In en, this message translates to:
  /// **'Agent Name'**
  String get labelAgentName;

  /// No description provided for @labelAgentUrl.
  ///
  /// In en, this message translates to:
  /// **'Agent URL'**
  String get labelAgentUrl;

  /// No description provided for @labelAgentToken.
  ///
  /// In en, this message translates to:
  /// **'Agent Token'**
  String get labelAgentToken;

  /// No description provided for @statusRunning.
  ///
  /// In en, this message translates to:
  /// **'Running'**
  String get statusRunning;

  /// No description provided for @statusStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting'**
  String get statusStarting;

  /// No description provided for @statusExited.
  ///
  /// In en, this message translates to:
  /// **'Exited'**
  String get statusExited;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
