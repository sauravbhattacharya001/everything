import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/services/age_calculator_service.dart';

/// Age Calculator screen — enter birth date, see exact age breakdown plus
/// fun life statistics (heartbeats, breaths, steps, etc.).
class AgeCalculatorScreen extends StatefulWidget {
  const AgeCalculatorScreen({super.key});

  @override
  State<AgeCalculatorScreen> createState() => _AgeCalculatorScreenState();
}

class _AgeCalculatorScreenState extends State<AgeCalculatorScreen> {
  DateTime? _birthDate;
  AgeResult? _result;

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select your birth date',
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _result = AgeCalculatorService.calculate(picked, DateTime.now());
      });
    }
  }

  String _formatNumber(int n) {
    if (n >= 1000000000) {
      return '${(n / 1000000000).toStringAsFixed(1)}B';
    } else if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    } else if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}K';
    }
    return NumberFormat('#,###').format(n);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Age Calculator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date picker card
            Card(
              child: InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(Icons.cake, size: 32, color: cs.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Birth Date',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _birthDate != null
                                  ? DateFormat.yMMMMd().format(_birthDate!)
                                  : 'Tap to select',
                              style: theme.textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.edit_calendar, color: cs.primary),
                    ],
                  ),
                ),
              ),
            ),

            if (_result != null) ...[
              const SizedBox(height: 20),

              // Main age display
              Card(
                color: cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'Your Age',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _result!.formattedAge,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: cs.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.celebration, size: 18, color: cs.onPrimaryContainer),
                          const SizedBox(width: 6),
                          Text(
                            '${_result!.daysUntilBirthday} days until next birthday',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cs.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Info chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  _infoChip(Icons.today, 'Born on ${_result!.dayOfWeekBorn}', cs),
                  _infoChip(Icons.auto_awesome, _result!.zodiacSign, cs),
                ],
              ),

              const SizedBox(height: 20),

              // Time alive breakdown
              Text(
                'Time Alive',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildGrid([
                _StatItem('Days', _formatNumber(_result!.totalDays), Icons.calendar_today),
                _StatItem('Weeks', _formatNumber(_result!.totalWeeks), Icons.date_range),
                _StatItem('Hours', _formatNumber(_result!.totalHours), Icons.access_time),
              ]),

              const SizedBox(height: 20),

              // Fun life stats
              Text(
                'Fun Life Stats',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildGrid([
                _StatItem('Heartbeats', _formatNumber(_result!.heartbeats), Icons.favorite),
                _StatItem('Breaths', _formatNumber(_result!.breaths), Icons.air),
                _StatItem('Sleep Hours', _formatNumber(_result!.sleepHours), Icons.bedtime),
                _StatItem('Meals Eaten', _formatNumber(_result!.mealsEaten), Icons.restaurant),
                _StatItem('Steps Walked', _formatNumber(_result!.stepsWalked), Icons.directions_walk),
                _StatItem('Words Spoken', _formatNumber(_result!.wordsSpoken), Icons.chat_bubble),
              ]),
            ] else ...[
              const SizedBox(height: 60),
              Center(
                child: Column(
                  children: [
                    Icon(Icons.cake_outlined, size: 64, color: cs.outline),
                    const SizedBox(height: 12),
                    Text(
                      'Select your birth date to see your age\nbreakdown and fun life statistics!',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, ColorScheme cs) {
    return Chip(
      avatar: Icon(icon, size: 18, color: cs.primary),
      label: Text(label),
    );
  }

  Widget _buildGrid(List<_StatItem> items) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: items.map((item) {
        final cs = Theme.of(context).colorScheme;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: cs.primary, size: 22),
                const SizedBox(height: 6),
                Text(
                  item.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  const _StatItem(this.label, this.value, this.icon);
}
