import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/mood_entry.dart';

void main() {
  group('MoodLevel', () {
    test('fromValue returns correct level', () {
      expect(MoodLevel.fromValue(1), MoodLevel.veryBad);
      expect(MoodLevel.fromValue(2), MoodLevel.bad);
      expect(MoodLevel.fromValue(3), MoodLevel.neutral);
      expect(MoodLevel.fromValue(4), MoodLevel.good);
      expect(MoodLevel.fromValue(5), MoodLevel.great);
    });

    test('fromValue defaults to neutral for invalid values', () {
      expect(MoodLevel.fromValue(0), MoodLevel.neutral);
      expect(MoodLevel.fromValue(99), MoodLevel.neutral);
    });

    test('value roundtrips correctly', () {
      for (final mood in MoodLevel.values) {
        expect(MoodLevel.fromValue(mood.value), mood);
      }
    });

    test('every level has a non-empty label and emoji', () {
      for (final mood in MoodLevel.values) {
        expect(mood.label.isNotEmpty, true);
        expect(mood.emoji.isNotEmpty, true);
      }
    });
  });

  group('MoodActivity', () {
    test('every activity has label and emoji', () {
      for (final activity in MoodActivity.values) {
        expect(activity.label.isNotEmpty, true);
        expect(activity.emoji.isNotEmpty, true);
      }
    });
  });

  group('MoodEntry', () {
    test('JSON roundtrip preserves all fields', () {
      final entry = MoodEntry(
        id: 'test-1',
        timestamp: DateTime(2026, 3, 3, 10, 30),
        mood: MoodLevel.good,
        note: 'Feeling productive!',
        activities: [MoodActivity.work, MoodActivity.exercise],
      );

      final json = entry.toJson();
      final restored = MoodEntry.fromJson(json);

      expect(restored.id, entry.id);
      expect(restored.timestamp, entry.timestamp);
      expect(restored.mood, entry.mood);
      expect(restored.note, entry.note);
      expect(restored.activities, entry.activities);
    });

    test('JSON roundtrip with no note or activities', () {
      final entry = MoodEntry(
        id: 'test-2',
        timestamp: DateTime(2026, 1, 15),
        mood: MoodLevel.neutral,
      );

      final json = entry.toJson();
      final restored = MoodEntry.fromJson(json);

      expect(restored.id, 'test-2');
      expect(restored.mood, MoodLevel.neutral);
      expect(restored.note, null);
      expect(restored.activities, isEmpty);
    });

    test('encodeList / decodeList roundtrip', () {
      final entries = [
        MoodEntry(
          id: 'a',
          timestamp: DateTime(2026, 3, 1),
          mood: MoodLevel.great,
          activities: [MoodActivity.meditation],
        ),
        MoodEntry(
          id: 'b',
          timestamp: DateTime(2026, 3, 2),
          mood: MoodLevel.bad,
          note: 'Rough day',
        ),
      ];

      final encoded = MoodEntry.encodeList(entries);
      final decoded = MoodEntry.decodeList(encoded);

      expect(decoded.length, 2);
      expect(decoded[0].id, 'a');
      expect(decoded[0].mood, MoodLevel.great);
      expect(decoded[1].note, 'Rough day');
    });

    test('copyWith creates modified copy', () {
      final entry = MoodEntry(
        id: 'orig',
        timestamp: DateTime(2026, 1, 1),
        mood: MoodLevel.neutral,
      );

      final modified = entry.copyWith(mood: MoodLevel.great, note: 'Updated');

      expect(modified.id, 'orig');
      expect(modified.mood, MoodLevel.great);
      expect(modified.note, 'Updated');
      // Original unchanged
      expect(entry.mood, MoodLevel.neutral);
      expect(entry.note, null);
    });

    test('fromJson handles unknown activity gracefully', () {
      final json = {
        'id': 'test',
        'timestamp': '2026-03-03T12:00:00.000',
        'mood': 4,
        'note': null,
        'activities': ['work', 'unknown_activity', 'rest'],
      };

      final entry = MoodEntry.fromJson(json);
      // unknown_activity should fall back to rest (orElse)
      expect(entry.activities.length, 3);
      expect(entry.activities[0], MoodActivity.work);
      expect(entry.activities[2], MoodActivity.rest);
    });
  });
}
