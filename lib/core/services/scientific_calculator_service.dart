import 'dart:math' as math;

/// A simple expression-based scientific calculator service.
///
/// Supports: +, -, *, /, ^, parentheses, and functions:
/// sin, cos, tan, asin, acos, atan, log, ln, sqrt, abs, factorial (!)
///
/// Angles are in degrees by default; set [useDegrees] = false for radians.
class ScientificCalculatorService {
  ScientificCalculatorService._();

  // ── constants ──────────────────────────────────────────────────────
  static const double pi = math.pi;
  static const double e = math.e;

  // ── quick helpers ──────────────────────────────────────────────────
  static double sin(double x, {bool deg = true}) =>
      math.sin(deg ? _toRad(x) : x);
  static double cos(double x, {bool deg = true}) =>
      math.cos(deg ? _toRad(x) : x);
  static double tan(double x, {bool deg = true}) =>
      math.tan(deg ? _toRad(x) : x);
  static double asin(double x, {bool deg = true}) {
    final r = math.asin(x);
    return deg ? _toDeg(r) : r;
  }

  static double acos(double x, {bool deg = true}) {
    final r = math.acos(x);
    return deg ? _toDeg(r) : r;
  }

  static double atan(double x, {bool deg = true}) {
    final r = math.atan(x);
    return deg ? _toDeg(r) : r;
  }

  static double log10(double x) => math.log(x) / math.ln10;
  static double ln(double x) => math.log(x);
  static double sqrt(double x) => math.sqrt(x);
  static double pow(double base, double exp) => math.pow(base, exp).toDouble();

  static double factorial(int n) {
    if (n < 0) throw ArgumentError('Negative factorial');
    if (n > 170) return double.infinity;
    double result = 1;
    for (int i = 2; i <= n; i++) {
      result *= i;
    }
    return result;
  }

  // ── expression evaluator ──────────────────────────────────────────
  /// Evaluate a mathematical expression string and return the result.
  static double evaluate(String expression, {bool useDegrees = true}) {
    final tokens = _tokenize(expression);
    final parser = _Parser(tokens, useDegrees);
    final result = parser.parseExpression();
    if (parser._pos < tokens.length) {
      throw FormatException('Unexpected token: ${tokens[parser._pos]}');
    }
    return result;
  }

  static double _toRad(double deg) => deg * math.pi / 180;
  static double _toDeg(double rad) => rad * 180 / math.pi;

  // ── tokenizer ─────────────────────────────────────────────────────
  static List<String> _tokenize(String expr) {
    final tokens = <String>[];
    final buf = StringBuffer();
    int i = 0;
    while (i < expr.length) {
      final c = expr[i];
      if (c == ' ') {
        i++;
        continue;
      }
      if ('0123456789.'.contains(c)) {
        buf.clear();
        while (i < expr.length && '0123456789.'.contains(expr[i])) {
          buf.write(expr[i++]);
        }
        tokens.add(buf.toString());
        continue;
      }
      if ('abcdefghijklmnopqrstuvwxyz'.contains(c.toLowerCase())) {
        buf.clear();
        while (i < expr.length &&
            'abcdefghijklmnopqrstuvwxyz'.contains(expr[i].toLowerCase())) {
          buf.write(expr[i++]);
        }
        tokens.add(buf.toString().toLowerCase());
        continue;
      }
      tokens.add(c);
      i++;
    }
    return tokens;
  }

  /// Format a result nicely (strip trailing zeros).
  static String format(double value) {
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toStringAsFixed(0);
    }
    final s = value.toStringAsFixed(10);
    // trim trailing zeros after decimal
    if (s.contains('.')) {
      var trimmed = s.replaceAll(RegExp(r'0+$'), '');
      if (trimmed.endsWith('.')) trimmed = trimmed.substring(0, trimmed.length - 1);
      return trimmed;
    }
    return s;
  }
}

