import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/utils/formatting_utils.dart';

void main() {
  group('FormattingUtils', () {
    group('formatTime12h', () {
      test('formats morning time', () {
        final dt = DateTime(2026, 3, 3, 9, 5);
        expect(FormattingUtils.formatTime12h(dt), '9:05 AM');
      });

      test('formats afternoon time', () {
        final dt = DateTime(2026, 3, 3, 14, 30);
        expect(FormattingUtils.formatTime12h(dt), '2:30 PM');
      });

      test('formats midnight as 12 AM', () {
        final dt = DateTime(2026, 3, 3, 0, 0);
        expect(FormattingUtils.formatTime12h(dt), '12:00 AM');
      });

      test('formats noon as 12 PM', () {
        final dt = DateTime(2026, 3, 3, 12, 0);
        expect(FormattingUtils.formatTime12h(dt), '12:00 PM');
      });
    });

    group('formatTime24h', () {
      test('formats with leading zeros', () {
        final dt = DateTime(2026, 3, 3, 9, 5);
        expect(FormattingUtils.formatTime24h(dt), '09:05');
      });

      test('formats midnight', () {
        final dt = DateTime(2026, 3, 3, 0, 0);
        expect(FormattingUtils.formatTime24h(dt), '00:00');
      });
    });

    group('formatTimeRange12h', () {
      test('formats a range', () {
        final start = DateTime(2026, 3, 3, 9, 0);
        final end = DateTime(2026, 3, 3, 10, 30);
        expect(
          FormattingUtils.formatTimeRange12h(start, end),
          '9:00 AM – 10:30 AM',
        );
      });
    });

    group('sameDay', () {
      test('returns true for same day', () {
        final a = DateTime(2026, 3, 3, 9, 0);
        final b = DateTime(2026, 3, 3, 23, 59);
        expect(FormattingUtils.sameDay(a, b), isTrue);
      });

      test('returns false for different days', () {
        final a = DateTime(2026, 3, 3);
        final b = DateTime(2026, 3, 4);
        expect(FormattingUtils.sameDay(a, b), isFalse);
      });
    });

    group('completionColor', () {
      test('returns green for high completion', () {
        expect(FormattingUtils.completionColor(95), Colors.green);
      });

      test('returns red for low completion', () {
        expect(FormattingUtils.completionColor(10), Colors.red);
      });

      test('returns orange for medium completion', () {
        expect(FormattingUtils.completionColor(55), Colors.orange);
      });
    });

    group('productivityIcon', () {
      test('returns trophy for Excellent', () {
        expect(
          FormattingUtils.productivityIcon('Excellent'),
          Icons.emoji_events,
        );
      });

      test('returns sad face for unknown', () {
        expect(
          FormattingUtils.productivityIcon('Bad'),
          Icons.sentiment_dissatisfied,
        );
      });
    });

    group('productivityColor', () {
      test('returns green for Excellent', () {
        expect(FormattingUtils.productivityColor('Excellent'), Colors.green);
      });

      test('returns red for unknown', () {
        expect(FormattingUtils.productivityColor('Bad'), Colors.red);
      });
    });
  });
}
