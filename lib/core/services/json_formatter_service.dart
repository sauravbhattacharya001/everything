import 'dart:convert';

/// Result of a JSON formatting/validation operation.
class JsonFormatResult {
  final bool isValid;
  final String? formatted;
  final String? minified;
  final String? errorMessage;
  final int? errorOffset;
  final JsonStats? stats;
  final List<JsonPathNode> tree;

  const JsonFormatResult({
    required this.isValid,
    this.formatted,
    this.minified,
    this.errorMessage,
    this.errorOffset,
    this.stats,
    this.tree = const [],
  });
}

/// Statistics about a parsed JSON document.
class JsonStats {
  final int totalKeys;
  final int totalValues;
  final int maxDepth;
  final int arrayCount;
  final int objectCount;
  final int stringCount;
  final int numberCount;
  final int boolCount;
  final int nullCount;

  const JsonStats({
    required this.totalKeys,
    required this.totalValues,
    required this.maxDepth,
    required this.arrayCount,
    required this.objectCount,
    required this.stringCount,
    required this.numberCount,
    required this.boolCount,
    required this.nullCount,
  });
}

/// A node in the JSON tree view.
class JsonPathNode {
  final String key;
  final String type;
  final String? valuePreview;
  final int depth;
  final List<JsonPathNode> children;

  const JsonPathNode({
    required this.key,
    required this.type,
    this.valuePreview,
    required this.depth,
    this.children = const [],
  });
}

/// Service for JSON formatting, validation, and analysis.
class JsonFormatterService {
  /// Validate, format, and analyze a JSON string.
  static JsonFormatResult process(String input, {int indent = 2}) {
    if (input.trim().isEmpty) {
      return const JsonFormatResult(
        isValid: false,
        errorMessage: 'Input is empty',
      );
    }

    try {
      final parsed = jsonDecode(input);
      final encoder = JsonEncoder.withIndent(' ' * indent);
      final formatted = encoder.convert(parsed);
      final minified = jsonEncode(parsed);
      final stats = _computeStats(parsed);
      final tree = _buildTree(parsed, '\$', 0);

      return JsonFormatResult(
        isValid: true,
        formatted: formatted,
        minified: minified,
        stats: stats,
        tree: [tree],
      );
    } on FormatException catch (e) {
      return JsonFormatResult(
        isValid: false,
        errorMessage: e.message,
        errorOffset: e.offset,
      );
    } catch (e) {
      return JsonFormatResult(
        isValid: false,
        errorMessage: e.toString(),
      );
    }
  }

  static JsonStats _computeStats(dynamic value) {
    int totalKeys = 0;
    int totalValues = 0;
    int maxDepth = 0;
    int arrayCount = 0;
    int objectCount = 0;
    int stringCount = 0;
    int numberCount = 0;
    int boolCount = 0;
    int nullCount = 0;

    void walk(dynamic v, int depth) {
      if (depth > maxDepth) maxDepth = depth;

      if (v == null) {
        nullCount++;
        totalValues++;
      } else if (v is bool) {
        boolCount++;
        totalValues++;
      } else if (v is num) {
        numberCount++;
        totalValues++;
      } else if (v is String) {
        stringCount++;
        totalValues++;
      } else if (v is List) {
        arrayCount++;
        for (final item in v) {
          walk(item, depth + 1);
        }
      } else if (v is Map) {
        objectCount++;
        totalKeys += v.length;
        for (final entry in v.entries) {
          walk(entry.value, depth + 1);
        }
      }
    }

    walk(value, 0);
    return JsonStats(
      totalKeys: totalKeys,
      totalValues: totalValues,
      maxDepth: maxDepth,
      arrayCount: arrayCount,
      objectCount: objectCount,
      stringCount: stringCount,
      numberCount: numberCount,
      boolCount: boolCount,
      nullCount: nullCount,
    );
  }

  static JsonPathNode _buildTree(dynamic value, String key, int depth) {
    if (value is Map) {
      return JsonPathNode(
        key: key,
        type: 'object',
        valuePreview: '{${value.length} keys}',
        depth: depth,
        children: value.entries
            .map((e) => _buildTree(e.value, e.key.toString(), depth + 1))
            .toList(),
      );
    } else if (value is List) {
      return JsonPathNode(
        key: key,
        type: 'array',
        valuePreview: '[${value.length} items]',
        depth: depth,
        children: List.generate(
          value.length,
          (i) => _buildTree(value[i], '[$i]', depth + 1),
        ),
      );
    } else if (value is String) {
      final preview = value.length > 50 ? '${value.substring(0, 50)}...' : value;
      return JsonPathNode(
        key: key,
        type: 'string',
        valuePreview: '"$preview"',
        depth: depth,
      );
    } else if (value is num) {
      return JsonPathNode(
        key: key,
        type: 'number',
        valuePreview: value.toString(),
        depth: depth,
      );
    } else if (value is bool) {
      return JsonPathNode(
        key: key,
        type: 'boolean',
        valuePreview: value.toString(),
        depth: depth,
      );
    } else {
      return JsonPathNode(
        key: key,
        type: 'null',
        valuePreview: 'null',
        depth: depth,
      );
    }
  }

  /// Pretty-print with custom indent.
  static String? format(String input, {int indent = 2}) {
    try {
      return JsonEncoder.withIndent(' ' * indent).convert(jsonDecode(input));
    } catch (_) {
      return null;
    }
  }

  /// Minify JSON by removing all whitespace.
  static String? minify(String input) {
    try {
      return jsonEncode(jsonDecode(input));
    } catch (_) {
      return null;
    }
  }
}
