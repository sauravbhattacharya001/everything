import 'dart:math';

/// Difficulty presets for Minesweeper.
enum MinesweeperDifficulty {
  beginner(9, 9, 10, 'Beginner'),
  intermediate(16, 16, 40, 'Intermediate'),
  expert(16, 30, 99, 'Expert');

  final int rows;
  final int cols;
  final int mines;
  final String label;
  const MinesweeperDifficulty(this.rows, this.cols, this.mines, this.label);
}

/// Cell state for Minesweeper grid.
class MinesweeperCell {
  bool hasMine;
  bool isRevealed;
  bool isFlagged;
  int adjacentMines;

  MinesweeperCell({
    this.hasMine = false,
    this.isRevealed = false,
    this.isFlagged = false,
    this.adjacentMines = 0,
  });
}

/// Game state enum.
enum MinesweeperState { playing, won, lost }

/// Service managing Minesweeper game logic.
///
/// Supports beginner/intermediate/expert difficulties, flood-fill
/// reveal, flagging, first-click safety, and win/loss detection.
class MinesweeperService {
  late int rows;
  late int cols;
  late int totalMines;
  late List<List<MinesweeperCell>> grid;
  MinesweeperState state = MinesweeperState.playing;
  MinesweeperDifficulty difficulty;
  int flagCount = 0;
  int revealedCount = 0;
  bool firstClick = true;
  final Stopwatch _stopwatch = Stopwatch();
  final _rng = Random();

  MinesweeperService({this.difficulty = MinesweeperDifficulty.beginner}) {
    newGame(difficulty);
  }

  /// Elapsed seconds since first click.
  int get elapsedSeconds => _stopwatch.elapsed.inSeconds;

  /// Remaining flags (mines − placed flags).
  int get remainingFlags => totalMines - flagCount;

  /// Start a new game with the given difficulty.
  void newGame(MinesweeperDifficulty diff) {
    difficulty = diff;
    rows = diff.rows;
    cols = diff.cols;
    totalMines = diff.mines;
    flagCount = 0;
    revealedCount = 0;
    firstClick = true;
    state = MinesweeperState.playing;
    _stopwatch.reset();
    grid = List.generate(
      rows,
      (_) => List.generate(cols, (_) => MinesweeperCell()),
    );
  }

  /// Place mines randomly, ensuring (safeR, safeC) and its neighbors
  /// are mine-free (first-click safety).
  void _placeMines(int safeR, int safeC) {
    final safeZone = <(int, int)>{};
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final nr = safeR + dr;
        final nc = safeC + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
          safeZone.add((nr, nc));
        }
      }
    }

    var placed = 0;
    while (placed < totalMines) {
      final r = _rng.nextInt(rows);
      final c = _rng.nextInt(cols);
      if (!grid[r][c].hasMine && !safeZone.contains((r, c))) {
        grid[r][c].hasMine = true;
        placed++;
      }
    }

    // Compute adjacent mine counts.
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        if (grid[r][c].hasMine) continue;
        var count = 0;
        for (var dr = -1; dr <= 1; dr++) {
          for (var dc = -1; dc <= 1; dc++) {
            final nr = r + dr;
            final nc = c + dc;
            if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && grid[nr][nc].hasMine) {
              count++;
            }
          }
        }
        grid[r][c].adjacentMines = count;
      }
    }
  }

  /// Reveal cell at (r, c). On first click, places mines safely.
  /// Returns true if state changed.
  bool reveal(int r, int c) {
    if (state != MinesweeperState.playing) return false;
    final cell = grid[r][c];
    if (cell.isRevealed || cell.isFlagged) return false;

    if (firstClick) {
      firstClick = false;
      _placeMines(r, c);
      _stopwatch.start();
    }

    if (cell.hasMine) {
      cell.isRevealed = true;
      state = MinesweeperState.lost;
      _stopwatch.stop();
      // Reveal all mines.
      for (var rr = 0; rr < rows; rr++) {
        for (var cc = 0; cc < cols; cc++) {
          if (grid[rr][cc].hasMine) grid[rr][cc].isRevealed = true;
        }
      }
      return true;
    }

    _floodReveal(r, c);
    _checkWin();
    return true;
  }

  /// Flood-fill reveal for empty cells.
  void _floodReveal(int r, int c) {
    if (r < 0 || r >= rows || c < 0 || c >= cols) return;
    final cell = grid[r][c];
    if (cell.isRevealed || cell.isFlagged || cell.hasMine) return;

    cell.isRevealed = true;
    revealedCount++;

    if (cell.adjacentMines == 0) {
      for (var dr = -1; dr <= 1; dr++) {
        for (var dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          _floodReveal(r + dr, c + dc);
        }
      }
    }
  }

  /// Toggle flag on cell at (r, c).
  bool toggleFlag(int r, int c) {
    if (state != MinesweeperState.playing) return false;
    final cell = grid[r][c];
    if (cell.isRevealed) return false;

    cell.isFlagged = !cell.isFlagged;
    flagCount += cell.isFlagged ? 1 : -1;
    return true;
  }

  /// Chord reveal: if a revealed numbered cell has exactly that many
  /// adjacent flags, reveal all unflagged neighbors.
  bool chordReveal(int r, int c) {
    if (state != MinesweeperState.playing) return false;
    final cell = grid[r][c];
    if (!cell.isRevealed || cell.adjacentMines == 0) return false;

    var adjFlags = 0;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final nr = r + dr;
        final nc = c + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols && grid[nr][nc].isFlagged) {
          adjFlags++;
        }
      }
    }

    if (adjFlags != cell.adjacentMines) return false;

    var changed = false;
    for (var dr = -1; dr <= 1; dr++) {
      for (var dc = -1; dc <= 1; dc++) {
        final nr = r + dr;
        final nc = c + dc;
        if (nr >= 0 && nr < rows && nc >= 0 && nc < cols) {
          if (!grid[nr][nc].isRevealed && !grid[nr][nc].isFlagged) {
            if (reveal(nr, nc)) changed = true;
          }
        }
      }
    }
    return changed;
  }

  void _checkWin() {
    if (revealedCount == (rows * cols) - totalMines) {
      state = MinesweeperState.won;
      _stopwatch.stop();
    }
  }
}
