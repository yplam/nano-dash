import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../widgets/panel_text.dart';
import '../models/pomodoro_log.dart';

/// `Hh Mm` past an hour, otherwise `Mm` — a compact focus total for a row.
String _formatFocus(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return h > 0 ? '${h}h ${m}m' : '${m}m';
}

/// The Pomodoro statistics page: completed focus sessions grouped per task per
/// day, newest first. Reached from the timer list; tapping back returns to it.
class PomodoroStatsView extends StatelessWidget {
  const PomodoroStatsView({
    super.key,
    required this.logs,
    required this.onBack,
    required this.onClear,
  });

  final List<PomodoroLog> logs;
  final VoidCallback onBack;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final rows = aggregateDaily(logs);
    // Locale-aware date, e.g. "Jan 5" (en) or "1月5日" (zh), matching the clock.
    final localeName = Localizations.localeOf(context).toString();
    final dayFormat = DateFormat.MMMd(localeName);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(constraints.maxWidth, constraints.maxHeight);
        final inset = side * 0.16;
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: inset,
            vertical: side * 0.14,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  // Tapping the chevron or the title returns to the list.
                  Expanded(
                    child: InkResponse(
                      onTap: onBack,
                      radius: side * 0.08,
                      child: Row(
                        children: [
                          Icon(
                            Icons.chevron_left,
                            size: side * 0.09,
                            color: colors.onSurfaceVariant,
                          ),
                          Expanded(
                            child: Text(
                              l10n.timerStats,
                              textAlign: TextAlign.center,
                              style: panelFont(
                                side * 0.065,
                                600,
                                colors.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  InkResponse(
                    onTap: rows.isEmpty ? null : onClear,
                    radius: side * 0.08,
                    child: Icon(
                      Icons.delete_outline,
                      size: side * 0.08,
                      color: rows.isEmpty
                          ? colors.onSurface.withValues(alpha: 0.25)
                          : colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              SizedBox(height: side * 0.03),
              Expanded(
                child: rows.isEmpty
                    ? Center(
                        child: Text(
                          l10n.timerStatsEmpty,
                          style: panelFont(16, 500, colors.onSurfaceVariant),
                        ),
                      )
                    : ListView.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, _) =>
                            SizedBox(height: side * 0.025),
                        itemBuilder: (context, i) => _StatRow(
                          stat: rows[i],
                          colors: colors,
                          dayLabel: dayFormat.format(rows[i].day),
                          sessionsLabel: l10n.timerStatsSessions(
                            rows[i].sessions,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.stat,
    required this.colors,
    required this.dayLabel,
    required this.sessionsLabel,
  });

  final PomodoroDailyStat stat;
  final ColorScheme colors;
  final String dayLabel;
  final String sessionsLabel;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colors.surface.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: panelFont(15, 600, colors.onSurface),
                  ),
                  Text(
                    '$dayLabel · $sessionsLabel',
                    style: panelFont(12, 500, colors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatFocus(stat.focus),
              style: panelFont(16, 600, colors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
