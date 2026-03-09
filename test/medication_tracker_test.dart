import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/medication_tracker_service.dart';
import 'package:everything/models/medication_entry.dart';

void main() {
  const service = MedicationTrackerService();
  final now = DateTime.now();

  Medication makeMed({
    String id = 'med1',
    String name = 'TestMed',
    MedFrequency frequency = MedFrequency.onceDaily,
    List<DoseTime> times = const [DoseTime.morning],
    DateTime? startDate,
    bool active = true,
  }) =>
      Medication(
        id: id, name: name, dosage: '100mg', form: MedForm.tablet,
        frequency: frequency, scheduledTimes: times,
        startDate: startDate ?? now.subtract(const Duration(days: 7)),
        active: active,
      );

  DoseLog makeLog({
    String medId = 'med1',
    required DateTime timestamp,
    DoseTime time = DoseTime.morning,
    bool taken = true,
    bool skipped = false,
    String? skipReason,
    String? sideEffects,
  }) =>
      DoseLog(
        id: 'dl${timestamp.millisecondsSinceEpoch}${time.name}',
        medicationId: medId, timestamp: timestamp, scheduledTime: time,
        taken: taken, skipped: skipped, skipReason: skipReason,
        sideEffects: sideEffects,
      );

  group('MedFrequency', () {
    test('labels are non-empty', () {
      for (final f in MedFrequency.values) {
        expect(f.label.isNotEmpty, true);
      }
    });

    test('dailyDoses returns correct counts', () {
      expect(MedFrequency.onceDaily.dailyDoses, 1);
      expect(MedFrequency.twiceDaily.dailyDoses, 2);
      expect(MedFrequency.thriceDaily.dailyDoses, 3);
      expect(MedFrequency.fourTimesDaily.dailyDoses, 4);
      expect(MedFrequency.asNeeded.dailyDoses, 0);
    });

    test('has 7 values', () {
      expect(MedFrequency.values.length, 7);
    });
  });

  group('MedForm', () {
    test('all forms have emoji and label', () {
      for (final f in MedForm.values) {
        expect(f.label.isNotEmpty, true);
        expect(f.emoji.isNotEmpty, true);
      }
    });

    test('has 9 values', () {
      expect(MedForm.values.length, 9);
    });
  });

  group('DoseTime', () {
    test('default hours increase through day', () {
      expect(DoseTime.morning.defaultHour, lessThan(DoseTime.afternoon.defaultHour));
      expect(DoseTime.afternoon.defaultHour, lessThan(DoseTime.evening.defaultHour));
      expect(DoseTime.evening.defaultHour, lessThan(DoseTime.bedtime.defaultHour));
    });

    test('has 4 values', () {
      expect(DoseTime.values.length, 4);
    });

    test('all have emoji', () {
      for (final t in DoseTime.values) {
        expect(t.emoji.isNotEmpty, true);
      }
    });
  });

  group('Medication model', () {
    test('toJson/fromJson roundtrip', () {
      final med = makeMed(times: [DoseTime.morning, DoseTime.evening]);
      final json = med.toJson();
      final restored = Medication.fromJson(json);
      expect(restored.id, med.id);
      expect(restored.name, med.name);
      expect(restored.dosage, med.dosage);
      expect(restored.form, med.form);
      expect(restored.frequency, med.frequency);
      expect(restored.scheduledTimes, med.scheduledTimes);
      expect(restored.active, true);
    });

    test('copyWith preserves unchanged fields', () {
      final med = makeMed();
      final copy = med.copyWith(name: 'NewName');
      expect(copy.name, 'NewName');
      expect(copy.id, med.id);
      expect(copy.dosage, med.dosage);
    });

    test('copyWith active toggle', () {
      final med = makeMed();
      expect(med.active, true);
      final deactivated = med.copyWith(active: false);
      expect(deactivated.active, false);
    });

    test('defaults', () {
      final med = makeMed();
      expect(med.active, true);
      expect(med.color, '#2196F3');
      expect(med.notes, isNull);
      expect(med.prescribedBy, isNull);
      expect(med.endDate, isNull);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'x', 'name': 'Test', 'dosage': '10mg', 'form': 'tablet',
        'frequency': 'onceDaily', 'scheduledTimes': ['morning'],
        'startDate': DateTime.now().toIso8601String(),
      };
      final med = Medication.fromJson(json);
      expect(med.active, true);
      expect(med.color, '#2196F3');
    });
  });

  group('DoseLog model', () {
    test('toJson/fromJson roundtrip', () {
      final log = makeLog(timestamp: now, sideEffects: 'nausea');
      final json = log.toJson();
      final restored = DoseLog.fromJson(json);
      expect(restored.id, log.id);
      expect(restored.medicationId, log.medicationId);
      expect(restored.taken, true);
      expect(restored.sideEffects, 'nausea');
    });

    test('skipped log roundtrip', () {
      final log = makeLog(timestamp: now, taken: false, skipped: true, skipReason: 'Forgot');
      final json = log.toJson();
      final restored = DoseLog.fromJson(json);
      expect(restored.skipped, true);
      expect(restored.taken, false);
      expect(restored.skipReason, 'Forgot');
    });
  });

  group('adherenceRate', () {
    test('returns 1.0 with no logs for as-needed', () {
      final med = makeMed(frequency: MedFrequency.asNeeded);
      expect(service.adherenceRate(med, [], now, now), 1.0);
    });

    test('returns 0.0 with no doses taken', () {
      final med = makeMed();
      final from = now.subtract(const Duration(days: 3));
      expect(service.adherenceRate(med, [], from, now), 0.0);
    });

    test('returns 1.0 when all doses taken', () {
      final start = now.subtract(const Duration(days: 2));
      final med = makeMed(startDate: start);
      final logs = [
        makeLog(timestamp: start),
        makeLog(timestamp: start.add(const Duration(days: 1))),
        makeLog(timestamp: start.add(const Duration(days: 2))),
      ];
      expect(service.adherenceRate(med, logs, start, now), 1.0);
    });

    test('calculates partial adherence', () {
      final start = now.subtract(const Duration(days: 3));
      final med = makeMed(startDate: start);
      final logs = [
        makeLog(timestamp: start),
        makeLog(timestamp: start.add(const Duration(days: 2))),
      ];
      final rate = service.adherenceRate(med, logs, start, now);
      expect(rate, closeTo(0.5, 0.01));
    });

    test('handles twice daily', () {
      final start = now.subtract(const Duration(days: 1));
      final med = makeMed(
        frequency: MedFrequency.twiceDaily,
        times: [DoseTime.morning, DoseTime.evening],
        startDate: start,
      );
      final logs = [
        makeLog(timestamp: start, time: DoseTime.morning),
        makeLog(timestamp: start, time: DoseTime.evening),
        makeLog(timestamp: now, time: DoseTime.morning),
      ];
      final rate = service.adherenceRate(med, logs, start, now);
      expect(rate, closeTo(0.75, 0.01));
    });

    test('ignores logs from other medications', () {
      final med = makeMed(id: 'med1', startDate: now);
      final logs = [
        makeLog(medId: 'med2', timestamp: now),
      ];
      expect(service.adherenceRate(med, logs, now, now), 0.0);
    });

    test('returns 1.0 for empty scheduled times', () {
      final med = makeMed(times: []);
      expect(service.adherenceRate(med, [], now, now), 1.0);
    });
  });

  group('currentStreak', () {
    test('returns 0 with no logs', () {
      expect(service.currentStreak(makeMed(), []), 0);
    });

    test('returns 0 for as-needed', () {
      expect(service.currentStreak(makeMed(frequency: MedFrequency.asNeeded), []), 0);
    });

    test('counts consecutive days', () {
      final med = makeMed(startDate: now.subtract(const Duration(days: 10)));
      final logs = [
        makeLog(timestamp: now),
        makeLog(timestamp: now.subtract(const Duration(days: 1))),
        makeLog(timestamp: now.subtract(const Duration(days: 2))),
      ];
      expect(service.currentStreak(med, logs), 3);
    });

    test('breaks on missed day', () {
      final med = makeMed(startDate: now.subtract(const Duration(days: 10)));
      final logs = [
        makeLog(timestamp: now),
        makeLog(timestamp: now.subtract(const Duration(days: 2))),
      ];
      expect(service.currentStreak(med, logs), 1);
    });
  });

  group('longestStreak', () {
    test('returns 0 with no logs', () {
      expect(service.longestStreak(makeMed(), []), 0);
    });

    test('finds longest streak', () {
      final start = now.subtract(const Duration(days: 10));
      final med = makeMed(startDate: start);
      final logs = [
        makeLog(timestamp: start),
        makeLog(timestamp: start.add(const Duration(days: 1))),
        makeLog(timestamp: start.add(const Duration(days: 2))),
        makeLog(timestamp: start.add(const Duration(days: 4))),
        makeLog(timestamp: start.add(const Duration(days: 5))),
      ];
      expect(service.longestStreak(med, logs), 3);
    });

    test('returns 0 for as-needed', () {
      expect(service.longestStreak(makeMed(frequency: MedFrequency.asNeeded), []), 0);
    });
  });

  group('todaySchedule', () {
    test('returns empty for no active meds', () {
      expect(service.todaySchedule([], []), isEmpty);
    });

    test('returns schedule for active meds', () {
      final med = makeMed(
        times: [DoseTime.morning, DoseTime.evening],
        startDate: now.subtract(const Duration(days: 1)),
      );
      final schedule = service.todaySchedule([med], []);
      expect(schedule.length, 2);
      expect(schedule[0]['doseTime'], DoseTime.morning);
      expect(schedule[1]['doseTime'], DoseTime.evening);
      expect(schedule[0]['taken'], false);
    });

    test('marks taken doses', () {
      final med = makeMed(startDate: now.subtract(const Duration(days: 1)));
      final logs = [makeLog(timestamp: now)];
      final schedule = service.todaySchedule([med], logs);
      expect(schedule[0]['taken'], true);
    });

    test('excludes inactive meds', () {
      final med = makeMed(active: false);
      expect(service.todaySchedule([med], []), isEmpty);
    });

    test('excludes as-needed meds', () {
      final med = makeMed(frequency: MedFrequency.asNeeded);
      expect(service.todaySchedule([med], []), isEmpty);
    });

    test('sorted by time of day', () {
      final med = makeMed(
        times: [DoseTime.evening, DoseTime.morning, DoseTime.bedtime],
        startDate: now.subtract(const Duration(days: 1)),
      );
      final schedule = service.todaySchedule([med], []);
      final times = schedule.map((s) => (s['doseTime'] as DoseTime).defaultHour).toList();
      for (int i = 1; i < times.length; i++) {
        expect(times[i], greaterThanOrEqualTo(times[i - 1]));
      }
    });
  });

  group('sideEffectFrequency', () {
    test('returns empty with no effects', () {
      expect(service.sideEffectFrequency('med1', []), isEmpty);
    });

    test('counts and sorts effects', () {
      final logs = [
        makeLog(timestamp: now, sideEffects: 'nausea'),
        makeLog(timestamp: now.subtract(const Duration(days: 1)), sideEffects: 'nausea'),
        makeLog(timestamp: now.subtract(const Duration(days: 2)), sideEffects: 'headache'),
      ];
      final effects = service.sideEffectFrequency('med1', logs);
      expect(effects.keys.first, 'nausea');
      expect(effects['nausea'], 2);
      expect(effects['headache'], 1);
    });

    test('ignores logs without side effects', () {
      final logs = [makeLog(timestamp: now)];
      expect(service.sideEffectFrequency('med1', logs), isEmpty);
    });
  });

  group('skipReasonFrequency', () {
    test('returns empty with no skips', () {
      expect(service.skipReasonFrequency('med1', []), isEmpty);
    });

    test('counts skip reasons', () {
      final logs = [
        makeLog(timestamp: now, taken: false, skipped: true, skipReason: 'Forgot'),
        makeLog(timestamp: now.subtract(const Duration(days: 1)),
            taken: false, skipped: true, skipReason: 'Forgot'),
        makeLog(timestamp: now.subtract(const Duration(days: 2)),
            taken: false, skipped: true, skipReason: 'Ran out'),
      ];
      final reasons = service.skipReasonFrequency('med1', logs);
      expect(reasons['forgot'], 2);
      expect(reasons['ran out'], 1);
    });

    test('ignores non-skipped logs', () {
      final logs = [makeLog(timestamp: now, taken: true)];
      expect(service.skipReasonFrequency('med1', logs), isEmpty);
    });
  });

  group('weeklyAdherence', () {
    test('returns correct number of weeks', () {
      final med = makeMed(startDate: now.subtract(const Duration(days: 30)));
      final result = service.weeklyAdherence(med, [], weeks: 4);
      expect(result.length, 4);
    });

    test('each entry has weekStart, weekEnd, rate', () {
      final med = makeMed(startDate: now.subtract(const Duration(days: 30)));
      final result = service.weeklyAdherence(med, [], weeks: 2);
      for (final week in result) {
        expect(week.containsKey('weekStart'), true);
        expect(week.containsKey('weekEnd'), true);
        expect(week.containsKey('rate'), true);
      }
    });

    test('defaults to 4 weeks', () {
      final med = makeMed(startDate: now.subtract(const Duration(days: 60)));
      final result = service.weeklyAdherence(med, []);
      expect(result.length, 4);
    });
  });

  group('adherenceGrade', () {
    test('A+ for 95%+', () => expect(service.adherenceGrade(0.95), 'A+'));
    test('A for 90%+', () => expect(service.adherenceGrade(0.92), 'A'));
    test('B for 80%+', () => expect(service.adherenceGrade(0.85), 'B'));
    test('C for 70%+', () => expect(service.adherenceGrade(0.75), 'C'));
    test('D for 50%+', () => expect(service.adherenceGrade(0.55), 'D'));
    test('F for below 50%', () => expect(service.adherenceGrade(0.30), 'F'));
    test('A+ for 100%', () => expect(service.adherenceGrade(1.0), 'A+'));
    test('F for 0%', () => expect(service.adherenceGrade(0.0), 'F'));
  });

  group('adherenceColor', () {
    test('green for high adherence', () => expect(service.adherenceColor(0.95), '#4CAF50'));
    test('orange for medium', () => expect(service.adherenceColor(0.75), '#FF9800'));
    test('red for low', () => expect(service.adherenceColor(0.40), '#F44336'));
    test('green at boundary', () => expect(service.adherenceColor(0.90), '#4CAF50'));
    test('orange at boundary', () => expect(service.adherenceColor(0.70), '#FF9800'));
  });
}
