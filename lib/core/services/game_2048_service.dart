import 'dart:math';

/// Directions for swiping in the 2048 game.
enum SwipeDirection { up, down, left, right }

/// Service that manages the 2048 game logic.
///
/// Maintains a 4×4 grid of tile values (0 = empty), handles
/// merging, spawning, scoring, and win/loss detection.
class Game2048Service {
  static const int size = 4;

  List<List<int>> grid = [];
  int score = 0;
  int bestScore = 0;
  bool won = false;
  bool _wonAcknowledged = false;
  final _rng = Random();

  Game2048Service() {
    newGame();
  }

  /// Start a fresh game.
  void newGame() {
    grid = List.generate(size, (_) => List.filled(size, 0));
    score = 0;
    won = false;
    _wonAcknowledged = false;
    _spawnTile();
    _spawnTile();
  }

  /// Acknowledge the win so the player can keep going.
  void acknowledgeWin() {
    _wonAcknowledged = true;
  }

  /// Spawn a 2 (90%) or 4 (10%) on a random empty cell.
  void _spawnTile() {
    final empty = <(int, int)>[];
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] == 0) empty.add((r, c));
      }
    }
    if (empty.isEmpty) return;
    final (r, c) = empty[_rng.nextInt(empty.length)];
    grid[r][c] = _rng.nextDouble() < 0.9 ? 2 : 4;
  }

  /// Slide and merge a single row to the left, returning the row and points earned.
  (List<int>, int) _mergeRow(List<int> row) {
    // Remove zeros
    final tiles = row.where((v) => v != 0).toList();
    final result = <int>[];
    var pts = 0;
    var i = 0;
    while (i < tiles.length) {
      if (i + 1 < tiles.length && tiles[i] == tiles[i + 1]) {
        final merged = tiles[i] * 2;
        result.add(merged);
        pts += merged;
        if (merged == 2048 && !_wonAcknowledged) won = true;
        i += 2;
      } else {
        result.add(tiles[i]);
        i++;
      }
    }
    while (result.length < size) {
      result.add(0);
    }
    return (result, pts);
  }

  /// Execute a swipe in the given direction. Returns true if the board changed.
  bool swipe(SwipeDirection dir) {
    final oldGrid =
        grid.map((r) => List<int>.from(r)).toList();

    switch (dir) {
      case SwipeDirection.left:
        for (var r = 0; r < size; r++) {
          final (row, pts) = _mergeRow(grid[r]);
          grid[r] = row;
          score += pts;
        }
      case SwipeDirection.right:
        for (var r = 0; r < size; r++) {
          final (row, pts) = _mergeRow(grid[r].reversed.toList());
          grid[r] = row.reversed.toList();
          score += pts;
        }
      case SwipeDirection.up:
        for (var c = 0; c < size; c++) {
          final col = [for (var r = 0; r < size; r++) grid[r][c]];
          final (merged, pts) = _mergeRow(col);
          for (var r = 0; r < size; r++) {
            grid[r][c] = merged[r];
          }
          score += pts;
        }
      case SwipeDirection.down:
        for (var c = 0; c < size; c++) {
          final col = [for (var r = size - 1; r >= 0; r--) grid[r][c]];
          final (merged, pts) = _mergeRow(col);
          for (var r = 0; r < size; r++) {
            grid[size - 1 - r][c] = merged[r];
          }
          score += pts;
        }
    }

    // Check if anything changed
    bool changed = false;
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] != oldGrid[r][c]) {
          changed = true;
          break;
        }
      }
      if (changed) break;
    }

    if (changed) {
      if (score > bestScore) bestScore = score;
      _spawnTile();
    }
    return changed;
  }

  /// Check if no moves remain.
  bool get isGameOver {
    for (var r = 0; r < size; r++) {
      for (var c = 0; c < size; c++) {
        if (grid[r][c] == 0) return false;
        if (c + 1 < size && grid[r][c] == grid[r][c + 1]) return false;
        if (r + 1 < size && grid[r][c] == grid[r + 1][c]) return false;
      }
    }
    return true;
  }
}
