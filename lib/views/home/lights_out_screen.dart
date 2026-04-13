import 'dart:math';
import 'package:flutter/material.dart';

/// Lights Out — classic puzzle where tapping a cell toggles it and its
/// orthogonal neighbors. Goal: turn all lights off.
///
/// Features:
/// - 5×5 grid (classic) with 3×3, 4×4, 6×6 size options
/// - Move counter and best-score tracking per size
/// - Hint system highlights a solvable next move (Gaussian elimination over GF(2))
/// - Shuffle generates guaranteed-solvable puzzles
/// - Win celebration with confetti animation
class LightsOutScreen extends StatefulWidget {
  const LightsOutScreen({super.key});

  @override
  State<LightsOutScreen> createState() => _LightsOutScreenState();
}

class _LightsOutScreenState extends State<LightsOutScreen>
    with SingleTickerProviderStateMixin {
  int _size = 5;
  late List<bool> _grid;
  int _moves = 0;
  bool _won = false;
  int? _hintIndex;
  final Map<int, int> _bestScores = {};
  late AnimationController _celebrationController;
  final _random = Random();

  @override
  void initState() {
    super.initState();
    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _newPuzzle();
  }

  @override
  void dispose() {
    _celebrationController.dispose();
    super.dispose();
  }

  // ── Puzzle generation (guaranteed solvable) ──

  void _newPuzzle() {
    final n = _size * _size;
    _grid = List.filled(n, false);
    // Apply random presses to guarantee solvability.
    final presses = List.generate(n, (_) => _random.nextBool());
    for (int i = 0; i < n; i++) {
      if (presses[i]) _applyToggle(i, updateState: false);
    }
    // If board is already solved, press a few random cells.
    if (_grid.every((c) => !c)) {
      for (int i = 0; i < _size + 1; i++) {
        _applyToggle(_random.nextInt(n), updateState: false);
      }
    }
    _moves = 0;
    _won = false;
    _hintIndex = null;
    _celebrationController.reset();
  }

  void _applyToggle(int index, {bool updateState = true}) {
    final r = index ~/ _size;
    final c = index % _size;
    _toggle(r, c);
    if (r > 0) _toggle(r - 1, c);
    if (r < _size - 1) _toggle(r + 1, c);
    if (c > 0) _toggle(r, c - 1);
    if (c < _size - 1) _toggle(r, c + 1);
  }

  void _toggle(int r, int c) {
    _grid[r * _size + c] = !_grid[r * _size + c];
  }

  void _onCellTap(int index) {
    if (_won) return;
    setState(() {
      _applyToggle(index);
      _moves++;
      _hintIndex = null;
      if (_grid.every((c) => !c)) {
        _won = true;
        final best = _bestScores[_size];
        if (best == null || _moves < best) {
          _bestScores[_size] = _moves;
        }
        _celebrationController.forward(from: 0);
      }
    });
  }

  // ── Hint: find one cell to press using GF(2) Gaussian elimination ──

  void _showHint() {
    final solution = _solveGF2();
    if (solution != null) {
      final idx = solution.indexWhere((v) => v);
      if (idx >= 0) {
        setState(() => _hintIndex = idx);
      }
    }
  }

  /// Solve the current board over GF(2). Returns a list of bools (press/no-press)
  /// or null if unsolvable.
  List<bool>? _solveGF2() {
    final n = _size * _size;
    // Build augmented matrix [A | b] over GF(2).
    final matrix = List.generate(n, (row) {
      final cols = List.filled(n + 1, false);
      // Column = which cells does pressing `col` affect?
      // Row = which cells are affected
      // Actually we need: for each cell (row), which presses (col) toggle it?
      final r = row ~/ _size;
      final c = row % _size;
      cols[row] = true; // self
      if (r > 0) cols[(r - 1) * _size + c] = true;
      if (r < _size - 1) cols[(r + 1) * _size + c] = true;
      if (c > 0) cols[r * _size + (c - 1)] = true;
      if (c < _size - 1) cols[r * _size + (c + 1)] = true;
      cols[n] = _grid[row]; // target: current state (want to flip all lit ones)
      return cols;
    });

    // Gaussian elimination over GF(2).
    int pivotRow = 0;
    for (int col = 0; col < n && pivotRow < n; col++) {
      // Find pivot.
      int pr = -1;
      for (int r = pivotRow; r < n; r++) {
        if (matrix[r][col]) {
          pr = r;
          break;
        }
      }
      if (pr == -1) continue;
      // Swap.
      final tmp = matrix[pivotRow];
      matrix[pivotRow] = matrix[pr];
      matrix[pr] = tmp;
      // Eliminate.
      for (int r = 0; r < n; r++) {
        if (r != pivotRow && matrix[r][col]) {
          for (int c2 = 0; c2 <= n; c2++) {
            matrix[r][c2] = matrix[r][c2] ^ matrix[pivotRow][c2];
          }
        }
      }
      pivotRow++;
    }

    // Back-substitute.
    final solution = List.filled(n, false);
    for (int r = 0; r < n; r++) {
      int leadCol = -1;
      for (int c = 0; c < n; c++) {
        if (matrix[r][c]) {
          leadCol = c;
          break;
        }
      }
      if (leadCol == -1) {
        if (matrix[r][n]) return null; // inconsistent
      } else {
        solution[leadCol] = matrix[r][n];
      }
    }
    return solution;
  }

  // ── UI ──

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final best = _bestScores[_size];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lights Out'),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.grid_on),
            tooltip: 'Grid size',
            onSelected: (size) {
              setState(() {
                _size = size;
                _newPuzzle();
              });
            },
            itemBuilder: (_) => [3, 4, 5, 6]
                .map((s) => PopupMenuItem(
                      value: s,
                      child: Text('${s}×$s${s == _size ? ' ✓' : ''}'),
                    ))
                .toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                    label: 'Moves', value: '$_moves', icon: Icons.touch_app),
                _StatChip(
                  label: 'Best',
                  value: best != null ? '$best' : '—',
                  icon: Icons.emoji_events,
                ),
                _StatChip(
                  label: 'Lit',
                  value: '${_grid.where((c) => c).length}',
                  icon: Icons.lightbulb,
                ),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _size,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                    ),
                    itemCount: _size * _size,
                    itemBuilder: (context, index) {
                      final lit = _grid[index];
                      final isHint = _hintIndex == index;
                      return GestureDetector(
                        onTap: () => _onCellTap(index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: lit
                                ? (isHint
                                    ? Colors.orange
                                    : Colors.amber[400])
                                : (isHint
                                    ? Colors.orange.withOpacity(0.3)
                                    : Colors.grey[800]!),
                            borderRadius: BorderRadius.circular(8),
                            border: isHint
                                ? Border.all(color: Colors.orange, width: 3)
                                : null,
                            boxShadow: lit
                                ? [
                                    BoxShadow(
                                      color:
                                          Colors.amber.withOpacity(0.5),
                                      blurRadius: 12,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                          child: lit
                              ? const Center(
                                  child: Icon(Icons.lightbulb,
                                      color: Colors.white, size: 28))
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          // Win banner
          if (_won)
            AnimatedBuilder(
              animation: _celebrationController,
              builder: (context, child) => Opacity(
                opacity: _celebrationController.value,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '🎉 Solved in $_moves moves!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.amber[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _won ? null : _showHint,
                    icon: const Icon(Icons.tips_and_updates),
                    label: const Text('Hint'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => setState(_newPuzzle),
                    icon: const Icon(Icons.refresh),
                    label: const Text('New Puzzle'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatChip(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
      ],
    );
  }
}
