import 'package:flutter/material.dart';

/// A tag/category that can be attached to events for organization.
///
/// Tags have a [name] and a [colorIndex] that maps to one of 8 preset
/// colors. Tags are stored as JSON strings in the database and identified
/// by name (case-insensitive equality).
class EventTag {
  final String name;
  final int colorIndex;

  /// Preset palette of 8 tag colors.
  static const List<Color> palette = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFF795548), // Brown
    Color(0xFF607D8B), // Blue Grey
  ];

  /// Human-readable names for each palette color.
  static const List<String> paletteNames = [
    'Blue',
    'Green',
    'Orange',
    'Purple',
    'Pink',
    'Cyan',
    'Brown',
    'Grey',
  ];

  /// Common preset tags users might want.
  static const List<EventTag> presets = [
    EventTag(name: 'Work', colorIndex: 0),
    EventTag(name: 'Personal', colorIndex: 1),
    EventTag(name: 'Meeting', colorIndex: 2),
    EventTag(name: 'Birthday', colorIndex: 3),
    EventTag(name: 'Health', colorIndex: 4),
    EventTag(name: 'Travel', colorIndex: 5),
    EventTag(name: 'Finance', colorIndex: 6),
    EventTag(name: 'Social', colorIndex: 7),
  ];

  const EventTag({
    required this.name,
    this.colorIndex = 0,
  });

  /// The resolved [Color] for this tag.
  Color get color => palette[colorIndex.clamp(0, palette.length - 1)];

  /// Creates an [EventTag] from a JSON map.
  factory EventTag.fromJson(Map<String, dynamic> json) {
    return EventTag(
      name: json['name'] as String,
      colorIndex: (json['colorIndex'] as int?) ?? 0,
    );
  }

  /// Serializes this tag to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'colorIndex': colorIndex,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventTag &&
          runtimeType == other.runtimeType &&
          name.toLowerCase() == other.name.toLowerCase();

  @override
  int get hashCode => name.toLowerCase().hashCode;

  @override
  String toString() => 'EventTag(name: $name, colorIndex: $colorIndex)';
}
