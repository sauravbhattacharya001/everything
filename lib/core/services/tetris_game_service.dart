import 'dart:math';

/// The 7 standard Tetromino types.
enum TetrominoType { I, O, T, S, Z, J, L }

/// A point on the Tetris board.
class TetrisPoint {
  final int x;
  final int y;
  const TetrisPoint(this.x, this.y);

  TetrisPoint operator +(TetrisPoint other) =>
      TetrisPoint(x + other.x, y + other.y);

  @override
  bool operator ==(Object other) =>
      other is TetrisPoint && other.x == x && other.y == y;

  @override
  int get hashCode => x.hashCode ^ (y.hashCode << 16);
}

/// A falling tetromino piece with position and rotation.
class Tetromino {
  TetrominoType type;
  int rotation; // 0-3
  TetrisPoint position; // top-left anchor

  Tetromino({required this.type, this.rotation = 0, required this.position});

  /// Get the 4 cell offsets for this piece at current rotation.
  List<TetrisPoint> get cells {
    final shape = _shapes[type]![rotation % _shapes[type]!.length];
    return shape.map((p) => p + position).toList();
  }

  Tetromino copy() =>
      Tetromino(type: type, rotation: rotation, position: position);

  static const Map<TetrominoType, List<List<TetrisPoint>>> _shapes = {
    TetrominoType.I: [
      [TetrisPoint(0, 1), TetrisPoint(1, 1), TetrisPoint(2, 1), TetrisPoint(3, 1)],
      [TetrisPoint(2, 0), TetrisPoint(2, 1), TetrisPoint(2, 2), TetrisPoint(2, 3)],
      [TetrisPoint(0, 2), TetrisPoint(1, 2), TetrisPoint(2, 2), TetrisPoint(3, 2)],
      [TetrisPoint(1, 0), TetrisPoint(1, 1), TetrisPoint(1, 2), TetrisPoint(1, 3)],
    ],
    TetrominoType.O: [
      [TetrisPoint(0, 0), TetrisPoint(1, 0), TetrisPoint(0, 1), TetrisPoint(1, 1)],
    ],
    TetrominoType.T: [
      [TetrisPoint(1, 0), TetrisPoint(0, 1), TetrisPoint(1, 1), TetrisPoint(2, 1)],
      [TetrisPoint(1, 0), TetrisPoint(1, 1), TetrisPoint(2, 1), TetrisPoint(1, 2)],
      [TetrisPoint(0, 1), TetrisPoint(1, 1), TetrisPoint(2, 1), TetrisPoint(1, 2)],
      [TetrisPoint(1, 0), TetrisPoint(0, 1), TetrisPoint(1, 1), TetrisPoint(1, 2)],
    ],
    TetrominoType.S: [
      [TetrisPoint(1, 0), TetrisPoint(2, 0), TetrisPoint(0, 1), TetrisPoint(1, 1)],
      [TetrisPoint(1, 0), TetrisPoint(1, 1), TetrisPoint(2, 1), TetrisPoint(2, 2)],
    ],
    TetrominoType.Z: [
      [TetrisPoint(0, 0), TetrisPoint(1, 0), TetrisPoint(1, 1), TetrisPoint(2, 1)],
      [TetrisPoint(2, 0), TetrisPoint(1, 1), TetrisPoint(2, 1), TetrisPoint(1, 2)],
    ],
    TetrominoType.J: [
      [TetrisPoint(0, 0), TetrisPoint(0, 1), TetrisPoint(1, 1), TetrisPoint(2, 1)],
      [TetrisPoint(1, 0), TetrisPoint(2, 0), TetrisPoint(1, 1), TetrisPoint(1, 2)],
      [TetrisPoint(0, 1), TetrisPoint(1, 1), TetrisPoint(2, 1), TetrisPoint(2, 2)],
      [TetrisPoint(1, 0), TetrisPoint(1, 1), TetrisPoint(0, 2), TetrisPoint(1, 2)],
    ],
    TetrominoType.L: [
      [TetrisPoint(2, 0), TetrisPoint(0, 1), TetrisPoint(1, 1), TetrisPoint(2, 1)],
      [TetrisPoint(1, 0), TetrisPoint(1, 1), TetrisPoint(1, 2), TetrisPoint(2, 2)],
      [TetrisPoint(0, 1), TetrisPoint(1, 1), TetrisPoint(2, 1), TetrisPoint(0, 2)],
      [TetrisPoint(0, 0), TetrisPoint(1, 0), TetrisPoint(1, 1), TetrisPoint(1, 2)],
    ],
  };
}

/// Color index for each tetromino type (used by the screen for rendering).
int tetrominoColorIndex(TetrominoType type) => type.index;

/// Core Tetris game logic service.
class TetrisGameService {
  static const int columns = 10;
  static const int rows = 20;

