import 'dart:convert';
import 'package:flutter/material.dart';
import 'event_model.dart';
import 'event_tag.dart';

/// A reusable template for quickly creating events with pre-filled fields.
///
/// Templates store default values for title, description, priority, tags,
/// and duration. Users can create events from templates, and the template
/// values pre-fill the event creation form.
///
/// Includes 10 built-in presets for common event types. Custom templates
/// can be created from existing events or from scratch.
class EventTemplate {
  final String id;
  final String name;
  final String icon;
  final String defaultTitle;
  final String defaultDescription;
  final EventPriority defaultPriority;
  final List<EventTag> defaultTags;
  final Duration defaultDuration;
  final bool isBuiltIn;

  const EventTemplate({
    required this.id,
    required this.name,
    required this.icon,
    this.defaultTitle = '',
    this.defaultDescription = '',
    this.defaultPriority = EventPriority.medium,
    this.defaultTags = const [],
    this.defaultDuration = const Duration(hours: 1),
    this.isBuiltIn = false,
  });

  /// Built-in preset templates for common event types.
  static const List<EventTemplate> presets = [
    EventTemplate(
      id: 'preset_meeting',
      name: 'Meeting',
      icon: '🤝',
      defaultTitle: 'Meeting',
      defaultDescription: 'Agenda:\n- \n\nAction items:\n- ',
      defaultPriority: EventPriority.high,
      defaultTags: [EventTag(name: 'Meeting', colorIndex: 2)],
      defaultDuration: Duration(hours: 1),
      isBuiltIn: true,
    ),
    EventTemplate(
      id: 'preset_birthday',
      name: 'Birthday',
      icon: '🎂',
      defaultTitle: 'Birthday',
      defaultDescription: 'Birthday celebration',
      defaultPriority: EventPriority.medium,
      defaultTags: [EventTag(name: 'Birthday', colorIndex: 3)],
      defaultDuration: Duration(hours: 3),
      isBuiltIn: true,
    ),
    EventTemplate(
      id: 'preset_doctor',
      name: 'Doctor',
      icon: '🏥',
      defaultTitle: 'Doctor Appointment',
      defaultDescription: 'Location:\nDoctor:\nNotes:',
      defaultPriority: EventPriority.high,
      defaultTags: [EventTag(name: 'Health', colorIndex: 4)],
      defaultDuration: Duration(minutes: 30),
      isBuiltIn: true,
    ),
    EventTemplate(
      id: 'preset_gym',
      name: 'Workout',
      icon: '💪',
      defaultTitle: 'Workout',
      defaultDescription: 'Exercises:\n- ',
      defaultPriority: EventPriority.medium,
      defaultTags: [EventTag(name: 'Health', colorIndex: 4)],
      defaultDuration: Duration(hours: 1),
      isBuiltIn: true,
    ),
    EventTemplate(
      id: 'preset_standup',
      name: 'Standup',
      icon: '🧑‍💻',
      defaultTitle: 'Daily Standup',
      defaultDescription: 'Yesterday:\n- \n\nToday:\n- \n\nBlockers:\n- ',
      defaultPriority: EventPriority.medium,
      defaultTags: [EventTag(name: 'Work', colorIndex: 0)],
      defaultDuration: Duration(minutes: 15),
      isBuiltIn: true,
    ),
    EventTemplate(
      id: 'preset_lunch',
      name: 'Lunch',
      icon: '🍽️',
      defaultTitle: 'Lunch',
      defaultDescription: '',
      defaultPriority: EventPriority.low,
      defaultTags: [EventTag(name: 'Personal', colorIndex: 1)],
      defaultDuration: Duration(hours: 1),
      isBuiltIn: true,
    ),
    EventTemplate(
      id: 'preset_travel',
      name: 'Travel',
      icon: '✈️',
      defaultTitle: 'Travel',
      defaultDescription: 'From:\nTo:\nBooking ref:',
      defaultPriority: EventPriority.high,
      defaultTags: [EventTag(name: 'Travel', colorIndex: 5)],
      defaultDuration: Duration(hours: 4),
      isBuiltIn: true,
    ),
    EventTemplate(
      id: 'preset_deadline',
      name: 'Deadline',
      icon: '⏰',
      defaultTitle: 'Deadline',
      defaultDescription: 'Deliverables:\n- ',
      defaultPriority: EventPriority.urgent,
      defaultTags: [EventTag(name: 'Work', colorIndex: 0)],
      defaultDuration: Duration(hours: 0),
      isBuiltIn: true,
    ),
    EventTemplate(
      id: 'preset_social',
      name: 'Social',
      icon: '🎉',
      defaultTitle: 'Social Event',
      defaultDescription: 'Location:\nWho:',
      defaultPriority: EventPriority.low,
      defaultTags: [EventTag(name: 'Social', colorIndex: 7)],
      defaultDuration: Duration(hours: 2),
      isBuiltIn: true,
    ),
    EventTemplate(
      id: 'preset_focus',
      name: 'Focus Time',
      icon: '🎯',
      defaultTitle: 'Focus Time',
      defaultDescription: 'Goal:\n- ',
      defaultPriority: EventPriority.medium,
      defaultTags: [EventTag(name: 'Work', colorIndex: 0)],
      defaultDuration: Duration(hours: 2),
      isBuiltIn: true,
    ),
  ];

