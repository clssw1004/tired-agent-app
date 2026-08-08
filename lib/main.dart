import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/providers/pinned_session_provider.dart';
import 'package:tired_agent_app/providers/pty_keyboard_scheme_provider.dart';
import 'package:tired_agent_app/providers/toast_provider.dart';
import 'package:tired_agent_app/screens/session/create_session_screen.dart';
import 'package:tired_agent_app/screens/server/add_agent_screen.dart';
import 'package:tired_agent_app/screens/server/add_manager_screen.dart';
import 'package:tired_agent_app/screens/session/pinned_sessions_screen.dart';
import 'package:tired_agent_app/screens/server/server_list_screen.dart';
import 'package:tired_agent_app/screens/session/server_sessions_screen.dart';
import 'package:tired_agent_app/screens/session/session_detail_screen.dart';
import 'package:tired_agent_app/screens/settings/about_settings_screen.dart';
import 'package:tired_agent_app/screens/settings/appearance_settings_screen.dart';
import 'package:tired_agent_app/screens/settings/settings_screen.dart';
import 'package:tired_agent_app/screens/settings/terminal_settings_screen.dart';
import 'package:tired_agent_app/screens/settings/keyboard_scheme_list_screen.dart';
import 'package:tired_agent_app/screens/settings/keyboard_scheme_editor_screen.dart';
import 'package:tired_agent_app/services/auth_service.dart';
import 'package:tired_agent_app/services/session_exit_notifier.dart';
import 'package:tired_agent_app/services/storage_service.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/shell/main_shell.dart';
import 'generated/l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TiredAgentApp());
}

class TiredAgentApp extends StatefulWidget {
  const TiredAgentApp({super.key});

  @override
  State<TiredAgentApp> createState() => _TiredAgentAppState();
}

