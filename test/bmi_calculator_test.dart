import 'package:everything/core/services/bmi_calculator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BmiCalculatorService.calculate', () {
    test('normal BMI for 70kg at 175cm', () {
      final bmi = BmiCalculatorService.calculate(70, 175);
      // 70 / (1.75 * 1.75) = 22.86
      expect(bmi, closeTo(22.86, 0.01));
    });

    test('returns 0 for zero height', () {
      expect(BmiCalculatorService.calculate(70, 0), 0);
    });

    test('returns 0 for negative weight', () {
      expect(BmiCalculatorService.calculate(-5, 170), 0);
    });

    test('returns 0 for zero weight', () {
      expect(BmiCalculatorService.calculate(0, 170), 0);
    });
  });

  group('BmiCalculatorService.calculateImperial', () {
    test('150 lbs at 5\'8" gives expected BMI', () {
      final bmi = BmiCalculatorService.calculateImperial(150, 5, 8);
      // (150 * 703) / (68 * 68) = 22.82
      expect(bmi, closeTo(22.82, 0.1));
    });

    test('returns 0 for zero height', () {
      expect(BmiCalculatorService.calculateImperial(150, 0, 0), 0);
    });

    test('returns 0 for zero weight', () {
      expect(BmiCalculatorService.calculateImperial(0, 5, 10), 0);
    });
  });

  group('BmiCalculatorService.categorize', () {
    test('severe thinness below 16', () {
      expect(BmiCalculatorService.categorize(15), BmiCategory.severeThinness);
    });

    test('moderate thinness 16-17', () {
      expect(BmiCalculatorService.categorize(16.5), BmiCategory.moderateThinness);
    });

    test('mild thinness 17-18.5', () {
      expect(BmiCalculatorService.categorize(18), BmiCategory.mildThinness);
    });

    test('normal 18.5-25', () {
      expect(BmiCalculatorService.categorize(22), BmiCategory.normal);
    });

    test('overweight 25-30', () {
      expect(BmiCalculatorService.categorize(27), BmiCategory.overweight);
    });

    test('obese class I 30-35', () {
      expect(BmiCalculatorService.categorize(32), BmiCategory.obeseClassI);
    });

    test('obese class II 35-40', () {
      expect(BmiCalculatorService.categorize(37), BmiCategory.obeseClassII);
    });

    test('obese class III >= 40', () {
      expect(BmiCalculatorService.categorize(45), BmiCategory.obeseClassIII);
    });

    test('boundary at 18.5 is normal', () {
      expect(BmiCalculatorService.categorize(18.5), BmiCategory.normal);
    });

    test('boundary at 25 is overweight', () {
      expect(BmiCalculatorService.categorize(25), BmiCategory.overweight);
    });
  });

  group('BmiCalculatorService.healthyWeightRange', () {
    test('175cm healthy range', () {
      final (min, max) = BmiCalculatorService.healthyWeightRange(175);
      // 18.5 * 1.75^2 = 56.66, 24.9 * 1.75^2 = 76.27
      expect(min, closeTo(56.66, 0.1));
      expect(max, closeTo(76.27, 0.1));
    });
  });

  group('BmiCalculatorService unit conversions', () {
    test('kg to lbs round trip', () {
      final lbs = BmiCalculatorService.kgToLbs(70);
      final kg = BmiCalculatorService.lbsToKg(lbs);
      expect(kg, closeTo(70, 0.01));
    });

    test('cm to feet/inches round trip', () {
      final (feet, inches) = BmiCalculatorService.cmToFeetInches(175);
      final cm = BmiCalculatorService.feetInchesToCm(feet, inches);
      expect(cm, closeTo(175, 0.5));
    });

    test('180cm is about 5\'11"', () {
      final (feet, inches) = BmiCalculatorService.cmToFeetInches(180);
      expect(feet, 5);
      expect(inches, closeTo(10.9, 0.1));
    });
  });

  group('BmiCategory enum', () {
    test('all categories have labels and ranges', () {
      for (final cat in BmiCategory.values) {
        expect(cat.label, isNotEmpty);
        expect(cat.range, isNotEmpty);
        expect(cat.colorValue, isPositive);
      }
    });
  });

  group('BmiRecord', () {
    test('toJson serializes correctly', () {
      final record = BmiRecord(
        date: DateTime(2026, 4, 20),
        weightKg: 70,
        heightCm: 175,
        bmi: 22.86,
        category: BmiCategory.normal,
      );
      final json = record.toJson();
      expect(json['weightKg'], 70);
      expect(json['heightCm'], 175);
      expect(json['bmi'], 22.86);
      expect(json['category'], 'Normal');
      expect(json['date'], contains('2026-04-20'));
    });
  });
}
