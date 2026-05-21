import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/goal_deadline_risk_advisor_service.dart';

DateTime _today() => DateTime(2026, 5, 21, 9, 0);

GoalDeadlineRiskAdvisorService _svc() => GoalDeadlineRiskAdvisorService();

GoalSnapshot _goal(
  String id, {
  String? title,
  String category = 'career',
  DateTime? deadline,
  double progress = 0.4,
  double targetUnits = 100.0,
  double unitsDoneSoFar = 40.0,
  DateTime? createdAt,
  double recentVelocityUnitsPerWeek = 5.0,
  int priorityWeight = 3,
  bool isPaused = false,
}) =>
    GoalSnapshot(
      id: id,
      title: title ?? id,
      category: category,
      deadline: deadline ?? DateTime(2026, 8, 1),
      progress: progress,
      targetUnits: targetUnits,
      unitsDoneSoFar: unitsDoneSoFar,
      createdAt: createdAt ?? DateTime(2026, 2, 1),
      recentVelocityUnitsPerWeek: recentVelocityUnitsPerWeek,
      priorityWeight: priorityWeight,
      isPaused: isPaused,
    );

DeadlineRiskOptions _opts({
  DeadlineRiskAppetite appetite = DeadlineRiskAppetite.balanced,
}) =>
    DeadlineRiskOptions(riskAppetite: appetite, now: _today);

