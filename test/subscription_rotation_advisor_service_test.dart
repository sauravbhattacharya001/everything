import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/subscription_rotation_advisor_service.dart';

DateTime _now() => DateTime(2026, 5, 23, 9, 0);

SubscriptionRotationAdvisorService _svc() =>
    const SubscriptionRotationAdvisorService();

RotationOptions _opts({
  SubscriptionRiskAppetite appetite = SubscriptionRiskAppetite.balanced,
}) =>
    RotationOptions(riskAppetite: appetite, now: _now);

SubscriptionSnapshot _sub(
  String id, {
  String name = '',
  String category = 'streaming',
  double cost = 15.0,
  int usesLast30 = 10,
  int lastUsedDaysAgo = 5,
  bool shared = false,
  bool contractLock = false,
  String? altName,
  double? altCost,
  int? trialEndsInHours,
  int? renewsInDays,
  double? signupCost,
}) {
  final now = _now();
  return SubscriptionSnapshot(
    id: id,
    name: name.isEmpty ? id : name,
    category: category,
    monthlyCost: cost,
    signedUpAt: now.subtract(const Duration(days: 365)),
    lastUsedAt: now.subtract(Duration(days: lastUsedDaysAgo)),
    usesInLast30Days: usesLast30,
    signupMonthlyCost: signupCost,
    nextRenewalAt:
        renewsInDays == null ? null : now.add(Duration(days: renewsInDays)),
    freeTrialEndsAt: trialEndsInHours == null
        ? null
        : now.add(Duration(hours: trialEndsInHours)),
    isShared: shared,
    hasContractLock: contractLock,
    cheaperAlternative: altName,
    cheaperAlternativeCost: altCost,
  );
}

