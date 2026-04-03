import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/services/cron_expression_service.dart';

/// Interactive Cron Expression Builder with visual field selectors,
/// presets, human-readable description, and next-run preview.
class CronExpressionScreen extends StatefulWidget {
  const CronExpressionScreen({super.key});

  @override
  State<CronExpressionScreen> createState() => _CronExpressionScreenState();
}

class _CronExpressionScreenState extends State<CronExpressionScreen> {
  final _expressionController = TextEditingController(text: '* * * * *');
  List<String> _fields = ['*', '*', '*', '*', '*'];
  String _description = '';
  List<DateTime> _nextRuns = [];

  @override
  void initState() {
    super.initState();
    _update();
  }

  @override
  void dispose() {
    _expressionController.dispose();
    super.dispose();
  }

  void _update() {
    final expr = CronExpressionService.build(_fields);
    _expressionController.text = expr;
    setState(() {
      _description = CronExpressionService.describe(expr);
      _nextRuns = CronExpressionService.nextOccurrences(expr, DateTime.now(), count: 5);
    });
  }

  void _parseFromText() {
    final parsed = CronExpressionService.parse(_expressionController.text);
    if (parsed != null) {
      setState(() {
        _fields = parsed;
      });
      _update();
    }
  }

  void _applyPreset(String expr) {
    final parsed = CronExpressionService.parse(expr);
    if (parsed != null) {
      _fields = parsed;
      _update();
    }
  }

  void _copyExpression() {
    Clipboard.setData(ClipboardData(text: _expressionController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Cron Expression Builder')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Expression display
          Card(
            color: isDark ? Colors.grey[900] : Colors.blueGrey[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _expressionController,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            labelText: 'Cron Expression',
                            hintText: '* * * * *',
                          ),
                          onSubmitted: (_) => _parseFromText(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: _parseFromText,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Parse',
                      ),
                      IconButton(
                        onPressed: _copyExpression,
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Field labels
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (i) => Expanded(
                      child: Text(
                        CronExpressionService.fieldNames[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withAlpha(60),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.translate, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _description,
                            style: TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Field editors
          ...List.generate(5, (i) => _buildFieldEditor(i, theme)),

          const SizedBox(height: 16),

          // Presets
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Presets', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CronExpressionService.presets.entries.map((e) {
                      final isSelected = _expressionController.text == e.key;
                      return ActionChip(
                        label: Text(e.value, style: const TextStyle(fontSize: 12)),
                        backgroundColor: isSelected ? theme.colorScheme.primaryContainer : null,
                        onPressed: () => _applyPreset(e.key),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Next runs
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.schedule, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Next 5 Runs', style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_nextRuns.isEmpty)
                    const Text('No upcoming runs found within the next year.')
                  else
                    ...List.generate(_nextRuns.length, (i) {
                      final dt = _nextRuns[i];
                      final dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
                      final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                      final dow = dayNames[dt.weekday % 7];
                      final mon = monthNames[dt.month - 1];
                      final formatted = '$dow, $mon ${dt.day}, ${dt.year} at '
                          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: theme.colorScheme.primary.withAlpha(30),
                              child: Text('${i + 1}', style: TextStyle(fontSize: 11, color: theme.colorScheme.primary)),
                            ),
                            const SizedBox(width: 12),
                            Text(formatted, style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFieldEditor(int index, ThemeData theme) {
    final range = CronExpressionService.fieldRanges[index];
    final current = _fields[index];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  CronExpressionService.fieldNames[index],
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  current,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _fieldOption(index, '*', 'Every', theme),
                // Common steps
                if (index == 0) ...[
                  _fieldOption(index, '*/5', 'Every 5', theme),
                  _fieldOption(index, '*/10', 'Every 10', theme),
                  _fieldOption(index, '*/15', 'Every 15', theme),
                  _fieldOption(index, '*/30', 'Every 30', theme),
                  _fieldOption(index, '0', '0', theme),
                  _fieldOption(index, '30', '30', theme),
                ],
                if (index == 1) ...[
                  _fieldOption(index, '*/2', 'Every 2h', theme),
                  _fieldOption(index, '*/4', 'Every 4h', theme),
                  _fieldOption(index, '*/6', 'Every 6h', theme),
                  for (final h in [0, 6, 9, 12, 18, 22])
                    _fieldOption(index, '$h', '$h:00', theme),
                ],
                if (index == 2) ...[
                  _fieldOption(index, '1', '1st', theme),
                  _fieldOption(index, '15', '15th', theme),
                  _fieldOption(index, '1,15', '1st & 15th', theme),
                ],
                if (index == 3) ...[
                  for (var m = 1; m <= 12; m++)
                    _fieldOption(index, '$m', CronExpressionService.monthNames[m - 1], theme),
                ],
                if (index == 4) ...[
                  for (var d = 0; d <= 6; d++)
                    _fieldOption(index, '$d', CronExpressionService.dayNames[d], theme),
                  _fieldOption(index, '1-5', 'Weekdays', theme),
                  _fieldOption(index, '0,6', 'Weekends', theme),
                ],
              ],
            ),
            const SizedBox(height: 8),
            // Custom input
            SizedBox(
              height: 36,
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Custom (e.g. ${range[0]}-${range[1]}, */2, 1,3,5)',
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: const OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    _fields[index] = value;
                    _update();
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldOption(int index, String value, String label, ThemeData theme) {
    final isSelected = _fields[index] == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      selected: isSelected,
      onSelected: (_) {
        _fields[index] = value;
        _update();
      },
      visualDensity: VisualDensity.compact,
    );
  }
}
