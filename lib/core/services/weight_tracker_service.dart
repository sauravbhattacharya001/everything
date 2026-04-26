import '../../models/weight_entry.dart';

/// Service for weight tracking analytics.
class WeightTrackerService {
  const WeightTrackerService();

  /// Weekly average weight.
  double? weeklyAverage(List<WeightEntry> entries) {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recent = entries.where((e) => e.timestamp.isAfter(weekAgo)).toList();
    if (recent.isEmpty) return null;
    return recent.map((e) => e.weightKg).reduce((a, b) => a + b) / recent.length;
  }

  /// Weight change over the last N days.
  double? changeOverDays(List<WeightEntry> entries, int days) {
    if (entries.length < 2) return null;
    final sorted = [...entries]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final older = sorted.where((e) => e.timestamp.isBefore(cutoff)).toList();
    if (older.isEmpty) return null;
    return sorted.last.weightKg - older.last.weightKg;
  }

  /// All-time min weight.
  double? minWeight(List<WeightEntry> entries) {
    if (entries.isEmpty) return null;
    return entries.map((e) => e.weightKg).reduce(min);
  }

  /// All-time max weight.
  double? maxWeight(List<WeightEntry> entries) {
    if (entries.isEmpty) return null;
    return entries.map((e) => e.weightKg).reduce(max);
  }

  /// Current streak of consecutive days with entries.
  int currentStreak(List<WeightEntry> entries) {
    if (entries.isEmpty) return 0;
    final sorted = [...entries]..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final days = sorted.map((e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day)).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    int streak = 1;
    for (int i = 1; i < days.length; i++) {
      if (days[i - 1].difference(days[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Goal weight progress (0.0 to 1.0+).
  double goalProgress(List<WeightEntry> entries, double startKg, double goalKg) {
    if (entries.isEmpty || startKg == goalKg) return 0;
    final current = entries.first.weightKg; // most recent
    return (startKg - current) / (startKg - goalKg);
  }

  /// Weekly trend: average change per week.
  double? weeklyTrend(List<WeightEntry> entries) {
    if (entries.length < 2) return null;
    final sorted = [...entries]..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    final spanDays = sorted.last.timestamp.difference(sorted.first.timestamp).inDays;
    if (spanDays == 0) return null;
    final totalChange = sorted.last.weightKg - sorted.first.weightKg;
    return totalChange / spanDays * 7;
  }
}
