import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/runway_engine_service.dart';

void main() {
  late RunwayEngineService service;

  setUp(() {
    service = RunwayEngineService();
  });

  group('RunwayEngineService — Basics', () {
    test('starts empty', () {
      expect(service.assets, isEmpty);
      expect(service.expenses, isEmpty);
      expect(service.history, isEmpty);
      expect(service.totalGrossAssets, 0);
      expect(service.totalLiquidAssets, 0);
      expect(service.monthlyBurnRate, 0);
    });

    test('add/remove/update assets', () {
      final asset = RunwayAsset(
        id: 'a1', name: 'Checking', category: AssetCategory.checking,
        balance: 5000, lastUpdated: DateTime.now(),
      );
      service.addAsset(asset);
      expect(service.assets.length, 1);
      expect(service.totalGrossAssets, 5000);

      service.updateAsset(RunwayAsset(
        id: 'a1', name: 'Checking', category: AssetCategory.checking,
        balance: 7000, lastUpdated: DateTime.now(),
      ));
      expect(service.totalGrossAssets, 7000);

      service.removeAsset('a1');
      expect(service.assets, isEmpty);
    });

    test('add/remove/update expenses', () {
      final expense = RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      );
      service.addExpense(expense);
      expect(service.expenses.length, 1);
      expect(service.monthlyBurnRate, 2000);

      service.updateExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2200,
      ));
      expect(service.monthlyBurnRate, 2200);

      service.removeExpense('e1');
      expect(service.expenses, isEmpty);
    });
  });

  group('Engine 1: Runway Calculator', () {
    test('computes runway correctly', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Savings', category: AssetCategory.savings,
        balance: 10000, lastUpdated: DateTime.now(),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      ));
      // Savings liquidity = 0.95, so liquid = 9500
      expect(service.totalLiquidAssets, 9500);
      expect(service.runwayMonthsFull, closeTo(4.75, 0.01));
    });

    test('infinite runway with no expenses', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 1000, lastUpdated: DateTime.now(),
      ));
      expect(service.runwayMonthsFull, double.infinity);
    });

    test('essential vs discretionary burn', () {
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      ));
      service.addExpense(RunwayExpense(
        id: 'e2', name: 'Netflix', category: ExpenseCategory.entertainment,
        monthlyAmount: 15,
      ));
      expect(service.essentialBurnRate, 2000);
      expect(service.discretionaryBurnRate, 15);
    });

    test('austerity runway is longer than full runway', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 10000, lastUpdated: DateTime.now(),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 1500,
      ));
      service.addExpense(RunwayExpense(
        id: 'e2', name: 'Fun', category: ExpenseCategory.entertainment,
        monthlyAmount: 500,
      ));
      expect(service.runwayMonthsEssentialOnly,
          greaterThan(service.runwayMonthsFull));
    });
  });

  group('Engine 2: Burn Rate Analyzer', () {
    test('breaks down by category sorted by amount', () {
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      ));
      service.addExpense(RunwayExpense(
        id: 'e2', name: 'Food', category: ExpenseCategory.food,
        monthlyAmount: 500,
      ));
      service.addExpense(RunwayExpense(
        id: 'e3', name: 'Netflix', category: ExpenseCategory.entertainment,
        monthlyAmount: 15,
      ));

      final breakdown = service.analyzeBurnRate();
      expect(breakdown.length, 3);
      expect(breakdown.first.category, ExpenseCategory.housing);
      expect(breakdown.first.amount, 2000);
      expect(breakdown.first.isEssential, true);
      expect(breakdown.last.isEssential, false);

      // Percentages add up to 100
      final totalPct = breakdown.fold(0.0, (s, b) => s + b.percentage);
      expect(totalPct, closeTo(100.0, 0.1));
    });

    test('empty expenses returns empty breakdown', () {
      expect(service.analyzeBurnRate(), isEmpty);
    });

    test('merges same-category expenses', () {
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Groceries', category: ExpenseCategory.food,
        monthlyAmount: 400,
      ));
      service.addExpense(RunwayExpense(
        id: 'e2', name: 'Dining', category: ExpenseCategory.food,
        monthlyAmount: 200,
      ));

      final breakdown = service.analyzeBurnRate();
      expect(breakdown.length, 1);
      expect(breakdown.first.amount, 600);
    });
  });

  group('Engine 3: Scenario Simulator', () {
    setUp(() {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 20000, lastUpdated: DateTime.now(),
      ));
      service.addAsset(RunwayAsset(
        id: 'a2', name: 'Stocks', category: AssetCategory.investment,
        balance: 30000, lastUpdated: DateTime.now(),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      ));
      service.addExpense(RunwayExpense(
        id: 'e2', name: 'Food', category: ExpenseCategory.food,
        monthlyAmount: 500,
      ));
      service.addExpense(RunwayExpense(
        id: 'e3', name: 'Fun', category: ExpenseCategory.entertainment,
        monthlyAmount: 300,
      ));
    });

    test('generates 6 scenarios', () {
      final scenarios = service.runScenarios();
      expect(scenarios.length, 6);
    });

    test('job loss extends runway (austerity mode)', () {
      final scenarios = service.runScenarios();
      final jobLoss = scenarios.firstWhere((s) => s.type == ScenarioType.jobLoss);
      // Job loss cuts discretionary, so burn rate drops
      expect(jobLoss.adjustedBurnRate, lessThan(service.monthlyBurnRate));
    });

    test('market crash reduces liquid assets', () {
      final scenarios = service.runScenarios();
      final crash = scenarios.firstWhere((s) => s.type == ScenarioType.marketCrash);
      expect(crash.adjustedLiquidAssets, lessThan(service.totalLiquidAssets));
      expect(crash.portfolioHaircut, greaterThan(0));
    });

    test('medical emergency has higher burn rate', () {
      final scenarios = service.runScenarios();
      final medical = scenarios.firstWhere((s) => s.type == ScenarioType.medicalEmergency);
      expect(medical.adjustedBurnRate, greaterThan(service.monthlyBurnRate));
    });

    test('sabbatical uses full burn rate', () {
      final scenarios = service.runScenarios();
      final sabbatical = scenarios.firstWhere((s) => s.type == ScenarioType.sabbatical);
      expect(sabbatical.adjustedBurnRate, service.monthlyBurnRate);
    });

    test('no scenarios without expenses', () {
      final emptyService = RunwayEngineService();
      emptyService.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 10000, lastUpdated: DateTime.now(),
      ));
      expect(emptyService.runScenarios(), isEmpty);
    });

    test('each scenario has recommendations', () {
      final scenarios = service.runScenarios();
      for (final s in scenarios) {
        expect(s.recommendations, isNotEmpty);
      }
    });
  });

  group('Engine 4: Resilience Scorer', () {
    test('empty service scores 0', () {
      expect(service.computeResilienceScore(), 0);
    });

    test('well-funded service scores high', () {
      for (final cat in [
        AssetCategory.checking,
        AssetCategory.savings,
        AssetCategory.emergencyFund,
        AssetCategory.investment,
      ]) {
        service.addAsset(RunwayAsset(
          id: cat.name, name: cat.label, category: cat,
          balance: 50000, lastUpdated: DateTime.now(),
        ));
      }
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      ));
      final score = service.computeResilienceScore();
      expect(score, greaterThan(60));
    });

    test('poorly funded service scores low', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Checking', category: AssetCategory.checking,
        balance: 500, lastUpdated: DateTime.now(),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 3000,
      ));
      final score = service.computeResilienceScore();
      expect(score, lessThan(40));
    });

    test('tiers assigned correctly', () {
      expect(service.computeTier(90), ResilienceTier.antifragile);
      expect(service.computeTier(75), ResilienceTier.resilient);
      expect(service.computeTier(55), ResilienceTier.stable);
      expect(service.computeTier(35), ResilienceTier.vulnerable);
      expect(service.computeTier(15), ResilienceTier.fragile);
    });

    test('score is between 0 and 100', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 1000, lastUpdated: DateTime.now(),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 1500,
      ));
      final score = service.computeResilienceScore();
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));
    });
  });

  group('Engine 5: Alert Generator', () {
    test('critical alert when runway < 3 months', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 2000, lastUpdated: DateTime.now(),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      ));
      final alerts = service.generateAlerts();
      expect(alerts.any((a) => a.severity == AlertSeverity.critical), true);
    });

    test('warning alert when runway < 6 months', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 10000, lastUpdated: DateTime.now(),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      ));
      final alerts = service.generateAlerts();
      expect(alerts.any((a) => a.severity == AlertSeverity.warning), true);
    });

    test('no runway alert when sufficiently funded', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 50000, lastUpdated: DateTime.now(),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      ));
      final alerts = service.generateAlerts();
      expect(alerts.any((a) => a.title == 'Critical Runway'), false);
      expect(alerts.any((a) => a.title == 'Low Runway'), false);
    });

    test('concentration alert for dominant category', () {
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 3000,
      ));
      service.addExpense(RunwayExpense(
        id: 'e2', name: 'Food', category: ExpenseCategory.food,
        monthlyAmount: 200,
      ));
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 100000, lastUpdated: DateTime.now(),
      ));
      final alerts = service.generateAlerts();
      expect(alerts.any((a) => a.title == 'Expense Concentration'), true);
    });

    test('stale balance alert', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Old Account', category: AssetCategory.savings,
        balance: 5000,
        lastUpdated: DateTime.now().subtract(const Duration(days: 60)),
      ));
      final alerts = service.generateAlerts();
      expect(alerts.any((a) => a.title == 'Stale Balances'), true);
    });

    test('declining trend alert', () {
      final now = DateTime.now();
      for (int i = 5; i >= 0; i--) {
        service.addSnapshot(RunwaySnapshot(
          date: now.subtract(Duration(days: 30 * i)),
          runwayMonths: 12.0 - i * 2.0, // Declining from 2 to 12
          burnRate: 3000,
          liquidAssets: 30000,
          resilienceScore: 50,
        ));
      }
      // Actually the data above goes from 2 months (5 months ago) to 12 months (now)
      // That's increasing. Let me reverse it:
      // We want declining: high in past, low now
      final service2 = RunwayEngineService();
      for (int i = 5; i >= 0; i--) {
        service2.addSnapshot(RunwaySnapshot(
          date: now.subtract(Duration(days: 30 * i)),
          runwayMonths: 2.0 + i * 2.0, // 12 -> 2 (declining)
          burnRate: 3000,
          liquidAssets: 30000,
          resilienceScore: 50,
        ));
      }
      service2.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 6000, lastUpdated: now,
      ));
      service2.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 3000,
      ));
      final alerts = service2.generateAlerts();
      expect(alerts.any((a) => a.title == 'Declining Runway'), true);
    });
  });

  group('Engine 6: Recommendation Engine', () {
    test('recommends cutting discretionary expenses', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 10000, lastUpdated: DateTime.now(),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      ));
      service.addExpense(RunwayExpense(
        id: 'e2', name: 'Entertainment', category: ExpenseCategory.entertainment,
        monthlyAmount: 500,
      ));
      final recs = service.generateRecommendations();
      expect(recs.any((r) => r.title.contains('Entertainment')), true);
    });

    test('recommends asset diversification', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Checking', category: AssetCategory.checking,
        balance: 50000, lastUpdated: DateTime.now(),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      ));
      final recs = service.generateRecommendations();
      expect(recs.any((r) => r.title.contains('Diversify')), true);
    });

    test('recommends building emergency fund', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Checking', category: AssetCategory.checking,
        balance: 5000, lastUpdated: DateTime.now(),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      ));
      final recs = service.generateRecommendations();
      expect(recs.any((r) => r.title.contains('Emergency Fund')), true);
    });

    test('sorted by priority then extension', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 10000, lastUpdated: DateTime.now(),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 1500,
      ));
      service.addExpense(RunwayExpense(
        id: 'e2', name: 'Entertainment', category: ExpenseCategory.entertainment,
        monthlyAmount: 300,
      ));
      service.addExpense(RunwayExpense(
        id: 'e3', name: 'Subs', category: ExpenseCategory.subscriptions,
        monthlyAmount: 100,
      ));
      final recs = service.generateRecommendations();
      if (recs.length >= 2) {
        final priorityOrder = {'high': 0, 'medium': 1, 'low': 2};
        for (int i = 0; i < recs.length - 1; i++) {
          final p1 = priorityOrder[recs[i].priority] ?? 2;
          final p2 = priorityOrder[recs[i + 1].priority] ?? 2;
          expect(p1, lessThanOrEqualTo(p2));
        }
      }
    });

    test('no recommendations without expenses', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 10000, lastUpdated: DateTime.now(),
      ));
      expect(service.generateRecommendations(), isEmpty);
    });
  });

  group('Engine 7: Trend Tracker', () {
    test('no trend with < 2 snapshots', () {
      final analysis = service.analyze();
      // Only 1 snapshot (the one taken during analyze)
      expect(analysis.runwayTrendPerMonth, isNull);
    });

    test('detects positive trend', () {
      final now = DateTime.now();
      for (int i = 4; i >= 0; i--) {
        service.addSnapshot(RunwaySnapshot(
          date: now.subtract(Duration(days: 30 * i)),
          runwayMonths: 6.0 + (4 - i) * 1.0, // 6, 7, 8, 9, 10
          burnRate: 3000,
          liquidAssets: 30000,
          resilienceScore: 50,
        ));
      }
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 30000, lastUpdated: now,
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 3000,
      ));
      final analysis = service.analyze();
      expect(analysis.runwayTrendPerMonth, isNotNull);
      expect(analysis.runwayTrendPerMonth!, greaterThan(0));
    });

    test('detects negative trend', () {
      final now = DateTime.now();
      for (int i = 4; i >= 0; i--) {
        service.addSnapshot(RunwaySnapshot(
          date: now.subtract(Duration(days: 30 * i)),
          runwayMonths: 12.0 - (4 - i) * 2.0, // 12, 10, 8, 6, 4
          burnRate: 3000,
          liquidAssets: 30000,
          resilienceScore: 50,
        ));
      }
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 12000, lastUpdated: now,
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 3000,
      ));
      final analysis = service.analyze();
      expect(analysis.runwayTrendPerMonth, isNotNull);
      expect(analysis.runwayTrendPerMonth!, lessThan(0));
    });
  });

  group('Full Analysis', () {
    test('produces complete analysis', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Cash', category: AssetCategory.cash,
        balance: 20000, lastUpdated: DateTime.now(),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      ));
      service.addExpense(RunwayExpense(
        id: 'e2', name: 'Fun', category: ExpenseCategory.entertainment,
        monthlyAmount: 200,
      ));

      final analysis = service.analyze();
      expect(analysis.totalLiquidAssets, 20000);
      expect(analysis.monthlyBurnRate, 2200);
      expect(analysis.runwayMonthsFull, closeTo(9.09, 0.1));
      expect(analysis.resilienceScore, greaterThan(0));
      expect(analysis.tier, isNotNull);
      expect(analysis.burnBreakdown, isNotEmpty);
      expect(analysis.scenarios, isNotEmpty);
      expect(analysis.analyzedAt, isNotNull);
    });
  });

  group('Persistence', () {
    test('round-trips through JSON', () {
      service.addAsset(RunwayAsset(
        id: 'a1', name: 'Savings', category: AssetCategory.savings,
        balance: 15000, lastUpdated: DateTime(2025, 1, 1),
      ));
      service.addExpense(RunwayExpense(
        id: 'e1', name: 'Rent', category: ExpenseCategory.housing,
        monthlyAmount: 2000,
      ));
      service.addSnapshot(RunwaySnapshot(
        date: DateTime(2025, 1, 1),
        runwayMonths: 7.0,
        burnRate: 2000,
        liquidAssets: 14250,
        resilienceScore: 45,
      ));

      final json = service.toJson();
      final restored = RunwayEngineService.fromJson(json);

      expect(restored.assets.length, 1);
      expect(restored.expenses.length, 1);
      expect(restored.history.length, 1);
      expect(restored.totalGrossAssets, 15000);
      expect(restored.monthlyBurnRate, 2000);
      expect(restored.criticalRunwayMonths, 3.0);
    });

    test('preserves custom thresholds', () {
      service.criticalRunwayMonths = 2.0;
      service.warningRunwayMonths = 4.0;
      service.targetRunwayMonths = 18.0;

      final json = service.toJson();
      final restored = RunwayEngineService.fromJson(json);

      expect(restored.criticalRunwayMonths, 2.0);
      expect(restored.warningRunwayMonths, 4.0);
      expect(restored.targetRunwayMonths, 18.0);
    });
  });

  group('Asset liquidity', () {
    test('checking has full liquidity', () {
      expect(AssetCategory.checking.liquidity, 1.0);
    });

    test('investment has reduced liquidity', () {
      expect(AssetCategory.investment.liquidity, lessThan(1.0));
    });

    test('crypto has lowest non-other liquidity', () {
      expect(AssetCategory.crypto.liquidity, lessThan(AssetCategory.investment.liquidity));
    });

    test('liquid value reflects liquidity factor', () {
      final asset = RunwayAsset(
        id: 'a1', name: 'Stocks', category: AssetCategory.investment,
        balance: 10000, lastUpdated: DateTime.now(),
      );
      expect(asset.liquidValue, 7000); // 10000 * 0.7
    });
  });

  group('Expense categories', () {
    test('housing is essential', () {
      expect(ExpenseCategory.housing.isEssential, true);
    });

    test('entertainment is not essential', () {
      expect(ExpenseCategory.entertainment.isEssential, false);
    });

    test('subscriptions are not essential', () {
      expect(ExpenseCategory.subscriptions.isEssential, false);
    });
  });

  group('Enums', () {
    test('all AssetCategory values have labels and emojis', () {
      for (final cat in AssetCategory.values) {
        expect(cat.label, isNotEmpty);
        expect(cat.emoji, isNotEmpty);
        expect(cat.liquidity, greaterThan(0));
        expect(cat.liquidity, lessThanOrEqualTo(1.0));
      }
    });

    test('all ExpenseCategory values have labels and emojis', () {
      for (final cat in ExpenseCategory.values) {
        expect(cat.label, isNotEmpty);
        expect(cat.emoji, isNotEmpty);
      }
    });

    test('all ScenarioType values have labels', () {
      for (final s in ScenarioType.values) {
        expect(s.label, isNotEmpty);
        expect(s.emoji, isNotEmpty);
        expect(s.description, isNotEmpty);
      }
    });

    test('all ResilienceTier values have labels', () {
      for (final t in ResilienceTier.values) {
        expect(t.label, isNotEmpty);
        expect(t.emoji, isNotEmpty);
      }
    });

    test('all AlertSeverity values have labels', () {
      for (final s in AlertSeverity.values) {
        expect(s.label, isNotEmpty);
        expect(s.emoji, isNotEmpty);
      }
    });
  });
}
