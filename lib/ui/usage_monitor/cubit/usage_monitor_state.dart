part of 'usage_monitor_cubit.dart';

/// View state for the usage monitor.
class UsageMonitorState {
  const UsageMonitorState({
    required this.config,
    this.usage,
    this.loading = false,
  });

  final UsageMonitorConfig config;

  /// The most recent per-provider usage, or null before the first fetch.
  final List<UsageMonitorProviderData>? usage;

  final bool loading;

  UsageMonitorState copyWith({
    UsageMonitorConfig? config,
    List<UsageMonitorProviderData>? usage,
    bool? loading,
  }) => UsageMonitorState(
    config: config ?? this.config,
    usage: usage ?? this.usage,
    loading: loading ?? this.loading,
  );
}
