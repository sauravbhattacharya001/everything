import 'dart:async';
import 'dart:math';

/// Direction the snake is moving.
enum SnakeDirection { up, down, left, right }

/// A point on the grid.
class GridPoint {
  final int x;
  final int y;
  const GridPoint(this.x, this.y);

  @override
  bool operator ==(Object other) =>
      other is GridPoint && other.x == x && other.y == y;

  @override
  int get hashCode => x.hashCode ^ (y.hashCode << 16);
}

/// Service that manages Snake game logic.
///
/// Maintains a grid, snake body, food position, score, and
/// handles movement, collision detection, and growth.
class SnakeGameService {
  static const int gridSize = 20;

  List<GridPoint> snake = [];
  GridPoint food = const GridPoint(0, 0);
  SnakeDirection direction = SnakeDirection.right;
  SnakeDirection _nextDirection = SnakeDirection.right;
  int score = 0;
  int highScore = 0;
  bool isGameOver = false;
  bool isPlaying = false;
  final _rng = Random();

  SnakeGameService() {
    _initGame();
  }

  void _initGame() {
    final mid = gridSize ~/ 2;
    snake = [
      GridPoint(mid, mid),
      GridPoint(mid - 1, mid),
      GridPoint(mid - 2, mid),
    ];
    direction = SnakeDirection.right;
    _nextDirection = SnakeDirection.right;
    score = 0;
    isGameOver = false;
    isPlaying = false;
    _spawnFood();
  }

  void newGame() {
    _initGame();
  }

  /// Change direction (prevents 180-degree turns).
  void setDirection(SnakeDirection dir) {
    if (_isOpposite(dir, direction)) return;
    _nextDirection = dir;
  }

  bool _isOpposite(SnakeDirection a, SnakeDirection b) {
    return (a == SnakeDirection.up && b == SnakeDirection.down) ||
        (a == SnakeDirection.down && b == SnakeDirection.up) ||
        (a == SnakeDirection.left && b == SnakeDirection.right) ||
        (a == SnakeDirection.right && b == SnakeDirection.left);
  }

  /// Advance the snake one step. Returns true if still alive.
  bool tick() {
    if (isGameOver) return false;

    direction = _nextDirection;

    final head = snake.first;
    late GridPoint newHead;

    switch (direction) {
      case SnakeDirection.up:
        newHead = GridPoint(head.x, head.y - 1);
        break;
      case SnakeDirection.down:
        newHead = GridPoint(head.x, head.y + 1);
        break;
      case SnakeDirection.left:
        newHead = GridPoint(head.x - 1, head.y);
        break;
      case SnakeDirection.right:
        newHead = GridPoint(head.x + 1, head.y);
        break;
    }

    // Wall collision
    if (newHead.x < 0 ||
        newHead.x >= gridSize ||
        newHead.y < 0 ||
        newHead.y >= gridSize) {
      isGameOver = true;
      isPlaying = false;
      if (score > highScore) highScore = score;
      return false;
    }

    // Self collision
    if (snake.contains(newHead)) {
      isGameOver = true;
      isPlaying = false;
      if (score > highScore) highScore = score;
      return false;
    }

    snake.insert(0, newHead);

    if (newHead == food) {
      score += 10;
      _spawnFood();
    } else {
      snake.removeLast();
    }

    return true;
  }

  void _spawnFood() {
    final emptySpots = <GridPoint>[];
    for (var x = 0; x < gridSize; x++) {
      for (var y = 0; y < gridSize; y++) {
        final p = GridPoint(x, y);
        if (!snake.contains(p)) {
          emptySpots.add(p);
        }
      }
    }
    if (emptySpots.isEmpty) return;
    food = emptySpots[_rng.nextInt(emptySpots.length)];
  }

  /// Speed increases as score grows (milliseconds per tick).
  int get tickDuration {
    final base = 200;
    final speedUp = (score ~/ 50) * 20;
    return (base - speedUp).clamp(80, 200);
  }
}
