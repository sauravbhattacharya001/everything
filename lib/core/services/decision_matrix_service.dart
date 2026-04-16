/// Decision Matrix service — weighted multi-criteria decision analysis.
///
/// Users define options and criteria with weights, score each option
/// on each criterion, and the service computes weighted totals and ranks.
class DecisionMatrixService {
  DecisionMatrixService._();

  /// Compute weighted scores for all options.
  ///
  /// [scores] is a Map<optionIndex, Map<criterionIndex, double score (0-10)>>.
  /// [weights] is a List<double> of criterion weights (any positive number).
  /// Returns a list of [DecisionResult] sorted best-first.
  static List<DecisionResult> evaluate({
    required List<String> options,
    required List<DecisionCriterion> criteria,
    required Map<int, Map<int, double>> scores,
  }) {
    if (options.isEmpty || criteria.isEmpty) return [];

    final totalWeight =
        criteria.fold<double>(0, (sum, c) => sum + c.weight);
    if (totalWeight == 0) return [];

    final results = <DecisionResult>[];
    double maxScore = 0;

    for (int i = 0; i < options.length; i++) {
      double weighted = 0;
      final breakdown = <CriterionScore>[];

      for (int j = 0; j < criteria.length; j++) {
        final raw = scores[i]?[j] ?? 0;
        final normalizedWeight = criteria[j].weight / totalWeight;
        final contribution = raw * normalizedWeight;
        weighted += contribution;
        breakdown.add(CriterionScore(
          criterionName: criteria[j].name,
          rawScore: raw,
          weight: criteria[j].weight,
          weightedContribution: contribution,
        ));
      }

      if (weighted > maxScore) maxScore = weighted;
      results.add(DecisionResult(
        option: options[i],
        totalScore: weighted,
        maxPossibleScore: 10.0,
        breakdown: breakdown,
      ));
    }

    // Sort descending by total score
    results.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    // Assign ranks (1-based)
    for (int i = 0; i < results.length; i++) {
      results[i].rank = i + 1;
    }

    return results;
  }

  /// Generate a recommendation blurb.
  static String recommend(List<DecisionResult> results) {
    if (results.isEmpty) return 'Add options and criteria to get started.';
    if (results.length == 1) return '"${results[0].option}" is your only option.';

    final best = results[0];
    final second = results[1];
    final gap = best.totalScore - second.totalScore;

    if (gap < 0.3) {
      return '"${best.option}" and "${second.option}" are very close — '
          'consider your gut feeling.';
    } else if (gap < 1.0) {
      return '"${best.option}" edges out "${second.option}" '
          '(${best.totalScore.toStringAsFixed(1)} vs ${second.totalScore.toStringAsFixed(1)}).';
    } else {
      return '"${best.option}" is the clear winner at '
          '${best.totalScore.toStringAsFixed(1)}/10.';
    }
  }

  /// Identify the strongest criterion for the winning option.
  static String? winnerStrength(List<DecisionResult> results) {
    if (results.isEmpty) return null;
    final best = results[0];
    if (best.breakdown.isEmpty) return null;
    final strongest = best.breakdown.reduce(
        (a, b) => a.weightedContribution > b.weightedContribution ? a : b);
    return 'Strongest factor: ${strongest.criterionName} '
        '(${strongest.rawScore.toStringAsFixed(0)}/10, '
        'weight ${strongest.weight.toStringAsFixed(0)}).';
  }
}

class DecisionCriterion {
  final String name;
  final double weight; // 1-10

  const DecisionCriterion({required this.name, this.weight = 5});
}

class CriterionScore {
  final String criterionName;
  final double rawScore;
  final double weight;
  final double weightedContribution;

  const CriterionScore({
    required this.criterionName,
    required this.rawScore,
    required this.weight,
    required this.weightedContribution,
  });
}

class DecisionResult {
  final String option;
  final double totalScore;
  final double maxPossibleScore;
  final List<CriterionScore> breakdown;
  int rank = 0;

  DecisionResult({
    required this.option,
    required this.totalScore,
    required this.maxPossibleScore,
    required this.breakdown,
  });
}
