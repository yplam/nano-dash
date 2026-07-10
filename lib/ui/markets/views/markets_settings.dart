import 'dart:async';

import 'package:flutter/material.dart';
import 'package:nano_dash/l10n/app_localizations.dart';

import '../../../../domain/models/markets.dart';

/// Settings control for the markets watchlist: a free-text box of tickers,
/// one per line or comma-separated.
class MarketsSettings extends StatefulWidget {
  const MarketsSettings({
    super.key,
    required this.initialConfig,
    required this.onConfigChanged,
  });

  /// The settings to seed the control with. Read once, in [initState]; later
  /// changes from the owner are ignored so they can't clobber in-progress edits.
  final MarketsConfig initialConfig;

  /// Called with the full updated config whenever the user pauses editing.
  final ValueChanged<MarketsConfig> onConfigChanged;

  @override
  State<MarketsSettings> createState() => _MarketsSettingsState();
}

class _MarketsSettingsState extends State<MarketsSettings> {
  late final TextEditingController _controller;

  late final TextEditingController _proxy;

  /// Hold off committing until the user pauses typing, so we don't refetch (and
  /// surface errors for) every half-typed ticker.
  Timer? _debounce;
  static const Duration _debounceDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: [for (final s in widget.initialConfig.symbols) s.symbol].join('\n'),
    );
    _proxy = TextEditingController(text: widget.initialConfig.proxy ?? '');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _proxy.dispose();
    super.dispose();
  }

  void _emit() {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      // Split on newlines and commas; blanks are dropped by fromTickers.
      final tickers = _controller.text.split(RegExp(r'[,\n]'));
      widget.onConfigChanged(
        MarketsConfig.fromTickers(tickers, proxy: _proxy.text.trim()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _controller,
            minLines: 3,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: l10n.marketsWatchlist,
              hintText: l10n.marketsWatchlistHint,
              helperText: l10n.marketsWatchlistHelp,
              helperMaxLines: 8,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _proxy,
            keyboardType: TextInputType.url,
            decoration: InputDecoration(
              labelText: l10n.marketsProxyYahoo,
              hintText: l10n.marketsProxyHint,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => _emit(),
          ),
        ],
      ),
    );
  }
}
