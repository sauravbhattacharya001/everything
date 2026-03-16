import 'dart:convert';
import '../../models/subscription_entry.dart';

/// Alert for an upcoming subscription billing event.
class BillingAlert {
  final SubscriptionEntry subscription;
  final int daysUntil;
  final String message;
  const BillingAlert({required this.subscription, required this.daysUntil, required this.message});
}

/// Spending breakdown for a single [SubscriptionCategory].
class CategoryBreakdown {
  final SubscriptionCategory category;
  final int count;
  final double monthlyTotal;
  final double annualTotal;
  final double percentOfTotal;
  const CategoryBreakdown({required this.category, required this.count, required this.monthlyTotal, required this.annualTotal, required this.percentOfTotal});
}

/// High-level subscription portfolio summary with cost metrics and alerts.
class SubscriptionSummary {
  final int totalActive, totalPaused, totalCancelled, totalTrial;
  final double monthlySpend, annualSpend, dailySpend, averagePerSubscription, totalLifetimeSpent, totalPriceIncreaseAmount;
  final int totalPriceIncreases;
  final List<CategoryBreakdown> categoryBreakdown;
  final List<BillingAlert> upcomingBillings;
  final SubscriptionEntry? mostExpensive, cheapest;
  const SubscriptionSummary({
    required this.totalActive, required this.totalPaused, required this.totalCancelled,
    required this.totalTrial, required this.monthlySpend, required this.annualSpend,
    required this.dailySpend, required this.categoryBreakdown, required this.upcomingBillings,
    required this.averagePerSubscription, this.mostExpensive, this.cheapest,
    required this.totalLifetimeSpent, required this.totalPriceIncreases, required this.totalPriceIncreaseAmount,
  });
}

class RenewalCalendarEntry {
  final DateTime date;
  final List<SubscriptionEntry> subscriptions;
  final double totalAmount;
  const RenewalCalendarEntry({required this.date, required this.subscriptions, required this.totalAmount});
}

/// Service for managing and analyzing recurring subscriptions.
class SubscriptionTrackerService {
  final List<SubscriptionEntry> _subscriptions = [];
  List<SubscriptionEntry> get subscriptions => List.unmodifiable(_subscriptions);

  void add(SubscriptionEntry entry) {
    if (_subscriptions.any((s) => s.id == entry.id)) {
      throw ArgumentError('Subscription with id ${entry.id} already exists');
    }
    _subscriptions.add(entry);
  }

  void update(String id, SubscriptionEntry updated) {
    final idx = _subscriptions.indexWhere((s) => s.id == id);
    if (idx == -1) throw ArgumentError('Subscription $id not found');
    final old = _subscriptions[idx];
    if (old.amount != updated.amount) {
      final history = List<PriceChange>.from(updated.priceHistory)
        ..add(PriceChange(date: DateTime.now(), oldPrice: old.amount, newPrice: updated.amount));
      _subscriptions[idx] = updated.copyWith(priceHistory: history);
    } else {
      _subscriptions[idx] = updated;
    }
  }

  void remove(String id) => _subscriptions.removeWhere((s) => s.id == id);

  void cancel(String id) {
    final idx = _subscriptions.indexWhere((s) => s.id == id);
    if (idx == -1) throw ArgumentError('Subscription $id not found');
    _subscriptions[idx] = _subscriptions[idx].copyWith(status: SubscriptionStatus.cancelled, endDate: DateTime.now(), autoRenew: false);
  }

  void pause(String id) {
    final idx = _subscriptions.indexWhere((s) => s.id == id);
    if (idx == -1) throw ArgumentError('Subscription $id not found');
    _subscriptions[idx] = _subscriptions[idx].copyWith(status: SubscriptionStatus.paused);
  }

  void resume(String id) {
    final idx = _subscriptions.indexWhere((s) => s.id == id);
    if (idx == -1) throw ArgumentError('Subscription $id not found');
    _subscriptions[idx] = _subscriptions[idx].copyWith(status: SubscriptionStatus.active);
  }

