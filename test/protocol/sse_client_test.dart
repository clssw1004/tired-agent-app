import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:tired_agent_app/protocol/sse_client.dart';
import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/types.dart';

final _ref = ServerRef(
  id: 'a',
  name: 'a',
  baseUrl: 'http://127.0.0.1:9999',
  token: 'tok',
);

Session _session({String status = 'running'}) => Session(
  id: 's1',
  cmd: 'bash',
  args: const [],
  status: switch (status) {
    'exited' => SessionStatus.exited,
    _ => SessionStatus.running,
  },
  createdAt: 1,
  byteOffset: 0,
  cols: 80,
  rows: 24,
);

/// Scriptable [Transport] for SseClient unit tests.
class FakeTransport implements Transport {
  Object? fetchOutputError;
  FetchOutputResult fetchOutputResult = const FetchOutputResult(
    chunks: [],
    upTo: 0,
  );

  int subscribeCalls = 0;
  int resubscribeCalls = 0;
  final List<int> subscribeOffsets = [];
  SubscribeHandlers? lastHandlers;
  bool disposed = false;

  @override
  Future<FetchOutputResult> fetchOutput(
    ServerRef ref,
    String id, {
    int fromOffset = 0,
    int? limit,
    String? agentId,
    int? tail,
  }) async {
    if (fetchOutputError != null) throw fetchOutputError!;
    return fetchOutputResult;
  }

  @override
  Subscription subscribe(
    ServerRef ref,
    String id,
    SubscribeHandlers handlers, {
    String? agentId,
    int fromOffset = 0,
  }) {
    subscribeCalls++;
    subscribeOffsets.add(fromOffset);
    lastHandlers = handlers;
    return Subscription(
      close: () {},
      resubscribe: () {
        resubscribeCalls++;
        lastHandlers = handlers;
      },
    );
  }

  @override
  void dispose() {
    disposed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

void main() {
  test('start replays history then subscribes from result.upTo', () async {
    final fake = FakeTransport()
      ..fetchOutputResult = const FetchOutputResult(
        chunks: [
          OutputChunkJson(offset: 0, data: 'aGk='), // "hi" base64
        ],
        upTo: 2,
      );
    final client = SseClient(transport: fake, ref: _ref, sessionId: 's1');
    final chunks = <OutputChunk>[];
    client.onChunk = chunks.add;

    await client.start();

    expect(utf8.decode(chunks.single.data), 'hi');
    expect(fake.subscribeOffsets, [2]);
  });

  test('start with tail=0 skips history', () async {
    final fake = FakeTransport();
    final client = SseClient(transport: fake, ref: _ref, sessionId: 's1');
    await client.start(tail: 0);
    expect(fake.subscribeOffsets, [0]);
  });

  test('fetchOutput SessionNotFoundException → exited, no subscribe', () async {
    final fake = FakeTransport()
      ..fetchOutputError = SessionNotFoundException('NOT_FOUND');
    final client = SseClient(transport: fake, ref: _ref, sessionId: 's1');
    final errors = <Object>[];
    client.onError = errors.add;

    await client.start();

    expect(client.sessionExited, isTrue);
    expect(client.status, SseConnectionStatus.disconnected);
    expect(fake.subscribeCalls, 0);
    expect(errors.single, isA<SessionNotFoundException>());
  });

  test('fetchOutput generic error → onError but still subscribes', () async {
    final fake = FakeTransport()..fetchOutputError = Exception('network');
    final client = SseClient(transport: fake, ref: _ref, sessionId: 's1');
    final errors = <Object>[];
    client.onError = errors.add;

    await client.start();

    expect(errors, hasLength(1));
    expect(fake.subscribeCalls, 1);
  });

  test('reconnect calls resubscribe, not a fresh subscribe', () async {
    final fake = FakeTransport();
    final client = SseClient(transport: fake, ref: _ref, sessionId: 's1');
    await client.start();

    client.reconnect();

    expect(fake.resubscribeCalls, 1);
    expect(fake.subscribeCalls, 1);
  });

  test('state exited → sessionExited + disconnected', () async {
    final fake = FakeTransport();
    final client = SseClient(transport: fake, ref: _ref, sessionId: 's1');
    await client.start();

    fake.lastHandlers!.onState(_session(status: 'exited'));

    expect(client.sessionExited, isTrue);
    expect(client.status, SseConnectionStatus.disconnected);
  });

  test('onConnected → status connected; onReconnecting → reconnecting', () async {
    final fake = FakeTransport();
    final client = SseClient(transport: fake, ref: _ref, sessionId: 's1');
    final connected = <int>[];
    final reconnecting = <int>[];
    client.onConnected = () => connected.add(1);
    client.onReconnecting = () => reconnecting.add(1);
    await client.start();

    fake.lastHandlers!.onConnected?.call();
    expect(client.status, SseConnectionStatus.connected);
    expect(connected, hasLength(1));

    fake.lastHandlers!.onReconnecting?.call();
    expect(client.status, SseConnectionStatus.reconnecting);
    expect(reconnecting, hasLength(1));
  });

  test('stream SessionNotFoundException → exited, no reconnect attempt', () async {
    final fake = FakeTransport();
    final client = SseClient(transport: fake, ref: _ref, sessionId: 's1');
    await client.start();

    fake.lastHandlers!.onError(SessionNotFoundException('gone'));

    expect(client.sessionExited, isTrue);
    expect(client.status, SseConnectionStatus.disconnected);
  });

  test('close() tears down and stops reconnects', () async {
    final fake = FakeTransport();
    final client = SseClient(transport: fake, ref: _ref, sessionId: 's1');
    await client.start();

    client.close();

    expect(client.status, SseConnectionStatus.disconnected);
    client.reconnect(); // no-op after close
    expect(fake.resubscribeCalls, 0);
  });
}
