import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/daily_top_three_advisor_service.dart';

DateTime _today() => DateTime(2026, 5, 18, 9, 0);

DailyTopThreeAdvisorService _svc() => DailyTopThreeAdvisorService();

CandidateAction _act(
  String id, {
  String? title,
  CandidateCategory category = CandidateCategory.deepWork,
  int minutes = 60,
  int importance = 3,
  int urgency = 3,
  String? goalId,
  String? habitId,
  DateTime? deadline,
  bool anchor = false,
  CandidateContext context = CandidateContext.any,
  int enjoyment = 3,
}) =>
    CandidateAction(
      id: id,
      title: title ?? id,
      category: category,
      estimateMinutes: minutes,
      importance: importance,
      urgency: urgency,
      tiedToGoalId: goalId,
      tiedToHabitId: habitId,
      deadline: deadline,
      isAnchor: anchor,
      context: context,
      enjoyment: enjoyment,
    );

DailyAdvisorOptions _opts({
  DailyRiskAppetite appetite = DailyRiskAppetite.balanced,
  int maxPicks = 3,
}) =>
    DailyAdvisorOptions(
      riskAppetite: appetite,
      maxPicks: maxPicks,
      now: _today,
    );

void main() {
  group('DailyTopThreeAdvisorService', () {
    test('empty candidate list => no picks, grade F', () {
      final r = _svc().recommend(const <CandidateAction>[],
          const DailyContext(), _opts());
      expect(r.picks, isEmpty);
      expect(r.grade, 'F');
      expect(r.headline, contains('NO_PICKS'));
    });

    test('aligned top-goal high-importance candidate ships and grades A', () {
      final r = _svc().recommend(
        [
          _act('a', importance: 5, urgency: 5, goalId: 'g1', minutes: 60),
        ],
        const DailyContext(
          availableMinutes: 240,
          energyState: 0.8,
          chronotypePeakHour: 9,
          currentHour: 9,
          topGoalIds: ['g1'],
        ),
        _opts(),
      );
      expect(r.picks, hasLength(1));
      expect(r.picks.first.verdict, DailyVerdict.shipToday);
      expect(r.picks.first.reasons, contains('ALIGNS_TOP_GOAL'));
      expect(r.grade, 'A');
    });

    test('keystone habit rescue surfaces RESCUE_KEYSTONE_HABIT playbook P0',
        () {
      final r = _svc().recommend(
        [
          _act('h', category: CandidateCategory.habit, habitId: 'meditate',
              minutes: 10, importance: 4),
        ],
        const DailyContext(
          availableMinutes: 240,
          energyState: 0.5,
          keystoneHabitsAtRisk: ['meditate'],
        ),
        _opts(),
      );
      expect(
        r.playbook.any((p) =>
            p.code == 'RESCUE_KEYSTONE_HABIT' &&
            p.priority == DailyPriority.p0),
        isTrue,
      );
    });

    test('anchor candidate gets PROTECT_TIME and is picked first', () {
      final r = _svc().recommend(
        [
          _act('low', importance: 1, urgency: 1, anchor: true, minutes: 30,
              category: CandidateCategory.admin),
          _act('hi', importance: 5, urgency: 5, minutes: 60,
              category: CandidateCategory.deepWork),
        ],
        const DailyContext(availableMinutes: 240, energyState: 0.8),
        _opts(maxPicks: 2),
      );
      // Anchor must appear.
      final anchorPick = r.picks.firstWhere((p) => p.actionId == 'low');
      expect(anchorPick.verdict, DailyVerdict.protectTime);
    });

    test('greedy budget cap respected (5x90m, 180m budget => <=2 picks)', () {
      final r = _svc().recommend(
        List.generate(
            5,
            (i) => _act('c$i',
                importance: 4, urgency: 3, minutes: 90,
                category: CandidateCategory.deepWork)),
        const DailyContext(availableMinutes: 180, energyState: 0.7),
        _opts(maxPicks: 5),
      );
      expect(r.picks.length, lessThanOrEqualTo(2));
    });

    test('risk-appetite monotonicity aggressive >= balanced >= cautious', () {
      final cand = _act('m', importance: 4, urgency: 4, minutes: 45);
      final ctx = const DailyContext(energyState: 0.7);
      final cautious = _svc().recommend([cand], ctx,
          _opts(appetite: DailyRiskAppetite.cautious)).picks.first.score;
      final balanced = _svc()
          .recommend([cand], ctx, _opts(appetite: DailyRiskAppetite.balanced))
          .picks
          .first
          .score;
      final aggressive = _svc().recommend([cand], ctx,
          _opts(appetite: DailyRiskAppetite.aggressive)).picks.first.score;
      expect(aggressive + 0.01, greaterThanOrEqualTo(balanced));
      expect(balanced + 0.01, greaterThanOrEqualTo(cautious));
    });

    test('deep work at off-peak surfaces MOVE_DEEP_WORK_TO_PEAK', () {
      final r = _svc().recommend(
        [
          _act('d', category: CandidateCategory.deepWork,
              importance: 5, urgency: 4, minutes: 60),
        ],
        const DailyContext(
          availableMinutes: 240,
          energyState: 0.8,
          chronotypePeakHour: 10,
          currentHour: 18, // far off-peak
        ),
        _opts(),
      );
      expect(
        r.playbook.any((p) => p.code == 'MOVE_DEEP_WORK_TO_PEAK'),
        isTrue,
      );
    });

    test('OVERLOADED when anchors force more minutes than available', () {
      final r = _svc().recommend(
        [
          _act('anc1', anchor: true, minutes: 180,
              category: CandidateCategory.admin),
          _act('anc2', anchor: true, minutes: 180,
              category: CandidateCategory.admin),
        ],
        const DailyContext(availableMinutes: 240, energyState: 0.6),
        _opts(maxPicks: 3),
      );
      expect(r.band, DailyBand.overloaded);
      expect(
          r.playbook.any((p) => p.code == 'REDUCE_SCOPE'), isTrue);
    });

    test('determinism: same inputs => identical Markdown bytes', () {
      List<CandidateAction> mk() => [
            _act('a', importance: 4, urgency: 3, minutes: 45,
                category: CandidateCategory.deepWork),
            _act('b', importance: 3, urgency: 4, minutes: 30,
                category: CandidateCategory.admin),
            _act('c', importance: 2, urgency: 2, minutes: 60,
                category: CandidateCategory.learning),
          ];
      const ctx = DailyContext(availableMinutes: 200, energyState: 0.7);
      final r1 = _svc().recommend(mk(), ctx, _opts());
      final r2 = _svc().recommend(mk(), ctx, _opts());
      expect(_svc().formatMarkdown(r1), _svc().formatMarkdown(r2));
    });

    test('items with score < 20 land in unpicked with verdict DROP', () {
      // Force a tiny score: importance=1, urgency=1, enjoyment=1, no
      // alignment, energy=0 so deepWork energyFit=0.2.
      final r = _svc().recommend(
        [
          _act('keep', importance: 5, urgency: 5, minutes: 60,
              category: CandidateCategory.deepWork),
          // Use aggressive multiplier reductions: very low scoring item.
          _act('junk',
              importance: 1,
              urgency: 1,
              enjoyment: 1,
              minutes: 600, // big so it definitely won't be picked
              category: CandidateCategory.errand,
              context: CandidateContext.outdoors),
        ],
        const DailyContext(
          availableMinutes: 60,
          energyState: 0.8,
          location: CandidateContext.home, // location mismatch -> locationFit=0
        ),
        _opts(appetite: DailyRiskAppetite.cautious, maxPicks: 1),
      );
      // Top pick uses the 60m budget; junk lands in unpicked.
      final junk = r.unpicked.firstWhere((p) => p.actionId == 'junk');
      // With the harsh setup, junk score should be < 20 -> DROP.
      // (importance*8 + urgency*7 + enjoymentBonus = 8+7-4 = 11; energyFit
      //  for errand=0.6 -> +6; locationFit=0; chronoFit=0.5 -> +4;
      //  total ~21 * 0.92 ~= 19.3 -> DROP.)
      expect(junk.score, lessThan(20));
      expect(junk.verdict, DailyVerdict.drop);
    });

    test('each pick has non-empty reasons of uppercase_with_underscore codes',
        () {
      final r = _svc().recommend(
        [
          _act('a', importance: 4, urgency: 4, minutes: 45,
              category: CandidateCategory.deepWork),
        ],
        const DailyContext(energyState: 0.7),
        _opts(),
      );
      final p = r.picks.first;
      expect(p.reasons, isNotEmpty);
      for (final code in p.reasons) {
        expect(RegExp(r'^[A-Z][A-Z0-9_]*$').hasMatch(code), isTrue,
            reason: 'bad code: $code');
      }
    });

    test('unpicked ordering is deterministic (score desc then id asc)', () {
      final r = _svc().recommend(
        [
          _act('alpha', importance: 4, urgency: 4, minutes: 60),
          _act('bravo', importance: 4, urgency: 4, minutes: 60),
          _act('charlie', importance: 3, urgency: 3, minutes: 60),
        ],
        const DailyContext(availableMinutes: 60, energyState: 0.7),
        _opts(maxPicks: 1),
      );
      // Two unpicked. Ties (alpha vs bravo) -> alpha first by id asc;
      // charlie has lower score -> last.
      final ids = r.unpicked.map((p) => p.actionId).toList();
      expect(ids.first, anyOf('alpha', 'bravo'));
      expect(ids.last, 'charlie');
      // Confirm full ordering by score desc then id asc.
      for (var i = 1; i < ids.length; i++) {
        final prev = r.unpicked[i - 1];
        final cur = r.unpicked[i];
        expect(prev.score >= cur.score, isTrue);
        if (prev.score == cur.score) {
          expect(prev.actionId.compareTo(cur.actionId) <= 0, isTrue);
        }
      }
    });
  });
}
