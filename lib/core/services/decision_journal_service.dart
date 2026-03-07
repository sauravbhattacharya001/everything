/// Decision Journal Service — track important decisions, record outcomes,
/// and analyze decision-making patterns over time.
///
/// Use this for structured decision logging: capture context, alternatives,
/// confidence, and expected outcomes at decision time. Later, record what
/// actually happened and reflect on lessons learned.
///
/// Key concepts:
///   - **Decision Entry**: A logged decision with context, alternatives,
///     confidence level, and expected outcome.
///   - **Outcome Review**: Recording what actually happened after a
///     configurable review period.
///   - **Confidence Calibration**: How well your confidence predicts actual
///     outcomes. Are you overconfident? Underconfident?
///   - **Category Analysis**: Decision patterns grouped by life domain
///     (career, finance, health, etc.).
///   - **Decision Quality Score**: Composite metric combining calibration,
///     outcome positivity, and reflection completion.

import '../../models/decision_entry.dart';

// ─── Data Classes ───────────────────────────────────────────────

/// Aggregated stats for a decision category.
class CategoryStats {
  final DecisionCategory category;
  final int total;
  final int reviewed;
  final int positiveOutcomes;
  final double avgConfidence;
  final double calibrationRate;

  const CategoryStats({
    required this.category,
    required this.total,
    required this.reviewed,
    required this.positiveOutcomes,
    required this.avgConfidence,
    required this.calibrationRate,
  });

  double get reviewRate => total > 0 ? reviewed / total : 0;
  double get successRate => reviewed > 0 ? positiveOutcomes / reviewed : 0;
}

/// Confidence calibration analysis.
class CalibrationReport {
  final int sampleSize;
  final int calibratedCount;
  final int overconfidentCount;
  final int underconfidentCount;
  final double avgConfidence;
  final double avgOutcome;
  final double calibrationRate;
  final String calibrationLabel;

  const CalibrationReport({
    required this.sampleSize,
    required this.calibratedCount,
    required this.overconfidentCount,
    required this.underconfidentCount,
    required this.avgConfidence,
    required this.avgOutcome,
    required this.calibrationRate,
    required this.calibrationLabel,
  });
}

/// Overall decision journal statistics.
class JournalStats {
  final int totalDecisions;
  final int reviewedDecisions;
  final int pendingReviews;
  final int overdueReviews;
  final Map<DecisionCategory, int> byCategory;
  final double avgConfidence;
  final double avgOutcome;
  final double reviewCompletionRate;

  const JournalStats({
    required this.totalDecisions,
    required this.reviewedDecisions,
    required this.pendingReviews,
    required this.overdueReviews,
    required this.byCategory,
    required this.avgConfidence,
    required this.avgOutcome,
    required this.reviewCompletionRate,
  });
}

/// Review streak tracking.
class ReviewStreak {
  final int current;
  final int longest;

  const ReviewStreak({required this.current, required this.longest});
}

/// Decision quality score with breakdown.
class QualityScore {
  final double overall;
  final double calibration;
  final double outcomes;
  final double reviewCompletion;
  final double reflectionDepth;
  final String label;

  const QualityScore({
    required this.overall,
    required this.calibration,
    required this.outcomes,
    required this.reviewCompletion,
    required this.reflectionDepth,
    required this.label,
  });
}

// ─── Service ────────────────────────────────────────────────────

/// Decision Journal Service.
///
/// Manages a collection of [DecisionEntry] objects with CRUD operations,
/// outcome recording, and analytical capabilities.
class DecisionJournalService {
  final List<DecisionEntry> _entries;
  final Duration defaultReviewPeriod;

  DecisionJournalService({
    List<DecisionEntry>? entries,
    this.defaultReviewPeriod = const Duration(days: 30),
  }) : _entries = entries != null ? List.of(entries) : [];

  List<DecisionEntry> get entries => List.unmodifiable(_entries);
  int get count => _entries.length;

  // ── CRUD ────────────────────────────────────────────────────

