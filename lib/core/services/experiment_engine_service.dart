/// Life Experiment Engine — autonomous self-experimentation framework.
///
/// Users define hypotheses about their habits and wellness, the engine
/// designs experiments with baseline vs intervention periods, records data,
/// runs statistical analysis (Welch's t-test, Cohen's d effect size),
/// and draws evidence-based conclusions.
///
/// This is an "agentic" feature: the app autonomously designs experiments,
/// monitors data quality, detects patterns, and generates verdicts.
import 'dart:math';

// ── Enums ──────────────────────────────────────────────────────

/// Status of an experiment lifecycle.
enum ExperimentStatus {
  draft,
  baseline,
  active,
  analyzing,
  completed,
  abandoned;

  String get label {
    switch (this) {
      case ExperimentStatus.draft:
        return 'Draft';
      case ExperimentStatus.baseline:
        return 'Baseline';
      case ExperimentStatus.active:
        return 'Active';
      case ExperimentStatus.analyzing:
        return 'Analyzing';
      case ExperimentStatus.completed:
        return 'Completed';
      case ExperimentStatus.abandoned:
        return 'Abandoned';
    }
  }

  String get emoji {
    switch (this) {
      case ExperimentStatus.draft:
        return '📝';
      case ExperimentStatus.baseline:
        return '📊';
      case ExperimentStatus.active:
        return '🧪';
      case ExperimentStatus.analyzing:
        return '🔬';
      case ExperimentStatus.completed:
        return '✅';
      case ExperimentStatus.abandoned:
        return '❌';
    }
  }
}

/// Outcome after statistical analysis.
enum ExperimentOutcome {
  confirmed,
  rejected,
  inconclusive;

  String get label {
    switch (this) {
      case ExperimentOutcome.confirmed:
        return 'Hypothesis Confirmed';
      case ExperimentOutcome.rejected:
        return 'Hypothesis Rejected';
      case ExperimentOutcome.inconclusive:
        return 'Inconclusive';
    }
  }

  String get emoji {
    switch (this) {
      case ExperimentOutcome.confirmed:
        return '✅';
      case ExperimentOutcome.rejected:
        return '❌';
      case ExperimentOutcome.inconclusive:
        return '🤷';
    }
  }
}

/// Confidence level of results.
enum ConfidenceLevel {
  low,
  moderate,
  high,
  veryHigh;

  String get label {
    switch (this) {
      case ConfidenceLevel.low:
        return 'Low';
      case ConfidenceLevel.moderate:
        return 'Moderate';
      case ConfidenceLevel.high:
        return 'High';
      case ConfidenceLevel.veryHigh:
        return 'Very High';
    }
  }
}

/// Effect size magnitude per Cohen's conventions.
enum EffectMagnitude {
  negligible,
  small,
  medium,
  large;

  String get label {
    switch (this) {
      case EffectMagnitude.negligible:
        return 'Negligible';
      case EffectMagnitude.small:
        return 'Small';
      case EffectMagnitude.medium:
        return 'Medium';
      case EffectMagnitude.large:
        return 'Large';
    }
  }
}

// ── Data Models ────────────────────────────────────────────────

/// What the user hypothesizes.
class ExperimentHypothesis {
  final String intervention;
  final String expectedOutcome;
  final String metric;
  final String direction; // "increase" or "decrease"

  const ExperimentHypothesis({
    required this.intervention,
    required this.expectedOutcome,
    required this.metric,
    required this.direction,
  });
}

/// Experiment parameters.
class ExperimentConfig {
  final int baselineDays;
  final int experimentDays;
  final double significanceLevel;
  final int minimumDataPoints;

  const ExperimentConfig({
    this.baselineDays = 7,
    this.experimentDays = 14,
    this.significanceLevel = 0.05,
    this.minimumDataPoints = 5,
  });
}

/// A single recorded measurement.
class DataPoint {
  final DateTime date;
  final double value;
  final bool isBaseline;

  const DataPoint({
    required this.date,
    required this.value,
    required this.isBaseline,
  });
}

/// Statistical analysis result.
class StatisticalResult {
  final double baselineMean;
  final double baselineStdDev;
  final double experimentMean;
  final double experimentStdDev;
  final double effectSize;
  final EffectMagnitude effectMagnitude;
  final double tStatistic;
  final double pValue;
  final ConfidenceLevel confidence;
  final double percentChange;

