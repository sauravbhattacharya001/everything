import 'dart:convert';
import 'dart:math';
import '../../models/debt_entry.dart';

/// Payoff strategy type.
enum PayoffStrategy { snowball, avalanche }

/// A single month in a payoff schedule.
class PayoffMonth {
  final int month;
  final String debtId;
  final String debtName;
  final double startBalance;
  final double interest;
  final double payment;
  final double endBalance;

  PayoffMonth({
    required this.month,
    required this.debtId,
    required this.debtName,
    required this.startBalance,
    required this.interest,
    required this.payment,
    required this.endBalance,
  });
}

/// Summary of a payoff plan.
class PayoffPlan {
  final PayoffStrategy strategy;
  final int totalMonths;
  final double totalInterest;
  final double totalPaid;
  final List<PayoffMonth> schedule;
  final List<String> payoffOrder;

  PayoffPlan({
    required this.strategy,
    required this.totalMonths,
    required this.totalInterest,
    required this.totalPaid,
    required this.schedule,
    required this.payoffOrder,
  });

  DateTime get estimatedPayoffDate =>
      DateTime.now().add(Duration(days: totalMonths * 30));
}

/// Service for managing debts and computing payoff strategies.
class DebtPayoffService {
  final List<DebtEntry> _debts = [];

  List<DebtEntry> get debts => List.unmodifiable(_debts);
  List<DebtEntry> get activeDebts =>
      _debts.where((d) => !d.isPaidOff).toList();
  List<DebtEntry> get paidOffDebts =>
      _debts.where((d) => d.isPaidOff).toList();

  double get totalDebt => activeDebts.fold(0.0, (s, d) => s + d.currentBalance);
  double get totalMinimumPayments =>
      activeDebts.fold(0.0, (s, d) => s + d.minimumPayment);
  double get weightedAverageRate {
    final total = totalDebt;
    if (total == 0) return 0;
    return activeDebts.fold(
            0.0, (s, d) => s + d.interestRate * d.currentBalance) /
        total;
  }

  // ── CRUD ──────────────────────────────────────────────────────

  DebtEntry addDebt({
    required String name,
    required double balance,
    required double interestRate,
    required double minimumPayment,
    String emoji = '💳',
    DebtCategory category = DebtCategory.creditCard,
  }) {
    if (name.trim().isEmpty) throw ArgumentError('Name cannot be empty');
    if (balance <= 0) throw ArgumentError('Balance must be positive');
    if (interestRate < 0) throw ArgumentError('Interest rate cannot be negative');
    if (minimumPayment <= 0) {
      throw ArgumentError('Minimum payment must be positive');
    }

    final debt = DebtEntry(
      id: _generateId(),
      name: name.trim(),
      emoji: emoji,
      balance: balance,
      interestRate: interestRate,
      minimumPayment: minimumPayment,
      category: category,
    );
    _debts.add(debt);
    return debt;
  }

  void removeDebt(String debtId) {
    _debts.removeWhere((d) => d.id == debtId);
  }

  DebtEntry? markPaidOff(String debtId) {
    final idx = _debts.indexWhere((d) => d.id == debtId);
    if (idx < 0) return null;
    final updated = _debts[idx].copyWith(isPaidOff: true);
    _debts[idx] = updated;
    return updated;
  }

  DebtPayment? addPayment(String debtId, double amount, {String? note}) {
    final idx = _debts.indexWhere((d) => d.id == debtId);
    if (idx < 0) return null;
    if (amount <= 0) throw ArgumentError('Payment must be positive');

    final payment = DebtPayment(
      id: _generateId(),
      amount: amount,
      note: note,
    );
    final debt = _debts[idx];
    final updatedPayments = [...debt.payments, payment];
    _debts[idx] = debt.copyWith(payments: updatedPayments);
    return payment;
  }

  // ── Payoff Strategies ─────────────────────────────────────────

