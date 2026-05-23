import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/compound_interest_service.dart';

void main() {
  const svc = CompoundInterestService();

  group('CompoundInterestService.calculate', () {
    test('emits year 0 baseline + one point per year', () {
      final pts = svc.calculate(
        principal: 1000,
        annualRate: 5,
        years: 3,
      );
      expect(pts.length, 4);
      expect(pts.first.year, 0);
      expect(pts.first.balance, closeTo(1000, 1e-9));
      expect(pts.first.totalContributed, closeTo(1000, 1e-9));
      expect(pts.first.totalInterest, 0);
      expect(pts.last.year, 3);
    });

    test('zero years still returns the baseline-only series', () {
      final pts = svc.calculate(
        principal: 500,
        annualRate: 7,
        years: 0,
      );
      expect(pts.length, 1);
      expect(pts.single.year, 0);
      expect(pts.single.balance, closeTo(500, 1e-9));
    });

    test('annual compounding matches A = P(1+r)^t closed form', () {
      // 1000 at 10% for 5 years annually compounded = 1610.51
      final balance = svc
          .calculate(
            principal: 1000,
            annualRate: 10,
            years: 5,
            compoundFrequency: CompoundFrequency.annually,
          )
          .last
          .balance;
      expect(balance, closeTo(1610.51, 0.01));
    });

    test('monthly compounding produces more than annual for same rate', () {
      final annual = svc.finalBalance(
        principal: 1000,
        annualRate: 10,
        years: 10,
        compoundFrequency: CompoundFrequency.annually,
      );
      final monthly = svc.finalBalance(
        principal: 1000,
        annualRate: 10,
        years: 10,
        compoundFrequency: CompoundFrequency.monthly,
      );
      expect(monthly, greaterThan(annual));
    });

    test('zero rate with no contributions preserves principal exactly', () {
      final pts = svc.calculate(
        principal: 2500,
        annualRate: 0,
        years: 7,
      );
      for (final p in pts) {
        expect(p.balance, closeTo(2500, 1e-9));
        expect(p.totalInterest, closeTo(0, 1e-9));
        expect(p.totalContributed, closeTo(2500, 1e-9));
      }
    });

    test('zero rate with monthly contributions equals principal + sum', () {
      final pts = svc.calculate(
        principal: 1000,
        annualRate: 0,
        years: 2,
        monthlyContribution: 100,
      );
      // 1000 + 2 * 12 * 100 = 3400, interest = 0
      expect(pts.last.balance, closeTo(3400, 1e-9));
      expect(pts.last.totalContributed, closeTo(3400, 1e-9));
      expect(pts.last.totalInterest, closeTo(0, 1e-9));
    });

    test('totalContributed grows linearly with monthly contribution', () {
      final pts = svc.calculate(
        principal: 0,
        annualRate: 5,
        years: 3,
        monthlyContribution: 50,
      );
      expect(pts[1].totalContributed, closeTo(600, 1e-9));
      expect(pts[2].totalContributed, closeTo(1200, 1e-9));
      expect(pts[3].totalContributed, closeTo(1800, 1e-9));
    });

    test('totalInterest == balance - totalContributed every year', () {
      final pts = svc.calculate(
        principal: 1500,
        annualRate: 6.5,
        years: 5,
        monthlyContribution: 25,
      );
      for (final p in pts) {
        expect(p.totalInterest,
            closeTo(p.balance - p.totalContributed, 1e-9));
      }
    });

    test('zero principal + zero contributions stays at zero forever', () {
      final pts = svc.calculate(
        principal: 0,
        annualRate: 12,
        years: 4,
      );
      for (final p in pts) {
        expect(p.balance, 0);
      }
    });

    test('balance grows monotonically when rate and contribution non-negative',
        () {
      final pts = svc.calculate(
        principal: 1000,
        annualRate: 4,
        years: 10,
        monthlyContribution: 50,
      );
      for (var i = 1; i < pts.length; i++) {
        expect(pts[i].balance, greaterThanOrEqualTo(pts[i - 1].balance));
      }
    });

    test('finalBalance matches last point of calculate()', () {
      const args = {
        'principal': 1234.0,
        'annualRate': 7.5,
        'years': 8,
        'monthlyContribution': 75.0,
      };
      final pts = svc.calculate(
        principal: args['principal'] as double,
        annualRate: args['annualRate'] as double,
        years: args['years'] as int,
        monthlyContribution: args['monthlyContribution'] as double,
      );
      final fb = svc.finalBalance(
        principal: args['principal'] as double,
        annualRate: args['annualRate'] as double,
        years: args['years'] as int,
        monthlyContribution: args['monthlyContribution'] as double,
      );
      expect(fb, closeTo(pts.last.balance, 1e-9));
    });
  });

  group('CompoundInterestService.yearsToReach', () {
    test('returns 0 when principal already meets target (regression)', () {
      // Pre-fix this returned `maxYears` because the loop never short-circuits
      // on an already-met target.
      expect(
        svc.yearsToReach(
          principal: 10000,
          annualRate: 5,
          target: 10000,
        ),
        0,
      );
      expect(
        svc.yearsToReach(
          principal: 20000,
          annualRate: 5,
          target: 10000,
        ),
        0,
      );
    });

    test('returns maxYears when growth is impossible (zero rate + zero pmt)',
        () {
      // Pre-fix this spent `maxYears * n` iterations spinning. Now it bails
      // immediately.
      expect(
        svc.yearsToReach(
          principal: 100,
          annualRate: 0,
          target: 1000,
          maxYears: 50,
        ),
        50,
      );
    });

    test('reaches target via contributions even when rate is zero', () {
      // 100/mo for 10 years = 12000. Should reach 6000 at year 5.
      expect(
        svc.yearsToReach(
          principal: 0,
          annualRate: 0,
          target: 6000,
          monthlyContribution: 100,
        ),
        5,
      );
    });

    test('doubles via rule of 72 approximately matches yearsToReach', () {
      // 1000 -> 2000 at 8% ~= 9 years (rule of 72: 72/8 = 9)
      final years = svc.yearsToReach(
        principal: 1000,
        annualRate: 8,
        target: 2000,
        compoundFrequency: CompoundFrequency.annually,
      );
      // Annual compounding: 1000 * 1.08^9 = 1999.0 (just under) -> year 10.
      expect(years, anyOf(9, 10));
    });

    test('returns maxYears when horizon is too short to reach target', () {
      final years = svc.yearsToReach(
        principal: 100,
        annualRate: 1,
        target: 1_000_000,
        maxYears: 5,
      );
      expect(years, 5);
    });
  });

  group('CompoundInterestService.ruleOf72', () {
    test('returns 72 / rate for positive rates', () {
      expect(svc.ruleOf72(8), closeTo(9, 1e-9));
      expect(svc.ruleOf72(6), closeTo(12, 1e-9));
      expect(svc.ruleOf72(1), closeTo(72, 1e-9));
    });

    test('returns infinity for zero or negative rates', () {
      expect(svc.ruleOf72(0), double.infinity);
      expect(svc.ruleOf72(-5), double.infinity);
    });
  });

  group('CompoundFrequency enum', () {
    test('exposes correct periodsPerYear for each frequency', () {
      expect(CompoundFrequency.annually.periodsPerYear, 1);
      expect(CompoundFrequency.semiAnnually.periodsPerYear, 2);
      expect(CompoundFrequency.quarterly.periodsPerYear, 4);
      expect(CompoundFrequency.monthly.periodsPerYear, 12);
      expect(CompoundFrequency.daily.periodsPerYear, 365);
    });

    test('carries a non-empty human label per value', () {
      for (final f in CompoundFrequency.values) {
        expect(f.label, isNotEmpty);
      }
    });
  });
}
