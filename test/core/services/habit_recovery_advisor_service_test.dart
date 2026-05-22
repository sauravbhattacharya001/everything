import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/habit_recovery_advisor_service.dart';

void main() {
  late HabitRecoveryAdvisorService svc;
  final DateTime fixedNow = DateTime.utc(2026, 5, 22, 12);
  RecoveryOptions optsAt({
    RecoveryRiskAppetite app = RecoveryRiskAppetite.balanced,
    int lookback = 28,
  }) =>
      RecoveryOptions(
        riskAppetite: app,
        lookbackDays: lookback,
        now: () => fixedNow,
      );

  HabitRecoverySnapshot snap({
    String id = 'h',
    String title = 'Habit',
    String category = 'health',
    int priorityWeight = 3,
    DateTime? createdAt,
    DateTime? lastCompletionAt,
    double freq = 7,
    int completions = 0,
    int longestStreak = 0,
    int currentStreak = 0,
    int restartCount = 0,
    DateTime? pausedAt,
    DateTime? abandonedAt,
  }) =>
      HabitRecoverySnapshot(
        id: id,
        title: title,
        category: category,
        priorityWeight: priorityWeight,
        createdAt: createdAt ?? fixedNow.subtract(const Duration(days: 60)),
        lastCompletionAt: lastCompletionAt,
        expectedFrequencyPerWeek: freq,
        completionsInWindow: completions,
        longestStreak: longestStreak,
        currentStreak: currentStreak,
        restartCount: restartCount,
        pausedAt: pausedAt,
        abandonedAt: abandonedAt,
      );

  setUp(() {
    svc = HabitRecoveryAdvisorService();
  });

  group('Empty + degenerate input', () {
    test('empty list returns healthy zero report', () {
      final r = svc.advise([], options: optsAt());
      expect(r.totalHabits, 0);
      expect(r.lapsedCount, 0);
      expect(r.grade, 'A');
      expect(r.band, RecoveryPortfolioBand.healthy);
      expect(r.forecasts, isEmpty);
      expect(r.playbook.length, 1);
      expect(r.playbook.first.priority, RecoveryPriority.p3);
      expect(r.headline, 'No habits to advise on.');
    });
  });

  group('Per-habit verdicts', () {
    test('recent completion -> keep_active_no_action', () {
      final s = snap(
        id: 'a',
        lastCompletionAt: fixedNow.subtract(const Duration(days: 1)),
        completions: 25,
        currentStreak: 25,
      );
      final r = svc.advise([s], options: optsAt());
      final f = r.forecasts.single;
      expect(f.verdict, HabitRecoveryVerdict.keepActiveNoAction);
      expect(f.reasons, contains('RECENT_COMPLETION'));
    });

    test('fresh lapse within grace -> resume_tomorrow', () {
      final s = snap(
        id: 'b',
        lastCompletionAt: fixedNow.subtract(const Duration(days: 5)),
        freq: 7,
        completions: 15,
        longestStreak: 30,
      );
      final r = svc.advise([s], options: optsAt());
      expect(r.forecasts.single.verdict, HabitRecoveryVerdict.resumeTomorrow);
    });

    test('partial adherence -> scale_down', () {
      final s = snap(
        id: 'c',
        lastCompletionAt: fixedNow.subtract(const Duration(days: 6)),
        freq: 7,
        completions: 14, // ratio = 14 / 28 = 0.5
        longestStreak: 10,
      );
      final r = svc.advise([s], options: optsAt());
      expect(r.forecasts.single.verdict, HabitRecoveryVerdict.scaleDown);
    });

    test('chronic restarts + low ratio -> restructure', () {
      final s = snap(
        id: 'd',
        lastCompletionAt: fixedNow.subtract(const Duration(days: 8)),
        freq: 7,
        completions: 4, // ratio ~0.14
        restartCount: 4,
        longestStreak: 10,
      );
      final r = svc.advise([s], options: optsAt());
      expect(r.forecasts.single.verdict, HabitRecoveryVerdict.restructure);
      expect(r.forecasts.single.reasons, contains('CHRONIC_RESTARTS'));
    });

    test('low adherence never stuck -> drop_and_archive', () {
      final s = snap(
        id: 'e',
        lastCompletionAt: fixedNow.subtract(const Duration(days: 14)),
        freq: 7,
        completions: 2,
        longestStreak: 3,
      );
      final r = svc.advise([s], options: optsAt());
      expect(r.forecasts.single.verdict, HabitRecoveryVerdict.dropAndArchive);
    });

    test('long lapse -> restructure', () {
      final s = snap(
        id: 'f',
        lastCompletionAt: fixedNow.subtract(const Duration(days: 80)),
        freq: 7,
        completions: 0,
        longestStreak: 30,
      );
      final r = svc.advise([s], options: optsAt());
      expect(r.forecasts.single.verdict, HabitRecoveryVerdict.restructure);
      expect(r.forecasts.single.reasons, contains('LONG_LAPSE'));
    });

    test('paused -> pause_intentionally', () {
      final s = snap(
        id: 'g',
        lastCompletionAt: fixedNow.subtract(const Duration(days: 30)),
        pausedAt: fixedNow.subtract(const Duration(days: 14)),
      );
      final r = svc.advise([s], options: optsAt());
      expect(
          r.forecasts.single.verdict, HabitRecoveryVerdict.pauseIntentionally);
    });

    test('abandoned -> drop_and_archive', () {
      final s = snap(
        id: 'h',
        lastCompletionAt: fixedNow.subtract(const Duration(days: 90)),
        abandonedAt: fixedNow.subtract(const Duration(days: 30)),
      );
      final r = svc.advise([s], options: optsAt());
      expect(r.forecasts.single.verdict, HabitRecoveryVerdict.dropAndArchive);
      expect(r.forecasts.single.reasons, contains('ABANDONED_BY_USER'));
    });

    test('new habit no completions in first week -> probation', () {
      final s = snap(
        id: 'i',
        createdAt: fixedNow.subtract(const Duration(days: 3)),
        lastCompletionAt: null,
      );
      final r = svc.advise([s], options: optsAt());
      expect(
          r.forecasts.single.verdict, HabitRecoveryVerdict.newHabitProbation);
    });

    test('never completed older than a week -> drop_and_archive', () {
      final s = snap(
        id: 'j',
        createdAt: fixedNow.subtract(const Duration(days: 30)),
        lastCompletionAt: null,
      );
      final r = svc.advise([s], options: optsAt());
      expect(r.forecasts.single.verdict, HabitRecoveryVerdict.dropAndArchive);
    });
  });

  group('Difficulty + sorting', () {
    test('forecasts sorted by difficulty desc then id asc', () {
      final hard = snap(
        id: 'zzz',
        lastCompletionAt: fixedNow.subtract(const Duration(days: 40)),
        freq: 7,
        completions: 1,
        restartCount: 4,
        priorityWeight: 5,
      );
      final easy = snap(
        id: 'aaa',
        lastCompletionAt: fixedNow.subtract(const Duration(days: 1)),
        freq: 7,
        completions: 25,
      );
      final r = svc.advise([easy, hard], options: optsAt());
      expect(r.forecasts.first.id, 'zzz');
      expect(r.forecasts.last.id, 'aaa');
    });

    test('aggressive appetite lowers difficulty vs cautious', () {
      final s = snap(
        id: 'k',
        lastCompletionAt: fixedNow.subtract(const Duration(days: 10)),
        freq: 7,
        completions: 7,
        priorityWeight: 5,
      );
      final cautious =
          svc.advise([s], options: optsAt(app: RecoveryRiskAppetite.cautious));
      final aggressive = svc.advise([s],
          options: optsAt(app: RecoveryRiskAppetite.aggressive));
      expect(cautious.forecasts.single.recoveryDifficulty,
          greaterThan(aggressive.forecasts.single.recoveryDifficulty));
    });
  });

  group('Portfolio aggregates + grade', () {
    test('all healthy -> grade A', () {
      final list = List.generate(
        3,
        (i) => snap(
          id: 'h$i',
          lastCompletionAt: fixedNow.subtract(const Duration(days: 1)),
          completions: 25,
        ),
      );
      final r = svc.advise(list, options: optsAt());
      expect(r.grade, 'A');
      expect(r.band, RecoveryPortfolioBand.healthy);
      expect(r.lapsedCount, 0);
    });

    test('two high-priority restructures -> grade F', () {
      final list = [
        snap(
          id: 'a',
          priorityWeight: 5,
          lastCompletionAt: fixedNow.subtract(const Duration(days: 8)),
          freq: 7,
          completions: 4,
          restartCount: 4,
        ),
        snap(
          id: 'b',
          priorityWeight: 4,
          lastCompletionAt: fixedNow.subtract(const Duration(days: 9)),
          freq: 7,
          completions: 3,
          restartCount: 5,
        ),
      ];
      final r = svc.advise(list, options: optsAt());
      expect(r.grade, 'F');
    });
  });

  group('Playbook construction', () {
    test('high-priority restructure surfaces as P0', () {
      final list = [
        snap(
          id: 'a',
          priorityWeight: 5,
          lastCompletionAt: fixedNow.subtract(const Duration(days: 8)),
          freq: 7,
          completions: 4,
          restartCount: 4,
        ),
      ];
      final r = svc.advise(list, options: optsAt());
      expect(r.playbook.any((a) => a.priority == RecoveryPriority.p0), isTrue);
      final p0 = r.playbook.firstWhere((a) => a.priority == RecoveryPriority.p0);
      expect(p0.relatedIds, contains('a'));
    });

    test('two drop candidates -> P0 archive action', () {
      final list = [
        snap(
          id: 'a',
          lastCompletionAt: fixedNow.subtract(const Duration(days: 14)),
          freq: 7,
          completions: 1,
          longestStreak: 2,
        ),
        snap(
          id: 'b',
          lastCompletionAt: fixedNow.subtract(const Duration(days: 16)),
          freq: 7,
          completions: 2,
          longestStreak: 3,
        ),
      ];
      final r = svc.advise(list, options: optsAt());
      final archive = r.playbook.where((a) => a.label.contains('Archive'));
      expect(archive, isNotEmpty);
      expect(archive.first.priority, RecoveryPriority.p0);
    });

    test('aggressive trims lone P2 when P0/P1 present', () {
      final list = [
        snap(
          id: 'fresh',
          lastCompletionAt: fixedNow.subtract(const Duration(days: 4)),
          freq: 7,
          completions: 18,
        ),
        snap(
          id: 'new1',
          createdAt: fixedNow.subtract(const Duration(days: 2)),
          lastCompletionAt: null,
        ),
      ];
      final balanced =
          svc.advise(list, options: optsAt(app: RecoveryRiskAppetite.balanced));
      final aggressive = svc.advise(list,
          options: optsAt(app: RecoveryRiskAppetite.aggressive));
      final balancedHasP2 =
          balanced.playbook.any((a) => a.priority == RecoveryPriority.p2);
      final aggressiveHasP2 =
          aggressive.playbook.any((a) => a.priority == RecoveryPriority.p2);
      expect(balancedHasP2, isTrue);
      expect(aggressiveHasP2, isFalse);
    });

    test('cautious adds weekly review action when grade not A/B', () {
      final list = [
        snap(
          id: 'a',
          priorityWeight: 5,
          lastCompletionAt: fixedNow.subtract(const Duration(days: 8)),
          freq: 7,
          completions: 4,
          restartCount: 4,
        ),
      ];
      final cautious = svc.advise(list,
          options: optsAt(app: RecoveryRiskAppetite.cautious));
      expect(
          cautious.playbook.any((a) => a.label.contains('weekly habit-portfolio review')),
          isTrue);
    });
  });

  group('Insights', () {
    test('high priority lapse cluster', () {
      final list = [
        snap(
          id: 'a',
          priorityWeight: 5,
          lastCompletionAt: fixedNow.subtract(const Duration(days: 5)),
          freq: 7,
          completions: 10,
        ),
        snap(
          id: 'b',
          priorityWeight: 4,
          lastCompletionAt: fixedNow.subtract(const Duration(days: 6)),
          freq: 7,
          completions: 9,
        ),
      ];
      final r = svc.advise(list, options: optsAt());
      expect(
          r.insights.any((i) => i.startsWith('HIGH_PRIORITY_LAPSE_CLUSTER')),
          isTrue);
    });

    test('category hotspot fires when >= 3 lapsed in same category', () {
      final list = List.generate(3, (i) => snap(
            id: 'h$i',
            category: 'fitness',
            lastCompletionAt: fixedNow.subtract(const Duration(days: 6)),
            freq: 7,
            completions: 12, // ratio ~0.43 -> scale_down
            longestStreak: 10,
          ));
      final r = svc.advise(list, options: optsAt());
      expect(
          r.insights.any((i) => i.startsWith('CATEGORY_HOTSPOT')), isTrue);
    });

    test('healthy portfolio insight when nothing lapsed', () {
      final list = List.generate(
        3,
        (i) => snap(
          id: 'h$i',
          lastCompletionAt: fixedNow.subtract(const Duration(days: 1)),
          completions: 25,
        ),
      );
      final r = svc.advise(list, options: optsAt());
      expect(
          r.insights.any((i) => i.startsWith('HEALTHY_PORTFOLIO')), isTrue);
    });
  });

  group('Renderers', () {
    test('text renderer includes headline and sections', () {
      final r = svc.advise([
        snap(
          id: 'a',
          lastCompletionAt: fixedNow.subtract(const Duration(days: 5)),
          freq: 7,
          completions: 15,
          longestStreak: 20,
        ),
      ], options: optsAt());
      final out = svc.toText(r);
      expect(out, contains('Habit Recovery Report'));
      expect(out, contains('Insights:'));
      expect(out, contains('Forecasts:'));
      expect(out, contains('Playbook:'));
    });

    test('markdown renderer has tables', () {
      final r = svc.advise([
        snap(
          id: 'a',
          lastCompletionAt: fixedNow.subtract(const Duration(days: 5)),
          freq: 7,
          completions: 15,
          longestStreak: 20,
        ),
      ], options: optsAt());
      final md = svc.toMarkdown(r);
      expect(md, contains('# Habit Recovery Report'));
      expect(md, contains('## Forecasts'));
      expect(md, contains('| Habit |'));
      expect(md, contains('## Playbook'));
    });

    test('json renderer is byte-stable across runs', () {
      final list = [
        snap(
          id: 'a',
          lastCompletionAt: fixedNow.subtract(const Duration(days: 5)),
          freq: 7,
          completions: 15,
          longestStreak: 20,
        ),
        snap(
          id: 'b',
          lastCompletionAt: fixedNow.subtract(const Duration(days: 1)),
          completions: 25,
        ),
      ];
      final r1 = svc.advise(list, options: optsAt());
      final r2 = svc.advise(list, options: optsAt());
      expect(svc.toJson(r1), equals(svc.toJson(r2)));
      expect(svc.toJson(r1), contains('"grade":"'));
      expect(svc.toJson(r1), contains('"forecasts":'));
    });
  });

  group('Determinism + immutability', () {
    test('repeated invocation yields identical report payload', () {
      final list = [
        snap(
          id: 'a',
          priorityWeight: 5,
          lastCompletionAt: fixedNow.subtract(const Duration(days: 8)),
          freq: 7,
          completions: 4,
          restartCount: 4,
        ),
        snap(
          id: 'b',
          lastCompletionAt: fixedNow.subtract(const Duration(days: 1)),
          completions: 25,
        ),
      ];
      final r1 = svc.advise(list, options: optsAt());
      final r2 = svc.advise(list, options: optsAt());
      expect(r1.portfolioRecoveryScore, r2.portfolioRecoveryScore);
      expect(r1.grade, r2.grade);
      expect(r1.headline, r2.headline);
      expect(r1.forecasts.length, r2.forecasts.length);
      expect(r1.playbook.length, r2.playbook.length);
    });
  });
}
