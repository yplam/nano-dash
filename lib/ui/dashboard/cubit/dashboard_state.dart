part of 'dashboard_cubit.dart';

/// View state for the dashboard. [items] holds every known module in display
/// order (enabled and disabled); [currentPage] is the active LCD page index
/// into [enabledItems].
class DashboardState {
  const DashboardState({
    this.items = const [],
    this.currentPage = 0,
    this.forward = true,
  });

  final List<DashItemConfig> items;
  final int currentPage;

  /// Direction of the most recent page change, used to pick the LCD slide
  /// direction: `true` = moved to a *next* page (slide content left), `false` =
  /// moved to a *previous* page (slide content right).
  final bool forward;

  /// The enabled subset, in display order — what the LCD carousel shows.
  List<DashItemConfig> get enabledItems =>
      items.where((i) => i.enabled).toList(growable: false);

  DashboardState copyWith({
    List<DashItemConfig>? items,
    int? currentPage,
    bool? forward,
  }) {
    return DashboardState(
      items: items ?? this.items,
      currentPage: currentPage ?? this.currentPage,
      forward: forward ?? this.forward,
    );
  }
}
