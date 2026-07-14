import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../domain/models/usage_monitor.dart';
import 'usage_monitor_provider.dart';

/// Reads usage from the undocumented `GET /backend-api/wham/usage` endpoint the
/// Codex CLI uses for its ChatGPT-subscription rate-limit display, reusing the
/// local Codex CLI login state (`${CODEX_HOME:-~/.codex}/auth.json`).
class CodexUsageMonitorProvider implements UsageMonitorQuotaProvider {
  const CodexUsageMonitorProvider();

  static const String _endpoint = 'https://chatgpt.com/backend-api/wham/usage';

  @override
  UsageMonitorProvider get provider => UsageMonitorProvider.codex;

  @override
  Future<UsageMonitorProviderData> fetch(Dio client) async {
    final auth = await _loadAuth();
    if (auth == null) return _err(UsageMonitorError.notSignedIn);
    if (auth.expiresAt != null && !auth.expiresAt!.isAfter(DateTime.now())) {
      return _err(UsageMonitorError.authExpired);
    }

    final Response<Object?> res;
    try {
      res = await client.getUri<Object?>(
        Uri.parse(_endpoint),
        options: Options(
          headers: {
            'Authorization': 'Bearer ${auth.accessToken}',
            'ChatGPT-Account-Id': auth.accountId,
            'User-Agent': 'codex_cli_rs',
          },
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
    final rateLimit = data['rate_limit'];
    if (rateLimit is! Map) return _err(UsageMonitorError.upstream);

    final windows = [
      ?_window(rateLimit['primary_window'], id: '5h', fallbackMins: 5 * 60),
      ?_window(
        rateLimit['secondary_window'],
        id: '7d',
        fallbackMins: 7 * 24 * 60,
      ),
    ];
    return UsageMonitorProviderData(
      provider: provider,
      windows: windows,
      fetchedAt: DateTime.now(),
    );
  }

  UsageMonitorProviderData _err(UsageMonitorError e) =>
      UsageMonitorProviderData.error(provider, e);

  UsageMonitorError? _errorForStatus(int? status) {
    if (status == null) return UsageMonitorError.network;
    if (status == 401 || status == 403) return UsageMonitorError.authExpired;
    if (status == 429) return UsageMonitorError.rateLimited;
    if (status >= 400) return UsageMonitorError.upstream;
    return null;
  }

  /// Read one `{ used_percent, limit_window_seconds, reset_at }` block into a
  /// [UsageMonitorWindow]. `reset_at` is unix **seconds**; [fallbackMins] is used when
  /// the endpoint omits the window length.
  UsageMonitorWindow? _window(
    Object? raw, {
    required String id,
    required int fallbackMins,
  }) {
    if (raw is! Map) return null;
    final used = raw['used_percent'];
    if (used is! num) return null;
    final resetAt = raw['reset_at'];
    final windowSecs = raw['limit_window_seconds'];
    return UsageMonitorWindow(
      id: id,
      usedPct: used.toDouble(),
      resetsAt: resetAt is num
          ? DateTime.fromMillisecondsSinceEpoch(resetAt.toInt() * 1000)
          : null,
      durationMins: windowSecs is num
          ? (windowSecs.toInt() / 60).round()
          : fallbackMins,
    );
  }

  /// Load the local Codex CLI token from `${CODEX_HOME:-~/.codex}/auth.json`.
  Future<_CodexAuth?> _loadAuth() async {
    final env = Platform.environment;
    final home =
        env['CODEX_HOME'] ??
        (env['HOME'] != null ? '${env['HOME']}/.codex' : null);
    if (home == null) return null;
    final file = File('$home/auth.json');
    if (!await file.exists()) return null;

    Object? decoded;
    try {
      decoded = jsonDecode(await file.readAsString());
    } catch (_) {
      return null;
    }
    if (decoded is! Map) return null;
    final tokens = decoded['tokens'];
    if (tokens is! Map) return null;

    final token = tokens['access_token'];
    final accountId = tokens['account_id'];
    if (token is! String || token.isEmpty) return null;
    if (accountId is! String || accountId.isEmpty) return null;

    return _CodexAuth(
      accessToken: token,
      accountId: accountId,
      expiresAt: _jwtExpiry(token),
    );
  }

  /// Best-effort `exp` claim (unix seconds → [DateTime]) from a JWT access
  /// token. Returns null for opaque/unparsable tokens, which callers then treat
  /// as non-expiring rather than rejecting outright.
  DateTime? _jwtExpiry(String token) {
    final parts = token.split('.');
    if (parts.length < 2) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map) return null;
      final exp = payload['exp'];
      if (exp is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(exp.toInt() * 1000);
    } catch (_) {
      return null;
    }
  }
}

/// The subset of the Codex CLI credential file we need.
class _CodexAuth {
  const _CodexAuth({
    required this.accessToken,
    required this.accountId,
    this.expiresAt,
  });

  final String accessToken;
  final String accountId;

  /// Absolute expiry, or null for "never expires" (treat as valid).
  final DateTime? expiresAt;
}
