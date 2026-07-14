import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../domain/models/usage_monitor.dart';
import 'usage_monitor_provider.dart';

/// Reads usage from Claude Code's undocumented `GET /api/oauth/usage` endpoint,
/// reusing the local Claude Code OAuth login state.
class ClaudeUsageMonitorProvider implements UsageMonitorQuotaProvider {
  const ClaudeUsageMonitorProvider();

  static const String _endpoint = 'https://api.anthropic.com/api/oauth/usage';
  static const String _betaHeader = 'oauth-2025-04-20';

  /// Both scopes must be present or the usage endpoint rejects the token.
  static const List<String> _requiredScopes = [
    'user:profile',
    'user:inference',
  ];

  @override
  UsageMonitorProvider get provider => UsageMonitorProvider.claude;

  @override
  Future<UsageMonitorProviderData> fetch(Dio client) async {
    final auth = await _loadAuth();
    if (auth == null) return _err(UsageMonitorError.notSignedIn);
    if (auth.expiresAt != null && !auth.expiresAt!.isAfter(DateTime.now())) {
      return _err(UsageMonitorError.authExpired);
    }
    if (!_hasRequiredScopes(auth)) return _err(UsageMonitorError.notSignedIn);

    final Response<Object?> res;
    try {
      res = await client.getUri<Object?>(
        Uri.parse(_endpoint),
        options: Options(
          headers: {
            'Authorization': 'Bearer ${auth.accessToken}',
            'anthropic-beta': _betaHeader,
            'Content-Type': 'application/json',
          },
          // Read every status so we can map it; Dio otherwise throws on 4xx/5xx.
          validateStatus: (_) => true,
        ),
      );
    } on DioException {
      return _err(UsageMonitorError.network);
    }

    final mapped = _errorForStatus(res.statusCode);
    if (mapped != null) return _err(mapped);

    final data = res.data;
    if (data is! Map) return _err(UsageMonitorError.upstream);

    final windows = [
      ?_window(data['five_hour'], id: '5h', durationMins: 5 * 60),
      ?_window(data['seven_day'], id: '7d', durationMins: 7 * 24 * 60),
    ];
    return UsageMonitorProviderData(
      provider: provider,
      windows: windows,
      fetchedAt: DateTime.now(),
    );
  }

  UsageMonitorProviderData _err(UsageMonitorError e) =>
      UsageMonitorProviderData.error(provider, e);

  /// Map an HTTP status to a [UsageMonitorError], or null when the response is OK.
  UsageMonitorError? _errorForStatus(int? status) {
    if (status == null) return UsageMonitorError.network;
    if (status == 401 || status == 403) return UsageMonitorError.authExpired;
    if (status == 429) return UsageMonitorError.rateLimited;
    if (status >= 400) return UsageMonitorError.upstream;
    return null;
  }

  /// Read one `{ utilization, resets_at }` block into a [UsageMonitorWindow], or null
  /// when the block is missing or lacks a numeric utilization.
  UsageMonitorWindow? _window(
    Object? raw, {
    required String id,
    required int durationMins,
  }) {
    if (raw is! Map) return null;
    final util = raw['utilization'];
    if (util is! num) return null;
    final resetsAt = raw['resets_at'];
    return UsageMonitorWindow(
      id: id,
      usedPct: util.toDouble(),
      resetsAt: resetsAt is String ? DateTime.tryParse(resetsAt) : null,
      durationMins: durationMins,
    );
  }

  bool _hasRequiredScopes(_ClaudeAuth auth) {
    final scopes = auth.scopes;
    if (scopes == null) return false;
    return _requiredScopes.every(scopes.contains);
  }

  /// Load the local Claude Code OAuth token. Linux/desktop keeps it in a plain
  /// file at `~/.claude/.credentials.json`; on macOS it lives in the Keychain,
  /// which we don't read here, so that platform reports "not signed in".
  Future<_ClaudeAuth?> _loadAuth() async {
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return null;
    final file = File('$home/.claude/.credentials.json');
    if (!await file.exists()) return null;

    Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;
    final oauth = decoded['claudeAiOauth'];
    if (oauth is! Map) return null;

    final token = oauth['accessToken'];
    if (token is! String || token.isEmpty) return null;

    final expiresAt = oauth['expiresAt'];
    final scopes = oauth['scopes'];
    return _ClaudeAuth(
      accessToken: token,
      expiresAt: expiresAt is num
          ? DateTime.fromMillisecondsSinceEpoch(expiresAt.toInt())
          : null,
      scopes: scopes is List ? scopes.whereType<String>().toList() : null,
    );
  }
}

/// The subset of the Claude Code credential file we need.
class _ClaudeAuth {
  const _ClaudeAuth({required this.accessToken, this.expiresAt, this.scopes});

  final String accessToken;

  /// Absolute expiry, or null for "never expires" (treat as valid).
  final DateTime? expiresAt;
  final List<String>? scopes;
}
