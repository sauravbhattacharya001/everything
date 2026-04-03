import 'dart:math';
import 'package:flutter/material.dart';

/// Shared sRGB ↔ linear RGB conversion utilities.
///
/// Used by color-related services (contrast, blindness simulation, mixing)
/// to avoid duplicating the W3C sRGB transfer function.
class SrgbUtils {
  SrgbUtils._();

  /// Linearize a single sRGB channel value (0–255) to [0.0, 1.0].
  ///
  /// Implements the IEC 61966-2-1 inverse transfer function used by
  /// WCAG 2.1 luminance calculations and color-space conversions.
  static double linearize(int channel) {
    final s = channel / 255.0;
    return s <= 0.04045 ? s / 12.92 : pow((s + 0.055) / 1.055, 2.4).toDouble();
  }

  /// Convert a linear-light value [0.0, 1.0] back to sRGB (0–255).
  static int delinearize(double v) {
    final clamped = v.clamp(0.0, 1.0);
    final s = clamped <= 0.0031308
        ? clamped * 12.92
        : 1.055 * pow(clamped, 1.0 / 2.4) - 0.055;
    return (s * 255).round().clamp(0, 255);
  }

  /// Convert a [Color] to linear RGB as [r, g, b] in [0.0, 1.0].
  static List<double> colorToLinear(Color c) {
    return [linearize(c.red), linearize(c.green), linearize(c.blue)];
  }

  /// Convert linear RGB [r, g, b] back to an opaque [Color].
  static Color linearToColor(List<double> rgb) {
    return Color.fromARGB(
      255,
      delinearize(rgb[0]),
      delinearize(rgb[1]),
      delinearize(rgb[2]),
    );
  }

  /// WCAG 2.1 relative luminance from sRGB channel values (0–255).
  static double relativeLuminance(int r, int g, int b) {
    return 0.2126 * linearize(r) + 0.7152 * linearize(g) + 0.0722 * linearize(b);
  }
}
