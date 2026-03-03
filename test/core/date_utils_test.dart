import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/utils/date_utils.dart';

void main() {
  group('AppDateUtils.timeAgo', () {
    test('returns "just now" for very recent times', () {
      final now = DateTime.now();
      expect(AppDateUtils.timeAgo(now), 'just now');
    });

    test('returns minutes ago', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 5));
      expect(AppDateUtils.timeAgo(dt), '5 minutes ago');
    });

    test('returns singular minute', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 1));
      expect(AppDateUtils.timeAgo(dt), '1 minute ago');
    });

    test('returns hours ago', () {
      final dt = DateTime.now().subtract(const Duration(hours: 3));
      expect(AppDateUtils.timeAgo(dt), '3 hours ago');
    });

    test('returns singular hour', () {
      final dt = DateTime.now().subtract(const Duration(hours: 1));
      expect(AppDateUtils.timeAgo(dt), '1 hour ago');
    });

    test('returns days ago for less than a week', () {
      final dt = DateTime.now().subtract(const Duration(days: 4));
      expect(AppDateUtils.timeAgo(dt), '4 days ago');
    });

    test('returns weeks ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 14));
      expect(AppDateUtils.timeAgo(dt), '2 weeks ago');
    });

    test('returns singular week', () {
      final dt = DateTime.now().subtract(const Duration(days: 7));
      expect(AppDateUtils.timeAgo(dt), '1 week ago');
    });

    test('returns months ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 90));
      expect(AppDateUtils.timeAgo(dt), '3 months ago');
    });

    test('returns singular month', () {
      final dt = DateTime.now().subtract(const Duration(days: 30));
      expect(AppDateUtils.timeAgo(dt), '1 month ago');
    });

    test('returns years ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 730));
      expect(AppDateUtils.timeAgo(dt), '2 years ago');
    });

    test('returns singular year', () {
      final dt = DateTime.now().subtract(const Duration(days: 365));
      expect(AppDateUtils.timeAgo(dt), '1 year ago');
    });

    // Future dates
    test('returns "in X minutes" for future', () {
      final dt = DateTime.now().add(const Duration(minutes: 10));
      expect(AppDateUtils.timeAgo(dt), 'in 10 minutes');
    });

    test('returns "in X weeks" for future', () {
      final dt = DateTime.now().add(const Duration(days: 21));
      expect(AppDateUtils.timeAgo(dt), 'in 3 weeks');
    });

    test('returns "in X months" for future', () {
      final dt = DateTime.now().add(const Duration(days: 60));
      expect(AppDateUtils.timeAgo(dt), 'in 2 months');
    });

    test('returns "in X years" for future', () {
      final dt = DateTime.now().add(const Duration(days: 400));
      expect(AppDateUtils.timeAgo(dt), 'in 1 year');
    });
  });

  group('AppDateUtils.isSameDay', () {
    test('same day returns true', () {
      final a = DateTime(2026, 3, 3, 10, 30);
      final b = DateTime(2026, 3, 3, 22, 15);
      expect(AppDateUtils.isSameDay(a, b), isTrue);
    });

    test('different day returns false', () {
      final a = DateTime(2026, 3, 3);
      final b = DateTime(2026, 3, 4);
      expect(AppDateUtils.isSameDay(a, b), isFalse);
    });
  });

  group('AppDateUtils.dateOnly', () {
    test('strips time component', () {
      final dt = DateTime(2026, 3, 3, 14, 30, 45);
      final result = AppDateUtils.dateOnly(dt);
      expect(result, DateTime(2026, 3, 3));
      expect(result.hour, 0);
      expect(result.minute, 0);
    });
  });
}
