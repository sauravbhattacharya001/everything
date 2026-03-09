import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/water_entry.dart';
import 'package:everything/core/services/water_tracker_service.dart';

void main() {
  // ── Model Tests ──

  group('DrinkType', () {
    test('water has hydration factor 1.0', () {
      expect(DrinkType.water.hydrationFactor, 1.0);
    });

    test('coffee has reduced hydration factor', () {
      expect(DrinkType.coffee.hydrationFactor, 0.8);
    });

    test('all types have labels and emojis', () {
      for (final type in DrinkType.values) {
        expect(type.label.isNotEmpty, true);
        expect(type.emoji.isNotEmpty, true);
      }
    });
  });

  group('ContainerSize', () {
    test('sizes have increasing default ml', () {
      expect(ContainerSize.sip.defaultMl, 50);
      expect(ContainerSize.small.defaultMl, 200);
      expect(ContainerSize.medium.defaultMl, 300);
      expect(ContainerSize.large.defaultMl, 400);
      expect(ContainerSize.bottle.defaultMl, 500);
    });

    test('all sizes have labels', () {
      for (final size in ContainerSize.values) {
        expect(size.label.isNotEmpty, true);
      }
    });
  });

  group('WaterEntry', () {
    test('creates with defaults', () {
      final entry = WaterEntry(
        id: '1',
        timestamp: DateTime(2026, 3, 4, 10, 0),
        amountMl: 300,
      );
      expect(entry.drinkType, DrinkType.water);
      expect(entry.containerSize, ContainerSize.medium);
      expect(entry.note, isNull);
    });

    test('effectiveHydrationMl adjusts for drink type', () {
      final water = WaterEntry(
        id: '1',
        timestamp: DateTime(2026, 3, 4),
        amountMl: 300,
        drinkType: DrinkType.water,
      );
      expect(water.effectiveHydrationMl, 300.0);

      final coffee = WaterEntry(
        id: '2',
        timestamp: DateTime(2026, 3, 4),
        amountMl: 300,
        drinkType: DrinkType.coffee,
      );
      expect(coffee.effectiveHydrationMl, 240.0);
    });

    test('serializes to/from JSON', () {
      final entry = WaterEntry(
        id: 'test-1',
        timestamp: DateTime(2026, 3, 4, 14, 30),
        amountMl: 500,
        drinkType: DrinkType.tea,
        containerSize: ContainerSize.bottle,
        note: 'Green tea',
      );
      final json = entry.toJson();
      final restored = WaterEntry.fromJson(json);
      expect(restored.id, 'test-1');
      expect(restored.amountMl, 500);
      expect(restored.drinkType, DrinkType.tea);
      expect(restored.containerSize, ContainerSize.bottle);
      expect(restored.note, 'Green tea');
    });

    test('copyWith works', () {
      final entry = WaterEntry(
        id: '1',
        timestamp: DateTime(2026, 3, 4),
        amountMl: 300,
      );
      final updated = entry.copyWith(amountMl: 500, drinkType: DrinkType.juice);
      expect(updated.amountMl, 500);
      expect(updated.drinkType, DrinkType.juice);
      expect(updated.id, '1');
    });

    test('encodeList and decodeList roundtrip', () {
      final entries = [
        WaterEntry(id: '1', timestamp: DateTime(2026, 3, 4, 8), amountMl: 300),
        WaterEntry(
            id: '2',
            timestamp: DateTime(2026, 3, 4, 10),
            amountMl: 200,
            drinkType: DrinkType.coffee),
      ];
      final json = WaterEntry.encodeList(entries);
      final decoded = WaterEntry.decodeList(json);
      expect(decoded.length, 2);
      expect(decoded[0].id, '1');
      expect(decoded[1].drinkType, DrinkType.coffee);
    });

    test('fromJson handles missing fields gracefully', () {
      final entry = WaterEntry.fromJson({'id': 'x', 'timestamp': '2026-03-04'});
      expect(entry.amountMl, 250);
      expect(entry.drinkType, DrinkType.water);
    });
  });

  // ── Config Tests ──

  group('HydrationConfig', () {
    test('defaults are sensible', () {
      const config = HydrationConfig();
      expect(config.dailyGoalMl, 2500);
      expect(config.wakeHour, 7);
      expect(config.sleepHour, 23);
      expect(config.activeHours, 16);
    });

    test('mlPerHour calculation', () {
      const config = HydrationConfig(dailyGoalMl: 2400, wakeHour: 8, sleepHour: 20);
      expect(config.activeHours, 12);
      expect(config.mlPerHour, 200.0);
    });

    test('serializes to/from JSON', () {
      const config = HydrationConfig(dailyGoalMl: 3000, wakeHour: 6, sleepHour: 22);
      final json = config.toJson();
      final restored = HydrationConfig.fromJson(json);
      expect(restored.dailyGoalMl, 3000);
      expect(restored.wakeHour, 6);
    });
  });

  // ── Service Tests ──

  group('WaterTrackerService', () {
    late WaterTrackerService service;
    final today = DateTime(2026, 3, 4);

    setUp(() {
      service = const WaterTrackerService(
        config: HydrationConfig(dailyGoalMl: 2000, wakeHour: 8, sleepHour: 22),
      );
    });

    List<WaterEntry> _makeEntries(List<Map<String, dynamic>> specs) {
      return specs
          .asMap()
          .entries
          .map((e) => WaterEntry(
                id: 'e${e.key}',
                timestamp: e.value['time'] as DateTime,
                amountMl: e.value['ml'] as int,
                drinkType:
                    (e.value['type'] as DrinkType?) ?? DrinkType.water,
              ))
          .toList();
    }

    group('HydrationDailySummary', () {
      test('empty entries returns zero totals', () {
        final s = service.HydrationDailySummary([], today);
        expect(s.totalMl, 0);
        expect(s.entryCount, 0);
        expect(s.progressPercent, 0);
        expect(s.goalMet, false);
        expect(s.grade, 'F');
      });

      test('sums entries for the correct day', () {
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 300},
          {'time': DateTime(2026, 3, 4, 12), 'ml': 500},
          {'time': DateTime(2026, 3, 3, 10), 'ml': 1000}, // different day
        ]);
        final s = service.HydrationDailySummary(entries, today);
        expect(s.totalMl, 800);
        expect(s.entryCount, 2);
      });

      test('tracks drink type breakdown', () {
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 300, 'type': DrinkType.water},
          {'time': DateTime(2026, 3, 4, 10), 'ml': 200, 'type': DrinkType.coffee},
          {'time': DateTime(2026, 3, 4, 14), 'ml': 300, 'type': DrinkType.water},
        ]);
        final s = service.HydrationDailySummary(entries, today);
        expect(s.byDrinkType[DrinkType.water], 600);
        expect(s.byDrinkType[DrinkType.coffee], 200);
      });

      test('tracks hourly breakdown', () {
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 300},
          {'time': DateTime(2026, 3, 4, 8, 30), 'ml': 200},
          {'time': DateTime(2026, 3, 4, 14), 'ml': 500},
        ]);
        final s = service.HydrationDailySummary(entries, today);
        expect(s.byHour[8], 500);
        expect(s.byHour[14], 500);
      });

      test('effective hydration accounts for drink factors', () {
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 10), 'ml': 200, 'type': DrinkType.coffee},
        ]);
        final s = service.HydrationDailySummary(entries, today);
        expect(s.totalMl, 200);
        expect(s.effectiveHydrationMl, 160.0);
      });

      test('grade reflects progress', () {
        // 100% = A
        var entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 2000},
        ]);
        expect(service.HydrationDailySummary(entries, today).grade, 'A');

        // 80% = B
        entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 1600},
        ]);
        expect(service.HydrationDailySummary(entries, today).grade, 'B');

        // 60% = C
        entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 1200},
        ]);
        expect(service.HydrationDailySummary(entries, today).grade, 'C');

        // 40% = D
        entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 800},
        ]);
        expect(service.HydrationDailySummary(entries, today).grade, 'D');

        // <40% = F
        entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 500},
        ]);
        expect(service.HydrationDailySummary(entries, today).grade, 'F');
      });

      test('remaining ml clamps at 0 when over goal', () {
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 3000},
        ]);
        final s = service.HydrationDailySummary(entries, today);
        expect(s.remainingMl, 0);
        expect(s.goalMet, true);
      });
    });

    group('pacing', () {
      test('ahead when consumed more than expected', () {
        final now = DateTime(2026, 3, 4, 12, 0); // 4 hours after wake(8)
        // expected: 4h * 2000/14 ≈ 571ml
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 400},
          {'time': DateTime(2026, 3, 4, 10), 'ml': 400},
        ]);
        final p = service.pacing(entries, now);
        expect(p.status, 'ahead');
        expect(p.actualMlByNow, 800);
      });

      test('behind when consumed less than expected', () {
        final now = DateTime(2026, 3, 4, 15, 0); // 7 hours after wake
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 200},
        ]);
        final p = service.pacing(entries, now);
        expect(p.status == 'behind' || p.status == 'way_behind', true);
      });

      test('on_track when near expected', () {
        final now = DateTime(2026, 3, 4, 12, 0); // 4 hours
        // expected ~571ml, provide ~550
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 250},
          {'time': DateTime(2026, 3, 4, 10), 'ml': 300},
        ]);
        final p = service.pacing(entries, now);
        expect(p.status, 'on_track');
      });

      test('before wake hour shows 0 expected', () {
        final now = DateTime(2026, 3, 4, 6, 0);
        final p = service.pacing([], now);
        expect(p.expectedMlByNow, 0);
      });
    });

    group('streak', () {
      test('no entries = no streak', () {
        final s = service.streak([], today);
        expect(s.currentStreak, 0);
        expect(s.longestStreak, 0);
      });

      test('consecutive goal days build streak', () {
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 10), 'ml': 2000},
          {'time': DateTime(2026, 3, 3, 10), 'ml': 2000},
          {'time': DateTime(2026, 3, 2, 10), 'ml': 2000},
        ]);
        final s = service.streak(entries, today);
        expect(s.currentStreak, 3);
        expect(s.longestStreak, 3);
      });

      test('gap breaks current streak', () {
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 10), 'ml': 2000},
          // gap on 3/3
          {'time': DateTime(2026, 3, 2, 10), 'ml': 2000},
          {'time': DateTime(2026, 3, 1, 10), 'ml': 2000},
        ]);
        final s = service.streak(entries, today);
        expect(s.currentStreak, 1);
        expect(s.longestStreak, 2); // 3/1 + 3/2
      });

      test('below-goal day breaks streak', () {
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 10), 'ml': 500}, // below goal
        ]);
        final s = service.streak(entries, today);
        expect(s.currentStreak, 0);
      });
    });

    group('weeklyTrend', () {
      test('calculates 7-day averages', () {
        final entries = <WaterEntry>[];
        for (int i = 0; i < 7; i++) {
          entries.add(WaterEntry(
            id: 'd$i',
            timestamp: today.subtract(Duration(days: i)).add(const Duration(hours: 10)),
            amountMl: 1000 + i * 200,
          ));
        }
        final trend = service.weeklyTrend(entries, today);
        expect(trend.days.length, 7);
        expect(trend.avgDailyMl, greaterThan(0));
        expect(trend.mostCommonDrink, DrinkType.water);
      });

      test('finds peak hour', () {
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 14), 'ml': 1000},
          {'time': DateTime(2026, 3, 4, 8), 'ml': 200},
        ]);
        final trend = service.weeklyTrend(entries, today);
        expect(trend.peakHour, 14);
      });

      test('consistency is 100 when all days equal', () {
        final entries = <WaterEntry>[];
        for (int i = 0; i < 7; i++) {
          entries.add(WaterEntry(
            id: 'd$i',
            timestamp: today.subtract(Duration(days: i)).add(const Duration(hours: 10)),
            amountMl: 2000,
          ));
        }
        final trend = service.weeklyTrend(entries, today);
        expect(trend.consistency, 100.0);
      });

      test('counts days goal met', () {
        final entries = <WaterEntry>[];
        // 3 days meet goal
        for (int i = 0; i < 3; i++) {
          entries.add(WaterEntry(
            id: 'd$i',
            timestamp: today.subtract(Duration(days: i)).add(const Duration(hours: 10)),
            amountMl: 2000,
          ));
        }
        final trend = service.weeklyTrend(entries, today);
        expect(trend.daysGoalMet, 3);
      });
    });

    group('drinkTypePercentages', () {
      test('empty returns empty map', () {
        expect(service.drinkTypePercentages([]), isEmpty);
      });

      test('calculates percentages correctly', () {
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 600, 'type': DrinkType.water},
          {'time': DateTime(2026, 3, 4, 10), 'ml': 200, 'type': DrinkType.coffee},
          {'time': DateTime(2026, 3, 4, 14), 'ml': 200, 'type': DrinkType.tea},
        ]);
        final pct = service.drinkTypePercentages(entries);
        expect(pct[DrinkType.water], 60.0);
        expect(pct[DrinkType.coffee], 20.0);
        expect(pct[DrinkType.tea], 20.0);
      });
    });

    group('generateTips', () {
      test('tip for high coffee intake', () {
        final summary = HydrationDailySummary(
          date: today,
          totalMl: 1000,
          effectiveHydrationMl: 800,
          entryCount: 3,
          goalMl: 2000,
          byDrinkType: {DrinkType.coffee: 600},
          byHour: {10: 500, 14: 500},
        );
        final pace = const HydrationPacing(
          currentHour: 14,
          expectedMlByNow: 800,
          actualMlByNow: 1000,
          status: 'ahead',
          suggestedNextMl: 150,
          recommendation: '',
        );
        final tips = service.generateTips(summary, pace);
        expect(tips.any((t) => t.contains('coffee')), true);
      });

      test('tip for no morning intake', () {
        final summary = HydrationDailySummary(
          date: today,
          totalMl: 500,
          effectiveHydrationMl: 500,
          entryCount: 2,
          goalMl: 2000,
          byDrinkType: {DrinkType.water: 500},
          byHour: {14: 300, 16: 200},
        );
        final pace = const HydrationPacing(
          currentHour: 16,
          expectedMlByNow: 1000,
          actualMlByNow: 500,
          status: 'behind',
          suggestedNextMl: 300,
          recommendation: '',
        );
        final tips = service.generateTips(summary, pace);
        expect(tips.any((t) => t.contains('morning')), true);
      });

      test('tip for goal reached', () {
        final summary = HydrationDailySummary(
          date: today,
          totalMl: 2500,
          effectiveHydrationMl: 2500,
          entryCount: 8,
          goalMl: 2000,
          byDrinkType: {DrinkType.water: 2500},
          byHour: {8: 300, 10: 300, 12: 500, 14: 500, 16: 500, 18: 400},
        );
        final pace = const HydrationPacing(
          currentHour: 18,
          expectedMlByNow: 1500,
          actualMlByNow: 2500,
          status: 'ahead',
          suggestedNextMl: 100,
          recommendation: '',
        );
        final tips = service.generateTips(summary, pace);
        expect(tips.any((t) => t.contains('🎉')), true);
      });

      test('tip for large infrequent drinks', () {
        final summary = HydrationDailySummary(
          date: today,
          totalMl: 1500,
          effectiveHydrationMl: 1500,
          entryCount: 2,
          goalMl: 2000,
          byDrinkType: {DrinkType.water: 1500},
          byHour: {8: 750, 14: 750},
        );
        final pace = const HydrationPacing(
          currentHour: 14,
          expectedMlByNow: 800,
          actualMlByNow: 1500,
          status: 'ahead',
          suggestedNextMl: 100,
          recommendation: '',
        );
        final tips = service.generateTips(summary, pace);
        expect(tips.any((t) => t.contains('smaller')), true);
      });

      test('tip for being behind', () {
        final summary = HydrationDailySummary(
          date: today,
          totalMl: 200,
          effectiveHydrationMl: 200,
          entryCount: 1,
          goalMl: 2000,
          byDrinkType: {DrinkType.water: 200},
          byHour: {8: 200},
        );
        final pace = const HydrationPacing(
          currentHour: 16,
          expectedMlByNow: 1200,
          actualMlByNow: 200,
          status: 'way_behind',
          suggestedNextMl: 400,
          recommendation: '',
        );
        final tips = service.generateTips(summary, pace);
        expect(tips.any((t) => t.contains('timer')), true);
      });

      test('tip for soda intake', () {
        final summary = HydrationDailySummary(
          date: today,
          totalMl: 800,
          effectiveHydrationMl: 600,
          entryCount: 3,
          goalMl: 2000,
          byDrinkType: {DrinkType.soda: 400, DrinkType.water: 400},
          byHour: {10: 400, 14: 400},
        );
        final pace = const HydrationPacing(
          currentHour: 14,
          expectedMlByNow: 800,
          actualMlByNow: 800,
          status: 'on_track',
          suggestedNextMl: 150,
          recommendation: '',
        );
        final tips = service.generateTips(summary, pace);
        expect(tips.any((t) => t.contains('soda')), true);
      });
    });

    group('report', () {
      test('generates full report', () {
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 300},
          {'time': DateTime(2026, 3, 4, 10), 'ml': 400},
          {'time': DateTime(2026, 3, 4, 12), 'ml': 300},
        ]);
        final now = DateTime(2026, 3, 4, 14);
        final r = service.report(entries, now);
        expect(r.today.totalMl, 1000);
        expect(r.pacing.status, isNotEmpty);
        expect(r.streak, isNotNull);
        expect(r.weeklyTrend, isNotNull);
      });

      test('toTextSummary includes key info', () {
        final entries = _makeEntries([
          {'time': DateTime(2026, 3, 4, 8), 'ml': 2000},
        ]);
        final r = service.report(entries, DateTime(2026, 3, 4, 14));
        final text = r.toTextSummary();
        expect(text.contains('Hydration Report'), true);
        expect(text.contains('2000ml'), true);
        expect(text.contains('Streak'), true);
      });
    });
  });
}
