import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/travel_entry.dart';
import 'package:everything/core/services/travel_log_service.dart';

void main() {
  const service = TravelLogService();
  final now = DateTime.now();

  TravelEntry _make({
    String id = 't1',
    String destination = 'Tokyo',
    String? country = 'Japan',
    DateTime? startDate,
    DateTime? endDate,
    TripType type = TripType.leisure,
    TripTransport transport = TripTransport.flight,
    TripRating? rating,
    double? totalCost,
    List<String> highlights = const [],
    bool isCompleted = true,
  }) {
    return TravelEntry(
      id: id,
      destination: destination,
      country: country,
      startDate: startDate ?? now.subtract(const Duration(days: 10)),
      endDate: endDate ?? now.subtract(const Duration(days: 5)),
      type: type,
      transport: transport,
      rating: rating,
      totalCost: totalCost,
      highlights: highlights,
      isCompleted: isCompleted,
    );
  }

  // ─── Model Tests ──────────────────────────────────────────────────

  group('TravelEntry model', () {
    test('durationDays calculates correctly', () {
      final e = _make(
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 5),
      );
      expect(e.durationDays, 5);
    });

    test('durationDays is at least 1 for same-day trip', () {
      final d = DateTime(2026, 3, 1);
      final e = _make(startDate: d, endDate: d);
      expect(e.durationDays, 1);
    });

    test('costPerDay is null without totalCost', () {
      final e = _make();
      expect(e.costPerDay, isNull);
    });

    test('costPerDay calculates correctly', () {
      final e = _make(
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 5),
        totalCost: 500,
      );
      expect(e.costPerDay, 100.0);
    });

    test('isUpcoming for future trip', () {
      final e = _make(
        startDate: now.add(const Duration(days: 10)),
        endDate: now.add(const Duration(days: 15)),
        isCompleted: false,
      );
      expect(e.isUpcoming, true);
    });

    test('isUpcoming false for past trip', () {
      final e = _make();
      expect(e.isUpcoming, false);
    });

    test('copyWith preserves fields', () {
      final e = _make(totalCost: 1200, rating: TripRating.great);
      final copy = e.copyWith(destination: 'Osaka');
      expect(copy.destination, 'Osaka');
      expect(copy.totalCost, 1200);
      expect(copy.rating, TripRating.great);
      expect(copy.id, e.id);
    });

    test('copyWith overrides specified fields', () {
      final e = _make(type: TripType.business);
      final copy = e.copyWith(type: TripType.adventure);
      expect(copy.type, TripType.adventure);
    });
  });

  group('TripType enum', () {
    test('all types have label and emoji', () {
      for (final t in TripType.values) {
        expect(t.label.isNotEmpty, true);
        expect(t.emoji.isNotEmpty, true);
      }
    });
  });

  group('TripTransport enum', () {
    test('all transports have label and emoji', () {
      for (final t in TripTransport.values) {
        expect(t.label.isNotEmpty, true);
        expect(t.emoji.isNotEmpty, true);
      }
    });
  });

  group('TripRating enum', () {
    test('ratings are 1 through 5', () {
      final values = TripRating.values.map((r) => r.value).toList()..sort();
      expect(values, [1, 2, 3, 4, 5]);
    });
  });

  // ─── Service Tests ────────────────────────────────────────────────

  group('computeStats', () {
    test('empty list returns zeroes', () {
      final stats = service.computeStats([]);
      expect(stats.totalTrips, 0);
      expect(stats.totalDays, 0);
      expect(stats.totalSpent, 0);
      expect(stats.avgRating, 0);
    });

    test('counts total trips and days', () {
      final entries = [
        _make(
          id: 't1',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 5),
        ),
        _make(
          id: 't2',
          startDate: DateTime(2026, 2, 10),
          endDate: DateTime(2026, 2, 12),
        ),
      ];
      final stats = service.computeStats(entries);
      expect(stats.totalTrips, 2);
      expect(stats.totalDays, 8); // 5 + 3
    });

    test('calculates average rating', () {
      final entries = [
        _make(id: 't1', rating: TripRating.amazing),
        _make(id: 't2', rating: TripRating.good),
      ];
      final stats = service.computeStats(entries);
      expect(stats.avgRating, 4.0); // (5+3)/2
    });

    test('excludes non-completed trips', () {
      final entries = [
        _make(id: 't1'),
        _make(id: 't2', isCompleted: false),
      ];
      final stats = service.computeStats(entries);
      expect(stats.totalTrips, 1);
    });

    test('counts unique countries', () {
      final entries = [
        _make(id: 't1', country: 'Japan'),
        _make(id: 't2', country: 'Japan'),
        _make(id: 't3', country: 'France'),
      ];
      final stats = service.computeStats(entries);
      expect(stats.countriesVisited, 2);
    });

    test('counts unique cities', () {
      final entries = [
        _make(id: 't1', destination: 'Tokyo'),
        _make(id: 't2', destination: 'Tokyo'),
        _make(id: 't3', destination: 'Paris'),
      ];
      final stats = service.computeStats(entries);
      expect(stats.citiesVisited, 2);
    });

    test('sums total cost', () {
      final entries = [
        _make(id: 't1', totalCost: 1000),
        _make(id: 't2', totalCost: 500),
      ];
      final stats = service.computeStats(entries);
      expect(stats.totalSpent, 1500);
    });

    test('finds longest trip', () {
      final entries = [
        _make(
          id: 't1',
          startDate: DateTime(2026, 1, 1),
          endDate: DateTime(2026, 1, 3),
        ),
        _make(
          id: 't2',
          startDate: DateTime(2026, 2, 1),
          endDate: DateTime(2026, 2, 10),
        ),
      ];
      final stats = service.computeStats(entries);
      expect(stats.longestTripDays, 10);
    });

    test('identifies favorite destination', () {
      final entries = [
        _make(id: 't1', destination: 'Tokyo'),
        _make(id: 't2', destination: 'Tokyo'),
        _make(id: 't3', destination: 'Paris'),
      ];
      final stats = service.computeStats(entries);
      expect(stats.favoriteDestination, 'Tokyo');
    });

    test('tracks type breakdown', () {
      final entries = [
        _make(id: 't1', type: TripType.business),
        _make(id: 't2', type: TripType.leisure),
        _make(id: 't3', type: TripType.business),
      ];
      final stats = service.computeStats(entries);
      expect(stats.typeBreakdown[TripType.business], 2);
      expect(stats.typeBreakdown[TripType.leisure], 1);
    });

    test('tracks transport breakdown', () {
      final entries = [
        _make(id: 't1', transport: TripTransport.flight),
        _make(id: 't2', transport: TripTransport.train),
        _make(id: 't3', transport: TripTransport.flight),
      ];
      final stats = service.computeStats(entries);
      expect(stats.transportBreakdown[TripTransport.flight], 2);
    });
  });

  group('getMonthlyCosts', () {
    test('empty list returns empty', () {
      expect(service.getMonthlyCosts([]), isEmpty);
    });

    test('groups by month', () {
      final entries = [
        _make(
          id: 't1',
          startDate: DateTime(2026, 1, 5),
          endDate: DateTime(2026, 1, 10),
          totalCost: 800,
        ),
        _make(
          id: 't2',
          startDate: DateTime(2026, 1, 20),
          endDate: DateTime(2026, 1, 22),
          totalCost: 200,
        ),
        _make(
          id: 't3',
          startDate: DateTime(2026, 3, 1),
          endDate: DateTime(2026, 3, 5),
          totalCost: 600,
        ),
      ];
      final costs = service.getMonthlyCosts(entries);
      expect(costs.length, 2);
      expect(costs[0].month, 1);
      expect(costs[0].total, 1000);
      expect(costs[0].tripCount, 2);
      expect(costs[1].month, 3);
      expect(costs[1].total, 600);
    });

    test('excludes entries without cost', () {
      final entries = [
        _make(id: 't1', totalCost: 500,
            startDate: DateTime(2026, 2, 1), endDate: DateTime(2026, 2, 3)),
        _make(id: 't2',
            startDate: DateTime(2026, 2, 10), endDate: DateTime(2026, 2, 12)),
      ];
      final costs = service.getMonthlyCosts(entries);
      expect(costs.length, 1);
      expect(costs[0].total, 500);
      expect(costs[0].tripCount, 1);
    });

    test('sorted chronologically', () {
      final entries = [
        _make(id: 't1', totalCost: 100,
            startDate: DateTime(2026, 6, 1), endDate: DateTime(2026, 6, 3)),
        _make(id: 't2', totalCost: 200,
            startDate: DateTime(2026, 2, 1), endDate: DateTime(2026, 2, 3)),
      ];
      final costs = service.getMonthlyCosts(entries);
      expect(costs[0].month, 2);
      expect(costs[1].month, 6);
    });
  });

  group('getUpcoming', () {
    test('returns only future, non-completed trips', () {
      final entries = [
        _make(id: 't1'), // past completed
        _make(
          id: 't2',
          startDate: now.add(const Duration(days: 5)),
          endDate: now.add(const Duration(days: 10)),
          isCompleted: false,
        ),
        _make(
          id: 't3',
          startDate: now.add(const Duration(days: 20)),
          endDate: now.add(const Duration(days: 25)),
          isCompleted: false,
        ),
      ];
      final upcoming = service.getUpcoming(entries);
      expect(upcoming.length, 2);
      expect(upcoming[0].id, 't2'); // earliest first
    });

    test('empty when all completed', () {
      final entries = [_make(id: 't1'), _make(id: 't2')];
      expect(service.getUpcoming(entries), isEmpty);
    });
  });

  group('getByYear', () {
    test('filters by year', () {
      final entries = [
        _make(id: 't1', startDate: DateTime(2025, 5, 1),
            endDate: DateTime(2025, 5, 5)),
        _make(id: 't2', startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 1, 3)),
        _make(id: 't3', startDate: DateTime(2026, 6, 1),
            endDate: DateTime(2026, 6, 5)),
      ];
      final y2026 = service.getByYear(entries, 2026);
      expect(y2026.length, 2);
    });

    test('returns most recent first', () {
      final entries = [
        _make(id: 't1', startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 1, 3)),
        _make(id: 't2', startDate: DateTime(2026, 6, 1),
            endDate: DateTime(2026, 6, 5)),
      ];
      final result = service.getByYear(entries, 2026);
      expect(result[0].id, 't2');
    });
  });

  group('getYears', () {
    test('returns unique years descending', () {
      final entries = [
        _make(id: 't1', startDate: DateTime(2024, 1, 1),
            endDate: DateTime(2024, 1, 3)),
        _make(id: 't2', startDate: DateTime(2026, 1, 1),
            endDate: DateTime(2026, 1, 3)),
        _make(id: 't3', startDate: DateTime(2025, 1, 1),
            endDate: DateTime(2025, 1, 3)),
      ];
      expect(service.getYears(entries), [2026, 2025, 2024]);
    });
  });

  group('generateInsights', () {
    test('empty for no entries', () {
      expect(service.generateInsights([]), isEmpty);
    });

    test('generates insights for trips', () {
      final entries = [
        _make(id: 't1', totalCost: 1000, rating: TripRating.great,
            country: 'Japan'),
        _make(id: 't2', totalCost: 800, rating: TripRating.amazing,
            destination: 'Paris', country: 'France'),
      ];
      final insights = service.generateInsights(entries);
      expect(insights.length, greaterThanOrEqualTo(4));
      expect(insights.any((i) => i.title == 'Total Travel'), true);
      expect(insights.any((i) => i.title == 'Countries'), true);
      expect(insights.any((i) => i.title == 'Avg Rating'), true);
      expect(insights.any((i) => i.title == 'Avg Trip Cost'), true);
    });

    test('includes preferred transport', () {
      final entries = [
        _make(id: 't1', transport: TripTransport.train),
        _make(id: 't2', transport: TripTransport.train),
        _make(id: 't3', transport: TripTransport.flight),
      ];
      final insights = service.generateInsights(entries);
      final transportInsight = insights.firstWhere(
          (i) => i.title == 'Preferred Transport',
          orElse: () => const TravelInsight(
              title: '', value: '', emoji: ''));
      expect(transportInsight.value, 'Train');
    });

    test('includes most visited destination', () {
      final entries = [
        _make(id: 't1', destination: 'Tokyo'),
        _make(id: 't2', destination: 'Tokyo'),
        _make(id: 't3', destination: 'Paris'),
      ];
      final insights = service.generateInsights(entries);
      final mostVisited = insights.firstWhere(
          (i) => i.title == 'Most Visited',
          orElse: () => const TravelInsight(
              title: '', value: '', emoji: ''));
      expect(mostVisited.value, 'Tokyo');
    });
  });

  group('TravelMonthlyCost', () {
    test('label formats correctly', () {
      const cost = TravelMonthlyCost(
          year: 2026, month: 3, total: 1500, tripCount: 2);
      expect(cost.label, 'Mar 2026');
    });

    test('clamps invalid months', () {
      const cost = TravelMonthlyCost(
          year: 2026, month: 0, total: 0, tripCount: 0);
      expect(cost.label, 'Jan 2026'); // clamps to 1
    });
  });
}