  /// Creates an [EventModel] from this template at the given [dateTime].
  ///
  /// Uses the template's defaults for title, description, priority, and tags.
  /// The [id] must be provided by the caller (typically a UUID).
  EventModel createEvent({
    required String id,
    required DateTime dateTime,
    String? title,
    String? description,
    EventPriority? priority,
    List<EventTag>? tags,
  }) {
    return EventModel(
      id: id,
      title: title ?? defaultTitle,
      description: description ?? defaultDescription,
      date: dateTime,
      priority: priority ?? defaultPriority,
      tags: tags ?? List.of(defaultTags),
    );
  }

  /// Creates a custom template from an existing [EventModel].
  ///
  /// Captures the event's title, description, priority, and tags as defaults.
  static EventTemplate fromEvent({
    required String id,
    required String name,
    required String icon,
    required EventModel event,
  }) {
    return EventTemplate(
      id: id,
      name: name,
      icon: icon,
      defaultTitle: event.title,
      defaultDescription: event.description,
      defaultPriority: event.priority,
      defaultTags: List.of(event.tags),
      isBuiltIn: false,
    );
  }

  /// Creates a copy of this template with the given fields replaced.
  EventTemplate copyWith({
    String? id,
    String? name,
    String? icon,
    String? defaultTitle,
    String? defaultDescription,
    EventPriority? defaultPriority,
    List<EventTag>? defaultTags,
    Duration? defaultDuration,
    bool? isBuiltIn,
  }) {
    return EventTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      defaultTitle: defaultTitle ?? this.defaultTitle,
      defaultDescription: defaultDescription ?? this.defaultDescription,
      defaultPriority: defaultPriority ?? this.defaultPriority,
      defaultTags: defaultTags ?? List.of(this.defaultTags),
      defaultDuration: defaultDuration ?? this.defaultDuration,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
    );
  }

  /// Serializes this template to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'defaultTitle': defaultTitle,
      'defaultDescription': defaultDescription,
      'defaultPriority': defaultPriority.name,
      'defaultTags': defaultTags.map((t) => t.toJson()).toList(),
      'defaultDurationMinutes': defaultDuration.inMinutes,
      'isBuiltIn': isBuiltIn,
    };
  }

  /// Creates an [EventTemplate] from a JSON map.
  factory EventTemplate.fromJson(Map<String, dynamic> json) {
    return EventTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      defaultTitle: (json['defaultTitle'] as String?) ?? '',
      defaultDescription: (json['defaultDescription'] as String?) ?? '',
      defaultPriority: EventPriority.fromString(
        (json['defaultPriority'] as String?) ?? 'medium',
      ),
      defaultTags: (json['defaultTags'] as List<dynamic>?)
              ?.map((t) => EventTag.fromJson(t as Map<String, dynamic>))
              .toList() ??
          const [],
      defaultDuration: Duration(
        minutes: (json['defaultDurationMinutes'] as int?) ?? 60,
      ),
      isBuiltIn: (json['isBuiltIn'] as bool?) ?? false,
    );
  }

  /// Serializes a list of templates to a JSON string for storage.
  static String toJsonString(List<EventTemplate> templates) {
    return jsonEncode(templates.map((t) => t.toJson()).toList());
  }

  /// Deserializes a list of templates from a JSON string.
  static List<EventTemplate> fromJsonString(String? jsonStr) {
    if (jsonStr == null || jsonStr.isEmpty) return [];
    try {
      final decoded = jsonDecode(jsonStr) as List<dynamic>;
      return decoded
          .map((t) => EventTemplate.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Gracefully handle malformed stored data
      return [];
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'EventTemplate(id: $id, name: $name, icon: $icon, isBuiltIn: $isBuiltIn)';
}