  /// Log a new decision.
  DecisionEntry addDecision({
    required String id,
    required String title,
    required String description,
    required DecisionCategory category,
    required ConfidenceLevel confidence,
    required String expectedOutcome,
    List<Alternative> alternatives = const [],
    String? context,
    DateTime? reviewDate,
    DateTime? decidedAt,
    bool setDefaultReview = true,
  }) {
    if (title.trim().isEmpty) {
      throw ArgumentError('Decision title cannot be empty');
    }
    if (description.trim().isEmpty) {
      throw ArgumentError('Decision description cannot be empty');
    }
    if (expectedOutcome.trim().isEmpty) {
      throw ArgumentError('Expected outcome cannot be empty');
    }
    if (_entries.any((e) => e.id == id)) {
      throw StateError('Decision with id "$id" already exists');
    }

    final now = decidedAt ?? DateTime.now();
    final entry = DecisionEntry(
      id: id,
      decidedAt: now,
      title: title.trim(),
      description: description.trim(),
      category: category,
      confidence: confidence,
      expectedOutcome: expectedOutcome.trim(),
      alternatives: alternatives,
      context: context?.trim(),
      reviewDate: reviewDate ??
          (setDefaultReview ? now.add(defaultReviewPeriod) : null),
    );

    _entries.add(entry);
    return entry;
  }

  /// Get a decision by ID.
  DecisionEntry? getById(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Update a decision (before it's reviewed).
  DecisionEntry updateDecision(
    String id, {
    String? title,
    String? description,
    DecisionCategory? category,
    ConfidenceLevel? confidence,
    String? expectedOutcome,
    List<Alternative>? alternatives,
    String? context,
    DateTime? reviewDate,
  }) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw StateError('Decision "$id" not found');
    }

    final updated = _entries[index].copyWith(
      title: title,
      description: description,
      category: category,
      confidence: confidence,
      expectedOutcome: expectedOutcome,
      alternatives: alternatives,
      context: context,
      reviewDate: reviewDate,
    );

    _entries[index] = updated;
    return updated;
  }

  /// Remove a decision. Returns true if found and removed.
  bool removeDecision(String id) {
    final lengthBefore = _entries.length;
    _entries.removeWhere((e) => e.id == id);
    return _entries.length < lengthBefore;
  }

  // ── Outcome Recording ─────────────────────────────────────

  /// Record the outcome of a decision.
  DecisionEntry recordOutcome(
    String id, {
    required DecisionOutcome outcome,
    String? reflection,
    String? lessonsLearned,
    DateTime? reviewedAt,
  }) {
    final index = _entries.indexWhere((e) => e.id == id);
    if (index == -1) {
      throw StateError('Decision "$id" not found');
    }

    final updated = _entries[index].copyWith(
      outcome: outcome,
      reviewedAt: reviewedAt ?? DateTime.now(),
      reflection: reflection?.trim(),
      lessonsLearned: lessonsLearned?.trim(),
    );

    _entries[index] = updated;
    return updated;
  }

  // ── Queries ───────────────────────────────────────────────

  /// Decisions pending review (have review date, not yet reviewed).
  List<DecisionEntry> get pendingReviews {
    return _entries
        .where((e) => !e.isReviewed && e.reviewDate != null)
        .toList()
      ..sort((a, b) => a.reviewDate!.compareTo(b.reviewDate!));
  }

  /// Decisions with overdue reviews.
  List<DecisionEntry> get overdueReviews {
    return _entries.where((e) => e.isReviewDue).toList()
      ..sort((a, b) => a.reviewDate!.compareTo(b.reviewDate!));
  }

  /// Decisions in a specific category.
  List<DecisionEntry> byCategory(DecisionCategory category) {
    return _entries.where((e) => e.category == category).toList();
  }

  /// Decisions made within a date range.
  List<DecisionEntry> inDateRange(DateTime start, DateTime end) {
    return _entries
        .where((e) =>
            !e.decidedAt.isBefore(start) && !e.decidedAt.isAfter(end))
        .toList();
  }

  /// Decisions made in the last N days.
  List<DecisionEntry> recentDecisions(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _entries.where((e) => e.decidedAt.isAfter(cutoff)).toList();
  }

  /// All reviewed decisions.
  List<DecisionEntry> get reviewedDecisions {
    return _entries.where((e) => e.isReviewed).toList();
  }

