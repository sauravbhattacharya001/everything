import 'package:everything/core/services/mortgage_calculator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const svc = MortgageCalculatorService();

  group('MortgageCalculatorService.calculate', () {
    test('30-year fixed at 6.5% produces correct monthly payment', () {
      final result = svc.calculate(
        principal: 300000,
        annualRatePercent: 6.5,
        termYears: 30,
      );
      // Known value: ~$1896.20/month
      expect(result.monthlyPayment, closeTo(1896.20, 0.50));
      expect(result.loanAmount, 300000);
      expect(result.annualRate, 6.5);
      expect(result.termYears, 30);
    });

    test('schedule has 360 rows for 30-year mortgage', () {
      final result = svc.calculate(
        principal: 200000,
        annualRatePercent: 5.0,
        termYears: 30,
      );
      expect(result.schedule.length, 360);
      expect(result.schedule.first.month, 1);
      expect(result.schedule.last.month, 360);
    });

    test('final balance is zero', () {
      final result = svc.calculate(
        principal: 100000,
        annualRatePercent: 4.0,
        termYears: 15,
      );
      expect(result.schedule.last.balance, closeTo(0, 0.01));
    });

    test('total payment equals principal + total interest', () {
      final result = svc.calculate(
        principal: 250000,
        annualRatePercent: 7.0,
        termYears: 30,
      );
      expect(result.totalPayment, closeTo(result.loanAmount + result.totalInterest, 0.01));
    });

    test('zero interest rate divides evenly', () {
      final result = svc.calculate(
        principal: 120000,
        annualRatePercent: 0,
        termYears: 10,
      );
      expect(result.monthlyPayment, closeTo(1000, 0.01));
      expect(result.totalInterest, closeTo(0, 0.01));
      expect(result.schedule.length, 120);
    });

    test('extra monthly payment shortens the loan', () {
      final noExtra = svc.calculate(
        principal: 200000,
        annualRatePercent: 5.0,
        termYears: 30,
      );
      final withExtra = svc.calculate(
        principal: 200000,
        annualRatePercent: 5.0,
        termYears: 30,
        extraMonthlyPayment: 500,
      );
      expect(withExtra.schedule.length, lessThan(noExtra.schedule.length));
      expect(withExtra.totalInterest, lessThan(noExtra.totalInterest));
    });

    test('extra payment reduces total interest paid', () {
      final result = svc.calculate(
        principal: 300000,
        annualRatePercent: 6.0,
        termYears: 30,
        extraMonthlyPayment: 200,
      );
      final baseline = svc.calculate(
        principal: 300000,
        annualRatePercent: 6.0,
        termYears: 30,
      );
      expect(result.totalInterest, lessThan(baseline.totalInterest));
    });

    test('schedule interest decreases over time', () {
      final result = svc.calculate(
        principal: 250000,
        annualRatePercent: 5.5,
        termYears: 30,
      );
      expect(result.schedule.first.interest,
          greaterThan(result.schedule.last.interest));
    });

    test('schedule principal increases over time', () {
      final result = svc.calculate(
        principal: 250000,
        annualRatePercent: 5.5,
        termYears: 30,
      );
      expect(result.schedule.last.principal,
          greaterThan(result.schedule.first.principal));
    });

    test('15-year mortgage has higher payment but less total interest', () {
      final thirty = svc.calculate(
        principal: 200000,
        annualRatePercent: 5.0,
        termYears: 30,
      );
      final fifteen = svc.calculate(
        principal: 200000,
        annualRatePercent: 5.0,
        termYears: 15,
      );
      expect(fifteen.monthlyPayment, greaterThan(thirty.monthlyPayment));
      expect(fifteen.totalInterest, lessThan(thirty.totalInterest));
    });
  });

  group('MortgageCalculatorService.maxLoanAmount', () {
    test('calculates affordable loan for given budget', () {
      final maxLoan = svc.maxLoanAmount(
        monthlyBudget: 2000,
        annualRatePercent: 5.0,
        termYears: 30,
      );
      // Verify by computing payment on that loan
      final result = svc.calculate(
        principal: maxLoan,
        annualRatePercent: 5.0,
        termYears: 30,
      );
      expect(result.monthlyPayment, closeTo(2000, 1.0));
    });

    test('zero rate returns budget * months', () {
      final maxLoan = svc.maxLoanAmount(
        monthlyBudget: 1500,
        annualRatePercent: 0,
        termYears: 20,
      );
      expect(maxLoan, closeTo(1500 * 240, 0.01));
    });

    test('higher rate means smaller affordable loan', () {
      final low = svc.maxLoanAmount(
        monthlyBudget: 2000,
        annualRatePercent: 3.0,
        termYears: 30,
      );
      final high = svc.maxLoanAmount(
        monthlyBudget: 2000,
        annualRatePercent: 7.0,
        termYears: 30,
      );
      expect(low, greaterThan(high));
    });
  });
}
