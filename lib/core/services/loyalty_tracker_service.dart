import 'dart:convert';
import '../../models/loyalty_card.dart';

/// Alert for expiring points or membership.
class ExpiryAlert {
  final LoyaltyCard card;
  final int daysUntil;
  final String message;
  final double atRiskValue;
  const ExpiryAlert({
    required this.card, required this.daysUntil,
    required this.message, required this.atRiskValue,
  });
}

/// Breakdown by program type.
class TypeBreakdown {
  final RewardsProgramType type;
  final int count;
  final double totalBalance;
  final double totalValue;
  final double percentOfValue;
  const TypeBreakdown({
    required this.type, required this.count, required this.totalBalance,
    required this.totalValue, required this.percentOfValue,
  });
}

/// Monthly earning/redeeming trend.
class MonthlyTrend {
  final int year;
  final int month;
  final double earned;
  final double redeemed;
  final double netChange;
  const MonthlyTrend({
    required this.year, required this.month,
    required this.earned, required this.redeemed, required this.netChange,
  });
}

/// Top earning category insight.
class EarningCategory {
  final String category;
  final double totalEarned;
  final int transactionCount;
  final double percentOfTotal;
  const EarningCategory({
    required this.category, required this.totalEarned,
    required this.transactionCount, required this.percentOfTotal,
  });
}

/// Portfolio-wide summary of all loyalty programs.
class LoyaltyPortfolioSummary {
  final int totalPrograms;
  final int activePrograms;
  final double totalPointsBalance;
  final double totalDollarValue;
  final double lifetimeEarned;
  final double lifetimeRedeemed;
  final double averageRedemptionRate;
  final int expiringWithin30Days;
  final double expiringValue;
  final List<TypeBreakdown> typeBreakdown;
  final List<ExpiryAlert> expiryAlerts;
  final LoyaltyCard? highestValue;
  final LoyaltyCard? mostActive;
  const LoyaltyPortfolioSummary({
    required this.totalPrograms, required this.activePrograms,
    required this.totalPointsBalance, required this.totalDollarValue,
    required this.lifetimeEarned, required this.lifetimeRedeemed,
    required this.averageRedemptionRate, required this.expiringWithin30Days,
    required this.expiringValue, required this.typeBreakdown,
    required this.expiryAlerts, this.highestValue, this.mostActive,
  });
}

/// Service for managing loyalty/rewards programs.
///
/// Features:
///   - CRUD for loyalty cards
///   - Record earning & redemption transactions
///   - Points expiry alerts
///   - Portfolio summary & analytics
///   - Type breakdown & category insights
///   - Monthly earning/redemption trends
///   - Search and filter
///   - JSON import/export
class LoyaltyTrackerService {
  final List<LoyaltyCard> _cards = [];
  List<LoyaltyCard> get cards => List.unmodifiable(_cards);

  // ── CRUD ────────────────────────────────────────────────

  void add(LoyaltyCard card) {
    if (card.programName.trim().isEmpty) {
      throw ArgumentError('Program name cannot be empty');
    }
    if (_cards.any((c) => c.id == card.id)) {
      throw ArgumentError('Card with id ${card.id} already exists');
    }
    if (card.pointValue < 0) {
      throw ArgumentError('Point value cannot be negative');
    }
    _cards.add(card);
  }

  void update(String id, LoyaltyCard updated) {
    final idx = _cards.indexWhere((c) => c.id == id);
    if (idx == -1) throw ArgumentError('Card $id not found');
    _cards[idx] = updated;
  }

  void remove(String id) {
    final idx = _cards.indexWhere((c) => c.id == id);
    if (idx == -1) throw ArgumentError('Card $id not found');
    _cards.removeAt(idx);
  }

  LoyaltyCard? getById(String id) {
    final idx = _cards.indexWhere((c) => c.id == id);
    return idx == -1 ? null : _cards[idx];
  }

  // ── Transactions ────────────────────────────────────────

