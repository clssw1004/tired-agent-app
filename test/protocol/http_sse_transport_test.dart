import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/types.dart';

ServerRef _ref(HttpServer server, {String token = 'tok'}) => ServerRef(
  id: 'a',
  name: 'a',
  baseUrl: 'http://127.0.0.1:${server.port}',
  token: token,
);

Map<String, dynamic> _sessionJson({
  String id = 's1',
  String status = 'running',
}) => {
  'id': id,
  'cmd': 'bash',
  'args': <String>[],
  'status': status,
  'createdAt': 1,
  'byteOffset': 0,
  'cols': 80,
  'rows': 24,
};

String _sseOutput(int offset, String data) =>
    'event: output\ndata: ${jsonEncode({'offset': offset, 'data': base64.encode(utf8.encode(data))})}\n\n';

String _sseState(Map<String, dynamic> session) =>
    'event: state\ndata: ${jsonEncode(session)}\n\n';

String _sseHeartbeat() =>
    'event: heartbeat\ndata: ${jsonEncode({'ts': 1})}\n\n';

Future<HttpServer> _startServer(
  FutureOr<void> Function(HttpRequest req) handler,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  server.listen((req) {
    // fire-and-forget so the handler's async work doesn't block the socket.
    Future.sync(() => handler(req)).catchError((e) {
      req.response.statusCode = 500;
      req.response.write('handler error: $e');
      req.response.close();
    });
  });
  return server;
}