  /// Compute a payoff plan for the given strategy and extra monthly payment.
  PayoffPlan computePlan(PayoffStrategy strategy, {double extraPayment = 0}) {
    if (activeDebts.isEmpty) {
      return PayoffPlan(
        strategy: strategy,
        totalMonths: 0,
        totalInterest: 0,
        totalPaid: 0,
        schedule: [],
        payoffOrder: [],
      );
    }

    final balances = <String, double>{};
    final rates = <String, double>{};
    final mins = <String, double>{};
    final names = <String, String>{};

    for (final d in activeDebts) {
      balances[d.id] = d.currentBalance;
      rates[d.id] = d.monthlyInterestRate;
      mins[d.id] = d.minimumPayment;
      names[d.id] = d.name;
    }

    List<String> priorityOrder() {
      final ids = balances.keys.where((id) => balances[id]! > 0.01).toList();
      if (strategy == PayoffStrategy.snowball) {
        ids.sort((a, b) => balances[a]!.compareTo(balances[b]!));
      } else {
        ids.sort((a, b) => rates[b]!.compareTo(rates[a]!));
      }
      return ids;
    }

    final schedule = <PayoffMonth>[];
    final payoffOrder = <String>[];
    var totalInterest = 0.0;
    var totalPaid = 0.0;
    var month = 0;
    const maxMonths = 600;
    // Track freed minimums from paid-off debts so they snowball
    // into future months (the core mechanic of debt snowball/avalanche).
    var freedMinimums = 0.0;

    while (balances.values.any((b) => b > 0.01) && month < maxMonths) {
      month++;
      var extraLeft = extraPayment + freedMinimums;

      for (final id in balances.keys.toList()) {
        if (balances[id]! <= 0.01) continue;
        final interest = balances[id]! * rates[id]!;
        totalInterest += interest;
        final bal = balances[id]! + interest;
        final payment = min(mins[id]!, bal);
        balances[id] = bal - payment;
        totalPaid += payment;

        schedule.add(PayoffMonth(
          month: month,
          debtId: id,
          debtName: names[id]!,
          startBalance: bal,
          interest: interest,
          payment: payment,
          endBalance: balances[id]!,
        ));

        if (balances[id]! <= 0.01 && !payoffOrder.contains(id)) {
          payoffOrder.add(id);
          // Freed minimum is permanently available for future months.
          freedMinimums += mins[id]!;
          // Also make the surplus available this month: the actual payment
          // was min(mins[id], bal), so the unused portion is freed now.
          extraLeft += mins[id]! - payment;
        }
      }

      final order = priorityOrder();
      for (final id in order) {
        if (extraLeft <= 0) break;
        if (balances[id]! <= 0.01) continue;
        final payment = min(extraLeft, balances[id]!);
        balances[id] = balances[id]! - payment;
        totalPaid += payment;
        extraLeft -= payment;

        schedule.add(PayoffMonth(
          month: month,
          debtId: id,
          debtName: names[id]!,
          startBalance: balances[id]! + payment,
          interest: 0,
          payment: payment,
          endBalance: balances[id]!,
        ));

        if (balances[id]! <= 0.01 && !payoffOrder.contains(id)) {
          payoffOrder.add(id);
          freedMinimums += mins[id]!;
        }
      }
    }

    return PayoffPlan(
      strategy: strategy,
      totalMonths: month,
      totalInterest: totalInterest,
      totalPaid: totalPaid,
      schedule: schedule,
      payoffOrder: payoffOrder,
    );
  }

  /// Compare snowball vs avalanche side-by-side.
  Map<String, PayoffPlan> compareStrategies({double extraPayment = 0}) {
    return {
      'snowball': computePlan(PayoffStrategy.snowball,
          extraPayment: extraPayment),
      'avalanche': computePlan(PayoffStrategy.avalanche,
          extraPayment: extraPayment),
    };
  }

  /// Interest savings from avalanche over snowball.
  double interestSavings({double extraPayment = 0}) {
    final plans = compareStrategies(extraPayment: extraPayment);
    return plans['snowball']!.totalInterest -
        plans['avalanche']!.totalInterest;
  }

  // ── Persistence ───────────────────────────────────────────────

  String exportToJson() =>
      const JsonEncoder.withIndent('  ').convert(
        _debts.map((d) => d.toJson()).toList(),
      );

  void importFromJson(String json) {
    final list = jsonDecode(json) as List<dynamic>;
    _debts
      ..clear()
      ..addAll(list.map(
          (e) => DebtEntry.fromJson(e as Map<String, dynamic>)));
  }

  String _generateId() =>
      '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
}
