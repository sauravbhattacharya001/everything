/// Service for regex testing and pattern analysis.
class RegexTesterService {
  RegexTesterService._();

  /// Test a regex pattern against input text and return all matches.
  static RegexTestResult test({
    required String pattern,
    required String input,
    bool caseSensitive = true,
    bool multiLine = false,
    bool dotAll = false,
    bool unicode = false,
  }) {
    if (pattern.isEmpty) {
      return const RegexTestResult(
        matches: [],
        matchCount: 0,
        groupCount: 0,
        error: null,
      );
    }

    try {
      final regex = RegExp(
        pattern,
        caseSensitive: caseSensitive,
        multiLine: multiLine,
        dotAll: dotAll,
        unicode: unicode,
      );

      final matches = regex.allMatches(input).toList();
      final matchDetails = matches.map((m) {
        final groups = <int, String?>{};
        for (var i = 0; i <= m.groupCount; i++) {
          groups[i] = m.group(i);
        }
        return RegexMatchDetail(
          fullMatch: m.group(0) ?? '',
          start: m.start,
          end: m.end,
          groups: groups,
        );
      }).toList();

      return RegexTestResult(
        matches: matchDetails,
        matchCount: matchDetails.length,
        groupCount: matches.isNotEmpty ? matches.first.groupCount : 0,
        error: null,
      );
    } catch (e) {
      return RegexTestResult(
        matches: [],
        matchCount: 0,
        groupCount: 0,
        error: e.toString(),
      );
    }
  }

  /// Common regex patterns for quick reference.
  static const Map<String, String> commonPatterns = {
    'Email': r'[\w.+-]+@[\w-]+\.[\w.]+',
    'URL': r'https?://[^\s]+',
    'IPv4 Address': r'\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b',
    'Phone (US)': r'\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}',
    'Date (YYYY-MM-DD)': r'\d{4}-(?:0[1-9]|1[0-2])-(?:0[1-9]|[12]\d|3[01])',
    'Time (HH:MM)': r'(?:[01]\d|2[0-3]):[0-5]\d',
    'Hex Color': r'#(?:[0-9a-fA-F]{3}){1,2}\b',
    'HTML Tag': r'<[^>]+>',
    'Integer': r'-?\d+',
    'Decimal Number': r'-?\d+\.?\d*',
    'Word': r'\b\w+\b',
    'Whitespace': r'\s+',
  };
}

class RegexTestResult {
  final List<RegexMatchDetail> matches;
  final int matchCount;
  final int groupCount;
  final String? error;

  const RegexTestResult({
    required this.matches,
    required this.matchCount,
    required this.groupCount,
    required this.error,
  });
}

class RegexMatchDetail {
  final String fullMatch;
  final int start;
  final int end;
  final Map<int, String?> groups;

  const RegexMatchDetail({
    required this.fullMatch,
    required this.start,
    required this.end,
    required this.groups,
  });
}
