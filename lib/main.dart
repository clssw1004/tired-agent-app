import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/providers/server_provider.dart';
import 'package:tired_agent_app/providers/toast_provider.dart';
import 'package:tired_agent_app/screens/create_session_screen.dart';
import 'package:tired_agent_app/screens/server_list_screen.dart';
import 'package:tired_agent_app/screens/server_add_screen.dart';
import 'package:tired_agent_app/screens/server_sessions_screen.dart';
import 'package:tired_agent_app/screens/session_detail_screen.dart';
import 'package:tired_agent_app/screens/settings_screen.dart';
import 'package:tired_agent_app/services/auth_service.dart';
import 'package:tired_agent_app/services/storage_service.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/widgets/main_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TiredAgentApp());
}

class TiredAgentApp extends StatefulWidget {
  const TiredAgentApp({super.key});

  @override
  State<TiredAgentApp> createState() => _TiredAgentAppState();
}

class _TiredAgentAppState extends State<TiredAgentApp> {
  late final AuthService _authService;
  late final AuthProvider _authProvider;
  late final ServerProvider _serverProvider;
  late final ToastProvider _toastProvider;
  late final GoRouter _router;
  final _rootNavigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    final storage = StorageService();
    _authService = AuthService(storage: storage);
    _authProvider = AuthProvider(authService: _authService);
    _serverProvider = ServerProvider(_authService);
    _toastProvider = ToastProvider();

    _router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      // Re-evaluate redirects when auth state changes
      refreshListenable: _authProvider,
      routes: [
        // ── Main shell with bottom tabs ───────────────────────────
        StatefulShellRoute.indexedStack(
          builder: (_, _, navigationShell) =>
              MainShell(navigationShell: navigationShell),
          branches: [
            // Tab 0: Servers
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (_, _) => const ServerListScreen(),
                ),
                GoRoute(
                  path: '/server/new',
                  builder: (_, _) => const ServerAddScreen(),
                ),
                GoRoute(
                  path: '/server/:id',
                  builder: (_, state) => ServerSessionsScreen(
                    serverId: state.pathParameters['id'] ?? '',
                  ),
                ),
              ],
            ),
            // Tab 1: Settings
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

        // ── Full-screen routes (no tabs) ──────────────────────────
        GoRoute(
          path: '/session/:serverId/:sessionId',
          builder: (_, state) => SessionDetailScreen(
            serverId: state.pathParameters['serverId'] ?? '',
            sessionId: state.pathParameters['sessionId'] ?? '',
          ),
          parentNavigatorKey: _rootNavigatorKey,
        ),
        GoRoute(
          path: '/server/:id/create-session',
          builder: (_, state) =>
              CreateSessionScreen(serverId: state.pathParameters['id'] ?? ''),
          parentNavigatorKey: _rootNavigatorKey,
        ),
      ],
    );

    _authProvider.boot();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _serverProvider),
        ChangeNotifierProvider.value(value: _toastProvider),
      ],
      child: MaterialApp.router(
        title: 'tiredAgentMobile',
        theme: buildDarkTheme(),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
