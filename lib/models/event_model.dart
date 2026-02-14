class EventModel {
  final String id;
  final String title;
  final DateTime date;

  EventModel({
    required this.id,
    required this.title,
    required this.date,
  });

  // Factory method to create an EventModel from JSON
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
    );
  }

  // Method to convert an EventModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
    };
  }

  /// Creates a copy of this event with the given fields replaced.
  EventModel copyWith({
    String? id,
    String? title,
    DateTime? date,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      date: date ?? this.date,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          date == other.date;

  @override
  int get hashCode => Object.hash(id, title, date);

  @override
  String toString() => 'EventModel(id: $id, title: $title, date: $date)';
}
