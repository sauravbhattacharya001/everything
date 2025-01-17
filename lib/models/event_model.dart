class EventModel {
  final String id;
  final String title;
  final String date;

  EventModel({
    required this.id,
    required this.title,
    required this.date,
  });

  // Factory method to create an EventModel from JSON
  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      date: json['date'],
    );
  }

  // Method to convert an EventModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date,
    };
  }
}
