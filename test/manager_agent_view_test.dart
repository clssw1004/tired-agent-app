import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tired_agent_app/generated/l10n/app_localizations_en.dart';
import 'package:tired_agent_app/models/manager_connection.dart';
import 'package:tired_agent_app/models/manager_profile.dart';
import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/providers/auth_provider.dart';
import 'package:tired_agent_app/screens/server/manager_agent_view.dart';
import 'package:tired_agent_app/services/auth_service.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/forms/add_agent_form.dart';

final _agentA = AgentInfo(
  id: 'a1',
  name: 'agent-a',
  baseUrl: 'http://a',
  state: AgentState.online,
);
final _agentB = AgentInfo(
  id: 'a2',
  name: 'agent-b',
  baseUrl: 'http://b',
  state: AgentState.offline,
);

/// Scriptable [HttpSseTransport]：只重写 ManagerAgentView 用到的调用。
class FakeHttpSseTransport extends HttpSseTransport {
  FakeHttpSseTransport({List<AgentInfo>? agents})
    : agents = agents ?? [],
      super();

  List<AgentInfo> agents;
  int loginCalls = 0;
  int refreshCalls = 0;
  int addAgentCalls = 0;
  String? lastAddedName;
  bool disposed = false;

  @override
  Future<List<AgentInfo>> listAgents(ServerRef ref) async => List.of(agents);

  @override
  Future<LoginResponse> login(ServerRef ref, String token) async {
    loginCalls++;
    return const LoginResponse(
      sessionToken: 'tok',
      refreshToken: 'rt',
      sessionExpiresIn: 3600,
      refreshExpiresIn: 3600,
    );
  }

  @override
  Future<LoginResponse> refreshSession(
    ServerRef ref,
    String refreshToken,
  ) async {
    refreshCalls++;
    return const LoginResponse(
      sessionToken: 'tok2',
      refreshToken: 'rt2',
      sessionExpiresIn: 3600,
      refreshExpiresIn: 3600,
    );
  }

  @override
  Future<Map<String, dynamic>> addAgent(
    ServerRef ref, {
    required String name,
    required String baseUrl,
    required String token,
  }) async {
    addAgentCalls++;
    lastAddedName = name;
    agents = [
      ...agents,
      AgentInfo(id: 'new-$name', name: name, baseUrl: baseUrl),
    ];
    return <String, dynamic>{};
  }

  @override
  Future<void> deleteAgent(ServerRef ref, String agentId) async {
    agents = agents.where((a) => a.id != agentId).toList();
  }

  @override
  Future<void> updateAgent(
    ServerRef ref,
    String agentId, {
    required String name,
    required String baseUrl,
    String? token,
  }) async {}

  @override
  void dispose() {
    disposed = true;
  }
}

class FakeAuthService extends AuthService {
  FakeAuthService(this._conns);

  final List<ManagerConnection> _conns;

  @override
  List<ManagerConnection> get connections => List.unmodifiable(_conns);

  @override
  ManagerConnection? connectionFor(String profileId) {
    for (final c in _conns) {
      if (c.profile.id == profileId) return c;
    }
    return null;
  }
}

/// 构造一个已注入 transport 的 [ManagerConnection]。
ManagerConnection _conn({
  required String id,
  required String name,
  required FakeHttpSseTransport fake,
  ConnectionStatus status = ConnectionStatus.connected,
  String? error,
  bool fresh = true,
}) {
  final profile = ManagerProfile(
    id: id,
    name: name,
    baseUrl: 'http://$id',
    refreshToken: 'rt',
    sessionToken: 'tok',
    sessionExpiresAtMs: fresh
        ? DateTime.now().millisecondsSinceEpoch + 600000
        : 0,
  );
  final conn = ManagerConnection(profile: profile, transport: fake);
  conn.status = status;
  conn.error = error;
  conn.agents = List.of(fake.agents);
  return conn;
}

/// 桩 GoRouter：ManagerAgentView 为首页，其余 push 记录到 [pushed]。
GoRouter _stubRouter(List<String> pushed) => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const ManagerAgentView()),
    GoRoute(
      path: '/profile/:profileId',
      builder: (context, state) {
        pushed.add('/profile/${state.pathParameters['profileId']}');
        return const Scaffold(body: Text('STUB_DETAIL'));
      },
    ),
    GoRoute(
      path: '/profile/:profileId/add-agent',
      builder: (context, state) {
        pushed.add('add-agent:${state.pathParameters['profileId']}');
        final ctx = context;
        // 首帧后立即带表单结果 pop，驱动添加流程。
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ctx.mounted) {
            Navigator.of(
              ctx,
            ).pop(const AddAgentFormData('a1', 'http://a1', 'tok'));
          }
        });
        return const Scaffold(body: Text('STUB_ADD_AGENT'));
      },
    ),
    GoRoute(
      path: '/profile/:profileId/agent/:agentId',
      builder: (context, state) {
        pushed.add(
          '/profile/${state.pathParameters['profileId']}/agent/${state.pathParameters['agentId']}',
        );
        return const Scaffold(body: Text('STUB_AGENT'));
      },
    ),
  ],
);

