part of 'dashboard_cubit.dart';

/// View state for the dashboard. [items] holds every known module in display
/// order (enabled and disabled); [currentPage] is the active LCD page index
/// into [enabledItems].
class DashboardState {
  const DashboardState({
    this.items = const [],
    this.currentPage = 0,
    this.forward = true,
    this.tempModuleId,
    this.tempReturnPage,
  });

  final List<DashboardItemConfig> items;
  final int currentPage;

  /// Direction of the most recent page change, used to pick the LCD slide
  /// direction: `true` = moved to a *next* page (slide content left), `false` =
  /// moved to a *previous* page (slide content right).
  final bool forward;

  /// The assistant-shown transient page, if any: a module that is *not* part of
  /// the carousel rotation, displayed over it until a swipe or a timeout returns
  /// to [tempReturnPage]. Null when no transient page is showing.
  final String? tempModuleId;

  /// The carousel page index to restore when the transient page is dismissed.
  final int? tempReturnPage;

  /// Whether a transient (assistant-shown) page is currently displayed.
  bool get showingTemp => tempModuleId != null;

  /// The enabled subset, in display order — what the LCD carousel shows.
  List<DashboardItemConfig> get enabledItems =>
      items.where((i) => i.enabled).toList(growable: false);

  DashboardState copyWith({
    List<DashboardItemConfig>? items,
    int? currentPage,
    bool? forward,
  }) {
    return DashboardState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      forward: forward ?? this.forward,
      // Transient state is deliberately not carried by copyWith: it is set and
      // cleared through explicit emits in the cubit, never inherited.
      tempModuleId: null,
      tempReturnPage: null,
    );
  }

  /// A copy showing [moduleId] as the transient page, returning to
  /// [returnPage] when dismissed.
  DashboardState withTemp(String moduleId, int returnPage) {
    return DashboardState(
      items: items,
      currentPage: currentPage,
      forward: true,
      tempModuleId: moduleId,
      tempReturnPage: returnPage,
    );
  }
}
