import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/habit_momentum_service.dart';

DateTime _d(int y, int m, int d) => DateTime(y, m, d);

/// Build a synthetic series of records for [habitId] over the last [days] days
/// ending at [today], where [doneMask] (list of bool, oldest-first) decides
/// per-day completion. Optional intensity per day.
List<HabitDailyRecord> _series(
  String habitId,
  DateTime today,
  List<bool> doneMask, {
  List<double?>? intensity,
}) {
  final out = <HabitDailyRecord>[];
  final n = doneMask.length;
  for (int i = 0; i < n; i++) {
    final day = today.subtract(Duration(days: n - 1 - i));
    out.add(HabitDailyRecord(
      habitId: habitId,
      date: day,
      done: doneMask[i],
      intensity: intensity == null ? null : intensity[i],
    ));
  }
  return out;
}

void main() {
  final today = _d(2026, 5, 17);
  HabitMomentumService make({HabitRiskAppetite r = HabitRiskAppetite.balanced}) =>
      HabitMomentumService(now: () => today, riskAppetite: r);

  group('per-habit scoring', () {
    test('perfect 28d streak -> on track, low risk, A', () {
      final svc = make();
      final profile = HabitProfile(
        habitId: 'water',
        displayName: 'Water',
        weeklyTarget: 7,
      );
      final records = _series('water', today, List.filled(28, true));
      final r = svc.analyze(profiles: [profile], records: records);
      expect(r.habits, hasLength(1));
      final h = r.habits.first;
      expect(h.verdict, HabitVerdict.onTrack);
      expect(h.currentStreak, greaterThanOrEqualTo(27));
      expect(h.weekConsistency, 1.0);
      expect(h.riskScore, lessThan(20));
      expect(r.grade, 'A');
      expect(h.intervention, isNull);
    });

    test('all-miss series -> broken, risk high, grade F', () {
      final svc = make();
      final profile =
          HabitProfile(habitId: 'med', displayName: 'Meditate');
      final records = _series('med', today, List.filled(28, false));
      final r = svc.analyze(profiles: [profile], records: records);
      final h = r.habits.first;
      expect(h.verdict, HabitVerdict.broken);
      expect(h.intervention, isNotNull);
      expect(h.intervention!.dueToday, isTrue);
      expect(r.grade, anyOf(['D', 'F']));
    });

    test('drop from full to 2/7 last week -> breaking + reasons', () {
      final svc = make();
      final profile = HabitProfile(
          habitId: 'workout', displayName: 'Workout', isKeystone: true);
      // 14 prior days perfect, last 7 days mostly missed.
      final mask = <bool>[
        ...List.filled(14, true),
        ...[true, true, false, false, false, false, false],
        ...[false, false, false, false, false, false, false],
      ];
      final records = _series('workout', today, mask);
      final r = svc.analyze(profiles: [profile], records: records);
      final h = r.habits.first;
      expect(h.verdict,
          anyOf([HabitVerdict.breaking, HabitVerdict.broken]));
      expect(h.recentMisses, 3);
      expect(h.reasons.any((s) => s.contains('missed')), isTrue);
      // keystone-aware playbook present (either protect or re-onboard).
      expect(
        r.playbook.any((a) =>
            a.priority == HabitPlaybookPriority.p0 &&
            (a.code == 'PROTECT_KEYSTONE' ||
                a.code == 'RE_ONBOARD_BROKEN')),
        isTrue,
      );
    });

    test('zero-tolerance habit -> single miss flips to broken', () {
      final svc = make();
      final profile = HabitProfile(
        habitId: 'meds',
        displayName: 'Medication',
        zeroToleranceStreak: true,
      );
      final mask = <bool>[
        ...List.filled(20, true),
        ...List.filled(7, true),
        false, // missed today
      ];
      final records = _series('meds', today, mask);
      final r = svc.analyze(profiles: [profile], records: records);
      expect(r.habits.first.verdict, HabitVerdict.broken);
    });

    test('rising momentum: week 2/7 -> week 7/7 flagged momentum_rising', () {
      final svc = make();
      final profile = HabitProfile(habitId: 'read', displayName: 'Read');
      final week2 = List<bool>.filled(7, false);
      week2[0] = true;
      week2[6] = true;
      final mask = <bool>[
        ...List.filled(14, false),
        ...week2,
        ...List.filled(7, true),
      ];
      final records = _series('read', today, mask);
      final r = svc.analyze(profiles: [profile], records: records);
      expect(r.habits.first.verdict, HabitVerdict.momentumRising);
      expect(r.habits.first.intervention, isNotNull);
      expect(
        r.playbook.any((a) => a.code == 'RAISE_TARGET'),
        isTrue,
      );
    });
  });

  group('portfolio aggregation', () {
    test('cluster fatigue: 3 at-risk habits triggers P1 CLUSTER_FATIGUE', () {
      final svc = make();
      final profiles = [
        HabitProfile(habitId: 'a', displayName: 'A'),
        HabitProfile(habitId: 'b', displayName: 'B'),
        HabitProfile(habitId: 'c', displayName: 'C'),
      ];
      // Each: strong then partial slip producing at-risk (not full broken).
      final mask = <bool>[
        ...List.filled(14, true),
        ...List.filled(7, true),
        ...[true, true, false, false, false, true, true],
      ];
      final records = [
        ..._series('a', today, mask),
        ..._series('b', today, mask),
        ..._series('c', today, mask),
      ];
      final r = svc.analyze(profiles: profiles, records: records);
      expect(
        r.playbook.any((a) => a.code == 'CLUSTER_FATIGUE'),
        isTrue,
      );
    });

    test('risk-appetite cautious raises score vs aggressive', () {
      final profile = HabitProfile(habitId: 'x', displayName: 'X');
      // Soft slip: prior week perfect, this week 4/7.
      final mask = <bool>[
        ...List.filled(14, true),
        ...List.filled(7, true),
        ...[true, true, true, false, false, false, true],
      ];
      final records = _series('x', today, mask);
      final cautious = HabitMomentumService(
              now: () => today, riskAppetite: HabitRiskAppetite.cautious)
          .analyze(profiles: [profile], records: records);
      final aggressive = HabitMomentumService(
              now: () => today, riskAppetite: HabitRiskAppetite.aggressive)
          .analyze(profiles: [profile], records: records);
      expect(cautious.habits.first.riskScore,
          greaterThan(aggressive.habits.first.riskScore));
    });

    test('insights: keystone broken surfaces cascading warning', () {
      final svc = make();
      final profiles = [
        HabitProfile(
            habitId: 'sleep',
            displayName: 'Sleep',
            isKeystone: true,
            category: 'health'),
      ];
      final mask = List<bool>.filled(28, false);
      final records = _series('sleep', today, mask);
      final r = svc.analyze(profiles: profiles, records: records);
      expect(
        r.insights.any((s) => s.toLowerCase().contains('keystone')),
        isTrue,
      );
    });

    test('category fatigue insight when >=2 same-category slipping', () {
      final svc = make();
      final profiles = [
        HabitProfile(
            habitId: 'w', displayName: 'Water', category: 'health'),
        HabitProfile(
            habitId: 's', displayName: 'Sleep', category: 'health'),
      ];
      final mask = List<bool>.filled(28, false);
      final records = [
        ..._series('w', today, mask),
        ..._series('s', today, mask),
      ];
      final r = svc.analyze(profiles: profiles, records: records);
      expect(
        r.insights.any((s) => s.toLowerCase().contains('health')),
        isTrue,
      );
    });
  });

  group('formatters', () {
    test('formatText + formatMarkdown emit non-empty output', () {
      final svc = make();
      final profile = HabitProfile(habitId: 'a', displayName: 'A');
      final records = _series(
          'a', today, [...List.filled(21, true), ...List.filled(7, false)]);
      final r = svc.analyze(profiles: [profile], records: records);
      final text = r.formatText();
      final md = r.formatMarkdown();
      expect(text, contains('Habit Momentum Report'));
      expect(md, contains('# Habit Momentum Report'));
      expect(md, contains('| Habit |'));
    });
  });

  group('edge cases', () {
    test('empty profiles -> empty habits, A grade, 0 risk', () {
      final r = make().analyze(profiles: const [], records: const []);
      expect(r.habits, isEmpty);
      expect(r.playbook, isEmpty);
      expect(r.portfolioRisk, 0);
      expect(r.grade, 'A');
    });

    test('habit with no records -> broken verdict', () {
      final svc = make();
      final profile = HabitProfile(habitId: 'ghost', displayName: 'Ghost');
      final r = svc.analyze(profiles: [profile], records: const []);
      expect(r.habits.first.verdict, HabitVerdict.broken);
    });

    test('duplicate records on same day prefer done==true', () {
      final svc = make();
      final profile = HabitProfile(habitId: 'd', displayName: 'D');
      final records = <HabitDailyRecord>[
        HabitDailyRecord(habitId: 'd', date: today, done: false),
        HabitDailyRecord(habitId: 'd', date: today, done: true),
        ...List.generate(
          14,
          (i) => HabitDailyRecord(
            habitId: 'd',
            date: today.subtract(Duration(days: i + 1)),
            done: true,
          ),
        ),
      ];
      final r = svc.analyze(profiles: [profile], records: records);
      expect(r.habits.first.currentStreak, greaterThanOrEqualTo(14));
    });
  });

  group('regression: issue #143 (unlogged != missed)', () {
    // Bug 1: opening the app before today's log used to wipe longestStreak.
    test('today unlogged after 10-day prior streak: longestStreak preserved',
        () {
      final svc = make();
      final profile = HabitProfile(habitId: 'x', displayName: 'X');
      // 10 consecutive done days ending yesterday; today has no record.
      final records = List<HabitDailyRecord>.generate(
        10,
        (i) => HabitDailyRecord(
          habitId: 'x',
          // i=0 -> yesterday, i=9 -> 10 days ago
          date: today.subtract(Duration(days: i + 1)),
          done: true,
        ),
      );
      final r = svc.analyze(profiles: [profile], records: records).habits.first;
      expect(r.currentStreak, 10,
          reason: 'today unlogged should not zero a 10-day run');
      expect(r.longestStreak, 10,
          reason: 'longestStreak must capture the open run when today is unlogged');
    });

    // Bug 2: sparse-but-clean histories (Mon/Wed/Fri) used to generate
    // spurious BREAKING / BROKEN verdicts because null was treated as a miss.
    test('sparse history (M/W/F all done) does not trigger BREAKING', () {
      // today = Sunday 2026-05-17, so this week's M/W/F are 11/13/15.
      final svc = make();
      final profile = HabitProfile(
        habitId: 'sparse',
        displayName: 'Sparse',
        weeklyTarget: 3,
      );
      final logged = <DateTime>[
        _d(2026, 5, 4), _d(2026, 5, 6), _d(2026, 5, 8),  // prev week M/W/F
        _d(2026, 5, 11), _d(2026, 5, 13), _d(2026, 5, 15), // this week M/W/F
      ];
      final records = logged
          .map((d) => HabitDailyRecord(habitId: 'sparse', date: d, done: true))
          .toList();
      final r = svc.analyze(profiles: [profile], records: records).habits.first;
      expect(r.verdict, isNot(HabitVerdict.breaking),
          reason: 'clean sparse history should not be flagged BREAKING');
      expect(r.verdict, isNot(HabitVerdict.broken),
          reason: 'clean sparse history should not be flagged BROKEN');
      // No explicit logged misses anywhere in the window.
      // riskScore should be modest, well below the BREAKING threshold.
      expect(r.riskScore, lessThan(70.0));
    });

    // Bug 2 policy split: zero-tolerance habits must still break on gap.
    test('zero-tolerance habit: unlogged day mid-window still breaks streak',
        () {
      final svc = make();
      final profile = HabitProfile(
        habitId: 'meds',
        displayName: 'Meds',
        zeroToleranceStreak: true,
      );
      // Done for the last 5 days INCLUDING today, but with a gap at day-2
      // (yesterday-but-one) where no record exists.
      final records = <HabitDailyRecord>[
        HabitDailyRecord(habitId: 'meds', date: today, done: true),
        HabitDailyRecord(
            habitId: 'meds',
            date: today.subtract(const Duration(days: 1)),
            done: true),
        // day -2 intentionally omitted (unlogged)
        HabitDailyRecord(
            habitId: 'meds',
            date: today.subtract(const Duration(days: 3)),
            done: true),
        HabitDailyRecord(
            habitId: 'meds',
            date: today.subtract(const Duration(days: 4)),
            done: true),
      ];
      final r = svc.analyze(profiles: [profile], records: records).habits.first;
      // Walking back from today: done, done, unlogged -> break.
      // currentStreak should be 2, not 4.
      expect(r.currentStreak, 2,
          reason: 'zero-tolerance habit must treat unlogged as breaking');
    });

    // Empty / freshly-onboarded profile must not be graded BROKEN.
    test('empty records produces onTrack, not BROKEN', () {
      final svc = make();
      final profiles = List<HabitProfile>.generate(
        5,
        (i) => HabitProfile(habitId: 'h$i', displayName: 'H$i'),
      );
      final r = svc.analyze(profiles: profiles, records: const []);
      for (final h in r.habits) {
        expect(h.verdict, HabitVerdict.onTrack,
            reason: 'empty history must default to onTrack');
        expect(h.riskScore, lessThan(70.0));
      }
    });
  });
}
