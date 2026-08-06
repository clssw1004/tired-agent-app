import 'package:flutter/material.dart';

import 'package:tired_agent_app/protocol/http_sse_transport.dart';
import 'package:tired_agent_app/theme.dart';
import 'package:tired_agent_app/utils/app_strings.dart';
import 'package:tired_agent_app/widgets/common/themed_text.dart';

/// UI-side result returned by the [ConnectionTestButton.test] callback.
///
/// Decoupled from [AgentConnectionTestResult] so the same button widget can
/// be reused by the manager form (which uses [HttpSseTransport.login] under
/// the hood) and the agent form (which uses `testAgentConnection`).
class ConnectionTestResult {
  /// Whether the probe succeeded.
  final bool ok;

  /// Optional success detail shown next to the "✓ 连接成功" line — typically
  /// the agent's name/version pair, or null for managers.
  final String? detail;

  /// Already-localized, user-facing error message; only set when [ok] is false.
  final String? error;

  const ConnectionTestResult._({required this.ok, this.detail, this.error});

  factory ConnectionTestResult.ok({String? detail}) =>
      ConnectionTestResult._(ok: true, detail: detail);

  factory ConnectionTestResult.fail(String error) =>
      ConnectionTestResult._(ok: false, error: error);
}

/// Maps the protocol-layer error tag from [describeTransportError] into a
/// localized message. Falls back to `失败：<raw>` for unrecognized shapes.
///
/// Categories recognized:
///   - `network:*`     → 无法连接服务器，请检查网络与 URL
///   - `http:401:*`    → 认证失败（401）——令牌可能无效
///   - `http:404:*`    → 地址不存在（404）——请检查 URL
///   - `http:5xx:*`    → 服务器错误（{code}）——请稍后重试
///   - anything else   → `失败：<raw>`
String renderTransportError(String encoded) {
  if (encoded.startsWith('network:')) {
    return AppStrings.of.testConnectionFailedNetwork;
  }
  if (encoded.startsWith('http:401:')) {
    return AppStrings.of.testConnectionFailed401;
  }
  if (encoded.startsWith('http:404:')) {
    return AppStrings.of.testConnectionFailed404;
  }
  final fiveXx = RegExp(r'^http:5\d\d:');
  if (fiveXx.hasMatch(encoded)) {
    final code = encoded.substring(5, 8);
    return AppStrings.of.testConnectionFailed5xx(code);
  }
  return AppStrings.of.testConnectionFailed(encoded);
}

/// "Test Connection" affordance used inside Add/Edit Manager and Add/Edit
/// Agent forms. Renders an OutlinedButton next to a status line that
/// reflects the latest probe (idle / testing / success / error).
///
/// The widget does not perform the probe itself — callers inject a
/// [test] callback so the form can keep ownership of its transport and any
/// per-form quirks (manager uses login, agent uses `testAgentConnection`).
class ConnectionTestButton extends StatefulWidget {
  const ConnectionTestButton({
    super.key,
    required this.url,
    required this.token,
    required this.test,
  });

  /// Reads the current URL value at click time. Closure over the form's
  /// controller keeps this widget controller-agnostic.
  final String Function() url;

  /// Reads the current token value at click time.
  final String Function() token;

  /// Performs the probe and returns a UI-ready result.
  final Future<ConnectionTestResult> Function(String url, String token) test;

  @override
  State<ConnectionTestButton> createState() => _ConnectionTestButtonState();
}

enum _Status { idle, testing, success, error }

class _ConnectionTestButtonState extends State<ConnectionTestButton> {
  _Status _status = _Status.idle;
  String? _message;

  Future<void> _run() async {
    final url = widget.url().trim();
    final token = widget.token().trim();
    if (url.isEmpty || token.isEmpty) {
      setState(() {
        _status = _Status.error;
        _message = AppStrings.of.testConnectionNeedUrlToken;
      });
      return;
    }

    setState(() {
      _status = _Status.testing;
      _message = null;
    });
    try {
      final result = await widget.test(url, token);
      if (!mounted) return;
      setState(() {
        if (result.ok) {
          _status = _Status.success;
          _message = result.detail;
        } else {
          _status = _Status.error;
          _message = result.error;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _Status.error;
        _message = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final testing = _status == _Status.testing;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: testing ? null : _run,
          icon: testing
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_tethering, size: 16),
          label: Text(AppStrings.of.testConnection),
          style: OutlinedButton.styleFrom(
            foregroundColor: c.primary,
            side: BorderSide(color: c.primary.withAlpha(120), width: 0.8),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.three,
              vertical: AppSpacing.two,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
            textStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.two),
        Expanded(child: _buildStatus(c)),
      ],
    );
  }

  Widget _buildStatus(AppColors c) {
    switch (_status) {
      case _Status.idle:
        return const SizedBox.shrink();
      case _Status.testing:
        return ThemedText.small(
          AppStrings.of.testConnectionTesting,
          color: c.textSecondary,
        );
      case _Status.success:
        final text = _message == null
            ? AppStrings.of.testConnectionSuccess
            : '${AppStrings.of.testConnectionSuccess} · $_message';
        return ThemedText.small(
          text,
          color: c.success,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        );
      case _Status.error:
        return ThemedText.small(
          _message ?? AppStrings.of.testConnectionFailed(''),
          color: c.danger,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        );
    }
  }
}
