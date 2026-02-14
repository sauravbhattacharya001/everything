import 'package:flutter/material.dart';

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

  EventModel({
    required this.id,
    required this.title,
    this.description = '',
    required this.date,
    this.priority = EventPriority.medium,
  });

  // Factory method to create an EventModel from JSON
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      date: DateTime.parse(json['date'] as String),
      priority: EventPriority.fromString(
        (json['priority'] as String?) ?? 'medium',
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
    };
  }

  /// Creates a copy of this event with the given fields replaced.
  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? date,
    EventPriority? priority,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      priority: priority ?? this.priority,
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
          priority == other.priority;

  @override
  int get hashCode => Object.hash(id, title, description, date, priority);

  @override
  String toString() =>
      'EventModel(id: $id, title: $title, description: $description, date: $date, priority: ${priority.label})';
}
