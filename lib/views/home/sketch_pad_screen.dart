import 'package:flutter/material.dart';
import '../../core/services/sketch_pad_service.dart';

/// A freehand sketch pad with color picker, brush size, undo/redo, and eraser.
class SketchPadScreen extends StatefulWidget {
  const SketchPadScreen({super.key});

  @override
  State<SketchPadScreen> createState() => _SketchPadScreenState();
}

class _SketchPadScreenState extends State<SketchPadScreen> {
  final _service = SketchPadService();
  Color _currentColor = Colors.black;
  double _brushSize = 3.0;
  bool _erasing = false;

  static const List<Color> _palette = [
    Colors.black,
    Colors.white,
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.pink,
    Colors.brown,
    Colors.grey,
  ];

  void _onPanStart(DragStartDetails details) {
    final color = _erasing ? Colors.white : _currentColor;
    final width = _erasing ? _brushSize * 3 : _brushSize;
    setState(() {
      _service.startStroke(details.localPosition, color, width);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _service.addPoint(details.localPosition);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sketch Pad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: _service.canUndo
                ? () => setState(() => _service.undo())
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            tooltip: 'Redo',
            onPressed: _service.canRedo
                ? () => setState(() => _service.redo())
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Clear canvas',
            onPressed: _service.strokes.isNotEmpty
                ? () => setState(() => _service.clear())
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          // Canvas
          Expanded(
            child: Container(
              color: Colors.white,
              child: GestureDetector(
                onPanStart: _onPanStart,
                onPanUpdate: _onPanUpdate,
                child: CustomPaint(
                  painter: _SketchPainter(strokes: _service.strokes),
                  size: Size.infinite,
                ),
              ),
            ),
          ),

          // Toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Tool toggle + brush size
                Row(
                  children: [
                    // Pencil / Eraser toggle
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          icon: Icon(Icons.edit, size: 18),
                          label: Text('Draw'),
                        ),
                        ButtonSegment(
                          value: true,
                          icon: Icon(Icons.auto_fix_high, size: 18),
                          label: Text('Erase'),
                        ),
                      ],
                      selected: {_erasing},
                      onSelectionChanged: (v) =>
                          setState(() => _erasing = v.first),
                    ),
                    const SizedBox(width: 12),

                    // Brush size
                    const Icon(Icons.brush, size: 18),
                    Expanded(
                      child: Slider(
                        value: _brushSize,
                        min: 1,
                        max: 20,
                        divisions: 19,
                        label: _brushSize.round().toString(),
                        onChanged: (v) => setState(() => _brushSize = v),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Color palette
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _palette.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 6),
                    itemBuilder: (context, index) {
                      final color = _palette[index];
                      final selected = !_erasing && _currentColor == color;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _currentColor = color;
                          _erasing = false;
                        }),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : Colors.grey.shade400,
                              width: selected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints all strokes on the canvas.
class _SketchPainter extends CustomPainter {
  final List<SketchStroke> strokes;

  _SketchPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    // White background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        // Single dot
        canvas.drawCircle(
          stroke.points.first,
          stroke.width / 2,
          Paint()
            ..color = stroke.color
            ..style = PaintingStyle.fill,
        );
      } else {
        final path = Path();
        path.moveTo(stroke.points.first.dx, stroke.points.first.dy);
        for (int i = 1; i < stroke.points.length; i++) {
          path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
        }
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SketchPainter oldDelegate) => true;
}
