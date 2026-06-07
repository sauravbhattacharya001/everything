import 'dart:convert';
import '../utils/date_streak_calculator.dart';
import 'storage_backend.dart';

/// Music Practice Tracker service — log instrument practice sessions,
/// track streaks, and monitor progress toward goals.
class MusicPracticeService {
  MusicPracticeService._();

  static const _storageKey = 'music_practice_sessions';
  static const _goalsKey = 'music_practice_goals';

  /// Predefined instrument list for quick selection.
  static const instruments = [
    'Piano',
    'Guitar',
    'Violin',
    'Drums',
    'Bass',
    'Ukulele',
    'Flute',
    'Saxophone',
    'Trumpet',
    'Cello',
    'Voice',
    'Other',
  ];

  /// Predefined practice categories.
  static const categories = [
    'Scales & Warm-up',
    'Technique',
    'Sight Reading',
    'Theory',
    'New Piece',
    'Repertoire Review',
    'Improvisation',
    'Ear Training',
    'Performance Prep',
    'Free Play',
  ];

  // ── Persistence ──

  static Future<List<PracticeSession>> loadSessions() async {
    final raw = await StorageBackend.read(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    return list
        .map((e) => PracticeSession.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<void> saveSessions(List<PracticeSession> sessions) async {
    await StorageBackend.write(
      _storageKey,
      jsonEncode(sessions.map((s) => s.toJson()).toList()),
    );
  }

  static Future<PracticeGoal?> loadGoal() async {
    final raw = await StorageBackend.read(_goalsKey);
    if (raw == null || raw.isEmpty) return null;
    return PracticeGoal.fromJson(jsonDecode(raw));
  }

  static Future<void> saveGoal(PracticeGoal goal) async {
    await StorageBackend.write(_goalsKey, jsonEncode(goal.toJson()));
  }

  // ── Analytics ──

  /// Current streak in consecutive days.
  ///
  /// Delegates to [DateStreakCalculator] for DST-safe calendar-day
  /// arithmetic instead of manual day-walking.
  static int currentStreak(List<PracticeSession> sessions) {
    if (sessions.isEmpty) return 0;
    return DateStreakCalculator.compute(
      sessions.map((s) => s.date),
    ).current;
  }

  /// Longest ever streak.
  static int longestStreak(List<PracticeSession> sessions) {
    if (sessions.isEmpty) return 0;
    return DateStreakCalculator.compute(
      sessions.map((s) => s.date),
    ).longest;
  }

  /// Total minutes this week (Mon–Sun).
  static int weeklyMinutes(List<PracticeSession> sessions) {
    final now = DateTime.now();
    final monday = _dateOnly(now.subtract(Duration(days: now.weekday - 1)));
    return sessions
        .where((s) => !_dateOnly(s.date).isBefore(monday))
        .fold<int>(0, (sum, s) => sum + s.durationMinutes);
  }

  /// Total minutes all time.
  static int totalMinutes(List<PracticeSession> sessions) =>
      sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

  /// Minutes per instrument breakdown.
  static Map<String, int> minutesByInstrument(List<PracticeSession> sessions) {
    final map = <String, int>{};
    for (final s in sessions) {
      map[s.instrument] = (map[s.instrument] ?? 0) + s.durationMinutes;
    }
    return map;
  }

  /// Minutes per category breakdown.
  static Map<String, int> minutesByCategory(List<PracticeSession> sessions) {
    final map = <String, int>{};
    for (final s in sessions) {
      map[s.category] = (map[s.category] ?? 0) + s.durationMinutes;
    }
    return map;
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}

/// A single practice session.
class PracticeSession {
  final String id;
  final String instrument;
  final String category;
  final int durationMinutes;
  final DateTime date;
  final String? notes;
  final int rating; // 1-5 subjective quality

  const PracticeSession({
    required this.id,
    required this.instrument,
    required this.category,
    required this.durationMinutes,
    required this.date,
    this.notes,
    this.rating = 3,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'instrument': instrument,
        'category': category,
        'durationMinutes': durationMinutes,
        'date': date.toIso8601String(),
        'notes': notes,
        'rating': rating,
      };

  factory PracticeSession.fromJson(Map<String, dynamic> j) => PracticeSession(
        id: j['id'] as String,
        instrument: j['instrument'] as String,
        category: j['category'] as String,
        durationMinutes: j['durationMinutes'] as int,
        date: DateTime.parse(j['date'] as String),
        notes: j['notes'] as String?,
        rating: j['rating'] as int? ?? 3,
      );
}

/// Weekly practice goal.
class PracticeGoal {
  final int weeklyMinutes;
  final int dailySessions;

  const PracticeGoal({
    this.weeklyMinutes = 300, // 5 hours default
    this.dailySessions = 1,
  });

  Map<String, dynamic> toJson() => {
        'weeklyMinutes': weeklyMinutes,
        'dailySessions': dailySessions,
      };

  factory PracticeGoal.fromJson(Map<String, dynamic> j) => PracticeGoal(
        weeklyMinutes: j['weeklyMinutes'] as int? ?? 300,
        dailySessions: j['dailySessions'] as int? ?? 1,
      );
}
