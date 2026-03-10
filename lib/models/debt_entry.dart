import 'dart:math' show log;

/// Represents a single debt (credit card, loan, mortgage, etc.)
class DebtEntry {
  final String id;
  final String name;
  final String emoji;
  final double balance;
  final double interestRate; // Annual percentage rate (e.g. 18.5)
  final double minimumPayment;
  final DebtCategory category;
  final DateTime createdAt;
  final List<DebtPayment> payments;
  final bool isPaidOff;

  DebtEntry({
    required this.id,
    required this.name,
    this.emoji = '💳',
    required this.balance,
    required this.interestRate,
    required this.minimumPayment,
    this.category = DebtCategory.creditCard,
    DateTime? createdAt,
    List<DebtPayment>? payments,
    this.isPaidOff = false,
  })  : createdAt = createdAt ?? DateTime.now(),
        payments = payments ?? [];

  double get totalPaid => payments.fold(0.0, (sum, p) => sum + p.amount);

  double get currentBalance => (balance - totalPaid).clamp(0.0, double.infinity);

  double get monthlyInterestRate => interestRate / 100.0 / 12.0;

  /// Months to pay off at minimum payment (ignoring extra payments).
  int? get monthsToPayoff {
    if (minimumPayment <= 0 || currentBalance <= 0) return 0;
    final r = monthlyInterestRate;
    if (r == 0) return (currentBalance / minimumPayment).ceil();
    final monthlyInterest = currentBalance * r;
    if (minimumPayment <= monthlyInterest) return null; // Never pays off
    return (-log(1 - (currentBalance * r / minimumPayment)) / log(1 + r))
        .ceil();
  }

  /// Total interest if paying only minimums from current balance.
  double get totalInterestAtMinimum {
    if (currentBalance <= 0 || minimumPayment <= 0) return 0;
    final r = monthlyInterestRate;
    if (r == 0) return 0;
    var bal = currentBalance;
    var totalInterest = 0.0;
    var months = 0;
    while (bal > 0.01 && months < 600) {
      final interest = bal * r;
      totalInterest += interest;
      final payment =
          minimumPayment > bal + interest ? bal + interest : minimumPayment;
      bal = bal + interest - payment;
      months++;
    }
    return totalInterest;
  }

  DebtEntry copyWith({
    String? name,
    String? emoji,
    double? balance,
    double? interestRate,
    double? minimumPayment,
    DebtCategory? category,
    List<DebtPayment>? payments,
    bool? isPaidOff,
  }) {
    return DebtEntry(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      balance: balance ?? this.balance,
      interestRate: interestRate ?? this.interestRate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      category: category ?? this.category,
      createdAt: createdAt,
      payments: payments ?? this.payments,
      isPaidOff: isPaidOff ?? this.isPaidOff,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'balance': balance,
        'interestRate': interestRate,
        'minimumPayment': minimumPayment,
        'category': category.name,
        'createdAt': createdAt.toIso8601String(),
        'payments': payments.map((p) => p.toJson()).toList(),
        'isPaidOff': isPaidOff,
      };

  factory DebtEntry.fromJson(Map<String, dynamic> json) {
    return DebtEntry(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '💳',
      balance: (json['balance'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      minimumPayment: (json['minimumPayment'] as num).toDouble(),
      category: DebtCategory.values.firstWhere(
        (v) => v.name == json['category'],
        orElse: () => DebtCategory.creditCard,
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      payments: (json['payments'] as List<dynamic>?)
              ?.map((p) => DebtPayment.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      isPaidOff: json['isPaidOff'] as bool? ?? false,
    );
  }
}

/// A single payment made toward a debt.
class DebtPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String? note;

  DebtPayment({
    required this.id,
    required this.amount,
    DateTime? date,
    this.note,
  }) : date = date ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'date': date.toIso8601String(),
        'note': note,
      };

  factory DebtPayment.fromJson(Map<String, dynamic> json) {
    return DebtPayment(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );
  }
}

enum DebtCategory {
  creditCard,
  studentLoan,
  autoLoan,
  mortgage,
  personalLoan,
  medical,
  other,
}

extension DebtCategoryX on DebtCategory {
  String get label => switch (this) {
        DebtCategory.creditCard => 'Credit Card',
        DebtCategory.studentLoan => 'Student Loan',
        DebtCategory.autoLoan => 'Auto Loan',
        DebtCategory.mortgage => 'Mortgage',
        DebtCategory.personalLoan => 'Personal Loan',
        DebtCategory.medical => 'Medical',
        DebtCategory.other => 'Other',
      };

  String get emoji => switch (this) {
        DebtCategory.creditCard => '💳',
        DebtCategory.studentLoan => '🎓',
        DebtCategory.autoLoan => '🚗',
        DebtCategory.mortgage => '🏠',
        DebtCategory.personalLoan => '🤝',
        DebtCategory.medical => '🏥',
        DebtCategory.other => '📄',
      };
}
