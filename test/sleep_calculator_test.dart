import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/sleep_calculator_service.dart';

void main() {
  group('SleepCalculatorService', () {
    test('bedtimesForWakeUp returns 4 suggestions (6 down to 3 cycles)', () {
      final wake = DateTime(2026, 3, 30, 7, 0);
      final results = SleepCalculatorService.bedtimesForWakeUp(wake);
      expect(results.length, 4);
      expect(results.first.cycles, 6);
      expect(results.last.cycles, 3);
    });

    test('bedtime accounts for 14-min fall-asleep time', () {
      final wake = DateTime(2026, 3, 30, 7, 0);
      final results = SleepCalculatorService.bedtimesForWakeUp(wake);
      // 6 cycles = 9h, plus 14 min = 9h14m before 7:00 AM → 9:46 PM
      final sixCycle = results.first;
      expect(sixCycle.time.hour, 21);
      expect(sixCycle.time.minute, 46);
    });

    test('wakeTimesForBedtime returns 4 suggestions (3 up to 6 cycles)', () {
      final bed = DateTime(2026, 3, 30, 23, 0);
      final results = SleepCalculatorService.wakeTimesForBedtime(bed);
      expect(results.length, 4);
      expect(results.first.cycles, 3);
      expect(results.last.cycles, 6);
    });

    test('wakeTimesForBedtime accounts for fall-asleep time', () {
      final bed = DateTime(2026, 3, 30, 23, 0);
      final results = SleepCalculatorService.wakeTimesForBedtime(bed);
      // 3 cycles = 4.5h, fall asleep at 23:14, wake at 03:44
      final threeCycle = results.first;
      expect(threeCycle.time.hour, 3);
      expect(threeCycle.time.minute, 44);
      expect(threeCycle.sleepHours, 4.5);
    });

    test('qualityLabel returns correct labels', () {
      expect(SleepCalculatorService.qualityLabel(6), 'Ideal');
      expect(SleepCalculatorService.qualityLabel(5), 'Great');
      expect(SleepCalculatorService.qualityLabel(4), 'Good');
      expect(SleepCalculatorService.qualityLabel(3), 'Minimum');
    });
  });
}
