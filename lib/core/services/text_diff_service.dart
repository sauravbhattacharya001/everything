import 'dart:math';

/// The type of a diff chunk.
enum DiffType { equal, added, removed }

/// A single chunk in a diff result.
class DiffChunk {
  final DiffType type;
  final String text;
  const DiffChunk(this.type, this.text);
}

/// Statistics about a diff result.
class DiffStats {
  final int additions;
  final int deletions;
  final int unchanged;
  const DiffStats({required this.additions, required this.deletions, required this.unchanged});
  int get total => additions + deletions + unchanged;
  double get similarity => total == 0 ? 1.0 : unchanged / total;
}

/// Service that computes line-by-line and character-level diffs
/// using the Myers diff algorithm (simple O(ND) approach).
class TextDiffService {
  /// Compare two texts line-by-line and return diff chunks.
  List<DiffChunk> diffLines(String oldText, String newText) {
    final oldLines = oldText.split('\n');
    final newLines = newText.split('\n');
    return _diff(oldLines, newLines, (lines) => lines.join('\n'));
  }

  /// Compare two texts character-by-character and return diff chunks.
  List<DiffChunk> diffChars(String oldText, String newText) {
    final oldChars = oldText.split('');
    final newChars = newText.split('');
    return _diff(oldChars, newChars, (chars) => chars.join());
  }

  /// Compare two texts word-by-word and return diff chunks.
  List<DiffChunk> diffWords(String oldText, String newText) {
    final oldWords = _tokenize(oldText);
    final newWords = _tokenize(newText);
    return _diff(oldWords, newWords, (words) => words.join());
  }

  /// Compute statistics from a diff result.
  DiffStats stats(List<DiffChunk> chunks) {
    int added = 0, removed = 0, unchanged = 0;
    for (final c in chunks) {
      final len = c.text.length;
      switch (c.type) {
        case DiffType.added:
          added += len;
          break;
        case DiffType.removed:
          removed += len;
          break;
        case DiffType.equal:
          unchanged += len;
          break;
      }
    }
    return DiffStats(additions: added, deletions: removed, unchanged: unchanged);
  }

  /// Tokenize text into words and whitespace tokens for word-level diff.
  List<String> _tokenize(String text) {
    final tokens = <String>[];
    final re = RegExp(r'\S+|\s+');
    for (final m in re.allMatches(text)) {
      tokens.add(m.group(0)!);
    }
    return tokens;
  }

  /// Generic Myers-like diff on sequences of tokens.
  List<DiffChunk> _diff(
    List<String> oldTokens,
    List<String> newTokens,
    String Function(List<String>) join,
  ) {
    // Compute LCS table
    final n = oldTokens.length;
    final m = newTokens.length;

    // For very large inputs, fall back to a simpler approach
    if (n * m > 10000000) {
      return _simpleDiff(oldTokens, newTokens, join);
    }

    // Standard LCS with DP
    final dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));
    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        if (oldTokens[i - 1] == newTokens[j - 1]) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
        }
      }
    }

    // Backtrack to get diff
    final result = <DiffChunk>[];
    int i = n, j = m;
    final removedBuf = <String>[];
    final addedBuf = <String>[];
    final equalBuf = <String>[];

    void flushEqual() {
      if (equalBuf.isNotEmpty) {
        result.add(DiffChunk(DiffType.equal, join(equalBuf.toList())));
        equalBuf.clear();
      }
    }

    void flushChanges() {
      if (removedBuf.isNotEmpty) {
        result.add(DiffChunk(DiffType.removed, join(removedBuf.toList())));
        removedBuf.clear();
      }
      if (addedBuf.isNotEmpty) {
        result.add(DiffChunk(DiffType.added, join(addedBuf.toList())));
        addedBuf.clear();
      }
    }

    // Build in reverse
    final reversed = <_DiffOp>[];
    while (i > 0 && j > 0) {
      if (oldTokens[i - 1] == newTokens[j - 1]) {
        reversed.add(_DiffOp.equal(oldTokens[i - 1]));
        i--;
        j--;
      } else if (dp[i - 1][j] >= dp[i][j - 1]) {
        reversed.add(_DiffOp.removed(oldTokens[i - 1]));
        i--;
      } else {
        reversed.add(_DiffOp.added(newTokens[j - 1]));
        j--;
      }
    }
    while (i > 0) {
      reversed.add(_DiffOp.removed(oldTokens[i - 1]));
      i--;
    }
    while (j > 0) {
      reversed.add(_DiffOp.added(newTokens[j - 1]));
      j--;
    }

    // Process in forward order
    for (final op in reversed.reversed) {
      if (op.type == DiffType.equal) {
        flushChanges();
        equalBuf.add(op.token);
      } else if (op.type == DiffType.removed) {
        flushEqual();
        removedBuf.add(op.token);
      } else {
        flushEqual();
        addedBuf.add(op.token);
      }
    }
    flushEqual();
    flushChanges();

    return result;
  }

  /// Simple fallback diff for large inputs.
  List<DiffChunk> _simpleDiff(
    List<String> oldTokens,
    List<String> newTokens,
    String Function(List<String>) join,
  ) {
    final result = <DiffChunk>[];
    if (oldTokens.isNotEmpty) {
      result.add(DiffChunk(DiffType.removed, join(oldTokens)));
    }
    if (newTokens.isNotEmpty) {
      result.add(DiffChunk(DiffType.added, join(newTokens)));
    }
    return result;
  }
}

class _DiffOp {
  final DiffType type;
  final String token;
  const _DiffOp(this.type, this.token);
  factory _DiffOp.equal(String t) => _DiffOp(DiffType.equal, t);
  factory _DiffOp.added(String t) => _DiffOp(DiffType.added, t);
  factory _DiffOp.removed(String t) => _DiffOp(DiffType.removed, t);
}
