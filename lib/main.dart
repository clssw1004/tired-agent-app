import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/providers/app_settings_provider.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/providers/pinned_session_provider.dart';
import 'package:tired_agent_app/providers/toast_provider.dart';
import 'package:tired_agent_app/screens/session/create_session_screen.dart';
import 'package:tired_agent_app/screens/server/manager_detail_screen.dart';
import 'package:tired_agent_app/screens/session/pinned_sessions_screen.dart';
import 'package:tired_agent_app/screens/server/server_list_screen.dart';
import 'package:tired_agent_app/screens/session/server_sessions_screen.dart';
import 'package:tired_agent_app/screens/session/session_detail_screen.dart';
import 'package:tired_agent_app/screens/settings/settings_screen.dart';
import 'package:tired_agent_app/screens/settings/terminal_settings_screen.dart';
import 'package:tired_agent_app/screens/settings/theme_settings_screen.dart';
import 'package:tired_agent_app/services/auth_service.dart';
import 'package:tired_agent_app/services/storage_service.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/shell/main_shell.dart';
import 'package:tired_agent_app/enhancements/enhancement.dart';
import 'package:tired_agent_app/enhancements/claude_projects/claude_projects_enhancement.dart';
import 'generated/l10n/app_localizations.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  EnhancementRegistry.register(ClaudeProjectsEnhancement());
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

        // ── Manager detail (full-screen) ─────────────────────────
        GoRoute(
          path: '/profile/:profileId',
          builder: (_, state) => ManagerDetailScreen(
            profileId: state.pathParameters['profileId'] ?? '',
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

        // ── Theme settings (full-screen) ─────────────────────────
        GoRoute(
          path: '/settings/theme',
          builder: (_, _) => const ThemeSettingsScreen(),
          parentNavigatorKey: _rootNavigatorKey,
        ),
      ],
    );

    _authProvider.boot();
    _pinnedSessionProvider.load();
    _settingsProvider.load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 切回前台时，刷新所有 manager 的 session 状态。
      // Confirmed Rotation 确保 refreshToken 在丢响应后仍可用，此处静默恢复即可。
      _authProvider.refreshAllSessions();
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
