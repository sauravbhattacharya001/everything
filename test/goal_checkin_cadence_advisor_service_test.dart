import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/goal_checkin_cadence_advisor_service.dart';

DateTime _today() => DateTime(2026, 5, 21, 9, 0);

GoalCheckinCadenceAdvisorService _svc() =>
    const GoalCheckinCadenceAdvisorService();

CheckinCadenceOptions _opts({
  CheckinRiskAppetite appetite = CheckinRiskAppetite.balanced,
  int defaultCadenceDays = 14,
  int newGoalGraceDays = 7,
}) =>
    CheckinCadenceOptions(
      riskAppetite: appetite,
      now: _today,
      defaultCadenceDays: defaultCadenceDays,
      newGoalGraceDays: newGoalGraceDays,
    );

GoalCheckinSnapshot _g(
  String id, {
  String? title,
  String category = 'career',
  int priorityWeight = 3,
  DateTime? createdAt,
  DateTime? lastCheckinAt,
  DateTime? lastProgressUpdateAt,
  double recentProgressDelta = 0.0,
  DateTime? deadline,
  bool isPaused = false,
  String currentStatus = '',
}) =>
    GoalCheckinSnapshot(
      id: id,
      title: title ?? id,
      category: category,
      createdAt: createdAt ?? DateTime(2026, 1, 1),
      priorityWeight: priorityWeight,
      lastCheckinAt: lastCheckinAt,
      lastProgressUpdateAt: lastProgressUpdateAt,
      recentProgressDelta: recentProgressDelta,
      deadline: deadline,
      isPaused: isPaused,
      currentStatus: currentStatus,
    );

