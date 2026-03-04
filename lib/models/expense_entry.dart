import 'dart:convert';

/// Expense categories for classification.
enum ExpenseCategory {
  food,
  transport,
  housing,
  utilities,
  entertainment,
  shopping,
  health,
  education,
  travel,
  subscriptions,
  gifts,
  savings,
  income,
  other;

  String get label {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food & Dining';
      case ExpenseCategory.transport:
        return 'Transport';
      case ExpenseCategory.housing:
        return 'Housing';
      case ExpenseCategory.utilities:
        return 'Utilities';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.shopping:
        return 'Shopping';
      case ExpenseCategory.health:
        return 'Health';
      case ExpenseCategory.education:
        return 'Education';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.subscriptions:
        return 'Subscriptions';
      case ExpenseCategory.gifts:
        return 'Gifts';
      case ExpenseCategory.savings:
        return 'Savings';
      case ExpenseCategory.income:
        return 'Income';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ExpenseCategory.food:
        return '🍔';
      case ExpenseCategory.transport:
        return '🚗';
      case ExpenseCategory.housing:
        return '🏠';
      case ExpenseCategory.utilities:
        return '💡';
      case ExpenseCategory.entertainment:
        return '🎬';
      case ExpenseCategory.shopping:
        return '🛍️';
      case ExpenseCategory.health:
        return '🏥';
      case ExpenseCategory.education:
        return '📚';
      case ExpenseCategory.travel:
        return '✈️';
      case ExpenseCategory.subscriptions:
        return '📱';
      case ExpenseCategory.gifts:
        return '🎁';
      case ExpenseCategory.savings:
        return '💰';
      case ExpenseCategory.income:
        return '💵';
      case ExpenseCategory.other:
        return '📦';
    }
  }

  /// Whether this category represents money coming in rather than going out.
  bool get isIncome => this == ExpenseCategory.income;
}

/// Payment methods for tracking how money was spent.
enum PaymentMethod {
  cash,
  debit,
  credit,
  bankTransfer,
  digital,
  crypto,
  other;

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.debit:
        return 'Debit Card';
      case PaymentMethod.credit:
        return 'Credit Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.digital:
        return 'Digital Wallet';
      case PaymentMethod.crypto:
        return 'Crypto';
      case PaymentMethod.other:
        return 'Other';
    }
  }
}

/// A single expense or income entry.
class ExpenseEntry {
  final String id;
  final DateTime timestamp;
  final double amount;
  final ExpenseCategory category;
  final PaymentMethod paymentMethod;
  final String? description;
  final String? vendor;
  final List<String> tags;
  final bool isRecurring;

  const ExpenseEntry({
    required this.id,
    required this.timestamp,
    required this.amount,
    this.category = ExpenseCategory.other,
    this.paymentMethod = PaymentMethod.debit,
    this.description,
    this.vendor,
    this.tags = const [],
    this.isRecurring = false,
  });

  /// Positive = expense, negative = income (or use income category).
  bool get isExpense => !category.isIncome && amount >= 0;

  ExpenseEntry copyWith({
    String? id,
    DateTime? timestamp,
    double? amount,
    ExpenseCategory? category,
    PaymentMethod? paymentMethod,
    String? description,
    String? vendor,
    List<String>? tags,
    bool? isRecurring,
  }) {
    return ExpenseEntry(
      id: id ?? this.id,
      timestamp: timestamp ?? this.timestamp,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      description: description ?? this.description,
      vendor: vendor ?? this.vendor,
      tags: tags ?? this.tags,
      isRecurring: isRecurring ?? this.isRecurring,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'amount': amount,
      'category': category.name,
      'paymentMethod': paymentMethod.name,
      'description': description,
      'vendor': vendor,
      'tags': tags,
      'isRecurring': isRecurring,
    };
  }

  factory ExpenseEntry.fromJson(Map<String, dynamic> json) {
    return ExpenseEntry(
      id: json['id'] as String,
      timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: ExpenseCategory.values.firstWhere(
        (v) => v.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (v) => v.name == json['paymentMethod'],
        orElse: () => PaymentMethod.debit,
      ),
      description: json['description'] as String?,
      vendor: json['vendor'] as String?,
      tags: (json['tags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      isRecurring: json['isRecurring'] as bool? ?? false,
    );
  }

  static String encodeList(List<ExpenseEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<ExpenseEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => ExpenseEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
