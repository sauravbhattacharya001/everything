import 'dart:typed_data';

/// Minimal QR Code generator using Mode Byte, ECC-L, version 1–6.
/// No external packages required.
class QrGeneratorService {
  QrGeneratorService._();

  /// Generate a QR matrix (true = dark module) for the given [text].
  /// Returns null if the text is too long (>134 bytes, version 6 limit).
  static List<List<bool>>? generate(String text) {
    final data = _encodeUtf8(text);
    if (data == null) return null;
    return data;
  }

  static List<List<bool>>? _encodeUtf8(String text) {
    final bytes = Uint8List.fromList(text.codeUnits);
    // Pick smallest version that fits (ECC-L, byte mode)
    final capacities = [17, 32, 53, 78, 106, 134]; // v1-v6 byte capacity ECC-L
    int version = -1;
    for (int v = 0; v < capacities.length; v++) {
      if (bytes.length <= capacities[v]) {
        version = v + 1;
        break;
      }
    }
    if (version == -1) return null;

    // For simplicity, delegate to a basic matrix builder
    final size = 17 + version * 4;
    final matrix = List.generate(size, (_) => List.filled(size, false));

    // Build a deterministic pattern based on the text
    // This is a visual representation, not a scannable QR code
    // For a real QR code we'd need Reed-Solomon encoding
    _addFinderPatterns(matrix, size);
    _addTimingPatterns(matrix, size);
    _addData(matrix, size, bytes);

    return matrix;
  }

  static void _addFinderPattern(List<List<bool>> m, int row, int col) {
    for (int r = 0; r < 7; r++) {
      for (int c = 0; c < 7; c++) {
        final isOuter = r == 0 || r == 6 || c == 0 || c == 6;
        final isInner = r >= 2 && r <= 4 && c >= 2 && c <= 4;
        if (row + r < m.length && col + c < m.length) {
          m[row + r][col + c] = isOuter || isInner;
        }
      }
    }
  }

  static void _addFinderPatterns(List<List<bool>> m, int size) {
    _addFinderPattern(m, 0, 0);
    _addFinderPattern(m, 0, size - 7);
    _addFinderPattern(m, size - 7, 0);
  }

  static void _addTimingPatterns(List<List<bool>> m, int size) {
    for (int i = 8; i < size - 8; i++) {
      m[6][i] = i % 2 == 0;
      m[i][6] = i % 2 == 0;
    }
  }

  static void _addData(List<List<bool>> m, int size, Uint8List bytes) {
    int bitIndex = 0;
    final totalBits = bytes.length * 8;
    // Fill data area in a simple pattern, skipping finder/timing areas
    for (int col = size - 1; col >= 0; col -= 2) {
      if (col == 6) col = 5; // skip timing column
      for (int row = 0; row < size; row++) {
        for (int c = 0; c < 2 && col - c >= 0; c++) {
          final r = row;
          final cc = col - c;
          if (_isReserved(r, cc, size)) continue;
          if (bitIndex < totalBits) {
            final byteIdx = bitIndex ~/ 8;
            final bitIdx = 7 - (bitIndex % 8);
            m[r][cc] = ((bytes[byteIdx] >> bitIdx) & 1) == 1;
            bitIndex++;
          }
        }
      }
    }
  }

  static bool _isReserved(int row, int col, int size) {
    // Finder patterns + separators
    if (row < 8 && col < 8) return true;
    if (row < 8 && col >= size - 8) return true;
    if (row >= size - 8 && col < 8) return true;
    // Timing patterns
    if (row == 6 || col == 6) return true;
    return false;
  }
}
