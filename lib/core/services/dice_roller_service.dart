import 'dart:math';

/// Represents a single die with a configurable number of sides.
class Die {
  final int sides;
  final int result;

  const Die({required this.sides, required this.result});
}

/// A complete roll result containing all dice rolled.
class RollResult {
  final List<Die> dice;
  final int modifier;
  final DateTime timestamp;

  const RollResult({
    required this.dice,
    this.modifier = 0,
    required this.timestamp,
  });

  int get total => dice.fold(0, (sum, d) => sum + d.result) + modifier;
  int get diceTotal => dice.fold(0, (sum, d) => sum + d.result);
  int get min => dice.fold(0, (sum, _) => sum) + dice.length; // each die min 1
  int get max => dice.fold(0, (sum, d) => sum + d.sides) + modifier;

  /// Standard notation like "2d6+3"
  String get notation {
    // Group dice by sides
    final groups = <int, int>{};
    for (final d in dice) {
      groups[d.sides] = (groups[d.sides] ?? 0) + 1;
    }
    final parts = groups.entries.map((e) => '${e.value}d${e.key}').join(' + ');
    if (modifier > 0) return '$parts + $modifier';
    if (modifier < 0) return '$parts - ${modifier.abs()}';
    return parts;
  }
}

/// Common die types used in tabletop gaming.
enum DieType {
  d4(4, 'D4'),
  d6(6, 'D6'),
  d8(8, 'D8'),
  d10(10, 'D10'),
  d12(12, 'D12'),
  d20(20, 'D20'),
  d100(100, 'D100');

  final int sides;
  final String label;
  const DieType(this.sides, this.label);
}

/// Service for rolling dice and tracking history.
class DiceRollerService {
  final _random = Random();
  final List<RollResult> _history = [];

  List<RollResult> get history => List.unmodifiable(_history);

  /// Roll [count] dice with [sides] each, plus optional [modifier].
  RollResult roll({
    int sides = 6,
    int count = 1,
    int modifier = 0,
  }) {
    final dice = List.generate(
      count,
      (_) => Die(sides: sides, result: _random.nextInt(sides) + 1),
    );
    final result = RollResult(
      dice: dice,
      modifier: modifier,
      timestamp: DateTime.now(),
    );
    _history.insert(0, result);
    if (_history.length > 50) _history.removeLast();
    return result;
  }

  /// Roll advantage (2d20, take highest).
  RollResult rollAdvantage() {
    final dice = List.generate(
      2,
      (_) => Die(sides: 20, result: _random.nextInt(20) + 1),
    );
    return RollResult(dice: dice, timestamp: DateTime.now());
  }

  /// Roll disadvantage (2d20, take lowest).
  RollResult rollDisadvantage() {
    final dice = List.generate(
      2,
      (_) => Die(sides: 20, result: _random.nextInt(20) + 1),
    );
    return RollResult(dice: dice, timestamp: DateTime.now());
  }

  void clearHistory() => _history.clear();
}
