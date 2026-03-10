import 'dart:convert';

/// Type of rewards program.
enum RewardsProgramType {
  airline, hotel, creditCard, grocery, gas, pharmacy, restaurant,
  retail, cashback, other;

  String get label {
    switch (this) {
      case RewardsProgramType.airline: return 'Airline';
      case RewardsProgramType.hotel: return 'Hotel';
      case RewardsProgramType.creditCard: return 'Credit Card';
      case RewardsProgramType.grocery: return 'Grocery';
      case RewardsProgramType.gas: return 'Gas Station';
      case RewardsProgramType.pharmacy: return 'Pharmacy';
      case RewardsProgramType.restaurant: return 'Restaurant';
      case RewardsProgramType.retail: return 'Retail';
      case RewardsProgramType.cashback: return 'Cashback';
      case RewardsProgramType.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case RewardsProgramType.airline: return '✈️';
      case RewardsProgramType.hotel: return '🏨';
      case RewardsProgramType.creditCard: return '💳';
      case RewardsProgramType.grocery: return '🛒';
      case RewardsProgramType.gas: return '⛽';
      case RewardsProgramType.pharmacy: return '💊';
      case RewardsProgramType.restaurant: return '🍽️';
      case RewardsProgramType.retail: return '🛍️';
      case RewardsProgramType.cashback: return '💰';
      case RewardsProgramType.other: return '🎁';
    }
  }
}

/// Unit of reward currency.
enum PointsUnit {
  points, miles, dollars, percent, stamps, stars;

  String get label {
    switch (this) {
      case PointsUnit.points: return 'Points';
      case PointsUnit.miles: return 'Miles';
      case PointsUnit.dollars: return 'Dollars';
      case PointsUnit.percent: return 'Percent';
      case PointsUnit.stamps: return 'Stamps';
      case PointsUnit.stars: return 'Stars';
    }
  }
}

/// Membership tier level.
enum TierLevel {
  none, basic, silver, gold, platinum, diamond;

  String get label {
    switch (this) {
      case TierLevel.none: return 'None';
      case TierLevel.basic: return 'Basic';
      case TierLevel.silver: return 'Silver';
      case TierLevel.gold: return 'Gold';
      case TierLevel.platinum: return 'Platinum';
      case TierLevel.diamond: return 'Diamond';
    }
  }

  int get rank {
    switch (this) {
      case TierLevel.none: return 0;
      case TierLevel.basic: return 1;
      case TierLevel.silver: return 2;
      case TierLevel.gold: return 3;
      case TierLevel.platinum: return 4;
      case TierLevel.diamond: return 5;
    }
  }
}

/// A single points transaction (earn or redeem).
class PointsTransaction {
  final String id;
  final DateTime date;
  final double amount;
  final bool isEarn;
  final String description;
  final String? category;

  const PointsTransaction({
    required this.id, required this.date, required this.amount,
    required this.isEarn, required this.description, this.category,
  });

  Map<String, dynamic> toJson() => {
    'id': id, 'date': date.toIso8601String(), 'amount': amount,
    'isEarn': isEarn, 'description': description, 'category': category,
  };

  factory PointsTransaction.fromJson(Map<String, dynamic> json) =>
      PointsTransaction(
        id: json['id'] as String,
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num).toDouble(),
        isEarn: json['isEarn'] as bool,
        description: json['description'] as String,
        category: json['category'] as String?,
      );
}

/// A loyalty/rewards program entry.
class LoyaltyCard {
  final String id;
  final String programName;
  final RewardsProgramType type;
  final PointsUnit unit;
  final double currentBalance;
  final double lifetimeEarned;
  final double lifetimeRedeemed;
  final TierLevel tier;
  final DateTime enrollDate;
  final DateTime? expirationDate;
  final DateTime? pointsExpiryDate;
  final double pointValue; // value per point in dollars
  final String? membershipNumber;
  final String? notes;
  final List<String> tags;
  final List<PointsTransaction> transactions;

  const LoyaltyCard({
    required this.id, required this.programName,
    this.type = RewardsProgramType.other, this.unit = PointsUnit.points,
    this.currentBalance = 0, this.lifetimeEarned = 0,
    this.lifetimeRedeemed = 0, this.tier = TierLevel.none,
    required this.enrollDate, this.expirationDate, this.pointsExpiryDate,
    this.pointValue = 0.01, this.membershipNumber, this.notes,
    this.tags = const [], this.transactions = const [],
  });

