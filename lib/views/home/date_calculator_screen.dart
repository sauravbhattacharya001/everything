import 'package:flutter/material.dart';
import '../../core/services/date_calculator_service.dart';

/// Date Calculator — compute the difference between two dates or
/// add/subtract durations from a date. Includes business-day counts,
/// day-of-year, week number, and quick-access milestone presets.
class DateCalculatorScreen extends StatefulWidget {
  const DateCalculatorScreen({super.key});

  @override
  State<DateCalculatorScreen> createState() => _DateCalculatorScreenState();
}

class _DateCalculatorScreenState extends State<DateCalculatorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ── Difference tab ──
  DateTime _fromDate = DateTime.now();
  DateTime _toDate = DateTime.now();
  DateDifference? _diff;

  // ── Offset tab ──
  DateTime _baseDate = DateTime.now();
  bool _isAdd = true;
  int _offsetYears = 0;
  int _offsetMonths = 0;
  int _offsetWeeks = 0;
  int _offsetDays = 0;
  DateTime? _resultDate;

  final _yearsCtrl = TextEditingController(text: '0');
  final _monthsCtrl = TextEditingController(text: '0');
  final _weeksCtrl = TextEditingController(text: '0');
  final _daysCtrl = TextEditingController(text: '0');

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _yearsCtrl.dispose();
    _monthsCtrl.dispose();
    _weeksCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  // ── Difference helpers ──

  Future<void> _pickDate(bool isFrom) async {
    final initial = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
        _diff = null;
      });
    }
  }

  void _calcDifference() {
    setState(() {
      _diff = DateCalculatorService.difference(_fromDate, _toDate);
    });
  }

  // ── Offset helpers ──

  Future<void> _pickBaseDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _baseDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2200),
    );
    if (picked != null) {
      setState(() {
        _baseDate = picked;
        _resultDate = null;
      });
    }
  }

  void _calcOffset() {
    _offsetYears = int.tryParse(_yearsCtrl.text) ?? 0;
    _offsetMonths = int.tryParse(_monthsCtrl.text) ?? 0;
    _offsetWeeks = int.tryParse(_weeksCtrl.text) ?? 0;
    _offsetDays = int.tryParse(_daysCtrl.text) ?? 0;

    final sign = _isAdd ? 1 : -1;
    setState(() {
      _resultDate = DateCalculatorService.offset(
        _baseDate,
        years: sign * _offsetYears,
        months: sign * _offsetMonths,
        weeks: sign * _offsetWeeks,
        days: sign * _offsetDays,
      );
    });
  }

  // ── Milestone presets ──

  void _applyPreset(int days) {
    _daysCtrl.text = days.toString();
    _weeksCtrl.text = '0';
    _monthsCtrl.text = '0';
    _yearsCtrl.text = '0';
    _isAdd = true;
    _calcOffset();
  }

  // ── Formatting ──

  String _fmt(DateTime d) =>
      '${_monthName(d.month)} ${d.day}, ${d.year} (${DateCalculatorService.dayOfWeekName(d.weekday)})';

  String _monthName(int m) => const [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ][m - 1];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          _buildDifferenceTab(theme),
          _buildOffsetTab(theme),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  Difference Tab
  // ═══════════════════════════════════════════════

  Widget _buildDifferenceTab(ThemeData theme) {
    final now = DateTime.now();
    final dayOfYear = DateCalculatorService.dayOfYear(now);
    final weekOfYear = DateCalculatorService.weekOfYear(now);
    final daysLeft = DateCalculatorService.daysRemainingInYear(now);
    final leap = DateCalculatorService.isLeapYear(now.year);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Today info card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Today', style: theme.textTheme.titleSmall),
                const SizedBox(height: 8),
                Text(_fmt(now), style: theme.textTheme.bodyLarge),
                const SizedBox(height: 4),
                Text(
                  'Day $dayOfYear · Week $weekOfYear · '
                  '$daysLeft days left in ${now.year}'
                  '${leap ? ' (leap year)' : ''}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // From / To pickers
        _dateTile('From', _fromDate, () => _pickDate(true), theme),
        const SizedBox(height: 8),
        _dateTile('To', _toDate, () => _pickDate(false), theme),
        const SizedBox(height: 16),

        FilledButton.icon(
          onPressed: _calcDifference,
          icon: const Icon(Icons.calculate),
          label: const Text('Calculate'),
        ),

        if (_diff != null) ...[
          const SizedBox(height: 24),
          _diffResults(theme),
        ],
      ],
    );
  }

  Widget _dateTile(
      String label, DateTime date, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelSmall),
                  Text(_fmt(date), style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
            const Icon(Icons.edit, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _diffResults(ThemeData theme) {
    final d = _diff!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Result', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            _resultRow('Duration', d.humanReadable, theme, bold: true),
            const Divider(height: 24),
            _resultRow('Total days', '${d.totalDays}', theme),
            _resultRow('Weeks + days', '${d.totalWeeks} wk ${d.remainderDays} d', theme),
            _resultRow('Business days', '${d.businessDays}', theme),
            _resultRow('Total hours', '${d.totalHours}', theme),
            _resultRow('Total minutes', '${d.totalMinutes}', theme),
          ],
        ),
      ),
    );
  }

  Widget _resultRow(String label, String value, ThemeData theme,
      {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: bold
                ? theme.textTheme.titleSmall
                : theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  //  Offset Tab (Add / Subtract)
  // ═══════════════════════════════════════════════

  Widget _buildOffsetTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _dateTile('Start date', _baseDate, _pickBaseDate, theme),
        const SizedBox(height: 16),

        // Add / Subtract toggle
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Add'), icon: Icon(Icons.add)),
            ButtonSegment(
                value: false,
                label: Text('Subtract'),
                icon: Icon(Icons.remove)),
          ],
          selected: {_isAdd},
          onSelectionChanged: (s) => setState(() => _isAdd = s.first),
        ),
        const SizedBox(height: 16),

        // Duration inputs
        Row(
          children: [
            Expanded(child: _numField('Years', _yearsCtrl)),
            const SizedBox(width: 8),
            Expanded(child: _numField('Months', _monthsCtrl)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _numField('Weeks', _weeksCtrl)),
            const SizedBox(width: 8),
            Expanded(child: _numField('Days', _daysCtrl)),
          ],
        ),
        const SizedBox(height: 16),

        FilledButton.icon(
          onPressed: _calcOffset,
          icon: const Icon(Icons.calculate),
          label: const Text('Calculate'),
        ),

        const SizedBox(height: 16),

        // Quick presets
        Text('Quick presets', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _presetChip('30 days', 30),
            _presetChip('60 days', 60),
            _presetChip('90 days', 90),
            _presetChip('180 days', 180),
            _presetChip('365 days', 365),
          ],
        ),

        if (_resultDate != null) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Result', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Text(
                    _fmt(_resultDate!),
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Day ${DateCalculatorService.dayOfYear(_resultDate!)} · '
                    'Week ${DateCalculatorService.weekOfYear(_resultDate!)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _numField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  Widget _presetChip(String label, int days) {
    return ActionChip(
      label: Text(label),
      onPressed: () => _applyPreset(days),
    );
  }
}
