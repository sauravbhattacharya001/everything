/// Model for a decision list used by the Random Decision Maker.

class DecisionOption {
  final String id;
  final String text;
  final String? emoji;
  final int weight;

  const DecisionOption({
    required this.id,
    required this.text,
    this.emoji,
    this.weight = 1,
  });

  DecisionOption copyWith({String? text, String? emoji, int? weight}) {
    return DecisionOption(
      id: id,
      text: text ?? this.text,
      emoji: emoji ?? this.emoji,
      weight: weight ?? this.weight,
    );
  }
}

class DecisionList {
  final String id;
  final String title;
  final String? emoji;
  final List<DecisionOption> options;
  final List<DecisionResult> history;
  final DateTime createdAt;

  const DecisionList({
    required this.id,
    required this.title,
    this.emoji,
    required this.options,
    this.history = const [],
    required this.createdAt,
  });

  DecisionList copyWith({
    String? title,
    String? emoji,
    List<DecisionOption>? options,
    List<DecisionResult>? history,
  }) {
    return DecisionList(
      id: id,
      title: title ?? this.title,
      emoji: emoji ?? this.emoji,
      options: options ?? this.options,
      history: history ?? this.history,
      createdAt: createdAt,
    );
  }
}

class DecisionResult {
  final String optionId;
  final String optionText;
  final DateTime decidedAt;

  const DecisionResult({
    required this.optionId,
    required this.optionText,
    required this.decidedAt,
  });
}
