import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/pace_calculator_service.dart';

void main() {
  group('PaceCalculatorService.fromDistanceAndTime', () {
    test('calculates pace for a 5K in 25 minutes', () {
      final result = PaceCalculatorService.fromDistanceAndTime(
        distanceKm: 5.0,
        totalTime: const Duration(minutes: 25),
      );
      expect(result.distanceKm, 5.0);
      expect(result.totalTime, const Duration(minutes: 25));
      expect(result.paceMinPerUnit, closeTo(5.0, 0.01)); // 5 min/km
      expect(result.speedKmh, closeTo(12.0, 0.01)); // 12 km/h
      expect(result.useMiles, isFalse);
    });

    test('calculates pace in miles when useMiles is true', () {
      final result = PaceCalculatorService.fromDistanceAndTime(
        distanceKm: 5.0,
        totalTime: const Duration(minutes: 25),
        useMiles: true,
      );
      // 5 km = 3.107 mi → pace = 25/3.107 ≈ 8.05 min/mi
      expect(result.paceMinPerUnit, closeTo(8.05, 0.1));
      expect(result.useMiles, isTrue);
    });

    test('calculates correct speed for a marathon in 4 hours', () {
      final result = PaceCalculatorService.fromDistanceAndTime(
        distanceKm: 42.195,
        totalTime: const Duration(hours: 4),
      );
      // speed = 42.195 / 4 = 10.549 km/h
      expect(result.speedKmh, closeTo(10.549, 0.01));
      // pace = 240 / 42.195 ≈ 5.69 min/km
      expect(result.paceMinPerUnit, closeTo(5.69, 0.01));
    });
  });

  group('PaceCalculatorService.fromDistanceAndPace', () {
    test('calculates finish time for 10K at 6 min/km pace', () {
      final result = PaceCalculatorService.fromDistanceAndPace(
        distanceKm: 10.0,
        paceMinPerUnit: 6.0,
      );
      // 10 km * 6 min/km = 60 min
      expect(result.totalTime.inMinutes, 60);
      expect(result.distanceKm, 10.0);
    });

    test('calculates finish time in miles mode', () {
      final result = PaceCalculatorService.fromDistanceAndPace(
        distanceKm: 5.0,
        paceMinPerUnit: 8.0,
        useMiles: true,
      );
      // 5 km = 3.107 mi → time = 8 * 3.107 = 24.85 min
      expect(result.totalTime.inSeconds, closeTo(24.85 * 60, 2));
    });

    test('produces consistent speed', () {
      final result = PaceCalculatorService.fromDistanceAndPace(
        distanceKm: 21.0975,
        paceMinPerUnit: 5.0,
      );
      // 21.0975 km at 5 min/km = 105.49 min → speed = 21.0975 / (105.49/60) ≈ 12 km/h
      expect(result.speedKmh, closeTo(12.0, 0.1));
    });
  });

  group('PaceCalculatorService.fromTimeAndPace', () {
    test('calculates distance from 30 min at 5 min/km', () {
      final result = PaceCalculatorService.fromTimeAndPace(
        totalTime: const Duration(minutes: 30),
        paceMinPerUnit: 5.0,
      );
      // 30 / 5 = 6 km
      expect(result.distanceKm, closeTo(6.0, 0.01));
    });

    test('calculates distance in miles mode', () {
      final result = PaceCalculatorService.fromTimeAndPace(
        totalTime: const Duration(minutes: 30),
        paceMinPerUnit: 8.0,
        useMiles: true,
      );
      // 30 / 8 = 3.75 miles → 3.75 * 1.60934 = 6.035 km
      expect(result.distanceKm, closeTo(6.035, 0.05));
    });

    test('handles very fast pace (3 min/km)', () {
      final result = PaceCalculatorService.fromTimeAndPace(
        totalTime: const Duration(hours: 1),
        paceMinPerUnit: 3.0,
      );
      // 60 / 3 = 20 km
      expect(result.distanceKm, closeTo(20.0, 0.01));
      expect(result.speedKmh, closeTo(20.0, 0.1));
    });
  });

  group('PaceCalculatorService.generateSplits', () {
    test('generates correct number of 1km splits for 5K', () {
      final splits = PaceCalculatorService.generateSplits(
        distanceKm: 5.0,
        totalTime: const Duration(minutes: 25),
      );
      expect(splits.length, 5);
    });

    test('split times are consistent with total time', () {
      final splits = PaceCalculatorService.generateSplits(
        distanceKm: 10.0,
        totalTime: const Duration(minutes: 50),
      );
      // Even pace: each split ≈ 5:00
      for (final split in splits) {
        expect(split.splitTime.inSeconds, closeTo(300, 1));
      }
      // Last elapsed time ≈ total time
      expect(splits.last.elapsedTime.inSeconds,
          closeTo(const Duration(minutes: 50).inSeconds, 2));
    });

    test('handles partial last split', () {
      final splits = PaceCalculatorService.generateSplits(
        distanceKm: 5.5,
        totalTime: const Duration(minutes: 27, seconds: 30),
        splitEveryKm: 1.0,
      );
      // 5 full km splits + 1 partial (0.5 km)
      expect(splits.length, 6);
      // Last split distance should be ~0.5
      expect(splits.last.distance, closeTo(0.5, 0.01));
    });

    test('split numbers are sequential starting at 1', () {
      final splits = PaceCalculatorService.generateSplits(
        distanceKm: 3.0,
        totalTime: const Duration(minutes: 15),
      );
      for (var i = 0; i < splits.length; i++) {
        expect(splits[i].splitNumber, i + 1);
      }
    });

    test('mile splits with useMiles flag', () {
      final splits = PaceCalculatorService.generateSplits(
        distanceKm: 5.0,
        totalTime: const Duration(minutes: 25),
        splitEveryKm: 1.0,
        useMiles: true,
      );
      // splitEveryKm=1.0 with useMiles means every 1.60934 km
      // 5.0 / 1.60934 ≈ 3.107 → 3 full splits + 1 partial
      expect(splits.length, greaterThanOrEqualTo(3));
      expect(splits.length, lessThanOrEqualTo(4));
    });
  });

  group('PaceCalculatorService.formatPace', () {
    test('formats whole-minute pace', () {
      expect(PaceCalculatorService.formatPace(5.0), '5:00');
    });

    test('formats pace with seconds', () {
      expect(PaceCalculatorService.formatPace(5.5), '5:30');
    });

    test('pads single-digit seconds', () {
      expect(PaceCalculatorService.formatPace(4.083), '4:05');
    });

    test('formats fast pace', () {
      expect(PaceCalculatorService.formatPace(3.25), '3:15');
    });
  });

  group('PaceCalculatorService.formatDuration', () {
    test('formats minutes and seconds without hours', () {
      expect(PaceCalculatorService.formatDuration(
          const Duration(minutes: 25, seconds: 30)), '25:30');
    });

    test('formats with hours', () {
      expect(PaceCalculatorService.formatDuration(
          const Duration(hours: 1, minutes: 5, seconds: 3)), '1:05:03');
    });

    test('formats zero duration', () {
      expect(PaceCalculatorService.formatDuration(Duration.zero), '0:00');
    });

    test('formats large duration', () {
      expect(PaceCalculatorService.formatDuration(
          const Duration(hours: 4, minutes: 0, seconds: 0)), '4:00:00');
    });
  });

  group('PaceCalculatorService.raceDistances', () {
    test('contains standard race distances', () {
      expect(PaceCalculatorService.raceDistances['5K'], 5.0);
      expect(PaceCalculatorService.raceDistances['10K'], 10.0);
      expect(PaceCalculatorService.raceDistances['Marathon'], 42.195);
      expect(PaceCalculatorService.raceDistances['Half Marathon'], 21.0975);
    });
  });

  group('PaceResult', () {
    test('unitLabel returns km when not using miles', () {
      final result = PaceCalculatorService.fromDistanceAndTime(
        distanceKm: 10.0,
        totalTime: const Duration(minutes: 50),
      );
      expect(result.unitLabel, 'km');
    });

    test('unitLabel returns mi when using miles', () {
      final result = PaceCalculatorService.fromDistanceAndTime(
        distanceKm: 10.0,
        totalTime: const Duration(minutes: 50),
        useMiles: true,
      );
      expect(result.unitLabel, 'mi');
    });

    test('displayDistance converts to miles when useMiles', () {
      final result = PaceCalculatorService.fromDistanceAndTime(
        distanceKm: 10.0,
        totalTime: const Duration(minutes: 50),
        useMiles: true,
      );
      expect(result.displayDistance, closeTo(6.214, 0.01));
    });

    test('displaySpeed returns mph when useMiles', () {
      final result = PaceCalculatorService.fromDistanceAndTime(
        distanceKm: 10.0,
        totalTime: const Duration(minutes: 50),
        useMiles: true,
      );
      expect(result.displaySpeed, result.speedMph);
    });
  });
}
