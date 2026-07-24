import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

import 'package:tired_agent_app/protocol/transport.dart';
import 'package:tired_agent_app/protocol/types.dart';

/// Concrete [Transport] implementation that speaks HTTP + SSE to
/// a tired-agent manager or agent daemon, backed by [Dio].
class HttpSseTransport implements Transport {
  final Dio _dio;
  final Future<String?> Function()? _tokenProvider;

  HttpSseTransport({Dio? dio, Future<String?> Function()? tokenProvider})
      : _dio = dio ??
            Dio(BaseOptions(
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 30),
            )),
        _tokenProvider = tokenProvider {
    // Dio interceptor: on 401, refresh token and retry once.
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401 && _tokenProvider != null) {
          try {
            final freshToken = await _tokenProvider();
            if (freshToken != null && freshToken.isNotEmpty) {
              error.requestOptions.headers['Authorization'] =
                  'Bearer $freshToken';
              final response = await _dio.fetch<dynamic>(error.requestOptions);
              handler.resolve(response);
              return;
            }
          } catch (_) {
            // Refresh failed — fall through to original error.
          }
        }
        handler.next(error);
      },
    ));
  }

  bool closed = false;

  // ─── URL helpers ──────────────────────────────────────────────────────

  String _ensureBaseUrl(String url) => url.replaceAll(RegExp(r'/+$'), '');

  String _sessionsUrl(String baseUrl, {String? agentId}) {
    final base = _ensureBaseUrl(baseUrl);
    if (agentId != null && agentId.isNotEmpty) {
      return '$base/api/v1/agents/${Uri.encodeComponent(agentId)}/sessions';
    }
    return '$base/api/v1/sessions';
  }

  String _sessionUrl(String baseUrl, String sessionId, {String? agentId}) {
    final base = _ensureBaseUrl(baseUrl);
    if (agentId != null && agentId.isNotEmpty) {
      return '$base/api/v1/agents/${Uri.encodeComponent(agentId)}/sessions/${Uri.encodeComponent(sessionId)}';
    }
    return '$base/api/v1/sessions/${Uri.encodeComponent(sessionId)}';
  }

  String _directoriesUrl(String baseUrl, {String? agentId}) {
    final base = _ensureBaseUrl(baseUrl);
    if (agentId != null && agentId.isNotEmpty) {
      return '$base/api/v1/agents/${Uri.encodeComponent(agentId)}/directories';
    }
    return '$base/api/v1/directories';
  }

  String _agentsUrl(String baseUrl) =>
      '${_ensureBaseUrl(baseUrl)}/api/v1/manager/agents';

  String _loginUrl(String baseUrl) =>
      '${_ensureBaseUrl(baseUrl)}/api/v1/manager/auth/login';

  String _refreshUrl(String baseUrl) =>
      '${_ensureBaseUrl(baseUrl)}/api/v1/manager/auth/refresh';

  String _checkSessionUrl(String baseUrl) =>
      '${_ensureBaseUrl(baseUrl)}/api/v1/manager/auth/me';

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
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
        if (agentId != null) 'X-Agent-Id': agentId,
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
      debugPrint('[HttpSseTransport] DioException: ${e.type} ${e.message} status=${e.response?.statusCode}');
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
          debugPrint('[HttpSseTransport] parsed error: ${error.code}: ${error.message}');
          throw TransportException('${error.code}: ${error.message}',
              statusCode: e.response?.statusCode);
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
  Future<List<Session>> listSessions(ServerRef ref,
      {String? agentId}) async {
    final data = await _request('GET', _sessionsUrl(ref.baseUrl, agentId: agentId),
        token: ref.token, agentId: agentId);
    if (data == null) return [];
    final list = data as List<dynamic>;
    return list
        .map((e) => Session.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Session> createSession(ServerRef ref, SessionSpec spec,
      {String? agentId}) async {
    final data = await _request('POST', _sessionsUrl(ref.baseUrl, agentId: agentId),
        body: spec.toJson(), token: ref.token, agentId: agentId);
    return Session.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<Session> getSession(ServerRef ref, String id,
      {String? agentId}) async {
    final data = await _request('GET', _sessionUrl(ref.baseUrl, id, agentId: agentId),
        token: ref.token, agentId: agentId);
    return Session.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> killSession(ServerRef ref, String id,
      {String? agentId}) async {
    await _request('POST', '${_sessionUrl(ref.baseUrl, id, agentId: agentId)}/kill',
        token: ref.token, agentId: agentId);
  }

  @override
  Future<void> deleteSession(ServerRef ref, String id,
      {String? agentId}) async {
    await _request('DELETE', _sessionUrl(ref.baseUrl, id, agentId: agentId),
        token: ref.token, agentId: agentId);
  }

  @override
  Future<Map<String, dynamic>> pruneSessions(ServerRef ref,
      {int olderThanHours = 24, String? agentId}) async {
    final data = await _request(
        'POST', '${_sessionsUrl(ref.baseUrl, agentId: agentId)}/prune',
        body: {'olderThanHours': olderThanHours},
        token: ref.token,
        agentId: agentId);
    if (data == null) return <String, dynamic>{};
    return data as Map<String, dynamic>;
  }

  @override
  Future<void> resizeSession(ServerRef ref, String id, int cols, int rows,
      {String? agentId}) async {
    await _request('POST', '${_sessionUrl(ref.baseUrl, id, agentId: agentId)}/resize',
        body: ResizeRequest(cols: cols, rows: rows).toJson(),
        token: ref.token,
        agentId: agentId);
  }

  @override
  Future<FetchOutputResult> fetchOutput(ServerRef ref, String id,
      {int fromOffset = 0, int? limit, String? agentId, int? tail}) async {
    final queryParams = <String, dynamic>{'from': fromOffset};
    if (limit != null) queryParams['limit'] = limit;
    if (tail != null) queryParams['tail'] = tail;

    final data = await _request(
        'GET', '${_sessionUrl(ref.baseUrl, id, agentId: agentId)}/output',
        queryParameters: queryParams, token: ref.token, agentId: agentId);
    return FetchOutputResult.fromJson(data as Map<String, dynamic>);
  }

  @override
  Subscription subscribe(ServerRef ref, String id,
      SubscribeHandlers handlers, {String? agentId, int fromOffset = 0}) {
    bool closed = false;
    CancelToken? cancelToken;
    StreamSubscription<String>? lineSub;
    int currentFrom = fromOffset;
    int reconnectAttempt = 0;
    late void Function() scheduleReconnect;

    void teardown() {
      closed = true;
      cancelToken?.cancel();
      lineSub?.cancel();
    }

    void connect() {
      if (closed) return;
      cancelToken?.cancel();
      cancelToken = CancelToken();

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
        if (closed) return;

        final queryParams = <String, String>{};
        if (currentFrom > 0) {
          queryParams['from'] = currentFrom.toString();
        }
        final path = '${_sessionUrl(ref.baseUrl, id, agentId: agentId)}/stream';
        final uri = Uri.parse(path).replace(
            queryParameters:
                queryParams.isNotEmpty ? queryParams : null);

        final options = Options(
          responseType: ResponseType.stream,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'text/event-stream',
            if (agentId != null) 'X-Agent-Id': agentId,
          },
          // Don't throw on non-2xx so we can read the error body.
          validateStatus: (_) => true,
        );

        _dio
            .get(
          uri.toString(),
          options: options,
          cancelToken: cancelToken,
        )
            .then((Response<dynamic> response) {
          if (closed) return;

          final responseBody = response.data as ResponseBody;

          if (response.statusCode != 200) {
            // Read error body from the streamed response.
            utf8.decodeStream(responseBody.stream).then((body) {
              if (closed) return;
              try {
                final error = ErrorResponse.fromJson(
                    json.decode(body) as Map<String, dynamic>);
                handlers.onError(TransportException(
                    '${error.code}: ${error.message}',
                    statusCode: response.statusCode));
              } catch (inner) {
                if (inner is TransportException) {
                  handlers.onError(inner);
                } else {
                  handlers.onError(TransportException(
                      'HTTP ${response.statusCode}',
                      statusCode: response.statusCode));
                }
              }
              scheduleReconnect();
            });
            return;
          }

          // Successful connection -- reset back-off counter.
          reconnectAttempt = 0;

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
                      handlers.onChunk(OutputChunk(
                          offset: event.offset, data: decoded));
                    case StateEvent():
                      handlers.onState(event.session);
                    case HeartbeatEvent():
                      // Heartbeats keep the connection alive;
                      // nothing to dispatch to handlers.
                      break;
                  }
                } catch (e) {
                  handlers.onError(e);
                }
              }
            },
            onError: (Object error) {
              if (!closed) {
                handlers.onError(error);
                scheduleReconnect();
              }
            },
            onDone: () {
              if (!closed) {
                scheduleReconnect();
              }
            },
          );
        }).catchError((Object error) {
          if (closed) return;
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
      reconnectAttempt++;
      final delayMs =
          (500 * (1 << (reconnectAttempt - 1))).clamp(500, 30000);
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (!closed) connect();
      });
    };

    // Kick off the initial connection.
    connect();

    return Subscription(close: teardown);
  }

  @override
  Future<void> sendInput(ServerRef ref, String id, List<int> data,
      {String? agentId}) async {
    final encoded = base64.encode(data);
    await _request('POST', '${_sessionUrl(ref.baseUrl, id, agentId: agentId)}/input',
        body: InputRequest(data: encoded).toJson(),
        token: ref.token,
        agentId: agentId);
  }

  // ─── Directory endpoints ──────────────────────────────────────────────

  @override
  Future<DirectoryListing> listDirectories(ServerRef ref,
      {String? path, String? agentId}) async {
    final queryParams = <String, dynamic>{};
    if (path != null) queryParams['path'] = path;

    final data = await _request('GET', _directoriesUrl(ref.baseUrl, agentId: agentId),
        queryParameters:
            queryParams.isNotEmpty ? queryParams : null,
        token: ref.token,
        agentId: agentId);
    return DirectoryListing.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<DirectoryShortcuts> getDirectoryShortcuts(ServerRef ref,
      {String? agentId}) async {
    final data = await _request(
        'GET', '${_directoriesUrl(ref.baseUrl, agentId: agentId)}/shortcuts',
        token: ref.token, agentId: agentId);
    return DirectoryShortcuts.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<DirectoryFavorite> addDirectoryFavorite(ServerRef ref,
      {required String path, String? name, String? agentId}) async {
    final data = await _request(
        'POST', '${_directoriesUrl(ref.baseUrl, agentId: agentId)}/favorites',
        body: {'path': path, if (name != null) 'name': name},
        token: ref.token,
        agentId: agentId);
    return DirectoryFavorite.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<void> removeDirectoryFavorite(ServerRef ref, String id,
      {String? agentId}) async {
    await _request('DELETE', '${_directoriesUrl(ref.baseUrl, agentId: agentId)}/favorites/$id',
        token: ref.token, agentId: agentId);
  }

  // ─── Agent endpoints ──────────────────────────────────────────────────

  @override
  Future<List<AgentInfo>> listAgents(ServerRef ref) async {
    final data = await _request('GET', _agentsUrl(ref.baseUrl),
        token: ref.token);
    if (data == null) return [];
    final list = data as List<dynamic>;
    return list
        .map((e) => AgentInfo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, dynamic>> addAgent(ServerRef ref,
      {required String name,
      required String baseUrl,
      required String token}) async {
    final data = await _request('POST', _agentsUrl(ref.baseUrl),
        body: {'name': name, 'baseUrl': baseUrl, 'token': token},
        token: ref.token);
    if (data == null) return <String, dynamic>{};
    return data as Map<String, dynamic>;
  }

  @override
  Future<void> deleteAgent(ServerRef ref, String agentId) async {
    await _request('DELETE', '${_agentsUrl(ref.baseUrl)}/$agentId',
        token: ref.token);
  }

  // ─── Auth endpoints ───────────────────────────────────────────────────

  @override
  Future<LoginResponse> login(ServerRef ref, String token) async {
    final data = await _request('POST', _loginUrl(ref.baseUrl),
        body: {'token': token});
    return LoginResponse.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<LoginResponse> refreshSession(
      ServerRef ref, String refreshToken) async {
    final data = await _request('POST', _refreshUrl(ref.baseUrl),
        body: {'refreshToken': refreshToken}, token: refreshToken);
    return LoginResponse.fromJson(data as Map<String, dynamic>);
  }

  @override
  Future<bool> checkSession(ServerRef ref) async {
    try {
      final data = await _request('GET', _checkSessionUrl(ref.baseUrl),
          token: ref.token);
      final result = data as Map<String, dynamic>;
      return result['valid'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }
}
