import 'package:dio/dio.dart';

import '../../../domain/models/usage_monitor.dart';

/// A source of live [UsageMonitorProviderData] for one coding agent, kept behind an
/// interface so a new provider can be added without touching the service or cubit.
abstract class UsageMonitorQuotaProvider {
  UsageMonitorProvider get provider;

  /// Fetch usage over [client] (already routed through any configured proxy).
  Future<UsageMonitorProviderData> fetch(Dio client);
}
