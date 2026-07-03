part of 'calendar_cubit.dart';

/// View state for the calendar module.
class CalendarState {
  const CalendarState({
    this.sources = const [],
    this.range = CalendarRange.all,
    this.events = const [],
    this.loading = false,
    this.error,
    this.sourceErrors = const {},
  });

  /// The configured feeds (persisted).
  final List<CalendarSource> sources;

  /// How far ahead the agenda lists events (persisted display filter).
  final CalendarRange range;

  /// Merged, start-sorted events across all enabled feeds.
  final List<CalendarEvent> events;
  final bool loading;

  /// The error from the most recent fetch when it left nothing to show, or
  /// `null` otherwise.
  final Object? error;

  /// Per-source fetch failures from the most recent poll, keyed by
  /// [CalendarSource.id] with a human-readable message.
  final Map<String, String> sourceErrors;

  CalendarState copyWith({
    List<CalendarSource>? sources,
    CalendarRange? range,
    List<CalendarEvent>? events,
    bool? loading,
    Object? error,
    bool clearError = false,
    Map<String, String>? sourceErrors,
  }) {
    return CalendarState(
      sources: sources ?? this.sources,
      range: range ?? this.range,
      events: events ?? this.events,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      sourceErrors: sourceErrors ?? this.sourceErrors,
    );
  }
}
