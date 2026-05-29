/// Sleep Debt Advisor Service - agentic sleep debt accumulation & recovery planner.
///
/// While [SleepTrackerService] logs raw entries and [SleepCalculatorService]
/// does static math, this service answers the agentic question:
///
///   "How much sleep debt have I accumulated, is it getting worse, what's the
///    fastest safe recovery path, and which behaviours are driving the deficit?"
///
/// Inputs are platform-agnostic [SleepNight] records (bedtime, wake, quality).
/// No Flutter or persistence dependency — same service powers widgets,
/// notifications, and unit tests.
///
/// Pipeline:
///   1. Compute nightly deficit vs configurable target (default 8.0h).
///   2. Accumulate rolling sleep debt over trailing window (default 14d)
///      with natural decay (body recovers ~20min/night of excess sleep).
///   3. Detect patterns: chronic undersleep, schedule inconsistency (bedtime
///      variance), weekend oversleep rebound, quality degradation trend.
///   4. Per-night verdict: SURPLUS / ON_TARGET / MILD_DEFICIT / MODERATE_DEFICIT /
///      SEVERE_DEFICIT / CRITICAL_DEBT.
///   5. Portfolio-level recovery plan with P0/P1/P2 playbook, A-F grade,
///      estimated recovery days, and autonomous insights.
///
/// Sibling to [HabitMomentumService] (habit layer) but focused on the sleep
/// debt accumulation dynamics that those habit trackers cannot model.
library;

import 'dart:math' as math;

// ─── Data Models ──────────────────────────────────────────────────────────────

/// A single night of sleep data for analysis.
class SleepNight {
  final DateTime bedtime;
  final DateTime wakeTime;

  /// 1-5 quality rating (maps to SleepQuality enum values).
  final int quality;

  /// Optional factors that affected this night.
  final List<String> factors;

  const SleepNight({
    required this.bedtime,
    required this.wakeTime,
    this.quality = 3,
    this.factors = const [],
  });

  double get durationHours => wakeTime.difference(bedtime).inMinutes / 60.0;

  DateTime get date => DateTime(wakeTime.year, wakeTime.month, wakeTime.day);

  bool get isWeekend => wakeTime.weekday == DateTime.saturday || wakeTime.weekday == DateTime.sunday;
}

/// Risk appetite for sleep debt analysis.
enum SleepDebtRiskAppetite { cautious, balanced, aggressive }

/// Per-night analysis result.
class NightVerdict {
  final DateTime date;
  final double hoursSlept;
  final double deficit; // positive = under-slept, negative = surplus
  final String verdict;
  final int priority; // 0-3
  final double cumulativeDebt;
  final List<String> reasons;

  const NightVerdict({
    required this.date,
    required this.hoursSlept,
    required this.deficit,
    required this.verdict,
    required this.priority,
    required this.cumulativeDebt,
    required this.reasons,
  });
}

/// A recommended action in the recovery playbook.
class SleepAction {
  final String id;
  final int priority; // 0=P0, 1=P1, 2=P2, 3=P3
  final String label;
  final String reason;
  final String owner; // user / system / environment
  final int blastRadius; // 1-5
  final String reversibility; // low / medium / high

  const SleepAction({
    required this.id,
    required this.priority,
    required this.label,
    required this.reason,
    this.owner = 'user',
    this.blastRadius = 1,
    this.reversibility = 'high',
  });
}

/// Full advisory report.
class SleepDebtReport {
  final double totalDebtHours;
  final double averageNightlyDeficit;
  final int estimatedRecoveryDays;
  final String grade; // A-F
  final String headline;
  final String trend; // improving / stable / worsening
  final double consistencyScore; // 0-100
  final List<NightVerdict> nights;
  final List<SleepAction> playbook;
  final List<String> insights;
  final double debtScore; // 0-100 (higher = worse)

  const SleepDebtReport({
    required this.totalDebtHours,
    required this.averageNightlyDeficit,
    required this.estimatedRecoveryDays,
    required this.grade,
    required this.headline,
    required this.trend,
    required this.consistencyScore,
    required this.nights,
    required this.playbook,
    required this.insights,
    required this.debtScore,
  });
}

// ─── Service ──────────────────────────────────────────────────────────────────

