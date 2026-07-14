import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../extensions/loggable.dart';

/// Host-side alert channel: shows a system notification.
class NotificationService with Loggable {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Stable ids so a fresh alert of each kind replaces its predecessor in the
  /// notification centre instead of stacking.
  static const int timerId = 1;
  static const int reminderId = 2;

  bool _ready = false;

  @override
  String get logIdentifier => '[NotificationService]';

  /// Wire up the plugin for the current desktop platform.
  Future<void> init() async {
    try {
      const settings = InitializationSettings(
        linux: LinuxInitializationSettings(defaultActionName: 'Open'),
        macOS: DarwinInitializationSettings(),
        windows: WindowsInitializationSettings(
          appName: 'NanoDash',
          appUserModelId: 'lokxy.NanoDash',
          guid: '70357334-f8e8-481b-a1a8-640740d4cc51',
        ),
      );
      await _plugin.initialize(settings: settings);
      _ready = true;
    } catch (e, s) {
      logWarning(
        'notification init failed; host alerts will be silent',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Desktop notifications need no runtime permission gesture.
  Future<bool> requestPermission() async => _ready;

  Future<void> notify({
    required String title,
    required String body,
    int id = timerId,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body.isEmpty ? null : body,
        notificationDetails: _details,
      );
    } catch (e, s) {
      logWarning('notification show failed', error: e, stackTrace: s);
    }
  }

  static const NotificationDetails _details = NotificationDetails(
    linux: LinuxNotificationDetails(),
    macOS: DarwinNotificationDetails(),
    windows: WindowsNotificationDetails(),
  );
}
