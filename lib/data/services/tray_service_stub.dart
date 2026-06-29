import '../../l10n/app_localizations.dart';

/// Web [TrayService]: a no-op stub.
class TrayService {
  TrayService();

  Future<void> init(AppLocalizations l10n) async {}

  Future<void> show() async {}

  Future<void> hide() async {}

  Future<void> quit() async {}

  void dispose() {}
}
