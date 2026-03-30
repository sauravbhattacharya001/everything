import 'dart:math';

/// Difficulty levels for Sudoku puzzles.
enum SudokuDifficulty {
  easy('Easy', 36),
  medium('Medium', 30),
  hard('Hard', 25),
  expert('Expert', 20);

  final String label;
  final int givens;
  const SudokuDifficulty(this.label, this.givens);
}

/// Service that generates and manages Sudoku puzzles.
class SudokuService {
  final _rng = Random();

  /// The current puzzle grid (0 = empty).
  List<List<int>> puzzle = List.generate(9, (_) => List.filled(9, 0));

  /// The solved grid for validation.
  List<List<int>> solution = List.generate(9, (_) => List.filled(9, 0));

  /// Player's working grid.
  List<List<int>> playerGrid = List.generate(9, (_) => List.filled(9, 0));

  /// Tracks which cells are given (not editable).
  List<List<bool>> given = List.generate(9, (_) => List.filled(9, false));

  /// Tracks pencil marks (candidates) per cell.
  List<List<Set<int>>> pencilMarks =
      List.generate(9, (_) => List.generate(9, (_) => <int>{}));

  SudokuDifficulty difficulty = SudokuDifficulty.medium;
  int selectedRow = -1;
  int selectedCol = -1;
  bool isComplete = false;
  int mistakes = 0;
  int hintsUsed = 0;
  DateTime? startTime;
  bool pencilMode = false;

  /// Generate a new puzzle.
  void newGame(SudokuDifficulty diff) {
    difficulty = diff;
    mistakes = 0;
    hintsUsed = 0;
    isComplete = false;
    selectedRow = -1;
    selectedCol = -1;
    pencilMode = false;
    startTime = DateTime.now();

    // Generate a solved board.
    solution = List.generate(9, (_) => List.filled(9, 0));
    _fillBoard(solution);

    // Copy and remove cells to create puzzle.
    puzzle = solution.map((r) => List<int>.from(r)).toList();
    _removeCells(puzzle, 81 - diff.givens);

    playerGrid = puzzle.map((r) => List<int>.from(r)).toList();
    given = puzzle
        .map((r) => r.map((v) => v != 0).toList())
        .toList();
    pencilMarks =
        List.generate(9, (_) => List.generate(9, (_) => <int>{}));
  }

  bool _fillBoard(List<List<int>> board) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (board[r][c] == 0) {
          final nums = List.generate(9, (i) => i + 1)..shuffle(_rng);
          for (final n in nums) {
            if (_isValid(board, r, c, n)) {
              board[r][c] = n;
              if (_fillBoard(board)) return true;
              board[r][c] = 0;
            }
          }
          return false;
        }
      }
    }
    return true;
  }

  void _removeCells(List<List<int>> board, int count) {
    final cells = <List<int>>[];
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        cells.add([r, c]);
      }
    }
    cells.shuffle(_rng);
    int removed = 0;
    for (final cell in cells) {
      if (removed >= count) break;
      board[cell[0]][cell[1]] = 0;
      removed++;
    }
  }

  bool _isValid(List<List<int>> board, int row, int col, int num) {
    for (int i = 0; i < 9; i++) {
      if (board[row][i] == num) return false;
      if (board[i][col] == num) return false;
    }
    final boxR = (row ~/ 3) * 3;
    final boxC = (col ~/ 3) * 3;
    for (int r = boxR; r < boxR + 3; r++) {
      for (int c = boxC; c < boxC + 3; c++) {
        if (board[r][c] == num) return false;
      }
    }
    return true;
  }

  /// Place a number in the selected cell. Returns true if correct.
  bool placeNumber(int num) {
    if (selectedRow < 0 || selectedCol < 0) return false;
    if (given[selectedRow][selectedCol]) return false;

    if (pencilMode) {
      final marks = pencilMarks[selectedRow][selectedCol];
      if (marks.contains(num)) {
        marks.remove(num);
      } else {
        marks.add(num);
      }
      return true;
    }

    playerGrid[selectedRow][selectedCol] = num;
    pencilMarks[selectedRow][selectedCol].clear();

    if (num != solution[selectedRow][selectedCol]) {
      mistakes++;
      return false;
    }

    _checkComplete();
    return true;
  }

  /// Clear the selected cell.
  void clearCell() {
    if (selectedRow < 0 || selectedCol < 0) return;
    if (given[selectedRow][selectedCol]) return;
    playerGrid[selectedRow][selectedCol] = 0;
    pencilMarks[selectedRow][selectedCol].clear();
  }

  /// Reveal the correct value for the selected cell.
  bool useHint() {
    if (selectedRow < 0 || selectedCol < 0) return false;
    if (given[selectedRow][selectedCol]) return false;
    if (playerGrid[selectedRow][selectedCol] == solution[selectedRow][selectedCol]) {
      return false;
    }
    playerGrid[selectedRow][selectedCol] = solution[selectedRow][selectedCol];
    pencilMarks[selectedRow][selectedCol].clear();
    hintsUsed++;
    _checkComplete();
    return true;
  }

  void _checkComplete() {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (playerGrid[r][c] != solution[r][c]) return;
      }
    }
    isComplete = true;
  }

  /// Select a cell.
  void selectCell(int row, int col) {
    selectedRow = row;
    selectedCol = col;
  }

  /// Check if a placed number is wrong.
  bool isError(int row, int col) {
    final v = playerGrid[row][col];
    return v != 0 && !given[row][col] && v != solution[row][col];
  }

  /// Get elapsed time.
  Duration get elapsed =>
      startTime != null ? DateTime.now().difference(startTime!) : Duration.zero;

  String get elapsedFormatted {
    final d = elapsed;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? "${d.inHours}:" : ""}$m:$s';
  }
}
