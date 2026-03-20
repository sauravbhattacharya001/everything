import '../../models/home_maintenance_entry.dart';
import 'crud_service.dart';

/// Service for managing home maintenance tasks — CRUD, scheduling, analytics.
///
/// Extends [CrudService] for standard CRUD + JSON persistence,
/// adding maintenance-specific scheduling, completion tracking, and
/// spending analytics.
class HomeMaintenanceService extends CrudService<HomeMaintenanceEntry> {
  @override
  String getId(HomeMaintenanceEntry item) => item.id;
  @override
  Map<String, dynamic> toJson(HomeMaintenanceEntry item) => item.toJson();
  @override
  HomeMaintenanceEntry fromJson(Map<String, dynamic> json) =>
      HomeMaintenanceEntry.fromJson(json);

  /// Backward-compatible accessor.
  List<HomeMaintenanceEntry> get tasks => items;

  /// Tasks sorted by urgency (overdue first, then by days until due).
  List<HomeMaintenanceEntry> get sortedByUrgency {
    final sorted = List<HomeMaintenanceEntry>.from(items);
    sorted.sort((a, b) => a.daysUntilDue.compareTo(b.daysUntilDue));
    return sorted;
  }

  /// Tasks that are overdue.
  List<HomeMaintenanceEntry> get overdueTasks =>
      items.where((t) => t.status == MaintenanceStatus.overdue).toList();

  /// Tasks due within 7 days.
  List<HomeMaintenanceEntry> get dueSoonTasks =>
      items.where((t) => t.status == MaintenanceStatus.dueSoon).toList();

  /// Tasks needing attention (overdue or due soon).
  List<HomeMaintenanceEntry> get alertTasks =>
      sortedByUrgency.where((t) =>
          t.status == MaintenanceStatus.overdue ||
          t.status == MaintenanceStatus.dueSoon).toList();

  /// Filter by category.
  List<HomeMaintenanceEntry> byCategory(MaintenanceCategory category) =>
      items.where((t) => t.category == category).toList();

  /// Filter by priority.
  List<HomeMaintenanceEntry> byPriority(MaintenancePriority priority) =>
      items.where((t) => t.priority == priority).toList();

  /// Filter by status.
  List<HomeMaintenanceEntry> byStatus(MaintenanceStatus status) =>
      items.where((t) => t.status == status).toList();

  /// Filter by location.
  List<HomeMaintenanceEntry> byLocation(String location) =>
      items.where((t) =>
          t.location?.toLowerCase() == location.toLowerCase()).toList();

  /// Search tasks by name, description, or location.
  List<HomeMaintenanceEntry> search(String query) {
    final q = query.toLowerCase();
    return items.where((t) =>
        t.name.toLowerCase().contains(q) ||
        (t.description?.toLowerCase().contains(q) ?? false) ||
        (t.location?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  /// All unique locations.
  List<String> get locations {
    final locs = items
        .where((t) => t.location != null && t.location!.isNotEmpty)
        .map((t) => t.location!)
        .toSet()
        .toList();
    locs.sort();
    return locs;
  }

  // ── Legacy CRUD wrappers ──

  void addTask(HomeMaintenanceEntry task) => add(task);

  void updateTask(String id, HomeMaintenanceEntry updated) {
    final idx = indexById(id);
    if (idx >= 0) updateAt(idx, updated);
  }

  void removeTask(String id) => remove(id);

  /// Mark a task as completed and advance the next due date.
  void completeTask(String id, {double? cost, String? vendor, String? notes}) {
    final idx = indexById(id);
    if (idx < 0) return;
    final task = itemsMutable[idx];
    final completion = MaintenanceCompletion(
      completedDate: DateTime.now(),
      cost: cost,
      vendor: vendor,
      notes: notes,
    );
    final nextDue = DateTime.now().add(Duration(days: task.recurrenceDays));
    updateAt(idx, task.copyWith(
      completions: [...task.completions, completion],
      nextDueDate: nextDue,
    ));
  }

  // --- Analytics ---

  /// Total spent across all tasks.
  double get totalSpent =>
      items.fold(0.0, (sum, t) => sum + t.totalSpent);

  /// Spending by category.
  Map<MaintenanceCategory, double> get spendingByCategory {
    final map = <MaintenanceCategory, double>{};
    for (final t in items) {
      map[t.category] = (map[t.category] ?? 0) + t.totalSpent;
    }
    return map;
  }

  /// Count by status.
  Map<MaintenanceStatus, int> get countByStatus {
    final map = <MaintenanceStatus, int>{};
    for (final t in items) {
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
    for (final t in items) {
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
      items.where((t) => t.completions.isEmpty).toList();

  /// Completion rate (tasks completed at least once / total tasks).
  double get completionRate {
    if (isEmpty) return 0;
    return items.where((t) => t.completions.isNotEmpty).length / length;
  }
}
