import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Represents a single pixel art canvas with undo/redo support.
class PixelArtCanvas {
  final int width;
  final int height;
  late List<List<Color>> _pixels;
  final List<List<List<Color>>> _undoStack = [];
  final List<List<List<Color>>> _redoStack = [];

  PixelArtCanvas({this.width = 16, this.height = 16}) {
    _pixels = List.generate(
      height,
      (_) => List.generate(width, (_) => Colors.transparent),
    );
  }

  Color getPixel(int x, int y) => _pixels[y][x];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void _saveState() {
    _undoStack.add(_pixels.map((row) => List<Color>.from(row)).toList());
    _redoStack.clear();
    // Limit undo history
    if (_undoStack.length > 50) _undoStack.removeAt(0);
  }

  void setPixel(int x, int y, Color color) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    if (_pixels[y][x] == color) return;
    _saveState();
    _pixels[y][x] = color;
  }

  /// Fill a contiguous region of the same color (flood fill).
  void fill(int x, int y, Color fillColor) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    final targetColor = _pixels[y][x];
    if (targetColor == fillColor) return;
    _saveState();
    _floodFill(x, y, targetColor, fillColor);
  }

  void _floodFill(int x, int y, Color target, Color replacement) {
    if (x < 0 || x >= width || y < 0 || y >= height) return;
    if (_pixels[y][x] != target) return;
    _pixels[y][x] = replacement;
    _floodFill(x + 1, y, target, replacement);
    _floodFill(x - 1, y, target, replacement);
    _floodFill(x, y + 1, target, replacement);
    _floodFill(x, y - 1, target, replacement);
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_pixels.map((row) => List<Color>.from(row)).toList());
    _pixels = _undoStack.removeLast();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_pixels.map((row) => List<Color>.from(row)).toList());
    _pixels = _redoStack.removeLast();
  }

  void clear() {
    _saveState();
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        _pixels[y][x] = Colors.transparent;
      }
    }
  }

  /// Generate PNG bytes of the pixel art.
  Future<Uint8List?> toPngBytes({int scale = 16}) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final color = _pixels[y][x];
        if (color != Colors.transparent) {
          paint.color = color;
          canvas.drawRect(
            Rect.fromLTWH(
              x * scale.toDouble(),
              y * scale.toDouble(),
              scale.toDouble(),
              scale.toDouble(),
            ),
            paint,
          );
        }
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width * scale, height * scale);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}

/// Available drawing tools.
enum PixelTool {
  pencil('Pencil', Icons.edit),
  eraser('Eraser', Icons.auto_fix_normal),
  fill('Fill', Icons.format_color_fill);

  final String label;
  final IconData icon;
  const PixelTool(this.label, this.icon);
}

/// Available canvas sizes.
enum CanvasSize {
  small(8, '8×8'),
  medium(16, '16×16'),
  large(32, '32×32');

  final int size;
  final String label;
  const CanvasSize(this.size, this.label);
}
