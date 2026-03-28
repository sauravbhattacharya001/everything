/// Service for aspect ratio calculations, conversions, and common presets.
class AspectRatioService {
  AspectRatioService._();

  /// Common aspect ratios with names and use cases.
  static const List<AspectRatioPreset> presets = [
    AspectRatioPreset('1:1', 1, 1, 'Square — Instagram, profile pics'),
    AspectRatioPreset('4:3', 4, 3, 'Classic — TV, iPad, presentations'),
    AspectRatioPreset('3:2', 3, 2, 'Photography — DSLR, 35mm film'),
    AspectRatioPreset('16:9', 16, 9, 'Widescreen — YouTube, monitors'),
    AspectRatioPreset('16:10', 16, 10, 'Laptop — MacBook, ultrawide'),
    AspectRatioPreset('21:9', 21, 9, 'Ultrawide — cinema, gaming'),
    AspectRatioPreset('9:16', 9, 16, 'Vertical — Stories, Reels, TikTok'),
    AspectRatioPreset('2:3', 2, 3, 'Portrait — posters, book covers'),
    AspectRatioPreset('5:4', 5, 4, 'Medium format — 8x10 prints'),
    AspectRatioPreset('3:1', 3, 1, 'Panoramic — banners, headers'),
    AspectRatioPreset('2.39:1', 2.39, 1, 'Anamorphic — widescreen cinema'),
    AspectRatioPreset('1.85:1', 1.85, 1, 'Academy flat — US cinema'),
  ];

  /// Calculate GCD using Euclidean algorithm.
  static int gcd(int a, int b) {
    a = a.abs();
    b = b.abs();
    while (b != 0) {
      final t = b;
      b = a % t;
      a = t;
    }
    return a;
  }

  /// Simplify a ratio to its lowest terms.
  static (int, int) simplify(int width, int height) {
    if (width <= 0 || height <= 0) return (0, 0);
    final g = gcd(width, height);
    return (width ~/ g, height ~/ g);
  }

  /// Given width and aspect ratio, calculate height.
  static double calculateHeight(double width, double ratioW, double ratioH) {
    if (ratioW <= 0) return 0;
    return width * ratioH / ratioW;
  }

  /// Given height and aspect ratio, calculate width.
  static double calculateWidth(double height, double ratioW, double ratioH) {
    if (ratioH <= 0) return 0;
    return height * ratioW / ratioH;
  }

  /// Calculate the aspect ratio as a decimal.
  static double toDecimal(double ratioW, double ratioH) {
    if (ratioH <= 0) return 0;
    return ratioW / ratioH;
  }

  /// Determine orientation from dimensions.
  static String orientation(double width, double height) {
    if (width > height) return 'Landscape';
    if (height > width) return 'Portrait';
    return 'Square';
  }

  /// Calculate megapixels from width and height.
  static double megapixels(double width, double height) {
    return (width * height) / 1000000;
  }

  /// Scale dimensions by a factor.
  static (double, double) scale(double width, double height, double factor) {
    return (width * factor, height * factor);
  }

  /// Fit dimensions within a max bounding box while preserving ratio.
  static (double, double) fitWithin(
    double width,
    double height,
    double maxWidth,
    double maxHeight,
  ) {
    if (width <= 0 || height <= 0) return (0, 0);
    final scaleW = maxWidth / width;
    final scaleH = maxHeight / height;
    final s = scaleW < scaleH ? scaleW : scaleH;
    return (width * s, height * s);
  }
}

class AspectRatioPreset {
  final String label;
  final double w;
  final double h;
  final String description;

  const AspectRatioPreset(this.label, this.w, this.h, this.description);
}
