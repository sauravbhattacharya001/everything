import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/compound_interest_service.dart';

void main() {
  group('CompoundInterestService', () {
    const service = CompoundInterestService();

    // ── calculate ──

    group('calculate', () {
      test('returns starting point at year 0 with principal only', () {
        final points = service.calculate(
          principal: 10000,
          annualRate: 5,
          years: 1,
        );
        expect(points.first.year, 0);
        expect(points.first.balance, 10000);
        expect(points.first.totalContributed, 10000);
        expect(points.first.totalInterest, 0);
      });

      test('generates correct number of projection points', () {
        final points = service.calculate(
          principal: 1000,
          annualRate: 10,
          years: 5,
        );
        // year 0 through year 5 = 6 points
        expect(points.length, 6);
        expect(points.first.year, 0);
        expect(points.last.year, 5);
      });

      test('compound monthly produces expected growth for 1 year at 12%', () {
        // $1000 at 12% compounded monthly for 1 year
        // Formula: 1000 * (1 + 0.12/12)^12 = 1000 * 1.01^12 ≈ 1126.83
        final points = service.calculate(
          principal: 1000,
          annualRate: 12,
          years: 1,
          compoundFrequency: CompoundFrequency.monthly,
        );
        expect(points.last.balance, closeTo(1126.83, 0.01));
      });

      test('compound annually produces correct result', () {
        // $5000 at 8% compounded annually for 3 years
        // Year 1: 5400, Year 2: 5832, Year 3: 6298.56
        final points = service.calculate(
          principal: 5000,
          annualRate: 8,
          years: 3,
          compoundFrequency: CompoundFrequency.annually,
        );
        expect(points[1].balance, closeTo(5400, 0.01));
        expect(points[2].balance, closeTo(5832, 0.01));
        expect(points[3].balance, closeTo(6298.56, 0.01));
      });

      test('monthly contributions add correctly', () {
        // $0 principal, $100/month contribution, 0% rate, 1 year
        // After 1 year: 100 * 12 = $1200
        final points = service.calculate(
          principal: 0,
          annualRate: 0,
          years: 1,
          monthlyContribution: 100,
          compoundFrequency: CompoundFrequency.monthly,
        );
        expect(points.last.balance, closeTo(1200, 0.01));
        expect(points.last.totalContributed, closeTo(1200, 0.01));
        expect(points.last.totalInterest, closeTo(0, 0.01));
      });

      test('totalInterest equals balance minus totalContributed', () {
        final points = service.calculate(
          principal: 5000,
          annualRate: 7,
          years: 10,
          monthlyContribution: 200,
        );
        for (final p in points) {
          expect(p.totalInterest, closeTo(p.balance - p.totalContributed, 0.01));
        }
      });

      test('zero rate with contributions grows linearly', () {
        final points = service.calculate(
          principal: 1000,
          annualRate: 0,
          years: 5,
          monthlyContribution: 50,
        );
        // Each year adds 50*12 = 600
        expect(points[1].balance, closeTo(1600, 0.01));
        expect(points[2].balance, closeTo(2200, 0.01));
        expect(points[5].balance, closeTo(4000, 0.01));
      });

      test('quarterly compounding differs from monthly', () {
        final monthly = service.calculate(
          principal: 10000,
          annualRate: 6,
          years: 5,
          compoundFrequency: CompoundFrequency.monthly,
        );
        final quarterly = service.calculate(
          principal: 10000,
          annualRate: 6,
          years: 5,
          compoundFrequency: CompoundFrequency.quarterly,
        );
        // More frequent compounding = slightly higher balance
        expect(monthly.last.balance, greaterThan(quarterly.last.balance));
      });

      test('daily compounding exceeds monthly compounding', () {
        final daily = service.calculate(
          principal: 10000,
          annualRate: 10,
          years: 10,
          compoundFrequency: CompoundFrequency.daily,
        );
        final monthly = service.calculate(
          principal: 10000,
          annualRate: 10,
          years: 10,
          compoundFrequency: CompoundFrequency.monthly,
        );
        expect(daily.last.balance, greaterThan(monthly.last.balance));
      });
    });

    // ── finalBalance ──

    group('finalBalance', () {
      test('returns last projection point balance', () {
        final balance = service.finalBalance(
          principal: 1000,
          annualRate: 5,
          years: 10,
        );
        final points = service.calculate(
          principal: 1000,
          annualRate: 5,
          years: 10,
        );
        expect(balance, points.last.balance);
      });

      test('zero principal and zero contribution returns zero', () {
        final balance = service.finalBalance(
          principal: 0,
          annualRate: 10,
          years: 5,
        );
        expect(balance, 0);
      });
    });

    // ── yearsToReach ──

    group('yearsToReach', () {
      test('returns 0 when principal already meets target', () {
        final years = service.yearsToReach(
          principal: 10000,
          annualRate: 5,
          target: 5000,
        );
        expect(years, 0);
      });

      test('returns 0 when principal equals target', () {
        final years = service.yearsToReach(
          principal: 5000,
          annualRate: 5,
          target: 5000,
        );
        expect(years, 0);
      });

      test('returns maxYears when impossible (zero rate, zero contribution)', () {
        final years = service.yearsToReach(
          principal: 1000,
          annualRate: 0,
          target: 2000,
          maxYears: 50,
        );
        expect(years, 50);
      });

      test('correctly estimates years to double at 7% annual', () {
        // Rule of 72: ~10.3 years to double at 7%
        final years = service.yearsToReach(
          principal: 1000,
          annualRate: 7,
          target: 2000,
          compoundFrequency: CompoundFrequency.annually,
        );
        expect(years, inInclusiveRange(10, 11));
      });

      test('contributions help reach target faster', () {
        final withoutContrib = service.yearsToReach(
          principal: 1000,
          annualRate: 5,
          target: 10000,
        );
        final withContrib = service.yearsToReach(
          principal: 1000,
          annualRate: 5,
          target: 10000,
          monthlyContribution: 100,
        );
        expect(withContrib, lessThan(withoutContrib));
      });
    });

    // ── ruleOf72 ──

    group('ruleOf72', () {
      test('returns 72 divided by rate', () {
        expect(service.ruleOf72(6), 12.0);
        expect(service.ruleOf72(8), 9.0);
        expect(service.ruleOf72(12), 6.0);
        expect(service.ruleOf72(1), 72.0);
      });

      test('returns infinity for zero rate', () {
        expect(service.ruleOf72(0), double.infinity);
      });

      test('returns infinity for negative rate', () {
        expect(service.ruleOf72(-5), double.infinity);
      });
    });
  });

  // ── CompoundFrequency enum ──

  group('CompoundFrequency', () {
    test('annually has 1 period per year', () {
      expect(CompoundFrequency.annually.periodsPerYear, 1);
    });

    test('semiAnnually has 2 periods per year', () {
      expect(CompoundFrequency.semiAnnually.periodsPerYear, 2);
    });

    test('quarterly has 4 periods per year', () {
      expect(CompoundFrequency.quarterly.periodsPerYear, 4);
    });

    test('monthly has 12 periods per year', () {
      expect(CompoundFrequency.monthly.periodsPerYear, 12);
    });

    test('daily has 365 periods per year', () {
      expect(CompoundFrequency.daily.periodsPerYear, 365);
    });

    test('all frequencies have a non-empty label', () {
      for (final freq in CompoundFrequency.values) {
        expect(freq.label.isNotEmpty, isTrue);
      }
    });
  });
}
