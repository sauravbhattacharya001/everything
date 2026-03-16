import '../../models/learning_item.dart';

/// Service for managing learning items and analytics.
class LearningTrackerService {
  final List<LearningItem> _items = [];

  List<LearningItem> get items => List.unmodifiable(_items);

  void addItem(LearningItem item) => _items.add(item);

  void removeItem(String id) => _items.removeWhere((i) => i.id == id);

  void updateItem(LearningItem updated) {
    final idx = _items.indexWhere((i) => i.id == updated.id);
    if (idx >= 0) _items[idx] = updated;
  }

  LearningItem? getItem(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Items filtered by status.
  List<LearningItem> byStatus(LearningStatus status) =>
      _items.where((i) => i.status == status).toList();

  /// Items filtered by type.
  List<LearningItem> byType(LearningType type) =>
      _items.where((i) => i.type == type).toList();

  /// Items filtered by category.
  List<LearningItem> byCategory(LearningCategory category) =>
      _items.where((i) => i.category == category).toList();

  /// Search items by title or source.
  List<LearningItem> search(String query) {
    final q = query.toLowerCase();
    return _items.where((i) =>
        i.title.toLowerCase().contains(q) ||
        (i.source?.toLowerCase().contains(q) ?? false) ||
        i.tags.any((t) => t.toLowerCase().contains(q))).toList();
  }

  /// Total study time across all items in minutes.
  int get totalMinutesStudied =>
      _items.fold(0, (sum, i) => sum + i.totalMinutesStudied);

  /// Total hours studied.
  double get totalHoursStudied => totalMinutesStudied / 60.0;

  /// Count of completed items.
  int get completedCount =>
      _items.where((i) => i.status == LearningStatus.completed).length;

  /// Overall completion rate.
  double get completionRate =>
      _items.isEmpty ? 0 : completedCount / _items.length * 100;

  /// Average rating of rated items.
  double get averageRating {
    final rated = _items.where((i) => i.rating != null).toList();
    if (rated.isEmpty) return 0;
    return rated.fold(0, (sum, i) => sum + i.rating!) / rated.length;
  }

  /// Items sorted by priority (highest first).
  List<LearningItem> get prioritized =>
      List.of(_items)..sort((a, b) => b.priority.compareTo(a.priority));

  /// Currently in-progress items.
  List<LearningItem> get inProgress => byStatus(LearningStatus.inProgress);

  /// Items with study sessions in the last N days.
  List<LearningItem> activeInLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _items.where((i) =>
        i.sessions.any((s) => s.date.isAfter(cutoff))).toList();
  }

  /// Category breakdown: category → count.
  Map<LearningCategory, int> get categoryBreakdown {
    final map = <LearningCategory, int>{};
    for (final item in _items) {
      map[item.category] = (map[item.category] ?? 0) + 1;
    }
    return map;
  }

  /// Type breakdown: type → count.
  Map<LearningType, int> get typeBreakdown {
    final map = <LearningType, int>{};
    for (final item in _items) {
      map[item.type] = (map[item.type] ?? 0) + 1;
    }
    return map;
  }

  /// Study minutes per day for the last N days.
  Map<DateTime, int> studyMinutesPerDay(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final map = <DateTime, int>{};
    for (final item in _items) {
      for (final session in item.sessions) {
        if (session.date.isAfter(cutoff)) {
          final day = DateTime(session.date.year, session.date.month, session.date.day);
          map[day] = (map[day] ?? 0) + session.minutesSpent;
        }
      }
    }
    return map;
  }

  /// Current study streak (consecutive days with sessions).
  int get currentStreak {
    final now = DateTime.now();
    final allDates = <DateTime>{};
    for (final item in _items) {
      for (final session in item.sessions) {
        allDates.add(DateTime(session.date.year, session.date.month, session.date.day));
      }
    }
    if (allDates.isEmpty) return 0;

    int streak = 0;
    var check = DateTime(now.year, now.month, now.day);
    // Allow today or yesterday as start
    if (!allDates.contains(check)) {
      check = check.subtract(const Duration(days: 1));
      if (!allDates.contains(check)) return 0;
    }
    while (allDates.contains(check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// Suggested next items to study (in-progress by priority, then planned).
  List<LearningItem> get suggestedNext {
    final ip = inProgress..sort((a, b) => b.priority.compareTo(a.priority));
    final planned = byStatus(LearningStatus.planned)
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return [...ip, ...planned];
  }
}
