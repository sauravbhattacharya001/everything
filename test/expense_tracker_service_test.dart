import 'package:test/test.dart';
import '../lib/models/expense_entry.dart';
import '../lib/core/services/expense_tracker_service.dart';

void main() {
  // --- Model Tests ---

  group('ExpenseCategory', () {
    test('all categories have labels', () {
      for (final cat in ExpenseCategory.values) {
        expect(cat.label, isNotEmpty);
      }
    });

    test('all categories have emojis', () {
      for (final cat in ExpenseCategory.values) {
        expect(cat.emoji, isNotEmpty);
      }
    });

    test('only income category isIncome', () {
      expect(ExpenseCategory.income.isIncome, isTrue);
      for (final cat in ExpenseCategory.values) {
        if (cat != ExpenseCategory.income) {
          expect(cat.isIncome, isFalse);
        }
      }
    });
  });

  group('PaymentMethod', () {
    test('all methods have labels', () {
      for (final pm in PaymentMethod.values) {
        expect(pm.label, isNotEmpty);
      }
    });
  });

  group('ExpenseEntry', () {
    final entry = ExpenseEntry(
      id: 'e1',
      timestamp: DateTime(2026, 3, 4, 12, 0),
      amount: 25.50,
      category: ExpenseCategory.food,
      paymentMethod: PaymentMethod.credit,
      description: 'Lunch',
      vendor: 'Cafe',
      tags: ['work', 'lunch'],
      isRecurring: false,
    );

    test('isExpense for non-income', () {
      expect(entry.isExpense, isTrue);
    });

    test('isExpense false for income', () {
      final income = entry.copyWith(category: ExpenseCategory.income);
      expect(income.isExpense, isFalse);
    });

    test('toJson and fromJson roundtrip', () {
      final json = entry.toJson();
      final restored = ExpenseEntry.fromJson(json);
      expect(restored.id, entry.id);
      expect(restored.amount, entry.amount);
      expect(restored.category, entry.category);
      expect(restored.paymentMethod, entry.paymentMethod);
      expect(restored.description, entry.description);
      expect(restored.vendor, entry.vendor);
      expect(restored.tags, entry.tags);
      expect(restored.isRecurring, entry.isRecurring);
    });

    test('encodeList and decodeList roundtrip', () {
      final list = [entry, entry.copyWith(id: 'e2', amount: 10.0)];
      final encoded = ExpenseEntry.encodeList(list);
      final decoded = ExpenseEntry.decodeList(encoded);
      expect(decoded.length, 2);
      expect(decoded[0].id, 'e1');
      expect(decoded[1].id, 'e2');
    });

    test('copyWith preserves unchanged fields', () {
      final copy = entry.copyWith(amount: 50.0);
      expect(copy.amount, 50.0);
      expect(copy.id, entry.id);
      expect(copy.vendor, entry.vendor);
    });

    test('fromJson with missing fields uses defaults', () {
      final json = {'id': 'x', 'timestamp': '2026-01-01T00:00:00.000'};
      final e = ExpenseEntry.fromJson(json);
      expect(e.amount, 0.0);
      expect(e.category, ExpenseCategory.other);
      expect(e.paymentMethod, PaymentMethod.debit);
      expect(e.tags, isEmpty);
      expect(e.isRecurring, false);
    });
  });

  // --- BudgetConfig Tests ---

  group('BudgetConfig', () {
    test('default values', () {
      const config = BudgetConfig();
      expect(config.monthlyBudget, 3000.0);
      expect(config.alertThreshold, 0.8);
      expect(config.currencySymbol, '\$');
    });

    test('toJson and fromJson roundtrip', () {
      final config = BudgetConfig(
        monthlyBudget: 5000,
        categoryLimits: {ExpenseCategory.food: 800},
        alertThreshold: 0.9,
        currencySymbol: '€',
      );
      final json = config.toJson();
      final restored = BudgetConfig.fromJson(json);
      expect(restored.monthlyBudget, 5000);
      expect(restored.alertThreshold, 0.9);
      expect(restored.currencySymbol, '€');
      expect(restored.categoryLimits[ExpenseCategory.food], 800);
    });
  });

  // --- Service Tests ---

  group('ExpenseTrackerService', () {
    late ExpenseTrackerService service;

    ExpenseEntry _makeEntry({
      String id = 'e1',
      DateTime? timestamp,
      double amount = 10.0,
      ExpenseCategory category = ExpenseCategory.food,
      PaymentMethod paymentMethod = PaymentMethod.debit,
      String? vendor,
      List<String> tags = const [],
      bool isRecurring = false,
    }) {
      return ExpenseEntry(
        id: id,
        timestamp: timestamp ?? DateTime(2026, 3, 4, 12, 0),
        amount: amount,
        category: category,
        paymentMethod: paymentMethod,
        vendor: vendor,
        tags: tags,
        isRecurring: isRecurring,
      );
    }

    setUp(() {
      service = ExpenseTrackerService();
    });

    test('add and retrieve entry', () {
      final e = _makeEntry();
      service.addEntry(e);
      expect(service.entries.length, 1);
      expect(service.getEntry('e1'), isNotNull);
    });

    test('addEntries bulk', () {
      service.addEntries([
        _makeEntry(id: 'a'),
        _makeEntry(id: 'b'),
      ]);
      expect(service.entries.length, 2);
    });

    test('removeEntry', () {
      service.addEntry(_makeEntry());
      expect(service.removeEntry('e1'), isTrue);
      expect(service.entries, isEmpty);
    });

    test('removeEntry returns false for missing', () {
      expect(service.removeEntry('nope'), isFalse);
    });

    test('updateEntry', () {
      service.addEntry(_makeEntry());
      final updated = _makeEntry(amount: 99.0);
      expect(service.updateEntry('e1', updated), isTrue);
      expect(service.getEntry('e1')!.amount, 99.0);
    });

    test('updateEntry returns false for missing', () {
      expect(service.updateEntry('nope', _makeEntry()), isFalse);
    });

    test('getEntriesForDate', () {
      service.addEntry(_makeEntry(id: 'a', timestamp: DateTime(2026, 3, 4)));
      service.addEntry(_makeEntry(id: 'b', timestamp: DateTime(2026, 3, 5)));
      final result = service.getEntriesForDate(DateTime(2026, 3, 4));
      expect(result.length, 1);
      expect(result.first.id, 'a');
    });

    test('getEntriesForMonth', () {
      service.addEntry(_makeEntry(id: 'a', timestamp: DateTime(2026, 3, 4)));
      service.addEntry(_makeEntry(id: 'b', timestamp: DateTime(2026, 2, 4)));
      final result = service.getEntriesForMonth(2026, 3);
      expect(result.length, 1);
    });

    test('getEntriesInRange', () {
      service.addEntry(_makeEntry(id: 'a', timestamp: DateTime(2026, 3, 1)));
      service.addEntry(_makeEntry(id: 'b', timestamp: DateTime(2026, 3, 10)));
      service.addEntry(_makeEntry(id: 'c', timestamp: DateTime(2026, 3, 20)));
      final result = service.getEntriesInRange(
          DateTime(2026, 3, 5), DateTime(2026, 3, 15));
      expect(result.length, 1);
      expect(result.first.id, 'b');
    });

    test('getByCategory', () {
      service.addEntry(_makeEntry(id: 'a', category: ExpenseCategory.food));
      service.addEntry(
          _makeEntry(id: 'b', category: ExpenseCategory.transport));
      expect(service.getByCategory(ExpenseCategory.food).length, 1);
    });

    test('getByVendor', () {
      service.addEntry(_makeEntry(id: 'a', vendor: 'Starbucks'));
      service.addEntry(_makeEntry(id: 'b', vendor: 'Amazon'));
      expect(service.getByVendor('star').length, 1);
    });

    test('getByTag', () {
      service.addEntry(_makeEntry(id: 'a', tags: ['work']));
      service.addEntry(_makeEntry(id: 'b', tags: ['personal']));
      expect(service.getByTag('work').length, 1);
    });

    test('getRecurring', () {
      service.addEntry(_makeEntry(id: 'a', isRecurring: true));
      service.addEntry(_makeEntry(id: 'b', isRecurring: false));
      expect(service.getRecurring().length, 1);
    });

    test('getDailySummary separates income and expenses', () {
      service.addEntry(_makeEntry(
          id: 'a', amount: 50, category: ExpenseCategory.food,
          timestamp: DateTime(2026, 3, 4)));
      service.addEntry(_makeEntry(
          id: 'b', amount: 1000, category: ExpenseCategory.income,
          timestamp: DateTime(2026, 3, 4)));
      final summary = service.getDailySummary(DateTime(2026, 3, 4));
      expect(summary.totalSpent, 50);
      expect(summary.totalIncome, 1000);
      expect(summary.transactionCount, 2);
      expect(summary.netFlow, 950);
    });

    test('getMonthlyReport basic', () {
      service.addEntry(_makeEntry(
          id: 'a', amount: 100, timestamp: DateTime(2026, 3, 1)));
      service.addEntry(_makeEntry(
          id: 'b', amount: 200, timestamp: DateTime(2026, 3, 2)));
      final report = service.getMonthlyReport(2026, 3);
      expect(report.totalSpent, 300);
      expect(report.transactionCount, 2);
    });

    test('monthly report budget grade', () {
      service.updateConfig(const BudgetConfig(monthlyBudget: 1000));
      service.addEntry(_makeEntry(amount: 400, timestamp: DateTime(2026, 3, 1)));
      final report = service.getMonthlyReport(2026, 3);
      expect(report.budgetUsedPercent, 40);
      expect(report.budgetGrade, 'A');
    });

    test('budget exceeded alert', () {
      service.updateConfig(const BudgetConfig(monthlyBudget: 100));
      service.addEntry(_makeEntry(amount: 150, timestamp: DateTime(2026, 3, 1)));
      final report = service.getMonthlyReport(2026, 3);
      expect(report.alerts.any((a) => a.severity == 'critical'), isTrue);
    });

    test('budget warning alert', () {
      service.updateConfig(
          const BudgetConfig(monthlyBudget: 100, alertThreshold: 0.8));
      service.addEntry(_makeEntry(amount: 85, timestamp: DateTime(2026, 3, 1)));
      final report = service.getMonthlyReport(2026, 3);
      expect(report.alerts.any((a) => a.severity == 'warning'), isTrue);
    });

    test('category budget alert', () {
      service.updateConfig(BudgetConfig(
        monthlyBudget: 5000,
        categoryLimits: {ExpenseCategory.food: 100},
      ));
      service.addEntry(_makeEntry(
          amount: 120, category: ExpenseCategory.food,
          timestamp: DateTime(2026, 3, 1)));
      final report = service.getMonthlyReport(2026, 3);
      expect(
          report.alerts.any(
              (a) => a.category == ExpenseCategory.food && a.severity == 'critical'),
          isTrue);
    });

    test('savings rate calculation', () {
      service.addEntry(_makeEntry(
          id: 'a', amount: 500, category: ExpenseCategory.food,
          timestamp: DateTime(2026, 3, 1)));
      service.addEntry(_makeEntry(
          id: 'b', amount: 2000, category: ExpenseCategory.income,
          timestamp: DateTime(2026, 3, 1)));
      final report = service.getMonthlyReport(2026, 3);
      expect(report.savingsRate, 75.0);
    });

    test('getSpendingTrend returns weekly data', () {
      final now = DateTime.now();
      for (int i = 0; i < 28; i++) {
        service.addEntry(_makeEntry(
          id: 'e$i',
          amount: 10.0 + i,
          timestamp: now.subtract(Duration(days: i)),
        ));
      }
      final trend = service.getSpendingTrend(weeks: 4);
      expect(trend.weeklyTotals.length, 4);
      expect(trend.direction, isNotEmpty);
    });

    test('getTopVendors', () {
      service.addEntry(_makeEntry(id: 'a', vendor: 'Amazon', amount: 100));
      service.addEntry(_makeEntry(id: 'b', vendor: 'Amazon', amount: 50));
      service.addEntry(_makeEntry(id: 'c', vendor: 'Costco', amount: 200));
      final vendors = service.getTopVendors();
      expect(vendors.first.vendor, 'Costco');
      expect(vendors.first.totalSpent, 200);
      expect(vendors[1].transactionCount, 2);
    });

    test('getCategoryPercentages', () {
      final entries = [
        _makeEntry(id: 'a', amount: 75, category: ExpenseCategory.food),
        _makeEntry(id: 'b', amount: 25, category: ExpenseCategory.transport),
      ];
      service.addEntries(entries);
      final pcts = service.getCategoryPercentages(service.entries);
      expect(pcts[ExpenseCategory.food], 75.0);
      expect(pcts[ExpenseCategory.transport], 25.0);
    });

    test('getCategoryPercentages excludes income', () {
      final entries = [
        _makeEntry(id: 'a', amount: 100, category: ExpenseCategory.food),
        _makeEntry(id: 'b', amount: 5000, category: ExpenseCategory.income),
      ];
      service.addEntries(entries);
      final pcts = service.getCategoryPercentages(service.entries);
      expect(pcts[ExpenseCategory.food], 100.0);
      expect(pcts.containsKey(ExpenseCategory.income), isFalse);
    });

    test('generateInsights returns tips', () {
      service.addEntry(_makeEntry(
          id: 'a', amount: 500, category: ExpenseCategory.food,
          timestamp: DateTime(2026, 3, 1)));
      service.addEntry(_makeEntry(
          id: 'b', amount: 2000, category: ExpenseCategory.income,
          timestamp: DateTime(2026, 3, 1)));
      final insights = service.generateInsights(2026, 3);
      expect(insights, isNotEmpty);
    });

    test('getLoggingStreak consecutive days', () {
      final now = DateTime.now();
      for (int i = 0; i < 5; i++) {
        service.addEntry(_makeEntry(
          id: 'e$i',
          timestamp: now.subtract(Duration(days: i)),
        ));
      }
      expect(service.getLoggingStreak(), 5);
    });

    test('getLoggingStreak returns 0 when most recent entry is stale', () {
      // Issue #38: streak should be 0 if last entry > 1 day ago
      final staleDate = DateTime.now().subtract(const Duration(days: 10));
      for (int i = 0; i < 5; i++) {
        service.addEntry(_makeEntry(
          id: 'stale$i',
          timestamp: staleDate.subtract(Duration(days: i)),
        ));
      }
      expect(service.getLoggingStreak(), 0);
    });

    test('getLoggingStreak breaks on gap', () {
      final now = DateTime.now();
      service.addEntry(_makeEntry(id: 'a', timestamp: now));
      service.addEntry(
          _makeEntry(id: 'b', timestamp: now.subtract(const Duration(days: 1))));
      service.addEntry(
          _makeEntry(id: 'c', timestamp: now.subtract(const Duration(days: 3))));
      expect(service.getLoggingStreak(), 2);
    });

    test('exportToJson and importFromJson roundtrip', () {
      service.updateConfig(const BudgetConfig(monthlyBudget: 5000));
      service.addEntry(_makeEntry(id: 'a', amount: 42.0));
      service.addEntry(_makeEntry(id: 'b', amount: 13.0));
      final json = service.exportToJson();

      final service2 = ExpenseTrackerService();
      service2.importFromJson(json);
      expect(service2.entries.length, 2);
      expect(service2.config.monthlyBudget, 5000);
      expect(service2.getEntry('a')!.amount, 42.0);
    });

    test('getFullReport produces complete report', () {
      service.addEntry(_makeEntry(
          id: 'a', amount: 100, vendor: 'Store',
          timestamp: DateTime(2026, 3, 1)));
      final report = service.getFullReport(2026, 3);
      expect(report.currentMonth.totalSpent, 100);
      expect(report.categoryPercentages, isNotEmpty);
    });

    test('getTextSummary produces output', () {
      service.addEntry(_makeEntry(
          id: 'a', amount: 100, timestamp: DateTime(2026, 3, 1)));
      final text = service.getTextSummary(2026, 3);
      expect(text, contains('Expense Report'));
      expect(text, contains('100.00'));
    });

    test('updateConfig changes behavior', () {
      service.updateConfig(const BudgetConfig(
        monthlyBudget: 500,
        currencySymbol: '£',
      ));
      expect(service.config.monthlyBudget, 500);
      expect(service.config.currencySymbol, '£');
    });

    test('empty service returns empty results', () {
      expect(service.entries, isEmpty);
      expect(service.getTopVendors(), isEmpty);
      expect(service.getLoggingStreak(), 0);
      final report = service.getMonthlyReport(2026, 3);
      expect(report.totalSpent, 0);
      expect(report.transactionCount, 0);
    });

    test('getEntry returns null for missing', () {
      expect(service.getEntry('missing'), isNull);
    });

    test('remainingBudget calculation', () {
      service.updateConfig(const BudgetConfig(monthlyBudget: 1000));
      service.addEntry(_makeEntry(amount: 300, timestamp: DateTime(2026, 3, 1)));
      final report = service.getMonthlyReport(2026, 3);
      expect(report.remainingBudget, 700);
    });

    test('BudgetAlert percentUsed', () {
      const alert = BudgetAlert(
        message: 'test',
        severity: 'warning',
        currentAmount: 80,
        limitAmount: 100,
      );
      expect(alert.percentUsed, 80.0);
    });

    test('BudgetAlert zero limit', () {
      const alert = BudgetAlert(
        message: 'test',
        severity: 'info',
        currentAmount: 50,
        limitAmount: 0,
      );
      expect(alert.percentUsed, 0);
    });

    test('multiple payment methods tracked', () {
      service.addEntry(_makeEntry(
          id: 'a', paymentMethod: PaymentMethod.cash, amount: 50,
          timestamp: DateTime(2026, 3, 1)));
      service.addEntry(_makeEntry(
          id: 'b', paymentMethod: PaymentMethod.credit, amount: 100,
          timestamp: DateTime(2026, 3, 1)));
      final report = service.getMonthlyReport(2026, 3);
      expect(report.byPaymentMethod[PaymentMethod.cash], 50);
      expect(report.byPaymentMethod[PaymentMethod.credit], 100);
    });

    test('vendor stats average transaction', () {
      service.addEntry(_makeEntry(id: 'a', vendor: 'Store', amount: 10));
      service.addEntry(_makeEntry(id: 'b', vendor: 'Store', amount: 30));
      final vendors = service.getTopVendors();
      expect(vendors.first.averageTransaction, 20.0);
    });

    test('income entries excluded from vendor stats', () {
      service.addEntry(_makeEntry(
          id: 'a', vendor: 'Employer', amount: 5000,
          category: ExpenseCategory.income));
      expect(service.getTopVendors(), isEmpty);
    });
  });
}