  SubscriptionEntry? getById(String id) {
    try { return _subscriptions.firstWhere((s) => s.id == id); } catch (_) { return null; }
  }

  List<SubscriptionEntry> byStatus(SubscriptionStatus status) => _subscriptions.where((s) => s.status == status).toList();
  List<SubscriptionEntry> byCategory(SubscriptionCategory category) => _subscriptions.where((s) => s.category == category).toList();
  List<SubscriptionEntry> byTag(String tag) {
    final lower = tag.toLowerCase();
    return _subscriptions.where((s) => s.tags.any((t) => t.toLowerCase() == lower)).toList();
  }
  List<SubscriptionEntry> search(String query) {
    final lower = query.toLowerCase();
    return _subscriptions.where((s) => s.name.toLowerCase().contains(lower)).toList();
  }
  List<SubscriptionEntry> get active => _subscriptions.where((s) => s.status == SubscriptionStatus.active || s.status == SubscriptionStatus.trial).toList();

  double get totalMonthlySpend => active.fold(0.0, (sum, s) => sum + s.monthlyCost);
  double get totalAnnualSpend => active.fold(0.0, (sum, s) => sum + s.annualCost);

  List<CategoryBreakdown> getCategoryBreakdown() {
    final activeSubs = active;
    if (activeSubs.isEmpty) return [];
    final totalMonthly = totalMonthlySpend;
    final grouped = <SubscriptionCategory, List<SubscriptionEntry>>{};
    for (final s in activeSubs) grouped.putIfAbsent(s.category, () => []).add(s);
    final result = grouped.entries.map((e) {
      final monthly = e.value.fold(0.0, (sum, s) => sum + s.monthlyCost);
      return CategoryBreakdown(category: e.key, count: e.value.length, monthlyTotal: monthly, annualTotal: monthly * 12, percentOfTotal: totalMonthly > 0 ? (monthly / totalMonthly) * 100 : 0);
    }).toList()..sort((a, b) => b.monthlyTotal.compareTo(a.monthlyTotal));
    return result;
  }

  List<BillingAlert> getUpcomingBillings({int withinDays = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final alerts = <BillingAlert>[];
    for (final s in active) {
      final days = s.nextBillingDate.difference(today).inDays;
      if (days >= 0 && days <= withinDays) {
        final msg = days == 0
            ? '${s.name} bills today (\$${s.amount.toStringAsFixed(2)})'
            : '${s.name} bills in $days day${days == 1 ? '' : 's'} (\$${s.amount.toStringAsFixed(2)})';
        alerts.add(BillingAlert(subscription: s, daysUntil: days, message: msg));
      }
    }
    return alerts..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
  }

  List<BillingAlert> getExpiringTrials({int withinDays = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _subscriptions
        .where((s) => s.status == SubscriptionStatus.trial && s.trialEndDate != null)
        .map((s) {
          final days = s.trialEndDate!.difference(today).inDays;
          return (days >= 0 && days <= withinDays) ? BillingAlert(subscription: s, daysUntil: days, message: '${s.name} trial ends in $days day${days == 1 ? '' : 's'}') : null;
        }).whereType<BillingAlert>().toList()..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
  }

  List<SubscriptionEntry> get sortedByCost => List<SubscriptionEntry>.from(active)..sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));

  List<List<SubscriptionEntry>> detectPotentialDuplicates() {
    final activeSubs = active;
    final groups = <List<SubscriptionEntry>>[];
    final used = <String>{};
    for (var i = 0; i < activeSubs.length; i++) {
      if (used.contains(activeSubs[i].id)) continue;
      final group = [activeSubs[i]];
      for (var j = i + 1; j < activeSubs.length; j++) {
        if (used.contains(activeSubs[j].id)) continue;
        if (_areSimilar(activeSubs[i], activeSubs[j])) { group.add(activeSubs[j]); used.add(activeSubs[j].id); }
      }
      if (group.length > 1) { used.add(activeSubs[i].id); groups.add(group); }
    }
    return groups;
  }

