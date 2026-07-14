import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/models/usage_monitor.dart';
import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_empty.dart';
import '../../widgets/panel_text.dart';
import '../../widgets/panel_theme.dart';
import '../cubit/usage_monitor_cubit.dart';

/// The usage monitor's LCD page: one translucent card per coding agent, each
/// showing its rolling rate-limit windows (5h / 7d) as a labelled bar meter
/// with the percent consumed and a reset countdown.
class UsageMonitorView extends StatefulWidget {
  const UsageMonitorView({super.key});

  @override
  State<UsageMonitorView> createState() => _UsageMonitorViewState();
}

class _UsageMonitorViewState extends State<UsageMonitorView> {
  late final UsageMonitorCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<UsageMonitorCubit>();
    _cubit.onViewActive();
  }

  @override
  void dispose() {
    _cubit.onViewInactive();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : constraints.maxHeight,
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : constraints.maxWidth,
        );
        return BlocBuilder<UsageMonitorCubit, UsageMonitorState>(
          builder: (context, state) => _body(context, side, state),
        );
      },
    );
  }

  Widget _body(BuildContext context, double side, UsageMonitorState state) {
    final l10n = AppLocalizations.of(context);
    final m = PanelTheme.metricsOf(context, side, shape: PanelShape.square);
    final usage = state.usage;

    if (usage == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (usage.isEmpty) {
      return PanelEmpty(
        side: side,
        icon: Icons.data_usage,
        label: l10n.usageMonitorEmpty,
      );
    }

    return SingleChildScrollView(
      padding: m.pageInset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < usage.length; i++) ...[
            if (i > 0) SizedBox(height: m.gap),
            _ProviderCard(side: side, usage: usage[i]),
          ],
        ],
      ),
    );
  }
}

/// One provider's card: a brand header over either its window meters or a muted
/// reason the meters are missing.
class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.side, required this.usage});

  final double side;
  final UsageMonitorProviderData usage;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final m = PanelTheme.metricsOf(context, side);

    return Material(
      color: colors.surface.withValues(alpha: m.cardAlpha),
      borderRadius: BorderRadius.circular(m.cardRadius),
      child: Padding(
        padding: m.cardPaddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  _iconFor(usage.provider),
                  size: side * 0.05,
                  color: colors.onSurface,
                ),
                SizedBox(width: side * 0.02),
                Text(
                  usage.provider.displayName,
                  style: panelFont(m.fontMd, m.weightBold, colors.onSurface),
                ),
              ],
            ),
            SizedBox(height: side * 0.02),
            if (!usage.isOk)
              _reason(context, m, _errorText(l10n, usage.error!))
            else if (usage.windows.isEmpty)
              _reason(context, m, l10n.usageMonitorNoData)
            else
              for (var i = 0; i < usage.windows.length; i++) ...[
                if (i > 0) SizedBox(height: side * 0.02),
                _WindowMeter(side: side, window: usage.windows[i]),
              ],
          ],
        ),
      ),
    );
  }

  Widget _reason(BuildContext context, PanelMetrics m, String text) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: side * 0.01),
      child: Text(
        text,
        style: panelFont(m.fontSm, m.weightRegular, colors.onSurfaceVariant),
      ),
    );
  }

  static IconData _iconFor(UsageMonitorProvider provider) => switch (provider) {
    UsageMonitorProvider.claude => Icons.auto_awesome,
    UsageMonitorProvider.codex => Icons.terminal,
  };

  static String _errorText(AppLocalizations l10n, UsageMonitorError error) =>
      switch (error) {
        UsageMonitorError.notSignedIn => l10n.usageMonitorNotSignedIn,
        UsageMonitorError.authExpired => l10n.usageMonitorAuthExpired,
        UsageMonitorError.rateLimited => l10n.usageMonitorRateLimited,
        UsageMonitorError.network => l10n.usageMonitorNetworkError,
        UsageMonitorError.upstream => l10n.usageMonitorUpstreamError,
        UsageMonitorError.unknown => l10n.usageMonitorUnknownError,
      };
}

/// One rolling window: its short id, a filled bar meter, the percent consumed,
/// and (when known) a reset countdown beneath.
class _WindowMeter extends StatelessWidget {
  const _WindowMeter({required this.side, required this.window});

  final double side;
  final UsageMonitorWindow window;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final m = PanelTheme.metricsOf(context, side);
    final pct = window.usedPct.clamp(0, 100).toDouble();
    final fill = _fillColor(colors, pct);
    final reset = _resetText(l10n, window.resetsAt);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            SizedBox(
              width: side * 0.07,
              child: Text(
                window.id,
                style: panelFont(
                  m.fontSm,
                  m.weightMedium,
                  colors.onSurfaceVariant,
                ),
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(side * 0.02),
                child: SizedBox(
                  height: side * 0.03,
                  child: Stack(
                    children: [
                      Container(
                        color: colors.onSurface.withValues(alpha: 0.12),
                      ),
                      FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: pct / 100,
                        child: Container(color: fill),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: side * 0.03),
            SizedBox(
              width: side * 0.11,
              child: Text(
                '${pct.round()}%',
                textAlign: TextAlign.right,
                style: panelFont(m.fontSm, m.weightBold, colors.onSurface),
              ),
            ),
          ],
        ),
        if (reset != null)
          Padding(
            padding: EdgeInsets.only(left: side * 0.07, top: side * 0.008),
            child: Text(
              reset,
              style: panelFont(
                m.fontXs,
                m.weightRegular,
                colors.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ),
      ],
    );
  }

  /// Green under 70%, amber under 90%, red at/above — a quick "how close to the
  /// limit" read, tinted toward the theme's error color at the top.
  static Color _fillColor(ColorScheme colors, double pct) {
    if (pct >= 90) return colors.error;
    if (pct >= 70) return Color.lerp(colors.primary, colors.error, 0.5)!;
    return colors.primary;
  }

  /// A locale-free reset countdown: `resets in 42m` / `2h12m` / `1d 4h`, or the
  /// "about to reset" phrasing once the window is due. Null hides the line.
  static String? _resetText(AppLocalizations l10n, DateTime? resetsAt) {
    if (resetsAt == null) return null;
    final diff = resetsAt.difference(DateTime.now());
    if (diff.isNegative || diff.inSeconds < 30)
      return l10n.usageMonitorResetsSoon;

    final String rel;
    if (diff.inHours < 1) {
      rel = '${diff.inMinutes}m';
    } else if (diff.inHours < 24) {
      rel = '${diff.inHours}h${diff.inMinutes.remainder(60)}m';
    } else {
      rel = '${diff.inDays}d ${diff.inHours.remainder(24)}h';
    }
    return l10n.usageMonitorResetsIn(rel);
  }
}
