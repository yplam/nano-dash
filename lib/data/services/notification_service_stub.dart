class NotificationService {
  NotificationService();

  static const int timerId = 1;
  static const int reminderId = 2;

  Future<void> init() async {}

  Future<bool> requestPermission() async => false;

  Future<void> notify({
    required String title,
    required String body,
    int id = timerId,
  }) async {}
}
