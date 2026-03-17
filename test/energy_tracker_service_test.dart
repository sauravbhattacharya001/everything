import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/energy_tracker_service.dart';
import 'package:everything/models/energy_entry.dart';
import 'package:everything/models/sleep_entry.dart';

/// Helper to create an EnergyEntry at a specific hour with a given level.
EnergyEntry _entry({
  required int hour,
  required EnergyLevel level,
  List<EnergyFactor> factors = const [],
  DateTime? date,
  String? id,
}) {
  final d = date ?? DateTime(2026, 3, 10);
  return EnergyEntry(
    id: id ?? '${d.toIso8601String()}-$hour',
    timestamp: DateTime(d.year, d.month, d.day, hour),
    level: level,
    factors: factors,
  );
}

void main() {
  late EnergyTrackerService service;

  setUp(() {
    service = EnergyTrackerService();
  });

  group('timeSlotAverages', () {
    test('returns empty list for empty entries', () {
      expect(service.timeSlotAverages([]), isEmpty);
    });

    test('computes correct average per slot', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.high), // morning
        _entry(hour: 10, level: EnergyLevel.peak), // morning
        _entry(hour: 15, level: EnergyLevel.low), // afternoon
      ];
      final avgs = service.timeSlotAverages(entries);

      final morning = avgs.firstWhere((a) => a.slot == TimeSlot.morning);
      expect(morning.average, 4.5); // (4+5)/2
      expect(morning.count, 2);

      final afternoon = avgs.firstWhere((a) => a.slot == TimeSlot.afternoon);
      expect(afternoon.average, 2.0);
      expect(afternoon.count, 1);
    });

    test('only includes slots with entries', () {
      final entries = [_entry(hour: 9, level: EnergyLevel.moderate)];
      final avgs = service.timeSlotAverages(entries);
      expect(avgs.length, 1);
      expect(avgs.first.slot, TimeSlot.morning);
    });
  });

  group('peakTimeSlot / troughTimeSlot', () {
    test('returns null for empty entries', () {
      expect(service.peakTimeSlot([]), isNull);
      expect(service.troughTimeSlot([]), isNull);
    });

    test('identifies peak and trough correctly', () {
      final entries = [
        _entry(hour: 6, level: EnergyLevel.moderate), // early morning
        _entry(hour: 9, level: EnergyLevel.peak), // morning
        _entry(hour: 15, level: EnergyLevel.exhausted), // afternoon
        _entry(hour: 20, level: EnergyLevel.high), // evening
      ];
      expect(service.peakTimeSlot(entries), TimeSlot.morning);
      expect(service.troughTimeSlot(entries), TimeSlot.afternoon);
    });
  });

  group('factorAnalysis', () {
    test('returns empty for empty entries', () {
      expect(service.factorAnalysis([]), isEmpty);
    });

    test('calculates factor impact delta correctly', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.peak, factors: [EnergyFactor.exercise]),
        _entry(hour: 10, level: EnergyLevel.peak, factors: [EnergyFactor.exercise]),
        _entry(hour: 11, level: EnergyLevel.low, factors: []),
        _entry(hour: 15, level: EnergyLevel.low, factors: []),
      ];
      final impacts = service.factorAnalysis(entries);
      final exerciseImpact =
          impacts.firstWhere((i) => i.factor == EnergyFactor.exercise);

      // With exercise: avg 5.0, without: avg 2.0, delta: +3.0
      expect(exerciseImpact.avgWithFactor, 5.0);
      expect(exerciseImpact.avgWithout, 2.0);
      expect(exerciseImpact.delta, 3.0);
      expect(exerciseImpact.isPositive, isTrue);
      expect(exerciseImpact.occurrences, 2);
    });

    test('skips factors present in all or no entries', () {
      // caffeine in ALL entries → no "without" group → skipped
      final entries = [
        _entry(hour: 9, level: EnergyLevel.high, factors: [EnergyFactor.caffeine]),
        _entry(hour: 10, level: EnergyLevel.moderate, factors: [EnergyFactor.caffeine]),
      ];
      final impacts = service.factorAnalysis(entries);
      expect(impacts.where((i) => i.factor == EnergyFactor.caffeine), isEmpty);
    });

    test('sorts by absolute delta descending', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.peak, factors: [EnergyFactor.exercise]),
        _entry(hour: 10, level: EnergyLevel.exhausted, factors: [EnergyFactor.stress]),
        _entry(hour: 11, level: EnergyLevel.moderate, factors: []),
      ];
      final impacts = service.factorAnalysis(entries);
      // First impact should have largest absolute delta
      if (impacts.length >= 2) {
        expect(impacts[0].delta.abs(), greaterThanOrEqualTo(impacts[1].delta.abs()));
      }
    });
  });

  group('energyBoosters / energyDrainers', () {
    test('separates positive and negative impacts', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.peak, factors: [EnergyFactor.exercise]),
        _entry(hour: 10, level: EnergyLevel.exhausted, factors: [EnergyFactor.stress]),
        _entry(hour: 11, level: EnergyLevel.moderate, factors: []),
      ];
      final boosters = service.energyBoosters(entries);
      final drainers = service.energyDrainers(entries);

      for (final b in boosters) {
        expect(b.delta, greaterThan(0));
      }
      for (final d in drainers) {
        expect(d.delta, lessThan(0));
      }
    });
  });

  group('dailySummaries', () {
    test('returns empty for empty entries', () {
      expect(service.dailySummaries([]), isEmpty);
    });

    test('groups by day and computes stats', () {
      final day1 = DateTime(2026, 3, 10);
      final day2 = DateTime(2026, 3, 11);
      final entries = [
        _entry(hour: 9, level: EnergyLevel.peak, date: day1),
        _entry(hour: 15, level: EnergyLevel.low, date: day1),
        _entry(hour: 9, level: EnergyLevel.moderate, date: day2),
      ];
      final summaries = service.dailySummaries(entries);
      expect(summaries.length, 2);

      final s1 = summaries.first;
      expect(s1.date, day1);
      expect(s1.peakValue, 5);
      expect(s1.troughValue, 2);
      expect(s1.range, 3);
      expect(s1.entryCount, 2);
      expect(s1.average, 3.5);

      final s2 = summaries.last;
      expect(s2.entryCount, 1);
      expect(s2.average, 3.0);
    });

    test('returns sorted by date ascending', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 12)),
        _entry(hour: 9, level: EnergyLevel.high, date: DateTime(2026, 3, 10)),
      ];
      final summaries = service.dailySummaries(entries);
      expect(summaries.first.date.isBefore(summaries.last.date), isTrue);
    });

    test('includes top factors for the day', () {
      final entries = [
        _entry(
          hour: 9,
          level: EnergyLevel.high,
          factors: [EnergyFactor.caffeine, EnergyFactor.exercise],
        ),
        _entry(
          hour: 15,
          level: EnergyLevel.moderate,
          factors: [EnergyFactor.caffeine],
        ),
      ];
      final summaries = service.dailySummaries(entries);
      // caffeine appears twice, exercise once → caffeine should be first
      expect(summaries.first.topFactors.first, EnergyFactor.caffeine);
    });
  });

  group('streaks', () {
    test('returns null streaks for empty entries', () {
      final result = service.streaks([]);
      expect(result['current'], isNull);
      expect(result['longest'], isNull);
    });

    test('detects single-day streak', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 17)),
      ];
      final result = service.streaks(entries, relativeTo: DateTime(2026, 3, 17));
      expect(result['current']?.days, 1);
      expect(result['longest']?.days, 1);
    });

    test('detects multi-day consecutive streak', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 14)),
        _entry(hour: 9, level: EnergyLevel.high, date: DateTime(2026, 3, 15)),
        _entry(hour: 9, level: EnergyLevel.peak, date: DateTime(2026, 3, 16)),
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 17)),
      ];
      final result = service.streaks(entries, relativeTo: DateTime(2026, 3, 17));
      expect(result['current']?.days, 4);
      expect(result['longest']?.days, 4);
    });

    test('breaks streak on gap days', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 10)),
        _entry(hour: 9, level: EnergyLevel.high, date: DateTime(2026, 3, 11)),
        // gap on 12th
        _entry(hour: 9, level: EnergyLevel.peak, date: DateTime(2026, 3, 13)),
      ];
      final result = service.streaks(entries, relativeTo: DateTime(2026, 3, 13));
      expect(result['longest']?.days, 2); // 10-11
      expect(result['current']?.days, 1); // 13 only
    });

    test('current streak is null if last entry is old', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 10)),
      ];
      final result = service.streaks(entries, relativeTo: DateTime(2026, 3, 17));
      expect(result['current'], isNull);
      expect(result['longest']?.days, 1);
    });
  });

  group('trend', () {
    test('returns null with fewer than minDays', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 10)),
        _entry(hour: 9, level: EnergyLevel.high, date: DateTime(2026, 3, 11)),
      ];
      expect(service.trend(entries, minDays: 3), isNull);
    });

    test('detects improving trend', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.exhausted, date: DateTime(2026, 3, 10)),
        _entry(hour: 9, level: EnergyLevel.low, date: DateTime(2026, 3, 11)),
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 12)),
        _entry(hour: 9, level: EnergyLevel.high, date: DateTime(2026, 3, 13)),
        _entry(hour: 9, level: EnergyLevel.peak, date: DateTime(2026, 3, 14)),
      ];
      final t = service.trend(entries);
      expect(t, isNotNull);
      expect(t!.direction, 'improving');
      expect(t.slope, greaterThan(0));
      expect(t.days, 5);
    });

    test('detects declining trend', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.peak, date: DateTime(2026, 3, 10)),
        _entry(hour: 9, level: EnergyLevel.high, date: DateTime(2026, 3, 11)),
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 12)),
        _entry(hour: 9, level: EnergyLevel.low, date: DateTime(2026, 3, 13)),
        _entry(hour: 9, level: EnergyLevel.exhausted, date: DateTime(2026, 3, 14)),
      ];
      final t = service.trend(entries);
      expect(t, isNotNull);
      expect(t!.direction, 'declining');
      expect(t.slope, lessThan(0));
    });

    test('detects stable trend', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 10)),
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 11)),
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 12)),
      ];
      final t = service.trend(entries);
      expect(t, isNotNull);
      expect(t!.direction, 'stable');
    });
  });

  group('sleepEnergyCorrelation', () {
    test('returns empty when no entries', () {
      expect(service.sleepEnergyCorrelation([], []), isEmpty);
    });

    test('correlates energy with sleep quality on same day', () {
      final energyEntries = [
        _entry(hour: 9, level: EnergyLevel.peak, date: DateTime(2026, 3, 10)),
        _entry(hour: 15, level: EnergyLevel.high, date: DateTime(2026, 3, 10)),
        _entry(hour: 9, level: EnergyLevel.low, date: DateTime(2026, 3, 11)),
      ];
      final sleepEntries = [
        SleepEntry(
          id: 's1',
          bedtime: DateTime(2026, 3, 9, 23),
          wakeTime: DateTime(2026, 3, 10, 7),
          quality: SleepQuality.excellent,
        ),
        SleepEntry(
          id: 's2',
          bedtime: DateTime(2026, 3, 10, 23),
          wakeTime: DateTime(2026, 3, 11, 7),
          quality: SleepQuality.poor,
        ),
      ];

      final corr = service.sleepEnergyCorrelation(energyEntries, sleepEntries);
      // Quality 5 (excellent) → avg energy (5+4)/2 = 4.5
      expect(corr[5], 4.5);
      // Quality 2 (poor) → avg energy 2.0
      expect(corr[2], 2.0);
    });
  });

  group('recommendations', () {
    test('returns empty for empty entries', () {
      expect(service.recommendations([]), isEmpty);
    });

    test('generates peak time recommendation', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.peak),
        _entry(hour: 15, level: EnergyLevel.low),
      ];
      final recs = service.recommendations(entries);
      expect(recs.any((r) => r.category == 'timing' && r.title.contains('Morning')),
          isTrue);
    });

    test('warns about low overall energy', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.exhausted),
        _entry(hour: 15, level: EnergyLevel.low),
      ];
      final recs = service.recommendations(entries);
      expect(recs.any((r) => r.category == 'warning'), isTrue);
    });

    test('detects afternoon energy crash', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.peak),
        _entry(hour: 10, level: EnergyLevel.peak),
        _entry(hour: 15, level: EnergyLevel.low),
        _entry(hour: 16, level: EnergyLevel.low),
      ];
      final recs = service.recommendations(entries);
      expect(
          recs.any((r) => r.title.contains('Afternoon energy crash')), isTrue);
    });

    test('suggests logging more frequently', () {
      // Many days with only 1 entry each
      final entries = List.generate(
        6,
        (i) => _entry(
          hour: 9,
          level: EnergyLevel.moderate,
          date: DateTime(2026, 3, 10 + i),
        ),
      );
      final recs = service.recommendations(entries);
      expect(recs.any((r) => r.title.contains('Log more frequently')), isTrue);
    });
  });

  group('filterByDateRange', () {
    test('includes entries within range', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 10)),
        _entry(hour: 9, level: EnergyLevel.high, date: DateTime(2026, 3, 12)),
        _entry(hour: 9, level: EnergyLevel.peak, date: DateTime(2026, 3, 15)),
      ];
      final filtered = service.filterByDateRange(
        entries,
        DateTime(2026, 3, 11),
        DateTime(2026, 3, 14),
      );
      expect(filtered.length, 1);
      expect(filtered.first.timestamp.day, 12);
    });
  });

  group('filterByTimeSlot', () {
    test('filters to specific slot', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.moderate), // morning
        _entry(hour: 15, level: EnergyLevel.high), // afternoon
        _entry(hour: 22, level: EnergyLevel.low), // night
      ];
      final morning = service.filterByTimeSlot(entries, TimeSlot.morning);
      expect(morning.length, 1);
      expect(morning.first.timestamp.hour, 9);
    });
  });

  group('overallAverage', () {
    test('returns 0 for empty entries', () {
      expect(service.overallAverage([]), 0.0);
    });

    test('computes correct average', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.high), // 4
        _entry(hour: 15, level: EnergyLevel.low), // 2
      ];
      expect(service.overallAverage(entries), 3.0);
    });
  });

  group('stability', () {
    test('returns 0 for single day', () {
      final entries = [_entry(hour: 9, level: EnergyLevel.moderate)];
      expect(service.stability(entries), 0.0);
    });

    test('returns 0 for perfectly consistent days', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 10)),
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 11)),
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 12)),
      ];
      expect(service.stability(entries), 0.0);
    });

    test('returns higher value for volatile days', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.peak, date: DateTime(2026, 3, 10)),
        _entry(hour: 9, level: EnergyLevel.exhausted, date: DateTime(2026, 3, 11)),
        _entry(hour: 9, level: EnergyLevel.peak, date: DateTime(2026, 3, 12)),
      ];
      expect(service.stability(entries), greaterThan(1.0));
    });
  });

  group('generateReport', () {
    test('produces a complete report', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.peak, date: DateTime(2026, 3, 10),
            factors: [EnergyFactor.exercise]),
        _entry(hour: 15, level: EnergyLevel.low, date: DateTime(2026, 3, 10),
            factors: [EnergyFactor.stress]),
        _entry(hour: 9, level: EnergyLevel.high, date: DateTime(2026, 3, 11)),
        _entry(hour: 15, level: EnergyLevel.moderate, date: DateTime(2026, 3, 11)),
        _entry(hour: 9, level: EnergyLevel.moderate, date: DateTime(2026, 3, 12)),
      ];
      final report = service.generateReport(entries);

      expect(report.totalEntries, 5);
      expect(report.totalDays, 3);
      expect(report.overallAverage, greaterThan(0));
      expect(report.slotAverages, isNotEmpty);
      expect(report.dailySummaries.length, 3);
      expect(report.recommendations, isNotEmpty);
      expect(report.peakSlot, isNotNull);
    });
  });

  group('textSummary', () {
    test('returns placeholder for empty entries', () {
      expect(service.textSummary([]), 'No energy entries recorded yet.');
    });

    test('produces non-empty summary for entries', () {
      final entries = [
        _entry(hour: 9, level: EnergyLevel.peak, date: DateTime(2026, 3, 10)),
        _entry(hour: 15, level: EnergyLevel.low, date: DateTime(2026, 3, 10)),
        _entry(hour: 9, level: EnergyLevel.high, date: DateTime(2026, 3, 11)),
      ];
      final summary = service.textSummary(entries);
      expect(summary, contains('Energy Report'));
      expect(summary, contains('Overall average'));
      expect(summary, contains('Peak time'));
    });
  });

  group('data class properties', () {
    test('TimeSlotAverage label format', () {
      final tsa = TimeSlotAverage(
        slot: TimeSlot.morning,
        average: 4.2,
        count: 5,
      );
      expect(tsa.label, contains('Morning'));
      expect(tsa.label, contains('4.2'));
      expect(tsa.label, contains('5 entries'));
    });

    test('FactorImpact label with positive delta', () {
      final fi = FactorImpact(
        factor: EnergyFactor.exercise,
        avgWithFactor: 4.5,
        avgWithout: 3.0,
        delta: 1.5,
        occurrences: 10,
      );
      expect(fi.isPositive, isTrue);
      expect(fi.label, contains('+'));
    });

    test('DailyEnergySummary range and dateLabel', () {
      final des = DailyEnergySummary(
        date: DateTime(2026, 3, 5),
        average: 3.5,
        peakValue: 5,
        troughValue: 2,
        entryCount: 3,
      );
      expect(des.range, 3);
      expect(des.dateLabel, '2026-03-05');
    });
  });
}
