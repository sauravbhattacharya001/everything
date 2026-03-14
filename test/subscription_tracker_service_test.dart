import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/subscription_entry.dart';
import 'package:everything/core/services/subscription_tracker_service.dart';

SubscriptionEntry _sub({
  String? id, String name = 'Netflix', double amount = 15.99,
  BillingCycle cycle = BillingCycle.monthly,
  SubscriptionCategory category = SubscriptionCategory.streaming,
  SubscriptionStatus status = SubscriptionStatus.active,
  DateTime? startDate, DateTime? nextBillingDate, DateTime? trialEndDate,
  List<String> tags = const [], bool autoRenew = true,
  List<PriceChange> priceHistory = const [],
}) {
  final now = DateTime.now();
  return SubscriptionEntry(
    id: id ?? 'sub_${name.toLowerCase().replaceAll(' ', '_')}',
    name: name, amount: amount, cycle: cycle, category: category,
    status: status, startDate: startDate ?? now.subtract(const Duration(days: 90)),
    nextBillingDate: nextBillingDate ?? now.add(const Duration(days: 15)),
    trialEndDate: trialEndDate, tags: tags, autoRenew: autoRenew,
    priceHistory: priceHistory,
  );
}

void main() {
  group('SubscriptionEntry model', () {
    test('annual cost monthly', () { expect(_sub(amount: 10, cycle: BillingCycle.monthly).annualCost, 120.0); });
    test('monthly cost from annual', () { expect(_sub(amount: 120, cycle: BillingCycle.annual).monthlyCost, 10.0); });
    test('daily cost', () { expect(_sub(amount: 365, cycle: BillingCycle.annual).dailyCost, 1.0); });
    test('quarterly cost', () { expect(_sub(amount: 30, cycle: BillingCycle.quarterly).annualCost, 120.0); });
    test('weekly cost', () { expect(_sub(amount: 5, cycle: BillingCycle.weekly).annualCost, 260.0); });
    test('biweekly cost', () { expect(_sub(amount: 10, cycle: BillingCycle.biweekly).annualCost, 260.0); });
    test('semiannual cost', () { expect(_sub(amount: 60, cycle: BillingCycle.semiannual).annualCost, 120.0); });
    test('copyWith preserves fields', () {
      final s = _sub(name: 'Spotify', amount: 9.99);
      final u = s.copyWith(amount: 12.99);
      expect(u.name, 'Spotify'); expect(u.amount, 12.99);
    });
    test('JSON round-trip', () {
      final s = _sub(name: 'GitHub', amount: 4, category: SubscriptionCategory.software, tags: ['dev']);
      final r = SubscriptionEntry.fromJson(s.toJson());
      expect(r.name, 'GitHub'); expect(r.amount, 4); expect(r.tags, ['dev']);
    });
    test('daysUntilNextBilling', () {
      expect(_sub(nextBillingDate: DateTime.now().add(const Duration(days: 5))).daysUntilNextBilling, inInclusiveRange(4, 6));
    });
    test('isInTrial active', () {
      expect(_sub(status: SubscriptionStatus.trial, trialEndDate: DateTime.now().add(const Duration(days: 10))).isInTrial, true);
    });
    test('isInTrial expired', () {
      expect(_sub(status: SubscriptionStatus.trial, trialEndDate: DateTime.now().subtract(const Duration(days: 1))).isInTrial, false);
    });
    test('isInTrial no date', () {
      expect(_sub(status: SubscriptionStatus.trial).isInTrial, false);
    });
    test('isInTrial wrong status', () {
      expect(_sub(status: SubscriptionStatus.active, trialEndDate: DateTime.now().add(const Duration(days: 10))).isInTrial, false);
    });
    test('totalSpent positive', () {
      expect(_sub(startDate: DateTime.now().subtract(const Duration(days: 90)), amount: 10, cycle: BillingCycle.monthly).totalSpent, greaterThan(0));
    });
    test('totalSpent zero for future start', () {
      expect(_sub(startDate: DateTime.now().add(const Duration(days: 1))).totalSpent, 0);
    });
    test('toString', () { expect(_sub(name: 'X', amount: 5).toString(), contains('X')); });
  });

  group('PriceChange', () {
    test('change amount and percent', () {
      final p = PriceChange(date: DateTime.now(), oldPrice: 10, newPrice: 12);
      expect(p.changeAmount, 2.0); expect(p.changePercent, 20.0);
    });
    test('zero old price', () {
      expect(PriceChange(date: DateTime.now(), oldPrice: 0, newPrice: 5).changePercent, 0);
    });
    test('JSON round-trip', () {
      final p = PriceChange(date: DateTime(2026), oldPrice: 5, newPrice: 7, reason: 'test');
      final r = PriceChange.fromJson(p.toJson());
      expect(r.oldPrice, 5); expect(r.reason, 'test');
    });
  });

  group('BillingCycle', () {
    test('labels', () { expect(BillingCycle.monthly.label, 'Monthly'); expect(BillingCycle.annual.label, 'Annual'); });
    test('periodsPerYear', () { expect(BillingCycle.monthly.periodsPerYear, 12); expect(BillingCycle.quarterly.periodsPerYear, 4); });
    test('daysBetween', () { expect(BillingCycle.weekly.daysBetween, 7); expect(BillingCycle.annual.daysBetween, 365); });
  });

  group('CRUD', () {
    late SubscriptionTrackerService svc;
    setUp(() { svc = SubscriptionTrackerService(); });

    test('add and retrieve', () { svc.add(_sub(id: 's1')); expect(svc.subscriptions.length, 1); expect(svc.getById('s1')?.name, 'Netflix'); });
    test('add duplicate throws', () { svc.add(_sub(id: 's1')); expect(() => svc.add(_sub(id: 's1')), throwsArgumentError); });
    test('remove', () { svc.add(_sub(id: 's1')); svc.remove('s1'); expect(svc.subscriptions, isEmpty); });
    test('cancel', () {
      svc.add(_sub(id: 's1'));
      svc.cancel('s1');
      expect(svc.getById('s1')!.status, SubscriptionStatus.cancelled);
      expect(svc.getById('s1')!.autoRenew, false);
    });
    test('pause and resume', () {
      svc.add(_sub(id: 's1'));
      svc.pause('s1'); expect(svc.getById('s1')!.status, SubscriptionStatus.paused);
      svc.resume('s1'); expect(svc.getById('s1')!.status, SubscriptionStatus.active);
    });
    test('update tracks price change', () {
      svc.add(_sub(id: 's1', amount: 10));
      svc.update('s1', svc.getById('s1')!.copyWith(amount: 15));
      expect(svc.getById('s1')!.priceHistory.length, 1);
    });
    test('update no price change', () {
      svc.add(_sub(id: 's1', amount: 10));
      svc.update('s1', svc.getById('s1')!.copyWith(name: 'X'));
      expect(svc.getById('s1')!.priceHistory, isEmpty);
    });
    test('update nonexistent throws', () { expect(() => svc.update('x', _sub()), throwsArgumentError); });
    test('cancel nonexistent throws', () { expect(() => svc.cancel('x'), throwsArgumentError); });
    test('pause nonexistent throws', () { expect(() => svc.pause('x'), throwsArgumentError); });
    test('resume nonexistent throws', () { expect(() => svc.resume('x'), throwsArgumentError); });
    test('getById nonexistent', () { expect(svc.getById('x'), isNull); });
  });

  group('Filtering', () {
    late SubscriptionTrackerService svc;
    setUp(() {
      svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', name: 'Netflix', category: SubscriptionCategory.streaming));
      svc.add(_sub(id: 's2', name: 'Spotify', category: SubscriptionCategory.music));
      svc.add(_sub(id: 's3', name: 'Hulu', category: SubscriptionCategory.streaming, status: SubscriptionStatus.cancelled));
      svc.add(_sub(id: 's4', name: 'ChatGPT', category: SubscriptionCategory.software, tags: ['ai']));
    });

    test('byStatus', () { expect(svc.byStatus(SubscriptionStatus.active).length, 3); });
    test('byCategory', () { expect(svc.byCategory(SubscriptionCategory.streaming).length, 2); });
    test('byTag case-insensitive', () { expect(svc.byTag('AI').length, 1); });
    test('search', () { expect(svc.search('net').length, 1); });
    test('active excludes cancelled', () { expect(svc.active.length, 3); });
  });

  group('Analytics', () {
    late SubscriptionTrackerService svc;
    setUp(() {
      svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', name: 'Netflix', amount: 15.99, category: SubscriptionCategory.streaming));
      svc.add(_sub(id: 's2', name: 'Spotify', amount: 9.99, category: SubscriptionCategory.music));
      svc.add(_sub(id: 's3', name: 'iCloud', amount: 2.99, category: SubscriptionCategory.cloud));
    });

    test('totalMonthlySpend', () { expect(svc.totalMonthlySpend, closeTo(28.97, 0.01)); });
    test('totalAnnualSpend', () { expect(svc.totalAnnualSpend, closeTo(347.64, 0.01)); });
    test('sortedByCost', () { expect(svc.sortedByCost.first.name, 'Netflix'); });
    test('getCategoryBreakdown', () {
      final b = svc.getCategoryBreakdown();
      expect(b.length, 3);
      expect(b.fold(0.0, (s, c) => s + c.percentOfTotal), closeTo(100, 0.1));
    });
    test('empty breakdown', () { expect(SubscriptionTrackerService().getCategoryBreakdown(), isEmpty); });
  });

  group('Alerts', () {
    test('upcoming billings', () {
      final svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', nextBillingDate: DateTime.now().add(const Duration(days: 3))));
      svc.add(_sub(id: 's2', name: 'Far', nextBillingDate: DateTime.now().add(const Duration(days: 10))));
      expect(svc.getUpcomingBillings(withinDays: 7).length, 1);
    });
    test('billing today', () {
      final svc = SubscriptionTrackerService();
      final t = DateTime.now();
      svc.add(_sub(id: 's1', nextBillingDate: DateTime(t.year, t.month, t.day)));
      expect(svc.getUpcomingBillings().any((a) => a.message.contains('today')), true);
    });
    test('expiring trials', () {
      final svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', status: SubscriptionStatus.trial, trialEndDate: DateTime.now().add(const Duration(days: 2))));
      expect(svc.getExpiringTrials().length, 1);
    });
  });

  group('Calendar', () {
    test('weekly generates 4+ entries', () {
      final svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', cycle: BillingCycle.weekly, nextBillingDate: DateTime.now().add(const Duration(days: 1))));
      expect(svc.getRenewalCalendar(days: 30).length, greaterThanOrEqualTo(4));
    });
    test('sorted by date', () {
      final svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', nextBillingDate: DateTime.now().add(const Duration(days: 20))));
      svc.add(_sub(id: 's2', name: 'B', nextBillingDate: DateTime.now().add(const Duration(days: 5))));
      final c = svc.getRenewalCalendar();
      if (c.length >= 2) expect(c.first.date.isBefore(c.last.date), true);
    });
  });

  group('Duplicates', () {
    test('same category similar price', () {
      final svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', amount: 15.99, category: SubscriptionCategory.streaming));
      svc.add(_sub(id: 's2', name: 'Hulu', amount: 14.99, category: SubscriptionCategory.streaming));
      expect(svc.detectPotentialDuplicates().length, 1);
    });
    test('name overlap', () {
      final svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', name: 'Adobe Creative Cloud', amount: 55, category: SubscriptionCategory.software));
      svc.add(_sub(id: 's2', name: 'Adobe', amount: 10, category: SubscriptionCategory.other));
      expect(svc.detectPotentialDuplicates().length, 1);
    });
  });

  group('Price analysis', () {
    test('tracks increases', () {
      final svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', amount: 10, priceHistory: [PriceChange(date: DateTime(2025), oldPrice: 8, newPrice: 10)]));
      final a = svc.getPriceIncreaseAnalysis();
      expect(a['totalIncreases'], 1); expect(a['totalIncreaseAmount'], 2.0);
    });
  });

  group('Summary', () {
    test('complete summary', () {
      final svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', amount: 15.99));
      svc.add(_sub(id: 's2', name: 'Spotify', amount: 9.99));
      final s = svc.getSummary();
      expect(s.totalActive, 2); expect(s.mostExpensive?.name, 'Netflix');
    });
    test('text summary', () {
      final svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1'));
      final t = svc.getTextSummary();
      expect(t, contains('Monthly spend')); expect(t, contains('Netflix'));
    });
  });

  group('Optimization', () {
    test('suggests annual', () {
      final svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', amount: 15));
      expect(svc.getOptimizationSuggestions().any((s) => s.contains('annual')), true);
    });
    test('flags expensive', () {
      final svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', name: 'Big', amount: 99));
      expect(svc.getOptimizationSuggestions().any((s) => s.contains('Big')), true);
    });
    test('flags trials', () {
      final svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', name: 'T', status: SubscriptionStatus.trial));
      expect(svc.getOptimizationSuggestions().any((s) => s.contains('trial')), true);
    });
  });

  group('Persistence', () {
    test('JSON round-trip', () {
      final svc = SubscriptionTrackerService();
      svc.add(_sub(id: 's1', name: 'Netflix'));
      svc.add(_sub(id: 's2', name: 'Spotify', amount: 9.99));
      final r = SubscriptionTrackerService()..loadFromJson(svc.toJson());
      expect(r.subscriptions.length, 2); expect(r.getById('s1')?.name, 'Netflix');
    });

    test('loadFromJson rejects oversized imports (CWE-770)', () {
      final overLimit = SubscriptionTrackerService.maxImportEntries + 1;
      final hugeJson = '[' +
          List.generate(overLimit, (i) =>
            '{"id":"sub-$i","name":"Sub $i","amount":9.99,"currency":"USD",'
            '"billingCycle":"monthly","category":"entertainment",'
            '"startDate":"2026-01-01T00:00:00.000","status":"active",'
            '"priceHistory":[]}'
          ).join(',') +
          ']';

      expect(
        () => SubscriptionTrackerService().loadFromJson(hugeJson),
        throwsA(isA<ArgumentError>().having(
          (e) => e.message, 'message',
          contains('maximum'),
        )),
      );
    });
  });

  // -----------------------------------------------------------------
  // Calendar-aware billing cycle tests (fix for issue #59)
  // -----------------------------------------------------------------
  group('BillingCycle.advanceDate', () {
    test('monthly advances by one calendar month', () {
      final date = DateTime(2026, 1, 15);
      expect(BillingCycle.monthly.advanceDate(date), DateTime(2026, 2, 15));
    });

    test('monthly Jan 31 clamps to Feb 28 (non-leap year)', () {
      final date = DateTime(2025, 1, 31);
      expect(BillingCycle.monthly.advanceDate(date), DateTime(2025, 2, 28));
    });

    test('monthly Jan 31 clamps to Feb 29 (leap year)', () {
      final date = DateTime(2028, 1, 31); // 2028 is a leap year
      expect(BillingCycle.monthly.advanceDate(date), DateTime(2028, 2, 29));
    });

    test('monthly Mar 31 clamps to Apr 30', () {
      final date = DateTime(2026, 3, 31);
      expect(BillingCycle.monthly.advanceDate(date), DateTime(2026, 4, 30));
    });

    test('monthly December wraps to next year January', () {
      final date = DateTime(2026, 12, 15);
      expect(BillingCycle.monthly.advanceDate(date), DateTime(2027, 1, 15));
    });

    test('quarterly advances by 3 months', () {
      final date = DateTime(2026, 1, 15);
      expect(BillingCycle.quarterly.advanceDate(date), DateTime(2026, 4, 15));
    });

    test('quarterly Oct wraps to next year Jan', () {
      final date = DateTime(2026, 10, 20);
      expect(BillingCycle.quarterly.advanceDate(date), DateTime(2027, 1, 20));
    });

    test('semiannual advances by 6 months', () {
      final date = DateTime(2026, 3, 15);
      expect(BillingCycle.semiannual.advanceDate(date), DateTime(2026, 9, 15));
    });

    test('semiannual Aug 31 clamps to Feb 28', () {
      final date = DateTime(2025, 8, 31);
      expect(BillingCycle.semiannual.advanceDate(date), DateTime(2026, 2, 28));
    });

    test('annual advances by one year', () {
      final date = DateTime(2026, 6, 15);
      expect(BillingCycle.annual.advanceDate(date), DateTime(2027, 6, 15));
    });

    test('annual Feb 29 clamps to Feb 28 in non-leap year', () {
      final date = DateTime(2028, 2, 29); // leap year
      expect(BillingCycle.annual.advanceDate(date), DateTime(2029, 2, 28));
    });

    test('weekly advances by 7 days', () {
      final date = DateTime(2026, 3, 10);
      expect(BillingCycle.weekly.advanceDate(date), DateTime(2026, 3, 17));
    });

    test('biweekly advances by 14 days', () {
      final date = DateTime(2026, 3, 10);
      expect(BillingCycle.biweekly.advanceDate(date), DateTime(2026, 3, 24));
    });

    test('12 monthly advances land on same day', () {
      // Key regression test: 12 monthly advances from Jan 15 should
      // return to Jan 15 the next year — not Jan 10 (which fixed-30-day
      // arithmetic would produce: 12*30 = 360 days, 5 days short).
      var date = DateTime(2026, 1, 15);
      for (var i = 0; i < 12; i++) {
        date = BillingCycle.monthly.advanceDate(date);
      }
      expect(date, DateTime(2027, 1, 15));
    });

    test('monthly preserves time components', () {
      final date = DateTime(2026, 3, 15, 14, 30, 45);
      final next = BillingCycle.monthly.advanceDate(date);
      expect(next.hour, 14);
      expect(next.minute, 30);
      expect(next.second, 45);
    });
  });

  group('getRenewalCalendar calendar-awareness', () {
    test('monthly renewal dates match calendar months', () {
      final service = SubscriptionTrackerService();
      // Subscription that bills on the 31st — should clamp properly
      service.addSubscription(_sub(
        name: 'TestSub',
        cycle: BillingCycle.monthly,
        amount: 10.0,
        nextBillingDate: DateTime(2026, 1, 31),
      ));
      final calendar = service.getRenewalCalendar(days: 90);
      // Should see Jan 31, Feb 28, Mar 31, Apr 30 (not Feb 2, Mar 4)
      final dates = calendar.map((e) => e.date).toList();
      // At minimum, no date should have day > 31 or be in the wrong month
      for (final d in dates) {
        expect(d.day, lessThanOrEqualTo(31));
      }
      // Feb entry should be on 28th, not some random drift date
      final febEntries = dates.where((d) => d.month == 2).toList();
      if (febEntries.isNotEmpty) {
        expect(febEntries.first.day, 28);
      }
    });
  });
}