  LoyaltyCard earnPoints(String cardId, double amount, String description,
      {String? category}) {
    if (amount <= 0) throw ArgumentError('Earn amount must be positive');
    final card = getById(cardId);
    if (card == null) throw ArgumentError('Card $cardId not found');

    final tx = PointsTransaction(
      id: '${cardId}_tx_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(), amount: amount, isEarn: true,
      description: description, category: category,
    );

    final updated = card.copyWith(
      currentBalance: card.currentBalance + amount,
      lifetimeEarned: card.lifetimeEarned + amount,
      transactions: [...card.transactions, tx],
    );
    update(cardId, updated);
    return updated;
  }

  LoyaltyCard redeemPoints(String cardId, double amount, String description,
      {String? category}) {
    if (amount <= 0) throw ArgumentError('Redeem amount must be positive');
    final card = getById(cardId);
    if (card == null) throw ArgumentError('Card $cardId not found');
    if (card.currentBalance < amount) {
      throw StateError(
          'Insufficient balance: ${card.currentBalance} < $amount');
    }

    final tx = PointsTransaction(
      id: '${cardId}_tx_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(), amount: amount, isEarn: false,
      description: description, category: category,
    );

    final updated = card.copyWith(
      currentBalance: card.currentBalance - amount,
      lifetimeRedeemed: card.lifetimeRedeemed + amount,
      transactions: [...card.transactions, tx],
    );
    update(cardId, updated);
    return updated;
  }

  // ── Queries ─────────────────────────────────────────────

  List<ExpiryAlert> getExpiryAlerts({int days = 30}) {
    return _cards
        .where((c) => c.isExpiringWithin(days))
        .map((c) => ExpiryAlert(
              card: c, daysUntil: c.daysUntilExpiry,
              message: '${c.programName}: ${c.currentBalance.toStringAsFixed(0)} '
                  '${c.unit.label} expire in ${c.daysUntilExpiry} days '
                  '(\$${c.dollarValue.toStringAsFixed(2)} value)',
              atRiskValue: c.dollarValue,
            ))
        .toList()
      ..sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
  }

  List<LoyaltyCard> search(String query) {
    final q = query.toLowerCase().trim();
    if (q.isEmpty) return List.unmodifiable(_cards);
    return _cards.where((c) {
      return c.programName.toLowerCase().contains(q) ||
          (c.notes?.toLowerCase().contains(q) ?? false) ||
          c.tags.any((t) => t.toLowerCase().contains(q)) ||
          c.type.label.toLowerCase().contains(q);
    }).toList();
  }

  List<LoyaltyCard> filterByType(RewardsProgramType type) =>
      _cards.where((c) => c.type == type).toList();

  List<LoyaltyCard> filterByTier(TierLevel tier) =>
      _cards.where((c) => c.tier == tier).toList();

  List<LoyaltyCard> sortedByValue() =>
      List.of(_cards)..sort((a, b) => b.dollarValue.compareTo(a.dollarValue));

  List<LoyaltyCard> sortedByBalance() =>
      List.of(_cards)..sort((a, b) => b.currentBalance.compareTo(a.currentBalance));

  // ── Analytics ───────────────────────────────────────────

  LoyaltyPortfolioSummary getSummary() {
    final alerts = getExpiryAlerts();
    final byType = _getTypeBreakdown();
    double totalBalance = 0, totalValue = 0, totalLtEarned = 0,
        totalLtRedeemed = 0, redemptionSum = 0;
    int activeCount = 0, maxTx = 0;
    LoyaltyCard? highestVal, mostActive;

    for (final c in _cards) {
      totalBalance += c.currentBalance;
      totalValue += c.dollarValue;
      totalLtEarned += c.lifetimeEarned;
      totalLtRedeemed += c.lifetimeRedeemed;
      redemptionSum += c.redemptionRate;
      if (c.daysUntilExpiry != 0) activeCount++;
      if (highestVal == null || c.dollarValue > highestVal.dollarValue) {
        highestVal = c;
      }
      if (c.transactions.length > maxTx) {
        maxTx = c.transactions.length;
        mostActive = c;
      }
    }

    return LoyaltyPortfolioSummary(
      totalPrograms: _cards.length, activePrograms: activeCount,
      totalPointsBalance: totalBalance, totalDollarValue: totalValue,
      lifetimeEarned: totalLtEarned, lifetimeRedeemed: totalLtRedeemed,
      averageRedemptionRate: _cards.isNotEmpty
          ? redemptionSum / _cards.length : 0,
      expiringWithin30Days: alerts.length,
      expiringValue: alerts.fold(0.0, (sum, a) => sum + a.atRiskValue),
      typeBreakdown: byType, expiryAlerts: alerts,
      highestValue: highestVal, mostActive: mostActive,
    );
  }

