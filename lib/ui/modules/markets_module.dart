import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../markets/markets.dart';

/// The markets page: a live watchlist of stocks, indices, crypto, and FX with
/// price, session change, and a day-range bar.
class MarketsModule extends Module {
  const MarketsModule();

  static const String kId = 'markets';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.show_chart;

  @override
  String title(AppLocalizations l10n) => l10n.moduleMarketsTitle;

  @override
  bool get hasSettings => true;

  @override
  Widget build(BuildContext context, ModuleSettings settings) =>
      const MarketsDetailView();

  @override
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) {
    final l10n = AppLocalizations.of(context);
    return BlocConsumer<MarketsCubit, MarketsState>(
      listenWhen: (prev, curr) =>
          curr.error != null && !identical(curr.error, prev.error),
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(SnackBar(content: Text(l10n.marketsFetchFailed)));
      },
      builder: (context, state) => MarketsSettings(
        initialConfig: state.config,
        onConfigChanged: (config) =>
            context.read<MarketsCubit>().setConfig(config),
      ),
    );
  }
}
