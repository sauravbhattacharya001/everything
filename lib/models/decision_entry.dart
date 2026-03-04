import 'dart:convert';

/// Categories for decisions to enable pattern analysis.
enum DecisionCategory {
  career,
  finance,
  health,
  relationships,
  education,
  technology,
  lifestyle,
  business,
  creative,
  other;

  String get label {
    switch (this) {
      case DecisionCategory.career:
        return 'Career';
      case DecisionCategory.finance:
        return 'Finance';
      case DecisionCategory.health:
        return 'Health';
      case DecisionCategory.relationships:
        return 'Relationships';
      case DecisionCategory.education:
        return 'Education';
      case DecisionCategory.technology:
        return 'Technology';
      case DecisionCategory.lifestyle:
        return 'Lifestyle';
      case DecisionCategory.business:
        return 'Business';
      case DecisionCategory.creative:
        return 'Creative';
      case DecisionCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case DecisionCategory.career:
        return '💼';
      case DecisionCategory.finance:
        return '💰';
      case DecisionCategory.health:
        return '🏥';
      case DecisionCategory.relationships:
        return '❤️';
      case DecisionCategory.education:
        return '🎓';
      case DecisionCategory.technology:
        return '💻';
      case DecisionCategory.lifestyle:
        return '🏡';
      case DecisionCategory.business:
        return '📈';
      case DecisionCategory.creative:
        return '🎨';
      case DecisionCategory.other:
        return '📝';
    }
  }

  static DecisionCategory fromString(String value) {
    return DecisionCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => DecisionCategory.other,
    );
  }
}

/// Confidence level when making a decision.
enum ConfidenceLevel {
  veryLow,
  low,
  moderate,
  high,
  veryHigh;

