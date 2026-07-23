import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/providers/server_provider.dart';
import 'package:tired_agent_app/providers/toast_provider.dart';
import 'package:tired_agent_app/router.dart';
import 'package:tired_agent_app/services/auth_service.dart';
import 'package:tired_agent_app/services/storage_service.dart';
import 'package:tired_agent_app/theme.dart';

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

  @override
  void initState() {
    super.initState();
    final storage = StorageService();
    _authService = AuthService(storage: storage);
    _authProvider = AuthProvider(authService: _authService);
    _serverProvider = ServerProvider(_authService);
    _toastProvider = ToastProvider();
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
        routerConfig: createRouter(context),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
