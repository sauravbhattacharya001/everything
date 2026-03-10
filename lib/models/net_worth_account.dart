/// Represents a financial account (asset or liability) for net worth tracking.
///
/// Accounts hold [snapshots] that record balance over time, enabling
/// historical net worth analysis and trend detection.
class NetWorthAccount {
  final String id;
  final String name;
  final String emoji;
  final AccountType type;
  final AccountCategory category;
  final String? institution;
  final String? notes;
  final DateTime createdAt;
  final bool isArchived;
  final List<BalanceSnapshot> snapshots;

  NetWorthAccount({
    required this.id,
    required this.name,
    this.emoji = '💰',
    required this.type,
    this.category = AccountCategory.other,
    this.institution,
    this.notes,
    DateTime? createdAt,
    this.isArchived = false,
    List<BalanceSnapshot>? snapshots,
  })  : createdAt = createdAt ?? DateTime.now(),
        snapshots = snapshots ?? [];

  /// Most recent balance, or 0.0 if no snapshots.
  double get currentBalance {
    if (snapshots.isEmpty) return 0.0;
    final sorted = List<BalanceSnapshot>.from(snapshots)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted.first.balance;
  }

  /// Signed balance: positive for assets, negative for liabilities.
  double get signedBalance =>
      type == AccountType.asset ? currentBalance : -currentBalance;

  /// Change from previous snapshot.
  double? get lastChange {
    if (snapshots.length < 2) return null;
    final sorted = List<BalanceSnapshot>.from(snapshots)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted[0].balance - sorted[1].balance;
  }

  /// Percent change from previous snapshot.
  double? get lastChangePercent {
    if (snapshots.length < 2) return null;
    final sorted = List<BalanceSnapshot>.from(snapshots)
      ..sort((a, b) => b.date.compareTo(a.date));
    final prev = sorted[1].balance;
    if (prev == 0) return null;
    return (sorted[0].balance - prev) / prev;
  }

  /// Balance at a specific date (most recent snapshot on or before date).
  double balanceAt(DateTime date) {
    final before = snapshots
        .where((s) =>
            s.date.isBefore(date) ||
            (s.date.year == date.year &&
                s.date.month == date.month &&
                s.date.day == date.day))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    return before.isEmpty ? 0.0 : before.first.balance;
  }

  /// Days since last balance update.
  int? get daysSinceUpdate {
    if (snapshots.isEmpty) return null;
    final sorted = List<BalanceSnapshot>.from(snapshots)
      ..sort((a, b) => b.date.compareTo(a.date));
    return DateTime.now().difference(sorted.first.date).inDays;
  }

  /// Whether this account's balance is stale (>30 days since update).
  bool get isStale => (daysSinceUpdate ?? 0) > 30;

  NetWorthAccount copyWith({
    String? name,
    String? emoji,
    AccountType? type,
    AccountCategory? category,
    String? institution,
    String? notes,
    bool? isArchived,
    List<BalanceSnapshot>? snapshots,
  }) {
    return NetWorthAccount(
      id: id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      type: type ?? this.type,
      category: category ?? this.category,
      institution: institution ?? this.institution,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      isArchived: isArchived ?? this.isArchived,
      snapshots: snapshots ?? List.from(this.snapshots),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'type': type.name,
        'category': category.name,
        if (institution != null) 'institution': institution,
        if (notes != null) 'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'isArchived': isArchived,
        'snapshots': snapshots.map((s) => s.toJson()).toList(),
      };

  factory NetWorthAccount.fromJson(Map<String, dynamic> json) {
    return NetWorthAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      emoji: json['emoji'] as String? ?? '💰',
      type: AccountType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AccountType.asset,
      ),
      category: AccountCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => AccountCategory.other,
      ),
      institution: json['institution'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isArchived: json['isArchived'] as bool? ?? false,
      snapshots: (json['snapshots'] as List<dynamic>?)
              ?.map((s) =>
                  BalanceSnapshot.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  String toString() =>
      'NetWorthAccount($name, ${type.name}, \$${currentBalance.toStringAsFixed(2)})';
}

/// A point-in-time balance recording.
class BalanceSnapshot {
  final DateTime date;
  final double balance;
  final String? note;

  const BalanceSnapshot({
    required this.date,
    required this.balance,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'balance': balance,
        if (note != null) 'note': note,
      };

  factory BalanceSnapshot.fromJson(Map<String, dynamic> json) {
    return BalanceSnapshot(
      date: DateTime.parse(json['date'] as String),
      balance: (json['balance'] as num).toDouble(),
      note: json['note'] as String?,
    );
  }

  @override
  String toString() =>
      'BalanceSnapshot(${date.toIso8601String()}, \$${balance.toStringAsFixed(2)})';
}

/// Whether an account represents something you own or owe.
enum AccountType {
  asset,
  liability,
}

/// Category for grouping accounts in reports.
enum AccountCategory {
  checking,
  savings,
  investment,
  retirement,
  property,
  vehicle,
  creditCard,
  loan,
  mortgage,
  studentLoan,
  crypto,
  other,
}

/// Extension for user-friendly category labels.
extension AccountCategoryLabel on AccountCategory {
  String get label {
    switch (this) {
      case AccountCategory.checking:
        return 'Checking';
      case AccountCategory.savings:
        return 'Savings';
      case AccountCategory.investment:
        return 'Investment';
      case AccountCategory.retirement:
        return 'Retirement';
      case AccountCategory.property:
        return 'Property';
      case AccountCategory.vehicle:
        return 'Vehicle';
      case AccountCategory.creditCard:
        return 'Credit Card';
      case AccountCategory.loan:
        return 'Loan';
      case AccountCategory.mortgage:
        return 'Mortgage';
      case AccountCategory.studentLoan:
        return 'Student Loan';
      case AccountCategory.crypto:
        return 'Crypto';
      case AccountCategory.other:
        return 'Other';
    }
  }

  /// Default account type for this category.
  AccountType get defaultType {
    switch (this) {
      case AccountCategory.creditCard:
      case AccountCategory.loan:
      case AccountCategory.mortgage:
      case AccountCategory.studentLoan:
        return AccountType.liability;
      default:
        return AccountType.asset;
    }
  }

  /// Suggested emoji for this category.
  String get defaultEmoji {
    switch (this) {
      case AccountCategory.checking:
        return '🏦';
      case AccountCategory.savings:
        return '🐖';
      case AccountCategory.investment:
        return '📈';
      case AccountCategory.retirement:
        return '🏖️';
      case AccountCategory.property:
        return '🏠';
      case AccountCategory.vehicle:
        return '🚗';
      case AccountCategory.creditCard:
        return '💳';
      case AccountCategory.loan:
        return '📋';
      case AccountCategory.mortgage:
        return '🏡';
      case AccountCategory.studentLoan:
        return '🎓';
      case AccountCategory.crypto:
        return '₿';
      case AccountCategory.other:
        return '💰';
    }
  }
}