  String get label {
    switch (this) {
      case ConfidenceLevel.veryLow:
        return 'Very Low';
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

  int get value {
    switch (this) {
      case ConfidenceLevel.veryLow:
        return 1;
      case ConfidenceLevel.low:
        return 2;
      case ConfidenceLevel.moderate:
        return 3;
      case ConfidenceLevel.high:
        return 4;
      case ConfidenceLevel.veryHigh:
        return 5;
    }
  }

  static ConfidenceLevel fromValue(int value) {
    switch (value) {
      case 1:
        return ConfidenceLevel.veryLow;
      case 2:
        return ConfidenceLevel.low;
      case 3:
        return ConfidenceLevel.moderate;
      case 4:
        return ConfidenceLevel.high;
      case 5:
        return ConfidenceLevel.veryHigh;
      default:
        return ConfidenceLevel.moderate;
    }
  }
}

/// Outcome assessment after a decision has played out.
enum DecisionOutcome {
  muchWorse,
  worse,
  asExpected,
  better,
  muchBetter;

  String get label {
    switch (this) {
      case DecisionOutcome.muchWorse:
        return 'Much Worse';
      case DecisionOutcome.worse:
        return 'Worse';
      case DecisionOutcome.asExpected:
        return 'As Expected';
      case DecisionOutcome.better:
        return 'Better';
      case DecisionOutcome.muchBetter:
        return 'Much Better';
    }
  }

  String get emoji {
    switch (this) {
      case DecisionOutcome.muchWorse:
        return '😰';
      case DecisionOutcome.worse:
        return '😕';
      case DecisionOutcome.asExpected:
        return '😐';
      case DecisionOutcome.better:
        return '😊';
      case DecisionOutcome.muchBetter:
        return '🎉';
    }
  }

  int get value {
    switch (this) {
      case DecisionOutcome.muchWorse:
        return 1;
      case DecisionOutcome.worse:
        return 2;
      case DecisionOutcome.asExpected:
        return 3;
      case DecisionOutcome.better:
        return 4;
      case DecisionOutcome.muchBetter:
        return 5;
    }
  }

  /// Whether the outcome met or exceeded expectations.
  bool get isPositive => value >= 3;

  static DecisionOutcome fromValue(int value) {
    switch (value) {
      case 1:
        return DecisionOutcome.muchWorse;
      case 2:
        return DecisionOutcome.worse;
      case 3:
        return DecisionOutcome.asExpected;
      case 4:
        return DecisionOutcome.better;
      case 5:
        return DecisionOutcome.muchBetter;
      default:
        return DecisionOutcome.asExpected;
    }
  }
}

/// An alternative option that was considered but not chosen.
class Alternative {
  final String description;
  final String? reason;

  const Alternative({required this.description, this.reason});

  Map<String, dynamic> toJson() => {
        'description': description,
        if (reason != null) 'reason': reason,
      };

  factory Alternative.fromJson(Map<String, dynamic> json) {
    return Alternative(
      description: json['description'] as String? ?? '',
      reason: json['reason'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Alternative &&
          description == other.description &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(description, reason);
}

/// A single decision journal entry.
///
/// Captures the decision context at the time it was made, then allows
/// recording the actual outcome later for reflection and learning.
class DecisionEntry {
  final String id;
  final DateTime decidedAt;
  final String title;
  final String description;
  final DecisionCategory category;
  final ConfidenceLevel confidence;
  final String expectedOutcome;
  final List<Alternative> alternatives;
  final String? context;
  final DateTime? reviewDate;
  final DecisionOutcome? outcome;
  final DateTime? reviewedAt;
  final String? reflection;
  final String? lessonsLearned;

  const DecisionEntry({
    required this.id,
    required this.decidedAt,
    required this.title,
    required this.description,
    required this.category,
    required this.confidence,
    required this.expectedOutcome,
    this.alternatives = const [],
    this.context,
    this.reviewDate,
    this.outcome,
    this.reviewedAt,
    this.reflection,
    this.lessonsLearned,
  });

  /// Whether this decision has been reviewed.
  bool get isReviewed => outcome != null;

  /// Whether a review is due (past the review date and not yet reviewed).
  bool get isReviewDue =>
      !isReviewed &&
      reviewDate != null &&
      DateTime.now().isAfter(reviewDate!);

  /// Days since the decision was made.
  int get daysSinceDecision =>
      DateTime.now().difference(decidedAt).inDays;

  /// Whether the outcome matched confidence direction.
  bool? get wasCalibrated {
    if (outcome == null) return null;
    if (confidence.value >= 4 && outcome!.isPositive) return true;
    if (confidence.value <= 2 && !outcome!.isPositive) return true;
    if (confidence.value >= 4 && !outcome!.isPositive) return false;
    if (confidence.value <= 2 && outcome!.isPositive) return false;
    return null; // Moderate confidence — inconclusive
  }

  DecisionEntry copyWith({
    String? id,
    DateTime? decidedAt,
    String? title,
    String? description,
    DecisionCategory? category,
    ConfidenceLevel? confidence,
    String? expectedOutcome,
    List<Alternative>? alternatives,
    String? context,
    DateTime? reviewDate,
    DecisionOutcome? outcome,
    DateTime? reviewedAt,
    String? reflection,
    String? lessonsLearned,
  }) {
    return DecisionEntry(
      id: id ?? this.id,
      decidedAt: decidedAt ?? this.decidedAt,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      confidence: confidence ?? this.confidence,
      expectedOutcome: expectedOutcome ?? this.expectedOutcome,
      alternatives: alternatives ?? this.alternatives,
      context: context ?? this.context,
      reviewDate: reviewDate ?? this.reviewDate,
      outcome: outcome ?? this.outcome,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reflection: reflection ?? this.reflection,
      lessonsLearned: lessonsLearned ?? this.lessonsLearned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'decidedAt': decidedAt.toIso8601String(),
      'title': title,
      'description': description,
      'category': category.name,
      'confidence': confidence.value,
      'expectedOutcome': expectedOutcome,
      'alternatives': alternatives.map((a) => a.toJson()).toList(),
      if (context != null) 'context': context,
      if (reviewDate != null) 'reviewDate': reviewDate!.toIso8601String(),
      if (outcome != null) 'outcome': outcome!.value,
      if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
      if (reflection != null) 'reflection': reflection,
      if (lessonsLearned != null) 'lessonsLearned': lessonsLearned,
    };
  }

  factory DecisionEntry.fromJson(Map<String, dynamic> json) {
    return DecisionEntry(
      id: json['id'] as String,
      decidedAt: DateTime.tryParse(json['decidedAt'] as String? ?? '') ??
          DateTime.now(),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      category: DecisionCategory.fromString(json['category'] as String? ?? ''),
      confidence: ConfidenceLevel.fromValue(json['confidence'] as int? ?? 3),
      expectedOutcome: json['expectedOutcome'] as String? ?? '',
      alternatives: (json['alternatives'] as List<dynamic>?)
              ?.map((a) => Alternative.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      context: json['context'] as String?,
      reviewDate: json['reviewDate'] != null
          ? DateTime.tryParse(json['reviewDate'] as String)
          : null,
      outcome: json['outcome'] != null
          ? DecisionOutcome.fromValue(json['outcome'] as int)
          : null,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.tryParse(json['reviewedAt'] as String)
          : null,
      reflection: json['reflection'] as String?,
      lessonsLearned: json['lessonsLearned'] as String?,
    );
  }

  static String encodeList(List<DecisionEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<DecisionEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => DecisionEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is DecisionEntry && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'DecisionEntry($id: $title, ${category.label}, ${isReviewed ? "reviewed" : "pending"})';
}