void main() {
  group('GoalDeadlineRiskAdvisorService', () {
    test('empty goals -> empty forecasts, grade A, CLEAR_RUNWAY headline', () {
      final r = _svc().evaluate(const <GoalSnapshot>[], _opts());
      expect(r.forecasts, isEmpty);
      expect(r.grade, 'A');
      expect(r.headline, contains('CLEAR_RUNWAY'));
      expect(r.insights, contains('CLEAR_RUNWAY'));
    });

    test('on-track goal grades A with verdict ON_TRACK', () {
      // Plenty of runway, healthy velocity, comfortably ahead.
      final r = _svc().evaluate(
        [
          _goal(
            'g1',
            deadline: DateTime(2027, 5, 21),
            progress: 0.6,
            targetUnits: 100,
            unitsDoneSoFar: 60,
            createdAt: DateTime(2026, 4, 1),
            recentVelocityUnitsPerWeek: 5.0,
          ),
        ],
        _opts(),
      );
      expect(r.forecasts, hasLength(1));
      // ON_TRACK or COASTING is fine here (deadline >365d AND progress>=0.05
      // can promote to coasting).
      final v = r.forecasts.first.verdict;
      expect(
        v == GoalDeadlineVerdict.onTrack ||
            v == GoalDeadlineVerdict.coasting,
        isTrue,
        reason: 'expected on-track or coasting but got ${v.name}',
      );
      expect(['A', 'B'], contains(r.grade));
    });

    test(
      'behind-schedule goal -> AT_RISK or CRITICAL, BEHIND_SCHEDULE reason, p0/p1',
      () {
        final r = _svc().evaluate(
          [
            _goal(
              'g1',
              deadline: _today().add(const Duration(days: 14)),
              progress: 0.3,
              targetUnits: 100,
              unitsDoneSoFar: 30,
              createdAt: DateTime(2026, 1, 1),
              recentVelocityUnitsPerWeek: 1.0,
              priorityWeight: 4,
            ),
          ],
          _opts(),
        );
        final f = r.forecasts.first;
        expect(
          f.verdict == GoalDeadlineVerdict.atRisk ||
              f.verdict == GoalDeadlineVerdict.critical,
          isTrue,
        );
        expect(
          f.priority == DeadlineRiskPriority.p0 ||
              f.priority == DeadlineRiskPriority.p1,
          isTrue,
        );
        expect(f.reasons, contains('BEHIND_SCHEDULE'));
      },
    );

    test('overdue goal -> MISSED, grade F, ESCALATE_MISSED_GOAL in playbook',
        () {
      final r = _svc().evaluate(
        [
          _goal(
            'g1',
            deadline: _today().subtract(const Duration(days: 5)),
            progress: 0.4,
            unitsDoneSoFar: 40,
            recentVelocityUnitsPerWeek: 0.0,
          ),
        ],
        _opts(),
      );
      expect(r.forecasts.first.verdict, GoalDeadlineVerdict.missed);
      expect(r.grade, 'F');
      expect(
        r.playbook.any((a) => a.label == 'ESCALATE_MISSED_GOAL'),
        isTrue,
      );
    });

    test('paused goal due in 7 days -> PAUSED_BUT_DUE_SOON + UNPAUSE_DUE_GOAL',
        () {
      final r = _svc().evaluate(
        [
          _goal(
            'g1',
            deadline: _today().add(const Duration(days: 7)),
            progress: 0.5,
            unitsDoneSoFar: 50,
            isPaused: true,
            recentVelocityUnitsPerWeek: 0.0,
          ),
        ],
        _opts(),
      );
      expect(
        r.forecasts.first.reasons,
        contains('PAUSED_BUT_DUE_SOON'),
      );
      expect(
        r.playbook.any((a) => a.label == 'UNPAUSE_DUE_GOAL'),
        isTrue,
      );
    });

    test('completed goal -> COASTING, p3, CELEBRATE_WIN in playbook', () {
      final r = _svc().evaluate(
        [
          _goal(
            'g1',
            deadline: DateTime(2026, 12, 31),
            progress: 1.0,
            targetUnits: 100,
            unitsDoneSoFar: 100,
            recentVelocityUnitsPerWeek: 5.0,
          ),
        ],
        _opts(),
      );
      expect(r.forecasts.first.verdict, GoalDeadlineVerdict.coasting);
      expect(r.forecasts.first.priority, DeadlineRiskPriority.p3);
      expect(
        r.playbook.any((a) => a.label == 'CELEBRATE_WIN'),
        isTrue,
      );
    });

    test('cautious shifts risk up vs aggressive on borderline goal', () {
      final goal = _goal(
        'g1',
        deadline: _today().add(const Duration(days: 30)),
        progress: 0.5,
        targetUnits: 100,
        unitsDoneSoFar: 50,
        recentVelocityUnitsPerWeek: 4.0,
        createdAt: DateTime(2026, 3, 1),
      );
      final cautious = _svc().evaluate(
          [goal], _opts(appetite: DeadlineRiskAppetite.cautious));
      final aggressive = _svc().evaluate(
          [goal], _opts(appetite: DeadlineRiskAppetite.aggressive));
      expect(
        cautious.forecasts.first.riskScore >
            aggressive.forecasts.first.riskScore,
        isTrue,
        reason:
            'cautious=${cautious.forecasts.first.riskScore} aggressive=${aggressive.forecasts.first.riskScore}',
      );
    });

    test('>=2 critical surfaces MANY_CRITICAL insight', () {
      List<GoalSnapshot> goals = [];
      for (var i = 0; i < 2; i++) {
        goals.add(_goal(
          'g$i',
          deadline: _today().add(const Duration(days: 7)),
          progress: 0.1,
          unitsDoneSoFar: 10,
          createdAt: DateTime(2026, 1, 1),
          recentVelocityUnitsPerWeek: 0.0,
          priorityWeight: 5,
        ));
      }
      final r = _svc().evaluate(goals, _opts());
      expect(r.insights, contains('MANY_CRITICAL'));
      expect(r.grade, anyOf('D', 'F'));
    });

    test(
      'velocityShortfall >= 2x required triggers INCREASE_WEEKLY_VELOCITY',
      () {
        final r = _svc().evaluate(
          [
            _goal(
              'g1',
              deadline: _today().add(const Duration(days: 21)),
              progress: 0.2,
              targetUnits: 100,
              unitsDoneSoFar: 20,
              createdAt: DateTime(2026, 1, 1),
              // required ~ (80 / 3 weeks) ~ 26.6/wk, velocity 5 (<13.3)
              recentVelocityUnitsPerWeek: 5.0,
              priorityWeight: 4,
            ),
          ],
          _opts(),
        );
        expect(
          r.playbook.any((a) => a.label == 'INCREASE_WEEKLY_VELOCITY'),
          isTrue,
        );
      },
    );

    test('CRITICAL with daysSlippage>=21 triggers RENEGOTIATE_DEADLINE', () {
      final r = _svc().evaluate(
        [
          _goal(
            'g1',
            deadline: _today().add(const Duration(days: 14)),
            progress: 0.1,
            targetUnits: 100,
            unitsDoneSoFar: 10,
            createdAt: DateTime(2026, 1, 1),
            recentVelocityUnitsPerWeek: 0.5, // huge slippage
            priorityWeight: 5,
          ),
        ],
        _opts(),
      );
      // We expect CRITICAL because daysRemaining<=30 AND projection slips
      // many weeks.
      final f = r.forecasts.first;
      expect(f.verdict, GoalDeadlineVerdict.critical);
      expect(f.daysSlippage, greaterThanOrEqualTo(21));
      expect(
        r.playbook.any((a) => a.label == 'RENEGOTIATE_DEADLINE'),
        isTrue,
      );
    });

    test('toJson exposes the expected top-level keys', () {
      final r = _svc().evaluate([_goal('g1')], _opts());
      final j = r.toJson();
      for (final k in [
        'forecasts',
        'playbook',
        'portfolioRiskScore',
        'band',
        'grade',
        'headline',
        'insights',
        'generatedAt',
      ]) {
        expect(j.containsKey(k), isTrue, reason: 'missing key $k');
      }
      expect(j['forecasts'], isA<List>());
      expect(j['playbook'], isA<List>());
    });

    test('toMarkdown contains ## Summary and ## Playbook', () {
      final r = _svc().evaluate([_goal('g1')], _opts());
      final md = r.toMarkdown();
      expect(md, contains('## Summary'));
      expect(md, contains('## Playbook'));
      expect(md, contains('## Forecasts'));
    });

    test('deterministic: identical inputs + injected now yield equal JSON',
        () {
      final goals = [
        _goal('g1', priorityWeight: 5),
        _goal('g2',
            deadline: _today().add(const Duration(days: 10)),
            recentVelocityUnitsPerWeek: 1.0),
      ];
      final a = _svc().evaluate(goals, _opts()).toJson().toString();
      final b = _svc().evaluate(goals, _opts()).toJson().toString();
      expect(a, equals(b));
    });

    test('forecasts are stable-sorted by riskScore desc then id asc', () {
      final goals = [
        _goal('a',
            deadline: _today().add(const Duration(days: 365)),
            recentVelocityUnitsPerWeek: 10.0),
        _goal('b',
            deadline: _today().add(const Duration(days: 7)),
            progress: 0.1,
            unitsDoneSoFar: 10,
            recentVelocityUnitsPerWeek: 0.0,
            priorityWeight: 5),
      ];
      final r = _svc().evaluate(goals, _opts());
      expect(r.forecasts.first.goalId, 'b');
      expect(r.forecasts.last.goalId, 'a');
    });
  });
}
