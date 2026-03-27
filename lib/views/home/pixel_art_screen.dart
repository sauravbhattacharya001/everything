import 'package:flutter/material.dart';
import '../../core/services/pixel_art_service.dart';

/// A pixel art editor with grid canvas, color picker, pencil/eraser/fill
/// tools, undo/redo, and canvas size options.
class PixelArtScreen extends StatefulWidget {
  const PixelArtScreen({super.key});

  @override
  State<PixelArtScreen> createState() => _PixelArtScreenState();
}

class _PixelArtScreenState extends State<PixelArtScreen> {
  late PixelArtCanvas _canvas;
  CanvasSize _canvasSize = CanvasSize.medium;
  PixelTool _tool = PixelTool.pencil;
  Color _selectedColor = Colors.black;
  bool _showGrid = true;

  static const List<Color> _palette = [
    Colors.black,
    Colors.white,
    Color(0xFF808080),
    Color(0xFFC0C0C0),
    Colors.red,
    Color(0xFFFF6600),
    Colors.orange,
    Colors.yellow,
    Color(0xFF80FF00),
    Colors.green,
    Color(0xFF00FF80),
    Colors.cyan,
    Color(0xFF0080FF),
    Colors.blue,
    Color(0xFF8000FF),
    Colors.purple,
    Color(0xFFFF0080),
    Colors.pink,
    Color(0xFF8B4513),
    Color(0xFFDEB887),
  ];

  @override
  void initState() {
    super.initState();
    _canvas = PixelArtCanvas(
      width: _canvasSize.size,
      height: _canvasSize.size,
    );
  }

  void _changeCanvasSize(CanvasSize size) {
    setState(() {
      _canvasSize = size;
      _canvas = PixelArtCanvas(width: size.size, height: size.size);
    });
  }

  void _handlePixelTap(int x, int y) {
    setState(() {
      switch (_tool) {
        case PixelTool.pencil:
          _canvas.setPixel(x, y, _selectedColor);
          break;
        case PixelTool.eraser:
          _canvas.setPixel(x, y, Colors.transparent);
          break;
        case PixelTool.fill:
          _canvas.fill(x, y, _selectedColor);
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pixel Art'),
        actions: [
          IconButton(
            icon: Icon(_showGrid ? Icons.grid_on : Icons.grid_off),
            tooltip: _showGrid ? 'Hide grid' : 'Show grid',
            onPressed: () => setState(() => _showGrid = !_showGrid),
          ),
          PopupMenuButton<CanvasSize>(
            icon: const Icon(Icons.aspect_ratio),
            tooltip: 'Canvas size',
            onSelected: _changeCanvasSize,
            itemBuilder: (_) => CanvasSize.values
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Text(s.label),
                    ))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear canvas',
            onPressed: () => setState(() => _canvas.clear()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tool bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Undo / Redo
                IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: 'Undo',
                  onPressed: _canvas.canUndo
                      ? () => setState(() => _canvas.undo())
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.redo),
                  tooltip: 'Redo',
                  onPressed: _canvas.canRedo
                      ? () => setState(() => _canvas.redo())
                      : null,
                ),
                const SizedBox(width: 8),
                // Tool selector
                ...PixelTool.values.map((t) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: ChoiceChip(
                        label: Icon(t.icon, size: 18),
                        selected: _tool == t,
                        onSelected: (_) => setState(() => _tool = t),
                        tooltip: t.label,
                        padding: EdgeInsets.zero,
                        labelPadding:
                            const EdgeInsets.symmetric(horizontal: 6),
                      ),
                    )),
                const Spacer(),
                // Current color preview
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _selectedColor,
                    border: Border.all(color: Colors.grey.shade400),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ],
            ),
          ),

          // Canvas
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellSize =
                        constraints.maxWidth / _canvas.width;
                    return GestureDetector(
                      onPanDown: (details) {
                        final x =
                            (details.localPosition.dx / cellSize).floor();
                        final y =
                            (details.localPosition.dy / cellSize).floor();
                        _handlePixelTap(x, y);
                      },
                      onPanUpdate: (details) {
                        if (_tool == PixelTool.fill) return;
                        final x =
                            (details.localPosition.dx / cellSize).floor();
                        final y =
                            (details.localPosition.dy / cellSize).floor();
                        _handlePixelTap(x, y);
                      },
                      child: CustomPaint(
                        size: Size(constraints.maxWidth,
                            constraints.maxWidth),
                        painter: _PixelGridPainter(
                          canvas: _canvas,
                          showGrid: _showGrid,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Color palette
          Container(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _palette.map((color) {
                final isSelected = color == _selectedColor;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.grey.shade300,
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the pixel grid on a [CustomPaint] widget.
class _PixelGridPainter extends CustomPainter {
  final PixelArtCanvas canvas;
  final bool showGrid;

  _PixelGridPainter({required this.canvas, required this.showGrid});

  @override
  void paint(Canvas c, Size size) {
    final cellW = size.width / canvas.width;
    final cellH = size.height / canvas.height;
    final paint = Paint()..style = PaintingStyle.fill;

    // Checkerboard background for transparency
    final lightGrey = Paint()..color = const Color(0xFFEEEEEE);
    final darkGrey = Paint()..color = const Color(0xFFCCCCCC);

    for (int y = 0; y < canvas.height; y++) {
      for (int x = 0; x < canvas.width; x++) {
        final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH);

        // Checkerboard
        c.drawRect(rect, (x + y) % 2 == 0 ? lightGrey : darkGrey);

        // Pixel color
        final color = canvas.getPixel(x, y);
        if (color != Colors.transparent) {
          paint.color = color;
          c.drawRect(rect, paint);
        }
      }
    }

    // Grid lines
    if (showGrid) {
      final gridPaint = Paint()
        ..color = Colors.grey.withAlpha(60)
        ..strokeWidth = 0.5;

      for (int x = 0; x <= canvas.width; x++) {
        c.drawLine(
          Offset(x * cellW, 0),
          Offset(x * cellW, size.height),
          gridPaint,
        );
      }
      for (int y = 0; y <= canvas.height; y++) {
        c.drawLine(
          Offset(0, y * cellH),
          Offset(size.width, y * cellH),
          gridPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PixelGridPainter oldDelegate) => true;
}
