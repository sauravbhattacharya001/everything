import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Date Calculator screen — calculate days between two dates, or
/// add/subtract days from a date. Handy for planning deadlines,
/// trips, or tracking durations.
class DateCalculatorScreen extends StatefulWidget {
  const DateCalculatorScreen({super.key});

  @override
  State<DateCalculatorScreen> createState() => _DateCalculatorScreenState();
}

class _DateCalculatorScreenState extends State<DateCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // ── Difference tab ──
  DateTime? _fromDate;
  DateTime? _toDate;

  // ── Add/Subtract tab ──
  DateTime? _baseDate;
  final TextEditingController _daysController = TextEditingController();
  bool _isAdd = true;
  DateTime? _resultDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _daysController.dispose();
    super.dispose();
  }

  // ── Helpers ──

  Future<DateTime?> _pickDate({DateTime? initial, DateTime? firstDate}) async {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(1900),
      lastDate: DateTime(2200),
    );
  }

  String _fmt(DateTime d) => DateFormat.yMMMMd().format(d);
  String _fmtWeekday(DateTime d) => DateFormat.EEEE().format(d);

  // ── Difference calculation ──

  Map<String, int>? get _diff {
    if (_fromDate == null || _toDate == null) return null;
    final a = _fromDate!.isBefore(_toDate!) ? _fromDate! : _toDate!;
    final b = _fromDate!.isBefore(_toDate!) ? _toDate! : _fromDate!;
    final totalDays = b.difference(a).inDays;
    final weeks = totalDays ~/ 7;
    final remainDays = totalDays % 7;

    // Year/month/day breakdown
    int years = b.year - a.year;
    int months = b.month - a.month;
    int days = b.day - a.day;
    if (days < 0) {
      months--;
      final prevMonth = DateTime(b.year, b.month, 0);
      days += prevMonth.day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    return {
      'totalDays': totalDays,
      'weeks': weeks,
      'remainDays': remainDays,
      'years': years,
      'months': months,
      'days': days,
      'totalHours': totalDays * 24,
    };
  }

  void _computeAddSub() {
    final n = int.tryParse(_daysController.text);
    if (_baseDate == null || n == null) {
      setState(() => _resultDate = null);
      return;
    }
    setState(() {
      _resultDate = _baseDate!.add(Duration(days: _isAdd ? n : -n));
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Date Calculator'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Difference'),
            Tab(text: 'Add / Subtract'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDifferenceTab(theme, cs),
          _buildAddSubTab(theme, cs),
        ],
      ),
    );
  }

  // ── Difference tab ──

  Widget _buildDifferenceTab(ThemeData theme, ColorScheme cs) {
    final diff = _diff;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _datePickerCard(
            label: 'From Date',
            icon: Icons.flight_takeoff,
            date: _fromDate,
            onTap: () async {
              final d = await _pickDate(initial: _fromDate);
              if (d != null) setState(() => _fromDate = d);
            },
            cs: cs,
            theme: theme,
          ),
          const SizedBox(height: 12),
          _datePickerCard(
            label: 'To Date',
            icon: Icons.flight_land,
            date: _toDate,
            onTap: () async {
              final d = await _pickDate(initial: _toDate);
              if (d != null) setState(() => _toDate = d);
            },
            cs: cs,
            theme: theme,
          ),
          if (diff != null) ...[
            const SizedBox(height: 20),
            Card(
              color: cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      '${diff['totalDays']} days',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (diff['years']! > 0 ||
                        diff['months']! > 0 ||
                        diff['days']! > 0)
                      Text(
                        '${diff['years']}y ${diff['months']}m ${diff['days']}d',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildGrid([
              _StatItem('Weeks', '${diff['weeks']}w ${diff['remainDays']}d',
                  Icons.date_range),
              _StatItem(
                  'Hours', '${NumberFormat('#,###').format(diff['totalHours'])}',
                  Icons.access_time),
              _StatItem('Weekdays', '${_countWeekdays()}', Icons.work),
            ]),
          ] else ...[
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Icon(Icons.date_range, size: 64, color: cs.outline),
                  const SizedBox(height: 12),
                  Text(
                    'Pick two dates to see the\ndifference between them',
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
    );
  }

  int _countWeekdays() {
    if (_fromDate == null || _toDate == null) return 0;
    final a = _fromDate!.isBefore(_toDate!) ? _fromDate! : _toDate!;
    final b = _fromDate!.isBefore(_toDate!) ? _toDate! : _fromDate!;
    int count = 0;
    var d = a;
    while (d.isBefore(b)) {
      if (d.weekday <= 5) count++;
      d = d.add(const Duration(days: 1));
    }
    return count;
  }

  // ── Add/Subtract tab ──

  Widget _buildAddSubTab(ThemeData theme, ColorScheme cs) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _datePickerCard(
            label: 'Start Date',
            icon: Icons.today,
            date: _baseDate,
            onTap: () async {
              final d = await _pickDate(initial: _baseDate);
              if (d != null) {
                setState(() => _baseDate = d);
                _computeAddSub();
              }
            },
            cs: cs,
            theme: theme,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Add')),
                  ButtonSegment(value: false, label: Text('Subtract')),
                ],
                selected: {_isAdd},
                onSelectionChanged: (v) {
                  setState(() => _isAdd = v.first);
                  _computeAddSub();
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Days',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => _computeAddSub(),
                ),
              ),
            ],
          ),
          if (_resultDate != null) ...[
            const SizedBox(height: 20),
            Card(
              color: cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      'Result',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _fmt(_resultDate!),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fmtWeekday(_resultDate!),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Shared widgets ──

  Widget _datePickerCard({
    required String label,
    required IconData icon,
    required DateTime? date,
    required VoidCallback onTap,
    required ColorScheme cs,
    required ThemeData theme,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 32, color: cs.primary),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: theme.textTheme.labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 4),
                    Text(
                      date != null ? _fmt(date) : 'Tap to select',
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
    );
  }

  Widget _buildGrid(List<_StatItem> items) {
    final cs = Theme.of(context).colorScheme;
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      children: items.map((item) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(item.icon, color: cs.primary, size: 22),
                const SizedBox(height: 6),
                Text(item.value,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(item.label,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                    textAlign: TextAlign.center),
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