/// Recursive-descent parser for math expressions.
class _Parser {
  final List<String> _tokens;
  final bool _deg;
  int _pos = 0;

  _Parser(this._tokens, this._deg);

  String? _peek() => _pos < _tokens.length ? _tokens[_pos] : null;
  String _advance() => _tokens[_pos++];

  // expression = term (('+' | '-') term)*
  double parseExpression() {
    var result = _parseTerm();
    while (_peek() == '+' || _peek() == '-') {
      final op = _advance();
      final right = _parseTerm();
      result = op == '+' ? result + right : result - right;
    }
    return result;
  }

  // term = power (('*' | '/') power)*
  double _parseTerm() {
    var result = _parsePower();
    while (_peek() == '*' || _peek() == '/' || _peek() == '×' || _peek() == '÷') {
      final op = _advance();
      final right = _parsePower();
      result = (op == '*' || op == '×') ? result * right : result / right;
    }
    return result;
  }

  // power = unary ('^' power)?
  double _parsePower() {
    var result = _parseUnary();
    if (_peek() == '^') {
      _advance();
      final exp = _parsePower(); // right-associative
      result = math.pow(result, exp).toDouble();
    }
    return result;
  }

  // unary = ('-' | '+') unary | postfix
  double _parseUnary() {
    if (_peek() == '-') {
      _advance();
      return -_parseUnary();
    }
    if (_peek() == '+') {
      _advance();
      return _parseUnary();
    }
    return _parsePostfix();
  }

  // postfix = primary ('!')?
  double _parsePostfix() {
    var result = _parsePrimary();
    while (_peek() == '!') {
      _advance();
      result = ScientificCalculatorService.factorial(result.toInt());
    }
    return result;
  }

  // primary = number | '(' expr ')' | function '(' expr ')' | constant
  double _parsePrimary() {
    final token = _peek();
    if (token == null) throw const FormatException('Unexpected end');

    // number
    final num = double.tryParse(token);
    if (num != null) {
      _advance();
      return num;
    }

    // parenthesized expression
    if (token == '(') {
      _advance();
      final result = parseExpression();
      if (_peek() != ')') throw const FormatException('Missing )');
      _advance();
      return result;
    }

    // constants
    if (token == 'pi' || token == 'π') {
      _advance();
      return math.pi;
    }
    if (token == 'e') {
      _advance();
      return math.e;
    }

    // functions
    const functions = {
      'sin', 'cos', 'tan', 'asin', 'acos', 'atan',
      'log', 'ln', 'sqrt', 'abs', 'ceil', 'floor', 'round',
    };
    if (functions.contains(token)) {
      _advance();
      if (_peek() != '(') throw FormatException('Expected ( after $token');
      _advance();
      final arg = parseExpression();
      if (_peek() != ')') throw const FormatException('Missing )');
      _advance();
      switch (token) {
        case 'sin':
          return ScientificCalculatorService.sin(arg, deg: _deg);
        case 'cos':
          return ScientificCalculatorService.cos(arg, deg: _deg);
        case 'tan':
          return ScientificCalculatorService.tan(arg, deg: _deg);
        case 'asin':
          return ScientificCalculatorService.asin(arg, deg: _deg);
        case 'acos':
          return ScientificCalculatorService.acos(arg, deg: _deg);
        case 'atan':
          return ScientificCalculatorService.atan(arg, deg: _deg);
        case 'log':
          return ScientificCalculatorService.log10(arg);
        case 'ln':
          return ScientificCalculatorService.ln(arg);
        case 'sqrt':
          return ScientificCalculatorService.sqrt(arg);
        case 'abs':
          return arg.abs();
        case 'ceil':
          return arg.ceilToDouble();
        case 'floor':
          return arg.floorToDouble();
        case 'round':
          return arg.roundToDouble();
        default:
          throw FormatException('Unknown function: $token');
      }
    }

    throw FormatException('Unexpected token: $token');
  }
}
