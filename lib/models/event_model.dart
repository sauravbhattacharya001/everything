import 'dart:convert';
import 'package:flutter/material.dart';
import 'event_attachment.dart';
import 'event_checklist.dart';
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

/// Core domain model representing a calendar event.
///
/// An [EventModel] holds all data for a single event: title, date/time,
/// priority, tags, recurrence rules, reminders, checklists, and attachments.
/// Events are identified by a unique [id] string and support JSON
/// serialization for SQLite persistence via [toJson] / [fromJson].
///
/// Recurring events use a [RecurrenceRule] to generate future occurrences
/// via [generateOccurrences]; each generated occurrence receives a derived
/// ID (`originalId_N`) and shifted date while sharing all other properties.
class EventModel {
  /// Unique identifier for this event (UUID or derived `parentId_N`).
  final String id;

  /// Short display title shown in calendar views and cards.
  final String title;

  /// Optional longer description with event details.
  final String description;

  /// Optional location or venue for this event.
  final String location;

  /// The date (and optional time) when this event starts.
  final DateTime date;

  /// Optional end date/time. When null the event is a point-in-time.
  final DateTime? endDate;

  /// Computed duration between [date] and [endDate], or null if no end date.
  Duration? get duration => endDate != null ? endDate!.difference(date) : null;

  /// Whether this event spans a time range (has both start and end).
  bool get hasTimeRange => endDate != null;

  /// Importance level affecting display color and sort order.
  final EventPriority priority;

  /// User-defined categorical tags for filtering and grouping.
  final List<EventTag> tags;

  /// Optional rule defining how this event repeats over time.
  final RecurrenceRule? recurrence;

  /// Notification settings (before-event alerts, custom offsets).
  final ReminderSettings reminders;

  /// Task checklist attached to this event for tracking sub-items.
  final EventChecklist checklist;

  /// File or link attachments associated with this event.
  final EventAttachments attachments;

  /// Creates a new event.
  ///
  /// [id] and [title] are required. All collection fields default to
  /// empty instances when omitted, and [priority] defaults to
  /// [EventPriority.medium].
  EventModel({
    required this.id,
    required this.title,
    this.description = '',
    this.location = '',
    required this.date,
    this.endDate,
    this.priority = EventPriority.medium,
    List<EventTag>? tags,
    this.recurrence,
    ReminderSettings? reminders,
    EventChecklist? checklist,
    EventAttachments? attachments,
  })  : tags = tags ?? const [],
        reminders = reminders ?? const ReminderSettings(),
        checklist = checklist ?? const EventChecklist(),
        attachments = attachments ?? const EventAttachments();

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
      final shift = entry.value.difference(date);
      return copyWith(
        id: '${id}_${entry.key + 1}',
        date: entry.value,
        endDate: endDate?.add(shift),
      );
    }).toList();
  }

  /// Deserializes an [EventModel] from a JSON map (typically from SQLite).
  ///
  /// Handles polymorphic tag/recurrence fields: values stored as JSON
  /// strings are decoded, while raw [Map]/[List] values are used directly.
  /// Invalid or missing optional fields fall back to safe defaults.
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
      location: (json['location'] as String?) ?? '',
      date: DateTime.parse(json['date'] as String),
      endDate: json['end_date'] != null
          ? DateTime.parse(json['end_date'] as String)
          : null,
      priority: EventPriority.fromString(
        (json['priority'] as String?) ?? 'medium',
      ),
      tags: parsedTags,
      recurrence: parsedRecurrence,
      reminders: ReminderSettings.fromJsonString(
        json['reminders'] as String?,
      ),
      checklist: EventChecklist.fromJsonString(
        json['checklist'] as String?,
      ),
      attachments: EventAttachments.fromJsonString(
        json['attachments'] as String?,
      ),
    );
  }

  /// Serializes this event to a JSON-compatible map for SQLite storage.
  ///
  /// Collection fields (tags, reminders, checklist, attachments) are
  /// encoded as JSON strings. Null/empty optional fields are stored as
  /// `null` to minimize storage.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'date': date.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'priority': priority.name,
      'tags': jsonEncode(tags.map((t) => t.toJson()).toList()),
      'recurrence': recurrence?.toJsonString(),
      'reminders': reminders.hasReminders ? reminders.toJsonString() : null,
      'checklist': checklist.hasItems ? checklist.toJsonString() : null,
      'attachments': attachments.hasAttachments ? attachments.toJsonString() : null,
    };
  }

  /// Creates a copy of this event with the given fields replaced.
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? date,
    DateTime? endDate,
    bool clearEndDate = false,
    EventPriority? priority,
    List<EventTag>? tags,
    RecurrenceRule? recurrence,
    bool clearRecurrence = false,
    ReminderSettings? reminders,
    EventChecklist? checklist,
    EventAttachments? attachments,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      date: date ?? this.date,
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      priority: priority ?? this.priority,
      tags: tags ?? List.of(this.tags),
      recurrence: clearRecurrence ? null : (recurrence ?? this.recurrence),
      reminders: reminders ?? this.reminders,
      checklist: checklist ?? this.checklist,
      attachments: attachments ?? this.attachments,
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
          location == other.location &&
          date == other.date &&
          endDate == other.endDate &&
          priority == other.priority &&
          _tagsEqual(tags, other.tags) &&
          recurrence == other.recurrence &&
          reminders == other.reminders &&
          checklist == other.checklist &&
          attachments == other.attachments;

  static bool _tagsEqual(List<EventTag> a, List<EventTag> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(id, title, description, location, date, endDate, priority, Object.hashAll(tags), recurrence, reminders, checklist, attachments);

  @override
  String toString() =>
      'EventModel(id: $id, title: $title, description: $description, location: $location, date: $date, endDate: $endDate, priority: ${priority.label}, tags: [${tags.map((t) => t.name).join(", ")}], recurrence: $recurrence, reminders: $reminders, checklist: $checklist, attachments: $attachments)';
}
