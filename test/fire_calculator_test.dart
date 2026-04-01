import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/fire_calculator_service.dart';

void main() {
  const service = FireCalculatorService();

  group('FireCalculatorService', () {
    test('basic FIRE calculation', () {
      final result = service.calculate(
        annualIncome: 100000,
        annualExpenses: 40000,
        currentSavings: 100000,
        expectedReturn: 7,
        strategy: WithdrawalStrategy.standard,
      );

      expect(result.savingsRate, closeTo(60, 0.1));
      expect(result.fireNumber, equals(1000000)); // 40k * 25
      expect(result.achievable, isTrue);
      expect(result.yearsToFire, greaterThan(0));
      expect(result.yearsToFire, lessThan(20));
      expect(result.annualWithdrawal, closeTo(40000, 0.01));
      expect(result.projection, isNotEmpty);
      expect(result.projection.first.year, equals(0));
    });

    test('high savings rate means faster FIRE', () {
      final fast = service.calculate(
        annualIncome: 100000,
        annualExpenses: 20000,
        currentSavings: 100000,
        expectedReturn: 7,
      );
      final slow = service.calculate(
        annualIncome: 100000,
        annualExpenses: 80000,
        currentSavings: 100000,
        expectedReturn: 7,
      );

      expect(fast.yearsToFire, lessThan(slow.yearsToFire));
      expect(fast.savingsRate, greaterThan(slow.savingsRate));
    });

    test('zero income returns not achievable', () {
      final result = service.calculate(
        annualIncome: 0,
        annualExpenses: 40000,
        currentSavings: 0,
      );

      expect(result.achievable, isFalse);
      expect(result.projection, isEmpty);
    });

    test('conservative strategy requires larger FIRE number', () {
      final conservative = service.calculate(
        annualIncome: 100000,
        annualExpenses: 40000,
        currentSavings: 0,
        strategy: WithdrawalStrategy.conservative,
      );
      final aggressive = service.calculate(
        annualIncome: 100000,
        annualExpenses: 40000,
        currentSavings: 0,
        strategy: WithdrawalStrategy.aggressive,
      );

      expect(conservative.fireNumber, greaterThan(aggressive.fireNumber));
      expect(conservative.yearsToFire, greaterThan(aggressive.yearsToFire));
    });

    test('projection grows over time', () {
      final result = service.calculate(
        annualIncome: 80000,
        annualExpenses: 40000,
        currentSavings: 50000,
      );

      for (int i = 1; i < result.projection.length; i++) {
        expect(result.projection[i].portfolioValue,
            greaterThan(result.projection[i - 1].portfolioValue));
      }
    });

    test('savings rate labels', () {
      expect(service.savingsRateLabel(75), equals('Extreme Saver'));
      expect(service.savingsRateLabel(50), equals('Aggressive'));
      expect(service.savingsRateLabel(30), equals('On Track'));
      expect(service.savingsRateLabel(15), equals('Getting Started'));
      expect(service.savingsRateLabel(5), equals('Below Target'));
    });

    test('requiredSavingsRate returns valid rate', () {
      final rate = service.requiredSavingsRate(
        annualIncome: 100000,
        currentSavings: 50000,
        targetYears: 15,
      );

      expect(rate, isNotNull);
      expect(rate!, greaterThan(0));
      expect(rate, lessThan(100));
    });

    test('requiredSavingsRate returns null for impossible target', () {
      final rate = service.requiredSavingsRate(
        annualIncome: 100000,
        currentSavings: 0,
        targetYears: 1,
      );

      expect(rate, isNull);
    });
  });
}
