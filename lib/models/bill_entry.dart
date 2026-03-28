/// Frequency at which a bill recurs.
enum BillFrequency {
  weekly('Weekly'),
  biweekly('Bi-weekly'),
  monthly('Monthly'),
  quarterly('Quarterly'),
  semiannual('Semi-annual'),
  annual('Annual'),
  oneTime('One-time');

  final String label;
  const BillFrequency(this.label);
}

/// Category for organizing bills.
enum BillCategory {
  housing('Housing', '🏠'),
  utilities('Utilities', '💡'),
  insurance('Insurance', '🛡️'),
  transportation('Transportation', '🚗'),
  subscriptions('Subscriptions', '📺'),
  loans('Loans & Debt', '💳'),
  education('Education', '📚'),
  health('Health', '🏥'),
  other('Other', '📋');

  final String label;
  final String emoji;
  const BillCategory(this.label, this.emoji);
}

/// Represents a single bill/recurring payment.
class BillEntry {
  final String id;
  final String name;
  final double amount;
  final BillCategory category;
  final BillFrequency frequency;
  final DateTime dueDate;
  final bool isPaid;
  final DateTime? paidDate;
  final bool autoPay;
  final String? notes;
  final String? payee;

  const BillEntry({
    required this.id,
    required this.name,
    required this.amount,
    required this.category,
    required this.frequency,
    required this.dueDate,
    this.isPaid = false,
    this.paidDate,
    this.autoPay = false,
    this.notes,
    this.payee,
  });

  BillEntry copyWith({
    String? id,
    String? name,
    double? amount,
    BillCategory? category,
    BillFrequency? frequency,
    DateTime? dueDate,
    bool? isPaid,
    DateTime? paidDate,
    bool? autoPay,
    String? notes,
    String? payee,
  }) {
    return BillEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      frequency: frequency ?? this.frequency,
      dueDate: dueDate ?? this.dueDate,
      isPaid: isPaid ?? this.isPaid,
      paidDate: paidDate ?? this.paidDate,
      autoPay: autoPay ?? this.autoPay,
      notes: notes ?? this.notes,
      payee: payee ?? this.payee,
    );
  }

  /// Whether the bill is overdue (past due date and not paid).
  bool get isOverdue =>
      !isPaid && dueDate.isBefore(DateTime.now());

  /// Days until due (negative if overdue).
  int get daysUntilDue =>
      DateTime(dueDate.year, dueDate.month, dueDate.day)
          .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
          .inDays;

  /// Whether the bill is due within the next N days.
  bool isDueSoon([int days = 7]) =>
      !isPaid && !isOverdue && daysUntilDue <= days;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'category': category.index,
        'frequency': frequency.index,
        'dueDate': dueDate.toIso8601String(),
        'isPaid': isPaid,
        'paidDate': paidDate?.toIso8601String(),
        'autoPay': autoPay,
        'notes': notes,
        'payee': payee,
      };

  factory BillEntry.fromJson(Map<String, dynamic> json) => BillEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        category: BillCategory.values[json['category'] as int],
        frequency: BillFrequency.values[json['frequency'] as int],
        dueDate: DateTime.parse(json['dueDate'] as String),
        isPaid: json['isPaid'] as bool? ?? false,
        paidDate: json['paidDate'] != null
            ? DateTime.parse(json['paidDate'] as String)
            : null,
        autoPay: json['autoPay'] as bool? ?? false,
        notes: json['notes'] as String?,
        payee: json['payee'] as String?,
      );
}