  double get dollarValue => currentBalance * pointValue;
  double get lifetimeValue => lifetimeEarned * pointValue;
  bool get hasBalance => currentBalance > 0;

  double get redemptionRate =>
      lifetimeEarned > 0 ? lifetimeRedeemed / lifetimeEarned : 0;

  bool isExpiringWithin(int days) {
    if (pointsExpiryDate == null) return false;
    final d = pointsExpiryDate!.difference(DateTime.now()).inDays;
    return d >= 0 && d <= days;
  }

  int get daysUntilExpiry {
    if (pointsExpiryDate == null) return -1;
    return pointsExpiryDate!
        .difference(DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .inDays;
  }

  LoyaltyCard copyWith({
    String? id, String? programName, RewardsProgramType? type,
    PointsUnit? unit, double? currentBalance, double? lifetimeEarned,
    double? lifetimeRedeemed, TierLevel? tier, DateTime? enrollDate,
    DateTime? expirationDate, DateTime? pointsExpiryDate,
    double? pointValue, String? membershipNumber, String? notes,
    List<String>? tags, List<PointsTransaction>? transactions,
  }) => LoyaltyCard(
    id: id ?? this.id, programName: programName ?? this.programName,
    type: type ?? this.type, unit: unit ?? this.unit,
    currentBalance: currentBalance ?? this.currentBalance,
    lifetimeEarned: lifetimeEarned ?? this.lifetimeEarned,
    lifetimeRedeemed: lifetimeRedeemed ?? this.lifetimeRedeemed,
    tier: tier ?? this.tier, enrollDate: enrollDate ?? this.enrollDate,
    expirationDate: expirationDate ?? this.expirationDate,
    pointsExpiryDate: pointsExpiryDate ?? this.pointsExpiryDate,
    pointValue: pointValue ?? this.pointValue,
    membershipNumber: membershipNumber ?? this.membershipNumber,
    notes: notes ?? this.notes, tags: tags ?? this.tags,
    transactions: transactions ?? this.transactions,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'programName': programName, 'type': type.name,
    'unit': unit.name, 'currentBalance': currentBalance,
    'lifetimeEarned': lifetimeEarned, 'lifetimeRedeemed': lifetimeRedeemed,
    'tier': tier.name, 'enrollDate': enrollDate.toIso8601String(),
    'expirationDate': expirationDate?.toIso8601String(),
    'pointsExpiryDate': pointsExpiryDate?.toIso8601String(),
    'pointValue': pointValue, 'membershipNumber': membershipNumber,
    'notes': notes, 'tags': tags,
    'transactions': transactions.map((t) => t.toJson()).toList(),
  };

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) => LoyaltyCard(
    id: json['id'] as String,
    programName: json['programName'] as String,
    type: RewardsProgramType.values.firstWhere(
        (v) => v.name == json['type'], orElse: () => RewardsProgramType.other),
    unit: PointsUnit.values.firstWhere(
        (v) => v.name == json['unit'], orElse: () => PointsUnit.points),
    currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0,
    lifetimeEarned: (json['lifetimeEarned'] as num?)?.toDouble() ?? 0,
    lifetimeRedeemed: (json['lifetimeRedeemed'] as num?)?.toDouble() ?? 0,
    tier: TierLevel.values.firstWhere(
        (v) => v.name == json['tier'], orElse: () => TierLevel.none),
    enrollDate: DateTime.parse(json['enrollDate'] as String),
    expirationDate: json['expirationDate'] != null
        ? DateTime.parse(json['expirationDate'] as String) : null,
    pointsExpiryDate: json['pointsExpiryDate'] != null
        ? DateTime.parse(json['pointsExpiryDate'] as String) : null,
    pointValue: (json['pointValue'] as num?)?.toDouble() ?? 0.01,
    membershipNumber: json['membershipNumber'] as String?,
    notes: json['notes'] as String?,
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    transactions: (json['transactions'] as List<dynamic>?)
        ?.map((t) => PointsTransaction.fromJson(t as Map<String, dynamic>))
        .toList() ?? [],
  );

  @override
  String toString() =>
      'LoyaltyCard($programName, $currentBalance ${unit.label})';
}
