import 'package:dio/dio.dart';

import '../../../domain/models/usage_monitor.dart';
import '../http_proxy_stub.dart' if (dart.library.io) '../http_proxy_io.dart';
import 'claude_usage_monitor_provider.dart';
import 'codex_usage_monitor_provider.dart';
import 'usage_monitor_provider.dart';

/// Fetches rolling rate-limit usage for the enabled coding agents.
class UsageMonitorService {
  UsageMonitorService(
    this._dio, {
    List<UsageMonitorQuotaProvider> providers = const [
      ClaudeUsageMonitorProvider(),
      CodexUsageMonitorProvider(),
    ],
  }) : _providers = {for (final p in providers) p.provider: p};

  final Dio _dio;
  final Map<UsageMonitorProvider, UsageMonitorQuotaProvider> _providers;

  /// Fetch every provider [config] has enabled, preserving [UsageMonitorProvider]
  /// declaration order.
  Future<List<UsageMonitorProviderData>> fetch(
    UsageMonitorConfig config,
  ) async {
    final wanted = [
      for (final p in UsageMonitorProvider.values)
        if (config.enabled(p) && _providers.containsKey(p)) p,
    ];
    return Future.wait([for (final p in wanted) _fetchOne(p, config)]);
  }

  Future<UsageMonitorProviderData> _fetchOne(
    UsageMonitorProvider p,
    UsageMonitorConfig config,
  ) async {
    final provider = _providers[p]!;
    final client = _clientFor(config.proxyFor(p));
    try {
      return await provider.fetch(client);
    } catch (_) {
      return UsageMonitorProviderData.error(p, UsageMonitorError.unknown);
    } finally {
      if (!identical(client, _dio)) client.close();
    }
  }

  Dio _clientFor(String? proxy) {
    if (proxy == null) return _dio;
    final adapter = proxyAdapter(proxy);
    if (adapter == null) return _dio;
    return Dio(_dio.options)..httpClientAdapter = adapter;
  }
}
