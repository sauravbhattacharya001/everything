import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/loyalty_card.dart';
import 'package:everything/core/services/loyalty_tracker_service.dart';

void main() {
  late LoyaltyTrackerService service;

  setUp(() {
    service = LoyaltyTrackerService();
  });

  LoyaltyCard _makeCard({
    String id = 'c1',
    String name = 'TestRewards',
    RewardsProgramType type = RewardsProgramType.retail,
    PointsUnit unit = PointsUnit.points,
    double balance = 1000,
    double ltEarned = 1500,
    double ltRedeemed = 500,
    TierLevel tier = TierLevel.gold,
    double pointValue = 0.01,
    DateTime? enrollDate,
    DateTime? expiryDate,
    List<PointsTransaction> transactions = const [],
  }) {
    return LoyaltyCard(
      id: id, programName: name, type: type, unit: unit,
      currentBalance: balance, lifetimeEarned: ltEarned,
      lifetimeRedeemed: ltRedeemed, tier: tier, pointValue: pointValue,
      enrollDate: enrollDate ?? DateTime(2024, 1, 1),
      pointsExpiryDate: expiryDate, transactions: transactions,
    );
  }

  // ── Model Tests ────────────────────────────────────────

  group('LoyaltyCard model', () {
    test('dollarValue computes correctly', () {
      final card = _makeCard(balance: 5000, pointValue: 0.02);
      expect(card.dollarValue, 100.0);
    });

    test('lifetimeValue computes correctly', () {
      final card = _makeCard(ltEarned: 10000, pointValue: 0.015);
      expect(card.lifetimeValue, 150.0);
    });

    test('redemptionRate is earned/redeemed ratio', () {
      final card = _makeCard(ltEarned: 2000, ltRedeemed: 500);
      expect(card.redemptionRate, 0.25);
    });

    test('redemptionRate is 0 when nothing earned', () {
      final card = _makeCard(ltEarned: 0, ltRedeemed: 0);
      expect(card.redemptionRate, 0);
    });

    test('isExpiringWithin detects upcoming expiry', () {
      final soon = DateTime.now().add(const Duration(days: 10));
      final card = _makeCard(expiryDate: soon);
      expect(card.isExpiringWithin(30), true);
      expect(card.isExpiringWithin(5), false);
    });

    test('isExpiringWithin returns false when no expiry', () {
      final card = _makeCard(expiryDate: null);
      expect(card.isExpiringWithin(30), false);
    });

    test('isExpiringWithin returns false for past dates', () {
      final past = DateTime.now().subtract(const Duration(days: 5));
      final card = _makeCard(expiryDate: past);
      expect(card.isExpiringWithin(30), false);
    });

    test('hasBalance returns true when balance > 0', () {
      expect(_makeCard(balance: 100).hasBalance, true);
      expect(_makeCard(balance: 0).hasBalance, false);
    });

    test('copyWith preserves fields', () {
      final card = _makeCard(name: 'Original', balance: 500);
      final copy = card.copyWith(programName: 'Updated');
      expect(copy.programName, 'Updated');
      expect(copy.currentBalance, 500);
      expect(copy.id, card.id);
    });

    test('toJson / fromJson roundtrip', () {
      final card = _makeCard(
        name: 'Delta SkyMiles',
        type: RewardsProgramType.airline,
        unit: PointsUnit.miles,
        tier: TierLevel.platinum,
        transactions: [
          PointsTransaction(
            id: 'tx1', date: DateTime(2025, 6, 15), amount: 500,
            isEarn: true, description: 'Flight', category: 'Travel',
          ),
        ],
      );
      final json = card.toJson();
      final restored = LoyaltyCard.fromJson(json);
      expect(restored.programName, 'Delta SkyMiles');
      expect(restored.type, RewardsProgramType.airline);
      expect(restored.unit, PointsUnit.miles);
      expect(restored.tier, TierLevel.platinum);
      expect(restored.transactions.length, 1);
      expect(restored.transactions[0].category, 'Travel');
    });

    test('PointsTransaction toJson / fromJson', () {
      final tx = PointsTransaction(
        id: 'tx1', date: DateTime(2025, 3, 1), amount: 250,
        isEarn: false, description: 'Gift card', category: 'Rewards',
      );
      final restored = PointsTransaction.fromJson(tx.toJson());
      expect(restored.id, 'tx1');
      expect(restored.amount, 250);
      expect(restored.isEarn, false);
      expect(restored.category, 'Rewards');
    });
  });

  // ── Enum Tests ─────────────────────────────────────────

  group('Enums', () {
    test('RewardsProgramType has labels and emojis', () {
      for (final t in RewardsProgramType.values) {
        expect(t.label.isNotEmpty, true);
        expect(t.emoji.isNotEmpty, true);
      }
    });

    test('PointsUnit has labels', () {
      for (final u in PointsUnit.values) {
        expect(u.label.isNotEmpty, true);
      }
    });

    test('TierLevel has labels and ranks', () {
      expect(TierLevel.none.rank, 0);
      expect(TierLevel.diamond.rank, 5);
      expect(TierLevel.gold.rank, greaterThan(TierLevel.silver.rank));
    });
  });

  // ── CRUD Tests ─────────────────────────────────────────

  group('LoyaltyTrackerService CRUD', () {
    test('add and retrieve card', () {
      service.add(_makeCard());
      expect(service.cards.length, 1);
      expect(service.getById('c1')?.programName, 'TestRewards');
    });

    test('add rejects duplicate id', () {
      service.add(_makeCard());
      expect(() => service.add(_makeCard()), throwsArgumentError);
    });

    test('add rejects empty name', () {
      expect(() => service.add(_makeCard(name: '')), throwsArgumentError);
      expect(() => service.add(_makeCard(name: '   ')), throwsArgumentError);
    });

    test('add rejects negative point value', () {
      expect(() => service.add(_makeCard(pointValue: -0.5)),
          throwsArgumentError);
    });

    test('update replaces card', () {
      service.add(_makeCard());
      service.update('c1', _makeCard(name: 'Updated'));
      expect(service.getById('c1')?.programName, 'Updated');
    });

    test('update throws on missing id', () {
      expect(() => service.update('nope', _makeCard()), throwsArgumentError);
    });

    test('remove deletes card', () {
      service.add(_makeCard());
      service.remove('c1');
      expect(service.cards.length, 0);
      expect(service.getById('c1'), isNull);
    });

    test('remove throws on missing id', () {
      expect(() => service.remove('nope'), throwsArgumentError);
    });

    test('getById returns null for missing id', () {
      expect(service.getById('nope'), isNull);
    });
  });

  // ── Transaction Tests ──────────────────────────────────

  group('Transactions', () {
    test('earnPoints increases balance', () {
      service.add(_makeCard(balance: 100, ltEarned: 100));
      final updated = service.earnPoints('c1', 50, 'Purchase');
      expect(updated.currentBalance, 150);
      expect(updated.lifetimeEarned, 150);
      expect(updated.transactions.length, 1);
      expect(updated.transactions[0].isEarn, true);
    });

    test('earnPoints rejects zero or negative', () {
      service.add(_makeCard());
      expect(() => service.earnPoints('c1', 0, 'bad'), throwsArgumentError);
      expect(() => service.earnPoints('c1', -10, 'bad'), throwsArgumentError);
    });

    test('earnPoints throws for missing card', () {
      expect(() => service.earnPoints('nope', 50, 'x'), throwsArgumentError);
    });

    test('redeemPoints decreases balance', () {
      service.add(_makeCard(balance: 500, ltRedeemed: 0));
      final updated = service.redeemPoints('c1', 200, 'Gift card');
      expect(updated.currentBalance, 300);
      expect(updated.lifetimeRedeemed, 200);
      expect(updated.transactions.length, 1);
      expect(updated.transactions[0].isEarn, false);
    });

    test('redeemPoints rejects insufficient balance', () {
      service.add(_makeCard(balance: 100));
      expect(() => service.redeemPoints('c1', 200, 'x'), throwsStateError);
    });

    test('redeemPoints rejects zero or negative', () {
      service.add(_makeCard(balance: 100));
      expect(() => service.redeemPoints('c1', 0, 'x'), throwsArgumentError);
    });

    test('multiple transactions accumulate', () {
      service.add(_makeCard(balance: 0, ltEarned: 0, ltRedeemed: 0));
      service.earnPoints('c1', 100, 'Buy 1');
      service.earnPoints('c1', 200, 'Buy 2');
      service.redeemPoints('c1', 50, 'Use 1');
      final card = service.getById('c1')!;
      expect(card.currentBalance, 250);
      expect(card.lifetimeEarned, 300);
      expect(card.lifetimeRedeemed, 50);
      expect(card.transactions.length, 3);
    });

    test('earn with category is recorded', () {
      service.add(_makeCard(balance: 0, ltEarned: 0));
      service.earnPoints('c1', 100, 'Grocery run', category: 'Grocery');
      expect(service.getById('c1')!.transactions[0].category, 'Grocery');
    });
  });

  // ── Query Tests ────────────────────────────────────────

  group('Queries', () {
    test('getExpiryAlerts returns expiring cards', () {
      final soon = DateTime.now().add(const Duration(days: 10));
      service.add(_makeCard(id: 'exp', expiryDate: soon, balance: 500));
      service.add(_makeCard(id: 'safe', balance: 300));
      final alerts = service.getExpiryAlerts(days: 30);
      expect(alerts.length, 1);
      expect(alerts[0].card.id, 'exp');
      expect(alerts[0].atRiskValue, greaterThan(0));
    });

    test('getExpiryAlerts sorted by urgency', () {
      service.add(_makeCard(id: 'far',
          expiryDate: DateTime.now().add(const Duration(days: 25))));
      service.add(_makeCard(id: 'near',
          expiryDate: DateTime.now().add(const Duration(days: 5))));
      final alerts = service.getExpiryAlerts(days: 30);
      expect(alerts[0].card.id, 'near');
      expect(alerts[1].card.id, 'far');
    });

    test('search by name', () {
      service.add(_makeCard(id: 'a', name: 'Starbucks Stars'));
      service.add(_makeCard(id: 'b', name: 'Delta SkyMiles'));
      expect(service.search('star').length, 1);
      expect(service.search('star')[0].programName, 'Starbucks Stars');
    });

    test('search by type label', () {
      service.add(_makeCard(id: 'a', type: RewardsProgramType.airline));
      expect(service.search('airline').length, 1);
    });

    test('search empty returns all', () {
      service.add(_makeCard(id: 'a', name: 'A'));
      service.add(_makeCard(id: 'b', name: 'B'));
      expect(service.search('').length, 2);
      expect(service.search('  ').length, 2);
    });

    test('filterByType', () {
      service.add(_makeCard(id: 'a', type: RewardsProgramType.airline));
      service.add(_makeCard(id: 'b', type: RewardsProgramType.grocery));
      service.add(_makeCard(id: 'c', type: RewardsProgramType.airline));
      expect(service.filterByType(RewardsProgramType.airline).length, 2);
    });

    test('filterByTier', () {
      service.add(_makeCard(id: 'a', tier: TierLevel.gold));
      service.add(_makeCard(id: 'b', tier: TierLevel.silver));
      expect(service.filterByTier(TierLevel.gold).length, 1);
    });

    test('sortedByValue orders by dollar value desc', () {
      service.add(_makeCard(id: 'low', balance: 100, pointValue: 0.01));
      service.add(_makeCard(id: 'high', balance: 100, pointValue: 0.1));
      final sorted = service.sortedByValue();
      expect(sorted[0].id, 'high');
      expect(sorted[1].id, 'low');
    });

    test('sortedByBalance orders by balance desc', () {
      service.add(_makeCard(id: 'a', balance: 500));
      service.add(_makeCard(id: 'b', balance: 2000));
      expect(service.sortedByBalance()[0].id, 'b');
    });
  });

  // ── Analytics Tests ────────────────────────────────────

  group('Analytics', () {
    test('getSummary on empty service', () {
      final s = service.getSummary();
      expect(s.totalPrograms, 0);
      expect(s.totalDollarValue, 0);
      expect(s.averageRedemptionRate, 0);
    });

    test('getSummary computes totals', () {
      service.add(_makeCard(id: 'a', balance: 1000, ltEarned: 2000,
          ltRedeemed: 1000, pointValue: 0.01));
      service.add(_makeCard(id: 'b', balance: 5000, ltEarned: 5000,
          ltRedeemed: 0, pointValue: 0.02));
      final s = service.getSummary();
      expect(s.totalPrograms, 2);
      expect(s.totalDollarValue, 110.0);
      expect(s.lifetimeEarned, 7000);
      expect(s.highestValue?.id, 'b');
    });

    test('getTopEarningCategories aggregates correctly', () {
      final txs = [
        PointsTransaction(id: 't1', date: DateTime.now(), amount: 100,
            isEarn: true, description: 'x', category: 'Travel'),
        PointsTransaction(id: 't2', date: DateTime.now(), amount: 200,
            isEarn: true, description: 'y', category: 'Dining'),
        PointsTransaction(id: 't3', date: DateTime.now(), amount: 50,
            isEarn: false, description: 'z', category: 'Rewards'),
      ];
      service.add(_makeCard(transactions: txs));
      final cats = service.getTopEarningCategories();
      expect(cats.length, 2); // only earn transactions
      expect(cats[0].category, 'Dining');
      expect(cats[0].totalEarned, 200);
    });

    test('getUnderUtilized finds low-redemption cards', () {
      service.add(_makeCard(id: 'unused', ltEarned: 5000,
          ltRedeemed: 100, balance: 4900));
      service.add(_makeCard(id: 'used', ltEarned: 5000,
          ltRedeemed: 4000, balance: 1000));
      final u = service.getUnderUtilized(maxRedemptionRate: 0.1);
      expect(u.length, 1);
      expect(u[0].id, 'unused');
    });

    test('getUnderUtilized excludes zero-balance', () {
      service.add(_makeCard(id: 'empty', ltEarned: 1000,
          ltRedeemed: 50, balance: 0));
      expect(service.getUnderUtilized().length, 0);
    });

    test('getMonthlyTrends returns correct months', () {
      service.add(_makeCard());
      final trends = service.getMonthlyTrends(months: 3);
      expect(trends.length, 3);
      expect(trends.last.month, DateTime.now().month);
    });

    test('getMonthlyTrends aggregates transactions', () {
      final now = DateTime.now();
      final txs = [
        PointsTransaction(id: 't1',
            date: DateTime(now.year, now.month, 5),
            amount: 300, isEarn: true, description: 'buy'),
        PointsTransaction(id: 't2',
            date: DateTime(now.year, now.month, 10),
            amount: 100, isEarn: false, description: 'use'),
      ];
      service.add(_makeCard(transactions: txs));
      final trends = service.getMonthlyTrends(months: 1);
      expect(trends[0].earned, 300);
      expect(trends[0].redeemed, 100);
      expect(trends[0].netChange, 200);
    });
  });

  // ── Import / Export Tests ──────────────────────────────

  group('Import/Export', () {
    test('exportToJson produces valid JSON', () {
      service.add(_makeCard(id: 'a', name: 'Program A'));
      service.add(_makeCard(id: 'b', name: 'Program B'));
      final json = service.exportToJson();
      expect(json.contains('Program A'), true);
      expect(json.contains('Program B'), true);
    });

    test('importFromJson adds new cards', () {
      service.add(_makeCard(id: 'existing'));
      final json = service.exportToJson();
      service.clear();
      expect(service.importFromJson(json), 1);
      expect(service.cards.length, 1);
    });

    test('importFromJson skips duplicates', () {
      service.add(_makeCard(id: 'a'));
      final other = LoyaltyTrackerService();
      other.add(_makeCard(id: 'a', name: 'Dup'));
      other.add(_makeCard(id: 'b', name: 'New'));
      expect(service.importFromJson(other.exportToJson()), 1);
      expect(service.cards.length, 2);
    });

    test('clear removes all', () {
      service.add(_makeCard(id: 'a'));
      service.add(_makeCard(id: 'b'));
      service.clear();
      expect(service.cards.length, 0);
    });
  });
}