  /// Search decisions by title or description.
  List<DecisionEntry> search(String query) {
    if (query.trim().isEmpty) return [];
    final lowerQuery = query.toLowerCase();
    return _entries.where((e) {
      return e.title.toLowerCase().contains(lowerQuery) ||
          e.description.toLowerCase().contains(lowerQuery) ||
          (e.context?.toLowerCase().contains(lowerQuery) ?? false) ||
          (e.reflection?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  // ── Analytics ─────────────────────────────────────────────

  /// Overall journal statistics.
  JournalStats getStats() {
    final reviewed = _entries.where((e) => e.isReviewed).toList();
    final pending =
        _entries.where((e) => !e.isReviewed && e.reviewDate != null).length;
    final overdue = _entries.where((e) => e.isReviewDue).length;

    final categoryMap = <DecisionCategory, int>{};
    for (final entry in _entries) {
      categoryMap[entry.category] =
          (categoryMap[entry.category] ?? 0) + 1;
    }

    double avgConf = 0;
    double avgOut = 0;
    if (_entries.isNotEmpty) {
      avgConf = _entries
              .map((e) => e.confidence.value)
              .reduce((a, b) => a + b) /
          _entries.length;
    }
    if (reviewed.isNotEmpty) {
      avgOut = reviewed
              .map((e) => e.outcome!.value)
              .reduce((a, b) => a + b) /
          reviewed.length;
    }

    return JournalStats(
      totalDecisions: _entries.length,
      reviewedDecisions: reviewed.length,
      pendingReviews: pending,
      overdueReviews: overdue,
      byCategory: categoryMap,
      avgConfidence: avgConf,
      avgOutcome: avgOut,
      reviewCompletionRate:
          _entries.isEmpty ? 0 : reviewed.length / _entries.length,
    );
  }

  /// Stats for a specific category.
  CategoryStats getCategoryStats(DecisionCategory category) {
    final catEntries = byCategory(category);
    final reviewed = catEntries.where((e) => e.isReviewed).toList();
    final positive = reviewed.where((e) => e.outcome!.isPositive).length;

    double avgConf = 0;
    if (catEntries.isNotEmpty) {
      avgConf = catEntries
              .map((e) => e.confidence.value)
              .reduce((a, b) => a + b) /
          catEntries.length;
    }

    int calibrated = 0;
    for (final e in reviewed) {
      if (e.wasCalibrated == true) calibrated++;
    }

    return CategoryStats(
      category: category,
      total: catEntries.length,
      reviewed: reviewed.length,
      positiveOutcomes: positive,
      avgConfidence: avgConf,
      calibrationRate: reviewed.isEmpty ? 0 : calibrated / reviewed.length,
    );
  }

  /// Analyze confidence calibration across all reviewed decisions.
  CalibrationReport getCalibrationReport() {
    final reviewed = _entries.where((e) => e.isReviewed).toList();
    if (reviewed.isEmpty) {
      return const CalibrationReport(
        sampleSize: 0,
        calibratedCount: 0,
        overconfidentCount: 0,
        underconfidentCount: 0,
        avgConfidence: 0,
        avgOutcome: 0,
        calibrationRate: 0,
        calibrationLabel: 'Insufficient data',
      );
    }

    int calibrated = 0;
    int overconfident = 0;
    int underconfident = 0;
    double totalConf = 0;
    double totalOut = 0;

    for (final entry in reviewed) {
      totalConf += entry.confidence.value;
      totalOut += entry.outcome!.value;

      final cal = entry.wasCalibrated;
      if (cal == true) {
        calibrated++;
      } else if (cal == false) {
        if (entry.confidence.value >= 4) {
          overconfident++;
        } else {
          underconfident++;
        }
      }
    }

    final rate = calibrated / reviewed.length;
    String label;
    if (reviewed.length < 5) {
      label = 'Too few decisions';
    } else if (rate >= 0.8) {
      label = 'Excellent';
    } else if (rate >= 0.6) {
      label = 'Good';
    } else if (rate >= 0.4) {
      label = 'Fair';
    } else {
      label = 'Needs improvement';
    }

    return CalibrationReport(
      sampleSize: reviewed.length,
      calibratedCount: calibrated,
      overconfidentCount: overconfident,
      underconfidentCount: underconfident,
      avgConfidence: totalConf / reviewed.length,
      avgOutcome: totalOut / reviewed.length,
      calibrationRate: rate,
      calibrationLabel: label,
    );
  }

  /// Review streak (consecutive reviewed decisions by date).
  ReviewStreak getReviewStreak() {
    if (_entries.isEmpty) {
      return const ReviewStreak(current: 0, longest: 0);
    }

    final sorted = List.of(_entries)
      ..sort((a, b) => b.decidedAt.compareTo(a.decidedAt));

    int current = 0;
    for (final entry in sorted) {
      if (entry.isReviewed) {
        current++;
      } else {
        break;
      }
    }

    int longest = 0;
    int streak = 0;
    for (final entry in sorted) {
      if (entry.isReviewed) {
        streak++;
        if (streak > longest) longest = streak;
      } else {
        streak = 0;
      }
    }

    return ReviewStreak(current: current, longest: longest);
  }

  /// Composite decision quality score (0-100).
  QualityScore getQualityScore() {
    if (_entries.isEmpty) {
      return const QualityScore(
        overall: 0,
        calibration: 0,
        outcomes: 0,
        reviewCompletion: 0,
        reflectionDepth: 0,
        label: 'No data',
      );
    }

    final reviewed = _entries.where((e) => e.isReviewed).toList();

    // Calibration (25%)
    double calScore = 0;
    if (reviewed.isNotEmpty) {
      int calibrated = 0;
      for (final e in reviewed) {
        if (e.wasCalibrated == true) calibrated++;
      }
      calScore = (calibrated / reviewed.length) * 100;
    }

    // Outcomes (25%)
    double outScore = 0;
    if (reviewed.isNotEmpty) {
      final avgOut = reviewed
              .map((e) => e.outcome!.value)
              .reduce((a, b) => a + b) /
          reviewed.length;
      outScore = ((avgOut - 1) / 4) * 100;
    }

    // Review completion (25%)
    final reviewScore = (reviewed.length / _entries.length) * 100;

    // Reflection depth (25%)
    double reflScore = 0;
    if (reviewed.isNotEmpty) {
      int withReflection = 0;
      for (final e in reviewed) {
        if (e.reflection != null && e.reflection!.isNotEmpty) {
          withReflection++;
        }
        if (e.lessonsLearned != null && e.lessonsLearned!.isNotEmpty) {
          withReflection++;
        }
      }
      reflScore = (withReflection / (reviewed.length * 2)) * 100;
    }

    final overall = (calScore * 0.25) +
        (outScore * 0.25) +
        (reviewScore * 0.25) +
        (reflScore * 0.25);

    String label;
    if (overall >= 80) {
      label = 'Excellent';
    } else if (overall >= 60) {
      label = 'Good';
    } else if (overall >= 40) {
      label = 'Fair';
    } else if (overall >= 20) {
      label = 'Developing';
    } else {
      label = 'Getting started';
    }

    return QualityScore(
      overall: overall,
      calibration: calScore,
      outcomes: outScore,
      reviewCompletion: reviewScore,
      reflectionDepth: reflScore,
      label: label,
    );
  }

  /// Most common decision categories, ranked by count.
  List<MapEntry<DecisionCategory, int>> topCategories({int limit = 5}) {
    final counts = <DecisionCategory, int>{};
    for (final entry in _entries) {
      counts[entry.category] = (counts[entry.category] ?? 0) + 1;
    }
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  /// All lessons learned from reviewed decisions.
  List<String> allLessonsLearned() {
    return _entries
        .where(
            (e) => e.lessonsLearned != null && e.lessonsLearned!.isNotEmpty)
        .map((e) => e.lessonsLearned!)
        .toList();
  }

  // ── Persistence ───────────────────────────────────────────

  String exportToJson() => DecisionEntry.encodeList(_entries);

  void importFromJson(String jsonStr) {
    // Parse into a temporary list first — if the JSON is malformed or
    // contains invalid entries, the existing data is preserved instead
    // of being cleared and lost.
    final parsed = DecisionEntry.decodeList(jsonStr);
    _entries.clear();
    _entries.addAll(parsed);
  }

  void clear() => _entries.clear();
}