void main() {
  group('GoalCheckinCadenceAdvisorService', () {
    test('empty portfolio -> grade A, healthy band, no-active headline', () {
      final r = _svc().evaluate(const <GoalCheckinSnapshot>[], _opts());
      expect(r.forecasts, isEmpty);
      expect(r.grade, 'A');
      expect(r.band, CheckinPortfolioBand.healthy);
      expect(r.headline, contains('NO_ACTIVE_GOALS'));
      expect(r.playbook, hasLength(1));
      expect(r.playbook.first.id, 'CADENCE_OK');
      expect(r.playbook.first.priority, CadencePriority.p3);
    });

    test('on-cadence goal -> ON_CADENCE verdict, grade A, healthy band', () {
      final r = _svc().evaluate(
        [
          _g(
            'g1',
            priorityWeight: 3,
            createdAt: DateTime(2025, 12, 1),
            lastCheckinAt: DateTime(2026, 5, 20),
          ),
        ],
        _opts(),
      );
      expect(r.forecasts, hasLength(1));
      expect(r.forecasts.first.verdict, GoalCheckinVerdict.onCadence);
      expect(r.forecasts.first.reasons, contains('ON_CADENCE'));
      expect(r.grade, 'A');
      expect(r.band, CheckinPortfolioBand.healthy);
    });

    test('overdue goal -> verdict overdue, P1 priority, grade demoted', () {
      // priority 3, default cadence 14d, last check-in 30d ago => factor ~2.14
      // -> crosses criticalFactor 2.0 actually, so use 25 days for plain overdue.
      final r = _svc().evaluate(
        [
          _g(
            'g1',
            priorityWeight: 3,
            createdAt: DateTime(2025, 12, 1),
            lastCheckinAt: DateTime(2026, 4, 26), // 25d ago vs 14d cadence
          ),
        ],
        _opts(),
      );
      final f = r.forecasts.first;
      expect(f.verdict, GoalCheckinVerdict.overdue);
      expect(f.priority, CadencePriority.p1);
      expect(f.reasons, contains('OVERDUE'));
      // Grade should be worse than A.
      expect(r.grade, isNot('A'));
      expect(r.playbook.any((a) => a.id == 'SCHEDULE_OVERDUE_CHECKINS'),
          isTrue);
    });

    test('critically-overdue high-priority goal -> P0, critical band, grade F',
        () {
      final r = _svc().evaluate(
        [
          _g(
            'g1',
            priorityWeight: 5,
            createdAt: DateTime(2025, 9, 1),
            lastCheckinAt: DateTime(2026, 2, 1), // ~109d ago
          ),
        ],
        _opts(),
      );
      final f = r.forecasts.first;
      expect(f.verdict, GoalCheckinVerdict.overdueCritical);
      expect(f.priority, CadencePriority.p0);
      expect(f.reasons, containsAll(['CRITICALLY_OVERDUE', 'HIGH_PRIORITY_NEGLECT']));
      expect(r.band, CheckinPortfolioBand.critical);
      expect(r.grade, 'F');
      expect(r.playbook.first.priority, CadencePriority.p0);
      expect(r.playbook.any((a) => a.id == 'EMERGENCY_REVIEW_SWEEP'), isTrue);
    });

    test('paused goal is excluded from active scoring and tagged PAUSED', () {
      final r = _svc().evaluate(
        [
          _g(
            'g1',
            priorityWeight: 4,
            createdAt: DateTime(2025, 9, 1),
            lastCheckinAt: DateTime(2026, 1, 1),
            isPaused: true,
          ),
        ],
        _opts(),
      );
      final f = r.forecasts.first;
      expect(f.verdict, GoalCheckinVerdict.paused);
      expect(f.reasons, contains('PAUSED'));
      expect(r.band, CheckinPortfolioBand.healthy);
      expect(r.grade, 'A');
    });

    test('new goal within grace period -> NEW_GOAL, P3, no overdue flag', () {
      final r = _svc().evaluate(
        [
          _g(
            'g1',
            priorityWeight: 4,
            createdAt: DateTime(2026, 5, 19), // 2d ago, within 7d grace
          ),
        ],
        _opts(),
      );
      final f = r.forecasts.first;
      expect(f.verdict, GoalCheckinVerdict.newGoal);
      expect(f.priority, CadencePriority.p3);
      expect(f.reasons, contains('NEW_GOAL_GRACE_PERIOD'));
    });

    test('never-checked-in past grace -> NEVER_CHECKED_IN + KICKOFF action',
        () {
      final r = _svc().evaluate(
        [
          _g(
            'g1',
            priorityWeight: 3,
            createdAt: DateTime(2026, 4, 1), // 50d ago
          ),
          _g(
            'g2',
            priorityWeight: 3,
            createdAt: DateTime(2026, 4, 5),
          ),
        ],
        _opts(),
      );
      expect(r.forecasts.every((f) => f.reasons.contains('NEVER_CHECKED_IN')),
          isTrue);
      expect(r.playbook.any((a) => a.id == 'KICKOFF_NEVER_CHECKED_GOALS'),
          isTrue);
    });

    test('deadline pressure tightens cadence and adds DEADLINE_PRESSURE reason',
        () {
      final r = _svc().evaluate(
        [
          _g(
            'g1',
            priorityWeight: 2,
            createdAt: DateTime(2026, 1, 1),
            lastCheckinAt: DateTime(2026, 5, 18),
            deadline: DateTime(2026, 5, 28), // 7d away
          ),
        ],
        _opts(),
      );
      final f = r.forecasts.first;
      // priority 2 default would be 14*1.3=18.2d, but deadline within 7d
      // forces cadence <= 2d.
      expect(f.recommendedCadenceDays, lessThanOrEqualTo(2));
      expect(f.reasons, contains('DEADLINE_PRESSURE'));
      expect(r.playbook.any((a) =>
              a.id == 'TIGHTEN_DEADLINE_CADENCE' ||
              a.id == 'SCHEDULE_OVERDUE_CHECKINS' ||
              a.id == 'EMERGENCY_REVIEW_SWEEP'),
          isTrue);
    });

    test('passed deadline triggers DEADLINE_PASSED + TRIAGE_PASSED_DEADLINES',
        () {
      final r = _svc().evaluate(
        [
          _g(
            'g1',
            priorityWeight: 3,
            createdAt: DateTime(2026, 1, 1),
            lastCheckinAt: DateTime(2026, 5, 20),
            deadline: DateTime(2026, 5, 10), // 11d in the past
          ),
        ],
        _opts(),
      );
      final f = r.forecasts.first;
      expect(f.reasons, contains('DEADLINE_PASSED'));
      expect(r.playbook.any((a) => a.id == 'TRIAGE_PASSED_DEADLINES'), isTrue);
      expect(r.playbook.first.priority, CadencePriority.p0);
    });

    test('risk appetite monotonicity: cautious >= balanced >= aggressive', () {
      final goals = [
        _g(
          'g1',
          priorityWeight: 3,
          createdAt: DateTime(2025, 12, 1),
          lastCheckinAt: DateTime(2026, 5, 6), // 15d ago
        ),
        _g(
          'g2',
          priorityWeight: 4,
          createdAt: DateTime(2025, 12, 1),
          lastCheckinAt: DateTime(2026, 5, 8),
        ),
      ];
      final c = _svc()
          .evaluate(goals, _opts(appetite: CheckinRiskAppetite.cautious));
      final b = _svc().evaluate(goals, _opts());
      final a = _svc()
          .evaluate(goals, _opts(appetite: CheckinRiskAppetite.aggressive));
      expect(c.portfolioOverdueScore,
          greaterThanOrEqualTo(b.portfolioOverdueScore));
      expect(b.portfolioOverdueScore,
          greaterThanOrEqualTo(a.portfolioOverdueScore));
    });

    test('aggressive trims P2 fallbacks when P0/P1 actions are present', () {
      final goals = [
        _g(
          'crit',
          priorityWeight: 5,
          createdAt: DateTime(2025, 9, 1),
          lastCheckinAt: DateTime(2026, 1, 1),
        ),
        _g(
          'soon',
          priorityWeight: 3,
          createdAt: DateTime(2025, 12, 1),
          lastCheckinAt: DateTime(2026, 5, 9), // ~75% cadence -> due soon
        ),
      ];
      final agg = _svc()
          .evaluate(goals, _opts(appetite: CheckinRiskAppetite.aggressive));
      final bal = _svc().evaluate(goals, _opts());
      expect(bal.playbook.any((a) => a.id == 'PRE_BOOK_DUE_SOON'), isTrue);
      expect(agg.playbook.any((a) => a.id == 'PRE_BOOK_DUE_SOON'), isFalse);
    });

    test('JSON renderer is deterministic and contains expected keys', () {
      final r = _svc().evaluate(
        [
          _g(
            'g1',
            priorityWeight: 3,
            createdAt: DateTime(2025, 12, 1),
            lastCheckinAt: DateTime(2026, 5, 20),
          ),
        ],
        _opts(),
      );
      final j1 = _svc().toJson(r);
      final j2 = _svc().toJson(r);
      expect(j1, equals(j2));
      expect(j1, contains('"grade":"A"'));
      expect(j1, contains('"forecasts":'));
      expect(j1, contains('"playbook":'));
      expect(j1, contains('"portfolioOverdueScore":'));
    });

    test('markdown renderer includes sections and table headers', () {
      final r = _svc().evaluate(
        [
          _g(
            'g1',
            priorityWeight: 3,
            createdAt: DateTime(2025, 12, 1),
            lastCheckinAt: DateTime(2026, 4, 26), // overdue
          ),
        ],
        _opts(),
      );
      final md = _svc().toMarkdown(r);
      expect(md, contains('# Goal Check-in Cadence Report'));
      expect(md, contains('## Forecasts'));
      expect(md, contains('## Playbook'));
      expect(md, contains('| Goal | Priority | Verdict'));
    });

    test('text renderer includes headline and verdict label', () {
      final r = _svc().evaluate(
        [
          _g(
            'g1',
            priorityWeight: 5,
            createdAt: DateTime(2025, 9, 1),
            lastCheckinAt: DateTime(2026, 2, 1),
          ),
        ],
        _opts(),
      );
      final t = _svc().toText(r);
      expect(t, contains('CADENCE_VERDICT'));
      expect(t, contains('OVERDUE_CRITICAL'));
      expect(t, contains('Playbook:'));
    });

    test('HIGH_PRIORITY_REVIEW_GAP insight surfaces with >=2 P4 overdue goals',
        () {
      final r = _svc().evaluate(
        [
          _g(
            'g1',
            priorityWeight: 5,
            createdAt: DateTime(2025, 9, 1),
            lastCheckinAt: DateTime(2026, 4, 26),
          ),
          _g(
            'g2',
            priorityWeight: 4,
            createdAt: DateTime(2025, 9, 1),
            lastCheckinAt: DateTime(2026, 4, 25),
          ),
        ],
        _opts(),
      );
      expect(r.insights, contains('HIGH_PRIORITY_REVIEW_GAP'));
    });

    test('forecasts sorted by overdueFactor desc then id asc', () {
      final r = _svc().evaluate(
        [
          _g(
            'b',
            priorityWeight: 3,
            createdAt: DateTime(2025, 12, 1),
            lastCheckinAt: DateTime(2026, 5, 20),
          ),
          _g(
            'a',
            priorityWeight: 3,
            createdAt: DateTime(2025, 12, 1),
            lastCheckinAt: DateTime(2026, 4, 1), // very overdue
          ),
          _g(
            'c',
            priorityWeight: 3,
            createdAt: DateTime(2025, 12, 1),
            lastCheckinAt: DateTime(2026, 5, 1), // mildly overdue
          ),
        ],
        _opts(),
      );
      expect(r.forecasts.map((f) => f.id).toList(), ['a', 'c', 'b']);
    });
  });
}
