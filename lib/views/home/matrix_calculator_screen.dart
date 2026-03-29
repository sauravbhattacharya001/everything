import 'package:flutter/material.dart';
import '../../core/services/matrix_calculator_service.dart';

/// Interactive matrix calculator supporting arithmetic, transpose,
/// determinant, inverse, trace, and row echelon form.
class MatrixCalculatorScreen extends StatefulWidget {
  const MatrixCalculatorScreen({super.key});

  @override
  State<MatrixCalculatorScreen> createState() => _MatrixCalculatorScreenState();
}

class _MatrixCalculatorScreenState extends State<MatrixCalculatorScreen> {
  final _matrixAController = TextEditingController(text: '1 0\n0 1');
  final _matrixBController = TextEditingController(text: '2 3\n4 5');
  final _scalarController = TextEditingController(text: '2');

  String _operation = 'A + B';
  String _result = '';

  static const _operations = [
    'A + B',
    'A − B',
    'A × B',
    'Scalar × A',
    'Transpose A',
    'Determinant A',
    'Inverse A',
    'Trace A',
    'Row Echelon A',
  ];

  bool get _needsB =>
      _operation == 'A + B' ||
      _operation == 'A − B' ||
      _operation == 'A × B';

  bool get _needsScalar => _operation == 'Scalar × A';

  void _calculate() {
    final a = MatrixCalculatorService.parse(_matrixAController.text);
    if (a == null) {
      setState(() => _result = 'Error: Invalid Matrix A');
      return;
    }

    setState(() {
      switch (_operation) {
        case 'A + B':
        case 'A − B':
        case 'A × B':
          final b = MatrixCalculatorService.parse(_matrixBController.text);
          if (b == null) {
            _result = 'Error: Invalid Matrix B';
            return;
          }
          List<List<double>>? res;
          if (_operation == 'A + B') {
            res = MatrixCalculatorService.add(a, b);
          } else if (_operation == 'A − B') {
            res = MatrixCalculatorService.subtract(a, b);
          } else {
            res = MatrixCalculatorService.multiply(a, b);
          }
          _result = res != null
              ? MatrixCalculatorService.format(res)
              : 'Error: Incompatible dimensions';
          break;

        case 'Scalar × A':
          final s = double.tryParse(_scalarController.text.trim());
          if (s == null) {
            _result = 'Error: Invalid scalar';
            return;
          }
          _result = MatrixCalculatorService.format(
            MatrixCalculatorService.scale(a, s),
          );
          break;

        case 'Transpose A':
          _result = MatrixCalculatorService.format(
            MatrixCalculatorService.transpose(a),
          );
          break;

        case 'Determinant A':
          final det = MatrixCalculatorService.determinant(a);
          _result = det != null
              ? 'det(A) = ${det == det.roundToDouble() ? det.toInt() : det.toStringAsFixed(6)}'
              : 'Error: Must be square (max 10×10)';
          break;

        case 'Inverse A':
          final inv = MatrixCalculatorService.inverse(a);
          _result = inv != null
              ? MatrixCalculatorService.format(inv)
              : 'Error: Matrix is singular or not square';
          break;

        case 'Trace A':
          final tr = MatrixCalculatorService.trace(a);
          _result = tr != null
              ? 'tr(A) = ${tr == tr.roundToDouble() ? tr.toInt() : tr.toStringAsFixed(6)}'
              : 'Error: Must be square';
          break;

        case 'Row Echelon A':
          _result = MatrixCalculatorService.format(
            MatrixCalculatorService.rowEchelon(a),
          );
          break;
      }
    });
  }

  @override
  void dispose() {
    _matrixAController.dispose();
    _matrixBController.dispose();
    _scalarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Matrix Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Operation selector
          DropdownButtonFormField<String>(
            value: _operation,
            decoration: const InputDecoration(
              labelText: 'Operation',
              border: OutlineInputBorder(),
            ),
            items: _operations
                .map((op) => DropdownMenuItem(value: op, child: Text(op)))
                .toList(),
            onChanged: (v) => setState(() => _operation = v!),
          ),
          const SizedBox(height: 16),

          // Matrix A
          Text('Matrix A', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'Enter rows on separate lines, values separated by spaces or commas',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _matrixAController,
            maxLines: 5,
            style: const TextStyle(fontFamily: 'monospace'),
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: '1 2 3\n4 5 6\n7 8 9',
            ),
          ),
          const SizedBox(height: 16),

          // Matrix B (conditional)
          if (_needsB) ...[
            Text('Matrix B', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _matrixBController,
              maxLines: 5,
              style: const TextStyle(fontFamily: 'monospace'),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '1 0\n0 1',
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Scalar (conditional)
          if (_needsScalar) ...[
            TextField(
              controller: _scalarController,
              decoration: const InputDecoration(
                labelText: 'Scalar',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
          ],

          // Calculate button
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate'),
          ),
          const SizedBox(height: 24),

          // Result
          if (_result.isNotEmpty) ...[
            Text('Result', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _result.startsWith('Error')
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _result.startsWith('Error')
                      ? Colors.red.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: SelectableText(
                _result,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  color: _result.startsWith('Error')
                      ? Colors.red.shade900
                      : Colors.green.shade900,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
