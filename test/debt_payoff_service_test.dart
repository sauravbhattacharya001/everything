import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/debt_payoff_service.dart';
import 'package:everything/models/debt_entry.dart';

void main() {
  late DebtPayoffService service;

  setUp(() {
    service = DebtPayoffService();
  });

  group('DebtEntry model', () {
    test('creates with defaults', () {
      final debt = DebtEntry(
        id: '1', name: 'Visa', balance: 5000,
        interestRate: 18.0, minimumPayment: 100,
      );
      expect(debt.emoji, '💳');
      expect(debt.category, DebtCategory.creditCard);
      expect(debt.isPaidOff, false);
      expect(debt.currentBalance, 5000);
      expect(debt.totalPaid, 0);
    });

    test('currentBalance reflects payments', () {
      final debt = DebtEntry(
        id: '1', name: 'Visa', balance: 5000,
        interestRate: 18.0, minimumPayment: 100,
        payments: [
          DebtPayment(id: 'p1', amount: 1000),
          DebtPayment(id: 'p2', amount: 500),
        ],
      );
      expect(debt.currentBalance, 3500);
      expect(debt.totalPaid, 1500);
    });

    test('monthlyInterestRate is correct', () {
      final debt = DebtEntry(
        id: '1', name: 'Test', balance: 1000,
        interestRate: 12.0, minimumPayment: 50,
      );
      expect(debt.monthlyInterestRate, closeTo(0.01, 0.0001));
    });

    test('zero balance means zero months', () {
      final debt = DebtEntry(
        id: '1', name: 'Done', balance: 1000,
        interestRate: 10, minimumPayment: 50,
        payments: [DebtPayment(id: 'p1', amount: 1000)],
      );
      expect(debt.monthsToPayoff, 0);
    });

    test('toJson and fromJson roundtrip', () {
      final debt = DebtEntry(
        id: 'abc', name: 'Car Loan', emoji: '🚗',
        balance: 15000, interestRate: 5.5, minimumPayment: 300,
        category: DebtCategory.autoLoan,
      );
      final restored = DebtEntry.fromJson(debt.toJson());
      expect(restored.id, 'abc');
      expect(restored.name, 'Car Loan');
      expect(restored.balance, 15000);
      expect(restored.interestRate, 5.5);
      expect(restored.category, DebtCategory.autoLoan);
    });

    test('copyWith works', () {
      final debt = DebtEntry(
        id: '1', name: 'Visa', balance: 5000,
        interestRate: 18, minimumPayment: 100,
      );
      final updated = debt.copyWith(name: 'Mastercard', isPaidOff: true);
      expect(updated.name, 'Mastercard');
      expect(updated.isPaidOff, true);
      expect(updated.balance, 5000);
    });
  });

  group('DebtPayment', () {
    test('toJson/fromJson roundtrip', () {
      final p = DebtPayment(id: 'x', amount: 250, note: 'extra');
      final restored = DebtPayment.fromJson(p.toJson());
      expect(restored.id, 'x');
      expect(restored.amount, 250);
      expect(restored.note, 'extra');
    });
  });

  group('DebtCategory', () {
    test('all categories have labels and emojis', () {
      for (final c in DebtCategory.values) {
        expect(c.label.isNotEmpty, true);
        expect(c.emoji.isNotEmpty, true);
      }
    });
  });

  group('DebtPayoffService CRUD', () {
    test('addDebt creates debt', () {
      final d = service.addDebt(
        name: 'Visa', balance: 3000, interestRate: 22, minimumPayment: 75,
      );
      expect(service.debts.length, 1);
      expect(d.name, 'Visa');
    });

    test('addDebt rejects empty name', () {
      expect(
        () => service.addDebt(name: '', balance: 100, interestRate: 5, minimumPayment: 10),
        throwsArgumentError,
      );
    });

    test('addDebt rejects zero balance', () {
      expect(
        () => service.addDebt(name: 'X', balance: 0, interestRate: 5, minimumPayment: 10),
        throwsArgumentError,
      );
    });

    test('addDebt rejects negative rate', () {
      expect(
        () => service.addDebt(name: 'X', balance: 100, interestRate: -1, minimumPayment: 10),
        throwsArgumentError,
      );
    });

    test('addDebt rejects zero minimum payment', () {
      expect(
        () => service.addDebt(name: 'X', balance: 100, interestRate: 5, minimumPayment: 0),
        throwsArgumentError,
      );
    });

    test('removeDebt removes', () {
      final d = service.addDebt(name: 'A', balance: 100, interestRate: 5, minimumPayment: 10);
      service.removeDebt(d.id);
      expect(service.debts.isEmpty, true);
    });

    test('markPaidOff marks debt', () {
      final d = service.addDebt(name: 'A', balance: 100, interestRate: 5, minimumPayment: 10);
      final updated = service.markPaidOff(d.id);
      expect(updated!.isPaidOff, true);
      expect(service.activeDebts.isEmpty, true);
      expect(service.paidOffDebts.length, 1);
    });

    test('markPaidOff returns null for unknown id', () {
      expect(service.markPaidOff('fake'), isNull);
    });

    test('addPayment records payment', () {
      final d = service.addDebt(name: 'A', balance: 1000, interestRate: 10, minimumPayment: 50);
      final p = service.addPayment(d.id, 200, note: 'bonus');
      expect(p!.amount, 200);
      expect(service.debts.first.payments.length, 1);
    });

    test('addPayment rejects zero amount', () {
      final d = service.addDebt(name: 'A', balance: 1000, interestRate: 10, minimumPayment: 50);
      expect(() => service.addPayment(d.id, 0), throwsArgumentError);
    });

    test('addPayment returns null for unknown id', () {
      expect(service.addPayment('fake', 100), isNull);
    });
  });

  group('Aggregate properties', () {
    test('totalDebt sums active debts', () {
      service.addDebt(name: 'A', balance: 1000, interestRate: 10, minimumPayment: 50);
      service.addDebt(name: 'B', balance: 2000, interestRate: 20, minimumPayment: 75);
      expect(service.totalDebt, 3000);
    });

    test('weightedAverageRate is correct', () {
      service.addDebt(name: 'A', balance: 1000, interestRate: 10, minimumPayment: 50);
      service.addDebt(name: 'B', balance: 3000, interestRate: 20, minimumPayment: 75);
      expect(service.weightedAverageRate, closeTo(17.5, 0.01));
    });

    test('weightedAverageRate is 0 with no debts', () {
      expect(service.weightedAverageRate, 0);
    });
  });

  group('Payoff strategies', () {
    test('empty debts produces empty plan', () {
      final plan = service.computePlan(PayoffStrategy.snowball);
      expect(plan.totalMonths, 0);
      expect(plan.totalInterest, 0);
    });

    test('single debt computes payoff months', () {
      service.addDebt(name: 'Card', balance: 1000, interestRate: 12, minimumPayment: 100);
      final plan = service.computePlan(PayoffStrategy.avalanche);
      expect(plan.totalMonths, greaterThan(0));
      expect(plan.totalMonths, lessThan(15));
      expect(plan.totalInterest, greaterThan(0));
      expect(plan.payoffOrder.length, 1);
    });

    test('zero interest debt pays off in exact months', () {
      service.addDebt(name: 'Friend', balance: 500, interestRate: 0, minimumPayment: 100);
      final plan = service.computePlan(PayoffStrategy.snowball);
      expect(plan.totalMonths, 5);
      expect(plan.totalInterest, 0);
    });

    test('snowball pays smallest balance first', () {
      service.addDebt(name: 'Small', balance: 500, interestRate: 20, minimumPayment: 50);
      service.addDebt(name: 'Big', balance: 5000, interestRate: 25, minimumPayment: 100);
      final plan = service.computePlan(PayoffStrategy.snowball, extraPayment: 100);
      expect(plan.payoffOrder.first,
          service.debts.firstWhere((d) => d.name == 'Small').id);
    });

    test('avalanche pays highest rate first', () {
      service.addDebt(name: 'LowRate', balance: 500, interestRate: 5, minimumPayment: 50);
      service.addDebt(name: 'HighRate', balance: 5000, interestRate: 25, minimumPayment: 100);
      final plan = service.computePlan(PayoffStrategy.avalanche, extraPayment: 100);
      expect(plan.payoffOrder.first,
          service.debts.firstWhere((d) => d.name == 'HighRate').id);
    });

    test('extra payment reduces total months', () {
      service.addDebt(name: 'Card', balance: 5000, interestRate: 18, minimumPayment: 100);
      final noExtra = service.computePlan(PayoffStrategy.avalanche);
      final withExtra = service.computePlan(PayoffStrategy.avalanche, extraPayment: 200);
      expect(withExtra.totalMonths, lessThan(noExtra.totalMonths));
    });

    test('extra payment reduces total interest', () {
      service.addDebt(name: 'Card', balance: 5000, interestRate: 18, minimumPayment: 100);
      final noExtra = service.computePlan(PayoffStrategy.avalanche);
      final withExtra = service.computePlan(PayoffStrategy.avalanche, extraPayment: 200);
      expect(withExtra.totalInterest, lessThan(noExtra.totalInterest));
    });

    test('compareStrategies returns both plans', () {
      service.addDebt(name: 'A', balance: 1000, interestRate: 15, minimumPayment: 50);
      final plans = service.compareStrategies();
      expect(plans.containsKey('snowball'), true);
      expect(plans.containsKey('avalanche'), true);
    });

    test('interestSavings is non-negative', () {
      service.addDebt(name: 'A', balance: 2000, interestRate: 20, minimumPayment: 50);
      service.addDebt(name: 'B', balance: 500, interestRate: 5, minimumPayment: 25);
      final savings = service.interestSavings(extraPayment: 50);
      expect(savings, greaterThanOrEqualTo(0));
    });
  });

  group('Persistence', () {
    test('export/import roundtrip', () {
      service.addDebt(name: 'Visa', balance: 3000, interestRate: 18,
          minimumPayment: 75, category: DebtCategory.creditCard);
      service.addDebt(name: 'Car', balance: 15000, interestRate: 5,
          minimumPayment: 300, category: DebtCategory.autoLoan);
      final json = service.exportToJson();
      final newService = DebtPayoffService();
      newService.importFromJson(json);
      expect(newService.debts.length, 2);
      expect(newService.debts[0].name, 'Visa');
      expect(newService.debts[1].category, DebtCategory.autoLoan);
    });
  });

  group('PayoffPlan', () {
    test('estimatedPayoffDate is in the future', () {
      service.addDebt(name: 'A', balance: 1000, interestRate: 10, minimumPayment: 100);
      final plan = service.computePlan(PayoffStrategy.avalanche);
      expect(plan.estimatedPayoffDate.isAfter(DateTime.now()), true);
    });
  });
}
