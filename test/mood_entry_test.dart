import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/mood_entry.dart';

void main() {
  group('MoodLevel', () {
    test('all levels have correct numeric values 1-5', () {
      expect(MoodLevel.veryBad.value, 1);
      expect(MoodLevel.bad.value, 2);
      expect(MoodLevel.neutral.value, 3);
      expect(MoodLevel.good.value, 4);
      expect(MoodLevel.great.value, 5);
    });

    test('fromValue round-trips all levels', () {
      for (final level in MoodLevel.values) {
        expect(MoodLevel.fromValue(level.value), level);
      }
    });

    test('fromValue with invalid input defaults to neutral', () {
      expect(MoodLevel.fromValue(0), MoodLevel.neutral);
      expect(MoodLevel.fromValue(99), MoodLevel.neutral);
      expect(MoodLevel.fromValue(-1), MoodLevel.neutral);
    });

    test('all levels have non-empty labels and emojis', () {
      for (final level in MoodLevel.values) {
        expect(level.label, isNotEmpty);
        expect(level.emoji, isNotEmpty);
      }
    });
  });

  group('MoodActivity', () {
    test('all activities have non-empty labels and emojis', () {
      for (final activity in MoodActivity.values) {
        expect(activity.label, isNotEmpty);
        expect(activity.emoji, isNotEmpty);
      }
    });
  });

  group('MoodEntry', () {
    final testEntry = MoodEntry(
      id: 'test-1',
      timestamp: DateTime(2026, 3, 18, 14, 30),
      mood: MoodLevel.good,
      note: 'Had a productive day',
      activities: [MoodActivity.work, MoodActivity.exercise],
    );

    test('toJson produces expected structure', () {
      final json = testEntry.toJson();
      expect(json['id'], 'test-1');
      expect(json['mood'], 4);
      expect(json['note'], 'Had a productive day');
      expect(json['activities'], ['work', 'exercise']);
      expect(json['timestamp'], contains('2026-03-18'));
    });

    test('fromJson/toJson round-trip preserves all fields', () {
      final json = testEntry.toJson();
      final restored = MoodEntry.fromJson(json);
      expect(restored.id, testEntry.id);
      expect(restored.mood, testEntry.mood);
      expect(restored.note, testEntry.note);
      expect(restored.activities.length, testEntry.activities.length);
      expect(restored.activities[0], MoodActivity.work);
      expect(restored.activities[1], MoodActivity.exercise);
      expect(restored.timestamp.year, 2026);
      expect(restored.timestamp.month, 3);
      expect(restored.timestamp.day, 18);
    });

    test('fromJson handles null activities', () {
      final json = {
        'id': 'test-2',
        'timestamp': '2026-03-18T10:00:00.000',
        'mood': 3,
        'note': null,
        'activities': null,
      };
      final entry = MoodEntry.fromJson(json);
      expect(entry.activities, isEmpty);
      expect(entry.note, isNull);
    });

    test('fromJson handles unknown activity gracefully', () {
      final json = {
        'id': 'test-3',
        'timestamp': '2026-03-18T10:00:00.000',
        'mood': 5,
        'activities': ['work', 'unknown_activity', 'reading'],
      };
      final entry = MoodEntry.fromJson(json);
      // Unknown activity falls back to rest
      expect(entry.activities.length, 3);
      expect(entry.activities[0], MoodActivity.work);
      expect(entry.activities[1], MoodActivity.rest);
      expect(entry.activities[2], MoodActivity.reading);
    });

    test('encodeList/decodeList round-trip', () {
      final entries = [
        testEntry,
        MoodEntry(
          id: 'test-4',
          timestamp: DateTime(2026, 3, 17),
          mood: MoodLevel.veryBad,
          note: 'Rough day',
          activities: [MoodActivity.rest],
        ),
      ];
      final encoded = MoodEntry.encodeList(entries);
      final decoded = MoodEntry.decodeList(encoded);
      expect(decoded.length, 2);
      expect(decoded[0].id, 'test-1');
      expect(decoded[0].mood, MoodLevel.good);
      expect(decoded[1].id, 'test-4');
      expect(decoded[1].mood, MoodLevel.veryBad);
    });

    test('copyWith overrides specified fields only', () {
      final modified = testEntry.copyWith(
        mood: MoodLevel.great,
        note: 'Updated note',
      );
      expect(modified.mood, MoodLevel.great);
      expect(modified.note, 'Updated note');
      expect(modified.id, testEntry.id);
      expect(modified.timestamp, testEntry.timestamp);
      expect(modified.activities, testEntry.activities);
    });

    test('copyWith with no args returns equivalent entry', () {
      final copy = testEntry.copyWith();
      expect(copy.id, testEntry.id);
      expect(copy.mood, testEntry.mood);
      expect(copy.note, testEntry.note);
    });
  });
}