class _TiredAgentAppState extends State<TiredAgentApp>
    with WidgetsBindingObserver {
  late final AuthService _authService;
  late final AuthProvider _authProvider;
  late final PinnedSessionProvider _pinnedSessionProvider;
  late final ToastProvider _toastProvider;
  late final AppSettingsProvider _settingsProvider;
  late final PtyKeyboardSchemeProvider _keyboardSchemeProvider;
  late final SessionExitNotifier _sessionExitNotifier;
  late final GoRouter _router;
  final _rootNavigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final storage = StorageService();
    _authService = AuthService(storage: storage);
    _authProvider = AuthProvider(authService: _authService);
    _pinnedSessionProvider = PinnedSessionProvider();
    _toastProvider = ToastProvider();
    _settingsProvider = AppSettingsProvider();
    _keyboardSchemeProvider = PtyKeyboardSchemeProvider();
    _sessionExitNotifier = SessionExitNotifier();
    _sessionExitNotifier
        .init(
          authService: _authService,
          isEnabled: () => _settingsProvider.sessionExitNotifications,
          onTap: _openSessionFromNotification,
        )
        .then((_) => _handleNotificationLaunch());

    _router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      refreshListenable: _authProvider,
      routes: [
        // ── Main shell with bottom tabs ──────────────────────────
        StatefulShellRoute.indexedStack(
          builder: (_, _, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            // Tab 0: Managers — multi-manager list
            StatefulShellBranch(
              routes: [
                GoRoute(path: '/', builder: (_, _) => const ServerListScreen()),
              ],
            ),
            // Tab 1: Sessions — pinned sessions
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/sessions',
                  builder: (_, _) => const PinnedSessionsScreen(),
                ),
              ],
            ),
            // Tab 2: Settings
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/settings',
                  builder: (_, _) => const SettingsScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Add Manager (full-screen form) ────────────────────────
        GoRoute(
          path: '/add-manager',
          builder: (_, state) => AddManagerScreen(
            initialName: state.extra is String ? state.extra as String : '',
          ),
          parentNavigatorKey: _rootNavigatorKey,
        ),

        // ── Add / Edit Agent (full-screen form) ───────────────────
        GoRoute(
          path: '/profile/:profileId/add-agent',
          builder: (_, state) => AddAgentScreen(
            profileId: state.pathParameters['profileId'] ?? '',
            args: state.extra is AddAgentPageArgs
                ? state.extra as AddAgentPageArgs
                : const AddAgentPageArgs(),
          ),
          parentNavigatorKey: _rootNavigatorKey,
        ),
        // ── Agent sessions (full-screen, no tabs) ────────────────
        GoRoute(
          path: '/profile/:profileId/agent/:agentId',
          builder: (_, state) => ServerSessionsScreen(
            profileId: state.pathParameters['profileId'] ?? '',
            agentId: state.pathParameters['agentId'] ?? '',
          ),
          parentNavigatorKey: _rootNavigatorKey,
        ),
        GoRoute(
          path: '/profile/:profileId/agent/:agentId/create',
          builder: (_, state) => CreateSessionScreen(
            profileId: state.pathParameters['profileId'] ?? '',
            agentId: state.pathParameters['agentId'] ?? '',
          ),
          parentNavigatorKey: _rootNavigatorKey,
        ),

        // ── Session detail (full-screen) ─────────────────────────
        GoRoute(
          path: '/session/:profileId/:agentId/:sessionId',
          builder: (_, state) => SessionDetailScreen(
            profileId: state.pathParameters['profileId'] ?? '',
            agentId: state.pathParameters['agentId'] ?? '',
            sessionId: state.pathParameters['sessionId'] ?? '',
          ),
          parentNavigatorKey: _rootNavigatorKey,
        ),

        // ── Terminal settings (full-screen) ──────────────────────
        GoRoute(
          path: '/settings/terminal',
          builder: (_, _) => const TerminalSettingsScreen(),
          parentNavigatorKey: _rootNavigatorKey,
        ),

        // ── Appearance settings (full-screen) ────────────────────
        GoRoute(
          path: '/settings/appearance',
          builder: (_, _) => const AppearanceSettingsScreen(),
          parentNavigatorKey: _rootNavigatorKey,
        ),

        // ── About (full-screen) ───────────────────────────────────
        GoRoute(
          path: '/settings/about',
          builder: (_, _) => const AboutSettingsScreen(),
          parentNavigatorKey: _rootNavigatorKey,
        ),

        // ── Keyboard scheme manager (full-screen) ────────────────
        GoRoute(
          path: '/settings/keyboard',
          builder: (_, _) => const KeyboardSchemeListScreen(),
          parentNavigatorKey: _rootNavigatorKey,
        ),
        GoRoute(
          path: '/settings/keyboard/new',
          builder: (_, state) => KeyboardSchemeEditorScreen(
            basePreset: state.uri.queryParameters['base'],
          ),
          parentNavigatorKey: _rootNavigatorKey,
        ),
        GoRoute(
          path: '/settings/keyboard/:schemeId',
          builder: (_, state) => KeyboardSchemeEditorScreen(
            schemeId: state.pathParameters['schemeId'],
          ),
          parentNavigatorKey: _rootNavigatorKey,
        ),
      ],
    );

    _authProvider.boot().whenComplete(() {
      // 轮询在连接建立后再启动。
      _sessionExitNotifier.startWatching();
    });
    _pinnedSessionProvider.load();
    _settingsProvider.load();
    _keyboardSchemeProvider.load();
  }

  /// 通知点击 / 冷启动跳转到对应会话详情页。
  void _openSessionFromNotification(SessionRef ref) {
    final navContext = _rootNavigatorKey.currentContext;
    if (navContext == null) return;
    navContext.push(
      '/session/${ref.profileId}/${ref.agentId}/${ref.sessionId}',
    );
  }

  /// 处理从通知冷启动 app 的跳转。
  Future<void> _handleNotificationLaunch() async {
    final ref = await _sessionExitNotifier.takeLaunchRef();
    if (ref == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openSessionFromNotification(ref);
    });
  }

  @override
  void dispose() {
    _sessionExitNotifier.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // 切回前台时，刷新所有 manager 的 session 状态。
        // Confirmed Rotation 确保 refreshToken 在丢响应后仍可用，此处静默恢复即可。
        _authProvider.refreshAllSessions();
        // 会话退出通知：回前台立即查一次 + 恢复轮询。
        _sessionExitNotifier.resumeCheck();
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.inactive:
        // 后台暂停轮询省电。
        _sessionExitNotifier.pauseWatching();
      case AppLifecycleState.detached:
        _sessionExitNotifier.pauseWatching();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _pinnedSessionProvider),
        ChangeNotifierProvider.value(value: _toastProvider),
        ChangeNotifierProvider.value(value: _settingsProvider),
        ChangeNotifierProvider.value(value: _keyboardSchemeProvider),
        Provider<SessionExitNotifier>.value(value: _sessionExitNotifier),
      ],
      child: Consumer<AppSettingsProvider>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            title: 'TiredAgent',
            theme: switch (settings.themeFlavor) {
              ThemeFlavor.geek => buildGeekLightTheme(),
              ThemeFlavor.material => buildMd3LightTheme(),
              _ => buildNeonLightTheme(),
            },
            darkTheme: switch (settings.themeFlavor) {
              ThemeFlavor.geek => buildGeekDarkTheme(),
              ThemeFlavor.material => buildMd3DarkTheme(),
              _ => buildNeonDarkTheme(),
            },
            themeMode: settings.themeMode,
            locale: settings.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              // 初始化全局 i18n 工具（context 在 Localizations widget 之下）
              AppStrings.init(AppLocalizations.of(context)!);
              return child!;
            },
          );
        },
      ),
    );
  }
}
