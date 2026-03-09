import '../models/pet_entry.dart';

/// Service for pet care analytics and insights.
class PetCareService {
  const PetCareService();

  /// Get care entries for a specific pet, sorted by most recent.
  List<CareEntry> entriesForPet(List<CareEntry> entries, String petId) {
    final filtered = entries.where((e) => e.petId == petId).toList();
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return filtered;
  }

  /// Get today's care entries for a pet.
  List<CareEntry> todayEntries(List<CareEntry> entries, String petId) {
    final now = DateTime.now();
    return entriesForPet(entries, petId).where((e) =>
      e.timestamp.year == now.year &&
      e.timestamp.month == now.month &&
      e.timestamp.day == now.day
    ).toList();
  }

  /// Category breakdown for a pet (count per category).
  Map<CareCategory, int> categoryBreakdown(List<CareEntry> entries, String petId) {
    final map = <CareCategory, int>{};
    for (final e in entries.where((e) => e.petId == petId)) {
      map[e.category] = (map[e.category] ?? 0) + 1;
    }
    return map;
  }

  /// Total cost across all care entries for a pet.
  double totalCost(List<CareEntry> entries, String petId) {
    return entries
        .where((e) => e.petId == petId && e.cost != null)
        .fold(0.0, (sum, e) => sum + e.cost!);
  }

  /// Current care streak (consecutive days with at least one entry).
  int careStreak(List<CareEntry> entries, String petId) {
    final petEntries = entriesForPet(entries, petId);
    if (petEntries.isEmpty) return 0;

    final days = <DateTime>{};
    for (final e in petEntries) {
      days.add(DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day));
    }
    final sorted = days.toList()..sort((a, b) => b.compareTo(a));

    int streak = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i - 1].difference(sorted[i]).inDays == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  /// Mood distribution for a pet.
  Map<PetMood, int> moodDistribution(List<CareEntry> entries, String petId) {
    final map = <PetMood, int>{};
    for (final e in entries.where((e) => e.petId == petId && e.mood != null)) {
      map[e.mood!] = (map[e.mood!] ?? 0) + 1;
    }
    return map;
  }

  /// Health records for a pet, sorted by most recent.
  List<HealthRecord> healthForPet(List<HealthRecord> records, String petId) {
    final filtered = records.where((r) => r.petId == petId).toList();
    filtered.sort((a, b) => b.date.compareTo(a.date));
    return filtered;
  }

  /// Overdue health records for a pet.
  List<HealthRecord> overdueRecords(List<HealthRecord> records, String petId) {
    return healthForPet(records, petId).where((r) => r.isOverdue).toList();
  }

  /// Upcoming (due soon) health records.
  List<HealthRecord> upcomingRecords(List<HealthRecord> records, String petId) {
    return healthForPet(records, petId).where((r) => r.isDueSoon).toList();
  }

  /// Average daily care activities (last 30 days).
  double avgDailyCare(List<CareEntry> entries, String petId) {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recent = entries.where((e) =>
      e.petId == petId && e.timestamp.isAfter(thirtyDaysAgo)
    ).length;
    return recent / 30.0;
  }

  /// Last feeding time for a pet.
  DateTime? lastFeeding(List<CareEntry> entries, String petId) {
    final feedings = entries.where((e) =>
      e.petId == petId && e.category == CareCategory.feeding
    ).toList();
    if (feedings.isEmpty) return null;
    feedings.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return feedings.first.timestamp;
  }

  /// Last walk time for a pet.
  DateTime? lastWalk(List<CareEntry> entries, String petId) {
    final walks = entries.where((e) =>
      e.petId == petId && e.category == CareCategory.walking
    ).toList();
    if (walks.isEmpty) return null;
    walks.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return walks.first.timestamp;
  }

  /// Weekly care summary (last 7 days, entries per day).
  List<int> weeklySummary(List<CareEntry> entries, String petId) {
    final now = DateTime.now();
    final result = List.filled(7, 0);
    for (final e in entries.where((e) => e.petId == petId)) {
      final daysAgo = DateTime(now.year, now.month, now.day)
          .difference(DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
          .inDays;
      if (daysAgo >= 0 && daysAgo < 7) {
        result[6 - daysAgo]++;
      }
    }
    return result;
  }
}
