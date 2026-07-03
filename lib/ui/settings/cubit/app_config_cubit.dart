import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/repositories/settings_repository.dart';
import '../../../domain/models/app_config.dart';
import '../../../extensions/loggable.dart';

/// Owns the app-wide [AppConfig] (background, language, theme seed).
class AppConfigCubit extends Cubit<AppConfig> with Loggable {
  AppConfigCubit(this._repository) : super(_repository.load(appConfigKey));

  final SettingsRepository _repository;

  @override
  String get logIdentifier => '[AppConfigCubit]';

  void update(AppConfig config) {
    if (config == state) return;
    emit(config);
    _repository.save(appConfigKey, config).catchError((Object e, StackTrace s) {
      logError('failed to persist app config', error: e, stackTrace: s);
    });
  }
}
