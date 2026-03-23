import 'package:flutter/material.dart';
import '../../core/services/qr_generator_service.dart';

/// QR Code Generator screen – type text or a URL and see a QR-style
/// pattern rendered in real-time.
class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _controller = TextEditingController();
  List<List<bool>>? _matrix;
  Color _foreground = Colors.black;
  Color _background = Colors.white;

  final _presetColors = [
    Colors.black,
    Colors.blue,
    Colors.deepPurple,
    Colors.teal,
    Colors.red,
    Colors.green,
    Colors.indigo,
    Colors.brown,
  ];

  void _generate() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _matrix = null);
      return;
    }
    setState(() {
      _matrix = QrGeneratorService.generate(text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('QR Code Generator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Text or URL',
                hintText: 'Enter text to encode…',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _controller.clear();
                    _generate();
                  },
                ),
              ),
              maxLines: 3,
              minLines: 1,
              onChanged: (_) => _generate(),
            ),
            const SizedBox(height: 12),

            // Color pickers
            Row(
              children: [
                const Text('Foreground: '),
                const SizedBox(width: 8),
                ..._presetColors.map((c) => GestureDetector(
                      onTap: () => setState(() => _foreground = c),
                      child: Container(
                        width: 28,
                        height: 28,
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _foreground == c
                                ? theme.colorScheme.primary
                                : Colors.grey.shade300,
                            width: _foreground == c ? 3 : 1,
                          ),
                        ),
                      ),
                    )),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Background: '),
                const SizedBox(width: 8),
                ...[Colors.white, Colors.yellow.shade100, Colors.lightBlue.shade50, Colors.grey.shade200]
                    .map((c) => GestureDetector(
                          onTap: () => setState(() => _background = c),
                          child: Container(
                            width: 28,
                            height: 28,
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _background == c
                                    ? theme.colorScheme.primary
                                    : Colors.grey.shade300,
                                width: _background == c ? 3 : 1,
                              ),
                            ),
                          ),
                        )),
              ],
            ),
            const SizedBox(height: 20),

            // QR display
            if (_matrix != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CustomPaint(
                    size: const Size(260, 260),
                    painter: _QrPainter(
                      matrix: _matrix!,
                      foreground: _foreground,
                      background: _background,
                    ),
                  ),
                ),
              )
            else if (_controller.text.trim().isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(Icons.warning_amber,
                          color: theme.colorScheme.error, size: 48),
                      const SizedBox(height: 8),
                      const Text(
                        'Text too long (max ~134 characters)',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.qr_code_2,
                          size: 64, color: theme.disabledColor),
                      const SizedBox(height: 12),
                      Text(
                        'Type something above to generate a QR pattern',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.disabledColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Info card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('About', style: theme.textTheme.titleSmall),
                    const SizedBox(height: 8),
                    const Text(
                      'This generates a QR-style visual pattern from your text. '
                      'The pattern includes standard QR finder patterns and timing '
                      'strips with your data encoded in the matrix. Great for '
                      'quick visual encoding of short text and URLs.',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QrPainter extends CustomPainter {
  final List<List<bool>> matrix;
  final Color foreground;
  final Color background;

  _QrPainter({
    required this.matrix,
    required this.foreground,
    required this.background,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rows = matrix.length;
    if (rows == 0) return;
    final cols = matrix[0].length;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    final cell = cellW < cellH ? cellW : cellH;

    final bgPaint = Paint()..color = background;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, cols * cell, rows * cell),
      bgPaint,
    );

    final fgPaint = Paint()..color = foreground;
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        if (matrix[r][c]) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(c * cell, r * cell, cell, cell),
              Radius.circular(cell * 0.15),
            ),
            fgPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter old) =>
      old.matrix != matrix ||
      old.foreground != foreground ||
      old.background != background;
}
