import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pico_view/pico_view.dart';

import '../../data/services/pico_view_service.dart';
import '../../domain/models/app_config.dart';
import '../../domain/models/dashboard.dart';
import '../../domain/models/module.dart';
import '../../l10n/app_localizations.dart';
import '../settings/cubit/app_config_cubit.dart';
import '../settings/views/firmware_update_tile.dart';
import '../settings/views/settings_view.dart';

/// A settings-only module.
class SettingsModule extends Module {
  const SettingsModule();

  static const String kId = 'app_settings';

  @override
  String get id => kId;

  @override
  IconData get icon => Icons.settings;

  @override
  String title(AppLocalizations l10n) => l10n.moduleSettingsTitle;

  @override
  bool get hasDisplay => false;

  @override
  bool get hasSettings => true;

  @override
  ModuleSettings get defaultSettings => const {};

  @override
  Widget buildSettings(
    BuildContext context,
    ModuleSettings settings,
    ValueChanged<ModuleSettings> onChanged,
  ) {
    final service = context.read<PicoViewService>();
    return BlocBuilder<AppConfigCubit, AppConfig>(
      builder: (context, config) => StreamBuilder<PicoLinkState>(
        // Rebuild on connect/disconnect so the hardware-only controls appear and
        // disappear as the panel is plugged in or removed while Settings is open.
        stream: service.linkStates,
        builder: (context, _) => SettingsView(
          config: config,
          onChanged: (next) => context.read<AppConfigCubit>().update(next),
          deviceConnected: service.isOpen,
          // Play the chosen alert on the panel so it can be felt as it's picked.
          onPreviewEffect: (effect) => service.playHaptic(effect),
          advanced: kIsWeb ? null : FirmwareUpdateTile(service: service),
        ),
      ),
    );
  }
}
