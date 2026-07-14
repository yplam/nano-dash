import 'package:flutter_local_notifications_web/flutter_local_notifications_web.dart';

import '../../extensions/loggable.dart';

/// Web [NotificationService]: the browser-backed counterpart to the desktop
/// implementation (see `notification_service_io.dart`). It talks to the
/// `flutter_local_notifications_web` plugin directly.
///
/// Two things gate a banner on web that don't apply on desktop: a service worker
/// must have registered ([init]), and the user must have granted the browser's
/// Notification permission.
class NotificationService with Loggable {
  NotificationService([WebFlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? WebFlutterLocalNotificationsPlugin();

  final WebFlutterLocalNotificationsPlugin _plugin;

  /// Ids kept in sync with the desktop implementation so callers can name the
  /// alert kind without a conditional import.
  static const int timerId = 1;
  static const int reminderId = 2;

  /// True once the service worker registered.
  bool _ready = false;

  @override
  String get logIdentifier => '[NotificationService]';

  /// Register the service worker the web plugin shows notifications through.
  Future<void> init() async {
    try {
      _ready = await _plugin.initialize() ?? false;
      if (!_ready) {
        logWarning('notification init failed; host alerts will be silent');
      }
    } catch (e, s) {
      logWarning(
        'notification init failed; host alerts will be silent',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Prompt for the browser's Notification permission, returning whether it is
  /// granted afterwards. Must be called synchronously from a user gesture (the
  /// timer-start tap) or the browser auto-rejects it; a previously denied
  /// permission resolves to `false` without re-prompting.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      return await _plugin.requestNotificationsPermission() ?? false;
    } catch (e, s) {
      logWarning(
        'notification permission request failed',
        error: e,
        stackTrace: s,
      );
      return false;
    }
  }

  /// Show (or replace) a browser notification.
  Future<void> notify({
    required String title,
    required String body,
    int id = timerId,
  }) async {
    if (!_ready) return;
    if (_plugin.permissionStatus != WebNotificationPermission.granted) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body.isEmpty ? null : body,
        notificationDetails: const WebNotificationDetails(),
      );
    } catch (e, s) {
      logWarning('notification show failed', error: e, stackTrace: s);
    }
  }
}
