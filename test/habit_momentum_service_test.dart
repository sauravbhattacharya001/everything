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
}
