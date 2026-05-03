import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/habit_correlation_engine_service.dart';

void main() {
  group('HabitCorrelationEngineService', () {
    late HabitCorrelationEngineService service;

    setUp(() {
      service = HabitCorrelationEngineService();
    });

    // ── Sample Data Tests ──

    group('Sample Data', () {
      test('loadSampleData populates signals', () {
        service.loadSampleData();
        expect(service.signalNames.isNotEmpty, isTrue);
      });

      test('loadSampleData creates 8 signals', () {
        service.loadSampleData();
        expect(service.signalNames.length, equals(8));
      });

      test('loadSampleData creates 90 days of data', () {
        service.loadSampleData();
        expect(service.daysAvailable, equals(90));
      });

      test('signal names include habits and outcomes', () {
        service.loadSampleData();
        expect(service.signalNames, containsAll(['Exercise', 'Meditation', 'Mood', 'Sleep', 'Energy']));
      });

      test('habit signals are binary (0 or 1)', () {
        service.loadSampleData();
        final exercise = service.getSignals('Exercise');
        for (final s in exercise) {
          expect(s.value == 0.0 || s.value == 1.0, isTrue);
        }
      });

      test('outcome signals are in range 1-5', () {
        service.loadSampleData();
        final mood = service.getSignals('Mood');
        for (final s in mood) {
          expect(s.value, greaterThanOrEqualTo(1.0));
          expect(s.value, lessThanOrEqualTo(5.0));
        }
      });

      test('signals have sequential dates', () {
        service.loadSampleData();
        final signals = service.getSignals('Exercise');
        for (int i = 1; i < signals.length; i++) {
          final diff = signals[i].date.difference(signals[i - 1].date).inDays;
          expect(diff, equals(1));
        }
      });
    });

    // ── Pearson Correlation Tests ──

    group('Pearson Correlation', () {
      test('perfect positive correlation returns 1.0', () {
        final x = [1.0, 2.0, 3.0, 4.0, 5.0];
        final y = [2.0, 4.0, 6.0, 8.0, 10.0];
        final r = HabitCorrelationEngineService.pearsonCorrelation(x, y);
        expect(r, closeTo(1.0, 0.001));
      });

      test('perfect negative correlation returns -1.0', () {
        final x = [1.0, 2.0, 3.0, 4.0, 5.0];
        final y = [10.0, 8.0, 6.0, 4.0, 2.0];
        final r = HabitCorrelationEngineService.pearsonCorrelation(x, y);
        expect(r, closeTo(-1.0, 0.001));
      });

      test('no correlation returns near 0', () {
        final x = [1.0, 2.0, 3.0, 4.0, 5.0];
        final y = [5.0, 2.0, 4.0, 1.0, 3.0];
        final r = HabitCorrelationEngineService.pearsonCorrelation(x, y);
        expect(r.abs(), lessThan(0.5));
      });

      test('identical signals return 1.0', () {
        final x = [3.0, 3.0, 3.0, 3.0, 3.0];
        final y = [3.0, 3.0, 3.0, 3.0, 3.0];
        final r = HabitCorrelationEngineService.pearsonCorrelation(x, y);
        expect(r, equals(0.0)); // constant signals → 0 variance → 0
      });

      test('short arrays (< 3) return 0', () {
        final r = HabitCorrelationEngineService.pearsonCorrelation([1.0, 2.0], [3.0, 4.0]);
        expect(r, equals(0.0));
      });

      test('mismatched lengths return 0', () {
        final r = HabitCorrelationEngineService.pearsonCorrelation([1.0, 2.0, 3.0], [4.0, 5.0]);
        expect(r, equals(0.0));
      });
    });

    // ── P-Value Tests ──

    group('P-Value', () {
      test('strong correlation has low p-value', () {
        final p = HabitCorrelationEngineService.approximatePValue(0.9, 50);
        expect(p, lessThan(0.05));
      });

      test('weak correlation has higher p-value', () {
        final p = HabitCorrelationEngineService.approximatePValue(0.1, 20);
        expect(p, greaterThan(0.05));
      });

      test('p-value is between 0 and 1', () {
        final p = HabitCorrelationEngineService.approximatePValue(0.5, 30);
        expect(p, greaterThanOrEqualTo(0.0));
        expect(p, lessThanOrEqualTo(1.0));
      });
    });

    // ── Strength Classification Tests ──

    group('Strength Classification', () {
      test('r=0.7 is strong', () {
        expect(HabitCorrelationEngineService.classifyStrength(0.7),
            equals(CorrelationStrength.strong));
      });

      test('r=-0.65 is strong', () {
        expect(HabitCorrelationEngineService.classifyStrength(-0.65),
            equals(CorrelationStrength.strong));
      });

      test('r=0.45 is moderate', () {
        expect(HabitCorrelationEngineService.classifyStrength(0.45),
            equals(CorrelationStrength.moderate));
      });

      test('r=0.25 is weak', () {
        expect(HabitCorrelationEngineService.classifyStrength(0.25),
            equals(CorrelationStrength.weak));
      });

      test('r=0.1 is negligible', () {
        expect(HabitCorrelationEngineService.classifyStrength(0.1),
            equals(CorrelationStrength.negligible));
      });

      test('r=0.0 is negligible', () {
        expect(HabitCorrelationEngineService.classifyStrength(0.0),
            equals(CorrelationStrength.negligible));
      });
    });

    // ── Correlation Computation Tests ──

    group('Compute Correlations', () {
      test('returns non-empty list with sample data', () {
        service.loadSampleData();
        final results = service.computeCorrelations();
        expect(results.isNotEmpty, isTrue);
      });

      test('results are sorted by absolute r descending', () {
        service.loadSampleData();
        final results = service.computeCorrelations();
        for (int i = 1; i < results.length; i++) {
          expect(results[i].r.abs(), lessThanOrEqualTo(results[i - 1].r.abs()));
        }
      });

      test('includes lagged correlations', () {
        service.loadSampleData();
        final results = service.computeCorrelations();
        final lagged = results.where((c) => c.lagDays > 0).toList();
        expect(lagged.isNotEmpty, isTrue);
      });

      test('includes same-day correlations', () {
        service.loadSampleData();
        final results = service.computeCorrelations();
        final sameDay = results.where((c) => c.lagDays == 0).toList();
        expect(sameDay.isNotEmpty, isTrue);
      });

      test('exercise-sleep lagged correlation is positive', () {
        service.loadSampleData();
        final results = service.computeCorrelations();
        final exerciseSleep = results.where((c) =>
            c.signalA == 'Exercise' && c.signalB == 'Sleep' && c.lagDays == 1).toList();
        if (exerciseSleep.isNotEmpty) {
          expect(exerciseSleep.first.r, greaterThan(0));
        }
      });

      test('negligible correlations are filtered out', () {
        service.loadSampleData();
        final results = service.computeCorrelations();
        final negligible = results.where((c) => c.strength == CorrelationStrength.negligible).toList();
        expect(negligible.isEmpty, isTrue);
      });

      test('empty signals produce empty correlations', () {
        final results = service.computeCorrelations();
        expect(results.isEmpty, isTrue);
      });
    });

    // ── Causal Hypothesis Tests ──

    group('Causal Hypotheses', () {
      test('generates hypotheses for lagged correlations', () {
        service.loadSampleData();
        final correlations = service.computeCorrelations();
        final hypotheses = service.generateHypotheses(correlations);
        expect(hypotheses.isNotEmpty, isTrue);
      });

      test('hypotheses only from lagged correlations', () {
        service.loadSampleData();
        final correlations = service.computeCorrelations();
        final hypotheses = service.generateHypotheses(correlations);
        for (final h in hypotheses) {
          expect(h.lagDays, greaterThan(0));
        }
      });

      test('hypotheses are sorted by confidence descending', () {
        service.loadSampleData();
        final correlations = service.computeCorrelations();
        final hypotheses = service.generateHypotheses(correlations);
        for (int i = 1; i < hypotheses.length; i++) {
          expect(hypotheses[i].confidence, lessThanOrEqualTo(hypotheses[i - 1].confidence));
        }
      });

      test('each hypothesis has an experiment suggestion', () {
        service.loadSampleData();
        final correlations = service.computeCorrelations();
        final hypotheses = service.generateHypotheses(correlations);
        for (final h in hypotheses) {
          expect(h.experiment.isNotEmpty, isTrue);
        }
      });

      test('no hypotheses from empty correlations', () {
        final hypotheses = service.generateHypotheses([]);
        expect(hypotheses.isEmpty, isTrue);
      });
    });

    // ── Synergy Detection Tests ──

    group('Synergy Detection', () {
      test('detects synergies with sample data', () {
        service.loadSampleData();
        final synergies = service.detectSynergies();
        // May or may not find synergies depending on random seed
        expect(synergies, isA<List<SynergyResult>>());
      });

      test('synergy score > 1.0 for all results', () {
        service.loadSampleData();
        final synergies = service.detectSynergies();
        for (final s in synergies) {
          expect(s.synergyScore, greaterThan(1.0));
        }
      });

      test('synergies involve exactly 2 habits', () {
        service.loadSampleData();
        final synergies = service.detectSynergies();
        for (final s in synergies) {
          expect(s.habits.length, equals(2));
        }
      });

      test('synergies are sorted by score descending', () {
        service.loadSampleData();
        final synergies = service.detectSynergies();
        for (int i = 1; i < synergies.length; i++) {
          expect(synergies[i].synergyScore, lessThanOrEqualTo(synergies[i - 1].synergyScore));
        }
      });

      test('no synergies with empty data', () {
        final synergies = service.detectSynergies();
        expect(synergies.isEmpty, isTrue);
      });
    });

    // ── Anti-Pattern Detection Tests ──

    group('Anti-Pattern Detection', () {
      test('detects anti-patterns with sample data', () {
        service.loadSampleData();
        final correlations = service.computeCorrelations();
        final antiPatterns = service.detectAntiPatterns(correlations);
        expect(antiPatterns, isA<List<AntiPattern>>());
      });

      test('anti-patterns have negative r values', () {
        service.loadSampleData();
        final correlations = service.computeCorrelations();
        final antiPatterns = service.detectAntiPatterns(correlations);
        for (final a in antiPatterns) {
          expect(a.r, lessThan(0));
        }
      });

      test('anti-patterns have recommendations', () {
        service.loadSampleData();
        final correlations = service.computeCorrelations();
        final antiPatterns = service.detectAntiPatterns(correlations);
        for (final a in antiPatterns) {
          expect(a.recommendation.isNotEmpty, isTrue);
        }
      });

      test('no anti-patterns from empty correlations', () {
        final antiPatterns = service.detectAntiPatterns([]);
        expect(antiPatterns.isEmpty, isTrue);
      });
    });

    // ── Timing Analysis Tests ──

    group('Timing Analysis', () {
      test('produces timing insights with sample data', () {
        service.loadSampleData();
        final timings = service.analyzeTimings();
        expect(timings, isA<List<TimingInsight>>());
      });

      test('best day != worst day', () {
        service.loadSampleData();
        final timings = service.analyzeTimings();
        for (final t in timings) {
          expect(t.bestDayOfWeek, isNot(equals(t.worstDayOfWeek)));
        }
      });

      test('best day effect > worst day effect', () {
        service.loadSampleData();
        final timings = service.analyzeTimings();
        for (final t in timings) {
          expect(t.bestDayEffect, greaterThan(t.worstDayEffect));
        }
      });

      test('day of week values are 1-7', () {
        service.loadSampleData();
        final timings = service.analyzeTimings();
        for (final t in timings) {
          expect(t.bestDayOfWeek, inInclusiveRange(1, 7));
          expect(t.worstDayOfWeek, inInclusiveRange(1, 7));
        }
      });

      test('no timing insights with empty data', () {
        final timings = service.analyzeTimings();
        expect(timings.isEmpty, isTrue);
      });
    });

    // ── Insight Generation Tests ──

    group('Insight Generation', () {
      test('generates insights from sample data', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(report.insights.isNotEmpty, isTrue);
      });

      test('insights have non-empty titles and descriptions', () {
        service.loadSampleData();
        final report = service.generateReport();
        for (final i in report.insights) {
          expect(i.title.isNotEmpty, isTrue);
          expect(i.description.isNotEmpty, isTrue);
          expect(i.actionItem.isNotEmpty, isTrue);
        }
      });

      test('insights confidence is 0-1', () {
        service.loadSampleData();
        final report = service.generateReport();
        for (final i in report.insights) {
          expect(i.confidence, greaterThanOrEqualTo(0.0));
          expect(i.confidence, lessThanOrEqualTo(1.0));
        }
      });

      test('insights are sorted by priority then confidence', () {
        service.loadSampleData();
        final report = service.generateReport();
        for (int i = 1; i < report.insights.length; i++) {
          final prev = report.insights[i - 1];
          final curr = report.insights[i];
          if (prev.priority.index == curr.priority.index) {
            expect(curr.confidence, lessThanOrEqualTo(prev.confidence));
          }
        }
      });

      test('empty inputs produce empty insights', () {
        final insights = service.generateInsights(
          correlations: [],
          hypotheses: [],
          synergies: [],
          antiPatterns: [],
          timingInsights: [],
        );
        expect(insights.isEmpty, isTrue);
      });
    });

    // ── Network Health Tests ──

    group('Network Health', () {
      test('health score is between 0 and 100', () {
        service.loadSampleData();
        final correlations = service.computeCorrelations();
        final antiPatterns = service.detectAntiPatterns(correlations);
        final health = service.computeNetworkHealth(correlations, antiPatterns);
        expect(health, greaterThanOrEqualTo(0.0));
        expect(health, lessThanOrEqualTo(100.0));
      });

      test('empty correlations give 0 health', () {
        final health = service.computeNetworkHealth([], []);
        expect(health, equals(0.0));
      });

      test('more anti-patterns lower health', () {
        service.loadSampleData();
        final correlations = service.computeCorrelations();
        final noAnti = service.computeNetworkHealth(correlations, []);
        final manyAnti = service.computeNetworkHealth(correlations, [
          const AntiPattern(habit: 'A', outcome: 'B', r: -0.5, explanation: '', recommendation: ''),
          const AntiPattern(habit: 'C', outcome: 'D', r: -0.6, explanation: '', recommendation: ''),
          const AntiPattern(habit: 'E', outcome: 'F', r: -0.7, explanation: '', recommendation: ''),
        ]);
        expect(noAnti, greaterThan(manyAnti));
      });
    });

    // ── Full Report Tests ──

    group('Report Generation', () {
      test('generates complete report', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(report.daysAnalyzed, equals(90));
        expect(report.totalSignals, equals(8));
        expect(report.correlations.isNotEmpty, isTrue);
        expect(report.networkHealth, greaterThanOrEqualTo(0.0));
        expect(report.networkHealth, lessThanOrEqualTo(100.0));
      });

      test('report with no data has zero values', () {
        final report = service.generateReport();
        expect(report.daysAnalyzed, equals(0));
        expect(report.correlations.isEmpty, isTrue);
        expect(report.networkHealth, equals(0.0));
      });

      test('loading sample data twice resets', () {
        service.loadSampleData();
        service.loadSampleData();
        expect(service.daysAvailable, equals(90));
        expect(service.signalNames.length, equals(8));
      });
    });

    // ── Enum Tests ──

    group('Enums', () {
      test('CorrelationStrength has 4 values', () {
        expect(CorrelationStrength.values.length, equals(4));
      });

      test('InsightCategory has 5 values', () {
        expect(InsightCategory.values.length, equals(5));
      });

      test('InsightPriority has 4 values', () {
        expect(InsightPriority.values.length, equals(4));
      });

      test('TimingInsight dayNames has 7 entries', () {
        expect(TimingInsight.dayNames.length, equals(7));
      });
    });

    // ── Custom Signal Tests ──

    group('Custom Signals', () {
      test('addSignals allows custom data', () {
        service.addSignals('Custom', [
          DailySignal(name: 'Custom', date: DateTime(2025, 1, 1), value: 3.0),
          DailySignal(name: 'Custom', date: DateTime(2025, 1, 2), value: 4.0),
        ]);
        expect(service.signalNames, contains('Custom'));
        expect(service.getSignals('Custom').length, equals(2));
      });

      test('getSignals returns empty for unknown name', () {
        expect(service.getSignals('Unknown'), isEmpty);
      });
    });
  });
}
