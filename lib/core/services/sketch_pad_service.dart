import 'package:flutter/material.dart';

/// A single stroke on the sketch canvas.
class SketchStroke {
  final List<Offset> points;
  final Color color;
  final double width;

  SketchStroke({
    required this.points,
    required this.color,
    required this.width,
  });
}

/// Service that manages sketch pad state with undo/redo support.
class SketchPadService {
  final List<SketchStroke> _strokes = [];
  final List<SketchStroke> _redoStack = [];

  List<SketchStroke> get strokes => List.unmodifiable(_strokes);

  bool get canUndo => _strokes.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  /// Start a new stroke.
  void startStroke(Offset point, Color color, double width) {
    _redoStack.clear();
    _strokes.add(SketchStroke(
      points: [point],
      color: color,
      width: width,
    ));
  }

  /// Add a point to the current stroke.
  void addPoint(Offset point) {
    if (_strokes.isNotEmpty) {
      _strokes.last.points.add(point);
    }
  }

  /// Undo the last stroke.
  void undo() {
    if (_strokes.isNotEmpty) {
      _redoStack.add(_strokes.removeLast());
    }
  }

  /// Redo the last undone stroke.
  void redo() {
    if (_redoStack.isNotEmpty) {
      _strokes.add(_redoStack.removeLast());
    }
  }

  /// Clear all strokes.
  void clear() {
    _strokes.clear();
    _redoStack.clear();
  }
}
