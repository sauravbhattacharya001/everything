import 'dart:convert';
import '../../models/home_maintenance_entry.dart';

/// Service for managing home maintenance tasks — CRUD, scheduling, analytics.
class HomeMaintenanceService {
  final List<HomeMaintenanceEntry> _tasks = [];

  List<HomeMaintenanceEntry> get tasks => List.unmodifiable(_tasks);

  /// Tasks sorted by urgency (overdue first, then by days until due).
  List<HomeMaintenanceEntry> get sortedByUrgency {
    final sorted = List<HomeMaintenanceEntry>.from(_tasks);
    sorted.sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
    return sorted;
  }

  /// Tasks that are overdue.
  List<HomeMaintenanceEntry> get overdueTasks =>
      _tasks.where((t) => t.status == MaintenanceStatus.overdue).toList();

  /// Tasks due within 7 days.
  List<HomeMaintenanceEntry> get dueSoonTasks =>
      _tasks.where((t) => t.status == MaintenanceStatus.dueSoon).toList();

  /// Tasks needing attention (overdue or due soon).
  List<HomeMaintenanceEntry> get alertTasks =>
      sortedByUrgency.where((t) =>
          t.status == MaintenanceStatus.overdue ||
          t.status == MaintenanceStatus.dueSoon).toList();

  /// Filter by category.
  List<HomeMaintenanceEntry> byCategory(MaintenanceCategory category) =>
      _tasks.where((t) => t.category == category).toList();

  /// Filter by priority.
  List<HomeMaintenanceEntry> byPriority(MaintenancePriority priority) =>
      _tasks.where((t) => t.priority == priority).toList();

  /// Filter by status.
  List<HomeMaintenanceEntry> byStatus(MaintenanceStatus status) =>
      _tasks.where((t) => t.status == status).toList();

  /// Filter by location.
  List<HomeMaintenanceEntry> byLocation(String location) =>
      _tasks.where((t) =>
          t.location?.toLowerCase() == location.toLowerCase()).toList();

  /// Search tasks by name, description, or location.
  List<HomeMaintenanceEntry> search(String query) {
    final q = query.toLowerCase();
    return _tasks.where((t) =>
        t.name.toLowerCase().contains(q) ||
        (t.description?.toLowerCase().contains(q) ?? false) ||
        (t.location?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  /// All unique locations.
  List<String> get locations {
    final locs = _tasks
        .where((t) => t.location != null && t.location!.isNotEmpty)
        .map((t) => t.location!)
        .toSet()
        .toList();
    locs.sort();
    return locs;
  }

  void addTask(HomeMaintenanceEntry task) => _tasks.add(task);

  void updateTask(String id, HomeMaintenanceEntry updated) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx >= 0) _tasks[idx] = updated;
  }

  void removeTask(String id) => _tasks.removeWhere((t) => t.id == id);

  /// Mark a task as completed and advance the next due date.
  void completeTask(String id, {double? cost, String? vendor, String? notes}) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx < 0) return;
    final task = _tasks[idx];
    final completion = MaintenanceCompletion(
      completedDate: DateTime.now(),
      cost: cost,
      vendor: vendor,
      notes: notes,
    );
    final nextDue = DateTime.now().add(Duration(days: task.recurrenceDays));
    _tasks[idx] = task.copyWith(
      completions: [...task.completions, completion],
      nextDueDate: nextDue,
    );
  }

  // --- Analytics ---

  /// Total spent across all tasks.
  double get totalSpent =>
      _tasks.fold(0.0, (sum, t) => sum + t.totalSpent);

  /// Spending by category.
  Map<MaintenanceCategory, double> get spendingByCategory {
    final map = <MaintenanceCategory, double>{};
    for (final t in _tasks) {
      map[t.category] = (map[t.category] ?? 0) + t.totalSpent;
    }
    return map;
  }

  /// Count by status.
  Map<MaintenanceStatus, int> get countByStatus {
    final map = <MaintenanceStatus, int>{};
    for (final t in _tasks) {
      map[t.status] = (map[t.status] ?? 0) + 1;
    }
    return map;
  }

  /// Monthly spending for the last N months.
  Map<String, double> monthlySpending({int months = 12}) {
    final now = DateTime.now();
    final map = <String, double>{};
    for (var i = 0; i < months; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      map[key] = 0;
    }
    for (final t in _tasks) {
      for (final c in t.completions) {
        final key = '${c.completedDate.year}-${c.completedDate.month.toString().padLeft(2, '0')}';
        if (map.containsKey(key)) {
          map[key] = map[key]! + (c.cost ?? 0);
        }
      }
    }
    return map;
  }

  /// Upcoming tasks for the next N days.
  List<HomeMaintenanceEntry> upcomingTasks({int days = 30}) =>
      sortedByUrgency.where((t) => t.daysUntilDue <= days).toList();

  /// Tasks that have never been completed.
  List<HomeMaintenanceEntry> get neverCompleted =>
      _tasks.where((t) => t.completions.isEmpty).toList();

  /// Completion rate (tasks completed at least once / total tasks).
  double get completionRate {
    if (_tasks.isEmpty) return 0;
    return _tasks.where((t) => t.completions.isNotEmpty).length / _tasks.length;
  }

  // --- Serialization ---

  String exportToJson() =>
      jsonEncode(_tasks.map((t) => t.toJson()).toList());

  void importFromJson(String json) {
    _tasks.clear();
    final list = jsonDecode(json) as List<dynamic>;
    _tasks.addAll(list.map((j) =>
        HomeMaintenanceEntry.fromJson(j as Map<String, dynamic>)));
  }
}
