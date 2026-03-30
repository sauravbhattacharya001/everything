import 'package:flutter/material.dart';
import 'dart:async';
import '../../core/services/sudoku_service.dart';

/// A fully-playable Sudoku puzzle with multiple difficulty levels,
/// pencil marks, hints, and error tracking.
class SudokuScreen extends StatefulWidget {
  const SudokuScreen({super.key});

  @override
  State<SudokuScreen> createState() => _SudokuScreenState();
}

class _SudokuScreenState extends State<SudokuScreen> {
  final _service = SudokuService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _service.newGame(SudokuDifficulty.medium);
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!_service.isComplete) setState(() {});
    });
  }

  void _newGame(SudokuDifficulty diff) {
    setState(() => _service.newGame(diff));
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sudoku'),
        actions: [
          PopupMenuButton<SudokuDifficulty>(
            icon: const Icon(Icons.tune),
            tooltip: 'Difficulty',
            onSelected: _newGame,
            itemBuilder: (_) => SudokuDifficulty.values
                .map((d) => PopupMenuItem(value: d, child: Text(d.label)))
                .toList(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'New Game',
            onPressed: () => _newGame(_service.difficulty),
          ),
        ],
      ),
      body: Column(
        children: [
          // Status bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_service.difficulty.label,
                    style: theme.textTheme.titleSmall),
                Text('⏱ ${_service.elapsedFormatted}',
                    style: theme.textTheme.titleSmall),
                Text('❌ ${_service.mistakes}',
                    style: theme.textTheme.titleSmall?.copyWith(
                        color: _service.mistakes > 0 ? Colors.red : null)),
                Text('💡 ${_service.hintsUsed}',
                    style: theme.textTheme.titleSmall),
              ],
            ),
          ),

          // Grid
          Expanded(
            child: Center(
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: isDark ? Colors.white54 : Colors.black87,
                        width: 2),
                  ),
                  child: _buildGrid(isDark),
                ),
              ),
            ),
          ),

          // Controls
          if (_service.isComplete) _buildCompleteBanner(theme),
          _buildNumberPad(theme, isDark),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildGrid(bool isDark) {
    return Column(
      children: List.generate(9, (row) {
        return Expanded(
          child: Row(
            children: List.generate(9, (col) {
              return Expanded(child: _buildCell(row, col, isDark));
            }),
          ),
        );
      }),
    );
  }

  Widget _buildCell(int row, int col, bool isDark) {
    final value = _service.playerGrid[row][col];
    final isGiven = _service.given[row][col];
    final isSelected =
        _service.selectedRow == row && _service.selectedCol == col;
    final isSameRow = _service.selectedRow == row;
    final isSameCol = _service.selectedCol == col;
    final isSameBox = _service.selectedRow >= 0 &&
        (row ~/ 3 == _service.selectedRow ~/ 3) &&
        (col ~/ 3 == _service.selectedCol ~/ 3);
    final isError = _service.isError(row, col);
    final marks = _service.pencilMarks[row][col];

    Color bgColor;
    if (isSelected) {
      bgColor = isDark ? Colors.blue.shade800 : Colors.blue.shade100;
    } else if (isSameRow || isSameCol || isSameBox) {
      bgColor =
          isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;
    } else {
      bgColor = Colors.transparent;
    }

    // Thicker borders at 3x3 box boundaries.
    final borderRight =
        (col + 1) % 3 == 0 && col < 8 ? 2.0 : 0.5;
    final borderBottom =
        (row + 1) % 3 == 0 && row < 8 ? 2.0 : 0.5;
    final borderColor = isDark ? Colors.white38 : Colors.black45;

    return GestureDetector(
      onTap: () => setState(() => _service.selectCell(row, col)),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            right: BorderSide(color: borderColor, width: borderRight),
            bottom: BorderSide(color: borderColor, width: borderBottom),
          ),
        ),
        child: Center(
          child: value != 0
              ? Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight:
                        isGiven ? FontWeight.bold : FontWeight.normal,
                    color: isError
                        ? Colors.red
                        : isGiven
                            ? null
                            : (isDark ? Colors.blue.shade200 : Colors.blue.shade700),
                  ),
                )
              : marks.isNotEmpty
                  ? _buildPencilMarks(marks, isDark)
                  : null,
        ),
      ),
    );
  }

  Widget _buildPencilMarks(Set<int> marks, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: GridView.count(
        crossAxisCount: 3,
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        children: List.generate(9, (i) {
          final n = i + 1;
          return Center(
            child: Text(
              marks.contains(n) ? '$n' : '',
              style: TextStyle(
                fontSize: 8,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCompleteBanner(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('🎉 Puzzle Complete!',
              style:
                  theme.textTheme.titleLarge?.copyWith(color: Colors.green.shade800)),
          const SizedBox(height: 4),
          Text(
            'Time: ${_service.elapsedFormatted} • Mistakes: ${_service.mistakes} • Hints: ${_service.hintsUsed}',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: Colors.green.shade700),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberPad(ThemeData theme, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _actionButton(
                icon: Icons.undo,
                label: 'Clear',
                onTap: () => setState(() => _service.clearCell()),
              ),
              const SizedBox(width: 12),
              _actionButton(
                icon: _service.pencilMode ? Icons.edit : Icons.edit_outlined,
                label: 'Pencil',
                active: _service.pencilMode,
                onTap: () => setState(
                    () => _service.pencilMode = !_service.pencilMode),
              ),
              const SizedBox(width: 12),
              _actionButton(
                icon: Icons.lightbulb_outline,
                label: 'Hint',
                onTap: () {
                  final used = _service.useHint();
                  setState(() {});
                  if (!used && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Select an empty or wrong cell first'),
                          duration: Duration(seconds: 1)),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Number buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(9, (i) {
              final n = i + 1;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      minimumSize: Size.zero,
                    ),
                    onPressed: _service.isComplete
                        ? null
                        : () {
                            final correct = _service.placeNumber(n);
                            setState(() {});
                            if (!correct &&
                                !_service.pencilMode &&
                                _service.playerGrid[_service.selectedRow]
                                        [_service.selectedCol] !=
                                    0 &&
                                mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Wrong number!'),
                                    backgroundColor: Colors.red,
                                    duration: Duration(milliseconds: 800)),
                              );
                            }
                          },
                    child: Text('$n', style: const TextStyle(fontSize: 18)),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    bool active = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: active ? Colors.blue : null),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: active ? Colors.blue : null)),
          ],
        ),
      ),
    );
  }
}