class SleepDebtAdvisorService {
  /// Target sleep hours per night.
  final double targetHours;

  /// Analysis window in days.
  final int windowDays;

  /// Natural debt recovery rate: hours recovered per hour of surplus sleep.
  final double recoveryRate;

  /// Risk appetite modulates thresholds.
  final SleepDebtRiskAppetite riskAppetite;

  /// Injectable clock for testing.
  final DateTime Function() nowFn;

  SleepDebtAdvisorService({
    this.targetHours = 8.0,
    this.windowDays = 14,
    this.recoveryRate = 0.75,
    this.riskAppetite = SleepDebtRiskAppetite.balanced,
    DateTime Function()? nowFn,
  }) : nowFn = nowFn ?? DateTime.now;

  /// Run the full advisory analysis.
  SleepDebtReport analyze(List<SleepNight> nights) {
    if (nights.isEmpty) {
      return SleepDebtReport(
        totalDebtHours: 0,
        averageNightlyDeficit: 0,
        estimatedRecoveryDays: 0,
        grade: 'A',
        headline: 'No sleep data available',
        trend: 'stable',
        consistencyScore: 100,
        nights: [],
        playbook: [
          const SleepAction(
            id: 'START_TRACKING',
            priority: 2,
            label: 'Start tracking sleep',
            reason: 'No data to analyze',
            owner: 'user',
            blastRadius: 1,
            reversibility: 'high',
          ),
        ],
        insights: ['INSUFFICIENT_DATA'],
        debtScore: 0,
      );
    }

    // Sort by date ascending
    final sorted = List<SleepNight>.from(nights)
      ..sort((a, b) => a.wakeTime.compareTo(b.wakeTime));

    // Filter to window
    final now = nowFn();
    final cutoff = now.subtract(Duration(days: windowDays));
    final windowNights = sorted.where((n) => n.wakeTime.isAfter(cutoff)).toList();
    final analysisNights = windowNights.isEmpty ? sorted : windowNights;

    // Compute per-night verdicts with cumulative debt
    final nightVerdicts = _computeNightVerdicts(analysisNights);

    // Compute summary metrics
    final totalDebt = nightVerdicts.isEmpty ? 0.0 : nightVerdicts.last.cumulativeDebt;
    final avgDeficit = nightVerdicts.isEmpty
        ? 0.0
        : nightVerdicts.map((n) => n.deficit).reduce((a, b) => a + b) / nightVerdicts.length;

    // Consistency score from bedtime variance
    final consistencyScore = _computeConsistencyScore(analysisNights);

    // Trend detection (first half vs second half)
    final trend = _detectTrend(nightVerdicts);

    // Debt score 0-100
    final debtScore = _computeDebtScore(totalDebt, avgDeficit, consistencyScore);

    // Grade
    final grade = _computeGrade(debtScore);

    // Recovery estimate (assumes +1h surplus per night with recovery rate)
    final recoveryDays = totalDebt <= 0 ? 0 : (totalDebt / (1.0 * recoveryRate)).ceil();

    // Playbook
    final playbook = _buildPlaybook(
      totalDebt: totalDebt,
      avgDeficit: avgDeficit,
      consistencyScore: consistencyScore,
      trend: trend,
      nights: analysisNights,
      grade: grade,
    );

    // Insights
    final insights = _buildInsights(
      totalDebt: totalDebt,
      avgDeficit: avgDeficit,
      consistencyScore: consistencyScore,
      trend: trend,
      nights: analysisNights,
    );

    // Headline
    final headline = _buildHeadline(grade, totalDebt, trend);

    return SleepDebtReport(
      totalDebtHours: totalDebt,
      averageNightlyDeficit: avgDeficit,
      estimatedRecoveryDays: recoveryDays,
      grade: grade,
      headline: headline,
      trend: trend,
      consistencyScore: consistencyScore,
      nights: nightVerdicts,
      playbook: playbook,
      insights: insights,
      debtScore: debtScore,
    );
  }

