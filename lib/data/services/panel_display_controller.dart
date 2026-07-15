import 'dart:async';

/// A request from the agent to put a module on the LCD. [sticky] asks the
/// carousel to land on the page and stay (for an explicit action, like starting
/// a timer, where returning would hide what the user just changed); otherwise
/// the page is shown transiently and returns after a swipe or a short idle.
typedef PanelShowRequest = ({String moduleId, bool sticky});

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
  final StreamController<PanelShowRequest> _requests =
      StreamController<PanelShowRequest>.broadcast();

  /// Module ids the assistant may show right now (visibility != off). Updated by
  /// [DashboardCubit] whenever the configuration changes.
  Set<String> displayable = const {};

  /// Show requests, oldest first. Broadcast so the cubit can (re)subscribe.
  Stream<PanelShowRequest> get requests => _requests.stream;

  bool canShow(String moduleId) => displayable.contains(moduleId);

  /// Ask for [moduleId] to be shown transiently on the LCD — it returns to the
  /// previous page on a swipe or after a short idle. A no-op reaches the cubit,
  /// which silently ignores ids that aren't currently displayable.
  void show(String moduleId) {
    if (!_requests.isClosed) _requests.add((moduleId: moduleId, sticky: false));
  }

  /// Ask the carousel to land on [moduleId] and stay there — for an explicit
  /// action (e.g. starting a timer) where the changed page is what the user
  /// wants to keep seeing. The cubit falls back to a transient [show] for a
  /// module that has no carousel page to stay on.
  void goTo(String moduleId) {
    if (!_requests.isClosed) _requests.add((moduleId: moduleId, sticky: true));
  }

  void dispose() {
    unawaited(_requests.close());
  }
}
