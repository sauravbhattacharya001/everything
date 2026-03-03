import 'package:flutter/material.dart';
import '../../core/data/daily_review_sample_data.dart';
import '../../core/services/daily_review_service.dart';
import '../../core/utils/formatting_utils.dart';
import '../../models/event_model.dart';

/// Daily Review Screen — end-of-day reflection with event summary,
/// completion stats, mood/energy tracking, day rating, and tomorrow preview.
class DailyReviewScreen extends StatefulWidget {
  const DailyReviewScreen({super.key});

  @override
  State<DailyReviewScreen> createState() => _DailyReviewScreenState();
}

class _DailyReviewScreenState extends State<DailyReviewScreen> {
  late DailyReviewService _service;
  late DateTime _selectedDate;
  late DaySummary _summary;
  late DayComparison _comparison;
  DailyReview? _review;

  int _rating = 3;
  int _mood = 3;
  int _energy = 3;
  final _notesController = TextEditingController();
  final _highlightController = TextEditingController();
  final _lowlightController = TextEditingController();
  final _focusController = TextEditingController();
  final List<String> _highlights = [];
  final List<String> _lowlights = [];
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _service = DailyReviewService(
      events: DailyReviewSampleData.sampleEvents(),
      reviews: DailyReviewSampleData.sampleReviews(),
    );
    _loadDay();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _highlightController.dispose();
    _lowlightController.dispose();
    _focusController.dispose();
    super.dispose();
  }

  void _loadDay() {
    _summary = _service.summarize(_selectedDate);
    _comparison = _service.compare(_selectedDate);
    _review = _service.getReview(_selectedDate);
    if (_review != null) {
      _rating = _review!.rating;
      _mood = _review!.mood;
      _energy = _review!.energy;
      _notesController.text = _review!.notes;
      _highlights
        ..clear()
        ..addAll(_review!.highlights);
      _lowlights
        ..clear()
        ..addAll(_review!.lowlights);
      _focusController.text = _review!.tomorrowFocus;
      _isSaved = true;
    } else {
      _rating = 3;
      _mood = 3;
      _energy = 3;
      _notesController.clear();
      _highlights.clear();
      _lowlights.clear();
      _focusController.clear();
      _isSaved = false;
    }
  }

  void _changeDate(int delta) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: delta));
      _loadDay();
    });
  }

  void _saveReview() {
    final review = DailyReview(
      date: _selectedDate,
      rating: _rating,
      mood: _mood,
      energy: _energy,
      notes: _notesController.text,
      highlights: List.from(_highlights),
      lowlights: List.from(_lowlights),
      tomorrowFocus: _focusController.text,
      createdAt: DateTime.now(),
    );
    _service.saveReview(review);
    setState(() {
      _review = review;
      _isSaved = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Daily review saved! 🎉'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _addHighlight() {
    final text = _highlightController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _highlights.add(text);
        _highlightController.clear();
        _isSaved = false;
      });
    }
  }

  void _addLowlight() {
    final text = _lowlightController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _lowlights.add(text);
        _lowlightController.clear();
        _isSaved = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trend = _service.getTrend(days: 7);
    final accomplishments = _service.topAccomplishments(_selectedDate);
    final tomorrow = _service.tomorrowEvents(_selectedDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Review'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Jump to today',
            onPressed: () {
              setState(() {
                _selectedDate = DateTime.now();
                _loadDay();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Date Navigator ──
            _buildDateNavigator(theme),
            const SizedBox(height: 16),

            // ── Day Summary Card ──
            _buildSummaryCard(theme),
            const SizedBox(height: 16),

            // ── Comparison Card ──
            _buildComparisonCard(theme),
            const SizedBox(height: 16),

            // ── Top Accomplishments ──
            if (accomplishments.isNotEmpty) ...[
              _buildAccomplishmentsCard(theme, accomplishments),
              const SizedBox(height: 16),
            ],

            // ── Rating & Mood/Energy ──
            _buildRatingCard(theme),
            const SizedBox(height: 16),

            // ── Highlights & Lowlights ──
            _buildReflectionCard(theme),
            const SizedBox(height: 16),

            // ── Tomorrow Focus ──
            _buildTomorrowCard(theme, tomorrow),
            const SizedBox(height: 16),

            // ── Notes ──
            _buildNotesCard(theme),
            const SizedBox(height: 16),

            // ── Streak & Trend ──
            _buildTrendCard(theme, trend),
            const SizedBox(height: 24),

            // ── Save Button ──
            FilledButton.icon(
              onPressed: _saveReview,
              icon: Icon(_isSaved ? Icons.check : Icons.save),
              label: Text(_isSaved ? 'Update Review' : 'Save Review'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ─── Widgets ────────────────────────────────────────────────────

  Widget _buildDateNavigator(ThemeData theme) {
    final isToday = FormattingUtils.sameDay(_selectedDate, DateTime.now());
    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeDate(-1),
        ),
        Column(
          children: [
            Text(
              isToday
                  ? 'Today'
                  : dayNames[_selectedDate.weekday - 1],
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${monthNames[_selectedDate.month - 1]} ${_selectedDate.day}, ${_selectedDate.year}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _selectedDate.isBefore(DateTime.now())
              ? () => _changeDate(1)
              : null,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.summarize, size: 20),
                const SizedBox(width: 8),
                Text('Day Summary',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _statTile(
                  theme,
                  '${_summary.totalEvents}',
                  'Events',
                  Icons.event,
                  theme.colorScheme.primary,
                )),
                Expanded(
                    child: _statTile(
                  theme,
                  '${_summary.completionRate.toStringAsFixed(0)}%',
                  'Complete',
                  Icons.check_circle,
                  FormattingUtils.completionColor(_summary.completionRate),
                )),
                Expanded(
                    child: _statTile(
                  theme,
                  '${(_summary.totalMinutesScheduled / 60).toStringAsFixed(1)}h',
                  'Scheduled',
                  Icons.schedule,
                  theme.colorScheme.tertiary,
                )),
                Expanded(
                    child: _statTile(
                  theme,
                  '${_summary.tagsUsed.length}',
                  'Tags',
                  Icons.label,
                  theme.colorScheme.secondary,
                )),
              ],
            ),
            if (_summary.totalChecklistItems > 0) ...[
              const SizedBox(height: 12),
              _buildProgressBar(
                label: 'Checklist Progress',
                value: _summary.checklistRate / 100,
                trailing:
                    '${_summary.completedChecklistItems}/${_summary.totalChecklistItems}',
                theme: theme,
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: Chip(
                avatar: Icon(FormattingUtils.productivityIcon(_summary.productivityLabel),
                    size: 18),
                label: Text(_summary.productivityLabel),
                backgroundColor:
                    FormattingUtils.productivityColor(_summary.productivityLabel)
                        .withAlpha(30),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonCard(ThemeData theme) {
    final comp = _comparison;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.compare_arrows, size: 20),
                const SizedBox(width: 8),
                Text('vs Yesterday',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                _trendChip(comp.trend, theme),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _deltaRow(
                        'Events', comp.eventDelta, '', theme)),
                Expanded(
                    child: _deltaRow('Completion',
                        comp.completionDelta.round(), '%', theme)),
                Expanded(
                    child: _deltaRow(
                        'Minutes', comp.minutesDelta, 'min', theme)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccomplishmentsCard(
      ThemeData theme, List<EventModel> accomplishments) {
    final top = accomplishments.take(5).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events, size: 20),
                const SizedBox(width: 8),
                Text('Top Accomplishments',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            ...top.map((e) => ListTile(
                  dense: true,
                  leading: Icon(e.priority.icon, color: e.priority.color),
                  title: Text(e.title),
                  subtitle: e.endDate != null
                      ? Text(
                          '${FormattingUtils.formatTime12h(e.date)} – ${FormattingUtils.formatTime12h(e.endDate!)}')
                      : null,
                  contentPadding: EdgeInsets.zero,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, size: 20),
                const SizedBox(width: 8),
                Text('How Was Your Day?',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),

            // Star rating
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = i + 1;
                        _isSaved = false;
                      });
                    },
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Mood slider
            _buildSlider(
              label: 'Mood',
              value: _mood,
              emojis: const ['😫', '😔', '😐', '🙂', '😄'],
              onChanged: (v) => setState(() {
                _mood = v;
                _isSaved = false;
              }),
              theme: theme,
            ),
            const SizedBox(height: 12),

            // Energy slider
            _buildSlider(
              label: 'Energy',
              value: _energy,
              emojis: const ['🔋', '🪫', '⚡', '💪', '🚀'],
              onChanged: (v) => setState(() {
                _energy = v;
                _isSaved = false;
              }),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReflectionCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb, size: 20),
                const SizedBox(width: 8),
                Text('Reflection',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),

            // Highlights
            Text('✨ Highlights',
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            ..._highlights.asMap().entries.map((entry) => ListTile(
                  dense: true,
                  leading: const Text('🌟'),
                  title: Text(entry.value),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _highlights.removeAt(entry.key);
                      _isSaved = false;
                    }),
                  ),
                  contentPadding: EdgeInsets.zero,
                )),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _highlightController,
                    decoration: const InputDecoration(
                      hintText: 'Add a highlight...',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addHighlight(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addHighlight,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Lowlights
            Text('🔻 Things to improve',
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            ..._lowlights.asMap().entries.map((entry) => ListTile(
                  dense: true,
                  leading: const Text('📌'),
                  title: Text(entry.value),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(() {
                      _lowlights.removeAt(entry.key);
                      _isSaved = false;
                    }),
                  ),
                  contentPadding: EdgeInsets.zero,
                )),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _lowlightController,
                    decoration: const InputDecoration(
                      hintText: 'Add something to improve...',
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addLowlight(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  onPressed: _addLowlight,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTomorrowCard(
      ThemeData theme, List<EventModel> tomorrowEvents) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny, size: 20),
                const SizedBox(width: 8),
                Text('Tomorrow Preview',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _focusController,
              decoration: const InputDecoration(
                hintText: 'My #1 focus for tomorrow...',
                prefixIcon: Icon(Icons.flag),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _isSaved = false),
            ),
            if (tomorrowEvents.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('${tomorrowEvents.length} event(s) scheduled:',
                  style: theme.textTheme.bodySmall),
              const SizedBox(height: 8),
              ...tomorrowEvents.take(5).map((e) => ListTile(
                    dense: true,
                    leading: Icon(e.priority.icon,
                        color: e.priority.color, size: 20),
                    title: Text(e.title),
                    trailing: Text(FormattingUtils.formatTime12h(e.date),
                        style: theme.textTheme.bodySmall),
                    contentPadding: EdgeInsets.zero,
                  )),
              if (tomorrowEvents.length > 5)
                Text('+${tomorrowEvents.length - 5} more',
                    style: theme.textTheme.bodySmall),
            ] else
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('No events scheduled for tomorrow',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_note, size: 20),
                const SizedBox(width: 8),
                Text('Notes',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Any thoughts about today...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() => _isSaved = false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendCard(ThemeData theme, ReviewTrend trend) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.trending_up, size: 20),
                const SizedBox(width: 8),
                Text('7-Day Trend',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _statTile(
                  theme,
                  trend.avgRating.toStringAsFixed(1),
                  'Avg Rating',
                  Icons.star,
                  Colors.amber,
                )),
                Expanded(
                    child: _statTile(
                  theme,
                  trend.avgMood.toStringAsFixed(1),
                  'Avg Mood',
                  Icons.mood,
                  Colors.blue,
                )),
                Expanded(
                    child: _statTile(
                  theme,
                  trend.avgEnergy.toStringAsFixed(1),
                  'Avg Energy',
                  Icons.bolt,
                  Colors.orange,
                )),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.local_fire_department,
                    color: Colors.deepOrange, size: 20),
                const SizedBox(width: 4),
                Text(
                  'Review Streak: ${trend.currentStreak} day(s)',
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 16),
                Text(
                  'Best: ${trend.longestStreak}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper Widgets ─────────────────────────────────────────────

  Widget _statTile(ThemeData theme, String value, String label,
      IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(value,
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double value,
    required String trailing,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            Text(trailing, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: 8,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget _buildSlider({
    required String label,
    required int value,
    required List<String> emojis,
    required ValueChanged<int> onChanged,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(label)),
        Text(emojis.first, style: const TextStyle(fontSize: 18)),
        Expanded(
          child: Slider(
            value: value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: emojis[value - 1],
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
        Text(emojis.last, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 8),
        Text(emojis[value - 1], style: const TextStyle(fontSize: 24)),
      ],
    );
  }

  Widget _deltaRow(String label, int delta, String unit, ThemeData theme) {
    final isPositive = delta > 0;
    final isZero = delta == 0;
    return Column(
      children: [
        Text(
          isZero ? '—' : '${isPositive ? '+' : ''}$delta$unit',
          style: theme.textTheme.titleMedium?.copyWith(
            color: isZero
                ? theme.colorScheme.onSurfaceVariant
                : isPositive
                    ? Colors.green
                    : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _trendChip(String trend, ThemeData theme) {
    final (icon, color, label) = switch (trend) {
      'improving' => (Icons.trending_up, Colors.green, 'Improving'),
      'declining' => (Icons.trending_down, Colors.red, 'Declining'),
      _ => (Icons.trending_flat, Colors.grey, 'Stable'),
    };
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label, style: TextStyle(color: color, fontSize: 12)),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }

}