  List<NightVerdict> _computeNightVerdicts(List<SleepNight> nights) {
    final results = <NightVerdict>[];
    double cumulativeDebt = 0;

    for (final night in nights) {
      final deficit = targetHours - night.durationHours;

      if (deficit > 0) {
        // Under-slept: add to debt
        cumulativeDebt += deficit;
      } else {
        // Surplus: reduce debt with recovery rate
        cumulativeDebt += deficit * recoveryRate; // deficit is negative
      }
      cumulativeDebt = math.max(0, cumulativeDebt);

      final verdict = _nightVerdict(deficit, cumulativeDebt);
      final priority = _nightPriority(verdict);
      final reasons = _nightReasons(night, deficit, cumulativeDebt);

      results.add(NightVerdict(
        date: night.date,
        hoursSlept: night.durationHours,
        deficit: deficit,
        verdict: verdict,
        priority: priority,
        cumulativeDebt: cumulativeDebt,
        reasons: reasons,
      ));
    }
    return results;
  }

  String _nightVerdict(double deficit, double cumulativeDebt) {
    final appetiteShift = riskAppetite == SleepDebtRiskAppetite.cautious
        ? -0.5
        : riskAppetite == SleepDebtRiskAppetite.aggressive
            ? 0.5
            : 0.0;

    if (deficit <= -0.5) return 'SURPLUS';
    if (deficit.abs() < 0.5 + appetiteShift * 0.2) return 'ON_TARGET';
    if (cumulativeDebt >= 10 + appetiteShift * 2) return 'CRITICAL_DEBT';
    if (deficit >= 2.5 + appetiteShift) return 'SEVERE_DEFICIT';
    if (deficit >= 1.5 + appetiteShift * 0.5) return 'MODERATE_DEFICIT';
    return 'MILD_DEFICIT';
  }

  int _nightPriority(String verdict) {
    switch (verdict) {
      case 'CRITICAL_DEBT':
        return 0;
      case 'SEVERE_DEFICIT':
        return 1;
      case 'MODERATE_DEFICIT':
        return 2;
      case 'MILD_DEFICIT':
        return 2;
      case 'ON_TARGET':
        return 3;
      case 'SURPLUS':
        return 3;
      default:
        return 3;
    }
  }

  List<String> _nightReasons(SleepNight night, double deficit, double cumulativeDebt) {
    final reasons = <String>[];
    if (deficit >= 2.0) reasons.add('LARGE_DEFICIT');
    if (deficit >= 1.0 && deficit < 2.0) reasons.add('MODERATE_DEFICIT');
    if (cumulativeDebt >= 10) reasons.add('DEBT_CRITICAL_THRESHOLD');
    if (cumulativeDebt >= 5 && cumulativeDebt < 10) reasons.add('DEBT_ELEVATED');
    if (night.quality <= 2) reasons.add('LOW_QUALITY_SLEEP');
    if (night.factors.contains('caffeine')) reasons.add('CAFFEINE_FACTOR');
    if (night.factors.contains('stress')) reasons.add('STRESS_FACTOR');
    if (night.factors.contains('screenTime')) reasons.add('SCREEN_TIME_FACTOR');
    if (night.factors.contains('alcohol')) reasons.add('ALCOHOL_FACTOR');
    if (night.isWeekend && deficit < -1.0) reasons.add('WEEKEND_REBOUND');
    if (reasons.isEmpty) reasons.add('NOMINAL');
    return reasons;
  }

  double _computeConsistencyScore(List<SleepNight> nights) {
    if (nights.length < 2) return 100;

    // Bedtime hour variance (0-24 scale, handle midnight wraparound)
    final bedtimeMinutes = nights.map((n) {
      var m = n.bedtime.hour * 60 + n.bedtime.minute;
      if (m < 720) m += 1440; // after midnight -> treat as late evening
      return m.toDouble();
    }).toList();

    final mean = bedtimeMinutes.reduce((a, b) => a + b) / bedtimeMinutes.length;
    final variance = bedtimeMinutes.map((m) => (m - mean) * (m - mean)).reduce((a, b) => a + b) /
        bedtimeMinutes.length;
    final stdDev = math.sqrt(variance);

    // Convert stddev (in minutes) to 0-100 score
    // 0 min stddev = 100, 120+ min stddev = 0
    return math.max(0, math.min(100, 100 - (stdDev / 120) * 100));
  }

