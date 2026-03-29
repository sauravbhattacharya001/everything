import 'dart:math';

/// Service for Conway's Game of Life cellular automaton.
class GameOfLifeService {
  late List<List<bool>> _grid;
  int _rows;
  int _cols;
  int _generation = 0;

  int get rows => _rows;
  int get cols => _cols;
  int get generation => _generation;

  GameOfLifeService({int rows = 30, int cols = 20})
      : _rows = rows,
        _cols = cols {
    _grid = _emptyGrid();
  }

  List<List<bool>> _emptyGrid() =>
      List.generate(_rows, (_) => List.filled(_cols, false));

  List<List<bool>> get grid =>
      _grid.map((row) => List<bool>.from(row)).toList();

  void resize(int rows, int cols) {
    _rows = rows;
    _cols = cols;
    clear();
  }

  void clear() {
    _grid = _emptyGrid();
    _generation = 0;
  }

  void toggleCell(int row, int col) {
    if (row >= 0 && row < _rows && col >= 0 && col < _cols) {
      _grid[row][col] = !_grid[row][col];
    }
  }

  void randomize({double density = 0.3}) {
    final rng = Random();
    _grid = List.generate(
      _rows,
      (_) => List.generate(_cols, (_) => rng.nextDouble() < density),
    );
    _generation = 0;
  }

  int _countNeighbors(int row, int col) {
    int count = 0;
    for (int dr = -1; dr <= 1; dr++) {
      for (int dc = -1; dc <= 1; dc++) {
        if (dr == 0 && dc == 0) continue;
        final r = (row + dr) % _rows;
        final c = (col + dc) % _cols;
        if (_grid[r][c]) count++;
      }
    }
    return count;
  }

  /// Advance one generation. Returns true if state changed.
  bool step() {
    final next = _emptyGrid();
    bool changed = false;
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final neighbors = _countNeighbors(r, c);
        final alive = _grid[r][c];
        final nextAlive =
            alive ? (neighbors == 2 || neighbors == 3) : (neighbors == 3);
        next[r][c] = nextAlive;
        if (nextAlive != alive) changed = true;
      }
    }
    _grid = next;
    _generation++;
    return changed;
  }

  int get liveCellCount {
    int count = 0;
    for (final row in _grid) {
      for (final cell in row) {
        if (cell) count++;
      }
    }
    return count;
  }

  // ── Preset patterns ──

  void loadGlider(int startRow, int startCol) {
    const pattern = [
      [0, 1],
      [1, 2],
      [2, 0],
      [2, 1],
      [2, 2],
    ];
    _loadPattern(pattern, startRow, startCol);
  }

  void loadBlinker(int startRow, int startCol) {
    const pattern = [
      [0, 0],
      [0, 1],
      [0, 2],
    ];
    _loadPattern(pattern, startRow, startCol);
  }

  void loadPulsar(int startRow, int startCol) {
    const pattern = [
      [0,2],[0,3],[0,4],[0,8],[0,9],[0,10],
      [2,0],[2,5],[2,7],[2,12],
      [3,0],[3,5],[3,7],[3,12],
      [4,0],[4,5],[4,7],[4,12],
      [5,2],[5,3],[5,4],[5,8],[5,9],[5,10],
      [7,2],[7,3],[7,4],[7,8],[7,9],[7,10],
      [8,0],[8,5],[8,7],[8,12],
      [9,0],[9,5],[9,7],[9,12],
      [10,0],[10,5],[10,7],[10,12],
      [12,2],[12,3],[12,4],[12,8],[12,9],[12,10],
    ];
    _loadPattern(pattern, startRow, startCol);
  }

  void loadGliderGun(int startRow, int startCol) {
    const pattern = [
      [0,24],
      [1,22],[1,24],
      [2,12],[2,13],[2,20],[2,21],[2,34],[2,35],
      [3,11],[3,15],[3,20],[3,21],[3,34],[3,35],
      [4,0],[4,1],[4,10],[4,16],[4,20],[4,21],
      [5,0],[5,1],[5,10],[5,14],[5,16],[5,17],[5,22],[5,24],
      [6,10],[6,16],[6,24],
      [7,11],[7,15],
      [8,12],[8,13],
    ];
    _loadPattern(pattern, startRow, startCol);
  }

  void _loadPattern(List<List<int>> pattern, int startRow, int startCol) {
    for (final p in pattern) {
      final r = (startRow + p[0]) % _rows;
      final c = (startCol + p[1]) % _cols;
      _grid[r][c] = true;
    }
  }
}
