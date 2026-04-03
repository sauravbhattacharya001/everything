import 'package:flutter/material.dart';

import '../utils/srgb_utils.dart';

/// Types of color vision deficiency.
enum ColorBlindnessType {
  protanopia('Protanopia', 'Red-blind (~1% of males)'),
  deuteranopia('Deuteranopia', 'Green-blind (~1% of males)'),
  tritanopia('Tritanopia', 'Blue-blind (~0.003%)'),
  protanomaly('Protanomaly', 'Red-weak (~1% of males)'),
  deuteranomaly('Deuteranomaly', 'Green-weak (~5% of males)'),
  tritanomaly('Tritanomaly', 'Blue-weak (~0.01%)'),
  achromatopsia('Achromatopsia', 'Total color blindness (~0.003%)');

  final String label;
  final String description;
  const ColorBlindnessType(this.label, this.description);
}

/// Simulates how colors appear to people with color vision deficiency.
class ColorBlindnessService {
  /// Convert sRGB to linear RGB.
  static List<double> _srgbToLinear(Color c) => SrgbUtils.colorToLinear(c);

  /// Convert linear RGB back to sRGB.
  static Color _linearToSrgb(List<double> rgb) => SrgbUtils.linearToColor(rgb);

  /// Apply a 3x3 matrix transformation to a linear RGB vector.
  static List<double> _applyMatrix(List<List<double>> m, List<double> v) {
    return [
      m[0][0] * v[0] + m[0][1] * v[1] + m[0][2] * v[2],
      m[1][0] * v[0] + m[1][1] * v[1] + m[1][2] * v[2],
      m[2][0] * v[0] + m[2][1] * v[1] + m[2][2] * v[2],
    ];
  }

  /// Blend between original and simulated for anomalous types (severity ~0.6).
  static List<double> _blend(List<double> orig, List<double> sim, double t) {
    return [
      orig[0] * (1 - t) + sim[0] * t,
      orig[1] * (1 - t) + sim[1] * t,
      orig[2] * (1 - t) + sim[2] * t,
    ];
  }

  // Simulation matrices (Brettel/Viénot model approximations in linear sRGB)
  static const _protanopia = [
    [0.152286, 1.052583, -0.204868],
    [0.114503, 0.786281, 0.099216],
    [-0.003882, -0.048116, 1.051998],
  ];

  static const _deuteranopia = [
    [0.367322, 0.860646, -0.227968],
    [0.280085, 0.672501, 0.047413],
    [-0.011820, 0.042940, 0.968881],
  ];

  static const _tritanopia = [
    [1.255528, -0.076749, -0.178779],
    [-0.078411, 0.930809, 0.147602],
    [0.004733, 0.691367, 0.303900],
  ];

  static const _achromatopsia = [
    [0.2126, 0.7152, 0.0722],
    [0.2126, 0.7152, 0.0722],
    [0.2126, 0.7152, 0.0722],
  ];

  /// Simulate a color as seen by someone with the given deficiency.
  static Color simulate(Color color, ColorBlindnessType type) {
    final linear = _srgbToLinear(color);

    switch (type) {
      case ColorBlindnessType.protanopia:
        return _linearToSrgb(_applyMatrix(_protanopia, linear));
      case ColorBlindnessType.deuteranopia:
        return _linearToSrgb(_applyMatrix(_deuteranopia, linear));
      case ColorBlindnessType.tritanopia:
        return _linearToSrgb(_applyMatrix(_tritanopia, linear));
      case ColorBlindnessType.protanomaly:
        return _linearToSrgb(_blend(linear, _applyMatrix(_protanopia, linear), 0.6));
      case ColorBlindnessType.deuteranomaly:
        return _linearToSrgb(_blend(linear, _applyMatrix(_deuteranopia, linear), 0.6));
      case ColorBlindnessType.tritanomaly:
        return _linearToSrgb(_blend(linear, _applyMatrix(_tritanopia, linear), 0.6));
      case ColorBlindnessType.achromatopsia:
        return _linearToSrgb(_applyMatrix(_achromatopsia, linear));
    }
  }

  /// Generate a palette of test colors.
  static List<Color> get testPalette => const [
    Color(0xFFFF0000), // Red
    Color(0xFF00FF00), // Green
    Color(0xFF0000FF), // Blue
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFF8000), // Orange
    Color(0xFF800080), // Purple
    Color(0xFF00FFFF), // Cyan
    Color(0xFFFF69B4), // Hot Pink
    Color(0xFF8B4513), // Saddle Brown
    Color(0xFF228B22), // Forest Green
    Color(0xFFDC143C), // Crimson
    Color(0xFF4169E1), // Royal Blue
  ];

  /// Parse a hex color string like "#FF0000" or "FF0000".
  static Color? parseHex(String hex) {
    hex = hex.replaceAll('#', '').trim();
    if (hex.length == 6) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) return Color(0xFF000000 | value);
    }
    if (hex.length == 8) {
      final value = int.tryParse(hex, radix: 16);
      if (value != null) return Color(value);
    }
    return null;
  }

  /// Format color as hex string.
  static String toHex(Color c) =>
      '#${c.red.toRadixString(16).padLeft(2, '0')}'
      '${c.green.toRadixString(16).padLeft(2, '0')}'
      '${c.blue.toRadixString(16).padLeft(2, '0')}'.toUpperCase();
}
