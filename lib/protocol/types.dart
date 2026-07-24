/// Shared type definitions for tired-agent.
/// Dart mirror of `@tired-agent/protocol` TypeScript types.
library;

// ─── Enums ────────────────────────────────────────────────────────────

/// Lifecycle state of a PTY session on the server.
enum SessionStatus { starting, running, exited }

/// Session lifecycle mode.
enum SessionMode { process, persistent }

/// Execution mode for persistent (chat) sessions.
enum ExecutionMode { auto, manual, plan }

// ─── Core types ───────────────────────────────────────────────────────

/// Specifications for creating a new session.
class SessionSpec {
  final String cmd;
  final List<String>? args;
  final String? cwd;
  final Map<String, String>? env;
  final int? cols;
  final int? rows;
  final String? label;
  final SessionMode? mode;
  final ExecutionMode? executionMode;

  const SessionSpec({
    required this.cmd,
    this.args,
    this.cwd,
    this.env,
    this.cols,
    this.rows,
    this.label,
    this.mode,
    this.executionMode,
  });

  Map<String, dynamic> toJson() => {
    'cmd': cmd,
    if (args != null && args!.isNotEmpty) 'args': args,
    if (cwd != null) 'cwd': cwd,
    if (env != null && env!.isNotEmpty) 'env': env,
    if (cols != null) 'cols': cols,
    if (rows != null) 'rows': rows,
    if (label != null) 'label': label,
    if (mode != null) 'mode': mode!.name,
    if (executionMode != null) 'executionMode': executionMode!.name,
  };
}

/// Server-side metadata for a session.
class Session {
  final String id;
  final String cmd;
  final List<String> args;
  final String? cwd;
  final Map<String, String>? env;
  final SessionStatus status;
  final int? pid;
  final int? exitCode;
  final int createdAt;
  final int? exitedAt;
  final int byteOffset;
  final int cols;
  final int rows;
  final String? label;
  final SessionMode? mode;

  const Session({
    required this.id,
    required this.cmd,
    required this.args,
    this.cwd,
    this.env,
    required this.status,
    this.pid,
    this.exitCode,
    required this.createdAt,
    this.exitedAt,
    required this.byteOffset,
    required this.cols,
    required this.rows,
    this.label,
    this.mode,
  });

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(
      id: json['id'] as String,
      cmd: json['cmd'] as String,
      args: (json['args'] as List<dynamic>?)?.cast<String>() ?? [],
      cwd: json['cwd'] as String?,
      env: (json['env'] as Map<String, dynamic>?)?.cast<String, String>(),
      status: _parseSessionStatus(json['status'] as String?),
      pid: json['pid'] as int?,
      exitCode: json['exitCode'] as int?,
      createdAt: (json['createdAt'] as num).toInt(),
      exitedAt: json['exitedAt'] as int?,
      byteOffset: (json['byteOffset'] as num).toInt(),
      cols: (json['cols'] as num?)?.toInt() ?? 80,
      rows: (json['rows'] as num?)?.toInt() ?? 24,
      label: json['label'] as String?,
      mode: json['mode'] != null
          ? SessionMode.values.byName(json['mode'] as String)
          : null,
    );
  }

  static SessionStatus _parseSessionStatus(String? s) {
    return switch (s) {
      'starting' => SessionStatus.starting,
      'running' => SessionStatus.running,
      'exited' => SessionStatus.exited,
      _ => SessionStatus.exited,
    };
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'cmd': cmd,
    'args': args,
    if (cwd != null) 'cwd': cwd,
    if (env != null) 'env': env,
    'status': status.name,
    if (pid != null) 'pid': pid,
    if (exitCode != null) 'exitCode': exitCode,
    'createdAt': createdAt,
    if (exitedAt != null) 'exitedAt': exitedAt,
    'byteOffset': byteOffset,
    'cols': cols,
    'rows': rows,
    if (label != null) 'label': label,
    if (mode != null) 'mode': mode!.name,
  };
}

/// A reference to a server daemon.
class ServerRef {
  final String id;
  final String name;
  final String baseUrl;
  final String token;

  const ServerRef({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.token,
  });

  factory ServerRef.fromJson(Map<String, dynamic> json) => ServerRef(
    id: json['id'] as String,
    name: json['name'] as String,
    baseUrl: json['baseUrl'] as String,
    token: json['token'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'token': token,
  };
}

/// A chunk of PTY output bytes.
class OutputChunk {
  final int offset;
  final List<int> data;

