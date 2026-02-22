import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/reminder_settings.dart';

void main() {
  group('ReminderOffset', () {
    test('all offsets have labels', () {
      for (final offset in ReminderOffset.values) {
        expect(offset.label.isNotEmpty, isTrue);
        expect(offset.shortLabel.isNotEmpty, isTrue);
      }
    });

    test('all offsets have non-negative durations', () {
      for (final offset in ReminderOffset.values) {
        expect(offset.duration.inSeconds >= 0, isTrue);
      }
    });

    test('atTime has zero duration', () {
      expect(ReminderOffset.atTime.duration, Duration.zero);
    });

    test('fiveMinutes is 5 minutes', () {
      expect(ReminderOffset.fiveMinutes.duration, const Duration(minutes: 5));
    });

    test('oneHour is 60 minutes', () {
      expect(ReminderOffset.oneHour.duration, const Duration(hours: 1));
    });

    test('oneDay is 24 hours', () {
      expect(ReminderOffset.oneDay.duration, const Duration(days: 1));
    });

    test('oneWeek is 7 days', () {
      expect(ReminderOffset.oneWeek.duration, const Duration(days: 7));
    });

    test('durations are in ascending order', () {
      for (var i = 1; i < ReminderOffset.values.length; i++) {
        final prev = ReminderOffset.values[i - 1].duration;
        final curr = ReminderOffset.values[i].duration;
        expect(curr >= prev, isTrue,
            reason:
                '${ReminderOffset.values[i]} should be >= ${ReminderOffset.values[i - 1]}');
      }
    });

    test('notificationTime subtracts duration', () {
      final eventDate = DateTime(2026, 3, 15, 14, 0);
      final time = ReminderOffset.oneHour.notificationTime(eventDate);
      expect(time, DateTime(2026, 3, 15, 13, 0));
    });

    test('notificationTime for atTime equals event date', () {
      final eventDate = DateTime(2026, 3, 15, 14, 0);
      expect(ReminderOffset.atTime.notificationTime(eventDate), eventDate);
    });

    test('fromString parses valid name', () {
      expect(ReminderOffset.fromString('oneHour'), ReminderOffset.oneHour);
      expect(
          ReminderOffset.fromString('fiveMinutes'), ReminderOffset.fiveMinutes);
    });

    test('fromString returns default for invalid', () {
      expect(ReminderOffset.fromString('invalid'),
          ReminderOffset.fifteenMinutes);
    });

    test('toJsonValue returns name', () {
      expect(ReminderOffset.oneDay.toJsonValue(), 'oneDay');
      expect(ReminderOffset.atTime.toJsonValue(), 'atTime');
    });

    test('shortLabels are concise', () {
      expect(ReminderOffset.fiveMinutes.shortLabel, '5m');
      expect(ReminderOffset.oneHour.shortLabel, '1h');
      expect(ReminderOffset.oneDay.shortLabel, '1d');
      expect(ReminderOffset.oneWeek.shortLabel, '1w');
    });

    test('isUpcoming for future event', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      expect(ReminderOffset.oneDay.isUpcoming(futureDate), isTrue);
    });

    test('isUpcoming false for past event', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 30));
      expect(ReminderOffset.fiveMinutes.isUpcoming(pastDate), isFalse);
    });
  });

  group('ReminderSettings', () {
    test('default constructor has no reminders', () {
      const settings = ReminderSettings();
      expect(settings.hasReminders, isFalse);
      expect(settings.count, 0);
      expect(settings.summary, 'None');
    });

    test('none constant has no reminders', () {
      expect(ReminderSettings.none.hasReminders, isFalse);
    });

    test('defaultReminder has 15 minutes', () {
      expect(ReminderSettings.defaultReminder.hasReminders, isTrue);
      expect(ReminderSettings.defaultReminder.count, 1);
      expect(ReminderSettings.defaultReminder.offsets,
          contains(ReminderOffset.fifteenMinutes));
    });

    test('addReminder adds offset', () {
      var settings = const ReminderSettings();
      settings = settings.addReminder(ReminderOffset.oneHour);
      expect(settings.count, 1);
      expect(settings.offsets, contains(ReminderOffset.oneHour));
    });

    test('addReminder prevents duplicates', () {
      var settings = const ReminderSettings();
      settings = settings.addReminder(ReminderOffset.oneHour);
      settings = settings.addReminder(ReminderOffset.oneHour);
      expect(settings.count, 1);
    });

    test('addReminder maintains sorted order', () {
      var settings = const ReminderSettings();
      settings = settings.addReminder(ReminderOffset.oneDay);
      settings = settings.addReminder(ReminderOffset.fiveMinutes);
      settings = settings.addReminder(ReminderOffset.oneHour);
      expect(settings.offsets[0], ReminderOffset.fiveMinutes);
      expect(settings.offsets[1], ReminderOffset.oneHour);
      expect(settings.offsets[2], ReminderOffset.oneDay);
    });

    test('removeReminder removes offset', () {
      var settings = ReminderSettings.defaultReminder;
      settings = settings.removeReminder(ReminderOffset.fifteenMinutes);
      expect(settings.hasReminders, isFalse);
    });

    test('removeReminder is safe for missing offset', () {
      const settings = ReminderSettings();
      final result = settings.removeReminder(ReminderOffset.oneHour);
      expect(result.count, 0);
    });

    test('toggleReminder adds when missing', () {
      var settings = const ReminderSettings();
      settings = settings.toggleReminder(ReminderOffset.thirtyMinutes);
      expect(settings.offsets, contains(ReminderOffset.thirtyMinutes));
    });

    test('toggleReminder removes when present', () {
      var settings = const ReminderSettings(
          offsets: [ReminderOffset.thirtyMinutes]);
      settings = settings.toggleReminder(ReminderOffset.thirtyMinutes);
      expect(settings.hasReminders, isFalse);
    });

    test('summary shows short labels', () {
      final settings = ReminderSettings(offsets: [
        ReminderOffset.fiveMinutes,
        ReminderOffset.oneHour,
        ReminderOffset.oneDay,
      ]);
      expect(settings.summary, '5m, 1h, 1d');
    });

    test('notificationTimes returns future times only', () {
      final futureDate = DateTime.now().add(const Duration(hours: 2));
      final settings = ReminderSettings(offsets: [
        ReminderOffset.fiveMinutes,
        ReminderOffset.oneHour,
        ReminderOffset.oneDay, // This one will be in the past
      ]);
      final times = settings.notificationTimes(futureDate);
      for (final t in times) {
        expect(t.isAfter(DateTime.now()), isTrue);
      }
    });

    test('notificationTimes are sorted', () {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final settings = ReminderSettings(offsets: [
        ReminderOffset.oneDay,
        ReminderOffset.fiveMinutes,
        ReminderOffset.oneHour,
      ]);
      final times = settings.notificationTimes(futureDate);
      for (var i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isTrue);
      }
    });

    test('nextNotificationTime returns earliest', () {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      final settings = ReminderSettings(offsets: [
        ReminderOffset.oneDay,
        ReminderOffset.fiveMinutes,
      ]);
      final next = settings.nextNotificationTime(futureDate);
      expect(next, isNotNull);
      // Should be the oneDay before (earliest notification)
      final expected =
          ReminderOffset.oneDay.notificationTime(futureDate);
      expect(next, expected);
    });

    test('nextNotificationTime returns null for past event', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 30));
      final settings = ReminderSettings.defaultReminder;
      expect(settings.nextNotificationTime(pastDate), isNull);
    });

    test('nextNotificationTime returns null for empty', () {
      final futureDate = DateTime.now().add(const Duration(days: 10));
      expect(ReminderSettings.none.nextNotificationTime(futureDate), isNull);
    });
  });

  group('ReminderSettings serialization', () {
    test('toJsonString and fromJsonString round-trip', () {
      final settings = ReminderSettings(offsets: [
        ReminderOffset.fiveMinutes,
        ReminderOffset.oneHour,
        ReminderOffset.oneDay,
      ]);
      final json = settings.toJsonString();
      final restored = ReminderSettings.fromJsonString(json);
      expect(restored.count, 3);
      expect(restored.offsets, contains(ReminderOffset.fiveMinutes));
      expect(restored.offsets, contains(ReminderOffset.oneHour));
      expect(restored.offsets, contains(ReminderOffset.oneDay));
    });

    test('fromJsonString handles null', () {
      final settings = ReminderSettings.fromJsonString(null);
      expect(settings.hasReminders, isFalse);
    });

    test('fromJsonString handles empty string', () {
      final settings = ReminderSettings.fromJsonString('');
      expect(settings.hasReminders, isFalse);
    });

    test('fromJsonString handles malformed JSON', () {
      final settings = ReminderSettings.fromJsonString('not json');
      expect(settings.hasReminders, isFalse);
    });

    test('toJsonString for empty', () {
      final json = ReminderSettings.none.toJsonString();
      expect(json, '[]');
    });

    test('single reminder round-trip', () {
      final settings = ReminderSettings(
          offsets: [ReminderOffset.thirtyMinutes]);
      final json = settings.toJsonString();
      final restored = ReminderSettings.fromJsonString(json);
      expect(restored.count, 1);
      expect(restored.offsets.first, ReminderOffset.thirtyMinutes);
    });
  });

  group('ReminderSettings equality', () {
    test('equal settings are equal', () {
      final a = ReminderSettings(offsets: [
        ReminderOffset.fiveMinutes,
        ReminderOffset.oneHour,
      ]);
      final b = ReminderSettings(offsets: [
        ReminderOffset.fiveMinutes,
        ReminderOffset.oneHour,
      ]);
      expect(a, equals(b));
    });

    test('different offsets are not equal', () {
      final a = ReminderSettings(offsets: [ReminderOffset.fiveMinutes]);
      final b = ReminderSettings(offsets: [ReminderOffset.oneHour]);
      expect(a, isNot(equals(b)));
    });

    test('different counts are not equal', () {
      final a = ReminderSettings(offsets: [ReminderOffset.fiveMinutes]);
      final b = ReminderSettings(offsets: [
        ReminderOffset.fiveMinutes,
        ReminderOffset.oneHour,
      ]);
      expect(a, isNot(equals(b)));
    });

    test('empty settings are equal', () {
      expect(const ReminderSettings(), equals(ReminderSettings.none));
    });

    test('hashCode matches for equal settings', () {
      final a = ReminderSettings(
          offsets: [ReminderOffset.oneDay]);
      final b = ReminderSettings(
          offsets: [ReminderOffset.oneDay]);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('ReminderSettings toString', () {
    test('toString includes summary', () {
      final settings = ReminderSettings(offsets: [
        ReminderOffset.fiveMinutes,
        ReminderOffset.oneHour,
      ]);
      expect(settings.toString(), contains('5m'));
      expect(settings.toString(), contains('1h'));
    });

    test('empty toString shows None', () {
      expect(ReminderSettings.none.toString(), contains('None'));
    });
  });

  group('ReminderSettings with multiple reminders', () {
    test('all 9 offsets can be added', () {
      var settings = const ReminderSettings();
      for (final offset in ReminderOffset.values) {
        settings = settings.addReminder(offset);
      }
      expect(settings.count, ReminderOffset.values.length);
    });

    test('all offsets can be removed individually', () {
      var settings = ReminderSettings(offsets: List.of(ReminderOffset.values));
      for (final offset in ReminderOffset.values) {
        settings = settings.removeReminder(offset);
      }
      expect(settings.hasReminders, isFalse);
    });

    test('toggle all on then off', () {
      var settings = const ReminderSettings();
      for (final offset in ReminderOffset.values) {
        settings = settings.toggleReminder(offset);
      }
      expect(settings.count, ReminderOffset.values.length);
      for (final offset in ReminderOffset.values) {
        settings = settings.toggleReminder(offset);
      }
      expect(settings.hasReminders, isFalse);
    });
  });
}