  String _detectTrend(List<NightVerdict> nights) {
    if (nights.length < 4) return 'stable';

    final mid = nights.length ~/ 2;
    final firstHalf = nights.sublist(0, mid);
    final secondHalf = nights.sublist(mid);

    final firstAvgDebt = firstHalf.map((n) => n.cumulativeDebt).reduce((a, b) => a + b) / firstHalf.length;
    final secondAvgDebt = secondHalf.map((n) => n.cumulativeDebt).reduce((a, b) => a + b) / secondHalf.length;

    final diff = secondAvgDebt - firstAvgDebt;
    if (diff > 1.5) return 'worsening';
    if (diff < -1.5) return 'improving';
    return 'stable';
  }

  double _computeDebtScore(double totalDebt, double avgDeficit, double consistencyScore) {
    // Base from total debt (0-50 contribution)
    final debtContrib = math.min(50, totalDebt * 3.5);

    // Average deficit contribution (0-30)
    final deficitContrib = math.min(30, math.max(0, avgDeficit) * 15);

    // Inconsistency contribution (0-20)
    final inconsistencyContrib = (100 - consistencyScore) * 0.2;

    final raw = debtContrib + deficitContrib + inconsistencyContrib;

    // Appetite modulation
    final mult = riskAppetite == SleepDebtRiskAppetite.cautious
        ? 1.15
        : riskAppetite == SleepDebtRiskAppetite.aggressive
            ? 0.85
            : 1.0;

    return math.min(100, math.max(0, raw * mult));
  }

  String _computeGrade(double debtScore) {
    if (debtScore >= 80) return 'F';
    if (debtScore >= 65) return 'D';
    if (debtScore >= 45) return 'C';
    if (debtScore >= 25) return 'B';
    return 'A';
  }

