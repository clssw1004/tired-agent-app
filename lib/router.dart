import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/screens/login_screen.dart';
import 'package:tired_agent_app/screens/server_list_screen.dart';
import 'package:tired_agent_app/screens/server_add_screen.dart';
import 'package:tired_agent_app/screens/server_sessions_screen.dart';
import 'package:tired_agent_app/screens/session_detail_screen.dart';

GoRouter createRouter(BuildContext context) {
  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final auth = context.read<AuthProvider>();
      final isLoggedIn = auth.status == AuthStatus.authenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginRoute) return '/login';
      if (isLoggedIn && isLoginRoute) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(path: '/', builder: (_, _) => const ServerListScreen()),
      GoRoute(
        path: '/server/new',
        builder: (_, _) => const ServerAddScreen(),
      ),
      GoRoute(
        path: '/server/:id',
        builder: (_, state) =>
            ServerSessionsScreen(serverId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/session/:serverId-:sessionId',
        builder: (_, state) => SessionDetailScreen(
          serverId: state.pathParameters['serverId'] ?? '',
          sessionId: state.pathParameters['sessionId'] ?? '',
        ),
      ),
    ],
  );
}
