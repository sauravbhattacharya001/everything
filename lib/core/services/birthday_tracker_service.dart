import 'dart:convert';

/// Type of occasion being tracked.
enum OccasionType {
  birthday('Birthday', '🎂'),
  anniversary('Anniversary', '💍'),
  memorial('Memorial', '🕯️'),
  custom('Custom', '📅');

  final String label;
  final String emoji;
  const OccasionType(this.label, this.emoji);
}

/// A single tracked occasion (birthday, anniversary, etc.).
class Occasion {
  final String id;
  final String name;
  final OccasionType type;
  final int month; // 1-12
  final int day; // 1-31
  final int? year; // Optional birth/start year
  final String? notes;
  final String? giftIdeas;
  final DateTime createdAt;

  const Occasion({
    required this.id,
    required this.name,
    required this.type,
    required this.month,
    required this.day,
    this.year,
    this.notes,
    this.giftIdeas,
    required this.createdAt,
  });

  /// Age or years since the occasion (if year is known).
  int? ageOn(DateTime date) {
    if (year == null) return null;
    int age = date.year - year!;
    if (date.month < month || (date.month == month && date.day < day)) {
      age--;
    }
    return age;
  }

  /// Next occurrence of this date from [reference].
  DateTime nextOccurrence(DateTime reference) {
    var next = DateTime(reference.year, month, day);
    if (next.isBefore(reference) ||
        (next.year == reference.year &&
            next.month == reference.month &&
            next.day == reference.day &&
            false)) {
      // If today, still show it; if past, go to next year
      if (next.isBefore(DateTime(reference.year, reference.month, reference.day))) {
        next = DateTime(reference.year + 1, month, day);
      }
    }
    return next;
  }

  /// Days until next occurrence from [reference].
  int daysUntil(DateTime reference) {
    final today = DateTime(reference.year, reference.month, reference.day);
    final next = nextOccurrence(today);
    return next.difference(today).inDays;
  }

  /// Whether this occasion is today.
  bool isToday(DateTime reference) => daysUntil(reference) == 0;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type.name,
        'month': month,
        'day': day,
        'year': year,
        'notes': notes,
        'giftIdeas': giftIdeas,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Occasion.fromJson(Map<String, dynamic> j) => Occasion(
        id: j['id'] as String,
        name: j['name'] as String,
        type: OccasionType.values.firstWhere(
          (t) => t.name == j['type'],
          orElse: () => OccasionType.custom,
        ),
        month: j['month'] as int,
        day: j['day'] as int,
        year: j['year'] as int?,
        notes: j['notes'] as String?,
        giftIdeas: j['giftIdeas'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

/// Upcoming occasion with computed fields.
class UpcomingOccasion {
  final Occasion occasion;
  final int daysUntil;
  final int? turningAge;

  const UpcomingOccasion({
    required this.occasion,
    required this.daysUntil,
    this.turningAge,
  });
}

/// Month summary for calendar-style views.
class MonthSummary {
  final int month;
  final List<Occasion> occasions;

  const MonthSummary({required this.month, required this.occasions});

  static const _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String get monthName => _monthNames[month - 1];
}

/// Service for managing birthdays and anniversaries.
class BirthdayTrackerService {
  BirthdayTrackerService._();

  /// Get upcoming occasions sorted by days until, within [daysAhead].
  static List<UpcomingOccasion> getUpcoming(
    List<Occasion> occasions,
    DateTime reference, {
    int daysAhead = 30,
  }) {
    final results = <UpcomingOccasion>[];
    for (final o in occasions) {
      final days = o.daysUntil(reference);
      if (days <= daysAhead) {
        final nextDate = o.nextOccurrence(reference);
        results.add(UpcomingOccasion(
          occasion: o,
          daysUntil: days,
          turningAge: o.year != null ? nextDate.year - o.year! : null,
        ));
      }
    }
    results.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return results;
  }

  /// Get occasions grouped by month (all 12 months).
  static List<MonthSummary> byMonth(List<Occasion> occasions) {
    final map = <int, List<Occasion>>{};
    for (int m = 1; m <= 12; m++) {
      map[m] = [];
    }
    for (final o in occasions) {
      map[o.month]!.add(o);
    }
    for (final list in map.values) {
      list.sort((a, b) => a.day.compareTo(b.day));
    }
    return List.generate(
      12,
      (i) => MonthSummary(month: i + 1, occasions: map[i + 1]!),
    );
  }

  /// Today's occasions.
  static List<Occasion> todayOccasions(
      List<Occasion> occasions, DateTime reference) {
    return occasions.where((o) => o.isToday(reference)).toList();
  }

  /// Serialize the full list.
  static String serialize(List<Occasion> occasions) =>
      jsonEncode(occasions.map((o) => o.toJson()).toList());

  /// Deserialize from JSON string.
  static List<Occasion> deserialize(String json) {
    final list = jsonDecode(json) as List;
    return list
        .map((j) => Occasion.fromJson(j as Map<String, dynamic>))
        .toList();
  }
}
