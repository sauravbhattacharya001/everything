import 'package:flutter/material.dart';
import '../../core/services/scientific_calculator_service.dart';

/// A scientific calculator with button grid, expression display, and history.
class ScientificCalculatorScreen extends StatefulWidget {
  const ScientificCalculatorScreen({super.key});

  @override
  State<ScientificCalculatorScreen> createState() =>
      _ScientificCalculatorScreenState();
}

class _ScientificCalculatorScreenState
    extends State<ScientificCalculatorScreen> {
  String _expression = '';
  String _result = '';
  bool _useDegrees = true;
  final List<_HistoryEntry> _history = [];
  bool _showHistory = false;
  bool _showAdvanced = false;

  void _append(String text) {
    setState(() {
      _expression += text;
      _tryEvaluate();
    });
  }

  void _clear() {
    setState(() {
      _expression = '';
      _result = '';
    });
  }

  void _backspace() {
    if (_expression.isEmpty) return;
    setState(() {
      _expression = _expression.substring(0, _expression.length - 1);
      _tryEvaluate();
    });
  }

  void _tryEvaluate() {
    if (_expression.isEmpty) {
      _result = '';
      return;
    }
    try {
      final value = ScientificCalculatorService.evaluate(
        _expression,
        useDegrees: _useDegrees,
      );
      _result = ScientificCalculatorService.format(value);
    } catch (_) {
      _result = '';
    }
  }

  void _evaluate() {
    if (_result.isEmpty || _expression.isEmpty) return;
    setState(() {
      _history.insert(0, _HistoryEntry(_expression, _result));
      if (_history.length > 50) _history.removeLast();
      _expression = _result;
      _result = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scientific Calculator'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _useDegrees = !_useDegrees),
            child: Text(
              _useDegrees ? 'DEG' : 'RAD',
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: Icon(_showHistory ? Icons.calculate : Icons.history),
            onPressed: () =>
                setState(() => _showHistory = !_showHistory),
          ),
        ],
      ),
      body: _showHistory ? _buildHistory(cs) : _buildCalculator(cs),
    );
  }

  Widget _buildCalculator(ColorScheme cs) {
    return Column(
      children: [
        // Display
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            alignment: Alignment.bottomRight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _expression.isEmpty ? '0' : _expression,
                  style: TextStyle(
                    fontSize: 28,
                    color: cs.onSurface,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _result.isEmpty ? '' : '= $_result',
                  style: TextStyle(
                    fontSize: 20,
                    color: cs.onSurface.withValues(alpha: 0.6),
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1),
        // Advanced toggle
        InkWell(
          onTap: () => setState(() => _showAdvanced = !_showAdvanced),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _showAdvanced
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: cs.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _showAdvanced ? 'Hide functions' : 'Show functions',
                  style: TextStyle(fontSize: 12, color: cs.primary),
                ),
              ],
            ),
          ),
        ),
        // Scientific function buttons
        if (_showAdvanced) ...[
          _buildRow([
            _fn('sin', 'sin('),
            _fn('cos', 'cos('),
            _fn('tan', 'tan('),
            _fn('π', 'pi'),
          ], cs),
          _buildRow([
            _fn('asin', 'asin('),
            _fn('acos', 'acos('),
            _fn('atan', 'atan('),
            _fn('e', 'e'),
          ], cs),
          _buildRow([
            _fn('log', 'log('),
            _fn('ln', 'ln('),
            _fn('√', 'sqrt('),
            _fn('x²', '^2'),
          ], cs),
          _buildRow([
            _fn('xʸ', '^'),
            _fn('|x|', 'abs('),
            _fn('n!', '!'),
            _fn('(', '('),
          ], cs),
        ],
        // Main buttons
        _buildRow([
          _btn('C', onTap: _clear, color: cs.error),
          _btn('⌫', onTap: _backspace),
          _fn(')', ')'),
          _op('÷', '/'),
        ], cs),
        _buildRow([_num('7'), _num('8'), _num('9'), _op('×', '*')], cs),
        _buildRow([_num('4'), _num('5'), _num('6'), _op('−', '-')], cs),
        _buildRow([_num('1'), _num('2'), _num('3'), _op('+', '+')], cs),
        _buildRow([
          _num('0'),
          _num('.'),
          _btn('(', onTap: () => _append('(')),
          _btn('=', onTap: _evaluate, color: cs.primary, textColor: cs.onPrimary),
        ], cs),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildHistory(ColorScheme cs) {
    if (_history.isEmpty) {
      return const Center(child: Text('No history yet'));
    }
    return ListView.builder(
      itemCount: _history.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (_, i) {
        final entry = _history[i];
        return Card(
          child: ListTile(
            title: Text(
              entry.expression,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            subtitle: Text(
              '= ${entry.result}',
              style: TextStyle(
                fontFamily: 'monospace',
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            onTap: () {
              setState(() {
                _expression = entry.result;
                _result = '';
                _showHistory = false;
              });
            },
          ),
        );
      },
    );
  }

  // ── button helpers ─────────────────────────────────────────────────

  _BtnData _num(String label) => _BtnData(label, () => _append(label));

  _BtnData _op(String label, String value) =>
      _BtnData(label, () => _append(value), isOp: true);

  _BtnData _fn(String label, String value) =>
      _BtnData(label, () => _append(value), isFn: true);

  _BtnData _btn(String label,
      {VoidCallback? onTap, Color? color, Color? textColor}) =>
      _BtnData(label, onTap ?? () => _append(label),
          color: color, textColor: textColor);

  Widget _buildRow(List<_BtnData> buttons, ColorScheme cs) {
    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.map((b) {
          final bg = b.color ??
              (b.isOp
                  ? cs.primaryContainer
                  : b.isFn
                      ? cs.tertiaryContainer
                      : null);
          final fg = b.textColor ??
              (b.isOp
                  ? cs.onPrimaryContainer
                  : b.isFn
                      ? cs.onTertiaryContainer
                      : cs.onSurface);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Material(
                color: bg ?? cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: b.onTap,
                  child: Center(
                    child: Text(
                      b.label,
                      style: TextStyle(
                        fontSize: b.isFn ? 14 : 20,
                        fontWeight: FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _BtnData {
  final String label;
  final VoidCallback? onTap;
  final bool isOp;
  final bool isFn;
  final Color? color;
  final Color? textColor;

  _BtnData(this.label, this.onTap,
      {this.isOp = false, this.isFn = false, this.color, this.textColor});
}

class _HistoryEntry {
  final String expression;
  final String result;
  _HistoryEntry(this.expression, this.result);
}
