import 'dart:convert';
import 'package:flutter/material.dart';
import 'event_tag.dart';
import 'recurrence_rule.dart';
import 'reminder_settings.dart';

/// Priority levels for events, each with an associated color and label.
enum EventPriority {
  low,
  medium,
  high,
  urgent;

  /// Display label for the priority.
  String get label {
    switch (this) {
      case EventPriority.low:
        return 'Low';
      case EventPriority.medium:
        return 'Medium';
      case EventPriority.high:
        return 'High';
      case EventPriority.urgent:
        return 'Urgent';
    }
  }

  /// Color associated with this priority level.
  Color get color {
    switch (this) {
      case EventPriority.low:
        return Colors.green;
      case EventPriority.medium:
        return Colors.orange;
      case EventPriority.high:
        return Colors.deepOrange;
      case EventPriority.urgent:
        return Colors.red;
    }
  }

  /// Icon associated with this priority level.
  IconData get icon {
    switch (this) {
      case EventPriority.low:
        return Icons.arrow_downward;
      case EventPriority.medium:
        return Icons.remove;
      case EventPriority.high:
        return Icons.arrow_upward;
      case EventPriority.urgent:
        return Icons.priority_high;
    }
  }

  /// Converts a stored string back to an [EventPriority].
  static EventPriority fromString(String value) {
    return EventPriority.values.firstWhere(
      (p) => p.name == value,
      orElse: () => EventPriority.medium,
    );
  }
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final EventPriority priority;
  final List<EventTag> tags;
  final RecurrenceRule? recurrence;
  final ReminderSettings reminders;

  EventModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.priority = EventPriority.medium,
    List<EventTag>? tags,
    this.recurrence,
    ReminderSettings? reminders,
  })  : tags = tags ?? const [],
        reminders = reminders ?? const ReminderSettings();

  /// Whether this event has a recurrence rule.
  bool get isRecurring => recurrence != null;

  /// Generates future occurrences of this recurring event as new [EventModel]s.
  ///
  /// Each generated occurrence gets a derived ID (originalId_N) and shifted date.
  /// Returns an empty list if the event is not recurring.
  List<EventModel> generateOccurrences({int maxOccurrences = 52}) {
    if (recurrence == null) return [];
    final dates = recurrence!.generateOccurrences(date, maxOccurrences: maxOccurrences);
    // Skip the first date (it's the original event)
    return dates.skip(1).toList().asMap().entries.map((entry) {
      return copyWith(
        id: '${id}_${entry.key + 1}',
        date: entry.value,
      );
    }).toList();
  }

  // Factory method to create an EventModel from JSON
  factory EventModel.fromJson(Map<String, dynamic> json) {
    List<EventTag> parsedTags = const [];
    final tagsRaw = json['tags'];
    if (tagsRaw is String && tagsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(tagsRaw) as List<dynamic>;
        parsedTags = decoded
            .map((t) => EventTag.fromJson(t as Map<String, dynamic>))
            .toList();
      } catch (_) {
        // Ignore malformed tags JSON
      }
    } else if (tagsRaw is List) {
      parsedTags = tagsRaw
          .map((t) => EventTag.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    RecurrenceRule? parsedRecurrence;
    final recurrenceRaw = json['recurrence'];
    if (recurrenceRaw is String && recurrenceRaw.isNotEmpty) {
      parsedRecurrence = RecurrenceRule.fromJsonString(recurrenceRaw);
    } else if (recurrenceRaw is Map<String, dynamic>) {
      parsedRecurrence = RecurrenceRule.fromJson(recurrenceRaw);
    }

    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      date: DateTime.parse(json['date'] as String),
      priority: EventPriority.fromString(
        (json['priority'] as String?) ?? 'medium',
      ),
      tags: parsedTags,
      recurrence: parsedRecurrence,
      reminders: ReminderSettings.fromJsonString(
        json['reminders'] as String?,
      ),
    );
  }

  // Method to convert an EventModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'priority': priority.name,
      'tags': jsonEncode(tags.map((t) => t.toJson()).toList()),
      'recurrence': recurrence?.toJsonString(),
      'reminders': reminders.hasReminders ? reminders.toJsonString() : null,
    };
  }

  /// Creates a copy of this event with the given fields replaced.
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    EventPriority? priority,
    List<EventTag>? tags,
    RecurrenceRule? recurrence,
    bool clearRecurrence = false,
    ReminderSettings? reminders,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      priority: priority ?? this.priority,
      tags: tags ?? List.of(this.tags),
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
      reminders: reminders ?? this.reminders,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          description == other.description &&
          date == other.date &&
          priority == other.priority &&
          _tagsEqual(tags, other.tags) &&
          recurrence == other.recurrence &&
          reminders == other.reminders;

  static bool _tagsEqual(List<EventTag> a, List<EventTag> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, title, description, date, priority, Object.hashAll(tags), recurrence, reminders);

  @override
  String toString() =>
      'EventModel(id: $id, title: $title, description: $description, date: $date, priority: ${priority.label}, tags: [${tags.map((t) => t.name).join(", ")}], recurrence: $recurrence, reminders: $reminders)';
}