  const StatisticalResult({
    required this.baselineMean,
    required this.baselineStdDev,
    required this.experimentMean,
    required this.experimentStdDev,
    required this.effectSize,
    required this.effectMagnitude,
    required this.tStatistic,
    required this.pValue,
    required this.confidence,
    required this.percentChange,
  });
}

/// A generated insight about the experiment.
class ExperimentInsight {
  final String icon;
  final String title;
  final String detail;
  final String category; // "statistical", "behavioral", "recommendation"

  const ExperimentInsight({
    required this.icon,
    required this.title,
    required this.detail,
    required this.category,
  });
}

/// Full experiment state.
class Experiment {
  final String id;
  final ExperimentHypothesis hypothesis;
  final ExperimentConfig config;
  final ExperimentStatus status;
  final List<DataPoint> data;
  final StatisticalResult? result;
  final ExperimentOutcome? outcome;
  final List<ExperimentInsight> insights;
  final DateTime createdAt;
  final DateTime? completedAt;

  const Experiment({
    required this.id,
    required this.hypothesis,
    required this.config,
    required this.status,
    required this.data,
    this.result,
    this.outcome,
    required this.insights,
    required this.createdAt,
    this.completedAt,
  });

  Experiment copyWith({
    ExperimentStatus? status,
    List<DataPoint>? data,
    StatisticalResult? result,
    ExperimentOutcome? outcome,
    List<ExperimentInsight>? insights,
    DateTime? completedAt,
  }) {
    return Experiment(
      id: id,
      hypothesis: hypothesis,
      config: config,
      status: status ?? this.status,
      data: data ?? this.data,
      result: result ?? this.result,
      outcome: outcome ?? this.outcome,
      insights: insights ?? this.insights,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// A suggested experiment the user might want to try.
class ExperimentSuggestion {
  final String title;
  final ExperimentHypothesis hypothesis;
  final String rationale;
  final String difficulty; // "easy", "moderate", "challenging"
  final int estimatedDays;

  const ExperimentSuggestion({
    required this.title,
    required this.hypothesis,
    required this.rationale,
    required this.difficulty,
    required this.estimatedDays,
  });
}

/// Full experiment report with analysis and next steps.
class ExperimentReport {
  final Experiment experiment;
  final StatisticalResult statistics;
  final List<ExperimentInsight> insights;
  final String verdict;
  final List<String> nextSteps;
  final DateTime generatedAt;

  const ExperimentReport({
    required this.experiment,
    required this.statistics,
    required this.insights,
    required this.verdict,
    required this.nextSteps,
    required this.generatedAt,
  });
}

// ── Service ────────────────────────────────────────────────────

/// Autonomous self-experimentation engine.
///
/// Designs experiments, tracks data, runs Welch's t-test with Cohen's d
/// effect size, and draws evidence-based conclusions about habit changes.
class ExperimentEngineService {
  const ExperimentEngineService();

  static int _idCounter = 0;

  // ── Lifecycle ──

  /// Create a new experiment in draft status.
  Experiment createExperiment(
    ExperimentHypothesis hypothesis, {
    ExperimentConfig? config,
  }) {
    _idCounter++;
    return Experiment(
      id: 'exp-$_idCounter',
      hypothesis: hypothesis,
      config: config ?? const ExperimentConfig(),
      status: ExperimentStatus.draft,
      data: const [],
      insights: const [],
      createdAt: DateTime.now(),
    );
  }

  /// Transition to baseline data-collection phase.
  Experiment startBaseline(Experiment experiment) {
    return experiment.copyWith(status: ExperimentStatus.baseline);
  }

  /// Transition from baseline to active intervention phase.
  Experiment startExperiment(Experiment experiment) {
    return experiment.copyWith(status: ExperimentStatus.active);
  }

  /// Record a data point. Auto-classifies as baseline or experiment.
  Experiment recordDataPoint(
    Experiment experiment,
    double value, {
    DateTime? date,
  }) {
    final isBaseline = experiment.status == ExperimentStatus.baseline;
    final point = DataPoint(
      date: date ?? DateTime.now(),
      value: value,
      isBaseline: isBaseline,
    );
    return experiment.copyWith(data: [...experiment.data, point]);
  }

  // ── Analysis ──

  /// Run full statistical analysis and generate a report.
  ExperimentReport analyzeResults(Experiment experiment) {
    final baselineData =
        experiment.data.where((d) => d.isBaseline).map((d) => d.value).toList();
    final experimentData =
        experiment.data.where((d) => !d.isBaseline).map((d) => d.value).toList();

    final stats = _computeStatistics(
      baselineData,
      experimentData,
      experiment.config.significanceLevel,
    );

    final outcome = _determineOutcome(
      stats,
      experiment.hypothesis.direction,
      experiment.config.significanceLevel,
    );

    final insights = generateInsights(
      experiment.copyWith(result: stats, outcome: outcome),
    );

    final verdict = _buildVerdict(experiment.hypothesis, stats, outcome);
    final nextSteps = _buildNextSteps(outcome, stats);

    final completed = experiment.copyWith(
      status: ExperimentStatus.completed,
      result: stats,
      outcome: outcome,
      insights: insights,
      completedAt: DateTime.now(),
    );

    return ExperimentReport(
      experiment: completed,
      statistics: stats,
      insights: insights,
      verdict: verdict,
      nextSteps: nextSteps,
      generatedAt: DateTime.now(),
    );
  }

  /// Generate behavioral and statistical insights about the experiment.
  List<ExperimentInsight> generateInsights(Experiment experiment) {
    final insights = <ExperimentInsight>[];
    final baselineData =
        experiment.data.where((d) => d.isBaseline).map((d) => d.value).toList();
    final experimentData =
        experiment.data.where((d) => !d.isBaseline).map((d) => d.value).toList();

    // Sample size check
    if (baselineData.length < experiment.config.minimumDataPoints) {
      insights.add(ExperimentInsight(
        icon: '⚠️',
        title: 'Insufficient baseline data',
        detail:
            '${baselineData.length} points collected, need at least ${experiment.config.minimumDataPoints}',
        category: 'statistical',
      ));
    }
    if (experimentData.length < experiment.config.minimumDataPoints) {
      insights.add(ExperimentInsight(
        icon: '⚠️',
        title: 'Insufficient experiment data',
        detail:
            '${experimentData.length} points collected, need at least ${experiment.config.minimumDataPoints}',
        category: 'statistical',
      ));
    }

    // Data consistency (coefficient of variation)
    if (baselineData.length >= 2) {
      final bMean = _mean(baselineData);
      final bStd = _stdDev(baselineData);
      if (bMean != 0) {
        final cv = (bStd / bMean).abs();
        if (cv > 0.5) {
          insights.add(const ExperimentInsight(
            icon: '📊',
            title: 'High baseline variability',
            detail:
                'Your baseline data varies a lot — results may be less reliable',
            category: 'statistical',
          ));
        }
      }
    }

    // Outlier detection (>2 std devs from mean)
    final allValues = experiment.data.map((d) => d.value).toList();
    if (allValues.length >= 3) {
      final m = _mean(allValues);
      final s = _stdDev(allValues);
      if (s > 0) {
        final outliers = allValues.where((v) => (v - m).abs() > 2 * s).length;
        if (outliers > 0) {
          insights.add(ExperimentInsight(
            icon: '🔍',
            title: 'Outliers detected',
            detail: '$outliers data point(s) are >2 std devs from the mean',
            category: 'behavioral',
          ));
        }
      }
    }

    // Trend within experiment period
    if (experimentData.length >= 4) {
      final firstHalf = experimentData.sublist(0, experimentData.length ~/ 2);
      final secondHalf = experimentData.sublist(experimentData.length ~/ 2);
      final firstMean = _mean(firstHalf);
      final secondMean = _mean(secondHalf);
      final diff = secondMean - firstMean;
      if (firstMean != 0 && (diff / firstMean).abs() > 0.1) {
        final direction = diff > 0 ? 'upward' : 'downward';
        insights.add(ExperimentInsight(
          icon: '📈',
          title: 'Trend within experiment',
          detail:
              'Values show an $direction trend during the intervention period',
          category: 'behavioral',
        ));
      }
    }

    // Weekend vs weekday pattern
    final weekdayPoints =
        experiment.data.where((d) => d.date.weekday <= 5).map((d) => d.value);
    final weekendPoints =
        experiment.data.where((d) => d.date.weekday > 5).map((d) => d.value);
    if (weekdayPoints.length >= 3 && weekendPoints.length >= 2) {
      final wdMean = _mean(weekdayPoints.toList());
      final weMean = _mean(weekendPoints.toList());
      if (wdMean != 0 && ((weMean - wdMean) / wdMean).abs() > 0.15) {
        insights.add(ExperimentInsight(
          icon: '📅',
          title: 'Weekday/weekend pattern',
          detail: weMean > wdMean
              ? 'Values tend to be higher on weekends'
              : 'Values tend to be higher on weekdays',
          category: 'behavioral',
        ));
      }
    }

    // Effect size interpretation
    if (experiment.result != null) {
      final r = experiment.result!;
      insights.add(ExperimentInsight(
        icon: r.effectMagnitude == EffectMagnitude.large
            ? '💪'
            : r.effectMagnitude == EffectMagnitude.medium
                ? '👍'
                : '📏',
        title: '${r.effectMagnitude.label} effect size',
        detail:
            "Cohen's d = ${r.effectSize.toStringAsFixed(2)} — ${_effectInterpretation(r.effectMagnitude)}",
        category: 'statistical',
      ));

      // Confidence interpretation
      if (r.confidence == ConfidenceLevel.veryHigh ||
          r.confidence == ConfidenceLevel.high) {
        insights.add(ExperimentInsight(
          icon: '🎯',
          title: '${r.confidence.label} confidence',
          detail: 'p = ${r.pValue.toStringAsFixed(4)} — results are statistically significant',
          category: 'statistical',
        ));
      }
    }

    // Recommendation based on outcome
    if (experiment.outcome == ExperimentOutcome.confirmed) {
      insights.add(ExperimentInsight(
        icon: '🏆',
        title: 'Keep it up!',
        detail:
            'The intervention "${experiment.hypothesis.intervention}" shows a real effect. Consider making it a permanent habit.',
        category: 'recommendation',
      ));
    } else if (experiment.outcome == ExperimentOutcome.inconclusive) {
      insights.add(ExperimentInsight(
        icon: '🔄',
        title: 'Try extending the experiment',
        detail:
            'More data could clarify the results. Consider running for another ${experiment.config.experimentDays} days.',
        category: 'recommendation',
      ));
    }

    return insights;
  }

  // ── Suggestions ──

  /// Generate smart experiment suggestions.
  List<ExperimentSuggestion> suggestExperiments({
    List<String> currentHabits = const [],
  }) {
    final suggestions = <ExperimentSuggestion>[
      const ExperimentSuggestion(
        title: 'Meditation & Sleep',
        hypothesis: ExperimentHypothesis(
          intervention: 'Meditate 10 minutes before bed',
          expectedOutcome: 'Better sleep quality',
          metric: 'sleep_quality',
          direction: 'increase',
        ),
        rationale:
            'Research shows mindfulness meditation can improve sleep quality by reducing pre-sleep arousal',
        difficulty: 'easy',
        estimatedDays: 21,
      ),
      const ExperimentSuggestion(
        title: 'Morning Exercise & Energy',
        hypothesis: ExperimentHypothesis(
          intervention: '20-minute morning walk',
          expectedOutcome: 'Higher afternoon energy',
          metric: 'energy_level',
          direction: 'increase',
        ),
        rationale:
            'Morning light exposure and movement can regulate circadian rhythm and boost daytime alertness',
        difficulty: 'easy',
        estimatedDays: 21,
      ),
      const ExperimentSuggestion(
        title: 'Caffeine Cutoff & Sleep',
        hypothesis: ExperimentHypothesis(
          intervention: 'No caffeine after 2 PM',
          expectedOutcome: 'Fall asleep faster',
          metric: 'sleep_onset_minutes',
          direction: 'decrease',
        ),
        rationale:
            'Caffeine has a 5-6 hour half-life; afternoon consumption can delay sleep onset',
        difficulty: 'moderate',
        estimatedDays: 21,
      ),
      const ExperimentSuggestion(
        title: 'Social Media Detox & Mood',
        hypothesis: ExperimentHypothesis(
          intervention: 'Limit social media to 30 min/day',
          expectedOutcome: 'Improved mood scores',
          metric: 'mood_score',
          direction: 'increase',
        ),
        rationale:
            'Excessive social media use is linked to comparison anxiety and reduced wellbeing',
        difficulty: 'challenging',
        estimatedDays: 28,
      ),
      const ExperimentSuggestion(
        title: 'Gratitude Journaling & Wellbeing',
        hypothesis: ExperimentHypothesis(
          intervention: 'Write 3 things you\'re grateful for each morning',
          expectedOutcome: 'Higher life satisfaction',
          metric: 'wellbeing_score',
          direction: 'increase',
        ),
        rationale:
            'Gratitude interventions consistently show positive effects on subjective wellbeing',
        difficulty: 'easy',
        estimatedDays: 21,
      ),
      const ExperimentSuggestion(
        title: 'Cold Showers & Alertness',
        hypothesis: ExperimentHypothesis(
          intervention: '30-second cold shower ending each morning',
          expectedOutcome: 'Better morning focus',
          metric: 'focus_score',
          direction: 'increase',
        ),
        rationale:
            'Cold exposure triggers norepinephrine release, which may improve alertness and focus',
        difficulty: 'moderate',
        estimatedDays: 21,
      ),
      const ExperimentSuggestion(
        title: 'Reading Before Bed & Screen Time',
        hypothesis: ExperimentHypothesis(
          intervention: 'Replace phone scrolling with 20 min of reading',
          expectedOutcome: 'Less screen time before bed',
          metric: 'evening_screen_minutes',
          direction: 'decrease',
        ),
        rationale:
            'Book reading provides a natural wind-down that blue-light-emitting screens don\'t',
        difficulty: 'moderate',
        estimatedDays: 21,
      ),
    ];

    // Filter out suggestions that overlap with current habits
    if (currentHabits.isNotEmpty) {
      final lowerHabits = currentHabits.map((h) => h.toLowerCase()).toSet();
      return suggestions
          .where((s) =>
              !lowerHabits.any((h) => s.hypothesis.intervention.toLowerCase().contains(h)))
          .toList();
    }

    return suggestions;
  }

  /// Get a fully completed sample experiment with realistic data.
  Experiment getSampleExperiment() {
    final rng = Random(42); // deterministic seed
    final now = DateTime.now();
    final startDate = now.subtract(const Duration(days: 21));

    // Generate baseline data (7 days): sleep quality ~6.5 ± 1.0
    final data = <DataPoint>[];
    for (int i = 0; i < 7; i++) {
      data.add(DataPoint(
        date: startDate.add(Duration(days: i)),
        value: 6.0 + rng.nextDouble() * 2.0, // 6.0-8.0 range
        isBaseline: true,
      ));
    }

    // Generate experiment data (14 days): sleep quality ~7.5 ± 0.8 (improvement)
    for (int i = 7; i < 21; i++) {
      data.add(DataPoint(
        date: startDate.add(Duration(days: i)),
        value: 7.0 + rng.nextDouble() * 1.6, // 7.0-8.6 range
        isBaseline: false,
      ));
    }

    const hypothesis = ExperimentHypothesis(
      intervention: 'Meditate 10 minutes before bed',
      expectedOutcome: 'Better sleep quality score',
      metric: 'sleep_quality',
      direction: 'increase',
    );

    var experiment = Experiment(
      id: 'exp-sample',
      hypothesis: hypothesis,
      config: const ExperimentConfig(),
      status: ExperimentStatus.active,
      data: data,
      insights: const [],
      createdAt: startDate,
    );

    // Run analysis
    final report = analyzeResults(experiment);
    return report.experiment;
  }

  /// Human-readable summary of the experiment.
  String getExperimentSummary(Experiment experiment) {
    final h = experiment.hypothesis;
    final buf = StringBuffer();

    buf.writeln('${experiment.status.emoji} Experiment: ${h.intervention}');
    buf.writeln('Hypothesis: ${h.intervention} → ${h.expectedOutcome}');
    buf.writeln('Metric: ${h.metric} (expected ${h.direction})');
    buf.writeln('Status: ${experiment.status.label}');

    final baselineCount = experiment.data.where((d) => d.isBaseline).length;
    final expCount = experiment.data.where((d) => !d.isBaseline).length;
    buf.writeln('Data points: $baselineCount baseline, $expCount experiment');

    if (experiment.result != null) {
      final r = experiment.result!;
      buf.writeln('');
      buf.writeln('── Results ──');
      buf.writeln(
          'Baseline: ${r.baselineMean.toStringAsFixed(2)} ± ${r.baselineStdDev.toStringAsFixed(2)}');
      buf.writeln(
          'Experiment: ${r.experimentMean.toStringAsFixed(2)} ± ${r.experimentStdDev.toStringAsFixed(2)}');
      buf.writeln('Change: ${r.percentChange >= 0 ? "+" : ""}${r.percentChange.toStringAsFixed(1)}%');
      buf.writeln(
          'Effect size: ${r.effectSize.toStringAsFixed(2)} (${r.effectMagnitude.label})');
      buf.writeln('p-value: ${r.pValue.toStringAsFixed(4)}');
      buf.writeln('Confidence: ${r.confidence.label}');
    }

    if (experiment.outcome != null) {
      buf.writeln('');
      buf.writeln(
          '${experiment.outcome!.emoji} Verdict: ${experiment.outcome!.label}');
    }

    if (experiment.insights.isNotEmpty) {
      buf.writeln('');
      buf.writeln('── Insights ──');
      for (final insight in experiment.insights) {
        buf.writeln('${insight.icon} ${insight.title}: ${insight.detail}');
      }
    }

    return buf.toString();
  }

  // ── Private Statistics ───────────────────────────────────────

  StatisticalResult _computeStatistics(
    List<double> baseline,
    List<double> experiment,
    double significanceLevel,
  ) {
    if (baseline.isEmpty && experiment.isEmpty) {
      return const StatisticalResult(
        baselineMean: 0,
        baselineStdDev: 0,
        experimentMean: 0,
        experimentStdDev: 0,
        effectSize: 0,
        effectMagnitude: EffectMagnitude.negligible,
        tStatistic: 0,
        pValue: 1.0,
        confidence: ConfidenceLevel.low,
        percentChange: 0,
      );
    }

    final bMean = baseline.isEmpty ? 0.0 : _mean(baseline);
    final bStd = baseline.length < 2 ? 0.0 : _stdDev(baseline);
    final eMean = experiment.isEmpty ? 0.0 : _mean(experiment);
    final eStd = experiment.length < 2 ? 0.0 : _stdDev(experiment);

    // Cohen's d effect size (pooled std dev)
    final pooledStd = _pooledStdDev(bStd, baseline.length, eStd, experiment.length);
    final effectSize = pooledStd > 0 ? (eMean - bMean) / pooledStd : 0.0;
    final effectMag = _classifyEffect(effectSize.abs());

    // Welch's t-test
    final n1 = baseline.length;
    final n2 = experiment.length;
    double tStat = 0;
    double pVal = 1.0;

    if (n1 >= 2 && n2 >= 2 && (bStd > 0 || eStd > 0)) {
      final se = sqrt((bStd * bStd / n1) + (eStd * eStd / n2));
      if (se > 0) {
        tStat = (eMean - bMean) / se;
        // Approximate two-tailed p-value using erfc
        pVal = _erfcApprox(tStat.abs() / sqrt(2));
      }
    }

    final confidence = _classifyConfidence(pVal);
    final percentChange = bMean != 0 ? ((eMean - bMean) / bMean) * 100 : 0.0;

    return StatisticalResult(
      baselineMean: bMean,
      baselineStdDev: bStd,
      experimentMean: eMean,
      experimentStdDev: eStd,
      effectSize: effectSize,
      effectMagnitude: effectMag,
      tStatistic: tStat,
      pValue: pVal,
      confidence: confidence,
      percentChange: percentChange,
    );
  }

  ExperimentOutcome _determineOutcome(
    StatisticalResult stats,
    String expectedDirection,
    double significanceLevel,
  ) {
    if (stats.pValue >= significanceLevel) {
      return ExperimentOutcome.inconclusive;
    }

    final directionMatches = expectedDirection == 'increase'
        ? stats.experimentMean > stats.baselineMean
        : stats.experimentMean < stats.baselineMean;

    return directionMatches
        ? ExperimentOutcome.confirmed
        : ExperimentOutcome.rejected;
  }

  String _buildVerdict(
    ExperimentHypothesis hypothesis,
    StatisticalResult stats,
    ExperimentOutcome outcome,
  ) {
    switch (outcome) {
      case ExperimentOutcome.confirmed:
        return 'Your hypothesis was confirmed! "${hypothesis.intervention}" led to a '
            '${stats.percentChange.abs().toStringAsFixed(1)}% ${hypothesis.direction} '
            'in ${hypothesis.metric} (p=${stats.pValue.toStringAsFixed(4)}, '
            "Cohen's d=${stats.effectSize.toStringAsFixed(2)}).";
      case ExperimentOutcome.rejected:
        return 'Your hypothesis was not supported. "${hypothesis.intervention}" '
            'showed the opposite effect — a ${stats.percentChange.abs().toStringAsFixed(1)}% '
            '${hypothesis.direction == "increase" ? "decrease" : "increase"} '
            'in ${hypothesis.metric} (p=${stats.pValue.toStringAsFixed(4)}).';
      case ExperimentOutcome.inconclusive:
        return 'The results are inconclusive (p=${stats.pValue.toStringAsFixed(4)}). '
            'There isn\'t enough statistical evidence to confirm or reject the hypothesis. '
            'Consider running the experiment for longer.';
    }
  }

  List<String> _buildNextSteps(ExperimentOutcome outcome, StatisticalResult stats) {
    switch (outcome) {
      case ExperimentOutcome.confirmed:
        return [
          'Consider making this intervention a permanent habit',
          'Run a follow-up experiment to test dose-response (e.g., more/less time)',
          'Track long-term to see if the effect persists over months',
        ];
      case ExperimentOutcome.rejected:
        return [
          'Review whether you followed the intervention consistently',
          'Consider confounding factors that may have influenced results',
          'Try a modified version of the intervention',
        ];
      case ExperimentOutcome.inconclusive:
        return [
          'Extend the experiment period for more data points',
          'Reduce sources of variability (consistent timing, conditions)',
          'Consider if the metric is sensitive enough to detect the change',
          'Try a stronger version of the intervention',
        ];
    }
  }

  // ── Math Helpers ─────────────────────────────────────────────

  double _mean(List<double> values) {
    if (values.isEmpty) return 0;
    return values.fold<double>(0, (a, b) => a + b) / values.length;
  }

  double _stdDev(List<double> values) {
    if (values.length < 2) return 0;
    final m = _mean(values);
    final sumSqDiff = values.fold<double>(0, (a, v) => a + (v - m) * (v - m));
    return sqrt(sumSqDiff / (values.length - 1)); // sample std dev
  }

  double _pooledStdDev(double s1, int n1, double s2, int n2) {
    if (n1 < 2 && n2 < 2) return 0;
    if (n1 < 2) return s2;
    if (n2 < 2) return s1;
    final num = (n1 - 1) * s1 * s1 + (n2 - 1) * s2 * s2;
    final den = n1 + n2 - 2;
    return den > 0 ? sqrt(num / den) : 0;
  }

  /// Complementary error function approximation (Abramowitz & Stegun 7.1.26).
  double _erfcApprox(double x) {
    if (x < 0) return 2.0 - _erfcApprox(-x);
    if (x > 6) return 0.0; // effectively zero

    const p = 0.3275911;
    const a1 = 0.254829592;
    const a2 = -0.284496736;
    const a3 = 1.421413741;
    const a4 = -1.453152027;
    const a5 = 1.061405429;

    final t = 1.0 / (1.0 + p * x);
    final t2 = t * t;
    final t3 = t2 * t;
    final t4 = t3 * t;
    final t5 = t4 * t;

    final result = (a1 * t + a2 * t2 + a3 * t3 + a4 * t4 + a5 * t5) * exp(-x * x);
    return result.clamp(0.0, 2.0);
  }

  EffectMagnitude _classifyEffect(double absEffect) {
    if (absEffect >= 0.8) return EffectMagnitude.large;
    if (absEffect >= 0.5) return EffectMagnitude.medium;
    if (absEffect >= 0.2) return EffectMagnitude.small;
    return EffectMagnitude.negligible;
  }

  ConfidenceLevel _classifyConfidence(double pValue) {
    if (pValue < 0.001) return ConfidenceLevel.veryHigh;
    if (pValue < 0.01) return ConfidenceLevel.high;
    if (pValue < 0.05) return ConfidenceLevel.moderate;
    return ConfidenceLevel.low;
  }

  String _effectInterpretation(EffectMagnitude mag) {
    switch (mag) {
      case EffectMagnitude.negligible:
        return 'the difference is too small to be practically meaningful';
      case EffectMagnitude.small:
        return 'a small but detectable difference';
      case EffectMagnitude.medium:
        return 'a noticeable, meaningful difference';
      case EffectMagnitude.large:
        return 'a substantial, clearly visible difference';
    }
  }
}
