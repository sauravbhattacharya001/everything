import '../../models/medication_entry.dart';

/// Service for medication tracking logic — adherence, streaks, insights.
class MedicationTrackerService {
  const MedicationTrackerService();

  /// Calculate adherence rate (0.0-1.0) for a medication over a date range.
  double adherenceRate(Medication med, List<DoseLog> logs, DateTime from, DateTime to) {
    final medLogs = logs.where((l) => l.medicationId == med.id).toList();
    if (med.frequency == MedFrequency.asNeeded) {
      if (medLogs.isEmpty) return 1.0;
      final taken = medLogs.where((l) => l.taken).length;
      return taken / medLogs.length;
    }

    final days = to.difference(from).inDays + 1;
    final expectedPerDay = med.scheduledTimes.length;
    if (expectedPerDay == 0) return 1.0;

    int totalExpected = 0;
    int totalTaken = 0;

    for (int d = 0; d < days; d++) {
      final date = from.add(Duration(days: d));
      if (med.frequency == MedFrequency.everyOtherDay) {
        final daysSinceStart = date.difference(med.startDate).inDays;
        if (daysSinceStart % 2 != 0) continue;
      }
      if (med.frequency == MedFrequency.weekly) {
        if (date.weekday != med.startDate.weekday) continue;
      }
      totalExpected += expectedPerDay;
      for (final time in med.scheduledTimes) {
        final hasLog = medLogs.any((l) =>
            l.taken && l.scheduledTime == time && _sameDay(l.timestamp, date));
        if (hasLog) totalTaken++;
      }
    }

    if (totalExpected == 0) return 1.0;
    return (totalTaken / totalExpected).clamp(0.0, 1.0);
  }

  /// Current streak of consecutive days with full adherence.
  int currentStreak(Medication med, List<DoseLog> logs) {
    if (med.frequency == MedFrequency.asNeeded) return 0;
    final medLogs = logs.where((l) => l.medicationId == med.id).toList();
    final today = DateTime.now();
    int streak = 0;

    for (int d = 0; d < 365; d++) {
      final date = today.subtract(Duration(days: d));
      if (date.isBefore(med.startDate)) break;

      if (med.frequency == MedFrequency.everyOtherDay) {
        final daysSinceStart = date.difference(med.startDate).inDays;
        if (daysSinceStart % 2 != 0) continue;
      }
      if (med.frequency == MedFrequency.weekly) {
        if (date.weekday != med.startDate.weekday) continue;
      }

      bool allTaken = true;
      for (final time in med.scheduledTimes) {
        final hasLog = medLogs.any((l) =>
            l.taken && l.scheduledTime == time && _sameDay(l.timestamp, date));
        if (!hasLog) { allTaken = false; break; }
      }
      if (allTaken) streak++; else break;
    }
    return streak;
  }

  /// Longest streak ever.
  int longestStreak(Medication med, List<DoseLog> logs) {
    if (med.frequency == MedFrequency.asNeeded) return 0;
    final medLogs = logs.where((l) => l.medicationId == med.id).toList();
    final today = DateTime.now();
    final days = today.difference(med.startDate).inDays + 1;
    int longest = 0, current = 0;

    for (int d = 0; d < days; d++) {
      final date = med.startDate.add(Duration(days: d));
      if (med.frequency == MedFrequency.everyOtherDay && d % 2 != 0) continue;
      if (med.frequency == MedFrequency.weekly && date.weekday != med.startDate.weekday) continue;

      bool allTaken = true;
      for (final time in med.scheduledTimes) {
        final hasLog = medLogs.any((l) =>
            l.taken && l.scheduledTime == time && _sameDay(l.timestamp, date));
        if (!hasLog) { allTaken = false; break; }
      }
      if (allTaken) { current++; if (current > longest) longest = current; }
      else current = 0;
    }
    return longest;
  }

  /// Get today's schedule: list of (medication, doseTime, taken, skipped).
  List<Map<String, dynamic>> todaySchedule(List<Medication> meds, List<DoseLog> logs) {
    final today = DateTime.now();
    final schedule = <Map<String, dynamic>>[];

    for (final med in meds) {
      if (!med.active) continue;
      if (med.endDate != null && today.isAfter(med.endDate!)) continue;
      if (med.frequency == MedFrequency.asNeeded) continue;
      if (med.frequency == MedFrequency.everyOtherDay) {
        if (today.difference(med.startDate).inDays % 2 != 0) continue;
      }
      if (med.frequency == MedFrequency.weekly) {
        if (today.weekday != med.startDate.weekday) continue;
      }

      for (final time in med.scheduledTimes) {
        final taken = logs.any((l) =>
            l.medicationId == med.id && l.taken &&
            l.scheduledTime == time && _sameDay(l.timestamp, today));
        final skipped = logs.any((l) =>
            l.medicationId == med.id && l.skipped &&
            l.scheduledTime == time && _sameDay(l.timestamp, today));
        schedule.add({'medication': med, 'doseTime': time, 'taken': taken, 'skipped': skipped});
      }
    }

    schedule.sort((a, b) =>
        (a['doseTime'] as DoseTime).defaultHour.compareTo((b['doseTime'] as DoseTime).defaultHour));
    return schedule;
  }

  /// Most commonly reported side effects.
  Map<String, int> sideEffectFrequency(String medId, List<DoseLog> logs) {
    final counts = <String, int>{};
    for (final log in logs) {
      if (log.medicationId != medId || log.sideEffects == null || log.sideEffects!.isEmpty) continue;
      final effect = log.sideEffects!.trim().toLowerCase();
      counts[effect] = (counts[effect] ?? 0) + 1;
    }
    return Map.fromEntries(counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  /// Most commonly given skip reasons.
  Map<String, int> skipReasonFrequency(String medId, List<DoseLog> logs) {
    final counts = <String, int>{};
    for (final log in logs) {
      if (log.medicationId != medId || !log.skipped || log.skipReason == null || log.skipReason!.isEmpty) continue;
      final reason = log.skipReason!.trim().toLowerCase();
      counts[reason] = (counts[reason] ?? 0) + 1;
    }
    return Map.fromEntries(counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)));
  }

  /// Weekly adherence for last N weeks.
  List<Map<String, dynamic>> weeklyAdherence(Medication med, List<DoseLog> logs, {int weeks = 4}) {
    final today = DateTime.now();
    final result = <Map<String, dynamic>>[];
    for (int w = weeks - 1; w >= 0; w--) {
      final weekEnd = today.subtract(Duration(days: w * 7));
      final weekStart = weekEnd.subtract(const Duration(days: 6));
      result.add({'weekStart': weekStart, 'weekEnd': weekEnd, 'rate': adherenceRate(med, logs, weekStart, weekEnd)});
    }
    return result;
  }

  String adherenceGrade(double rate) {
    if (rate >= 0.95) return 'A+';
    if (rate >= 0.90) return 'A';
    if (rate >= 0.80) return 'B';
    if (rate >= 0.70) return 'C';
    if (rate >= 0.50) return 'D';
    return 'F';
  }

  String adherenceColor(double rate) {
    if (rate >= 0.90) return '#4CAF50';
    if (rate >= 0.70) return '#FF9800';
    return '#F44336';
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}