void main() {
  group('SubscriptionRotationAdvisorService', () {
    test('empty portfolio => grade A, EMPTY headline', () {
      final r = _svc().recommend(const <SubscriptionSnapshot>[], _opts());
      expect(r.grade, 'A');
      expect(r.totalSubscriptions, 0);
      expect(r.headline, contains('EMPTY_PORTFOLIO'));
      expect(r.insights, contains('EMPTY_PORTFOLIO'));
    });

    test('actively used subscription => KEEP', () {
      final r = _svc().recommend([
        _sub('netflix', usesLast30: 25, lastUsedDaysAgo: 1, cost: 15),
      ], _opts());
      expect(r.forecasts.single.verdict, SubscriptionVerdict.keep);
      expect(r.grade, 'A');
    });

    test('long-unused subscription => CANCEL_NOW + projected savings', () {
      final r = _svc().recommend([
        _sub('hulu', usesLast30: 0, lastUsedDaysAgo: 200, cost: 12),
      ], _opts());
      expect(r.forecasts.single.verdict, SubscriptionVerdict.cancelNow);
      expect(r.projectedMonthlySavings, 12.0);
      expect(
        r.playbook.any((a) => a.code == 'CANCEL_UNUSED_SUBSCRIPTIONS'),
        isTrue,
      );
    });

    test('contract-locked unused subscription => PAUSE not CANCEL', () {
      final r = _svc().recommend([
        _sub('gym',
            category: 'fitness',
            usesLast30: 0,
            lastUsedDaysAgo: 200,
            cost: 40,
            contractLock: true),
      ], _opts());
      expect(
        r.forecasts.single.verdict,
        SubscriptionVerdict.pauseOneMonth,
      );
    });

    test('trial ending soon with low usage => CANCEL_NOW P0 playbook', () {
      final r = _svc().recommend([
        _sub('newthing',
            usesLast30: 0,
            lastUsedDaysAgo: 1,
            trialEndsInHours: 24,
            cost: 30),
      ], _opts());
      expect(r.forecasts.single.verdict, SubscriptionVerdict.cancelNow);
      expect(
        r.playbook.any((a) => a.code == 'CANCEL_BEFORE_TRIAL_AUTORENEW'),
        isTrue,
      );
    });

    test('cheaper alternative + elevated risk => SWAP_TO_ALTERNATIVE', () {
      final r = _svc().recommend([
        _sub('premium',
            category: 'music',
            usesLast30: 3,
            lastUsedDaysAgo: 20,
            cost: 20,
            altName: 'free tier',
            altCost: 0),
      ], _opts());
      final f = r.forecasts.single;
      expect(f.verdict, SubscriptionVerdict.swapToAlternative);
      expect(f.projectedMonthlySavings, 20.0);
    });

    test('duplicate category surfaces in insights', () {
      final r = _svc().recommend([
        _sub('netflix', category: 'streaming', usesLast30: 20, cost: 15),
        _sub('hbo', category: 'streaming', usesLast30: 18, cost: 15),
        _sub('disney', category: 'streaming', usesLast30: 10, cost: 10),
      ], _opts());
      expect(
        r.insights.any((i) => i.startsWith('DUPLICATE_CATEGORIES:')),
        isTrue,
      );
    });

    test('renewal within 7 days surfaces ACT_BEFORE_RENEWAL playbook', () {
      final r = _svc().recommend([
        _sub('cloud',
            category: 'cloud',
            usesLast30: 30,
            lastUsedDaysAgo: 1,
            cost: 12,
            renewsInDays: 3),
      ], _opts());
      expect(
        r.playbook.any((a) => a.code == 'ACT_BEFORE_RENEWAL_WINDOW'),
        isTrue,
      );
    });

    test('cautious appetite adds quarterly audit action', () {
      final r = _svc().recommend([
        _sub('a', usesLast30: 20, lastUsedDaysAgo: 2, cost: 5),
      ], _opts(appetite: SubscriptionRiskAppetite.cautious));
      expect(
        r.playbook.any((a) => a.code == 'SCHEDULE_QUARTERLY_AUDIT'),
        isTrue,
      );
    });

    test('aggressive appetite trims P3 fallback when other actions exist', () {
      final r = _svc().recommend([
        _sub('unused', usesLast30: 0, lastUsedDaysAgo: 120, cost: 12),
      ], _opts(appetite: SubscriptionRiskAppetite.aggressive));
      expect(
        r.playbook.any((a) => a.code == 'MAINTAIN_PORTFOLIO_HEALTH'),
        isFalse,
      );
    });

    test('downgrade verdict for low-use justifying a tier cut', () {
      final r = _svc().recommend([
        _sub('premium',
            category: 'productivity',
            usesLast30: 2,
            lastUsedDaysAgo: 4,
            cost: 25),
      ], _opts());
      expect(
        r.forecasts.single.verdict,
        anyOf(SubscriptionVerdict.downgradeTier,
            SubscriptionVerdict.pauseOneMonth),
      );
    });

    test('price creep flagged in reasons', () {
      final r = _svc().recommend([
        _sub('cloud',
            usesLast30: 20,
            lastUsedDaysAgo: 1,
            cost: 30,
            signupCost: 10),
      ], _opts());
      expect(
        r.forecasts.single.reasons.contains('PRICE_CREEP_50PCT_PLUS'),
        isTrue,
      );
    });

    test('renderers produce non-empty text/markdown/json', () {
      final r = _svc().recommend([
        _sub('hulu', usesLast30: 0, lastUsedDaysAgo: 200, cost: 12),
        _sub('netflix', usesLast30: 25, lastUsedDaysAgo: 1, cost: 15),
      ], _opts());
      final text = _svc().toText(r);
      final md = _svc().toMarkdown(r);
      final js = _svc().toJson(r);
      expect(text, contains('SUBSCRIPTION_ROTATION'));
      expect(md, contains('# Subscription Rotation Advisor'));
      expect(md, contains('## Playbook'));
      final decoded = jsonDecode(js) as Map<String, dynamic>;
      expect(decoded['total_subscriptions'], 2);
      expect(decoded['forecasts'], isA<List>());
      expect(decoded['playbook'], isA<List>());
    });

    test('determinism: same input => same JSON output', () {
      final inputs = [
        _sub('a', usesLast30: 0, lastUsedDaysAgo: 60, cost: 9),
        _sub('b', usesLast30: 12, lastUsedDaysAgo: 1, cost: 18),
        _sub('c',
            usesLast30: 1,
            lastUsedDaysAgo: 30,
            cost: 22,
            altName: 'lite',
            altCost: 8),
      ];
      final j1 = _svc().toJson(_svc().recommend(inputs, _opts()));
      final j2 = _svc().toJson(_svc().recommend(inputs, _opts()));
      expect(j1, j2);
    });

    test('grade F when 4+ cancellations recommended', () {
      final r = _svc().recommend([
        for (var i = 0; i < 4; i++)
          _sub('unused$i',
              category: 'cat$i', usesLast30: 0, lastUsedDaysAgo: 200, cost: 12),
      ], _opts());
      expect(r.grade, 'F');
    });
  });
}
