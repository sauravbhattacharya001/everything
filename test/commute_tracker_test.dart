import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/commute_entry.dart';
import 'package:everything/core/services/commute_tracker_service.dart';

void main() {
  const service = CommuteTrackerService();
  final now = DateTime.now();

  CommuteEntry _make({
    String id = 'c1',
    DateTime? date,
    CommuteMode mode = CommuteMode.car,
    int durationMinutes = 30,
    double? distanceKm,
    double? cost,
    CommuteComfort? comfort,
    bool isReturn = false,
  }) {
    return CommuteEntry(
      id: id,
      date: date ?? now,
      mode: mode,
      durationMinutes: durationMinutes,
      distanceKm: distanceKm,
      cost: cost,
      comfort: comfort,
      isReturn: isReturn,
    );
  }

  group('CommuteEntry model', () {
    test('co2Kg calculates correctly for car', () {
      final e = _make(distanceKm: 10.0, mode: CommuteMode.car);
      expect(e.co2Kg, closeTo(2.1, 0.01));
    });

    test('co2Kg is zero for bike', () {
      final e = _make(distanceKm: 10.0, mode: CommuteMode.bike);
      expect(e.co2Kg, 0.0);
    });

    test('co2Kg is zero when no distance', () {
      final e = _make(mode: CommuteMode.car);
      expect(e.co2Kg, 0.0);
    });

    test('copyWith preserves fields', () {
      final e = _make(cost: 5.0, comfort: CommuteComfort.good);
      final copy = e.copyWith(durationMinutes: 45);
      expect(copy.durationMinutes, 45);
      expect(copy.cost, 5.0);
      expect(copy.comfort, CommuteComfort.good);
      expect(copy.id, e.id);
    });

    test('isReturn flag', () {
      final e = _make(isReturn: true);
      expect(e.isReturn, true);
      final e2 = _make();
      expect(e2.isReturn, false);
    });
  });

  group('CommuteMode', () {
    test('all modes have labels and emoji', () {
      for (final m in CommuteMode.values) {
        expect(m.label.isNotEmpty, true);
        expect(m.emoji.isNotEmpty, true);
      }
    });

    test('zero-emission modes', () {
      final green = CommuteMode.values.where((m) => m.co2PerKm == 0).toList();
      expect(green, contains(CommuteMode.bike));
      expect(green, contains(CommuteMode.walk));
      expect(green, contains(CommuteMode.workFromHome));
    });
  });

  group('CommuteComfort', () {
    test('values range 1-5', () {
      expect(CommuteComfort.terrible.value, 1);
      expect(CommuteComfort.great.value, 5);
      expect(CommuteComfort.values.length, 5);
    });
  });

  group('CommuteTrackerService', () {
    test('entriesForDate filters correctly', () {
      final entries = [
        _make(id: 'c1', date: DateTime(2026, 3, 1)),
        _make(id: 'c2', date: DateTime(2026, 3, 1, 17, 0)),
        _make(id: 'c3', date: DateTime(2026, 3, 2)),
      ];
      final result = service.entriesForDate(entries, DateTime(2026, 3, 1));
      expect(result.length, 2);
    });

    test('entriesForDate returns empty for no matches', () {
      final entries = [_make(date: DateTime(2026, 3, 1))];
      final result = service.entriesForDate(entries, DateTime(2026, 3, 5));
      expect(result, isEmpty);
    });

    test('entriesInRange works', () {
      final entries = [
        _make(id: 'c1', date: DateTime(2026, 3, 1)),
        _make(id: 'c2', date: DateTime(2026, 3, 5)),
        _make(id: 'c3', date: DateTime(2026, 3, 10)),
      ];
      final result = service.entriesInRange(
          entries, DateTime(2026, 3, 2), DateTime(2026, 3, 6));
      expect(result.length, 1);
      expect(result.first.id, 'c2');
    });

    test('totalCost sums costs', () {
      final entries = [
        _make(id: 'c1', cost: 5.0),
        _make(id: 'c2', cost: 3.50),
        _make(id: 'c3'),
      ];
      expect(service.totalCost(entries), closeTo(8.50, 0.01));
    });

    test('totalCost is zero for empty', () {
      expect(service.totalCost([]), 0.0);
    });

    test('totalCo2 sums emissions', () {
      final entries = [
        _make(id: 'c1', mode: CommuteMode.car, distanceKm: 10),
        _make(id: 'c2', mode: CommuteMode.bike, distanceKm: 5),
      ];
      expect(service.totalCo2(entries), closeTo(2.1, 0.01));
    });

    test('totalMinutes sums durations', () {
      final entries = [
        _make(id: 'c1', durationMinutes: 30),
        _make(id: 'c2', durationMinutes: 45),
      ];
      expect(service.totalMinutes(entries), 75);
    });

    test('avgComfort computes average', () {
      final entries = [
        _make(id: 'c1', comfort: CommuteComfort.great),
        _make(id: 'c2', comfort: CommuteComfort.okay),
        _make(id: 'c3'),
      ];
      expect(service.avgComfort(entries), closeTo(4.0, 0.01));
    });

    test('avgComfort returns 0 for no rated', () {
      expect(service.avgComfort([_make()]), 0);
    });

    test('topMode returns most frequent', () {
      final entries = [
        _make(id: 'c1', mode: CommuteMode.bus),
        _make(id: 'c2', mode: CommuteMode.bus),
        _make(id: 'c3', mode: CommuteMode.car),
      ];
      expect(service.topMode(entries), CommuteMode.bus);
    });

    test('topMode returns null for empty', () {
      expect(service.topMode([]), null);
    });

    test('greenPercentage correct', () {
      final entries = [
        _make(id: 'c1', mode: CommuteMode.bike),
        _make(id: 'c2', mode: CommuteMode.walk),
        _make(id: 'c3', mode: CommuteMode.car),
        _make(id: 'c4', mode: CommuteMode.bus),
      ];
      expect(service.greenPercentage(entries), closeTo(50.0, 0.01));
    });

    test('greenPercentage zero for empty', () {
      expect(service.greenPercentage([]), 0);
    });

    test('avgDurationMinutes', () {
      final entries = [
        _make(id: 'c1', durationMinutes: 20),
        _make(id: 'c2', durationMinutes: 40),
      ];
      expect(service.avgDurationMinutes(entries), 30.0);
    });

    test('modeDistribution', () {
      final entries = [
        _make(id: 'c1', mode: CommuteMode.car),
        _make(id: 'c2', mode: CommuteMode.car),
        _make(id: 'c3', mode: CommuteMode.bus),
        _make(id: 'c4', mode: CommuteMode.bike),
      ];
      final dist = service.modeDistribution(entries);
      expect(dist[CommuteMode.car], closeTo(50.0, 0.01));
      expect(dist[CommuteMode.bus], closeTo(25.0, 0.01));
      expect(dist[CommuteMode.bike], closeTo(25.0, 0.01));
    });

    test('modeDistribution empty', () {
      expect(service.modeDistribution([]), isEmpty);
    });

    test('weeklySummary aggregates', () {
      final weekStart = DateTime(2026, 3, 2); // Monday
      final entries = [
        _make(id: 'c1', date: DateTime(2026, 3, 2), durationMinutes: 30,
            distanceKm: 10, cost: 5, comfort: CommuteComfort.good,
            mode: CommuteMode.car),
        _make(id: 'c2', date: DateTime(2026, 3, 3), durationMinutes: 25,
            distanceKm: 8, cost: 3, comfort: CommuteComfort.great,
            mode: CommuteMode.bus),
        _make(id: 'c3', date: DateTime(2026, 3, 10), durationMinutes: 20),
      ];
      final summary = service.weeklySummary(entries, weekStart);
      expect(summary.totalTrips, 2);
      expect(summary.totalMinutes, 55);
      expect(summary.totalDistanceKm, closeTo(18.0, 0.01));
      expect(summary.totalCost, closeTo(8.0, 0.01));
      expect(summary.avgComfort, closeTo(4.5, 0.01));
    });

    test('currentStreak consecutive days', () {
      final entries = [
        _make(id: 'c1', date: DateTime(2026, 3, 7)),
        _make(id: 'c2', date: DateTime(2026, 3, 8)),
        _make(id: 'c3', date: DateTime(2026, 3, 9)),
      ];
      expect(service.currentStreak(entries), 3);
    });

    test('currentStreak broken', () {
      final entries = [
        _make(id: 'c1', date: DateTime(2026, 3, 5)),
        _make(id: 'c2', date: DateTime(2026, 3, 7)),
        _make(id: 'c3', date: DateTime(2026, 3, 8)),
      ];
      expect(service.currentStreak(entries), 2);
    });

    test('currentStreak empty', () {
      expect(service.currentStreak([]), 0);
    });

    test('monthlyInsights returns no-data message when empty', () {
      final insights = service.monthlyInsights([]);
      expect(insights.length, 1);
      expect(insights.first.label, 'No Data');
    });
  });

  group('WeeklySummary model', () {
    test('fields accessible', () {
      final s = CommuteWeeklySummary(
        weekStart: DateTime(2026, 3, 2),
        totalTrips: 5,
        totalMinutes: 150,
        totalDistanceKm: 50.0,
        totalCost: 25.0,
        totalCo2Kg: 10.5,
        modeBreakdown: {CommuteMode.car: 3, CommuteMode.bus: 2},
        avgComfort: 3.5,
      );
      expect(s.totalTrips, 5);
      expect(s.modeBreakdown.length, 2);
    });
  });

  group('MonthlyInsight model', () {
    test('fields accessible', () {
      const i = CommuteMonthlyInsight(
        label: 'Trips', value: '10', emoji: '🧭', comparison: '+2');
      expect(i.label, 'Trips');
      expect(i.comparison, '+2');
    });
  });
}
