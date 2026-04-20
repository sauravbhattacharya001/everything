import 'package:everything/core/services/tip_calculator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TipCalculatorService.calculate', () {
    test('basic 20% tip on \$100 bill', () {
      final result = TipCalculatorService.calculate(
        billAmount: 100,
        tipPercent: 20,
        splitCount: 1,
      );
      expect(result.tipAmount, closeTo(20, 0.01));
      expect(result.total, closeTo(120, 0.01));
      expect(result.perPerson, closeTo(120, 0.01));
      expect(result.tipPerPerson, closeTo(20, 0.01));
    });

    test('split between 4 people', () {
      final result = TipCalculatorService.calculate(
        billAmount: 200,
        tipPercent: 15,
        splitCount: 4,
      );
      expect(result.tipAmount, closeTo(30, 0.01));
      expect(result.total, closeTo(230, 0.01));
      expect(result.perPerson, closeTo(57.50, 0.01));
      expect(result.tipPerPerson, closeTo(7.50, 0.01));
    });

    test('round up rounds total to next whole dollar', () {
      final result = TipCalculatorService.calculate(
        billAmount: 47.83,
        tipPercent: 18,
        splitCount: 1,
        roundUp: true,
      );
      // 47.83 * 1.18 = 56.4394 → ceil = 57
      expect(result.total, closeTo(57, 0.01));
    });

    test('zero tip returns bill amount', () {
      final result = TipCalculatorService.calculate(
        billAmount: 50,
        tipPercent: 0,
        splitCount: 1,
      );
      expect(result.tipAmount, closeTo(0, 0.01));
      expect(result.total, closeTo(50, 0.01));
    });

    test('zero bill amount', () {
      final result = TipCalculatorService.calculate(
        billAmount: 0,
        tipPercent: 20,
        splitCount: 1,
      );
      expect(result.tipAmount, closeTo(0, 0.01));
      expect(result.total, closeTo(0, 0.01));
    });

    test('split count of 1 returns same as total', () {
      final result = TipCalculatorService.calculate(
        billAmount: 80,
        tipPercent: 25,
        splitCount: 1,
      );
      expect(result.perPerson, result.total);
      expect(result.tipPerPerson, result.tipAmount);
    });

    test('preserves original bill amount and tip percent', () {
      final result = TipCalculatorService.calculate(
        billAmount: 123.45,
        tipPercent: 18,
        splitCount: 3,
      );
      expect(result.billAmount, 123.45);
      expect(result.tipPercent, 18);
      expect(result.splitCount, 3);
    });
  });

  group('TipCalculatorService.suggestRoundTip', () {
    test('suggests a positive tip', () {
      final tip = TipCalculatorService.suggestRoundTip(47.83);
      expect(tip, greaterThan(0));
    });

    test('suggested tip makes total a round number', () {
      final bill = 47.83;
      final tip = TipCalculatorService.suggestRoundTip(bill);
      final total = bill + tip;
      expect(total % 1.0, closeTo(0, 0.01));
    });

    test('works on already round bill', () {
      final tip = TipCalculatorService.suggestRoundTip(50.0);
      expect(tip, greaterThan(0));
    });
  });

  group('TipCalculatorService constants', () {
    test('preset percentages are in ascending order', () {
      for (int i = 1; i < TipCalculatorService.presetPercentages.length; i++) {
        expect(TipCalculatorService.presetPercentages[i],
            greaterThan(TipCalculatorService.presetPercentages[i - 1]));
      }
    });

    test('service ratings map has standard entries', () {
      expect(TipCalculatorService.serviceRatings.containsKey('Poor'), isTrue);
      expect(TipCalculatorService.serviceRatings.containsKey('Excellent'), isTrue);
      expect(TipCalculatorService.serviceRatings['Poor']!,
          lessThan(TipCalculatorService.serviceRatings['Excellent']!));
    });
  });
}
