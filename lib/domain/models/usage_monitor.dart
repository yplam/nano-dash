import 'json_model.dart';

/// A coding-agent subscription whose rolling rate-limit usage we mirror. Each
/// provider reuses the local CLI's login state and calls that vendor's
/// undocumented usage endpoint — see the services under
/// `data/services/usage_monitor/`.
enum UsageMonitorProvider {
  claude('claude', 'Claude'),
  codex('codex', 'Codex');

  const UsageMonitorProvider(this.id, this.displayName);

  /// Stable JSON discriminator / settings sub-key.
  final String id;

  /// Brand name shown on the card header.
  final String displayName;
}

enum UsageMonitorError {
  /// No local CLI login state found (or it's missing the required scopes).
  notSignedIn,

  /// Credentials found but expired; the user must re-login with the CLI.
  authExpired,

  /// The endpoint is rate-limiting us; back off and retry later.
  rateLimited,

  /// Couldn't reach the endpoint at all.
  network,

  /// The endpoint answered, but not with something we could use.
  upstream,
  unknown,
}

/// One rolling rate-limit window for a provider. Not persisted — produced fresh on every poll.
class UsageMonitorWindow {
  const UsageMonitorWindow({
    required this.id,
    required this.usedPct,
    this.resetsAt,
    required this.durationMins,
  });

  /// Short window key, `'5h'` or `'7d'`, used for the row label.
  final String id;

  /// Percent of the window consumed, 0–100.
  final double usedPct;

  /// When the window rolls over, if the endpoint reported it.
  final DateTime? resetsAt;

  /// Nominal window length in minutes (5h = 300, 7d = 10080).
  final int durationMins;
}

/// A provider's slice of the page: either its live [windows] or an [error]
/// explaining why there are none.
class UsageMonitorProviderData {
  const UsageMonitorProviderData({
    required this.provider,
    this.windows = const [],
    this.error,
    required this.fetchedAt,
  });

  UsageMonitorProviderData.error(
    this.provider,
    this.error, {
    DateTime? fetchedAt,
  }) : windows = const [],
       fetchedAt = fetchedAt ?? DateTime.now();

  final UsageMonitorProvider provider;
  final List<UsageMonitorWindow> windows;
  final UsageMonitorError? error;
  final DateTime fetchedAt;

  bool get isOk => error == null;
}

/// Persisted configuration for the usage monitor: whether each provider is
/// enabled and its optional proxy.
class UsageMonitorConfig implements JsonModel {
  const UsageMonitorConfig({
    this.claudeEnabled = true,
    this.claudeProxy,
    this.codexEnabled = true,
    this.codexProxy,
  });

  final bool claudeEnabled;
  final String? claudeProxy;
  final bool codexEnabled;
  final String? codexProxy;

  /// Whether [provider] is switched on.
  bool enabled(UsageMonitorProvider provider) => switch (provider) {
    UsageMonitorProvider.claude => claudeEnabled,
    UsageMonitorProvider.codex => codexEnabled,
  };

  /// The usable proxy for [provider], or null to connect direct. Blank strings
  /// normalize to null so an empty field and an absent one read the same.
  String? proxyFor(UsageMonitorProvider provider) {
    final raw = switch (provider) {
      UsageMonitorProvider.claude => claudeProxy,
      UsageMonitorProvider.codex => codexProxy,
    };
    final p = raw?.trim() ?? '';
    return p.isEmpty ? null : p;
  }

  UsageMonitorConfig copyWith({
    bool? claudeEnabled,
    String? claudeProxy,
    bool? codexEnabled,
    String? codexProxy,
  }) => UsageMonitorConfig(
    claudeEnabled: claudeEnabled ?? this.claudeEnabled,
    claudeProxy: claudeProxy ?? this.claudeProxy,
    codexEnabled: codexEnabled ?? this.codexEnabled,
    codexProxy: codexProxy ?? this.codexProxy,
  );

  factory UsageMonitorConfig.fromJson(Map<String, Object?> json) =>
      UsageMonitorConfig(
        claudeEnabled: json['claudeEnabled'] as bool? ?? true,
        claudeProxy: json['claudeProxy'] as String?,
        codexEnabled: json['codexEnabled'] as bool? ?? true,
        codexProxy: json['codexProxy'] as String?,
      );

  @override
  Map<String, Object?> toJson() => {
    'claudeEnabled': claudeEnabled,
    'claudeProxy': ?proxyFor(UsageMonitorProvider.claude),
    'codexEnabled': codexEnabled,
    'codexProxy': ?proxyFor(UsageMonitorProvider.codex),
  };

  @override
  bool operator ==(Object other) =>
      other is UsageMonitorConfig &&
      other.claudeEnabled == claudeEnabled &&
      other.proxyFor(UsageMonitorProvider.claude) ==
          proxyFor(UsageMonitorProvider.claude) &&
      other.codexEnabled == codexEnabled &&
      other.proxyFor(UsageMonitorProvider.codex) ==
          proxyFor(UsageMonitorProvider.codex);

  @override
  int get hashCode => Object.hash(
    claudeEnabled,
    proxyFor(UsageMonitorProvider.claude),
    codexEnabled,
    proxyFor(UsageMonitorProvider.codex),
  );
}

const usageMonitorSettingsKey = SettingKey<UsageMonitorConfig>(
  'usage_monitor_config_v1',
  UsageMonitorConfig.fromJson,
  defaults: UsageMonitorConfig(),
);