  const OutputChunk({required this.offset, required this.data});
}

// ─── Directory types ──────────────────────────────────────────────────

class DirectoryEntry {
  final String name;
  final String path;
  const DirectoryEntry({required this.name, required this.path});

  factory DirectoryEntry.fromJson(Map<String, dynamic> json) => DirectoryEntry(
    name: json['name'] as String,
    path: json['path'] as String,
  );
}

class DirectoryListing {
  final String path;
  final String? parent;
  final List<DirectoryEntry> entries;
  const DirectoryListing({
    required this.path,
    this.parent,
    required this.entries,
  });

  factory DirectoryListing.fromJson(Map<String, dynamic> json) =>
      DirectoryListing(
        path: json['path'] as String,
        parent: json['parent'] as String?,
        entries: (json['entries'] as List<dynamic>)
            .map((e) => DirectoryEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class DirectoryFavorite {
  final String id;
  final String name;
  final String path;
  const DirectoryFavorite({
    required this.id,
    required this.name,
    required this.path,
  });

  factory DirectoryFavorite.fromJson(Map<String, dynamic> json) =>
      DirectoryFavorite(
        id: json['id'] as String,
        name: json['name'] as String,
        path: json['path'] as String,
      );
}

class RecentDirectory {
  final String path;
  final int lastUsedAt;
  const RecentDirectory({required this.path, required this.lastUsedAt});

  factory RecentDirectory.fromJson(Map<String, dynamic> json) =>
      RecentDirectory(
        path: json['path'] as String,
        lastUsedAt: (json['lastUsedAt'] as num).toInt(),
      );
}

class DirectoryShortcuts {
  final List<DirectoryFavorite> favorites;
  final List<RecentDirectory> recent;
  const DirectoryShortcuts({required this.favorites, required this.recent});

  factory DirectoryShortcuts.fromJson(Map<String, dynamic> json) =>
      DirectoryShortcuts(
        favorites: (json['favorites'] as List<dynamic>)
            .map((e) => DirectoryFavorite.fromJson(e as Map<String, dynamic>))
            .toList(),
        recent: (json['recent'] as List<dynamic>)
            .map((e) => RecentDirectory.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

// ─── I/O types ────────────────────────────────────────────────────────

class FetchOutputResult {
  final List<OutputChunkJson> chunks;
  final int upTo;
  final bool? truncated;
  final int? totalBytes;

  const FetchOutputResult({
    required this.chunks,
    required this.upTo,
    this.truncated,
    this.totalBytes,
  });

  factory FetchOutputResult.fromJson(Map<String, dynamic> json) =>
      FetchOutputResult(
        chunks: (json['chunks'] as List<dynamic>)
            .map((e) => OutputChunkJson.fromJson(e as Map<String, dynamic>))
            .toList(),
        upTo: (json['upTo'] as num).toInt(),
        truncated: json['truncated'] as bool?,
        totalBytes: json['totalBytes'] as int?,
      );
}

class OutputChunkJson {
  final int offset;
  final String data; // base64-encoded

  const OutputChunkJson({required this.offset, required this.data});

  factory OutputChunkJson.fromJson(Map<String, dynamic> json) =>
      OutputChunkJson(
        offset: (json['offset'] as num).toInt(),
        data: json['data'] as String,
      );
}

class InputRequest {
  final String data; // base64-encoded
  const InputRequest({required this.data});

  Map<String, dynamic> toJson() => {'data': data};
}

class ResizeRequest {
  final int cols;
  final int rows;
  const ResizeRequest({required this.cols, required this.rows});

  Map<String, dynamic> toJson() => {'cols': cols, 'rows': rows};
}

// ─── SSE event types ──────────────────────────────────────────────────

sealed class StreamEvent {}

class OutputEvent extends StreamEvent {
  final int offset;
  final String data; // base64
  OutputEvent({required this.offset, required this.data});
}

class StateEvent extends StreamEvent {
  final Session session;
  StateEvent({required this.session});
}

class HeartbeatEvent extends StreamEvent {
  final int ts;
  HeartbeatEvent({required this.ts});
}

StreamEvent parseStreamEvent(String eventType, Map<String, dynamic> data) {
  return switch (eventType) {
    'state' => StateEvent(session: Session.fromJson(data)),
    'heartbeat' => HeartbeatEvent(ts: (data['ts'] as num?)?.toInt() ?? 0),
    _ => OutputEvent(
      offset: (data['offset'] as num?)?.toInt() ?? 0,
      data: (data['data'] as String?) ?? '',
    ),
  };
}

// ─── Auth types ───────────────────────────────────────────────────────

class LoginResponse {
  final String sessionToken;
  final String refreshToken;
  final int sessionExpiresIn;
  final int refreshExpiresIn;

  const LoginResponse({
    required this.sessionToken,
    required this.refreshToken,
    required this.sessionExpiresIn,
    required this.refreshExpiresIn,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
    sessionToken: json['sessionToken'] as String,
    refreshToken: json['refreshToken'] as String,
    sessionExpiresIn: (json['sessionExpiresIn'] as num).toInt(),
    refreshExpiresIn: (json['refreshExpiresIn'] as num).toInt(),
  );
}

class AgentInfo {
  final String id;
  final String name;
  final String baseUrl;

  const AgentInfo({
    required this.id,
    required this.name,
    required this.baseUrl,
  });

  factory AgentInfo.fromJson(Map<String, dynamic> json) => AgentInfo(
    id: json['id'] as String,
    name: json['name'] as String,
    baseUrl: json['baseUrl'] as String,
  );
}

// ─── Structured content types (renderer output) ───────────────────────

sealed class StructuredContent {
  const StructuredContent();
}

class ContentText extends StructuredContent {
  final String text;
  final ContentStyle? style;
  const ContentText({required this.text, this.style});
}

class ContentCode extends StructuredContent {
  final String code;
  final String? language;
  final bool displayBlock;
  const ContentCode({
    required this.code,
    this.language,
    this.displayBlock = true,
  });
}

class ContentDivider extends StructuredContent {
  final String? label;
  const ContentDivider({this.label});
}

class ContentStatus extends StructuredContent {
  final StatusKind kind;
  final String text;
  final bool ephemeral;
  const ContentStatus({
    required this.kind,
    required this.text,
    this.ephemeral = false,
  });
}

class ContentTable extends StructuredContent {
  final List<String> headers;
  final List<List<String>> rows;
  const ContentTable({required this.headers, required this.rows});
}

class ContentLink extends StructuredContent {
  final String url;
  final String text;
  const ContentLink({required this.url, required this.text});
}

class ContentImage extends StructuredContent {
  final String alt;
  final String url;
  const ContentImage({required this.alt, required this.url});
}

class ContentCommand extends StructuredContent {
  final String raw;
  final String parsed;
  const ContentCommand({required this.raw, required this.parsed});
}

class ContentUserMessage extends StructuredContent {
  final String text;
  const ContentUserMessage({required this.text});
}

class ContentToolUse extends StructuredContent {
  final String name;
  final String input; // JSON-stringified
  final String toolUseId;
  final bool completed;
  const ContentToolUse({
    required this.name,
    required this.input,
    required this.toolUseId,
    this.completed = false,
  });
}

class ContentToolResult extends StructuredContent {
  final String toolUseId;
  final String content;
  final String? mimeType;
  final bool isError;
  const ContentToolResult({
    required this.toolUseId,
    required this.content,
    this.mimeType,
    this.isError = false,
  });
}

class ContentStreamEvent extends StructuredContent {
  final String text;
  final bool append;
  const ContentStreamEvent({required this.text, this.append = false});
}

class ContentUsage extends StructuredContent {
  final int inputTokens;
  final int outputTokens;
  const ContentUsage({required this.inputTokens, required this.outputTokens});
}

enum StatusKind { starting, thinking, working, done, error, idle }

class ContentStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final bool faint;
  final bool inverse;
  final String? color;
  final String? background;
  final double? fontSize;
  final bool monospace;

  const ContentStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.faint = false,
    this.inverse = false,
    this.color,
    this.background,
    this.fontSize,
    this.monospace = false,
  });
}

// ─── Structured input types ───────────────────────────────────────────

sealed class StructuredInput {
  const StructuredInput();
}

class StructuredUserMessage extends StructuredInput {
  final String content;
  final ExecutionMode? executionMode;
  const StructuredUserMessage({required this.content, this.executionMode});

  Map<String, dynamic> toJson() => {
    'type': 'message',
    'content': content,
    if (executionMode != null) 'executionMode': executionMode!.name,
  };
}

class StructuredInterrupt extends StructuredInput {
  const StructuredInterrupt();

  Map<String, dynamic> toJson() => const {'type': 'interrupt'};
}

// ─── Error response ───────────────────────────────────────────────────

class ErrorResponse {
  final String code;
  final String message;
  const ErrorResponse({required this.code, required this.message});

  factory ErrorResponse.fromJson(Map<String, dynamic> json) => ErrorResponse(
    code: json['code'] as String? ?? 'unknown',
    message: json['message'] as String? ?? '',
  );
}
