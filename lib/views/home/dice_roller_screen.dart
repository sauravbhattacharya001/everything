import 'package:flutter/material.dart';
import 'dart:math';
import '../../core/services/dice_roller_service.dart';

/// A dice roller with multiple die types, count selector, modifier,
/// roll animation, and history log.
class DiceRollerScreen extends StatefulWidget {
  const DiceRollerScreen({super.key});

  @override
  State<DiceRollerScreen> createState() => _DiceRollerScreenState();
}

class _DiceRollerScreenState extends State<DiceRollerScreen>
    with SingleTickerProviderStateMixin {
  final _service = DiceRollerService();
  DieType _selectedDie = DieType.d6;
  int _count = 1;
  int _modifier = 0;
  RollResult? _lastResult;
  bool _rolling = false;
  late AnimationController _animController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _roll() {
    setState(() => _rolling = true);
    _animController.forward(from: 0).then((_) {
      final result = _service.roll(
        sides: _selectedDie.sides,
        count: _count,
        modifier: _modifier,
      );
      setState(() {
        _lastResult = result;
        _rolling = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dice Roller'),
        actions: [
          if (_service.history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear history',
              onPressed: () => setState(() {
                _service.clearHistory();
                _lastResult = null;
              }),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Die type selector
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Die Type',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: DieType.values.map((dt) {
                        final selected = dt == _selectedDie;
                        return ChoiceChip(
                          label: Text(dt.label),
                          selected: selected,
                          onSelected: (_) =>
                              setState(() => _selectedDie = dt),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Count & modifier
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Count
                    Expanded(
                      child: Column(
                        children: [
                          Text('Count',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _count > 1
                                    ? () => setState(() => _count--)
                                    : null,
                              ),
                              Text('$_count',
                                  style: theme.textTheme.headlineSmall),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _count < 20
                                    ? () => setState(() => _count++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey[300],
                    ),
                    // Modifier
                    Expanded(
                      child: Column(
                        children: [
                          Text('Modifier',
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: _modifier > -20
                                    ? () => setState(() => _modifier--)
                                    : null,
                              ),
                              Text(
                                _modifier >= 0
                                    ? '+$_modifier'
                                    : '$_modifier',
                                style: theme.textTheme.headlineSmall,
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: _modifier < 20
                                    ? () => setState(() => _modifier++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Roll button & notation
            Text(
              '${_count}d${_selectedDie.sides}${_modifier != 0 ? (_modifier > 0 ? "+$_modifier" : "$_modifier") : ""}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final shake = sin(_shakeAnimation.value * pi * 4) * 8 *
                    (1 - _shakeAnimation.value);
                return Transform.translate(
                  offset: Offset(shake, 0),
                  child: child,
                );
              },
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _rolling ? null : _roll,
                  icon: const Icon(Icons.casino, size: 28),
                  label: Text(_rolling ? 'Rolling...' : 'Roll!',
                      style: const TextStyle(fontSize: 20)),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Result display
            if (_lastResult != null) ...[
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '${_lastResult!.total}',
                        style: theme.textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: [
                          for (final die in _lastResult!.dice)
                            Chip(
                              label: Text('${die.result}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              avatar: Text('d${die.sides}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[600],
                                  )),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (_lastResult!.modifier != 0)
                            Chip(
                              label: Text(
                                _lastResult!.modifier > 0
                                    ? '+${_lastResult!.modifier}'
                                    : '${_lastResult!.modifier}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              avatar: const Icon(Icons.add, size: 14),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // History
            if (_service.history.length > 1) ...[
              Text('Roll History',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...(_service.history.skip(1).take(10).map((r) => ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      child: Text('${r.total}',
                          style: const TextStyle(fontSize: 12)),
                    ),
                    title: Text(r.notation),
                    subtitle: Text(
                      r.dice.map((d) => '${d.result}').join(', ') +
                          (r.modifier != 0
                              ? ' ${r.modifier > 0 ? "+" : ""}${r.modifier}'
                              : ''),
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                    trailing: Text(
                      '${r.timestamp.hour.toString().padLeft(2, '0')}:${r.timestamp.minute.toString().padLeft(2, '0')}:${r.timestamp.second.toString().padLeft(2, '0')}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500]),
                    ),
                  ))),
            ],
          ],
        ),
      ),
    );
  }
}
