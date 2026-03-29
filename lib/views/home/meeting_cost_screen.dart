import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/services/meeting_cost_service.dart';

/// A meeting cost calculator that shows the real-time cost of meetings
/// based on attendee count, average hourly rate, and duration.
/// Includes live ticker mode, presets, and recurrence cost projections.
class MeetingCostScreen extends StatefulWidget {
  const MeetingCostScreen({super.key});

  @override
  State<MeetingCostScreen> createState() => _MeetingCostScreenState();
}

class _MeetingCostScreenState extends State<MeetingCostScreen> {
  int _attendees = 5;
  double _hourlyRate = 75.0;
  int _durationMinutes = 30;

  // Live ticker
  bool _tickerRunning = false;
  int _elapsedSeconds = 0;
  Timer? _timer;

  final _attendeesController = TextEditingController(text: '5');
  final _rateController = TextEditingController(text: '75');
  final _durationController = TextEditingController(text: '30');

  @override
  void dispose() {
    _timer?.cancel();
    _attendeesController.dispose();
    _rateController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _startTicker() {
    setState(() {
      _tickerRunning = true;
      _elapsedSeconds = 0;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsedSeconds++);
    });
  }

  void _stopTicker() {
    _timer?.cancel();
    setState(() => _tickerRunning = false);
  }

  void _resetTicker() {
    _timer?.cancel();
    setState(() {
      _tickerRunning = false;
      _elapsedSeconds = 0;
    });
  }

  double get _liveCost {
    final costPerSecond =
        MeetingCostService.costPerMinute(
          attendees: _attendees,
          hourlyRate: _hourlyRate,
        ) /
        60.0;
    return costPerSecond * _elapsedSeconds;
  }

  void _applyPreset(MeetingPreset preset) {
    setState(() {
      _attendees = preset.attendees;
      _durationMinutes = preset.durationMinutes;
      _attendeesController.text = preset.attendees.toString();
      _durationController.text = preset.durationMinutes.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = MeetingCostService.totalCost(
      attendees: _attendees,
      hourlyRate: _hourlyRate,
      durationMinutes: _durationMinutes,
    );
    final perMin = MeetingCostService.costPerMinute(
      attendees: _attendees,
      hourlyRate: _hourlyRate,
    );
    final perAttendee = MeetingCostService.costPerAttendee(
      hourlyRate: _hourlyRate,
      durationMinutes: _durationMinutes,
    );
    final annualWeekly = MeetingCostService.annualCostWeekly(
      attendees: _attendees,
      hourlyRate: _hourlyRate,
      durationMinutes: _durationMinutes,
    );
    final annualDaily = MeetingCostService.annualCostDaily(
      attendees: _attendees,
      hourlyRate: _hourlyRate,
      durationMinutes: _durationMinutes,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Meeting Cost Calculator')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Live ticker section
          Card(
            color: _tickerRunning
                ? theme.colorScheme.errorContainer
                : theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    _tickerRunning ? 'Meeting in progress...' : 'Live Ticker',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: _tickerRunning
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    MeetingCostService.formatCurrency(_liveCost),
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: _tickerRunning
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onPrimaryContainer,
                      fontFamily: 'monospace',
                    ),
                  ),
                  Text(
                    _formatDuration(_elapsedSeconds),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: _tickerRunning
                          ? theme.colorScheme.onErrorContainer
                              .withValues(alpha: 0.7)
                          : theme.colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.7),
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!_tickerRunning)
                        FilledButton.icon(
                          onPressed: _startTicker,
                          icon: const Icon(Icons.play_arrow),
                          label: const Text('Start'),
                        )
                      else
                        FilledButton.icon(
                          onPressed: _stopTicker,
                          icon: const Icon(Icons.stop),
                          label: const Text('Stop'),
                        ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _elapsedSeconds > 0 ? _resetTicker : null,
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Presets
          Text('Quick Presets', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: MeetingCostService.presets.map((p) {
              return ActionChip(
                label: Text(p.name, style: const TextStyle(fontSize: 12)),
                avatar: Text('${p.attendees}', style: const TextStyle(fontSize: 10)),
                onPressed: () => _applyPreset(p),
              );
            }).toList(),
          ),
          const Divider(height: 32),

          // Input fields
          Text('Meeting Settings', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _attendeesController,
                  decoration: const InputDecoration(
                    labelText: 'Attendees',
                    prefixIcon: Icon(Icons.people),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final n = int.tryParse(v);
                    if (n != null && n > 0) setState(() => _attendees = n);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _rateController,
                  decoration: const InputDecoration(
                    labelText: 'Avg \$/hr',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (v) {
                    final r = double.tryParse(v);
                    if (r != null && r > 0) setState(() => _hourlyRate = r);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              prefixIcon: Icon(Icons.schedule),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final d = int.tryParse(v);
              if (d != null && d > 0) setState(() => _durationMinutes = d);
            },
          ),
          const SizedBox(height: 8),

          // Duration slider
          Slider(
            value: _durationMinutes.toDouble().clamp(5, 240),
            min: 5,
            max: 240,
            divisions: 47,
            label: '$_durationMinutes min',
            onChanged: (v) {
              setState(() {
                _durationMinutes = v.round();
                _durationController.text = _durationMinutes.toString();
              });
            },
          ),

          const Divider(height: 32),

          // Cost breakdown
          Text('Cost Breakdown', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),

          _costCard(
            theme,
            'Total Meeting Cost',
            MeetingCostService.formatCurrency(total),
            Icons.payments,
            theme.colorScheme.primary,
          ),
          _costCard(
            theme,
            'Cost Per Minute',
            '${MeetingCostService.formatCurrency(perMin)}/min',
            Icons.timer,
            Colors.orange,
          ),
          _costCard(
            theme,
            'Cost Per Attendee',
            MeetingCostService.formatCurrency(perAttendee),
            Icons.person,
            Colors.teal,
          ),

          const Divider(height: 32),
          Text('If This Meeting Recurs...', style: theme.textTheme.titleMedium),
          const SizedBox(height: 12),
          _costCard(
            theme,
            'Weekly (52x/year)',
            '${MeetingCostService.formatCurrency(annualWeekly)}/year',
            Icons.repeat,
            Colors.deepPurple,
          ),
          _costCard(
            theme,
            'Daily (260x/year)',
            '${MeetingCostService.formatCurrency(annualDaily)}/year',
            Icons.repeat_one,
            Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _costCard(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: iconColor.withValues(alpha: 0.15),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(label, style: theme.textTheme.bodySmall),
        trailing: Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
