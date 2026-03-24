import 'dart:convert';
import 'package:everything/core/utils/date_utils.dart';

/// Billing frequency for subscriptions.
enum BillingCycle {
  weekly,
  biweekly,
  monthly,
  quarterly,
  semiannual,
  annual;

  String get label {
    switch (this) {
      case BillingCycle.weekly: return 'Weekly';
      case BillingCycle.biweekly: return 'Bi-weekly';
      case BillingCycle.monthly: return 'Monthly';
      case BillingCycle.quarterly: return 'Quarterly';
      case BillingCycle.semiannual: return 'Semi-annual';
      case BillingCycle.annual: return 'Annual';
    }
  }

  double get periodsPerYear {
    switch (this) {
      case BillingCycle.weekly: return 52.0;
      case BillingCycle.biweekly: return 26.0;
      case BillingCycle.monthly: return 12.0;
      case BillingCycle.quarterly: return 4.0;
      case BillingCycle.semiannual: return 2.0;
      case BillingCycle.annual: return 1.0;
    }
  }

  int get daysBetween {
    switch (this) {
      case BillingCycle.weekly: return 7;
      case BillingCycle.biweekly: return 14;
      case BillingCycle.monthly: return 30;
      case BillingCycle.quarterly: return 91;
      case BillingCycle.semiannual: return 182;
      case BillingCycle.annual: return 365;
    }
  }

  /// Advance a date by one billing period using calendar-aware arithmetic.
  ///
  /// For monthly/quarterly/semi-annual/annual cycles, advances by the
  /// correct number of calendar months (or years) rather than a fixed
  /// day count.  Clamps the day to the last day of the target month to
  /// handle end-of-month edge cases (e.g., Jan 31 → Feb 28).
  DateTime advanceDate(DateTime date) {
    switch (this) {
      case BillingCycle.weekly:
        return date.add(const Duration(days: 7));
      case BillingCycle.biweekly:
        return date.add(const Duration(days: 14));
      case BillingCycle.monthly:
        return _addMonths(date, 1);
      case BillingCycle.quarterly:
        return _addMonths(date, 3);
      case BillingCycle.semiannual:
        return _addMonths(date, 6);
      case BillingCycle.annual:
        return _addMonths(date, 12);
    }
  }

  /// Add [months] calendar months, clamping day to end-of-month.
  static DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.month + months;
    final year = date.year + (totalMonths - 1) ~/ 12;
    final month = (totalMonths - 1) % 12 + 1;
    // Clamp day to last day of target month (handles Jan 31 → Feb 28)
    final maxDay = DateTime(year, month + 1, 0).day;
    final day = date.day > maxDay ? maxDay : date.day;
    return DateTime(year, month, day, date.hour, date.minute, date.second);
  }
}

enum SubscriptionCategory {
  streaming, music, gaming, software, cloud, news, fitness,
  food, education, finance, productivity, social, other;

  String get label {
    switch (this) {
      case SubscriptionCategory.streaming: return 'Streaming';
      case SubscriptionCategory.music: return 'Music';
      case SubscriptionCategory.gaming: return 'Gaming';
      case SubscriptionCategory.software: return 'Software';
      case SubscriptionCategory.cloud: return 'Cloud Storage';
      case SubscriptionCategory.news: return 'News & Media';
      case SubscriptionCategory.fitness: return 'Fitness';
      case SubscriptionCategory.food: return 'Food & Delivery';
      case SubscriptionCategory.education: return 'Education';
      case SubscriptionCategory.finance: return 'Finance';
      case SubscriptionCategory.productivity: return 'Productivity';
      case SubscriptionCategory.social: return 'Social';
      case SubscriptionCategory.other: return 'Other';
    }
  }
}

enum SubscriptionStatus {
  active, paused, cancelled, trial, expired;

  String get label {
    switch (this) {
      case SubscriptionStatus.active: return 'Active';
      case SubscriptionStatus.paused: return 'Paused';
      case SubscriptionStatus.cancelled: return 'Cancelled';
      case SubscriptionStatus.trial: return 'Trial';
      case SubscriptionStatus.expired: return 'Expired';
    }
  }
}

class SubscriptionEntry {
  final String id;
  final String name;
  final double amount;
  final BillingCycle cycle;
  final SubscriptionCategory category;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? trialEndDate;
  final DateTime nextBillingDate;
  final String? notes;
  final List<String> tags;
  final String? url;
  final bool autoRenew;
  final List<PriceChange> priceHistory;

