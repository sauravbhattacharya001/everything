import 'package:flutter/material.dart';

/// Represents a color in the mixer with its weight.
class MixerColor {
  final Color color;
  final double weight;
  final String? name;

  const MixerColor({required this.color, this.weight = 1.0, this.name});

  MixerColor copyWith({Color? color, double? weight, String? name}) {
    return MixerColor(
      color: color ?? this.color,
      weight: weight ?? this.weight,
      name: name ?? this.name,
    );
  }
}

/// Color mixing modes.
enum MixMode {
  average('Average (Additive)', 'Blends RGB channels weighted by amount'),
  multiply('Multiply', 'Darkens by multiplying channels together'),
  screen('Screen', 'Lightens by inverting, multiplying, and inverting again');

  final String label;
  final String description;
  const MixMode(this.label, this.description);
}

/// Service for mixing colors using various blend modes.
class ColorMixerService {
  /// Mix a list of colors using the specified mode.
  Color mix(List<MixerColor> colors, MixMode mode) {
    if (colors.isEmpty) return Colors.black;
    if (colors.length == 1) return colors.first.color;

    switch (mode) {
      case MixMode.average:
        return _averageMix(colors);
      case MixMode.multiply:
        return _multiplyMix(colors);
      case MixMode.screen:
        return _screenMix(colors);
    }
  }

  Color _averageMix(List<MixerColor> colors) {
    double totalWeight = colors.fold(0, (sum, c) => sum + c.weight);
    if (totalWeight == 0) totalWeight = 1;

    double r = 0, g = 0, b = 0, a = 0;
    for (final c in colors) {
      final w = c.weight / totalWeight;
      r += c.color.red * w;
      g += c.color.green * w;
      b += c.color.blue * w;
      a += c.color.alpha * w;
    }
    return Color.fromARGB(a.round().clamp(0, 255), r.round().clamp(0, 255),
        g.round().clamp(0, 255), b.round().clamp(0, 255));
  }

  Color _multiplyMix(List<MixerColor> colors) {
    double r = 1, g = 1, b = 1;
    for (final c in colors) {
      r *= c.color.red / 255;
      g *= c.color.green / 255;
      b *= c.color.blue / 255;
    }
    return Color.fromARGB(255, (r * 255).round().clamp(0, 255),
        (g * 255).round().clamp(0, 255), (b * 255).round().clamp(0, 255));
  }

  Color _screenMix(List<MixerColor> colors) {
    double r = 0, g = 0, b = 0;
    // Screen: 1 - product(1 - c_i)
    double pr = 1, pg = 1, pb = 1;
    for (final c in colors) {
      pr *= (1 - c.color.red / 255);
      pg *= (1 - c.color.green / 255);
      pb *= (1 - c.color.blue / 255);
    }
    r = 1 - pr;
    g = 1 - pg;
    b = 1 - pb;
    return Color.fromARGB(255, (r * 255).round().clamp(0, 255),
        (g * 255).round().clamp(0, 255), (b * 255).round().clamp(0, 255));
  }

  /// Get hex string for a color.
  String toHex(Color color) {
    return '#${color.red.toRadixString(16).padLeft(2, '0')}'
        '${color.green.toRadixString(16).padLeft(2, '0')}'
        '${color.blue.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  /// Get RGB string for a color.
  String toRgb(Color color) {
    return 'rgb(${color.red}, ${color.green}, ${color.blue})';
  }

  /// Get HSL string for a color.
  String toHsl(Color color) {
    final hsl = HSLColor.fromColor(color);
    return 'hsl(${hsl.hue.round()}, ${(hsl.saturation * 100).round()}%, ${(hsl.lightness * 100).round()}%)';
  }

  /// Suggest a name for common colors.
  String suggestName(Color color) {
    final presets = <String, Color>{
      'Red': Colors.red,
      'Pink': Colors.pink,
      'Purple': Colors.purple,
      'Deep Purple': Colors.deepPurple,
      'Indigo': Colors.indigo,
      'Blue': Colors.blue,
      'Light Blue': Colors.lightBlue,
      'Cyan': Colors.cyan,
      'Teal': Colors.teal,
      'Green': Colors.green,
      'Light Green': Colors.lightGreen,
      'Lime': Colors.lime,
      'Yellow': Colors.yellow,
      'Amber': Colors.amber,
      'Orange': Colors.orange,
      'Deep Orange': Colors.deepOrange,
      'Brown': Colors.brown,
      'Grey': Colors.grey,
      'Blue Grey': Colors.blueGrey,
      'White': Colors.white,
      'Black': Colors.black,
    };

    String closest = 'Custom';
    double minDist = double.infinity;
    for (final entry in presets.entries) {
      final d = _colorDistance(color, entry.value);
      if (d < minDist) {
        minDist = d;
        closest = entry.key;
      }
    }
    return closest;
  }

  double _colorDistance(Color a, Color b) {
    final dr = (a.red - b.red).toDouble();
    final dg = (a.green - b.green).toDouble();
    final db = (a.blue - b.blue).toDouble();
    return dr * dr + dg * dg + db * db;
  }
}
