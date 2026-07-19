import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../radar/radar.dart';

/// Live flight radar: a pure ATC scope with aircraft plotted around a chosen
/// point, plus an optional RainViewer rain overlay. Both layers are optional.
class RadarModule extends Module {
  const RadarModule();

  static const String kId = 'radar';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.radar;

  @override
  String title(AppLocalizations l10n) => l10n.moduleRadarTitle;

  @override
  bool get hasSettings => true;

  @override
  Widget build(BuildContext context, ModuleSettings settings) =>
      const RadarView();

  @override
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) {
    return BlocBuilder<RadarCubit, RadarState>(
      builder: (context, state) => RadarSettings(
        initialConfig: state.config,
        onConfigChanged: (config) =>
            context.read<RadarCubit>().setConfig(config),
      ),
    );
  }
}