  const SubscriptionEntry({
    required this.id, required this.name, required this.amount,
    required this.cycle, this.category = SubscriptionCategory.other,
    this.status = SubscriptionStatus.active, required this.startDate,
    this.endDate, this.trialEndDate, required this.nextBillingDate,
    this.notes, this.tags = const [], this.url, this.autoRenew = true,
    this.priceHistory = const [],
  });

  double get annualCost => amount * cycle.periodsPerYear;
  double get monthlyCost => annualCost / 12.0;
  double get dailyCost => annualCost / 365.0;

  bool get isInTrial {
    if (status != SubscriptionStatus.trial || trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  int get daysUntilNextBilling {
    final now = DateTime.now();
    return nextBillingDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  double get totalSpent {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0;
    // Count billing periods using calendar-aware advancement
    var cursor = startDate;
    var periods = 0;
    while (true) {
      final next = cycle.advanceDate(cursor);
      if (next.isAfter(now)) break;
      periods++;
      cursor = next;
    }
    return periods * amount;
  }

  SubscriptionEntry copyWith({
    String? id, String? name, double? amount, BillingCycle? cycle,
    SubscriptionCategory? category, SubscriptionStatus? status,
    DateTime? startDate, DateTime? endDate, DateTime? trialEndDate,
    DateTime? nextBillingDate, String? notes, List<String>? tags,
    String? url, bool? autoRenew, List<PriceChange>? priceHistory,
  }) => SubscriptionEntry(
    id: id ?? this.id, name: name ?? this.name,
    amount: amount ?? this.amount, cycle: cycle ?? this.cycle,
    category: category ?? this.category, status: status ?? this.status,
    startDate: startDate ?? this.startDate, endDate: endDate ?? this.endDate,
    trialEndDate: trialEndDate ?? this.trialEndDate,
    nextBillingDate: nextBillingDate ?? this.nextBillingDate,
    notes: notes ?? this.notes, tags: tags ?? this.tags,
    url: url ?? this.url, autoRenew: autoRenew ?? this.autoRenew,
    priceHistory: priceHistory ?? this.priceHistory,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'amount': amount, 'cycle': cycle.name,
    'category': category.name, 'status': status.name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'trialEndDate': trialEndDate?.toIso8601String(),
    'nextBillingDate': nextBillingDate.toIso8601String(),
    'notes': notes, 'tags': tags, 'url': url, 'autoRenew': autoRenew,
    'priceHistory': priceHistory.map((p) => p.toJson()).toList(),
  };

  factory SubscriptionEntry.fromJson(Map<String, dynamic> json) => SubscriptionEntry(
    id: json['id'] as String, name: json['name'] as String,
    amount: (json['amount'] as num).toDouble(),
    cycle: BillingCycle.values.firstWhere((v) => v.name == json['cycle'], orElse: () => BillingCycle.monthly),
    category: SubscriptionCategory.values.firstWhere((v) => v.name == json['category'], orElse: () => SubscriptionCategory.other),
    status: SubscriptionStatus.values.firstWhere((v) => v.name == json['status'], orElse: () => SubscriptionStatus.active),
    startDate: AppDateUtils.safeParse(json['startDate'] as String?),
    endDate: AppDateUtils.safeParseNullable(json['endDate'] as String?),
    trialEndDate: AppDateUtils.safeParseNullable(json['trialEndDate'] as String?),
    nextBillingDate: AppDateUtils.safeParse(json['nextBillingDate'] as String?),
    notes: json['notes'] as String?, tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    url: json['url'] as String?, autoRenew: json['autoRenew'] as bool? ?? true,
    priceHistory: (json['priceHistory'] as List<dynamic>?)?.map((p) => PriceChange.fromJson(p as Map<String, dynamic>)).toList() ?? [],
  );

  @override
  String toString() => 'SubscriptionEntry($name, \$$amount/${cycle.label})';
}

class PriceChange {
  final DateTime date;
  final double oldPrice;
  final double newPrice;
  final String? reason;

  const PriceChange({required this.date, required this.oldPrice, required this.newPrice, this.reason});

  double get changeAmount => newPrice - oldPrice;
  double get changePercent => oldPrice > 0 ? (changeAmount / oldPrice) * 100 : 0;

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(), 'oldPrice': oldPrice, 'newPrice': newPrice, 'reason': reason,
  };

  factory PriceChange.fromJson(Map<String, dynamic> json) => PriceChange(
    date: AppDateUtils.safeParse(json['date'] as String?),
    oldPrice: (json['oldPrice'] as num).toDouble(),
    newPrice: (json['newPrice'] as num).toDouble(),
    reason: json['reason'] as String?,
  );
}
