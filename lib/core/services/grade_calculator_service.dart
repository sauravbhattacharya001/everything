/// A single graded assignment/exam entry.
class GradeEntry {
  String name;
  double weight; // percentage weight (e.g. 30 for 30%)
  double score;  // percentage score (0-100)

  GradeEntry({required this.name, required this.weight, required this.score});

  double get weightedScore => weight * score / 100;
}

/// Letter grade thresholds.
class LetterGrade {
  final String letter;
  final double minScore;
  final String description;

  const LetterGrade(this.letter, this.minScore, this.description);

  static const List<LetterGrade> scale = [
    LetterGrade('A+', 97, 'Exceptional'),
    LetterGrade('A', 93, 'Excellent'),
    LetterGrade('A-', 90, 'Very Good'),
    LetterGrade('B+', 87, 'Good'),
    LetterGrade('B', 83, 'Above Average'),
    LetterGrade('B-', 80, 'Satisfactory'),
    LetterGrade('C+', 77, 'Fair'),
    LetterGrade('C', 73, 'Average'),
    LetterGrade('C-', 70, 'Below Average'),
    LetterGrade('D+', 67, 'Poor'),
    LetterGrade('D', 63, 'Very Poor'),
    LetterGrade('D-', 60, 'Barely Passing'),
    LetterGrade('F', 0, 'Failing'),
  ];

  static LetterGrade fromScore(double score) {
    for (final grade in scale) {
      if (score >= grade.minScore) return grade;
    }
    return scale.last;
  }

  static double toGPA(String letter) {
    switch (letter) {
      case 'A+': case 'A': return 4.0;
      case 'A-': return 3.7;
      case 'B+': return 3.3;
      case 'B': return 3.0;
      case 'B-': return 2.7;
      case 'C+': return 2.3;
      case 'C': return 2.0;
      case 'C-': return 1.7;
      case 'D+': return 1.3;
      case 'D': return 1.0;
      case 'D-': return 0.7;
      default: return 0.0;
    }
  }
}

/// Service for grade calculations.
class GradeCalculatorService {
  final List<GradeEntry> entries = [];

  void addEntry(String name, double weight, double score) {
    entries.add(GradeEntry(name: name, weight: weight, score: score.clamp(0, 100)));
  }

  void removeEntry(int index) {
    if (index >= 0 && index < entries.length) entries.removeAt(index);
  }

  void clear() => entries.clear();

  double get totalWeight => entries.fold(0.0, (sum, e) => sum + e.weight);

  /// Weighted average as a percentage.
  double get weightedAverage {
    if (entries.isEmpty || totalWeight == 0) return 0;
    final totalWeighted = entries.fold(0.0, (sum, e) => sum + e.weightedScore);
    return totalWeighted / totalWeight * 100;
  }

  LetterGrade get letterGrade => LetterGrade.fromScore(weightedAverage);

  double get gpa => LetterGrade.toGPA(letterGrade.letter);

  /// What score is needed on remaining weight to achieve target grade.
  double? scoreNeededForTarget(double targetScore) {
    final remainingWeight = 100 - totalWeight;
    if (remainingWeight <= 0) return null;
    final currentWeighted = entries.fold(0.0, (sum, e) => sum + e.weightedScore);
    final needed = (targetScore - currentWeighted) / remainingWeight * 100;
    return needed;
  }
}
