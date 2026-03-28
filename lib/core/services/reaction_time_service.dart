/// In-memory service for tracking reaction time test results.
class ReactionTimeService {
  final List<ReactionTimeResult> _history = [];

  List<ReactionTimeResult> get history => List.unmodifiable(_history);

  void addResult(ReactionTimeResult result) {
    _history.insert(0, result);
    if (_history.length > 100) _history.removeLast();
  }

  void clearHistory() => _history.clear();

  double? get averageMs {
    if (_history.isEmpty) return null;
    final sum = _history.fold<int>(0, (s, r) => s + r.reactionMs);
    return sum / _history.length;
  }

  int? get bestMs {
    if (_history.isEmpty) return null;
    return _history.map((r) => r.reactionMs).reduce((a, b) => a < b ? a : b);
  }

  int? get worstMs {
    if (_history.isEmpty) return null;
    return _history.map((r) => r.reactionMs).reduce((a, b) => a > b ? a : b);
  }

  int? get last5AverageMs {
    if (_history.isEmpty) return null;
    final recent = _history.take(5).toList();
    final sum = recent.fold<int>(0, (s, r) => s + r.reactionMs);
    return sum ~/ recent.length;
  }

  String ratingFor(int ms) {
    if (ms < 200) return 'Lightning! ⚡';
    if (ms < 250) return 'Excellent';
    if (ms < 300) return 'Great';
    if (ms < 350) return 'Good';
    if (ms < 400) return 'Average';
    if (ms < 500) return 'Below Average';
    return 'Slow';
  }
}

class ReactionTimeResult {
  final int reactionMs;
  final DateTime timestamp;

  ReactionTimeResult({required this.reactionMs, DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();
}