Widget _harness({
  required List<ManagerConnection> conns,
  required List<String> pushed,
}) {
  final auth = AuthProvider(authService: FakeAuthService(conns));
  // 复刻生产 _listenToAll：conn 通知转发给 auth，视图才会重建。
  for (final c in conns) {
    c.addListener(auth.notifyListeners);
  }
  return MultiProvider(
    providers: [ChangeNotifierProvider.value(value: auth)],
    child: MaterialApp.router(
      theme: ThemeData(extensions: const [AppColors.dark]),
      routerConfig: _stubRouter(pushed),
    ),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppStrings.init(AppLocalizationsEn('en'));
  });

  testWidgets('分组渲染：名称/状态/数量/agent 与空组提示', (tester) async {
    final fake1 = FakeHttpSseTransport(agents: [_agentA]);
    final fake2 = FakeHttpSseTransport(agents: []);
    final conn1 = _conn(id: 'm1', name: 'Manager1', fake: fake1);
    final conn2 = _conn(id: 'm2', name: 'Manager2', fake: fake2);
    final pushed = <String>[];

    await tester.pumpWidget(_harness(conns: [conn1, conn2], pushed: pushed));
    await tester.pumpAndSettle();

    expect(find.text('Manager1'), findsOneWidget);
    expect(find.text('Manager2'), findsOneWidget);
    expect(find.text('Connected'), findsNWidgets(2));
    expect(find.text('1 agents'), findsOneWidget);
    expect(find.text('agent-a'), findsOneWidget);
    expect(find.text('No Agents'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('点击分组头折叠/展开 agent 列表', (tester) async {
    final fake = FakeHttpSseTransport(agents: [_agentA]);
    final conn = _conn(id: 'm1', name: 'Manager1', fake: fake);
    final pushed = <String>[];

    await tester.pumpWidget(_harness(conns: [conn], pushed: pushed));
    await tester.pumpAndSettle();
    expect(find.text('agent-a'), findsOneWidget);

    await tester.tap(find.text('Manager1'));
    await tester.pumpAndSettle();
    expect(find.text('agent-a'), findsNothing);

    await tester.tap(find.text('Manager1'));
    await tester.pumpAndSettle();
    expect(find.text('agent-a'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('未连接分组显示错误 + Retry，点击后重连成功', (tester) async {
    final fake = FakeHttpSseTransport(agents: [_agentA]);
    final conn = _conn(
      id: 'm1',
      name: 'Manager1',
      fake: fake,
      status: ConnectionStatus.idle,
      error: 'boom',
      fresh: false,
    );
    final pushed = <String>[];

    await tester.pumpWidget(_harness(conns: [conn], pushed: pushed));
    await tester.pumpAndSettle();

    expect(find.text('boom'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(conn.status, ConnectionStatus.connected);
    expect(fake.refreshCalls, 1);
    expect(find.text('agent-a'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('5s 轮询拉取到新增 agent', (tester) async {
    final fake = FakeHttpSseTransport(agents: [_agentA]);
    final conn = _conn(id: 'm1', name: 'Manager1', fake: fake);
    final pushed = <String>[];

    await tester.pumpWidget(_harness(conns: [conn], pushed: pushed));
    await tester.pumpAndSettle();
    expect(find.text('agent-b'), findsNothing);

    fake.agents = [_agentA, _agentB];
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('agent-b'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('＋agent 走添加流程并刷新列表', (tester) async {
    final fake = FakeHttpSseTransport(agents: [_agentA]);
    final conn = _conn(id: 'm1', name: 'Manager1', fake: fake);
    final pushed = <String>[];

    await tester.pumpWidget(_harness(conns: [conn], pushed: pushed));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(pushed, contains('add-agent:m1'));
    expect(fake.addAgentCalls, 1);
    expect(fake.lastAddedName, 'a1');
    expect(find.text('a1'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('详情→ 进入 manager 详情', (tester) async {
    final fake = FakeHttpSseTransport(agents: [_agentA]);
    final conn = _conn(id: 'm1', name: 'Manager1', fake: fake);
    final pushed = <String>[];

    await tester.pumpWidget(_harness(conns: [conn], pushed: pushed));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();

    expect(pushed, contains('/profile/m1'));

    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('agent 行点击进入该 agent 的 session 列表', (tester) async {
    final fake = FakeHttpSseTransport(agents: [_agentA]);
    final conn = _conn(id: 'm1', name: 'Manager1', fake: fake);
    final pushed = <String>[];

    await tester.pumpWidget(_harness(conns: [conn], pushed: pushed));
    await tester.pumpAndSettle();

    await tester.tap(find.text('agent-a'));
    await tester.pumpAndSettle();

    expect(pushed, contains('/profile/m1/agent/a1'));

    await tester.pumpWidget(const SizedBox());
  });
}
