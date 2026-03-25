import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/blood_sugar_entry.dart';
import 'package:everything/core/services/blood_sugar_service.dart';

void main() {
  const service = BloodSugarService();

  group('BloodSugarEntry', () {
    test('categorizes normal fasting glucose', () {
      final entry = BloodSugarEntry(
        id: '1',
        timestamp: DateTime.now(),
        glucoseMgDl: 90,
        mealContext: MealContext.fasting,
      );
      expect(entry.category, BSCategory.normal);
    });

    test('categorizes pre-diabetic fasting glucose', () {
      final entry = BloodSugarEntry(
        id: '2',
        timestamp: DateTime.now(),
        glucoseMgDl: 110,
        mealContext: MealContext.fasting,
      );
      expect(entry.category, BSCategory.prediabetic);
    });

    test('categorizes diabetic fasting glucose', () {
      final entry = BloodSugarEntry(
        id: '3',
        timestamp: DateTime.now(),
        glucoseMgDl: 140,
        mealContext: MealContext.fasting,
      );
      expect(entry.category, BSCategory.diabetic);
    });

    test('categorizes normal post-meal glucose', () {
      final entry = BloodSugarEntry(
        id: '4',
        timestamp: DateTime.now(),
        glucoseMgDl: 130,
        mealContext: MealContext.afterMeal2h,
      );
      expect(entry.category, BSCategory.normal);
    });

    test('categorizes low glucose', () {
      final entry = BloodSugarEntry(
        id: '5',
        timestamp: DateTime.now(),
        glucoseMgDl: 55,
      );
      expect(entry.category, BSCategory.low);
    });

    test('categorizes dangerously high glucose', () {
      final entry = BloodSugarEntry(
        id: '6',
        timestamp: DateTime.now(),
        glucoseMgDl: 350,
      );
      expect(entry.category, BSCategory.dangerouslyHigh);
    });

    test('converts mg/dL to mmol/L', () {
      final entry = BloodSugarEntry(
        id: '7',
        timestamp: DateTime.now(),
        glucoseMgDl: 180,
      );
      expect(entry.glucoseMmolL, closeTo(10.0, 0.1));
    });

    test('JSON round-trip', () {
      final entry = BloodSugarEntry(
        id: 'test',
        timestamp: DateTime(2026, 3, 24, 12, 0),
        glucoseMgDl: 95,
        mealContext: MealContext.beforeMeal,
        note: 'Before lunch',
      );
      final json = entry.toJson();
      final restored = BloodSugarEntry.fromJson(json);
      expect(restored.id, entry.id);
      expect(restored.glucoseMgDl, entry.glucoseMgDl);
      expect(restored.mealContext, entry.mealContext);
      expect(restored.note, entry.note);
    });

    test('encodeList/decodeList round-trip', () {
      final entries = [
        BloodSugarEntry(
          id: 'a',
          timestamp: DateTime.now(),
          glucoseMgDl: 100,
        ),
        BloodSugarEntry(
          id: 'b',
          timestamp: DateTime.now(),
          glucoseMgDl: 200,
        ),
      ];
      final encoded = BloodSugarEntry.encodeList(entries);
      final decoded = BloodSugarEntry.decodeList(encoded);
      expect(decoded.length, 2);
      expect(decoded[0].glucoseMgDl, 100);
      expect(decoded[1].glucoseMgDl, 200);
    });
  });

  group('BloodSugarService', () {
    test('summarize returns correct stats', () {
      final entries = [
        BloodSugarEntry(id: '1', timestamp: DateTime.now(), glucoseMgDl: 90),
        BloodSugarEntry(id: '2', timestamp: DateTime.now(), glucoseMgDl: 110),
        BloodSugarEntry(id: '3', timestamp: DateTime.now(), glucoseMgDl: 100),
      ];
      final summary = service.summarize(entries);
      expect(summary.avgGlucose, 100);
      expect(summary.minGlucose, 90);
      expect(summary.maxGlucose, 110);
      expect(summary.readingCount, 3);
    });

    test('trend returns insufficient for few entries', () {
      final entries = [
        BloodSugarEntry(id: '1', timestamp: DateTime.now(), glucoseMgDl: 90),
      ];
      expect(service.trend(entries), BSTrend.insufficient);
    });

    test('estimatedA1c returns reasonable value', () {
      final entries = [
        BloodSugarEntry(id: '1', timestamp: DateTime.now(), glucoseMgDl: 100),
        BloodSugarEntry(id: '2', timestamp: DateTime.now(), glucoseMgDl: 100),
      ];
      final a1c = service.estimatedA1c(entries);
      expect(a1c, closeTo(5.1, 0.2));
    });

    test('timeInRange calculates correctly', () {
      final entries = [
        BloodSugarEntry(id: '1', timestamp: DateTime.now(), glucoseMgDl: 100),
        BloodSugarEntry(id: '2', timestamp: DateTime.now(), glucoseMgDl: 200),
        BloodSugarEntry(id: '3', timestamp: DateTime.now(), glucoseMgDl: 50),
        BloodSugarEntry(id: '4', timestamp: DateTime.now(), glucoseMgDl: 150),
      ];
      expect(service.timeInRange(entries), 50.0);
    });
  });
}
