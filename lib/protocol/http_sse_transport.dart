import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';

import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/types.dart';
import 'package:tired_agent_app/protocol/urls.dart';

/// Concrete [Transport] implementation that speaks HTTP + SSE to
/// a tired-agent manager or agent daemon, backed by [Dio].
class HttpSseTransport implements Transport {
  final Dio _dio;
  final Future<String?> Function()? _tokenProvider;

  /// Base delay (ms) for the first reconnect attempt. Reconnect backoff
  /// doubles this per attempt, capped at 30 s. Injectable to speed up tests.
  final int retryBaseDelayMs;

  /// Teardown callbacks for all active subscriptions, so [dispose] can close
  /// them (and any pending reconnect timers) in one shot.
  final Set<void Function()> _teardowns = {};

  HttpSseTransport({
    Dio? dio,
    Future<String?> Function()? tokenProvider,
    this.retryBaseDelayMs = 500,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 30),
             ),
           ),
       _tokenProvider = tokenProvider {
    // Dio interceptor: on 401, refresh token and retry once.
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          // Avoid recursive retry — only attempt once per request.
          if (error.requestOptions.extra['_retried'] == true) {
            handler.next(error);
            return;
          }
          if (error.response?.statusCode == 401 && _tokenProvider != null) {
            try {
              final freshToken = await _tokenProvider();
              if (freshToken != null && freshToken.isNotEmpty) {
                error.requestOptions.extra['_retried'] = true;
                error.requestOptions.headers['Authorization'] =
                    'Bearer $freshToken';
                final response = await _dio.fetch<dynamic>(
                  error.requestOptions,
                );
                handler.resolve(response);
                return;
              }
            } catch (_) {
              // Refresh failed — fall through to original error.
            }
          }
          handler.next(error);
        },
      ),
    );
  }

  // ─── URL helpers ──────────────────────────────────────────────────────

  /// /api/v1 prefix, optionally scoped under a specific agent.
  String _apiPrefix(String baseUrl, {String? agentId, String? subpath}) {
    final base = normalizeBaseUrl(baseUrl);
    final path = subpath != null ? '/$subpath' : '';
    if (agentId != null && agentId.isNotEmpty) {
      return '$base/api/v1/agents/${Uri.encodeComponent(agentId)}$path';
    }
    return '$base/api/v1$path';
  }

  String _sessionsBase(String baseUrl, {String? agentId}) =>
      _apiPrefix(baseUrl, agentId: agentId, subpath: 'sessions');

  String _sessionsUrl(String baseUrl, {String? agentId}) =>
      _sessionsBase(baseUrl, agentId: agentId);

  String _sessionUrl(String baseUrl, String sessionId, {String? agentId}) =>
      '${_sessionsBase(baseUrl, agentId: agentId)}/${Uri.encodeComponent(sessionId)}';

  String _directoriesBase(String baseUrl, {String? agentId}) =>
      _apiPrefix(baseUrl, agentId: agentId, subpath: 'directories');

  String _directoriesUrl(String baseUrl, {String? agentId}) =>
      _directoriesBase(baseUrl, agentId: agentId);

  String _agentsUrl(String baseUrl) =>
      '${normalizeBaseUrl(baseUrl)}/api/v1/manager/agents';

  String _loginUrl(String baseUrl) =>
      '${normalizeBaseUrl(baseUrl)}/api/v1/manager/auth/login';

  String _refreshUrl(String baseUrl) =>
      '${normalizeBaseUrl(baseUrl)}/api/v1/manager/auth/refresh';

  String _checkSessionUrl(String baseUrl) =>
      '${normalizeBaseUrl(baseUrl)}/api/v1/manager/auth/me';

  // ─── Low-level request helper ─────────────────────────────────────────
  //
  // Sends an HTTP request via Dio.  Dio automatically decodes JSON
  // responses so [response.data] is already a [Map] or [List].
  // On [DioException] we try to extract a structured [ErrorResponse] from
  // the body before throwing [TransportException].

  Future<dynamic> _request(
    String method,
    String url, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParameters,
    String? token,
    String? agentId,
  }) async {
    final options = Options(
      method: method,
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
        'X-Agent-Id': ?agentId,
      },
    );

    try {
      final response = await _dio.request<dynamic>(
        url,
        data: body,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      dev.log(
        'DioException: ${e.type} ${e.message} status=${e.response?.statusCode}',
        name: 'HttpSseTransport',
      );
      if (e.response?.data != null) {
        try {
          Map<String, dynamic> errorJson;
          final raw = e.response!.data;
          if (raw is String) {
            errorJson = json.decode(raw) as Map<String, dynamic>;
          } else {
            errorJson = raw as Map<String, dynamic>;
          }
          // Server wraps errors in {"error": {"code": "...", "message": "..."}}
          if (errorJson.containsKey('error') && errorJson['error'] is Map) {
            errorJson = errorJson['error'] as Map<String, dynamic>;
          }
          final error = ErrorResponse.fromJson(errorJson);
          dev.log(
            'parsed error: ${error.code}: ${error.message}',
            name: 'HttpSseTransport',
          );
          throw TransportException(
            '${error.code}: ${error.message}',
            statusCode: e.response?.statusCode,
          );
        } catch (inner) {
          if (inner is TransportException) rethrow;
        }
      }
      throw TransportException(
        e.message ?? 'HTTP ${e.response?.statusCode}',
        statusCode: e.response?.statusCode,
      );
    }
  }

  // ─── Session endpoints ────────────────────────────────────────────────

  @override
  Future<List<Session>> listSessions(ServerRef ref, {String? agentId}) async {
    final data = await _request(
      'GET',
      _sessionsUrl(ref.baseUrl, agentId: agentId),
      token: ref.token,
      agentId: agentId,
    );
    if (data == null) return [];
    final list = data as List<dynamic>;
    return list
        .map((e) => Session.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Session> createSession(
    ServerRef ref,
    SessionSpec spec, {
    String? agentId,
  }) async {
    final data = await _request(
      'POST',
      _sessionsUrl(ref.baseUrl, agentId: agentId),
      body: spec.toJson(),
      token: ref.token,
      agentId: agentId,
    );
    return Session.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Session> getSession(
    ServerRef ref,
    String id, {
    String? agentId,
  }) async {
    final data = await _request(
      'GET',
      _sessionUrl(ref.baseUrl, id, agentId: agentId),
      token: ref.token,
      agentId: agentId,
    );
    return Session.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> killSession(ServerRef ref, String id, {String? agentId}) async {
    // Same endpoint as deleteSession — server distinguishes exited vs running
    // and routes to hard-delete vs SIGKILL respectively.
    await _request(
      'DELETE',
      _sessionUrl(ref.baseUrl, id, agentId: agentId),
      token: ref.token,
      agentId: agentId,
    );
  }

  @override
  Future<void> deleteSession(
    ServerRef ref,
    String id, {
    String? agentId,
  }) async {
    await _request(
      'DELETE',
      _sessionUrl(ref.baseUrl, id, agentId: agentId),
      token: ref.token,
      agentId: agentId,
    );
  }

  @override
  Future<Map<String, dynamic>> pruneSessions(
    ServerRef ref, {
    int olderThanHours = 24,
    String? agentId,
  }) async {
    final data = await _request(
      'POST',
      '${_sessionsUrl(ref.baseUrl, agentId: agentId)}/prune',
      body: {'olderThanHours': olderThanHours},
      token: ref.token,
      agentId: agentId,
    );
    if (data == null) return <String, dynamic>{};
    return data as Map<String, dynamic>;
  }

  @override
  Future<void> resizeSession(
    ServerRef ref,
    String id,
    int cols,
    int rows, {
    String? agentId,
  }) async {
    await _request(
      'POST',
      '${_sessionUrl(ref.baseUrl, id, agentId: agentId)}/resize',
      body: ResizeRequest(cols: cols, rows: rows).toJson(),
      token: ref.token,
      agentId: agentId,
    );
  }

  @override
  Future<FetchOutputResult> fetchOutput(
    ServerRef ref,
    String id, {
    int fromOffset = 0,
    int? limit,
    String? agentId,
    int? tail,
  }) async {
    final queryParams = <String, dynamic>{'from': fromOffset};
    if (limit != null) queryParams['limit'] = limit;
    if (tail != null) queryParams['tail'] = tail;

    final data = await _request(
      'GET',
      '${_sessionUrl(ref.baseUrl, id, agentId: agentId)}/output',
      queryParameters: queryParams,
      token: ref.token,
      agentId: agentId,
    );
    return FetchOutputResult.fromJson(data as Map<String, dynamic>);
  }

  @override
  Subscription subscribe(
    ServerRef ref,
    String id,
    SubscribeHandlers handlers, {
    String? agentId,
    int fromOffset = 0,
  }) {
    bool closed = false;
    CancelToken? cancelToken;
    StreamSubscription<String>? lineSub;
    int currentFrom = fromOffset;
    int reconnectAttempt = 0;
    Timer? reconnectTimer;
    late void Function() scheduleReconnect;

    void teardown() {
      reconnectTimer?.cancel();
      closed = true;
      cancelToken?.cancel();
      lineSub?.cancel();
      _teardowns.remove(teardown);
    }

    void connect() {
      if (closed) return;
      reconnectTimer?.cancel();
      cancelToken?.cancel();
      // Per-connection token: once a newer connect() replaces this one,
      // `cancelToken` stops pointing at `thisCancelToken`, so a stale stream
      // (deliberately cancelled to start a successor) bails instead of
      // scheduling reconnects. Without this, cancelling a live stream on
      // reconnect() looks like a drop → schedules a reconnect → which cancels
      // the new connection → infinite connected↔reconnecting flicker.
      final thisCancelToken = CancelToken();
      cancelToken = thisCancelToken;

      // Resolve a fresh token before each connection attempt.
      Future<String> resolveToken() async {
        if (_tokenProvider == null) return ref.token;
        try {
          final fresh = await _tokenProvider();
          if (fresh != null && fresh.isNotEmpty) return fresh;
        } catch (_) {}
        return ref.token;
      }

      resolveToken().then((String token) {
        if (closed || cancelToken != thisCancelToken) return;

        final queryParams = <String, String>{};
        if (currentFrom > 0) {
          queryParams['from'] = currentFrom.toString();
        }
        final path = '${_sessionUrl(ref.baseUrl, id, agentId: agentId)}/stream';
        final uri = Uri.parse(
          path,
        ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

        final options = Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'text/event-stream',
            'X-Agent-Id': ?agentId,
          },
          // Don't throw on non-2xx so we can read the error body.
          validateStatus: (_) => true,
        );

        _dio
            .get(uri.toString(), options: options, cancelToken: thisCancelToken)
            .then((Response<dynamic> response) {
              if (closed || cancelToken != thisCancelToken) return;

              final responseBody = response.data as ResponseBody;

              if (response.statusCode != 200) {
                // Read error body from the streamed response.
                utf8.decodeStream(responseBody.stream).then((body) {
                  if (closed || cancelToken != thisCancelToken) return;
                  try {
                    // Server wraps errors in {"error": {"code", "message"}}.
                    var errorJson = json.decode(body) as Map<String, dynamic>;
                    if (errorJson.containsKey('error') &&
                        errorJson['error'] is Map) {
                      errorJson = errorJson['error'] as Map<String, dynamic>;
                    }
                    final error = ErrorResponse.fromJson(errorJson);
                    final status = response.statusCode;

                    // 404 NOT_FOUND → session 已永久删除/退出，不重连。
                    if (status == 404 && error.code == 'NOT_FOUND') {
                      handlers.onError(
                        SessionNotFoundException(
                          '${error.code}: ${error.message}',
                        ),
                      );
                      teardown();
                      return;
                    }
                    // 401 → token 已失效，重连也无法恢复；交由上层刷新后
                    // 手动 resubscribe，避免无限退避空转。
                    if (status == 401) {
                      handlers.onError(
                        TransportException(
                          '${error.code}: ${error.message}',
                          statusCode: 401,
                        ),
                      );
                      teardown();
                      return;
                    }

                    handlers.onError(
                      TransportException(
                        '${error.code}: ${error.message}',
                        statusCode: status,
                      ),
                    );
                  } catch (inner) {
                    if (inner is TransportException) {
                      handlers.onError(inner);
                    } else {
                      handlers.onError(
                        TransportException(
                          'HTTP ${response.statusCode}',
                          statusCode: response.statusCode,
                        ),
                      );
                    }
                  }
                  scheduleReconnect();
                });
                return;
              }

              // Successful connection -- reset back-off counter.
              reconnectAttempt = 0;
              handlers.onConnected?.call();

              final stream = responseBody.stream
                  .cast<List<int>>()
                  .transform(utf8.decoder)
                  .transform(const LineSplitter());

              String currentEvent = '';
              final StringBuffer dataBuffer = StringBuffer();

              lineSub = stream.listen(
                (String line) {
                  if (line.startsWith('event: ')) {
                    currentEvent = line.substring(7).trim();
                  } else if (line.startsWith('data: ')) {
                    if (dataBuffer.isNotEmpty) {
                      dataBuffer.write('\n');
                    }
                    dataBuffer.write(line.substring(6));
                  } else if (line.isEmpty && dataBuffer.isNotEmpty) {
                    // Blank line -> dispatch the accumulated event.
                    final rawData = dataBuffer.toString();
                    dataBuffer.clear();
                    final eventType = currentEvent;
                    currentEvent = '';

                    try {
                      final jsonData =
                          json.decode(rawData) as Map<String, dynamic>;
                      final event = parseStreamEvent(eventType, jsonData);

                      switch (event) {
                        case OutputEvent():
                          final decoded = base64.decode(event.data);
                          currentFrom = event.offset + decoded.length;
                          handlers.onChunk(
                            OutputChunk(offset: event.offset, data: decoded),
                          );
                        case StateEvent():
                          handlers.onState(event.session);
                        case HeartbeatEvent():
                          handlers.onHeartbeat?.call();
                          break;
                      }
                    } catch (e) {
                      handlers.onError(e);
                    }
                  }
                },
                onError: (Object error) {
                  // Deliberately cancelled — a newer connect()/teardown took
                  // over this stream. Not a real drop, so don't reconnect.
                  if (cancelToken != thisCancelToken) return;
                  if (!closed) {
                    handlers.onError(error);
                    scheduleReconnect();
                  }
                },
                onDone: () {
                  if (cancelToken != thisCancelToken) return;
                  if (!closed) {
                    scheduleReconnect();
                  }
                },
              );
            })
            .catchError((Object error) {
              if (closed || cancelToken != thisCancelToken) return;
              // Ignore cancellation errors since we trigger them deliberately.
              if (error is DioException &&
                  error.type == DioExceptionType.cancel) {
                return;
              }
              handlers.onError(error);
              scheduleReconnect();
            });
      });
    }

    scheduleReconnect = () {
      if (closed) return;
      handlers.onReconnecting?.call();
      reconnectAttempt++;
      final delayMs = (retryBaseDelayMs * (1 << (reconnectAttempt - 1))).clamp(
        retryBaseDelayMs,
        30000,
      );
      reconnectTimer = Timer(Duration(milliseconds: delayMs), () {
        if (!closed) connect();
      });
    };

    /// Reconnect from the current offset without re-fetching history.
    ///
    /// Cancels any pending backoff timer so a stale timer can't spawn a second
    /// connection after a manual reconnect.
    void resubscribe() {
      reconnectTimer?.cancel();
      closed = false;
      connect();
    }

    _teardowns.add(teardown);
    connect();

    return Subscription(close: teardown, resubscribe: resubscribe);
  }

  @override
  Future<void> sendInput(
    ServerRef ref,
    String id,
    List<int> data, {
    String? agentId,
  }) async {
    final encoded = base64.encode(data);
    await _request(
      'POST',
      '${_sessionUrl(ref.baseUrl, id, agentId: agentId)}/input',
      body: InputRequest(data: encoded).toJson(),
      token: ref.token,
      agentId: agentId,
    );
  }

  // ─── Directory endpoints ──────────────────────────────────────────────

  @override
  Future<DirectoryListing> listDirectories(
    ServerRef ref, {
    String? path,
    String? agentId,
  }) async {
    final queryParams = <String, dynamic>{};
    if (path != null) queryParams['path'] = path;

    final data = await _request(
      'GET',
      _directoriesUrl(ref.baseUrl, agentId: agentId),
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
      token: ref.token,
      agentId: agentId,
    );
    return DirectoryListing.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<DirectoryShortcuts> getDirectoryShortcuts(
    ServerRef ref, {
    String? agentId,
  }) async {
    final data = await _request(
      'GET',
      '${_directoriesUrl(ref.baseUrl, agentId: agentId)}/shortcuts',
      token: ref.token,
      agentId: agentId,
    );
    return DirectoryShortcuts.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<DirectoryFavorite> addDirectoryFavorite(
    ServerRef ref, {
    required String path,
    String? name,
    String? agentId,
  }) async {
    final data = await _request(
      'POST',
      '${_directoriesUrl(ref.baseUrl, agentId: agentId)}/favorites',
      body: {'path': path, 'name': ?name},
      token: ref.token,
      agentId: agentId,
    );
    return DirectoryFavorite.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> removeDirectoryFavorite(
    ServerRef ref,
    String id, {
    String? agentId,
  }) async {
    await _request(
      'DELETE',
      '${_directoriesUrl(ref.baseUrl, agentId: agentId)}/favorites/$id',
      token: ref.token,
      agentId: agentId,
    );
  }

  // ─── Agent endpoints ──────────────────────────────────────────────────

  @override
  Future<List<AgentInfo>> listAgents(ServerRef ref) async {
    final data = await _request(
      'GET',
      _agentsUrl(ref.baseUrl),
      token: ref.token,
    );
    if (data == null) return [];
    final list = data as List<dynamic>;
    return list
        .map((e) => AgentInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> addAgent(
    ServerRef ref, {
    required String name,
    required String baseUrl,
    required String token,
  }) async {
    final data = await _request(
      'POST',
      _agentsUrl(ref.baseUrl),
      body: {'name': name, 'baseUrl': baseUrl, 'token': token},
      token: ref.token,
    );
    if (data == null) return <String, dynamic>{};
    return data as Map<String, dynamic>;
  }

  @override
  Future<void> deleteAgent(ServerRef ref, String agentId) async {
    await _request(
      'DELETE',
      '${_agentsUrl(ref.baseUrl)}/$agentId',
      token: ref.token,
    );
  }

  @override
  Future<void> updateAgent(
    ServerRef ref,
    String agentId, {
    required String name,
    required String baseUrl,
    String? token,
  }) async {
    await _request(
      'PATCH',
      '${_agentsUrl(ref.baseUrl)}/$agentId',
      body: {
        'name': name,
        'baseUrl': baseUrl,
        if (token != null && token.isNotEmpty) 'token': token,
      },
      token: ref.token,
    );
  }

  // ─── Auth endpoints ───────────────────────────────────────────────────

  @override
  Future<LoginResponse> login(ServerRef ref, String token) async {
    final data = await _request(
      'POST',
      _loginUrl(ref.baseUrl),
      body: {'token': token},
    );
    return LoginResponse.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<LoginResponse> refreshSession(
    ServerRef ref,
    String refreshToken,
  ) async {
    final data = await _request(
      'POST',
      _refreshUrl(ref.baseUrl),
      body: {'refreshToken': refreshToken},
      token: refreshToken,
    );
    return LoginResponse.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<bool> checkSession(ServerRef ref) async {
    try {
      final data = await _request(
        'GET',
        _checkSessionUrl(ref.baseUrl),
        token: ref.token,
      );
      final result = data as Map<String, dynamic>;
      return result['valid'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  // ─── Connection probe ───────────────────────────────────────────────

  @override
  Future<AgentConnectionTestResult> testAgentConnection(
    String baseUrl,
    String token,
  ) async {
    final base = normalizeBaseUrl(baseUrl);
    try {
      // Step 1 — reachability + identity. `/health` is unauthenticated and
      // doubles as a sanity check that the target is actually a tired-agent
      // (non-JSON or 404 here is reported as a transport error).
      String? name;
      String? version;
      final health = await _request('GET', '$base/health');
      if (health is Map<String, dynamic>) {
        name = health['name'] as String?;
        version = health['version'] as String?;
      }

      // Step 2 — token validity. Bearer-protected; 401 means token is wrong.
      await _request('GET', '$base/api/v1/sessions', token: token);

      return AgentConnectionTestResult.success(name: name, version: version);
    } on TransportException catch (e) {
      return AgentConnectionTestResult.failure(describeTransportError(e));
    } catch (e) {
      return AgentConnectionTestResult.failure(e.toString());
    }
  }

  @override
  void dispose() {
    for (final teardown in List.of(_teardowns)) {
      teardown();
    }
  }
}

/// Normalize a transport-layer error into a short, prefix-tagged string
/// suitable for dispatching in the UI layer to a localized message.
///
/// Format: `<category>:<detail>` where category is one of:
///   - `network:<message>`   — request never reached a responder
///   - `http:<status>:<msg>` — server replied with non-2xx
///   - `other:<toString()>`  — fallback for any other thrown object
///
/// UI layers (e.g. the test-connection button) parse this prefix to pick
/// the right l10n entry. Keeping the helper here means protocol-layer code
/// owns its own error taxonomy and UI just translates.
String describeTransportError(Object error) {
  if (error is TransportException) {
    if (error.statusCode == null) {
      return 'network:${error.message}';
    }
    return 'http:${error.statusCode}:${error.message}';
  }
  return 'other:$error';
}