  List<SleepAction> _buildPlaybook({
    required double totalDebt,
    required double avgDeficit,
    required double consistencyScore,
    required String trend,
    required List<SleepNight> nights,
    required String grade,
  }) {
    final actions = <SleepAction>[];

    // P0 actions
    if (totalDebt >= 10) {
      actions.add(const SleepAction(
        id: 'IMMEDIATE_SLEEP_EXTENSION',
        priority: 0,
        label: 'Extend sleep by 1-2 hours tonight',
        reason: 'Critical sleep debt accumulated; cognitive impairment risk',
        owner: 'user',
        blastRadius: 3,
        reversibility: 'high',
      ));
    }

    if (totalDebt >= 14) {
      actions.add(const SleepAction(
        id: 'CANCEL_EARLY_COMMITMENTS',
        priority: 0,
        label: 'Cancel or defer early morning commitments this week',
        reason: 'Severe debt requires sustained recovery; early alarms prevent catch-up',
        owner: 'user',
        blastRadius: 4,
        reversibility: 'medium',
      ));
    }

    // P1 actions
    if (avgDeficit >= 1.0) {
      actions.add(const SleepAction(
        id: 'ADVANCE_BEDTIME_30MIN',
        priority: 1,
        label: 'Move bedtime 30 minutes earlier',
        reason: 'Chronic nightly deficit; gradual bedtime shift is sustainable',
        owner: 'user',
        blastRadius: 2,
        reversibility: 'high',
      ));
    }

    if (consistencyScore < 50) {
      actions.add(const SleepAction(
        id: 'STABILIZE_SCHEDULE',
        priority: 1,
        label: 'Fix bedtime to within 30-minute window',
        reason: 'High schedule variance disrupts circadian rhythm',
        owner: 'user',
        blastRadius: 2,
        reversibility: 'high',
      ));
    }

    final caffeineDays = nights.where((n) => n.factors.contains('caffeine')).length;
    if (caffeineDays >= nights.length * 0.4 && nights.isNotEmpty) {
      actions.add(const SleepAction(
        id: 'CAFFEINE_CURFEW',
        priority: 1,
        label: 'Set caffeine curfew at 2 PM',
        reason: 'Caffeine detected on 40%+ of nights with poor sleep',
        owner: 'user',
        blastRadius: 1,
        reversibility: 'high',
      ));
    }

    final screenDays = nights.where((n) => n.factors.contains('screenTime')).length;
    if (screenDays >= nights.length * 0.5 && nights.isNotEmpty) {
      actions.add(const SleepAction(
        id: 'SCREEN_CURFEW',
        priority: 1,
        label: 'No screens 60 minutes before bed',
        reason: 'Screen time correlated with 50%+ of deficit nights',
        owner: 'user',
        blastRadius: 1,
        reversibility: 'high',
      ));
    }

    if (trend == 'worsening') {
      actions.add(const SleepAction(
        id: 'TREND_INTERVENTION',
        priority: 1,
        label: 'Review and address worsening sleep trend',
        reason: 'Sleep debt is accelerating; early intervention prevents critical state',
        owner: 'user',
        blastRadius: 2,
        reversibility: 'high',
      ));
    }

    // P2 actions
    final weekendRebound = nights.where((n) => n.isWeekend && n.durationHours > targetHours + 1.5).length;
    if (weekendRebound >= 2) {
      actions.add(const SleepAction(
        id: 'REDUCE_WEEKEND_OVERSLEEP',
        priority: 2,
        label: 'Cap weekend sleep to target + 1 hour',
        reason: 'Weekend oversleep shifts circadian phase and worsens Monday deficit',
        owner: 'user',
        blastRadius: 2,
        reversibility: 'high',
      ));
    }

    final lowQualityNights = nights.where((n) => n.quality <= 2).length;
    if (lowQualityNights >= nights.length * 0.3 && nights.isNotEmpty) {
      actions.add(const SleepAction(
        id: 'INVESTIGATE_SLEEP_ENVIRONMENT',
        priority: 2,
        label: 'Audit sleep environment (temp, noise, light)',
        reason: '30%+ nights rated poor/terrible quality',
        owner: 'user',
        blastRadius: 1,
        reversibility: 'high',
      ));
    }

    // Cautious adds audit action
    if (riskAppetite == SleepDebtRiskAppetite.cautious &&
        (grade == 'C' || grade == 'D' || grade == 'F')) {
      actions.add(const SleepAction(
        id: 'SCHEDULE_SLEEP_AUDIT',
        priority: 2,
        label: 'Schedule comprehensive sleep audit',
        reason: 'Cautious appetite + low grade warrants formal review',
        owner: 'user',
        blastRadius: 1,
        reversibility: 'high',
      ));
    }

    // P3 fallback
    if (actions.isEmpty ||
        (riskAppetite != SleepDebtRiskAppetite.aggressive && !actions.any((a) => a.priority <= 1))) {
      actions.add(const SleepAction(
        id: 'MAINTAIN_SLEEP_HYGIENE',
        priority: 3,
        label: 'Continue current sleep hygiene practices',
        reason: 'Sleep health within acceptable range',
        owner: 'user',
        blastRadius: 1,
        reversibility: 'high',
      ));
    }

    // Aggressive trims P3 when P0/P1 present
    if (riskAppetite == SleepDebtRiskAppetite.aggressive && actions.any((a) => a.priority <= 1)) {
      actions.removeWhere((a) => a.priority == 3);
    }

    // Sort: priority asc, then id asc
    actions.sort((a, b) {
      final p = a.priority.compareTo(b.priority);
      return p != 0 ? p : a.id.compareTo(b.id);
    });

    return actions;
  }

  List<String> _buildInsights({
    required double totalDebt,
    required double avgDeficit,
    required double consistencyScore,
    required String trend,
    required List<SleepNight> nights,
  }) {
    final insights = <String>[];

    if (totalDebt >= 14) {
      insights.add('CRITICAL_SLEEP_DEBT');
    } else if (totalDebt >= 7) {
      insights.add('ELEVATED_SLEEP_DEBT');
    }

    if (trend == 'worsening') insights.add('WORSENING_TREND');
    if (trend == 'improving') insights.add('IMPROVING_TREND');

    if (consistencyScore < 40) insights.add('IRREGULAR_SCHEDULE');

    final weekendAvg = nights.where((n) => n.isWeekend).map((n) => n.durationHours);
    final weekdayAvg = nights.where((n) => !n.isWeekend).map((n) => n.durationHours);
    if (weekendAvg.isNotEmpty && weekdayAvg.isNotEmpty) {
      final wkendMean = weekendAvg.reduce((a, b) => a + b) / weekendAvg.length;
      final wkdayMean = weekdayAvg.reduce((a, b) => a + b) / weekdayAvg.length;
      if (wkendMean - wkdayMean >= 2.0) insights.add('WEEKEND_REBOUND_PATTERN');
    }

    final stressNights = nights.where((n) => n.factors.contains('stress')).length;
    if (stressNights >= 3 && nights.isNotEmpty) insights.add('STRESS_CORRELATED_DEFICIT');

    final lowQuality = nights.where((n) => n.quality <= 2).length;
    if (lowQuality >= nights.length * 0.4 && nights.isNotEmpty) {
      insights.add('QUALITY_DEGRADATION');
    }

    if (avgDeficit <= 0.25 && totalDebt < 3 && consistencyScore >= 80) {
      insights.add('HEALTHY_SLEEP_PATTERN');
    }

    if (insights.isEmpty) insights.add('NO_NOTABLE_SIGNALS');

    return insights;
  }