  List<TypeBreakdown> _getTypeBreakdown() {
    final totalValue = _cards.fold(0.0, (sum, c) => sum + c.dollarValue);
    final grouped = <RewardsProgramType, List<LoyaltyCard>>{};
    for (final c in _cards) {
      grouped.putIfAbsent(c.type, () => []).add(c);
    }
    return grouped.entries.map((e) {
      final gv = e.value.fold(0.0, (sum, c) => sum + c.dollarValue);
      final gb = e.value.fold(0.0, (sum, c) => sum + c.currentBalance);
      return TypeBreakdown(
        type: e.key, count: e.value.length, totalBalance: gb,
        totalValue: gv,
        percentOfValue: totalValue > 0 ? (gv / totalValue * 100) : 0,
      );
    }).toList()
      ..sort((a, b) => b.totalValue.compareTo(a.totalValue));
  }

  List<MonthlyTrend> getMonthlyTrends({int months = 6}) {
    final now = DateTime.now();
    final results = <MonthlyTrend>[];
    for (var i = months - 1; i >= 0; i--) {
      final target = DateTime(now.year, now.month - i, 1);
      double earned = 0, redeemed = 0;
      for (final card in _cards) {
        for (final tx in card.transactions) {
          if (tx.date.year == target.year && tx.date.month == target.month) {
            if (tx.isEarn) { earned += tx.amount; }
            else { redeemed += tx.amount; }
          }
        }
      }
      results.add(MonthlyTrend(
        year: target.year, month: target.month,
        earned: earned, redeemed: redeemed, netChange: earned - redeemed,
      ));
    }
    return results;
  }

  List<EarningCategory> getTopEarningCategories() {
    final catTotals = <String, double>{};
    final catCounts = <String, int>{};
    for (final card in _cards) {
      for (final tx in card.transactions) {
        if (tx.isEarn) {
          final cat = tx.category ?? 'Uncategorized';
          catTotals[cat] = (catTotals[cat] ?? 0) + tx.amount;
          catCounts[cat] = (catCounts[cat] ?? 0) + 1;
        }
      }
    }
    final total = catTotals.values.fold(0.0, (s, v) => s + v);
    return catTotals.entries.map((e) => EarningCategory(
      category: e.key, totalEarned: e.value,
      transactionCount: catCounts[e.key] ?? 0,
      percentOfTotal: total > 0 ? (e.value / total * 100) : 0,
    )).toList()
      ..sort((a, b) => b.totalEarned.compareTo(a.totalEarned));
  }

  List<LoyaltyCard> getUnderUtilized({double maxRedemptionRate = 0.1}) =>
      _cards.where((c) =>
          c.lifetimeEarned > 0 &&
          c.redemptionRate < maxRedemptionRate &&
          c.currentBalance > 0).toList()
        ..sort((a, b) => b.dollarValue.compareTo(a.dollarValue));

  // ── Import / Export ─────────────────────────────────────

  String exportToJson() =>
      const JsonEncoder.withIndent('  ')
          .convert(_cards.map((c) => c.toJson()).toList());

  /// Maximum entries allowed via [importFromJson] to prevent memory exhaustion.
  static const int maxImportEntries = 50000;

  int importFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    if (list.length > maxImportEntries) {
      throw ArgumentError(
        'Import exceeds maximum of $maxImportEntries entries '
        '(got ${list.length}). This limit prevents memory exhaustion '
        'from corrupted or malicious data.',
      );
    }
    int imported = 0;
    for (final item in list) {
      final card = LoyaltyCard.fromJson(item as Map<String, dynamic>);
      if (!_cards.any((c) => c.id == card.id)) {
        _cards.add(card);
        imported++;
      }
    }
    return imported;
  }

  void clear() => _cards.clear();
}
