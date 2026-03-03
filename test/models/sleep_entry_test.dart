import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/sleep_entry.dart';

void main() {
  group('SleepQuality', () {
    test('values have correct labels', () {
      expect(SleepQuality.terrible.label, 'Terrible');
      expect(SleepQuality.poor.label, 'Poor');
      expect(SleepQuality.fair.label, 'Fair');
      expect(SleepQuality.good.label, 'Good');
      expect(SleepQuality.excellent.label, 'Excellent');
    });

    test('values have correct numeric values', () {
      expect(SleepQuality.terrible.value, 1);
      expect(SleepQuality.poor.value, 2);
      expect(SleepQuality.fair.value, 3);
      expect(SleepQuality.good.value, 4);
      expect(SleepQuality.excellent.value, 5);
    });

    test('fromValue maps integers correctly', () {
      expect(SleepQuality.fromValue(1), SleepQuality.terrible);
      expect(SleepQuality.fromValue(3), SleepQuality.fair);
      expect(SleepQuality.fromValue(5), SleepQuality.excellent);
    });

    test('fromValue defaults to fair for out-of-range', () {
      expect(SleepQuality.fromValue(0), SleepQuality.fair);
      expect(SleepQuality.fromValue(6), SleepQuality.fair);
      expect(SleepQuality.fromValue(-1), SleepQuality.fair);
    });

    test('each quality has a non-empty emoji', () {
      for (final q in SleepQuality.values) {
        expect(q.emoji.isNotEmpty, isTrue);
      }
    });
  });

  group('SleepFactor', () {
    test('all factors have labels', () {
      for (final f in SleepFactor.values) {
        expect(f.label.isNotEmpty, isTrue);
      }
    });

    test('all factors have emojis', () {
      for (final f in SleepFactor.values) {
        expect(f.emoji.isNotEmpty, isTrue);
      }
    });

    test('factor count is 12', () {
      expect(SleepFactor.values.length, 12);
    });
  });

  group('SleepEntry', () {
    final bedtime = DateTime(2026, 3, 2, 23, 0);
    final wakeTime = DateTime(2026, 3, 3, 7, 30);

    SleepEntry makeEntry({
      SleepQuality quality = SleepQuality.good,
      String? note,
      List<SleepFactor> factors = const [],
      int? awakenings,
    }) {
      return SleepEntry(
        id: 'test-1',
        bedtime: bedtime,
        wakeTime: wakeTime,
        quality: quality,
        note: note,
        factors: factors,
        awakenings: awakenings,
      );
    }

    test('durationHours calculates correctly', () {
      final entry = makeEntry();
      expect(entry.durationHours, closeTo(8.5, 0.01));
    });

    test('durationFormatted formats correctly', () {
      final entry = makeEntry();
      expect(entry.durationFormatted, '8h 30m');
    });

    test('durationFormatted handles exact hours', () {
      final entry = SleepEntry(
        id: 'test',
        bedtime: DateTime(2026, 3, 2, 23, 0),
        wakeTime: DateTime(2026, 3, 3, 7, 0),
        quality: SleepQuality.good,
      );
      expect(entry.durationFormatted, '8h');
    });

    test('durationFormatted handles minutes only', () {
      final entry = SleepEntry(
        id: 'test',
        bedtime: DateTime(2026, 3, 3, 6, 15),
        wakeTime: DateTime(2026, 3, 3, 6, 45),
        quality: SleepQuality.poor,
      );
      expect(entry.durationFormatted, '30m');
    });

    test('date returns wake date without time', () {
      final entry = makeEntry();
      expect(entry.date, DateTime(2026, 3, 3));
    });

    test('duration returns correct Duration', () {
      final entry = makeEntry();
      expect(entry.duration, const Duration(hours: 8, minutes: 30));
    });

    test('copyWith creates modified copy', () {
      final entry = makeEntry(note: 'original');
      final copy = entry.copyWith(note: 'modified', quality: SleepQuality.excellent);
      expect(copy.note, 'modified');
      expect(copy.quality, SleepQuality.excellent);
      expect(copy.id, entry.id);
      expect(copy.bedtime, entry.bedtime);
    });

    test('copyWith preserves values when not specified', () {
      final entry = makeEntry(
        note: 'test',
        factors: [SleepFactor.caffeine],
        awakenings: 2,
      );
      final copy = entry.copyWith();
      expect(copy.note, 'test');
      expect(copy.factors, [SleepFactor.caffeine]);
      expect(copy.awakenings, 2);
    });

    test('toJson serializes all fields', () {
      final entry = makeEntry(
        note: 'good sleep',
        factors: [SleepFactor.meditation, SleepFactor.reading],
        awakenings: 1,
      );
      final json = entry.toJson();
      expect(json['id'], 'test-1');
      expect(json['quality'], 4);
      expect(json['note'], 'good sleep');
      expect(json['awakenings'], 1);
      expect(json['factors'], ['meditation', 'reading']);
      expect(json['bedtime'], bedtime.toIso8601String());
      expect(json['wakeTime'], wakeTime.toIso8601String());
    });

    test('fromJson deserializes correctly', () {
      final entry = makeEntry(
        note: 'test note',
        factors: [SleepFactor.caffeine, SleepFactor.stress],
        awakenings: 3,
      );
      final json = entry.toJson();
      final restored = SleepEntry.fromJson(json);
      expect(restored.id, entry.id);
      expect(restored.bedtime, entry.bedtime);
      expect(restored.wakeTime, entry.wakeTime);
      expect(restored.quality, entry.quality);
      expect(restored.note, entry.note);
      expect(restored.awakenings, 3);
      expect(restored.factors, [SleepFactor.caffeine, SleepFactor.stress]);
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'id': 'test',
        'bedtime': bedtime.toIso8601String(),
        'wakeTime': wakeTime.toIso8601String(),
        'quality': 3,
      };
      final entry = SleepEntry.fromJson(json);
      expect(entry.note, isNull);
      expect(entry.awakenings, isNull);
      expect(entry.factors, isEmpty);
    });

    test('encodeList and decodeList roundtrip', () {
      final entries = [
        makeEntry(note: 'first'),
        SleepEntry(
          id: 'test-2',
          bedtime: DateTime(2026, 3, 1, 22, 30),
          wakeTime: DateTime(2026, 3, 2, 6, 0),
          quality: SleepQuality.poor,
          factors: [SleepFactor.caffeine],
        ),
      ];
      final encoded = SleepEntry.encodeList(entries);
      final decoded = SleepEntry.decodeList(encoded);
      expect(decoded.length, 2);
      expect(decoded[0].id, 'test-1');
      expect(decoded[0].note, 'first');
      expect(decoded[1].id, 'test-2');
      expect(decoded[1].quality, SleepQuality.poor);
      expect(decoded[1].factors, [SleepFactor.caffeine]);
    });

    test('fromJson handles unknown factor gracefully', () {
      final json = {
        'id': 'test',
        'bedtime': bedtime.toIso8601String(),
        'wakeTime': wakeTime.toIso8601String(),
        'quality': 3,
        'factors': ['caffeine', 'unknown_factor'],
      };
      final entry = SleepEntry.fromJson(json);
      // Unknown factor falls back to stress
      expect(entry.factors.length, 2);
      expect(entry.factors[0], SleepFactor.caffeine);
      expect(entry.factors[1], SleepFactor.stress);
    });
  });
}
