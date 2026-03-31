import 'package:flutter/material.dart';
import '../../core/services/sleep_calculator_service.dart';

/// Sleep cycle calculator — find optimal bedtimes or wake-up times
/// based on 90-minute sleep cycles.
class SleepCalculatorScreen extends StatefulWidget {
  const SleepCalculatorScreen({super.key});

  @override
  State<SleepCalculatorScreen> createState() => _SleepCalculatorScreenState();
}

class _SleepCalculatorScreenState extends State<SleepCalculatorScreen> {
  /// true = "I want to wake up at …", false = "I'm going to bed at …"
  bool _modeWakeUp = true;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  List<SleepSuggestion> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _calculate();
  }

  void _calculate() {
    final now = DateTime.now();
    final target = DateTime(
      now.year,
      now.month,
      now.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    setState(() {
      _suggestions = _modeWakeUp
          ? SleepCalculatorService.bedtimesForWakeUp(target)
          : SleepCalculatorService.wakeTimesForBedtime(target);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      _selectedTime = picked;
      _calculate();
    }
  }

  void _toggleMode() {
    _modeWakeUp = !_modeWakeUp;
    _calculate();
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mode toggle
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Wake-up time'),
                  icon: Icon(Icons.alarm),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Bedtime'),
                  icon: Icon(Icons.bedtime),
                ),
              ],
              selected: {_modeWakeUp},
              onSelectionChanged: (_) => _toggleMode(),
            ),
            const SizedBox(height: 24),

            // Time picker card
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: _pickTime,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 24,
                    horizontal: 16,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _modeWakeUp
                            ? 'I want to wake up at'
                            : "I'm going to bed at",
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedTime.format(context),
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap to change',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Results header
            Text(
              _modeWakeUp
                  ? 'Go to sleep at one of these times:'
                  : 'Set your alarm for one of these times:',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Includes ~14 min to fall asleep',
              style: theme.textTheme.bodySmall?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 16),

            // Suggestion cards
            ..._suggestions.map((s) {
              final quality = SleepCalculatorService.qualityLabel(s.cycles);
              final color =
                  Color(SleepCalculatorService.qualityColorValue(s.cycles));
              final hours = s.sleepHours.toStringAsFixed(1);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(
                      '${s.cycles}',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    _formatTime(s.time),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '$hours hrs · ${s.cycles} cycles · $quality',
                  ),
                  trailing: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      quality,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // Info card
            Card(
              color: cs.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: cs.outline),
                        const SizedBox(width: 8),
                        Text(
                          'How it works',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sleep happens in ~90-minute cycles. Waking up between '
                      'cycles (not during one) helps you feel more refreshed. '
                      'Most adults need 5–6 cycles (7.5–9 hours) per night.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
