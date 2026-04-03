import 'dart:math';

import '../utils/srgb_utils.dart';

/// WCAG contrast ratio result with pass/fail for AA and AAA levels.
class ContrastResult {
  final double ratio;
  final bool passesAA;
  final bool passesAALarge;
  final bool passesAAA;
  final bool passesAAALarge;

  ContrastResult({
    required this.ratio,
    required this.passesAA,
    required this.passesAALarge,
    required this.passesAAA,
    required this.passesAAALarge,
  });
}

/// Service for checking WCAG 2.1 color contrast ratios.
class ColorContrastService {
  /// Calculate the relative luminance of an sRGB color.
  /// Per WCAG 2.1 definition.
  double relativeLuminance(int r, int g, int b) =>
      SrgbUtils.relativeLuminance(r, g, b);

  /// Calculate contrast ratio between two colors (each as r,g,b 0-255).
  double contrastRatio(int r1, int g1, int b1, int r2, int g2, int b2) {
    final l1 = relativeLuminance(r1, g1, b1);
    final l2 = relativeLuminance(r2, g2, b2);
    final lighter = max(l1, l2);
    final darker = min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Check contrast and return WCAG pass/fail results.
  ContrastResult check(int r1, int g1, int b1, int r2, int g2, int b2) {
    final ratio = contrastRatio(r1, g1, b1, r2, g2, b2);
    return ContrastResult(
      ratio: ratio,
      passesAA: ratio >= 4.5,
      passesAALarge: ratio >= 3.0,
      passesAAA: ratio >= 7.0,
      passesAAALarge: ratio >= 4.5,
    );
  }

  /// Parse a hex color string (#RRGGBB or RRGGBB) to (r, g, b).
  /// Returns null if invalid.
  List<int>? parseHex(String hex) {
    hex = hex.trim().replaceFirst('#', '');
    if (hex.length == 3) {
      hex = hex[0] * 2 + hex[1] * 2 + hex[2] * 2;
    }
    if (hex.length != 6) return null;
    final value = int.tryParse(hex, radix: 16);
    if (value == null) return null;
    return [(value >> 16) & 0xFF, (value >> 8) & 0xFF, value & 0xFF];
  }

  /// Suggest a lighter or darker variant of the foreground that passes AA.
  /// Returns the adjusted (r,g,b) or null if not possible.
  List<int>? suggestAccessibleColor(
      int fgR, int fgG, int fgB, int bgR, int bgG, int bgB) {
    final bgLum = relativeLuminance(bgR, bgG, bgB);

    // Try darkening or lightening the foreground
    for (double factor = 0.0; factor <= 1.0; factor += 0.01) {
      // Try darker
      final dr = (fgR * factor).round().clamp(0, 255);
      final dg = (fgG * factor).round().clamp(0, 255);
      final db = (fgB * factor).round().clamp(0, 255);
      final darkRatio = contrastRatio(dr, dg, db, bgR, bgG, bgB);
      if (darkRatio >= 4.5) return [dr, dg, db];
    }

    for (double factor = 0.0; factor <= 1.0; factor += 0.01) {
      // Try lighter
      final lr = (fgR + (255 - fgR) * factor).round().clamp(0, 255);
      final lg = (fgG + (255 - fgG) * factor).round().clamp(0, 255);
      final lb = (fgB + (255 - fgB) * factor).round().clamp(0, 255);
      final lightRatio = contrastRatio(lr, lg, lb, bgR, bgG, bgB);
      if (lightRatio >= 4.5) return [lr, lg, lb];
    }

    return null;
  }
}
