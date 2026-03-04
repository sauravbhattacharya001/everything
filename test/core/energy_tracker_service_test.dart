import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/energy_entry.dart';
import 'package:everything/models/sleep_entry.dart';
import 'package:everything/core/services/energy_tracker_service.dart';

void main() {
  late EnergyTrackerService service;

  setUp(() {
    service = EnergyTrackerService();
  });

  // ─── Helper ─────────────────────────────────────────────────

  EnergyEntry _entry({
    String id = 'e1',
    required DateTime timestamp,
    EnergyLevel level = EnergyLevel.moderate,
    String? note,
    List<EnergyFactor> factors = const [],
  }) {
    return EnergyEntry(
      id: id,
      timestamp: timestamp,
      level: level,
      note: note,
      factors: factors,
    );
  }

  // ─── EnergyLevel enum ─────────────────────────────────────────

  group('EnergyLevel', () {
    test('fromValue returns correct level', () {
      expect(EnergyLevel.fromValue(1), EnergyLevel.exhausted);
      expect(EnergyLevel.fromValue(2), EnergyLevel.low);
      expect(EnergyLevel.fromValue(3), EnergyLevel.moderate);
      expect(EnergyLevel.fromValue(4), EnergyLevel.high);
      expect(EnergyLevel.fromValue(5), EnergyLevel.peak);
    });

    test('fromValue defaults to moderate for invalid values', () {
      expect(EnergyLevel.fromValue(0), EnergyLevel.moderate);
      expect(EnergyLevel.fromValue(99), EnergyLevel.moderate);
      expect(EnergyLevel.fromValue(-1), EnergyLevel.moderate);
    });

    test('value roundtrips correctly', () {
      for (final level in EnergyLevel.values) {
        expect(EnergyLevel.fromValue(level.value), level);
      }
    });

    test('every level has non-empty label and emoji', () {
      for (final level in EnergyLevel.values) {
        expect(level.label.isNotEmpty, true);
        expect(level.emoji.isNotEmpty, true);
      }
    });

    test('values are monotonically increasing', () {
      for (var i = 0; i < EnergyLevel.values.length - 1; i++) {
        expect(
          EnergyLevel.values[i].value < EnergyLevel.values[i + 1].value,
          true,
        );
      }
    });
  });

  // ─── TimeSlot enum ────────────────────────────────────────────

  group('TimeSlot', () {
    test('fromHour maps correctly', () {
      expect(TimeSlot.fromHour(6), TimeSlot.earlyMorning);
      expect(TimeSlot.fromHour(9), TimeSlot.morning);
      expect(TimeSlot.fromHour(12), TimeSlot.midday);
      expect(TimeSlot.fromHour(15), TimeSlot.afternoon);
      expect(TimeSlot.fromHour(19), TimeSlot.evening);
      expect(TimeSlot.fromHour(22), TimeSlot.night);
      expect(TimeSlot.fromHour(3), TimeSlot.night);
      expect(TimeSlot.fromHour(0), TimeSlot.night);
    });

    test('boundary hours', () {
      expect(TimeSlot.fromHour(5), TimeSlot.earlyMorning);
      expect(TimeSlot.fromHour(8), TimeSlot.morning);
      expect(TimeSlot.fromHour(11), TimeSlot.midday);
      expect(TimeSlot.fromHour(14), TimeSlot.afternoon);
      expect(TimeSlot.fromHour(17), TimeSlot.evening);
      expect(TimeSlot.fromHour(21), TimeSlot.night);
    });

    test('every slot has non-empty label and emoji', () {
      for (final slot in TimeSlot.values) {
        expect(slot.label.isNotEmpty, true);
        expect(slot.emoji.isNotEmpty, true);
      }
    });

    test('every slot has hour range', () {
      for (final slot in TimeSlot.values) {
        expect(slot.hourRange.length, 2);
      }
    });
  });

  // ─── EnergyFactor enum ────────────────────────────────────────

  group('EnergyFactor', () {
    test('every factor has label and emoji', () {
      for (final factor in EnergyFactor.values) {
        expect(factor.label.isNotEmpty, true);
        expect(factor.emoji.isNotEmpty, true);
      }
    });

    test('has at least 10 factors', () {
      expect(EnergyFactor.values.length, greaterThanOrEqualTo(10));
    });
  });

  // ─── EnergyEntry model ────────────────────────────────────────

  group('EnergyEntry', () {
    test('JSON roundtrip preserves all fields', () {
      final entry = EnergyEntry(
        id: 'test-1',
        timestamp: DateTime(2026, 3, 4, 10, 30),
        level: EnergyLevel.high,
        note: 'Feeling energized',
        factors: [EnergyFactor.caffeine, EnergyFactor.exercise],
      );
      final json = entry.toJson();
      final restored = EnergyEntry.fromJson(json);

      expect(restored.id, entry.id);
      expect(restored.timestamp, entry.timestamp);
      expect(restored.level, entry.level);
      expect(restored.note, entry.note);
      expect(restored.factors, entry.factors);
    });

    test('fromJson handles missing fields gracefully', () {
      final entry = EnergyEntry.fromJson({
        'id': 'x',
        'timestamp': '2026-03-04T12:00:00.000',
        'level': 3,
      });
      expect(entry.level, EnergyLevel.moderate);
      expect(entry.note, isNull);
      expect(entry.factors, isEmpty);
    });

    test('encodeList and decodeList roundtrip', () {
      final entries = [
        EnergyEntry(
          id: 'a',
          timestamp: DateTime(2026, 3, 4, 9, 0),
          level: EnergyLevel.peak,
          factors: [EnergyFactor.exercise],
        ),
        EnergyEntry(
          id: 'b',
          timestamp: DateTime(2026, 3, 4, 15, 0),
          level: EnergyLevel.low,
        ),
      ];
      final json = EnergyEntry.encodeList(entries);
      final restored = EnergyEntry.decodeList(json);

      expect(restored.length, 2);
      expect(restored[0].id, 'a');
      expect(restored[0].level, EnergyLevel.peak);
      expect(restored[1].id, 'b');
      expect(restored[1].level, EnergyLevel.low);
    });

    test('copyWith creates modified copy', () {
      final original = EnergyEntry(
        id: 'orig',
        timestamp: DateTime(2026, 3, 4, 10, 0),
        level: EnergyLevel.moderate,
        note: 'original note',
      );
      final modified = original.copyWith(
        level: EnergyLevel.peak,
        note: 'new note',
      );

      expect(modified.id, 'orig');
      expect(modified.level, EnergyLevel.peak);
      expect(modified.note, 'new note');
      expect(original.level, EnergyLevel.moderate); // unchanged
    });

    test('timeSlot returns correct slot', () {
      final morning = EnergyEntry(
        id: 'x',
        timestamp: DateTime(2026, 3, 4, 9, 30),
        level: EnergyLevel.high,
      );
      expect(morning.timeSlot, TimeSlot.morning);

      final night = EnergyEntry(
        id: 'y',
        timestamp: DateTime(2026, 3, 4, 23, 0),
        level: EnergyLevel.low,
      );
      expect(night.timeSlot, TimeSlot.night);
    });
  });

  // ─── Time Slot Averages ───────────────────────────────────────

  group('timeSlotAverages', () {
    test('returns empty for no entries', () {
      expect(service.timeSlotAverages([]), isEmpty);
    });

    test('computes correct averages', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0), level: EnergyLevel.high),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 10, 0), level: EnergyLevel.peak),
        _entry(id: '3', timestamp: DateTime(2026, 3, 4, 15, 0), level: EnergyLevel.low),
      ];
      final avgs = service.timeSlotAverages(entries);

      final morningAvg = avgs.firstWhere((a) => a.slot == TimeSlot.morning);
      expect(morningAvg.average, 4.5); // (4+5)/2
      expect(morningAvg.count, 2);

      final afternoonAvg = avgs.firstWhere((a) => a.slot == TimeSlot.afternoon);
      expect(afternoonAvg.average, 2.0);
      expect(afternoonAvg.count, 1);
    });

    test('only includes slots with data', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0)),
      ];
      final avgs = service.timeSlotAverages(entries);
      expect(avgs.length, 1);
      expect(avgs.first.slot, TimeSlot.morning);
    });
  });

  // ─── Peak/Trough Slots ────────────────────────────────────────

  group('peakTimeSlot / troughTimeSlot', () {
    test('returns null for empty entries', () {
      expect(service.peakTimeSlot([]), isNull);
      expect(service.troughTimeSlot([]), isNull);
    });

    test('identifies correct peak and trough', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 6, 0), level: EnergyLevel.moderate),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 9, 0), level: EnergyLevel.peak),
        _entry(id: '3', timestamp: DateTime(2026, 3, 4, 15, 0), level: EnergyLevel.exhausted),
        _entry(id: '4', timestamp: DateTime(2026, 3, 4, 20, 0), level: EnergyLevel.low),
      ];
      expect(service.peakTimeSlot(entries), TimeSlot.morning);
      expect(service.troughTimeSlot(entries), TimeSlot.afternoon);
    });
  });

  // ─── Factor Analysis ──────────────────────────────────────────

  group('factorAnalysis', () {
    test('returns empty for no entries', () {
      expect(service.factorAnalysis([]), isEmpty);
    });

    test('computes correct factor impact', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0),
            level: EnergyLevel.peak, factors: [EnergyFactor.exercise]),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 10, 0),
            level: EnergyLevel.high, factors: [EnergyFactor.exercise]),
        _entry(id: '3', timestamp: DateTime(2026, 3, 4, 14, 0),
            level: EnergyLevel.low, factors: []),
        _entry(id: '4', timestamp: DateTime(2026, 3, 4, 15, 0),
            level: EnergyLevel.exhausted, factors: []),
      ];
      final impacts = service.factorAnalysis(entries);
      final exerciseImpact = impacts.firstWhere(
        (i) => i.factor == EnergyFactor.exercise,
      );
      expect(exerciseImpact.avgWithFactor, 4.5); // (5+4)/2
      expect(exerciseImpact.avgWithout, 1.5);    // (2+1)/2
      expect(exerciseImpact.delta, 3.0);
      expect(exerciseImpact.isPositive, true);
      expect(exerciseImpact.occurrences, 2);
    });

    test('detects energy drainers', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0),
            level: EnergyLevel.exhausted, factors: [EnergyFactor.stress]),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 10, 0),
            level: EnergyLevel.high, factors: []),
        _entry(id: '3', timestamp: DateTime(2026, 3, 4, 14, 0),
            level: EnergyLevel.peak, factors: []),
      ];
      final drainers = service.energyDrainers(entries);
      expect(drainers.isNotEmpty, true);
      expect(drainers.first.factor, EnergyFactor.stress);
      expect(drainers.first.delta, lessThan(0));
    });

    test('energyBoosters sorted by delta descending', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0),
            level: EnergyLevel.peak, factors: [EnergyFactor.exercise]),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 10, 0),
            level: EnergyLevel.high, factors: [EnergyFactor.caffeine]),
        _entry(id: '3', timestamp: DateTime(2026, 3, 4, 14, 0),
            level: EnergyLevel.low, factors: []),
      ];
      final boosters = service.energyBoosters(entries);
      if (boosters.length >= 2) {
        expect(boosters[0].delta, greaterThanOrEqualTo(boosters[1].delta));
      }
    });
  });

  // ─── Daily Summaries ──────────────────────────────────────────

  group('dailySummaries', () {
    test('returns empty for no entries', () {
      expect(service.dailySummaries([]), isEmpty);
    });

    test('groups entries by date correctly', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0), level: EnergyLevel.high),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 15, 0), level: EnergyLevel.low),
        _entry(id: '3', timestamp: DateTime(2026, 3, 5, 10, 0), level: EnergyLevel.peak),
      ];
      final summaries = service.dailySummaries(entries);
      expect(summaries.length, 2);
      expect(summaries[0].entryCount, 2); // March 4
      expect(summaries[1].entryCount, 1); // March 5
    });

    test('computes correct peak and trough', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 6, 0), level: EnergyLevel.moderate),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 9, 0), level: EnergyLevel.peak),
        _entry(id: '3', timestamp: DateTime(2026, 3, 4, 15, 0), level: EnergyLevel.exhausted),
      ];
      final summary = service.dailySummaries(entries).first;
      expect(summary.peakValue, 5);
      expect(summary.troughValue, 1);
      expect(summary.range, 4);
      expect(summary.peakSlot, TimeSlot.morning);
      expect(summary.troughSlot, TimeSlot.afternoon);
    });

    test('collects top factors', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0),
            factors: [EnergyFactor.caffeine, EnergyFactor.exercise]),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 15, 0),
            factors: [EnergyFactor.caffeine]),
      ];
      final summary = service.dailySummaries(entries).first;
      expect(summary.topFactors.first, EnergyFactor.caffeine); // 2 occurrences
    });

    test('dateLabel formats correctly', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0)),
      ];
      expect(service.dailySummaries(entries).first.dateLabel, '2026-03-04');
    });
  });

  // ─── Daily Averages ───────────────────────────────────────────

  group('dailyAverages', () {
    test('filters to last N days', () {
      final now = DateTime(2026, 3, 10);
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 9, 9, 0), level: EnergyLevel.high),
        _entry(id: '2', timestamp: DateTime(2026, 3, 1, 9, 0), level: EnergyLevel.low),
        _entry(id: '3', timestamp: DateTime(2026, 2, 1, 9, 0), level: EnergyLevel.peak),
      ];
      final avgs = service.dailyAverages(entries, days: 14, relativeTo: now);
      expect(avgs.length, 2); // March 9 and March 1
    });
  });

  // ─── Streaks ──────────────────────────────────────────────────

  group('streaks', () {
    test('returns null for empty entries', () {
      final result = service.streaks([]);
      expect(result['current'], isNull);
      expect(result['longest'], isNull);
    });

    test('detects single-day streak', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0)),
      ];
      final result = service.streaks(entries, relativeTo: DateTime(2026, 3, 4, 20, 0));
      expect(result['current']!.days, 1);
      expect(result['longest']!.days, 1);
    });

    test('detects multi-day consecutive streak', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 1, 9, 0)),
        _entry(id: '2', timestamp: DateTime(2026, 3, 2, 10, 0)),
        _entry(id: '3', timestamp: DateTime(2026, 3, 3, 11, 0)),
        _entry(id: '4', timestamp: DateTime(2026, 3, 4, 9, 0)),
      ];
      final result = service.streaks(entries, relativeTo: DateTime(2026, 3, 4, 20, 0));
      expect(result['current']!.days, 4);
      expect(result['longest']!.days, 4);
    });

    test('broken streak: current is null if gap to today', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 1, 9, 0)),
        _entry(id: '2', timestamp: DateTime(2026, 3, 2, 10, 0)),
      ];
      // Today is March 5 — gap of 3 days
      final result = service.streaks(entries, relativeTo: DateTime(2026, 3, 5));
      expect(result['current'], isNull);
      expect(result['longest']!.days, 2);
    });

    test('identifies longest streak across multiple streaks', () {
      final entries = [
        // Streak 1: 2 days
        _entry(id: '1', timestamp: DateTime(2026, 3, 1, 9, 0)),
        _entry(id: '2', timestamp: DateTime(2026, 3, 2, 10, 0)),
        // Gap
        // Streak 2: 3 days
        _entry(id: '3', timestamp: DateTime(2026, 3, 5, 9, 0)),
        _entry(id: '4', timestamp: DateTime(2026, 3, 6, 10, 0)),
        _entry(id: '5', timestamp: DateTime(2026, 3, 7, 11, 0)),
      ];
      final result = service.streaks(entries, relativeTo: DateTime(2026, 3, 7, 20, 0));
      expect(result['longest']!.days, 3);
      expect(result['current']!.days, 3);
    });
  });

  // ─── Trend ────────────────────────────────────────────────────

  group('trend', () {
    test('returns null for too few days', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0)),
      ];
      expect(service.trend(entries), isNull);
    });

    test('detects improving trend', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 1, 9, 0), level: EnergyLevel.exhausted),
        _entry(id: '2', timestamp: DateTime(2026, 3, 2, 9, 0), level: EnergyLevel.low),
        _entry(id: '3', timestamp: DateTime(2026, 3, 3, 9, 0), level: EnergyLevel.moderate),
        _entry(id: '4', timestamp: DateTime(2026, 3, 4, 9, 0), level: EnergyLevel.high),
        _entry(id: '5', timestamp: DateTime(2026, 3, 5, 9, 0), level: EnergyLevel.peak),
      ];
      final t = service.trend(entries);
      expect(t, isNotNull);
      expect(t!.slope, greaterThan(0));
      expect(t.direction, 'improving');
    });

    test('detects declining trend', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 1, 9, 0), level: EnergyLevel.peak),
        _entry(id: '2', timestamp: DateTime(2026, 3, 2, 9, 0), level: EnergyLevel.high),
        _entry(id: '3', timestamp: DateTime(2026, 3, 3, 9, 0), level: EnergyLevel.moderate),
        _entry(id: '4', timestamp: DateTime(2026, 3, 4, 9, 0), level: EnergyLevel.low),
        _entry(id: '5', timestamp: DateTime(2026, 3, 5, 9, 0), level: EnergyLevel.exhausted),
      ];
      final t = service.trend(entries);
      expect(t!.slope, lessThan(0));
      expect(t.direction, 'declining');
    });

    test('stable trend for constant energy', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 1, 9, 0), level: EnergyLevel.moderate),
        _entry(id: '2', timestamp: DateTime(2026, 3, 2, 9, 0), level: EnergyLevel.moderate),
        _entry(id: '3', timestamp: DateTime(2026, 3, 3, 9, 0), level: EnergyLevel.moderate),
      ];
      final t = service.trend(entries);
      expect(t!.direction, 'stable');
    });
  });

  // ─── Sleep-Energy Correlation ─────────────────────────────────

  group('sleepEnergyCorrelation', () {
    test('returns empty for no data', () {
      expect(service.sleepEnergyCorrelation([], []), isEmpty);
    });

    test('correlates sleep quality with energy', () {
      final energyEntries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0), level: EnergyLevel.peak),
        _entry(id: '2', timestamp: DateTime(2026, 3, 5, 9, 0), level: EnergyLevel.low),
      ];
      final sleepEntries = [
        SleepEntry(
          id: 's1',
          bedtime: DateTime(2026, 3, 3, 22, 0),
          wakeTime: DateTime(2026, 3, 4, 7, 0),
          quality: SleepQuality.excellent,
        ),
        SleepEntry(
          id: 's2',
          bedtime: DateTime(2026, 3, 4, 23, 0),
          wakeTime: DateTime(2026, 3, 5, 5, 0),
          quality: SleepQuality.terrible,
        ),
      ];

      final corr = service.sleepEnergyCorrelation(energyEntries, sleepEntries);
      expect(corr[5], 5.0); // Quality 5 -> energy 5
      expect(corr[1], 2.0); // Quality 1 -> energy 2
    });
  });

  // ─── Recommendations ─────────────────────────────────────────

  group('recommendations', () {
    test('returns empty for no entries', () {
      expect(service.recommendations([]), isEmpty);
    });

    test('generates peak time recommendation', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0), level: EnergyLevel.peak),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 15, 0), level: EnergyLevel.low),
      ];
      final recs = service.recommendations(entries);
      expect(recs.any((r) => r.category == 'timing'), true);
    });

    test('detects low energy warning', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0), level: EnergyLevel.exhausted),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 15, 0), level: EnergyLevel.low),
      ];
      final recs = service.recommendations(entries);
      expect(recs.any((r) => r.category == 'warning'), true);
    });

    test('detects afternoon crash', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0), level: EnergyLevel.peak),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 10, 0), level: EnergyLevel.peak),
        _entry(id: '3', timestamp: DateTime(2026, 3, 4, 15, 0), level: EnergyLevel.low),
        _entry(id: '4', timestamp: DateTime(2026, 3, 4, 16, 0), level: EnergyLevel.exhausted),
      ];
      final recs = service.recommendations(entries);
      expect(recs.any((r) => r.title.contains('Afternoon')), true);
    });

    test('suggests more logging when few entries per day', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 1, 9, 0)),
        _entry(id: '2', timestamp: DateTime(2026, 3, 2, 9, 0)),
        _entry(id: '3', timestamp: DateTime(2026, 3, 3, 9, 0)),
      ];
      final recs = service.recommendations(entries);
      expect(recs.any((r) => r.title.contains('Log more')), true);
    });

    test('includes factor-based recommendations', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0),
            level: EnergyLevel.peak, factors: [EnergyFactor.exercise]),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 10, 0),
            level: EnergyLevel.peak, factors: [EnergyFactor.exercise]),
        _entry(id: '3', timestamp: DateTime(2026, 3, 4, 14, 0),
            level: EnergyLevel.low, factors: []),
        _entry(id: '4', timestamp: DateTime(2026, 3, 4, 15, 0),
            level: EnergyLevel.low, factors: []),
      ];
      final recs = service.recommendations(entries);
      expect(recs.any((r) => r.category == 'factor'), true);
    });
  });

  // ─── Filtering ────────────────────────────────────────────────

  group('filtering', () {
    test('filterByDateRange includes boundary', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 3, 9, 0)),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 9, 0)),
        _entry(id: '3', timestamp: DateTime(2026, 3, 5, 9, 0)),
      ];
      final filtered = service.filterByDateRange(
        entries,
        DateTime(2026, 3, 4),
        DateTime(2026, 3, 5),
      );
      expect(filtered.length, 1);
      expect(filtered.first.id, '2');
    });

    test('filterByTimeSlot', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0)),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 15, 0)),
        _entry(id: '3', timestamp: DateTime(2026, 3, 4, 22, 0)),
      ];
      final morning = service.filterByTimeSlot(entries, TimeSlot.morning);
      expect(morning.length, 1);
      expect(morning.first.id, '1');
    });
  });

  // ─── Overall Average ──────────────────────────────────────────

  group('overallAverage', () {
    test('returns 0 for empty entries', () {
      expect(service.overallAverage([]), 0.0);
    });

    test('computes correct average', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0), level: EnergyLevel.high),
        _entry(id: '2', timestamp: DateTime(2026, 3, 4, 15, 0), level: EnergyLevel.low),
      ];
      expect(service.overallAverage(entries), 3.0); // (4+2)/2
    });
  });

  // ─── Stability ────────────────────────────────────────────────

  group('stability', () {
    test('zero for too few days', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 4, 9, 0)),
      ];
      expect(service.stability(entries), 0.0);
    });

    test('zero for constant energy', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 1, 9, 0), level: EnergyLevel.moderate),
        _entry(id: '2', timestamp: DateTime(2026, 3, 2, 9, 0), level: EnergyLevel.moderate),
        _entry(id: '3', timestamp: DateTime(2026, 3, 3, 9, 0), level: EnergyLevel.moderate),
      ];
      expect(service.stability(entries), 0.0);
    });

    test('higher for volatile energy', () {
      final stable = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 1, 9, 0), level: EnergyLevel.moderate),
        _entry(id: '2', timestamp: DateTime(2026, 3, 2, 9, 0), level: EnergyLevel.moderate),
        _entry(id: '3', timestamp: DateTime(2026, 3, 3, 9, 0), level: EnergyLevel.moderate),
      ];
      final volatile_ = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 1, 9, 0), level: EnergyLevel.exhausted),
        _entry(id: '2', timestamp: DateTime(2026, 3, 2, 9, 0), level: EnergyLevel.peak),
        _entry(id: '3', timestamp: DateTime(2026, 3, 3, 9, 0), level: EnergyLevel.exhausted),
      ];
      expect(service.stability(volatile_), greaterThan(service.stability(stable)));
    });
  });

  // ─── Report ───────────────────────────────────────────────────

  group('generateReport', () {
    test('generates report with all fields', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 1, 6, 0), level: EnergyLevel.moderate,
            factors: [EnergyFactor.caffeine]),
        _entry(id: '2', timestamp: DateTime(2026, 3, 1, 9, 0), level: EnergyLevel.peak,
            factors: [EnergyFactor.exercise]),
        _entry(id: '3', timestamp: DateTime(2026, 3, 1, 15, 0), level: EnergyLevel.low),
        _entry(id: '4', timestamp: DateTime(2026, 3, 2, 9, 0), level: EnergyLevel.high),
        _entry(id: '5', timestamp: DateTime(2026, 3, 2, 15, 0), level: EnergyLevel.moderate),
        _entry(id: '6', timestamp: DateTime(2026, 3, 3, 10, 0), level: EnergyLevel.peak),
      ];
      final report = service.generateReport(entries);

      expect(report.totalEntries, 6);
      expect(report.totalDays, 3);
      expect(report.overallAverage, greaterThan(0));
      expect(report.slotAverages, isNotEmpty);
      expect(report.dailySummaries.length, 3);
      expect(report.recommendations, isNotEmpty);
      expect(report.peakSlot, isNotNull);
      expect(report.troughSlot, isNotNull);
    });
  });

  // ─── Text Summary ────────────────────────────────────────────

  group('textSummary', () {
    test('returns message for empty entries', () {
      expect(service.textSummary([]), contains('No energy entries'));
    });

    test('generates readable summary', () {
      final entries = [
        _entry(id: '1', timestamp: DateTime(2026, 3, 1, 9, 0), level: EnergyLevel.peak,
            factors: [EnergyFactor.exercise]),
        _entry(id: '2', timestamp: DateTime(2026, 3, 1, 15, 0), level: EnergyLevel.low),
        _entry(id: '3', timestamp: DateTime(2026, 3, 2, 9, 0), level: EnergyLevel.high),
        _entry(id: '4', timestamp: DateTime(2026, 3, 2, 15, 0), level: EnergyLevel.moderate),
        _entry(id: '5', timestamp: DateTime(2026, 3, 3, 10, 0), level: EnergyLevel.peak),
      ];
      final summary = service.textSummary(entries);
      expect(summary, contains('Energy Report'));
      expect(summary, contains('Overall average'));
      expect(summary, contains('Peak time'));
    });
  });
}