  String _buildHeadline(String grade, double totalDebt, String trend) {
    final debtStr = totalDebt.toStringAsFixed(1);
    return 'VERDICT: grade=$grade debt=${debtStr}h trend=$trend';
  }

  // ─── Formatters ───────────────────────────────────────────────────────────

  /// Render report as plain text.
  String formatText(SleepDebtReport report) {
    final buf = StringBuffer();
    buf.writeln(report.headline);
    buf.writeln('');
    buf.writeln('Total Debt: ${report.totalDebtHours.toStringAsFixed(1)}h');
    buf.writeln('Avg Nightly Deficit: ${report.averageNightlyDeficit.toStringAsFixed(1)}h');
    buf.writeln('Recovery Estimate: ${report.estimatedRecoveryDays} days');
    buf.writeln('Consistency: ${report.consistencyScore.toStringAsFixed(0)}/100');
    buf.writeln('Grade: ${report.grade}');
    buf.writeln('');
    buf.writeln('Playbook:');
    for (final a in report.playbook) {
      buf.writeln('  [P${a.priority}] ${a.label} — ${a.reason}');
    }
    buf.writeln('');
    buf.writeln('Insights: ${report.insights.join(', ')}');
    return buf.toString();
  }

  /// Render report as markdown.
  String formatMarkdown(SleepDebtReport report) {
    final buf = StringBuffer();
    buf.writeln('# Sleep Debt Advisory');
    buf.writeln('');
    buf.writeln('**${report.headline}**');
    buf.writeln('');
    buf.writeln('## Summary');
    buf.writeln('');
    buf.writeln('| Metric | Value |');
    buf.writeln('|--------|-------|');
    buf.writeln('| Total Debt | ${report.totalDebtHours.toStringAsFixed(1)}h |');
    buf.writeln('| Avg Nightly Deficit | ${report.averageNightlyDeficit.toStringAsFixed(1)}h |');
    buf.writeln('| Recovery Estimate | ${report.estimatedRecoveryDays} days |');
    buf.writeln('| Consistency Score | ${report.consistencyScore.toStringAsFixed(0)}/100 |');
    buf.writeln('| Debt Score | ${report.debtScore.toStringAsFixed(0)}/100 |');
    buf.writeln('| Grade | ${report.grade} |');
    buf.writeln('| Trend | ${report.trend} |');
    buf.writeln('');
    if (report.nights.isNotEmpty) {
      buf.writeln('## Nights');
      buf.writeln('');
      buf.writeln('| Date | Hours | Deficit | Verdict | Debt |');
      buf.writeln('|------|-------|---------|---------|------|');
      for (final n in report.nights.reversed.take(14)) {
        final dateStr = '${n.date.year}-${n.date.month.toString().padLeft(2, '0')}-${n.date.day.toString().padLeft(2, '0')}';
        buf.writeln('| $dateStr | ${n.hoursSlept.toStringAsFixed(1)} | ${n.deficit.toStringAsFixed(1)} | ${n.verdict} | ${n.cumulativeDebt.toStringAsFixed(1)} |');
      }
      buf.writeln('');
    }
    buf.writeln('## Playbook');
    buf.writeln('');
    buf.writeln('| Priority | Action | Reason | Owner |');
    buf.writeln('|----------|--------|--------|-------|');
    for (final a in report.playbook) {
      buf.writeln('| P${a.priority} | ${a.label} | ${a.reason} | ${a.owner} |');
    }
    buf.writeln('');
    buf.writeln('## Insights');
    buf.writeln('');
    for (final i in report.insights) {
      buf.writeln('- $i');
    }
    return buf.toString();
  }
}