  bool _areSimilar(SubscriptionEntry a, SubscriptionEntry b) {
    if (a.category == b.category && (a.monthlyCost - b.monthlyCost).abs() < 3.0) return true;
    final na = a.name.toLowerCase(), nb = b.name.toLowerCase();
    return na.contains(nb) || nb.contains(na);
  }

  List<RenewalCalendarEntry> getRenewalCalendar({int days = 30}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final calendar = <DateTime, List<SubscriptionEntry>>{};
    for (final s in active) {
      var nextDate = s.nextBillingDate;
      while (nextDate.isBefore(today)) nextDate = s.cycle.advanceDate(nextDate);
      final end = today.add(Duration(days: days));
      while (!nextDate.isAfter(end)) {
        final key = DateTime(nextDate.year, nextDate.month, nextDate.day);
        calendar.putIfAbsent(key, () => []).add(s);
        nextDate = s.cycle.advanceDate(nextDate);
      }
    }
    return calendar.entries.map((e) => RenewalCalendarEntry(date: e.key, subscriptions: e.value, totalAmount: e.value.fold(0.0, (sum, s) => sum + s.amount))).toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Map<String, dynamic> getPriceIncreaseAnalysis() {
    var totalIncreases = 0; var totalAmount = 0.0;
    final details = <Map<String, dynamic>>[];
    for (final s in _subscriptions) {
      final increases = s.priceHistory.where((p) => p.newPrice > p.oldPrice).toList();
      if (increases.isNotEmpty) {
        totalIncreases += increases.length;
        final sum = increases.fold(0.0, (s, p) => s + p.changeAmount);
        totalAmount += sum;
        details.add({'name': s.name, 'increases': increases.length, 'totalIncrease': sum, 'currentPrice': s.amount});
      }
    }
    return {'totalIncreases': totalIncreases, 'totalIncreaseAmount': totalAmount, 'affectedSubscriptions': details.length, 'details': details};
  }

  SubscriptionSummary getSummary({int alertDays = 7}) {
    final activeSubs = active;
    final ms = totalMonthlySpend;
    final sorted = List<SubscriptionEntry>.from(activeSubs)..sort((a, b) => b.monthlyCost.compareTo(a.monthlyCost));
    final pa = getPriceIncreaseAnalysis();
    return SubscriptionSummary(
      totalActive: byStatus(SubscriptionStatus.active).length, totalPaused: byStatus(SubscriptionStatus.paused).length,
      totalCancelled: byStatus(SubscriptionStatus.cancelled).length, totalTrial: byStatus(SubscriptionStatus.trial).length,
      monthlySpend: ms, annualSpend: totalAnnualSpend, dailySpend: totalAnnualSpend / 365.0,
      categoryBreakdown: getCategoryBreakdown(), upcomingBillings: getUpcomingBillings(withinDays: alertDays),
      averagePerSubscription: activeSubs.isNotEmpty ? ms / activeSubs.length : 0,
      mostExpensive: sorted.isNotEmpty ? sorted.first : null, cheapest: sorted.isNotEmpty ? sorted.last : null,
      totalLifetimeSpent: _subscriptions.fold(0.0, (sum, s) => sum + s.totalSpent),
      totalPriceIncreases: pa['totalIncreases'] as int, totalPriceIncreaseAmount: pa['totalIncreaseAmount'] as double,
    );
  }

  List<String> getOptimizationSuggestions() {
    final suggestions = <String>[];
    for (final s in active) {
      if (s.cycle == BillingCycle.monthly && s.monthlyCost > 5) suggestions.add('Consider switching ${s.name} to annual billing - many services offer 15-20% discounts.');
      if (s.monthlyCost > 50) suggestions.add('${s.name} costs \$${s.monthlyCost.toStringAsFixed(2)}/mo (\$${s.annualCost.toStringAsFixed(2)}/yr) - worth reviewing.');
    }
    for (final group in detectPotentialDuplicates()) suggestions.add('Potential overlap: ${group.map((s) => s.name).join(', ')} - consider consolidating.');
    for (final t in byStatus(SubscriptionStatus.trial)) suggestions.add('${t.name} is on trial - decide before it converts to paid.');
    for (final cat in getCategoryBreakdown()) {
      if (cat.percentOfTotal > 40 && cat.count > 2) suggestions.add('${cat.category.label} = ${cat.percentOfTotal.toStringAsFixed(0)}% of spending (${cat.count} subs) - look for bundles.');
    }
    return suggestions;
  }

  String getTextSummary() {
    final s = getSummary();
    final b = StringBuffer()
      ..writeln('=== Subscription Tracker Summary ===')..writeln()
      ..writeln('Active: ${s.totalActive} | Paused: ${s.totalPaused} | Trial: ${s.totalTrial} | Cancelled: ${s.totalCancelled}')..writeln()
      ..writeln('Monthly spend: \$${s.monthlySpend.toStringAsFixed(2)}')
      ..writeln('Annual spend:  \$${s.annualSpend.toStringAsFixed(2)}')
      ..writeln('Daily spend:   \$${s.dailySpend.toStringAsFixed(2)}')
      ..writeln('Avg per sub:   \$${s.averagePerSubscription.toStringAsFixed(2)}/mo')..writeln();
    if (s.mostExpensive != null) b.writeln('Most expensive: ${s.mostExpensive!.name} (\$${s.mostExpensive!.monthlyCost.toStringAsFixed(2)}/mo)');
    if (s.cheapest != null) b.writeln('Cheapest: ${s.cheapest!.name} (\$${s.cheapest!.monthlyCost.toStringAsFixed(2)}/mo)');
    b.writeln()..writeln('--- By Category ---');
    for (final cat in s.categoryBreakdown) b.writeln('  ${cat.category.label}: ${cat.count} subs, \$${cat.monthlyTotal.toStringAsFixed(2)}/mo (${cat.percentOfTotal.toStringAsFixed(1)}%)');
    if (s.upcomingBillings.isNotEmpty) { b.writeln()..writeln('--- Upcoming Billings (7 days) ---'); for (final a in s.upcomingBillings) b.writeln('  ${a.message}'); }
    b.writeln()..writeln('Lifetime spent: \$${s.totalLifetimeSpent.toStringAsFixed(2)}');
    if (s.totalPriceIncreases > 0) b.writeln('Price increases: ${s.totalPriceIncreases} (+\$${s.totalPriceIncreaseAmount.toStringAsFixed(2)} total)');
    return b.toString();
  }

  String toJson() => jsonEncode(_subscriptions.map((s) => s.toJson()).toList());

  /// Maximum entries allowed via [loadFromJson].
  ///
  /// Prevents memory exhaustion (CWE-770) from oversized or malicious
  /// import data.  50 000 subscriptions is well above any realistic
  /// usage while still fitting comfortably in memory.
  static const int maxImportEntries = 50000;

  void loadFromJson(String json) {
    // Parse into a temporary list first - if the JSON is malformed,
    // existing subscriptions are preserved instead of being wiped.
    final list = jsonDecode(json) as List<dynamic>;
    if (list.length > maxImportEntries) {
      throw ArgumentError(
        'Import exceeds maximum of $maxImportEntries entries '
        '(got ${list.length}). This limit prevents memory exhaustion '
        'from corrupted or malicious data.',
      );
    }
    final parsed = <SubscriptionEntry>[];
    for (final item in list) {
      parsed.add(SubscriptionEntry.fromJson(item as Map<String, dynamic>));
    }
    _subscriptions.clear();
    _subscriptions.addAll(parsed);
  }
}