Future<void> _waitUntil(
  bool Function() cond, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!cond()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('condition not met within $timeout');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  test('listSessions parses the JSON list response', () async {
    final server = await _startServer((req) {
      expect(req.method, 'GET');
      expect(req.uri.path, '/api/v1/sessions');
      req.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode([_sessionJson(id: 's1')]))
        ..close();
    });
    final transport = HttpSseTransport();
    final sessions = await transport.listSessions(_ref(server));
    expect(sessions, hasLength(1));
    expect(sessions.single.id, 's1');
    await server.close();
  });

  test('createSession posts the spec and parses the created session', () async {
    final server = await _startServer((req) async {
      expect(req.method, 'POST');
      expect(req.uri.path, '/api/v1/agents/agt1/sessions');
      final body = jsonDecode(await utf8.decoder.bind(req).join()) as Map;
      expect(body['cmd'], 'bash');
      req.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(_sessionJson(id: 's9')))
        ..close();
    });
    final transport = HttpSseTransport();
    final session = await transport.createSession(
      _ref(server),
      const SessionSpec(cmd: 'bash'),
      agentId: 'agt1',
    );
    expect(session.id, 's9');
    await server.close();
  });

  test('fetchOutput passes tail and parses chunks', () async {
    final server = await _startServer((req) {
      expect(req.uri.queryParameters['tail'], '1048576');
      final data = base64.encode(utf8.encode('hi'));
      req.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'chunks': [
              {'offset': 0, 'data': data},
            ],
            'upTo': 2,
          }),
        )
        ..close();
    });
    final transport = HttpSseTransport();
    final result = await transport.fetchOutput(
      _ref(server),
      's1',
      tail: 1048576,
    );
    expect(result.chunks.single.offset, 0);
    expect(utf8.decode(base64.decode(result.chunks.single.data)), 'hi');
    expect(result.upTo, 2);
    await server.close();
  });

  test(
    'subscribe parses output/state/heartbeat and reports onConnected',
    () async {
      final server = await _startServer((req) async {
        req.response
          ..headers.contentType = ContentType('text', 'event-stream')
          ..write(_sseOutput(0, 'hello'))
          ..write(_sseState(_sessionJson()))
          ..write(_sseHeartbeat())
          ..close();
      });
      final transport = HttpSseTransport();
      final chunks = <OutputChunk>[];
      final states = <Session>[];
      final heartbeats = <int>[];
      final statuses = <String>[];
      final errors = <Object>[];
      final sub = transport.subscribe(
        _ref(server),
        's1',
        SubscribeHandlers(
          onChunk: chunks.add,
          onState: states.add,
          onError: errors.add,
          onHeartbeat: () => heartbeats.add(1),
          onConnected: () => statuses.add('connected'),
          onReconnecting: () => statuses.add('reconnecting'),
        ),
      );
      await _waitUntil(() => chunks.isNotEmpty && states.isNotEmpty);
      expect(utf8.decode(chunks.single.data), 'hello');
      expect(states.single.id, 's1');
      expect(heartbeats, hasLength(1));
      expect(statuses, contains('connected'));
      expect(errors, isEmpty);
      sub.close();
      await server.close();
    },
  );

  test(
    'auto-reconnects after the stream closes, firing status callbacks',
    () async {
      var requests = 0;
      final server = await _startServer((req) async {
        requests++;
        req.response
          ..headers.contentType = ContentType('text', 'event-stream')
          ..write(_sseOutput(0, 'hello'))
          ..close();
      });
      final transport = HttpSseTransport(retryBaseDelayMs: 10);
      final statuses = <String>[];
      final sub = transport.subscribe(
        _ref(server),
        's1',
        SubscribeHandlers(
          onChunk: (_) {},
          onState: (_) {},
          onError: (_) {},
          onConnected: () => statuses.add('connected'),
          onReconnecting: () => statuses.add('reconnecting'),
        ),
      );
      await _waitUntil(
        () => statuses.where((s) => s == 'connected').length >= 2,
      );
      expect(requests, greaterThanOrEqualTo(2));
      expect(statuses, contains('reconnecting'));
      expect(
        statuses.where((s) => s == 'connected').length,
        greaterThanOrEqualTo(2),
      );
      sub.close();
      await server.close();
    },
  );

  test('404 NOT_FOUND → SessionNotFoundException, no reconnect', () async {
    var requests = 0;
    final server = await _startServer((req) {
      requests++;
      req.response
        ..statusCode = 404
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'error': {'code': 'NOT_FOUND', 'message': 'gone'},
          }),
        )
        ..close();
    });
    final transport = HttpSseTransport(retryBaseDelayMs: 10);
    final errors = <Object>[];
    final statuses = <String>[];
    final sub = transport.subscribe(
      _ref(server),
      's1',
      SubscribeHandlers(
        onChunk: (_) {},
        onState: (_) {},
        onError: errors.add,
        onConnected: () => statuses.add('connected'),
        onReconnecting: () => statuses.add('reconnecting'),
      ),
    );
    await _waitUntil(() => errors.isNotEmpty);
    expect(errors.single, isA<SessionNotFoundException>());
    expect(statuses, isNot(contains('reconnecting')));
    // Give any (wrong) reconnect timer a chance to fire.
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(requests, 1);
    sub.close();
    await server.close();
  });

  test('401 → onError with statusCode 401, no reconnect', () async {
    var requests = 0;
    final server = await _startServer((req) {
      requests++;
      req.response
        ..statusCode = 401
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'error': {'code': 'UNAUTHORIZED', 'message': 'bad token'},
          }),
        )
        ..close();
    });
    final transport = HttpSseTransport(retryBaseDelayMs: 10);
    final errors = <Object>[];
    final statuses = <String>[];
    final sub = transport.subscribe(
      _ref(server),
      's1',
      SubscribeHandlers(
        onChunk: (_) {},
        onState: (_) {},
        onError: errors.add,
        onConnected: () => statuses.add('connected'),
        onReconnecting: () => statuses.add('reconnecting'),
      ),
    );
    await _waitUntil(() => errors.isNotEmpty);
    final e = errors.single as TransportException;
    expect(e.statusCode, 401);
    expect(statuses, isNot(contains('reconnecting')));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(requests, 1);
    sub.close();
    await server.close();
  });

  test('non-2xx (500) → onError then auto-reconnect succeeds', () async {
    var requests = 0;
    final server = await _startServer((req) async {
      requests++;
      if (requests == 1) {
        req.response
          ..statusCode = 500
          ..headers.contentType = ContentType.json
          ..write(
            jsonEncode({
              'error': {'code': 'INTERNAL', 'message': 'boom'},
            }),
          )
          ..close();
        return;
      }
      req.response
        ..headers.contentType = ContentType('text', 'event-stream')
        ..write(_sseHeartbeat())
        ..close();
    });
    final transport = HttpSseTransport(retryBaseDelayMs: 10);
    final errors = <Object>[];
    final statuses = <String>[];
    final sub = transport.subscribe(
      _ref(server),
      's1',
      SubscribeHandlers(
        onChunk: (_) {},
        onState: (_) {},
        onError: errors.add,
        onConnected: () => statuses.add('connected'),
        onReconnecting: () => statuses.add('reconnecting'),
      ),
    );
    await _waitUntil(() => requests >= 2 && statuses.contains('connected'));
    expect(requests, greaterThanOrEqualTo(2));
    expect(
      errors.whereType<TransportException>().any((e) => e.statusCode == 500),
      isTrue,
    );
    expect(statuses, contains('reconnecting'));
    sub.close();
    await server.close();
  });

  test('resubscribe continues from the current byte offset', () async {
    var requests = 0;
    final fromParams = <String?>[];
    final server = await _startServer((req) {
      requests++;
      fromParams.add(req.uri.queryParameters['from']);
      req.response
        ..headers.contentType = ContentType('text', 'event-stream')
        ..write(_sseOutput(0, 'hello'))
        ..close();
    });
    final transport = HttpSseTransport(retryBaseDelayMs: 10);
    final chunks = <OutputChunk>[];
    final sub = transport.subscribe(
      _ref(server),
      's1',
      SubscribeHandlers(onChunk: chunks.add, onState: (_) {}, onError: (_) {}),
    );
    await _waitUntil(() => chunks.isNotEmpty);
    expect(fromParams[0], isNull); // fromOffset 0 → no `from` param
    sub.resubscribe?.call();
    await _waitUntil(() => requests >= 2);
    expect(fromParams[1], '5'); // 5 bytes consumed → resume at 5
    sub.close();
    await server.close();
  });

  test(
    'resubscribe while connected does not schedule a spurious reconnect',
    () async {
      var requests = 0;
      final server = await _startServer((req) async {
        requests++;
        req.response
          ..headers.contentType = ContentType('text', 'event-stream')
          ..write(_sseHeartbeat());
        await req.response.flush();
        // keep the connection open; never close.
      });
      final transport = HttpSseTransport(retryBaseDelayMs: 10);
      final statuses = <String>[];
      final sub = transport.subscribe(
        _ref(server),
        's1',
        SubscribeHandlers(
          onChunk: (_) {},
          onState: (_) {},
          onError: (_) {},
          onConnected: () => statuses.add('connected'),
          onReconnecting: () => statuses.add('reconnecting'),
        ),
      );
      await _waitUntil(() => requests >= 1 && statuses.contains('connected'));
      // Manual reconnect while the current stream is alive.
      sub.resubscribe?.call();
      await _waitUntil(
        () =>
            requests >= 2 &&
            statuses.where((s) => s == 'connected').length >= 2,
      );
      // Give any (wrong) reconnect timer a chance to fire.
      await Future<void>.delayed(const Duration(milliseconds: 200));
      // Only the explicit resubscribe — the cancelled stream must not schedule
      // an extra reconnect, or the page would flicker connected↔reconnecting.
      expect(requests, 2);
      expect(statuses, isNot(contains('reconnecting')));
      sub.close();
      await server.close(force: true);
    },
  );

  test('dispose closes active subscriptions', () async {
    var requests = 0;
    final server = await _startServer((req) async {
      requests++;
      req.response
        ..headers.contentType = ContentType('text', 'event-stream')
        ..write(_sseHeartbeat());
      await req.response.flush();
      // keep the connection open; never close.
    });
    final transport = HttpSseTransport(retryBaseDelayMs: 10);
    final sub = transport.subscribe(
      _ref(server),
      's1',
      SubscribeHandlers(onChunk: (_) {}, onState: (_) {}, onError: (_) {}),
    );
    await _waitUntil(() => requests >= 1);
    transport.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(requests, 1);
    sub.close();
    await server.close(force: true);
  });

  // ── Connection probe (testAgentConnection) ────────────────────────────

  test(
    'testAgentConnection returns name/version when /health and /sessions both 200',
    () async {
      final server = await _startServer((req) async {
        if (req.uri.path == '/health') {
          req.response
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'status': 'ok',
                'name': 'web-01',
                'port': 3100,
                'ts': 1,
                'version': '1.2.3',
                'uptime': 42,
                'platform': {'os': 'linux', 'arch': 'x64', 'release': '6.0'},
              }),
            )
            ..close();
          return;
        }
        if (req.uri.path == '/api/v1/sessions') {
          // Token must ride along as a Bearer header for the probe to count.
          // `req.headers[name]` returns `List<String>` in Dart's HttpServer —
          // collapse to a single string before asserting.
          final auth = req.headers['authorization']?.join(' ') ?? '';
          expect(auth, 'Bearer probetok');
          req.response
            ..headers.contentType = ContentType.json
            ..write('[]')
            ..close();
          return;
        }
        req.response.statusCode = 404;
        req.response.close();
      });
      final transport = HttpSseTransport();
      final result = await transport.testAgentConnection(
        'http://127.0.0.1:${server.port}',
        'probetok',
      );
      expect(result.ok, isTrue);
      expect(result.name, 'web-01');
      expect(result.version, '1.2.3');
      expect(result.error, isNull);
      await server.close();
    },
  );

  test(
    'testAgentConnection fails with http:401 prefix when token is rejected',
    () async {
      final server = await _startServer((req) async {
        if (req.uri.path == '/health') {
          req.response
            ..headers.contentType = ContentType.json
            ..write(jsonEncode({'status': 'ok', 'name': 'a', 'version': '0'}))
            ..close();
          return;
        }
        if (req.uri.path == '/api/v1/sessions') {
          req.response
            ..statusCode = 401
            ..headers.contentType = ContentType.json
            ..write(
              jsonEncode({
                'error': {'code': 'FORBIDDEN', 'message': 'Invalid token'},
              }),
            )
            ..close();
          return;
        }
        req.response.statusCode = 404;
        req.response.close();
      });
      final transport = HttpSseTransport();
      final result = await transport.testAgentConnection(
        'http://127.0.0.1:${server.port}',
        'wrong',
      );
      expect(result.ok, isFalse);
      expect(result.name, isNull);
      expect(result.version, isNull);
      expect(result.error, startsWith('http:401:'));
      await server.close();
    },
  );

  test(
    'testAgentConnection fails with network: prefix when host is unreachable',
    () async {
      // Bind+close to grab a port we know is now free, then point the probe
      // at it — connection refused is what we're after.
      final probe = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final port = probe.port;
      await probe.close();
      final transport = HttpSseTransport();
      final result = await transport.testAgentConnection(
        'http://127.0.0.1:$port',
        'tok',
      );
      expect(result.ok, isFalse);
      expect(result.error, startsWith('network:'));
    },
  );

  test(
    'testAgentConnection tolerates non-JSON /health and still validates token',
    () async {
      final server = await _startServer((req) async {
        if (req.uri.path == '/health') {
          // Some misconfigured host returns plain text. The probe should not
          // explode — name/version simply stay null, and we move on to the
          // token check.
          req.response
            ..headers.contentType = ContentType.text
            ..write('ok')
            ..close();
          return;
        }
        if (req.uri.path == '/api/v1/sessions') {
          req.response
            ..headers.contentType = ContentType.json
            ..write('[]')
            ..close();
          return;
        }
        req.response.statusCode = 404;
        req.response.close();
      });
      final transport = HttpSseTransport();
      final result = await transport.testAgentConnection(
        'http://127.0.0.1:${server.port}',
        'tok',
      );
      expect(result.ok, isTrue);
      expect(result.name, isNull);
      expect(result.version, isNull);
      await server.close();
    },
  );
}
