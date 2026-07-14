import 'dart:async';

/// The one shared point between the (UI-free, app-scoped) agent and the LCD
/// carousel. The agent asks for a module to be shown by id; [DashboardCubit]
/// listens on [requests] and either jumps to that carousel page or brings the
/// module up as a transient page.
///
/// It also carries [displayable] — the ids the assistant is currently allowed
/// to show — so the `show_on_screen` tool can validate a request and describe
/// the choices without reaching into the UI layer. The cubit keeps this set in
/// sync with the module configuration.
class PanelDisplayController {
  final StreamController<String> _requests =
      StreamController<String>.broadcast();

  /// Module ids the assistant may show right now (visibility != off). Updated by
  /// [DashboardCubit] whenever the configuration changes.
  Set<String> displayable = const {};

  /// Show requests, oldest first. Broadcast so the cubit can (re)subscribe.
  Stream<String> get requests => _requests.stream;

  bool canShow(String moduleId) => displayable.contains(moduleId);

  /// Ask for [moduleId] to be shown on the LCD. A no-op reaches the cubit,
  /// which silently ignores ids that aren't currently displayable.
  void show(String moduleId) {
    if (!_requests.isClosed) _requests.add(moduleId);
  }

  void dispose() {
    unawaited(_requests.close());
  }
}
