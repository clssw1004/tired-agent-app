/// URL helpers for tired-agent servers.
/// Pure Dart mirror of `@tired-agent/protocol` constants.
library;

/// Strip surrounding whitespace and trailing slashes from a base URL.
String normalizeBaseUrl(String url) =>
    url.trim().replaceAll(RegExp(r'/+$'), '');
