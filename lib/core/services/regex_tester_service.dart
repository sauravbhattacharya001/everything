import 'dart:async';
import 'dart:isolate';

/// Service for regex testing and pattern analysis.
///
/// User-supplied regular expressions are executed in a separate [Isolate]
/// with a hard timeout to prevent ReDoS (Regular Expression Denial of
/// Service) attacks where a crafted pattern + input can lock the UI
/// thread for minutes or longer.
class RegexTesterService {
  RegexTesterService._();

  /// Maximum allowed input length (100 KB).
  ///
  /// Longer inputs increase the worst-case cost of pathological patterns
  /// exponentially. 100 KB is generous for any reasonable testing scenario.
  static const int maxInputLength = 100 * 1024;

  /// Maximum allowed pattern length (1 KB).
  static const int maxPatternLength = 1024;

  /// Timeout for regex execution in the isolate.
  static const Duration executionTimeout = Duration(seconds: 3);

  /// Maximum number of matches returned to avoid memory exhaustion.
  static const int maxMatches = 1000;

  /// Test a regex pattern against input text and return all matches.
  ///
  /// Runs the regex in a separate [Isolate] with a [executionTimeout]
  /// to prevent ReDoS from freezing the app. Returns an error result
  /// if the pattern is too complex or the input is too large.
  static Future<RegexTestResult> test({
    required String pattern,
    required String input,
    bool caseSensitive = true,
    bool multiLine = false,
    bool dotAll = false,
    bool unicode = false,
  }) async {
    if (pattern.isEmpty) {
      return const RegexTestResult(
        matches: [],
        matchCount: 0,
        groupCount: 0,
        error: null,
      );
    }

    // Enforce input length limits before spawning an isolate.
    if (pattern.length > maxPatternLength) {
      return RegexTestResult(
        matches: const [],
        matchCount: 0,
        groupCount: 0,
        error: 'Pattern exceeds maximum length of $maxPatternLength characters.',
      );
    }

    if (input.length > maxInputLength) {
      return RegexTestResult(
        matches: const [],
        matchCount: 0,
        groupCount: 0,
        error: 'Input exceeds maximum length of '
            '${maxInputLength ~/ 1024} KB.',
      );
    }

    // Run regex matching in an isolate with a timeout so a pathological
    // pattern cannot block the UI thread or run indefinitely.
    try {
      final result = await _runInIsolate(
        pattern: pattern,
        input: input,
        caseSensitive: caseSensitive,
        multiLine: multiLine,
        dotAll: dotAll,
        unicode: unicode,
      ).timeout(executionTimeout);

      return result;
    } on TimeoutException {
      return const RegexTestResult(
        matches: [],
        matchCount: 0,
        groupCount: 0,
        error: 'Pattern evaluation timed out — the regex may be too complex '
            'or vulnerable to catastrophic backtracking (ReDoS). '
            'Try simplifying the pattern or reducing the input size.',
      );
    }
  }

  /// Executes regex matching inside a short-lived [Isolate].
  static Future<RegexTestResult> _runInIsolate({
    required String pattern,
    required String input,
    required bool caseSensitive,
    required bool multiLine,
    required bool dotAll,
    required bool unicode,
  }) async {
    final receivePort = ReceivePort();

    late final Isolate isolate;
    try {
      isolate = await Isolate.spawn(
        _isolateWorker,
        _IsolateRequest(
          pattern: pattern,
          input: input,
          caseSensitive: caseSensitive,
          multiLine: multiLine,
          dotAll: dotAll,
          unicode: unicode,
          sendPort: receivePort.sendPort,
        ),
      );

      final response = await receivePort.first;
      if (response is RegexTestResult) {
        return response;
      }
      // Unexpected type — treat as error.
      return RegexTestResult(
        matches: const [],
        matchCount: 0,
        groupCount: 0,
        error: 'Unexpected isolate response: ${response.runtimeType}',
      );
    } catch (e) {
      return RegexTestResult(
        matches: const [],
        matchCount: 0,
        groupCount: 0,
        error: 'Failed to run regex: $e',
      );
    } finally {
      receivePort.close();
      // Kill the isolate in case it's still running (timeout path).
      try {
        isolate.kill(priority: Isolate.immediate);
      } catch (_) {
        // Isolate may already be dead.
      }
    }
  }

  /// Entry point for the regex-matching isolate.
  static void _isolateWorker(_IsolateRequest request) {
    try {
      final regex = RegExp(
        request.pattern,
        caseSensitive: request.caseSensitive,
        multiLine: request.multiLine,
        dotAll: request.dotAll,
        unicode: request.unicode,
      );

      final allMatches = regex.allMatches(request.input);
      final matchDetails = <RegexMatchDetail>[];
      var count = 0;

      for (final m in allMatches) {
        if (count >= maxMatches) break;
        final groups = <int, String?>{};
        for (var i = 0; i <= m.groupCount; i++) {
          groups[i] = m.group(i);
        }
        matchDetails.add(RegexMatchDetail(
          fullMatch: m.group(0) ?? '',
          start: m.start,
          end: m.end,
          groups: groups,
        ));
        count++;
      }

      request.sendPort.send(RegexTestResult(
        matches: matchDetails,
        matchCount: matchDetails.length,
        groupCount: allMatches.isNotEmpty
            ? matchDetails.first.groups.length - 1
            : 0,
        error: null,
        truncated: count >= maxMatches,
      ));
    } catch (e) {
      request.sendPort.send(RegexTestResult(
        matches: const [],
        matchCount: 0,
        groupCount: 0,
        error: e.toString(),
      ));
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

/// Internal request message sent to the regex isolate.
class _IsolateRequest {
  final String pattern;
  final String input;
  final bool caseSensitive;
  final bool multiLine;
  final bool dotAll;
  final bool unicode;
  final SendPort sendPort;

  const _IsolateRequest({
    required this.pattern,
    required this.input,
    required this.caseSensitive,
    required this.multiLine,
    required this.dotAll,
    required this.unicode,
    required this.sendPort,
  });
}

class RegexTestResult {
  final List<RegexMatchDetail> matches;
  final int matchCount;
  final int groupCount;
  final String? error;

  /// True if matches were capped at [RegexTesterService.maxMatches].
  final bool truncated;

  const RegexTestResult({
    required this.matches,
    required this.matchCount,
    required this.groupCount,
    required this.error,
    this.truncated = false,
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
