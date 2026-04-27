import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/experiment_engine_service.dart';

void main() {
  late ExperimentEngineService service;

  setUp(() {
    service = const ExperimentEngineService();
  });

  // ── Enum Labels ──

  group('ExperimentStatus', () {
    test('label returns human-readable string', () {
      expect(ExperimentStatus.draft.label, 'Draft');
      expect(ExperimentStatus.baseline.label, 'Baseline');
      expect(ExperimentStatus.active.label, 'Active');
      expect(ExperimentStatus.completed.label, 'Completed');
    });

    test('emoji returns correct indicator', () {
      expect(ExperimentStatus.draft.emoji, '📝');
      expect(ExperimentStatus.active.emoji, '🧪');
      expect(ExperimentStatus.completed.emoji, '✅');
    });
  });

  group('ExperimentOutcome', () {
    test('label returns human-readable string', () {
      expect(ExperimentOutcome.confirmed.label, 'Hypothesis Confirmed');
      expect(ExperimentOutcome.rejected.label, 'Hypothesis Rejected');
      expect(ExperimentOutcome.inconclusive.label, 'Inconclusive');
    });

    test('emoji returns correct indicator', () {
      expect(ExperimentOutcome.confirmed.emoji, '✅');
      expect(ExperimentOutcome.rejected.emoji, '❌');
      expect(ExperimentOutcome.inconclusive.emoji, '🤷');
    });
  });

  group('ConfidenceLevel', () {
    test('label returns human-readable string', () {
      expect(ConfidenceLevel.low.label, 'Low');
      expect(ConfidenceLevel.veryHigh.label, 'Very High');
    });
  });

  group('EffectMagnitude', () {
    test('label returns human-readable string', () {
      expect(EffectMagnitude.negligible.label, 'Negligible');
      expect(EffectMagnitude.small.label, 'Small');
      expect(EffectMagnitude.medium.label, 'Medium');
      expect(EffectMagnitude.large.label, 'Large');
    });
  });

  // ── Experiment Creation ──

  group('createExperiment', () {
    test('creates experiment in draft status with defaults', () {
      const hypothesis = ExperimentHypothesis(
        intervention: 'Test intervention',
        expectedOutcome: 'Better outcome',
        metric: 'test_metric',
        direction: 'increase',
      );
      final exp = service.createExperiment(hypothesis);

      expect(exp.status, ExperimentStatus.draft);
      expect(exp.hypothesis.intervention, 'Test intervention');
      expect(exp.data, isEmpty);
      expect(exp.insights, isEmpty);
      expect(exp.result, isNull);
      expect(exp.outcome, isNull);
      expect(exp.config.baselineDays, 7);
      expect(exp.config.experimentDays, 14);
      expect(exp.config.significanceLevel, 0.05);
    });

    test('accepts custom config', () {
      const hypothesis = ExperimentHypothesis(
        intervention: 'Test',
        expectedOutcome: 'Test',
        metric: 'test',
        direction: 'increase',
      );
      final exp = service.createExperiment(
        hypothesis,
        config: const ExperimentConfig(
          baselineDays: 14,
          experimentDays: 28,
          significanceLevel: 0.01,
          minimumDataPoints: 10,
        ),
      );

      expect(exp.config.baselineDays, 14);
      expect(exp.config.experimentDays, 28);
      expect(exp.config.significanceLevel, 0.01);
      expect(exp.config.minimumDataPoints, 10);
    });
  });

  // ── Status Transitions ──

  group('status transitions', () {
    late Experiment exp;

    setUp(() {
      const hypothesis = ExperimentHypothesis(
        intervention: 'Test',
        expectedOutcome: 'Test',
        metric: 'test',
        direction: 'increase',
      );
      exp = service.createExperiment(hypothesis);
    });

    test('draft → baseline', () {
      final started = service.startBaseline(exp);
      expect(started.status, ExperimentStatus.baseline);
      expect(started.id, exp.id);
    });

    test('baseline → active', () {
      final baseline = service.startBaseline(exp);
      final active = service.startExperiment(baseline);
      expect(active.status, ExperimentStatus.active);
    });

    test('full lifecycle: draft → baseline → active → completed', () {
      var e = service.startBaseline(exp);
      expect(e.status, ExperimentStatus.baseline);

      // Record baseline data
      for (int i = 0; i < 7; i++) {
        e = service.recordDataPoint(e, 5.0 + i * 0.1,
            date: DateTime(2026, 1, 1 + i));
      }
      expect(e.data.length, 7);
      expect(e.data.every((d) => d.isBaseline), isTrue);

      e = service.startExperiment(e);
      expect(e.status, ExperimentStatus.active);

      // Record experiment data (higher values)
      for (int i = 0; i < 14; i++) {
        e = service.recordDataPoint(e, 7.0 + i * 0.05,
            date: DateTime(2026, 1, 8 + i));
      }
      expect(e.data.length, 21);

      final report = service.analyzeResults(e);
      expect(report.experiment.status, ExperimentStatus.completed);
      expect(report.experiment.outcome, isNotNull);
      expect(report.experiment.completedAt, isNotNull);
    });
  });

  // ── Data Recording ──

  group('recordDataPoint', () {
    test('marks points as baseline during baseline phase', () {
      const hypothesis = ExperimentHypothesis(
        intervention: 'Test',
        expectedOutcome: 'Test',
        metric: 'test',
        direction: 'increase',
      );
      var exp = service.createExperiment(hypothesis);
      exp = service.startBaseline(exp);
      exp = service.recordDataPoint(exp, 5.0, date: DateTime(2026, 1, 1));

      expect(exp.data.length, 1);
      expect(exp.data.first.isBaseline, isTrue);
      expect(exp.data.first.value, 5.0);
    });

    test('marks points as experiment during active phase', () {
      const hypothesis = ExperimentHypothesis(
        intervention: 'Test',
        expectedOutcome: 'Test',
        metric: 'test',
        direction: 'increase',
      );
      var exp = service.createExperiment(hypothesis);
      exp = service.startBaseline(exp);
      exp = service.startExperiment(exp);
      exp = service.recordDataPoint(exp, 8.0, date: DateTime(2026, 1, 10));

      expect(exp.data.length, 1);
      expect(exp.data.first.isBaseline, isFalse);
    });
  });

  // ── Statistical Analysis ──

  group('analyzeResults', () {
    Experiment _buildExperiment(
      List<double> baselineValues,
      List<double> experimentValues, {
      String direction = 'increase',
    }) {
      const hypothesis = ExperimentHypothesis(
        intervention: 'Test intervention',
        expectedOutcome: 'Test outcome',
        metric: 'test_metric',
        direction: 'increase',
      );
      var exp = service.createExperiment(
        ExperimentHypothesis(
          intervention: hypothesis.intervention,
          expectedOutcome: hypothesis.expectedOutcome,
          metric: hypothesis.metric,
          direction: direction,
        ),
      );
      exp = service.startBaseline(exp);
      for (int i = 0; i < baselineValues.length; i++) {
        exp = service.recordDataPoint(exp, baselineValues[i],
            date: DateTime(2026, 1, 1 + i));
      }
      exp = service.startExperiment(exp);
      for (int i = 0; i < experimentValues.length; i++) {
        exp = service.recordDataPoint(exp, experimentValues[i],
            date: DateTime(2026, 1, 10 + i));
      }
      return exp;
    }

    test('handles empty data gracefully', () {
      const hypothesis = ExperimentHypothesis(
        intervention: 'Test',
        expectedOutcome: 'Test',
        metric: 'test',
        direction: 'increase',
      );
      final exp = service.createExperiment(hypothesis);
      final report = service.analyzeResults(exp);

      expect(report.statistics.baselineMean, 0);
      expect(report.statistics.pValue, 1.0);
      expect(report.experiment.outcome, ExperimentOutcome.inconclusive);
    });

    test('detects significant increase', () {
      // Baseline: ~5, Experiment: ~10 — clear difference
      final exp = _buildExperiment(
        [5.0, 5.1, 4.9, 5.2, 4.8, 5.0, 5.1],
        [10.0, 9.8, 10.2, 10.1, 9.9, 10.0, 10.3, 9.7, 10.1, 10.0, 9.9, 10.2, 10.0, 9.8],
      );
      final report = service.analyzeResults(exp);

      expect(report.statistics.baselineMean, closeTo(5.01, 0.1));
      expect(report.statistics.experimentMean, closeTo(10.0, 0.1));
      expect(report.statistics.effectSize, greaterThan(1.0)); // large effect
      expect(report.statistics.effectMagnitude, EffectMagnitude.large);
      expect(report.statistics.pValue, lessThan(0.05));
      expect(report.experiment.outcome, ExperimentOutcome.confirmed);
    });

    test('detects significant decrease', () {
      // Baseline: ~10, Experiment: ~5 — for a "decrease" hypothesis
      final exp = _buildExperiment(
        [10.0, 10.1, 9.9, 10.2, 9.8, 10.0, 10.1],
        [5.0, 5.1, 4.9, 5.2, 4.8, 5.0, 5.1, 5.0, 4.9, 5.1],
        direction: 'decrease',
      );
      final report = service.analyzeResults(exp);

      expect(report.experiment.outcome, ExperimentOutcome.confirmed);
      expect(report.statistics.percentChange, lessThan(0));
    });

    test('returns inconclusive for similar groups', () {
      // Both groups have similar values
      final exp = _buildExperiment(
        [5.0, 5.1, 4.9, 5.2, 4.8, 5.0, 5.1],
        [5.0, 5.2, 4.8, 5.1, 4.9, 5.0, 5.1, 5.0, 4.9, 5.2],
      );
      final report = service.analyzeResults(exp);

      expect(report.statistics.effectSize.abs(), lessThan(0.3));
      expect(report.statistics.pValue, greaterThan(0.05));
      expect(report.experiment.outcome, ExperimentOutcome.inconclusive);
    });

    test('rejects hypothesis when direction is opposite', () {
      // Hypothesis: increase. Reality: decrease.
      final exp = _buildExperiment(
        [10.0, 10.1, 9.9, 10.2, 9.8, 10.0, 10.1],
        [5.0, 5.1, 4.9, 5.2, 4.8, 5.0, 5.1, 5.0, 4.9, 5.1],
        direction: 'increase',
      );
      final report = service.analyzeResults(exp);

      expect(report.experiment.outcome, ExperimentOutcome.rejected);
    });

    test('percent change is correct', () {
      final exp = _buildExperiment(
        [10.0, 10.0, 10.0, 10.0, 10.0],
        [12.0, 12.0, 12.0, 12.0, 12.0],
      );
      final report = service.analyzeResults(exp);

      expect(report.statistics.percentChange, closeTo(20.0, 0.5));
    });

    test('handles single data point per group', () {
      final exp = _buildExperiment([5.0], [10.0]);
      final report = service.analyzeResults(exp);

      // Should not crash; likely inconclusive due to insufficient data
      expect(report.experiment.outcome, isNotNull);
      expect(report.statistics.pValue, 1.0); // can't compute with 1 point each
    });

    test('handles identical values', () {
      final exp = _buildExperiment(
        [5.0, 5.0, 5.0, 5.0, 5.0],
        [5.0, 5.0, 5.0, 5.0, 5.0],
      );
      final report = service.analyzeResults(exp);

      expect(report.statistics.effectSize, 0.0);
      expect(report.statistics.percentChange, 0.0);
    });
  });

  // ── Insights ──

  group('generateInsights', () {
    test('warns about insufficient baseline data', () {
      const hypothesis = ExperimentHypothesis(
        intervention: 'Test',
        expectedOutcome: 'Test',
        metric: 'test',
        direction: 'increase',
      );
      var exp = service.createExperiment(hypothesis);
      exp = service.startBaseline(exp);
      exp = service.recordDataPoint(exp, 5.0, date: DateTime(2026, 1, 1));
      // only 1 baseline point, needs 5

      final insights = service.generateInsights(exp);
      expect(
        insights.any((i) => i.title.contains('Insufficient baseline')),
        isTrue,
      );
    });

    test('detects outliers', () {
      const hypothesis = ExperimentHypothesis(
        intervention: 'Test',
        expectedOutcome: 'Test',
        metric: 'test',
        direction: 'increase',
      );
      var exp = service.createExperiment(hypothesis);
      exp = service.startBaseline(exp);
      // Add normal data + one outlier
      for (final v in [5.0, 5.1, 4.9, 5.0, 5.1, 5.0, 20.0]) {
        exp = service.recordDataPoint(exp, v, date: DateTime(2026, 1, 1));
      }

      final insights = service.generateInsights(exp);
      expect(
        insights.any((i) => i.title.contains('Outliers')),
        isTrue,
      );
    });

    test('detects trend within experiment period', () {
      const hypothesis = ExperimentHypothesis(
        intervention: 'Test',
        expectedOutcome: 'Test',
        metric: 'test',
        direction: 'increase',
      );
      var exp = service.createExperiment(hypothesis);
      exp = service.startBaseline(exp);
      for (int i = 0; i < 5; i++) {
        exp = service.recordDataPoint(exp, 5.0, date: DateTime(2026, 1, 1 + i));
      }
      exp = service.startExperiment(exp);
      // Clear upward trend
      for (int i = 0; i < 8; i++) {
        exp = service.recordDataPoint(exp, 5.0 + i * 1.0,
            date: DateTime(2026, 1, 10 + i));
      }

      final insights = service.generateInsights(exp);
      expect(
        insights.any((i) => i.title.contains('Trend')),
        isTrue,
      );
    });

    test('detects high baseline variability', () {
      const hypothesis = ExperimentHypothesis(
        intervention: 'Test',
        expectedOutcome: 'Test',
        metric: 'test',
        direction: 'increase',
      );
      var exp = service.createExperiment(hypothesis);
      exp = service.startBaseline(exp);
      // Highly variable baseline
      for (final v in [1.0, 10.0, 2.0, 9.0, 1.5, 8.5]) {
        exp = service.recordDataPoint(exp, v, date: DateTime(2026, 1, 1));
      }

      final insights = service.generateInsights(exp);
      expect(
        insights.any((i) => i.title.contains('variability')),
        isTrue,
      );
    });
  });

  // ── Suggestions ──

  group('suggestExperiments', () {
    test('returns 7 suggestions with no filter', () {
      final suggestions = service.suggestExperiments();
      expect(suggestions.length, 7);
    });

    test('each suggestion has all required fields', () {
      for (final s in service.suggestExperiments()) {
        expect(s.title, isNotEmpty);
        expect(s.hypothesis.intervention, isNotEmpty);
        expect(s.hypothesis.metric, isNotEmpty);
        expect(s.rationale, isNotEmpty);
        expect(s.estimatedDays, greaterThan(0));
        expect(['easy', 'moderate', 'challenging'], contains(s.difficulty));
      }
    });

    test('filters suggestions based on current habits', () {
      final all = service.suggestExperiments();
      final filtered = service.suggestExperiments(
        currentHabits: ['meditate', 'walk'],
      );
      expect(filtered.length, lessThan(all.length));
    });
  });

  // ── Sample Experiment ──

  group('getSampleExperiment', () {
    test('returns a completed experiment', () {
      final sample = service.getSampleExperiment();
      expect(sample.status, ExperimentStatus.completed);
      expect(sample.outcome, isNotNull);
      expect(sample.result, isNotNull);
      expect(sample.completedAt, isNotNull);
    });

    test('has 21 data points (7 baseline + 14 experiment)', () {
      final sample = service.getSampleExperiment();
      expect(sample.data.length, 21);
      expect(sample.data.where((d) => d.isBaseline).length, 7);
      expect(sample.data.where((d) => !d.isBaseline).length, 14);
    });

    test('sample shows confirmed outcome', () {
      final sample = service.getSampleExperiment();
      expect(sample.outcome, ExperimentOutcome.confirmed);
    });

    test('has generated insights', () {
      final sample = service.getSampleExperiment();
      expect(sample.insights, isNotEmpty);
    });
  });

  // ── Summary ──

  group('getExperimentSummary', () {
    test('contains experiment details', () {
      final sample = service.getSampleExperiment();
      final summary = service.getExperimentSummary(sample);

      expect(summary, contains('Meditate'));
      expect(summary, contains('sleep_quality'));
      expect(summary, contains('Completed'));
      expect(summary, contains('Results'));
      expect(summary, contains('Verdict'));
    });

    test('draft experiment shows minimal info', () {
      const hypothesis = ExperimentHypothesis(
        intervention: 'Test intervention',
        expectedOutcome: 'Better outcome',
        metric: 'test_metric',
        direction: 'increase',
      );
      final exp = service.createExperiment(hypothesis);
      final summary = service.getExperimentSummary(exp);

      expect(summary, contains('Draft'));
      expect(summary, contains('Test intervention'));
      expect(summary, isNot(contains('Results')));
    });
  });

  // ── Report ──

  group('ExperimentReport', () {
    test('verdict text matches outcome', () {
      // Confirmed case
      final sample = service.getSampleExperiment();
      final summary = service.getExperimentSummary(sample);
      expect(summary, contains('Confirmed'));
    });

    test('next steps are populated', () {
      const hypothesis = ExperimentHypothesis(
        intervention: 'Test',
        expectedOutcome: 'Test',
        metric: 'test',
        direction: 'increase',
      );
      var exp = service.createExperiment(hypothesis);
      exp = service.startBaseline(exp);
      for (int i = 0; i < 7; i++) {
        exp = service.recordDataPoint(exp, 5.0, date: DateTime(2026, 1, 1 + i));
      }
      exp = service.startExperiment(exp);
      for (int i = 0; i < 10; i++) {
        exp = service.recordDataPoint(exp, 5.0, date: DateTime(2026, 1, 10 + i));
      }
      final report = service.analyzeResults(exp);
      expect(report.nextSteps, isNotEmpty);
    });
  });
}
