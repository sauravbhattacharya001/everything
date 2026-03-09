import 'dart:convert';

/// Room/area where the chore takes place.
enum ChoreRoom {
  kitchen,
  bathroom,
  bedroom,
  livingRoom,
  laundry,
  garage,
  yard,
  office,
  general;

  String get label {
    switch (this) {
      case ChoreRoom.kitchen: return 'Kitchen';
      case ChoreRoom.bathroom: return 'Bathroom';
      case ChoreRoom.bedroom: return 'Bedroom';
      case ChoreRoom.livingRoom: return 'Living Room';
      case ChoreRoom.laundry: return 'Laundry';
      case ChoreRoom.garage: return 'Garage';
      case ChoreRoom.yard: return 'Yard';
      case ChoreRoom.office: return 'Office';
      case ChoreRoom.general: return 'General';
    }
  }

  String get emoji {
    switch (this) {
      case ChoreRoom.kitchen: return '🍳';
      case ChoreRoom.bathroom: return '🚿';
      case ChoreRoom.bedroom: return '🛏️';
      case ChoreRoom.livingRoom: return '🛋️';
      case ChoreRoom.laundry: return '👕';
      case ChoreRoom.garage: return '🔧';
      case ChoreRoom.yard: return '🌿';
      case ChoreRoom.office: return '💻';
      case ChoreRoom.general: return '🏠';
    }
  }
}

/// How often the chore should be done.
enum ChoreFrequency {
  daily,
  everyOtherDay,
  weekly,
  biweekly,
  monthly,
  quarterly,
  asNeeded;

  String get label {
    switch (this) {
      case ChoreFrequency.daily: return 'Daily';
      case ChoreFrequency.everyOtherDay: return 'Every Other Day';
      case ChoreFrequency.weekly: return 'Weekly';
      case ChoreFrequency.biweekly: return 'Biweekly';
      case ChoreFrequency.monthly: return 'Monthly';
      case ChoreFrequency.quarterly: return 'Quarterly';
      case ChoreFrequency.asNeeded: return 'As Needed';
    }
  }

  /// Ideal interval in days (asNeeded returns 0).
  int get intervalDays {
    switch (this) {
      case ChoreFrequency.daily: return 1;
      case ChoreFrequency.everyOtherDay: return 2;
      case ChoreFrequency.weekly: return 7;
      case ChoreFrequency.biweekly: return 14;
      case ChoreFrequency.monthly: return 30;
      case ChoreFrequency.quarterly: return 90;
      case ChoreFrequency.asNeeded: return 0;
    }
  }
}

/// Effort level of a chore.
enum ChoreEffort {
  quick,   // < 10 min
  moderate, // 10-30 min
  major;   // 30+ min

  String get label {
    switch (this) {
      case ChoreEffort.quick: return 'Quick (<10 min)';
      case ChoreEffort.moderate: return 'Moderate (10-30 min)';
      case ChoreEffort.major: return 'Major (30+ min)';
    }
  }

  String get emoji {
    switch (this) {
      case ChoreEffort.quick: return '⚡';
      case ChoreEffort.moderate: return '💪';
      case ChoreEffort.major: return '🏋️';
    }
  }

  int get estimatedMinutes {
    switch (this) {
      case ChoreEffort.quick: return 5;
      case ChoreEffort.moderate: return 20;
      case ChoreEffort.major: return 45;
    }
  }
}

/// A household chore definition.
class Chore {
  final String id;
  final String name;
  final ChoreRoom room;
  final ChoreFrequency frequency;
  final ChoreEffort effort;
  final String? assignee;
  final bool archived;

  const Chore({
    required this.id,
    required this.name,
    required this.room,
    this.frequency = ChoreFrequency.weekly,
    this.effort = ChoreEffort.moderate,
    this.assignee,
    this.archived = false,
  });

  Chore copyWith({
    String? name,
    ChoreRoom? room,
    ChoreFrequency? frequency,
    ChoreEffort? effort,
    String? assignee,
    bool? archived,
  }) {
    return Chore(
      id: id,
      name: name ?? this.name,
      room: room ?? this.room,
      frequency: frequency ?? this.frequency,
      effort: effort ?? this.effort,
      assignee: assignee ?? this.assignee,
      archived: archived ?? this.archived,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'room': room.index,
    'frequency': frequency.index,
    'effort': effort.index,
    'assignee': assignee,
    'archived': archived,
  };

  factory Chore.fromJson(Map<String, dynamic> json) => Chore(
    id: json['id'] as String,
    name: json['name'] as String,
    room: ChoreRoom.values[json['room'] as int],
    frequency: ChoreFrequency.values[json['frequency'] as int],
    effort: ChoreEffort.values[json['effort'] as int],
    assignee: json['assignee'] as String?,
    archived: json['archived'] as bool? ?? false,
  );
}

/// A record of completing a chore.
class ChoreCompletion {
  final String id;
  final String choreId;
  final DateTime completedAt;
  final int durationMinutes;
  final String? note;
  final int rating; // 1-5 satisfaction

  const ChoreCompletion({
    required this.id,
    required this.choreId,
    required this.completedAt,
    this.durationMinutes = 0,
    this.note,
    this.rating = 3,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'choreId': choreId,
    'completedAt': completedAt.toIso8601String(),
    'durationMinutes': durationMinutes,
    'note': note,
    'rating': rating,
  };

  factory ChoreCompletion.fromJson(Map<String, dynamic> json) =>
      ChoreCompletion(
        id: json['id'] as String,
        choreId: json['choreId'] as String,
        completedAt: DateTime.parse(json['completedAt'] as String),
        durationMinutes: json['durationMinutes'] as int? ?? 0,
        note: json['note'] as String?,
        rating: json['rating'] as int? ?? 3,
      );
}
