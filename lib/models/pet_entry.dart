import 'dart:convert';

/// Type of pet.
enum PetType {
  dog,
  cat,
  bird,
  fish,
  rabbit,
  hamster,
  reptile,
  other;

  String get label {
    switch (this) {
      case PetType.dog: return 'Dog';
      case PetType.cat: return 'Cat';
      case PetType.bird: return 'Bird';
      case PetType.fish: return 'Fish';
      case PetType.rabbit: return 'Rabbit';
      case PetType.hamster: return 'Hamster';
      case PetType.reptile: return 'Reptile';
      case PetType.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case PetType.dog: return '🐕';
      case PetType.cat: return '🐈';
      case PetType.bird: return '🐦';
      case PetType.fish: return '🐟';
      case PetType.rabbit: return '🐇';
      case PetType.hamster: return '🐹';
      case PetType.reptile: return '🦎';
      case PetType.other: return '🐾';
    }
  }
}

/// Category of care activity.
enum CareCategory {
  feeding,
  walking,
  grooming,
  medication,
  vetVisit,
  vaccination,
  training,
  play,
  cleaning,
  other;

  String get label {
    switch (this) {
      case CareCategory.feeding: return 'Feeding';
      case CareCategory.walking: return 'Walking';
      case CareCategory.grooming: return 'Grooming';
      case CareCategory.medication: return 'Medication';
      case CareCategory.vetVisit: return 'Vet Visit';
      case CareCategory.vaccination: return 'Vaccination';
      case CareCategory.training: return 'Training';
      case CareCategory.play: return 'Play';
      case CareCategory.cleaning: return 'Cleaning';
      case CareCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case CareCategory.feeding: return '🍖';
      case CareCategory.walking: return '🦮';
      case CareCategory.grooming: return '✂️';
      case CareCategory.medication: return '💊';
      case CareCategory.vetVisit: return '🏥';
      case CareCategory.vaccination: return '💉';
      case CareCategory.training: return '🎯';
      case CareCategory.play: return '🎾';
      case CareCategory.cleaning: return '🧹';
      case CareCategory.other: return '📝';
    }
  }
}

/// Mood/energy of the pet at time of logging.
enum PetMood {
  energetic,
  happy,
  calm,
  tired,
  anxious,
  sick;

  String get label {
    switch (this) {
      case PetMood.energetic: return 'Energetic';
      case PetMood.happy: return 'Happy';
      case PetMood.calm: return 'Calm';
      case PetMood.tired: return 'Tired';
      case PetMood.anxious: return 'Anxious';
      case PetMood.sick: return 'Sick';
    }
  }

  String get emoji {
    switch (this) {
      case PetMood.energetic: return '⚡';
      case PetMood.happy: return '😊';
      case PetMood.calm: return '😌';
      case PetMood.tired: return '😴';
      case PetMood.anxious: return '😰';
      case PetMood.sick: return '🤒';
    }
  }
}

/// A pet profile.
class Pet {
  final String id;
  final String name;
  final PetType type;
  final String? breed;
  final DateTime? birthday;
  final double? weightKg;
  final String? notes;

  const Pet({
    required this.id,
    required this.name,
    required this.type,
    this.breed,
    this.birthday,
    this.weightKg,
    this.notes,
  });

  int? get ageMonths {
    if (birthday == null) return null;
    final now = DateTime.now();
    return (now.year - birthday!.year) * 12 + now.month - birthday!.month;
  }

  String get ageLabel {
    final m = ageMonths;
    if (m == null) return 'Unknown age';
    if (m < 12) return '$m months';
    final y = m ~/ 12;
    final rm = m % 12;
    if (rm == 0) return '$y yr${y > 1 ? 's' : ''}';
    return '$y yr${y > 1 ? 's' : ''} $rm mo';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type.name,
    'breed': breed,
    'birthday': birthday?.toIso8601String(),
    'weightKg': weightKg,
    'notes': notes,
  };

  factory Pet.fromJson(Map<String, dynamic> json) => Pet(
    id: json['id'] as String,
    name: json['name'] as String,
    type: PetType.values.byName(json['type'] as String),
    breed: json['breed'] as String?,
    birthday: json['birthday'] != null ? DateTime.parse(json['birthday'] as String) : null,
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    notes: json['notes'] as String?,
  );
}

/// A single care log entry.
class CareEntry {
  final String id;
  final String petId;
  final DateTime timestamp;
  final CareCategory category;
  final String? note;
  final int? durationMinutes;
  final PetMood? mood;
  final double? cost;

  const CareEntry({
    required this.id,
    required this.petId,
    required this.timestamp,
    required this.category,
    this.note,
    this.durationMinutes,
    this.mood,
    this.cost,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'petId': petId,
    'timestamp': timestamp.toIso8601String(),
    'category': category.name,
    'note': note,
    'durationMinutes': durationMinutes,
    'mood': mood?.name,
    'cost': cost,
  };

  factory CareEntry.fromJson(Map<String, dynamic> json) => CareEntry(
    id: json['id'] as String,
    petId: json['petId'] as String,
    timestamp: DateTime.parse(json['timestamp'] as String),
    category: CareCategory.values.byName(json['category'] as String),
    note: json['note'] as String?,
    durationMinutes: json['durationMinutes'] as int?,
    mood: json['mood'] != null ? PetMood.values.byName(json['mood'] as String) : null,
    cost: (json['cost'] as num?)?.toDouble(),
  );
}

/// A health record (weight measurement, vet note, vaccination).
class HealthRecord {
  final String id;
  final String petId;
  final DateTime date;
  final CareCategory type; // vetVisit, vaccination, medication
  final String title;
  final String? description;
  final double? weightKg;
  final DateTime? nextDue;

  const HealthRecord({
    required this.id,
    required this.petId,
    required this.date,
    required this.type,
    required this.title,
    this.description,
    this.weightKg,
    this.nextDue,
  });

  bool get isOverdue => nextDue != null && nextDue!.isBefore(DateTime.now());
  bool get isDueSoon => nextDue != null &&
      nextDue!.isAfter(DateTime.now()) &&
      nextDue!.difference(DateTime.now()).inDays <= 14;

  Map<String, dynamic> toJson() => {
    'id': id,
    'petId': petId,
    'date': date.toIso8601String(),
    'type': type.name,
    'title': title,
    'description': description,
    'weightKg': weightKg,
    'nextDue': nextDue?.toIso8601String(),
  };

  factory HealthRecord.fromJson(Map<String, dynamic> json) => HealthRecord(
    id: json['id'] as String,
    petId: json['petId'] as String,
    date: DateTime.parse(json['date'] as String),
    type: CareCategory.values.byName(json['type'] as String),
    title: json['title'] as String,
    description: json['description'] as String?,
    weightKg: (json['weightKg'] as num?)?.toDouble(),
    nextDue: json['nextDue'] != null ? DateTime.parse(json['nextDue'] as String) : null,
  );
}
