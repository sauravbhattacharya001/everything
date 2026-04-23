import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/social_battery_service.dart';

/// Social Battery Tracker — monitor social energy levels with proactive
/// pattern detection, drain/recharge analysis, and burnout warnings.
class SocialBatteryScreen extends StatefulWidget {
  const SocialBatteryScreen({super.key});

  @override
  State<SocialBatteryScreen> createState() => _SocialBatteryScreenState();
}

class _SocialBatteryScreenState extends State<SocialBatteryScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'social_battery_entries';
  late TabController _tabController;

  List<SocialBatteryEntry> _entries = [];
  int _currentLevel = 50;
  SocialContext _selectedContext = SocialContext.work;
  SocialActivity _selectedActivity = SocialActivity.meeting;
  int _durationMinutes = 30;
  final _noteController = TextEditingController();
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      final list = jsonDecode(raw) as List;
      setState(() {
        _entries = list
            .map((e) =>
                SocialBatteryEntry.fromJson(e as Map<String, dynamic>))
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
        if (_entries.isNotEmpty) _currentLevel = _entries.first.level;
      });
    }
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _storageKey, jsonEncode(_entries.map((e) => e.toJson()).toList()));
  }

  void _addEntry() {
    final entry = SocialBatteryEntry(
      timestamp: DateTime.now(),
      level: _currentLevel,
      context: _selectedContext,
      activity: _selectedActivity,
      durationMinutes: _durationMinutes,
      note: _noteController.text.isEmpty ? null : _noteController.text,
    );
    setState(() {
      _entries.insert(0, entry);
      _noteController.clear();
      _showForm = false;
    });
    _saveEntries();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged ${entry.levelEmoji} $_currentLevel%'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _deleteEntry(int index) {
    setState(() => _entries.removeAt(index));
    _saveEntries();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Battery'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.battery_charging_full), text: 'Track'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTrackTab(theme),
          _buildHistoryTab(theme),
          _buildInsightsTab(theme),
        ],
      ),
    );
  }

  // ─── Track Tab ──────────────────────────────────────────────

  Widget _buildTrackTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Battery gauge
          SizedBox(
            height: 200,
            width: 120,
            child: CustomPaint(
              painter: _BatteryPainter(_currentLevel),
              child: Center(
                child: Text(
                  '$_currentLevel%',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: _levelColor(_currentLevel),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Level slider
          Text('How\'s your social battery?',
              style: theme.textTheme.titleMedium),
          Slider(
            value: _currentLevel.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            label: '$_currentLevel%',
            activeColor: _levelColor(_currentLevel),
            onChanged: (v) => setState(() => _currentLevel = v.round()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('🔴 Empty', style: theme.textTheme.bodySmall),
              Text('🔋 Full', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 16),

          // Quick-log row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _quickLogButton('😫', 10),
              _quickLogButton('😟', 30),
              _quickLogButton('😐', 50),
              _quickLogButton('😊', 70),
              _quickLogButton('🤩', 90),
            ],
          ),
          const SizedBox(height: 16),

          // Expand form toggle
          TextButton.icon(
            onPressed: () => setState(() => _showForm = !_showForm),
            icon: Icon(_showForm ? Icons.expand_less : Icons.expand_more),
            label: Text(_showForm ? 'Hide Details' : 'Add Details'),
          ),

          if (_showForm) ...[
            const SizedBox(height: 8),
            // Context chips
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Context', style: theme.textTheme.labelLarge),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: SocialContext.values.map((c) {
                return ChoiceChip(
                  label: Text('${c.emoji} ${c.label}'),
                  selected: _selectedContext == c,
                  onSelected: (_) =>
                      setState(() => _selectedContext = c),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Activity chips
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Activity', style: theme.textTheme.labelLarge),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: SocialActivity.values.map((a) {
                return ChoiceChip(
                  label: Text('${a.emoji} ${a.label}'),
                  selected: _selectedActivity == a,
                  onSelected: (_) =>
                      setState(() => _selectedActivity = a),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Duration
            Row(
              children: [
                Text('Duration: ', style: theme.textTheme.labelLarge),
                Expanded(
                  child: Slider(
                    value: _durationMinutes.toDouble(),
                    min: 5,
                    max: 240,
                    divisions: 47,
                    label: '$_durationMinutes min',
                    onChanged: (v) =>
                        setState(() => _durationMinutes = v.round()),
                  ),
                ),
                Text('$_durationMinutes min'),
              ],
            ),
            const SizedBox(height: 8),

            // Note
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
            ),
          ],

          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _addEntry,
            icon: const Icon(Icons.add),
            label: const Text('Log Entry'),
          ),
        ],
      ),
    );
  }

  Widget _quickLogButton(String emoji, int level) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() => _currentLevel = level);
        _addEntry();
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: _levelColor(level).withAlpha(128)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            Text('$level%', style: const TextStyle(fontSize: 11)),
          ],
        ),
      ),
    );
  }

  // ─── History Tab ────────────────────────────────────────────

  Widget _buildHistoryTab(ThemeData theme) {
    if (_entries.isEmpty) {
      return const Center(
        child: Text('No entries yet. Start tracking your social battery!'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _entries.length,
      itemBuilder: (_, i) {
        final e = _entries[i];
        final date =
            '${e.timestamp.month}/${e.timestamp.day} ${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}';
        return Dismissible(
          key: ValueKey(e.timestamp.toIso8601String()),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteEntry(i),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _levelColor(e.level).withAlpha(51),
                child: Text(e.levelEmoji, style: const TextStyle(fontSize: 20)),
              ),
              title: Text(
                  '${e.level}% — ${e.context.emoji} ${e.context.label} · ${e.activity.emoji} ${e.activity.label}'),
              subtitle: Text(
                  '$date · ${e.durationMinutes} min${e.note != null ? '\n${e.note}' : ''}'),
              isThreeLine: e.note != null,
            ),
          ),
        );
      },
    );
  }

  // ─── Insights Tab ──────────────────────────────────────────

  Widget _buildInsightsTab(ThemeData theme) {
    final insights = SocialBatteryService.generateInsights(_entries);
    final weeklyAvg = SocialBatteryService.weeklyAverage(_entries);
    final dailyAvgs = SocialBatteryService.dailyAverages(_entries);
    final risk = SocialBatteryService.burnoutRisk(_entries);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards row
          Row(
            children: [
              Expanded(
                child: _summaryCard(
                  theme,
                  'Weekly Avg',
                  '${weeklyAvg.toStringAsFixed(0)}%',
                  _levelColor(weeklyAvg.round()),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryCard(
                  theme,
                  'Entries',
                  '${_entries.length}',
                  theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _summaryCard(
                  theme,
                  'Burnout Risk',
                  '${(risk * 100).toStringAsFixed(0)}%',
                  risk > 0.5
                      ? Colors.red
                      : risk > 0.25
                          ? Colors.orange
                          : Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Daily trend
          if (dailyAvgs.isNotEmpty) ...[
            Text('7-Day Trend', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...dailyAvgs.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      SizedBox(width: 48, child: Text(e.key)),
                      Expanded(
                        child: LinearProgressIndicator(
                          value: e.value / 100,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                          color: _levelColor(e.value.round()),
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${e.value.toStringAsFixed(0)}%'),
                    ],
                  ),
                )),
            const SizedBox(height: 20),
          ],

          // Insights
          Text('Insights & Recommendations',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (insights.isEmpty)
            const Text('Keep logging to unlock insights!')
          else
            ...insights.map((ins) => Card(
                  color: _insightColor(ins.type, theme),
                  child: ListTile(
                    leading: Text(ins.emoji,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(ins.title,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(ins.description),
                  ),
                )),
        ],
      ),
    );
  }

  Widget _summaryCard(
      ThemeData theme, String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(label, style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Text(value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Color _insightColor(InsightType type, ThemeData theme) {
    switch (type) {
      case InsightType.drain:
        return Colors.red.withAlpha(25);
      case InsightType.recharge:
        return Colors.green.withAlpha(25);
      case InsightType.warning:
        return Colors.orange.withAlpha(25);
      case InsightType.tip:
        return Colors.blue.withAlpha(25);
    }
  }

  static Color _levelColor(int level) {
    if (level >= 70) return Colors.green;
    if (level >= 40) return Colors.orange;
    return Colors.red;
  }
}

// ─── Battery Gauge Painter ───────────────────────────────────

class _BatteryPainter extends CustomPainter {
  final int level;
  _BatteryPainter(this.level);

  @override
  void paint(Canvas canvas, Size size) {
    final borderPaint = Paint()
      ..color = Colors.grey.shade400
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Battery body
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(10, 20, size.width - 20, size.height - 20),
      const Radius.circular(8),
    );
    canvas.drawRRect(body, borderPaint);

    // Battery cap
    final capWidth = 30.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            (size.width - capWidth) / 2, 8, capWidth, 14),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.grey.shade400,
    );

    // Fill
    final fillHeight = (size.height - 28) * level / 100;
    final fillTop = size.height - fillHeight;
    final fillRect =
        Rect.fromLTWH(14, fillTop, size.width - 28, fillHeight - 4);
    if (fillHeight > 4) {
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          _SocialBatteryScreenState._levelColor(level),
          _SocialBatteryScreenState._levelColor(math.min(100, level + 20)),
        ],
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(fillRect, const Radius.circular(4)),
        Paint()..shader = gradient.createShader(fillRect),
      );
    }
  }

  @override
  bool shouldRepaint(_BatteryPainter old) => old.level != level;
}
