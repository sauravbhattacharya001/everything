import 'dart:math';
import 'package:flutter/material.dart';

/// Types of gradients the generator can produce.
enum GradientType {
  linear,
  radial,
  sweep;

  String get label {
    switch (this) {
      case GradientType.linear:
        return 'Linear';
      case GradientType.radial:
        return 'Radial';
      case GradientType.sweep:
        return 'Sweep';
    }
  }

  IconData get icon {
    switch (this) {
      case GradientType.linear:
        return Icons.gradient;
      case GradientType.radial:
        return Icons.radio_button_unchecked;
      case GradientType.sweep:
        return Icons.rotate_right;
    }
  }
}

/// A single color stop in a gradient.
class ColorStop {
  Color color;
  double position; // 0.0 to 1.0

  ColorStop({required this.color, required this.position});

  ColorStop copyWith({Color? color, double? position}) =>
      ColorStop(color: color ?? this.color, position: position ?? this.position);

  String get hexString =>
      '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  /// CSS rgba() representation.
  String get cssRgba =>
      'rgba(${color.red}, ${color.green}, ${color.blue}, ${(color.opacity).toStringAsFixed(2)})';
}

/// Preset gradient definitions.
class GradientPreset {
  final String name;
  final List<ColorStop> stops;
  final double angleDeg;

  const GradientPreset._({
    required this.name,
    required this.stops,
    this.angleDeg = 90,
  });

  static final List<GradientPreset> all = [
    GradientPreset._(
      name: 'Sunset',
      stops: [
        ColorStop(color: const Color(0xFFFF512F), position: 0.0),
        ColorStop(color: const Color(0xFFDD2476), position: 1.0),
      ],
    ),
    GradientPreset._(
      name: 'Ocean',
      stops: [
        ColorStop(color: const Color(0xFF2193B0), position: 0.0),
        ColorStop(color: const Color(0xFF6DD5ED), position: 1.0),
      ],
    ),
    GradientPreset._(
      name: 'Forest',
      stops: [
        ColorStop(color: const Color(0xFF134E5E), position: 0.0),
        ColorStop(color: const Color(0xFF71B280), position: 1.0),
      ],
    ),
    GradientPreset._(
      name: 'Candy',
      stops: [
        ColorStop(color: const Color(0xFFD585FF), position: 0.0),
        ColorStop(color: const Color(0xFFFFC6E9), position: 0.5),
        ColorStop(color: const Color(0xFFFF9DE2), position: 1.0),
      ],
    ),
    GradientPreset._(
      name: 'Fire',
      stops: [
        ColorStop(color: const Color(0xFFFF0000), position: 0.0),
        ColorStop(color: const Color(0xFFFF7300), position: 0.5),
        ColorStop(color: const Color(0xFFFFEB00), position: 1.0),
      ],
    ),
    GradientPreset._(
      name: 'Midnight',
      stops: [
        ColorStop(color: const Color(0xFF0F2027), position: 0.0),
        ColorStop(color: const Color(0xFF203A43), position: 0.5),
        ColorStop(color: const Color(0xFF2C5364), position: 1.0),
      ],
    ),
    GradientPreset._(
      name: 'Aurora',
      stops: [
        ColorStop(color: const Color(0xFF00C9FF), position: 0.0),
        ColorStop(color: const Color(0xFF92FE9D), position: 1.0),
      ],
    ),
    GradientPreset._(
      name: 'Peach',
      stops: [
        ColorStop(color: const Color(0xFFFFE259), position: 0.0),
        ColorStop(color: const Color(0xFFFFA751), position: 1.0),
      ],
    ),
  ];
}

