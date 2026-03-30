/// Tic Tac Toe service — game logic with optional AI opponent.
///
/// Supports two modes:
/// - Two-player (local): players alternate turns
/// - vs AI: simple minimax-based AI opponent
class TicTacToeService {
  List<String> _board = List.filled(9, '');
  String _currentPlayer = 'X';
  bool _vsAi = false;
  bool _gameOver = false;
  String? _winner;

  // Getters
  List<String> get board => List.unmodifiable(_board);
  String get currentPlayer => _currentPlayer;
  bool get vsAi => _vsAi;
  bool get gameOver => _gameOver;
  String? get winner => _winner;
  bool get isDraw => _gameOver && _winner == null;

  void setVsAi(bool value) {
    _vsAi = value;
    reset();
  }

  void reset() {
    _board = List.filled(9, '');
    _currentPlayer = 'X';
    _gameOver = false;
    _winner = null;
  }

  /// Returns true if the move was valid and applied.
  bool makeMove(int index) {
    if (_gameOver || index < 0 || index > 8 || _board[index].isNotEmpty) {
      return false;
    }
    _board[index] = _currentPlayer;
    if (_checkWin(_currentPlayer)) {
      _gameOver = true;
      _winner = _currentPlayer;
      return true;
    }
    if (!_board.contains('')) {
      _gameOver = true;
      return true;
    }
    _currentPlayer = _currentPlayer == 'X' ? 'O' : 'X';

    // AI turn
    if (_vsAi && _currentPlayer == 'O' && !_gameOver) {
      final aiMove = _bestMove();
      if (aiMove != -1) {
        _board[aiMove] = 'O';
        if (_checkWin('O')) {
          _gameOver = true;
          _winner = 'O';
        } else if (!_board.contains('')) {
          _gameOver = true;
        } else {
          _currentPlayer = 'X';
        }
      }
    }
    return true;
  }

  bool _checkWin(String player) {
    const wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
      [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
      [0, 4, 8], [2, 4, 6],            // diagonals
    ];
    return wins.any((w) => w.every((i) => _board[i] == player));
  }

  List<int>? get winningLine {
    const wins = [
      [0, 1, 2], [3, 4, 5], [6, 7, 8],
      [0, 3, 6], [1, 4, 7], [2, 5, 8],
      [0, 4, 8], [2, 4, 6],
    ];
    if (_winner == null) return null;
    for (final w in wins) {
      if (w.every((i) => _board[i] == _winner)) return w;
    }
    return null;
  }

  int _bestMove() {
    int bestScore = -1000;
    int bestIdx = -1;
    for (int i = 0; i < 9; i++) {
      if (_board[i].isEmpty) {
        _board[i] = 'O';
        int score = _minimax(false, 0);
        _board[i] = '';
        if (score > bestScore) {
          bestScore = score;
          bestIdx = i;
        }
      }
    }
    return bestIdx;
  }

  int _minimax(bool isMaximizing, int depth) {
    if (_checkWin('O')) return 10 - depth;
    if (_checkWin('X')) return depth - 10;
    if (!_board.contains('')) return 0;

    if (isMaximizing) {
      int best = -1000;
      for (int i = 0; i < 9; i++) {
        if (_board[i].isEmpty) {
          _board[i] = 'O';
          best = best > _minimax(false, depth + 1)
              ? best
              : _minimax(false, depth + 1);
          _board[i] = '';
        }
      }
      return best;
    } else {
      int best = 1000;
      for (int i = 0; i < 9; i++) {
        if (_board[i].isEmpty) {
          _board[i] = 'X';
          best = best < _minimax(true, depth + 1)
              ? best
              : _minimax(true, depth + 1);
          _board[i] = '';
        }
      }
      return best;
    }
  }
}