  /// The board grid: -1 = empty, 0-6 = color index of locked piece.
  late List<List<int>> board;

  Tetromino? current;
  Tetromino? nextPiece;
  int score = 0;
  int highScore = 0;
  int level = 1;
  int linesCleared = 0;
  bool isGameOver = false;
  bool isPlaying = false;
  final _rng = Random();

  TetrisGameService() {
    _initGame();
  }

  void _initGame() {
    board = List.generate(rows, (_) => List.filled(columns, -1));
    score = 0;
    level = 1;
    linesCleared = 0;
    isGameOver = false;
    isPlaying = false;
    current = null;
    nextPiece = null;
  }

  void newGame() {
    _initGame();
    isPlaying = true;
    nextPiece = _randomPiece();
    _spawnPiece();
  }

  /// Milliseconds per tick based on level.
  int get tickDuration => max(100, 800 - (level - 1) * 60);

  Tetromino _randomPiece() {
    final type = TetrominoType.values[_rng.nextInt(TetrominoType.values.length)];
    return Tetromino(type: type, position: TetrisPoint((columns - 4) ~/ 2, 0));
  }

  void _spawnPiece() {
    current = nextPiece ?? _randomPiece();
    nextPiece = _randomPiece();
    if (!_isValid(current!)) {
      isGameOver = true;
      isPlaying = false;
      if (score > highScore) highScore = score;
    }
  }

  bool _isValid(Tetromino piece) {
    for (final cell in piece.cells) {
      if (cell.x < 0 || cell.x >= columns || cell.y >= rows) return false;
      if (cell.y >= 0 && board[cell.y][cell.x] != -1) return false;
    }
    return true;
  }

  /// Lock the current piece into the board.
  void _lockPiece() {
    if (current == null) return;
    final colorIdx = tetrominoColorIndex(current!.type);
    for (final cell in current!.cells) {
      if (cell.y >= 0 && cell.y < rows && cell.x >= 0 && cell.x < columns) {
        board[cell.y][cell.x] = colorIdx;
      }
    }
    _clearLines();
    _spawnPiece();
  }

  void _clearLines() {
    int cleared = 0;
    for (int y = rows - 1; y >= 0; y--) {
      if (board[y].every((c) => c != -1)) {
        board.removeAt(y);
        board.insert(0, List.filled(columns, -1));
        cleared++;
        y++; // re-check this row
      }
    }
    if (cleared > 0) {
      linesCleared += cleared;
      // Classic scoring: 100, 300, 500, 800 for 1-4 lines
      const lineScores = [0, 100, 300, 500, 800];
      score += lineScores[cleared.clamp(0, 4)] * level;
      level = (linesCleared ~/ 10) + 1;
    }
  }

  /// Advance piece down one row. Returns true if game continues.
  bool tick() {
    if (isGameOver || current == null) return false;
    if (!_tryMove(0, 1)) {
      _lockPiece();
    }
    return !isGameOver;
  }

  bool _tryMove(int dx, int dy) {
    final test = current!.copy();
    test.position = TetrisPoint(test.position.x + dx, test.position.y + dy);
    if (_isValid(test)) {
      current = test;
      return true;
    }
    return false;
  }

  void moveLeft() {
    if (!isGameOver && current != null) _tryMove(-1, 0);
  }

  void moveRight() {
    if (!isGameOver && current != null) _tryMove(1, 0);
  }

  void rotate() {
    if (isGameOver || current == null) return;
    final test = current!.copy();
    test.rotation = (test.rotation + 1) % 4;
    // Try basic rotation, then wall kicks (-1, +1, -2, +2)
    for (final kick in [0, -1, 1, -2, 2]) {
      final kicked = Tetromino(
        type: test.type,
        rotation: test.rotation,
        position: TetrisPoint(test.position.x + kick, test.position.y),
      );
      if (_isValid(kicked)) {
        current = kicked;
        return;
      }
    }
  }

  /// Hard drop — move piece all the way down instantly.
  void hardDrop() {
    if (isGameOver || current == null) return;
    while (_tryMove(0, 1)) {
      score += 2;
    }
    _lockPiece();
  }

  /// Soft drop — accelerate one row, adds 1 point.
  bool softDrop() {
    if (isGameOver || current == null) return false;
    if (_tryMove(0, 1)) {
      score += 1;
      return true;
    }
    _lockPiece();
    return !isGameOver;
  }

  /// Get the ghost piece position (where the piece would land).
  List<TetrisPoint>? get ghostCells {
    if (current == null) return null;
    final ghost = current!.copy();
    while (true) {
      final next = Tetromino(
        type: ghost.type,
        rotation: ghost.rotation,
        position: TetrisPoint(ghost.position.x, ghost.position.y + 1),
      );
      if (!_isValid(next)) break;
      ghost.position = next.position;
    }
    return ghost.cells;
  }
}