/// Service for generating gradient objects and export strings.
class GradientGeneratorService {
  /// Build a Flutter [Gradient] from stops, type, and angle.
  static Gradient buildGradient({
    required List<ColorStop> stops,
    required GradientType type,
    double angleDeg = 90,
  }) {
    final sorted = List<ColorStop>.from(stops)
      ..sort((a, b) => a.position.compareTo(b.position));
    final colors = sorted.map((s) => s.color).toList();
    final positions = sorted.map((s) => s.position).toList();

    switch (type) {
      case GradientType.linear:
        return LinearGradient(
          colors: colors,
          stops: positions,
          begin: _angleToAlignment(angleDeg),
          end: _angleToAlignment(angleDeg + 180),
        );
      case GradientType.radial:
        return RadialGradient(colors: colors, stops: positions);
      case GradientType.sweep:
        return SweepGradient(colors: colors, stops: positions);
    }
  }

  /// Generate CSS gradient string.
  static String toCss({
    required List<ColorStop> stops,
    required GradientType type,
    double angleDeg = 90,
  }) {
    final sorted = List<ColorStop>.from(stops)
      ..sort((a, b) => a.position.compareTo(b.position));
    final stopsStr = sorted
        .map((s) => '${s.cssRgba} ${(s.position * 100).toStringAsFixed(0)}%')
        .join(', ');

    switch (type) {
      case GradientType.linear:
        return 'linear-gradient(${angleDeg.toStringAsFixed(0)}deg, $stopsStr)';
      case GradientType.radial:
        return 'radial-gradient(circle, $stopsStr)';
      case GradientType.sweep:
        return 'conic-gradient($stopsStr)';
    }
  }

  /// Generate Flutter code string.
  static String toFlutter({
    required List<ColorStop> stops,
    required GradientType type,
    double angleDeg = 90,
  }) {
    final sorted = List<ColorStop>.from(stops)
      ..sort((a, b) => a.position.compareTo(b.position));
    final colorsStr = sorted.map((s) {
      final hex = s.color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
      return 'Color(0x$hex)';
    }).join(', ');
    final stopsStr =
        sorted.map((s) => s.position.toStringAsFixed(2)).join(', ');

    switch (type) {
      case GradientType.linear:
        return 'LinearGradient(\n'
            '  colors: [$colorsStr],\n'
            '  stops: [$stopsStr],\n'
            '  begin: ${_alignmentString(_angleToAlignment(angleDeg))},\n'
            '  end: ${_alignmentString(_angleToAlignment(angleDeg + 180))},\n'
            ')';
      case GradientType.radial:
        return 'RadialGradient(\n'
            '  colors: [$colorsStr],\n'
            '  stops: [$stopsStr],\n'
            ')';
      case GradientType.sweep:
        return 'SweepGradient(\n'
            '  colors: [$colorsStr],\n'
            '  stops: [$stopsStr],\n'
            ')';
    }
  }

  /// Generate a random gradient.
  static List<ColorStop> randomStops({int count = 2}) {
    final rng = Random();
    final colors = List.generate(count, (_) {
      return Color.fromARGB(
          255, rng.nextInt(256), rng.nextInt(256), rng.nextInt(256));
    });
    return List.generate(count, (i) {
      return ColorStop(
        color: colors[i],
        position: count == 1 ? 0.5 : i / (count - 1),
      );
    });
  }

  static Alignment _angleToAlignment(double deg) {
    final rad = deg * pi / 180;
    return Alignment(cos(rad), sin(rad));
  }

  static String _alignmentString(Alignment a) {
    final x = a.x.toStringAsFixed(2);
    final y = a.y.toStringAsFixed(2);
    // Check for common alignments
    if (a.x.abs() < 0.01 && a.y < -0.99) return 'Alignment.topCenter';
    if (a.x.abs() < 0.01 && a.y > 0.99) return 'Alignment.bottomCenter';
    if (a.x < -0.99 && a.y.abs() < 0.01) return 'Alignment.centerLeft';
    if (a.x > 0.99 && a.y.abs() < 0.01) return 'Alignment.centerRight';
    return 'Alignment($x, $y)';
  }
}
