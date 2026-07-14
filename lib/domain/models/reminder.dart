import 'dart:math' as math;

import 'json_model.dart';

/// One scheduled reminder: a line of text to announce at [dueAt]. Created by
/// the voice agent, persisted by `ReminderRepository`, and removed once fired
/// or cancelled.
class Reminder implements JsonModel {
  const Reminder({required this.id, required this.text, required this.dueAt});

  /// Persistence key for the reminder list.
  /// Read/written via `SettingsRepository.loadList`/`saveList`.
  static const String kKey = 'reminders_v1';

  /// Stable identifier, unique within the list.
  final String id;

  /// What to announce, as the user phrased it ("take the pizza out").
  final String text;

  /// When to announce it (local time).
  final DateTime dueAt;

  @override
  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'dueAt': dueAt.toIso8601String(),
  };

  factory Reminder.fromJson(Map<String, Object?> json) => Reminder(
    id: json['id'] as String? ?? newId(),
    text: json['text'] as String? ?? '',
    dueAt:
        DateTime.tryParse(json['dueAt'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// A fresh, collision-resistant id for a newly added reminder.
  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${math.Random().nextInt(0x10000).toRadixString(36)}';
}
