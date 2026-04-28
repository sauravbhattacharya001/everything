/// Service for matrix arithmetic operations.
///
/// Supports addition, subtraction, multiplication, transpose,
/// determinant (up to 10×10), and inverse (via Gauss-Jordan).
class MatrixCalculatorService {
  MatrixCalculatorService._();

  /// Parse a text block into a matrix.
  /// Each line is a row; values separated by spaces or commas.
  static List<List<double>>? parse(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return null;
    final matrix = <List<double>>[];
    int? cols;
    for (final line in lines) {
      final parts = line
          .split(RegExp(r'[,\s]+'))
          .where((s) => s.isNotEmpty)
          .toList();
      final row = <double>[];
      for (final p in parts) {
        final v = double.tryParse(p);
        if (v == null) return null;
        row.add(v);
      }
      if (row.isEmpty) return null;
      cols ??= row.length;
      if (row.length != cols) return null;
      matrix.add(row);
    }
    return matrix;
  }

  /// Pretty-print a matrix.
  static String format(List<List<double>> m) {
    final buf = StringBuffer();
    for (final row in m) {
      buf.writeln(row.map(_fmtNum).join('\t'));
    }
    return buf.toString().trimRight();
  }

  static String _fmtNum(double v) {
    if (v == v.roundToDouble() && v.abs() < 1e12) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(4);
  }

  /// Add two matrices.
  static List<List<double>>? add(List<List<double>> a, List<List<double>> b) {
    if (a.length != b.length || a[0].length != b[0].length) return null;
    return List.generate(
      a.length,
      (i) => List.generate(a[0].length, (j) => a[i][j] + b[i][j]),
    );
  }

  /// Subtract B from A.
  static List<List<double>>? subtract(
      List<List<double>> a, List<List<double>> b) {
    if (a.length != b.length || a[0].length != b[0].length) return null;
    return List.generate(
      a.length,
      (i) => List.generate(a[0].length, (j) => a[i][j] - b[i][j]),
    );
  }

  /// Multiply A × B.
  ///
  /// Uses transposed-B access pattern for cache-friendly inner loop
  /// and pre-allocated result matrix to avoid closure overhead.
  static List<List<double>>? multiply(
      List<List<double>> a, List<List<double>> b) {
    if (a[0].length != b.length) return null;
    final rows = a.length;
    final cols = b[0].length;
    final n = a[0].length;
    // Transpose B so inner loop accesses contiguous memory
    final bT = List.generate(cols, (j) => List.generate(n, (k) => b[k][j]));
    final result = List.generate(rows, (_) => List<double>.filled(cols, 0.0));
    for (int i = 0; i < rows; i++) {
      final rowA = a[i];
      for (int j = 0; j < cols; j++) {
        final colB = bT[j];
        double sum = 0.0;
        for (int k = 0; k < n; k++) {
          sum += rowA[k] * colB[k];
        }
        result[i][j] = sum;
      }
    }
    return result;
  }

  /// Scalar multiply.
  static List<List<double>> scale(List<List<double>> m, double s) {
    return List.generate(
      m.length,
      (i) => List.generate(m[0].length, (j) => m[i][j] * s),
    );
  }

  /// Transpose.
  static List<List<double>> transpose(List<List<double>> m) {
    final rows = m.length;
    final cols = m[0].length;
    return List.generate(cols, (j) => List.generate(rows, (i) => m[i][j]));
  }

  /// Determinant via LU decomposition with partial pivoting — O(n³).
  ///
  /// Replaces the previous O(n!) cofactor expansion. Supports up to 10×10.
  static double? determinant(List<List<double>> m) {
    if (m.length != m[0].length) return null;
    final n = m.length;
    if (n > 10) return null;
    if (n == 1) return m[0][0];
    if (n == 2) return m[0][0] * m[1][1] - m[0][1] * m[1][0];
    final lu = List.generate(n, (i) => List<double>.from(m[i]));
    int swaps = 0;
    for (int col = 0; col < n; col++) {
      int pivot = col;
      double best = lu[col][col].abs();
      for (int row = col + 1; row < n; row++) {
        final v = lu[row][col].abs();
        if (v > best) {
          best = v;
          pivot = row;
        }
      }
      if (best < 1e-12) return 0.0;
      if (pivot != col) {
        final tmp = lu[col];
        lu[col] = lu[pivot];
        lu[pivot] = tmp;
        swaps++;
      }
      final pivotVal = lu[col][col];
      for (int row = col + 1; row < n; row++) {
        final factor = lu[row][col] / pivotVal;
        for (int j = col + 1; j < n; j++) {
          lu[row][j] -= factor * lu[col][j];
        }
      }
    }
    double det = swaps.isOdd ? -1.0 : 1.0;
    for (int i = 0; i < n; i++) {
      det *= lu[i][i];
    }
    return det;
  }

  /// Inverse via Gauss-Jordan elimination.
  static List<List<double>>? inverse(List<List<double>> m) {
    if (m.length != m[0].length) return null;
    final n = m.length;
    // Augment [m | I]
    final aug = List.generate(n, (i) {
      return List.generate(2 * n, (j) {
        if (j < n) return m[i][j];
        return i == (j - n) ? 1.0 : 0.0;
      });
    });
    for (int col = 0; col < n; col++) {
      // Find pivot
      int pivot = -1;
      double best = 0;
      for (int row = col; row < n; row++) {
        if (aug[row][col].abs() > best) {
          best = aug[row][col].abs();
          pivot = row;
        }
      }
      if (best < 1e-12) return null; // singular
      // Swap
      if (pivot != col) {
        final tmp = aug[col];
        aug[col] = aug[pivot];
        aug[pivot] = tmp;
      }
      // Scale pivot row
      final scale = aug[col][col];
      for (int j = 0; j < 2 * n; j++) {
        aug[col][j] /= scale;
      }
      // Eliminate
      for (int row = 0; row < n; row++) {
        if (row == col) continue;
        final factor = aug[row][col];
        for (int j = 0; j < 2 * n; j++) {
          aug[row][j] -= factor * aug[col][j];
        }
      }
    }
    // Extract right half
    return List.generate(
      n,
      (i) => List.generate(n, (j) => aug[i][j + n]),
    );
  }

  /// Trace (sum of diagonal).
  static double? trace(List<List<double>> m) {
    if (m.length != m[0].length) return null;
    double sum = 0;
    for (int i = 0; i < m.length; i++) {
      sum += m[i][i];
    }
    return sum;
  }

  /// Row Echelon Form (REF) via Gaussian elimination.
  static List<List<double>> rowEchelon(List<List<double>> m) {
    final rows = m.length;
    final cols = m[0].length;
    final r = List.generate(rows, (i) => List<double>.from(m[i]));
    int lead = 0;
    for (int row = 0; row < rows && lead < cols; row++) {
      int i = row;
      while (r[i][lead].abs() < 1e-12) {
        i++;
        if (i == rows) {
          i = row;
          lead++;
          if (lead == cols) return r;
        }
      }
      final tmp = r[i];
      r[i] = r[row];
      r[row] = tmp;
      final lv = r[row][lead];
      for (int j = 0; j < cols; j++) {
        r[row][j] /= lv;
      }
      for (int k = row + 1; k < rows; k++) {
        final f = r[k][lead];
        for (int j = 0; j < cols; j++) {
          r[k][j] -= f * r[row][j];
        }
      }
      lead++;
    }
    return r;
  }
}
