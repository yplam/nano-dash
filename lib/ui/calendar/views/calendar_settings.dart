import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/models/calendar.dart';
import '../../../l10n/app_localizations.dart';

/// A rotating palette assigned to new feeds so events from different calendars
/// are visually distinct without asking the user to pick a colour.
const List<int> _kPalette = [
  0xFF2196F3, // blue
  0xFFE91E63, // pink
  0xFF4CAF50, // green
  0xFFFF9800, // orange
  0xFF9C27B0, // purple
  0xFF00BCD4, // cyan
];

/// Settings controls for the calendar module: the user's list of feeds. Each
/// row edits one feed's URL and optional label/credentials; feeds can be added,
/// removed, and toggled on/off. Edits are debounced, then the whole updated list
/// is handed back through [onConfigChanged].
class CalendarSettings extends StatefulWidget {
  const CalendarSettings({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
    this.sourceErrors = const {},
  });

  /// Seeds the controls; read once, in [initState].
  final CalendarConfig initialConfig;

  /// Called with the full updated config whenever the user edits a control.
  final ValueChanged<CalendarConfig> onConfigChanged;

  /// Latest per-source fetch failures, keyed by [CalendarSource.id]. A row whose
  /// id is present shows a warning affordance with the message.
  final Map<String, String> sourceErrors;

  @override
  State<CalendarSettings> createState() => _CalendarSettingsState();
}

class _CalendarSettingsState extends State<CalendarSettings> {
  late List<CalendarSource> _sources;
  late CalendarRange _range;
  Timer? _debounce;
  static const Duration _debounceDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _sources = List.of(widget.initialConfig.sources);
    _range = widget.initialConfig.range;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _commit({bool immediate = false}) {
    _debounce?.cancel();
    void emit() => widget.onConfigChanged(
          CalendarConfig(sources: List.of(_sources), range: _range),
        );
    if (immediate) {
      emit();
    } else {
      _debounce = Timer(_debounceDelay, emit);
    }
  }

  void _setRange(CalendarRange range) {
    if (range == _range) return;
    setState(() => _range = range);
    _commit(immediate: true);
  }

  void _add() {
    final color = _kPalette[_sources.length % _kPalette.length];
    setState(() {
      _sources = [
        ..._sources,
        CalendarSource(
          id: 'cal_${DateTime.now().microsecondsSinceEpoch}',
          url: '',
          color: color,
        ),
      ];
    });
    _commit(immediate: true);
  }

  void _remove(int index) {
    setState(() => _sources = [..._sources]..removeAt(index));
    _commit(immediate: true);
  }

  void _update(int index, CalendarSource next) {
    setState(() {
      _sources = [..._sources];
      _sources[index] = next;
    });
    _commit();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              l10n.calendarRangeTitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<CalendarRange>(
              segments: [
                ButtonSegment(
                  value: CalendarRange.today,
                  label: Text(l10n.calendarRangeToday),
                ),
                ButtonSegment(
                  value: CalendarRange.todayAndTomorrow,
                  label: Text(l10n.calendarRangeTodayTomorrow),
                ),
                ButtonSegment(
                  value: CalendarRange.all,
                  label: Text(l10n.calendarRangeAll),
                ),
              ],
              selected: {_range},
              onSelectionChanged: (s) => _setRange(s.first),
            ),
          ),
          const SizedBox(height: 12),
          if (_sources.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                l10n.calendarNoFeeds,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          for (var i = 0; i < _sources.length; i++)
            _SourceTile(
              key: ValueKey(_sources[i].id),
              source: _sources[i],
              l10n: l10n,
              error: widget.sourceErrors[_sources[i].id],
              onChanged: (next) => _update(i, next),
              onRemove: () => _remove(i),
            ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add),
              label: Text(l10n.calendarAddFeed),
            ),
          ),
        ],
      ),
    );
  }
}

/// One editable feed row: enable toggle, URL field, an expandable
/// label/credentials section, and a remove button.
class _SourceTile extends StatefulWidget {
  const _SourceTile({
    super.key,
    required this.source,
    required this.l10n,
    required this.onChanged,
    required this.onRemove,
    this.error,
  });

  final CalendarSource source;
  final AppLocalizations l10n;

  /// Message from the latest failed fetch of this feed, or null if it's fine.
  final String? error;

  final ValueChanged<CalendarSource> onChanged;
  final VoidCallback onRemove;

  @override
  State<_SourceTile> createState() => _SourceTileState();
}

class _SourceTileState extends State<_SourceTile> {
  late final TextEditingController _url;
  late final TextEditingController _label;
  late final TextEditingController _user;
  late final TextEditingController _pass;
  late final TextEditingController _proxy;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.source.url);
    _label = TextEditingController(text: widget.source.label);
    _user = TextEditingController(text: widget.source.username ?? '');
    _pass = TextEditingController(text: widget.source.password ?? '');
    _proxy = TextEditingController(text: widget.source.proxy ?? '');
    // Open the extra fields by default when credentials or a proxy are set.
    _expanded = (widget.source.username ?? '').isNotEmpty ||
        (widget.source.proxy ?? '').isNotEmpty;
  }

  @override
  void dispose() {
    _url.dispose();
    _label.dispose();
    _user.dispose();
    _pass.dispose();
    _proxy.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged(
      widget.source.copyWith(
        url: _url.text.trim(),
        label: _label.text.trim(),
        username: _user.text.trim(),
        password: _pass.text,
        proxy: _proxy.text.trim(),
      ),
    );
  }

  /// Show the latest fetch error for this feed in a dismissible dialog.
  void _showError() {
    final message = widget.error;
    if (message == null) return;
    final title = widget.source.label.isNotEmpty
        ? widget.source.label
        : widget.source.url;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: Text(title.isEmpty ? widget.l10n.calendarError : title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).okButtonLabel),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(widget.source.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _url,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: l10n.calendarFeedUrl,
                      hintText: l10n.calendarFeedUrlHint,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (_) => _emit(),
                  ),
                ),
                if (widget.error != null)
                  IconButton(
                    tooltip: widget.error,
                    icon: Icon(Icons.warning_amber_rounded,
                        color: colors.error),
                    onPressed: _showError,
                  ),
                Switch(
                  value: widget.source.enabled,
                  onChanged: (v) =>
                      widget.onChanged(widget.source.copyWith(enabled: v)),
                ),
                IconButton(
                  tooltip: l10n.calendarRemoveFeed,
                  icon: Icon(Icons.delete_outline, color: colors.error),
                  onPressed: widget.onRemove,
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                label: Text(l10n.calendarFeedOptions),
              ),
            ),
            if (_expanded) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: SegmentedButton<CalendarKind>(
                  segments: const [
                    ButtonSegment(
                      value: CalendarKind.ics,
                      label: Text('ICS'),
                    ),
                    ButtonSegment(
                      value: CalendarKind.caldav,
                      label: Text('CalDAV'),
                    ),
                  ],
                  selected: {widget.source.kind},
                  onSelectionChanged: (s) =>
                      widget.onChanged(widget.source.copyWith(kind: s.first)),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _label,
                decoration: InputDecoration(
                  labelText: l10n.calendarFeedLabel,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _emit(),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _user,
                      decoration: InputDecoration(
                        labelText: l10n.calendarFeedUsername,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => _emit(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _pass,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: l10n.calendarFeedPassword,
                        isDense: true,
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) => _emit(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _proxy,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: l10n.calendarFeedProxy,
                  hintText: l10n.calendarFeedProxyHint,
                  isDense: true,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (_) => _emit(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
