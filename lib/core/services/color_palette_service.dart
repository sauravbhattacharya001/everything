import 'dart:math';
import 'package:flutter/material.dart';

/// A named color palette with its harmony type.
class ColorPalette {
  final String name;
  final HarmonyType harmony;
  final List<Color> colors;
  final DateTime created;
  final bool isFavorite;

  const ColorPalette({
    required this.name,
    required this.harmony,
    required this.colors,
    required this.created,
    this.isFavorite = false,
  });

  ColorPalette copyWith({bool? isFavorite}) => ColorPalette(
        name: name,
        harmony: harmony,
        colors: colors,
        created: created,
        isFavorite: isFavorite ?? this.isFavorite,
      );
}

/// Supported color harmony types.
enum HarmonyType {
  complementary('Complementary', 'Opposite colors on the wheel'),
  analogous('Analogous', 'Adjacent colors for smooth blends'),
  triadic('Triadic', 'Three evenly spaced colors'),
  splitComplementary('Split Comp.', 'Base + two adjacent to complement'),
  tetradic('Tetradic', 'Four colors in two complementary pairs'),
  monochromatic('Monochromatic', 'Shades & tints of one hue'),
  random('Random', 'Fully randomized palette');

  final String label;
  final String description;
  const HarmonyType(this.label, this.description);
}

/// Generates harmonious color palettes from a base hue.
class ColorPaletteService {
  static final _rng = Random();

  /// Generate a palette of [count] colors using the given [harmony]
  /// starting from [baseHue] (0–360).
  static List<Color> generate({
    required double baseHue,
    required HarmonyType harmony,
    int count = 5,
  }) {
    switch (harmony) {
      case HarmonyType.complementary:
        return _complementary(baseHue, count);
      case HarmonyType.analogous:
        return _analogous(baseHue, count);
      case HarmonyType.triadic:
        return _triadic(baseHue, count);
      case HarmonyType.splitComplementary:
        return _splitComplementary(baseHue, count);
      case HarmonyType.tetradic:
        return _tetradic(baseHue, count);
      case HarmonyType.monochromatic:
        return _monochromatic(baseHue, count);
      case HarmonyType.random:
        return _random(count);
    }
  }

  static String colorToHex(Color c) =>
      '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';

  static String colorToRgb(Color c) =>
      'rgb(${c.red}, ${c.green}, ${c.blue})';

  static String colorToHsl(Color c) {
    final hsl = HSLColor.fromColor(c);
    return 'hsl(${hsl.hue.round()}, ${(hsl.saturation * 100).round()}%, ${(hsl.lightness * 100).round()}%)';
  }

  static double randomHue() => _rng.nextDouble() * 360;

  // ── Harmony algorithms ──

  static List<Color> _complementary(double hue, int count) {
    final hues = <double>[hue, (hue + 180) % 360];
    return _expandFromHues(hues, count);
  }

  static List<Color> _analogous(double hue, int count) {
    final step = 30.0;
    final hues = List.generate(
        count, (i) => (hue + step * (i - count ~/ 2)) % 360);
    return hues
        .map((h) => HSLColor.fromAHSL(1, h < 0 ? h + 360 : h, 0.65, 0.55).toColor())
        .toList();
  }

  static List<Color> _triadic(double hue, int count) {
    final hues = [hue, (hue + 120) % 360, (hue + 240) % 360];
    return _expandFromHues(hues, count);
  }

  static List<Color> _splitComplementary(double hue, int count) {
    final hues = [hue, (hue + 150) % 360, (hue + 210) % 360];
    return _expandFromHues(hues, count);
  }

  static List<Color> _tetradic(double hue, int count) {
    final hues = [
      hue,
      (hue + 90) % 360,
      (hue + 180) % 360,
      (hue + 270) % 360,
    ];
    return _expandFromHues(hues, count);
  }

  static List<Color> _monochromatic(double hue, int count) {
    return List.generate(count, (i) {
      final lightness = 0.25 + (0.5 * i / (count - 1).clamp(1, count));
      return HSLColor.fromAHSL(1, hue, 0.6, lightness).toColor();
    });
  }

  static List<Color> _random(int count) {
    return List.generate(count, (_) {
      return HSLColor.fromAHSL(
        1,
        _rng.nextDouble() * 360,
        0.4 + _rng.nextDouble() * 0.4,
        0.35 + _rng.nextDouble() * 0.35,
      ).toColor();
    });
  }

  /// Expand a short list of key hues into [count] colors by varying
  /// saturation/lightness.
  static List<Color> _expandFromHues(List<double> hues, int count) {
    final colors = <Color>[];
    for (var i = 0; i < count; i++) {
      final h = hues[i % hues.length];
      final sat = 0.5 + 0.15 * (i % 3);
      final light = 0.4 + 0.1 * (i % 4);
      colors.add(HSLColor.fromAHSL(1, h, sat, light).toColor());
    }
    return colors;
  }
}
