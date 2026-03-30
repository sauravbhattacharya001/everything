import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/pace_calculator_service.dart';

/// Running / cycling pace calculator with split table.
class PaceCalculatorScreen extends StatefulWidget {
  const PaceCalculatorScreen({super.key});

  @override
  State<PaceCalculatorScreen> createState() => _PaceCalculatorScreenState();
}

enum _CalcMode { paceFromTime, timeFromPace, distanceFromPace }

class _PaceCalculatorScreenState extends State<PaceCalculatorScreen> {
  _CalcMode _mode = _CalcMode.paceFromTime;
  bool _useMiles = false;

  final _distanceController = TextEditingController();
  final _hoursController = TextEditingController();
  final _minutesController = TextEditingController();
  final _secondsController = TextEditingController();
  final _paceMinController = TextEditingController();
  final _paceSecController = TextEditingController();

  String? _selectedPreset;
  PaceResult? _result;
  List<SplitEntry>? _splits;
  bool _showSplits = false;

  @override
  void dispose() {
    _distanceController.dispose();
    _hoursController.dispose();
    _minutesController.dispose();
    _secondsController.dispose();
    _paceMinController.dispose();
    _paceSecController.dispose();
    super.dispose();
  }

  void _setPreset(String name, double km) {
    setState(() {
      _selectedPreset = name;
      final display = _useMiles ? (km / 1.60934) : km;
      _distanceController.text = display.toStringAsFixed(2);
    });
    _calculate();
  }

  Duration? _parseDuration() {
    final h = int.tryParse(_hoursController.text.trim()) ?? 0;
    final m = int.tryParse(_minutesController.text.trim()) ?? 0;
    final s = int.tryParse(_secondsController.text.trim()) ?? 0;
    if (h == 0 && m == 0 && s == 0) return null;
    return Duration(hours: h, minutes: m, seconds: s);
  }

  double? _parsePace() {
    final m = int.tryParse(_paceMinController.text.trim()) ?? 0;
    final s = int.tryParse(_paceSecController.text.trim()) ?? 0;
    if (m == 0 && s == 0) return null;
    return m + s / 60.0;
  }

  double? _parseDistance() {
    final d = double.tryParse(_distanceController.text.trim());
    if (d == null || d <= 0) return null;
    return _useMiles ? d * 1.60934 : d;
  }

  void _calculate() {
    PaceResult? result;
    try {
      switch (_mode) {
        case _CalcMode.paceFromTime:
          final dist = _parseDistance();
          final time = _parseDuration();
          if (dist != null && time != null) {
            result = PaceCalculatorService.fromDistanceAndTime(
              distanceKm: dist,
              totalTime: time,
              useMiles: _useMiles,
            );
          }
          break;
        case _CalcMode.timeFromPace:
          final dist = _parseDistance();
          final pace = _parsePace();
          if (dist != null && pace != null) {
            result = PaceCalculatorService.fromDistanceAndPace(
              distanceKm: dist,
              paceMinPerUnit: pace,
              useMiles: _useMiles,
            );
          }
          break;
        case _CalcMode.distanceFromPace:
          final time = _parseDuration();
          final pace = _parsePace();
          if (time != null && pace != null) {
            result = PaceCalculatorService.fromTimeAndPace(
              totalTime: time,
              paceMinPerUnit: pace,
              useMiles: _useMiles,
            );
          }
          break;
      }
    } catch (_) {}

    List<SplitEntry>? splits;
    if (result != null && result.distanceKm > 0) {
      splits = PaceCalculatorService.generateSplits(
        distanceKm: result.distanceKm,
        totalTime: result.totalTime,
        useMiles: _useMiles,
      );
    }

    setState(() {
      _result = result;
      _splits = splits;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unitLabel = _useMiles ? 'mi' : 'km';

    return Scaffold(
      appBar: AppBar(title: const Text('Pace Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Unit toggle
          Row(
            children: [
              const Text('Unit: '),
              ChoiceChip(
                label: const Text('km'),
                selected: !_useMiles,
                onSelected: (_) => setState(() {
                  _useMiles = false;
                  _selectedPreset = null;
                  _calculate();
                }),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('mi'),
                selected: _useMiles,
                onSelected: (_) => setState(() {
                  _useMiles = true;
                  _selectedPreset = null;
                  _calculate();
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mode selector
          Text('Calculate', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<_CalcMode>(
            segments: const [
              ButtonSegment(value: _CalcMode.paceFromTime, label: Text('Pace')),
              ButtonSegment(value: _CalcMode.timeFromPace, label: Text('Time')),
              ButtonSegment(value: _CalcMode.distanceFromPace, label: Text('Distance')),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() {
              _mode = s.first;
              _result = null;
              _splits = null;
            }),
          ),
          const SizedBox(height: 20),

          // Race presets
          if (_mode != _CalcMode.distanceFromPace) ...[
            Text('Quick Distances', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: PaceCalculatorService.raceDistances.entries.map((e) {
                return ChoiceChip(
                  label: Text(e.key),
                  selected: _selectedPreset == e.key,
                  onSelected: (_) => _setPreset(e.key, e.value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Distance input
          if (_mode != _CalcMode.distanceFromPace)
            TextField(
              controller: _distanceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
              decoration: InputDecoration(
                labelText: 'Distance ($unitLabel)',
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) {
                _selectedPreset = null;
                _calculate();
              },
            ),

          // Time input
          if (_mode != _CalcMode.timeFromPace) ...[
            const SizedBox(height: 16),
            Text('Time', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hoursController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Hours',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _minutesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Min',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _secondsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Sec',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ),
              ],
            ),
          ],

          // Pace input
          if (_mode != _CalcMode.paceFromTime) ...[
            const SizedBox(height: 16),
            Text('Pace (per $unitLabel)', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _paceMinController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Min',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _paceSecController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Sec',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => _calculate(),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Results
          if (_result != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Results', style: theme.textTheme.titleMedium),
                    const Divider(),
                    _resultRow(
                      'Distance',
                      '${_result!.displayDistance.toStringAsFixed(2)} $unitLabel',
                    ),
                    _resultRow(
                      'Time',
                      PaceCalculatorService.formatDuration(_result!.totalTime),
                    ),
                    _resultRow(
                      'Pace',
                      '${PaceCalculatorService.formatPace(_result!.paceMinPerUnit)} /$unitLabel',
                    ),
                    _resultRow(
                      'Speed',
                      '${_result!.displaySpeed.toStringAsFixed(1)} $unitLabel/h',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Splits toggle
            if (_splits != null && _splits!.isNotEmpty)
              Column(
                children: [
                  TextButton.icon(
                    onPressed: () => setState(() => _showSplits = !_showSplits),
                    icon: Icon(_showSplits ? Icons.expand_less : Icons.expand_more),
                    label: Text(_showSplits ? 'Hide Splits' : 'Show Splits'),
                  ),
                  if (_showSplits)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: Text('#', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Split', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text('Elapsed', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const Divider(),
                            ..._splits!.map((s) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Expanded(flex: 1, child: Text('${s.splitNumber}')),
                                  Expanded(flex: 2, child: Text(PaceCalculatorService.formatDuration(s.splitTime))),
                                  Expanded(flex: 2, child: Text(PaceCalculatorService.formatDuration(s.elapsedTime))),
                                ],
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
