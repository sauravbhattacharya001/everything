import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/screen_time_tracker_service.dart';
import '../../models/screen_time_entry.dart';

/// Screen Time Tracker screen for logging app usage, viewing daily summaries,
/// category breakdowns, and insights to help manage digital wellbeing.
class ScreenTimeTrackerScreen extends StatefulWidget {
  const ScreenTimeTrackerScreen({super.key});

  @override
  State<ScreenTimeTrackerScreen> createState() =>
      _ScreenTimeTrackerScreenState();
}

class _ScreenTimeTrackerScreenState extends State<ScreenTimeTrackerScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'screen_time_tracker_data';
  final ScreenTimeTrackerService _service = ScreenTimeTrackerService();
  late TabController _tabController;
  DateTime _selectedDate = DateTime.now();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null && json.isNotEmpty) {
      try {
        _service.importFromJson(json);
        _initialized = true;
        setState(() {});
        return;
      } catch (_) {}
    }
    _loadDemoData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, _service.exportToJson());
  }

  void _loadDemoData() {
    if (_initialized) return;
    _initialized = true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    int idCounter = 0;
    String nextId() => 'st_${idCounter++}';

    final todayApps = [
      (name: 'Instagram', cat: AppCategory.social, min: 45, picks: 12),
      (name: 'YouTube', cat: AppCategory.entertainment, min: 60, picks: 8),
      (name: 'Slack', cat: AppCategory.communication, min: 35, picks: 20),
      (name: 'VS Code', cat: AppCategory.productivity, min: 90, picks: 5),
      (name: 'Twitter', cat: AppCategory.social, min: 25, picks: 15),
      (name: 'Chrome', cat: AppCategory.productivity, min: 40, picks: 10),
      (name: 'Duolingo', cat: AppCategory.education, min: 15, picks: 3),
      (name: 'Reddit', cat: AppCategory.entertainment, min: 30, picks: 7),
    ];

    for (final app in todayApps) {
      _service.addEntry(ScreenTimeEntry(
        id: nextId(), date: today, appName: app.name,
        category: app.cat, durationMinutes: app.min, pickups: app.picks,
      ));
    }

    for (int d = 1; d <= 6; d++) {
      final date = today.subtract(Duration(days: d));
      final v = (d * 7 + 3) % 5;
      final apps = [
        (name: 'Instagram', cat: AppCategory.social, min: 30 + v * 5, picks: 8 + v),
        (name: 'YouTube', cat: AppCategory.entertainment, min: 40 + v * 8, picks: 5 + v),
        (name: 'Slack', cat: AppCategory.communication, min: 20 + v * 3, picks: 15 + v),
        (name: 'VS Code', cat: AppCategory.productivity, min: 60 + v * 10, picks: 3 + v),
        (name: 'Chrome', cat: AppCategory.productivity, min: 25 + v * 6, picks: 6 + v),
      ];
      for (final app in apps) {
        _service.addEntry(ScreenTimeEntry(
          id: nextId(), date: date, appName: app.name,
          category: app.cat, durationMinutes: app.min, pickups: app.picks,
        ));
      }
    }

    _service.addLimit(const ScreenTimeLimit(category: AppCategory.social, dailyLimitMinutes: 60));
    _service.addLimit(const ScreenTimeLimit(appName: 'YouTube', dailyLimitMinutes: 45));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Screen Time'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Log'),
            Tab(icon: Icon(Icons.today), text: 'Today'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Breakdown'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LogTab(service: _service, onLogged: () { setState(() {}); _saveData(); }),
          _TodayTab(
            service: _service, selectedDate: _selectedDate,
            onDateChanged: (d) => setState(() => _selectedDate = d),
            onChanged: () { setState(() {}); _saveData(); },
          ),
          _BreakdownTab(service: _service),
          _InsightsTab(service: _service),
        ],
      ),
    );
  }
}

// ─── LOG TAB ────────────────────────────────────────────────────────────────

class _LogTab extends StatefulWidget {
  final ScreenTimeTrackerService service;
  final VoidCallback onLogged;
  const _LogTab({required this.service, required this.onLogged});
  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  final _formKey = GlobalKey<FormState>();
  String _appName = '';
  AppCategory _category = AppCategory.social;
  int _duration = 30;
  int _pickups = 0;
  String? _notes;

  static const _presetApps = {
    'Instagram': AppCategory.social, 'TikTok': AppCategory.social,
    'Twitter': AppCategory.social, 'YouTube': AppCategory.entertainment,
    'Netflix': AppCategory.entertainment, 'Reddit': AppCategory.entertainment,
    'Slack': AppCategory.communication, 'WhatsApp': AppCategory.communication,
    'Discord': AppCategory.communication, 'VS Code': AppCategory.productivity,
    'Chrome': AppCategory.productivity, 'Notion': AppCategory.productivity,
    'Duolingo': AppCategory.education, 'Kindle': AppCategory.education,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Add', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _presetApps.entries.map((entry) {
                return ChoiceChip(
                  label: Text(entry.key),
                  selected: _appName == entry.key,
                  onSelected: (selected) {
                    setState(() {
                      _appName = selected ? entry.key : '';
                      if (selected) _category = entry.value;
                    });
                  },
                  avatar: Icon(_categoryIcon(entry.value), size: 16),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'App Name', hintText: 'Or type a custom app name',
                border: OutlineInputBorder(), prefixIcon: Icon(Icons.apps),
              ),
              initialValue: _appName,
              onChanged: (v) => setState(() => _appName = v.trim()),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter an app name' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<AppCategory>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category', border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: AppCategory.values.map((c) => DropdownMenuItem(
                value: c,
                child: Row(children: [
                  Icon(_categoryIcon(c), size: 18), const SizedBox(width: 8),
                  Text(_categoryLabel(c)),
                ]),
              )).toList(),
              onChanged: (v) { if (v != null) setState(() => _category = v); },
            ),
            const SizedBox(height: 16),
            Text('Duration: ${_formatDuration(_duration)}',
                style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: _duration.toDouble(), min: 1, max: 480, divisions: 479,
              label: _formatDuration(_duration),
              onChanged: (v) => setState(() => _duration = v.round()),
            ),
            Wrap(
              spacing: 8,
              children: [5, 15, 30, 60, 120].map((m) => ActionChip(
                label: Text(_formatDuration(m)),
                onPressed: () => setState(() => _duration = m),
              )).toList(),
            ),
            const SizedBox(height: 16),
            Text('Pickups: $_pickups', style: Theme.of(context).textTheme.titleSmall),
            Slider(
              value: _pickups.toDouble(), min: 0, max: 100, divisions: 100,
              label: '$_pickups',
              onChanged: (v) => setState(() => _pickups = v.round()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Notes (optional)', border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
              maxLines: 2,
              onChanged: (v) => _notes = v.trim().isEmpty ? null : v.trim(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.add),
                label: const Text('Log Screen Time'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_appName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or enter an app name')),
      );
      return;
    }
    final entry = ScreenTimeEntry(
      id: 'st_${DateTime.now().millisecondsSinceEpoch}',
      date: DateTime.now(), appName: _appName, category: _category,
      durationMinutes: _duration, pickups: _pickups, notes: _notes,
    );
    widget.service.addEntry(entry);
    widget.onLogged();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Logged ${_formatDuration(_duration)} of $_appName'), backgroundColor: Colors.green),
    );
    setState(() { _appName = ''; _duration = 30; _pickups = 0; _notes = null; });
  }
}

// ─── TODAY TAB ──────────────────────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  final ScreenTimeTrackerService service;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;
  final VoidCallback onChanged;

  const _TodayTab({
    required this.service, required this.selectedDate,
    required this.onDateChanged, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final summary = service.getDailySummary(selectedDate);
    final violations = service.checkLimits(selectedDate);
    final entries = service.getByDateRange(selectedDate, selectedDate);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => onDateChanged(selectedDate.subtract(const Duration(days: 1))),
              ),
              TextButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context, initialDate: selectedDate,
                    firstDate: DateTime(2020), lastDate: DateTime.now(),
                  );
                  if (picked != null) onDateChanged(picked);
                },
                child: Text(_formatDate(selectedDate), style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: selectedDate.isBefore(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
                    ? () => onDateChanged(selectedDate.add(const Duration(days: 1)))
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: _SummaryCard(icon: Icons.timer, label: 'Total', value: _formatDuration(summary.totalMinutes), color: _gradeColor(summary.grade))),
            const SizedBox(width: 8),
            Expanded(child: _SummaryCard(icon: Icons.touch_app, label: 'Pickups', value: '${summary.totalPickups}', color: Colors.blue)),
            const SizedBox(width: 8),
            Expanded(child: _SummaryCard(icon: Icons.apps, label: 'Apps', value: '${summary.appCount}', color: Colors.purple)),
          ]),
          const SizedBox(height: 8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: _gradeColor(summary.grade).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _gradeColor(summary.grade)),
              ),
              child: Text('Grade: ${summary.grade}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _gradeColor(summary.grade))),
            ),
          ),
          const SizedBox(height: 16),
          if (violations.isNotEmpty) ...[
            Text('⚠️ Limit Violations', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.red)),
            const SizedBox(height: 8),
            ...violations.map((v) => Card(
              color: Colors.red.shade50,
              child: ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text(v.target),
                subtitle: Text('${_formatDuration(v.actualMinutes)} / ${_formatDuration(v.limitMinutes)} (+${_formatDuration(v.overageMinutes)})'),
              ),
            )),
            const SizedBox(height: 16),
          ],
          if (summary.topApp.isNotEmpty) ...[
            Text('📱 Top App', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Card(child: ListTile(
              leading: CircleAvatar(backgroundColor: Colors.blue.shade100, child: const Icon(Icons.star, color: Colors.blue)),
              title: Text(summary.topApp),
              trailing: Text(_formatDuration(summary.topAppMinutes), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )),
            const SizedBox(height: 16),
          ],
          Text('📋 Usage Log (${entries.length} entries)', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No entries for this day', style: TextStyle(color: Colors.grey))))
          else
            ...entries.map((e) => Dismissible(
              key: Key(e.id), direction: DismissDirection.endToStart,
              background: Container(alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), color: Colors.red, child: const Icon(Icons.delete, color: Colors.white)),
              onDismissed: (_) { service.removeEntry(e.id); onChanged(); },
              child: Card(child: ListTile(
                leading: Icon(_categoryIcon(e.category), color: _categoryColor(e.category)),
                title: Text(e.appName),
                subtitle: Text('${_categoryLabel(e.category)} • ${e.pickups} pickups${e.notes != null ? ' • ${e.notes}' : ''}'),
                trailing: Text(_formatDuration(e.durationMinutes), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              )),
            )),
        ],
      ),
    );
  }
}

// ─── BREAKDOWN TAB ──────────────────────────────────────────────────────────

class _BreakdownTab extends StatelessWidget {
  final ScreenTimeTrackerService service;
  const _BreakdownTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final report = service.getReport();
    if (report.totalDaysTracked == 0) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.phone_android, size: 64, color: Colors.grey), SizedBox(height: 16),
        Text('No data yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
        Text('Start logging screen time to see breakdown', style: TextStyle(color: Colors.grey)),
      ])));
    }

    final rankings = service.getAppRankings();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
            Text('📊 Overview', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _StatItem(label: 'Days Tracked', value: '${report.totalDaysTracked}'),
              _StatItem(label: 'Avg Daily', value: _formatDuration(report.avgDailyMinutes.round())),
              _StatItem(label: 'Avg Pickups', value: '${report.avgDailyPickups.round()}'),
            ]),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _StatItem(label: 'Current Streak', value: '${report.currentStreak}d'),
              _StatItem(label: 'Best Streak', value: '${report.longestStreak}d'),
              _StatItem(label: 'Total', value: _formatDuration(report.totalMinutes)),
            ]),
          ]))),
          const SizedBox(height: 16),
          Text('📂 By Category', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...report.categoryBreakdown.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [Icon(_categoryIcon(b.category), size: 16, color: _categoryColor(b.category)), const SizedBox(width: 6), Text(_categoryLabel(b.category))]),
                Text('${_formatDuration(b.totalMinutes)} (${b.percentage.toStringAsFixed(1)}%)'),
              ]),
              const SizedBox(height: 4),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                value: b.percentage / 100, backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(_categoryColor(b.category)), minHeight: 8,
              )),
              Text('Top: ${b.topApp}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ]),
          )),
          const SizedBox(height: 16),
          Text('🏆 App Rankings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...rankings.take(10).toList().asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final app = entry.value;
            final maxMin = rankings.isNotEmpty ? rankings.first.value.toDouble() : 1.0;
            return Padding(padding: const EdgeInsets.only(bottom: 6), child: Row(children: [
              SizedBox(width: 24, child: Text(rank <= 3 ? ['🥇', '🥈', '🥉'][rank - 1] : '$rank.', style: const TextStyle(fontWeight: FontWeight.bold))),
              const SizedBox(width: 8),
              Expanded(flex: 2, child: Text(app.key)),
              Expanded(flex: 3, child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                value: app.value / maxMin, backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(Colors.indigo), minHeight: 6,
              ))),
              const SizedBox(width: 8),
              Text(_formatDuration(app.value), style: const TextStyle(fontWeight: FontWeight.w500)),
            ]));
          }),
          const SizedBox(height: 16),
          Text('⏱️ Active Limits', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (service.limits.isEmpty)
            const Text('No limits set', style: TextStyle(color: Colors.grey))
          else
            ...service.limits.map((l) => Card(child: ListTile(
              leading: Icon(l.appName != null ? Icons.apps : Icons.category, color: Colors.orange),
              title: Text(l.appName ?? _categoryLabel(l.category!)),
              trailing: Text('${_formatDuration(l.dailyLimitMinutes)}/day', style: const TextStyle(fontWeight: FontWeight.bold)),
            ))),
        ],
      ),
    );
  }
}

// ─── INSIGHTS TAB ───────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final ScreenTimeTrackerService service;
  const _InsightsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final report = service.getReport();
    final insights = service.generateInsights();

    if (report.totalDaysTracked == 0) {
      return const Center(child: Padding(padding: EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey), SizedBox(height: 16),
        Text('No insights yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
        Text('Log a few days of screen time first', style: TextStyle(color: Colors.grey)),
      ])));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Column(children: [
            Text('Digital Wellbeing', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SizedBox(height: 120, width: 120, child: Stack(alignment: Alignment.center, children: [
              SizedBox(height: 120, width: 120, child: CircularProgressIndicator(
                value: _wellbeingScore(report) / 100, strokeWidth: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(_wellbeingColor(_wellbeingScore(report))),
              )),
              Text('${_wellbeingScore(report).round()}', style: TextStyle(
                fontSize: 36, fontWeight: FontWeight.bold,
                color: _wellbeingColor(_wellbeingScore(report)),
              )),
            ])),
            const SizedBox(height: 8),
            Text(_wellbeingLabel(_wellbeingScore(report)), style: TextStyle(
              color: _wellbeingColor(_wellbeingScore(report)), fontWeight: FontWeight.w500,
            )),
          ])),
          const SizedBox(height: 24),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🎯 Daily Goal', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Goal: ${_formatDuration(service.dailyGoalMinutes)}'),
                Text('Avg: ${_formatDuration(report.avgDailyMinutes.round())}'),
              ]),
              const SizedBox(height: 8),
              ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(
                value: (report.avgDailyMinutes / service.dailyGoalMinutes).clamp(0.0, 1.5),
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(report.avgDailyMinutes <= service.dailyGoalMinutes ? Colors.green : Colors.red),
                minHeight: 10,
              )),
              const SizedBox(height: 4),
              Text(
                report.avgDailyMinutes <= service.dailyGoalMinutes
                    ? '✅ Under goal by ${_formatDuration((service.dailyGoalMinutes - report.avgDailyMinutes).round())}'
                    : '⚠️ Over goal by ${_formatDuration((report.avgDailyMinutes - service.dailyGoalMinutes).round())}',
                style: TextStyle(color: report.avgDailyMinutes <= service.dailyGoalMinutes ? Colors.green : Colors.red),
              ),
            ],
          ))),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              const Icon(Icons.local_fire_department, color: Colors.orange, size: 32),
              const SizedBox(height: 4),
              Text('${report.currentStreak}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('Current\nStreak', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
            ])))),
            Expanded(child: Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
              const Icon(Icons.emoji_events, color: Colors.amber, size: 32),
              const SizedBox(height: 4),
              Text('${report.longestStreak}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text('Best\nStreak', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
            ])))),
          ]),
          const SizedBox(height: 16),
          Text('💡 Insights', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (insights.isEmpty)
            const Text('Keep logging to unlock insights!', style: TextStyle(color: Colors.grey))
          else
            ...insights.map((i) => Card(
              color: _insightColor(i.severity),
              child: ListTile(
                leading: Icon(_insightIcon(i.severity), color: _insightIconColor(i.severity)),
                title: Text(i.message),
                subtitle: Text(i.type.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(fontSize: 11)),
              ),
            )),
          const SizedBox(height: 16),
          if (report.categoryBreakdown.isNotEmpty) ...[
            Card(color: Colors.blue.shade50, child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
              Icon(_categoryIcon(report.topCategory), size: 40, color: _categoryColor(report.topCategory)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Most Used Category', style: TextStyle(fontSize: 12)),
                Text(_categoryLabel(report.topCategory), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                if (report.topApp.isNotEmpty) Text('Top app: ${report.topApp}'),
              ])),
            ]))),
          ],
        ],
      ),
    );
  }

  double _wellbeingScore(ScreenTimeReport report) {
    if (report.totalDaysTracked == 0) return 50;
    double score = 100;
    final goalRatio = report.avgDailyMinutes / service.dailyGoalMinutes;
    if (goalRatio > 1.0) score -= (goalRatio - 1.0) * 30;
    for (final b in report.categoryBreakdown) {
      if (b.category == AppCategory.social && b.percentage > 30) score -= (b.percentage - 30) * 0.5;
      if (b.category == AppCategory.gaming && b.percentage > 25) score -= (b.percentage - 25) * 0.5;
    }
    for (final b in report.categoryBreakdown) {
      if (b.category == AppCategory.productivity || b.category == AppCategory.education) score += b.percentage * 0.2;
    }
    if (report.avgDailyPickups > 80) score -= 10;
    else if (report.avgDailyPickups > 50) score -= 5;
    score += (report.currentStreak * 2).clamp(0, 10).toDouble();
    return score.clamp(0, 100);
  }

  Color _wellbeingColor(double s) => s >= 80 ? Colors.green : s >= 60 ? Colors.lightGreen : s >= 40 ? Colors.orange : Colors.red;
  String _wellbeingLabel(double s) => s >= 80 ? 'Excellent' : s >= 60 ? 'Good' : s >= 40 ? 'Fair' : 'Needs Improvement';
  Color _insightColor(String s) => s == 'alert' ? Colors.red.shade50 : s == 'warning' ? Colors.orange.shade50 : Colors.green.shade50;
  IconData _insightIcon(String s) => s == 'alert' ? Icons.error_outline : s == 'warning' ? Icons.warning_amber : Icons.check_circle_outline;
  Color _insightIconColor(String s) => s == 'alert' ? Colors.red : s == 'warning' ? Colors.orange : Colors.green;
}

// ─── SHARED WIDGETS ─────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color;
  const _SummaryCard({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(children: [
    Icon(icon, color: color, size: 28), const SizedBox(height: 4),
    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    Text(label, style: const TextStyle(fontSize: 12)),
  ])));
}

class _StatItem extends StatelessWidget {
  final String label; final String value;
  const _StatItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
  ]);
}

// ─── HELPERS ────────────────────────────────────────────────────────────────

String _formatDuration(int minutes) {
  final h = minutes ~/ 60; final m = minutes % 60;
  if (h == 0) return '${m}m'; if (m == 0) return '${h}h'; return '${h}h ${m}m';
}

String _formatDate(DateTime d) {
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

Color _gradeColor(String g) => g == 'A' ? Colors.green : g == 'B' ? Colors.lightGreen : g == 'C' ? Colors.orange : g == 'D' ? Colors.deepOrange : Colors.red;

IconData _categoryIcon(AppCategory c) {
  switch (c) {
    case AppCategory.social: return Icons.people;
    case AppCategory.entertainment: return Icons.movie;
    case AppCategory.productivity: return Icons.work;
    case AppCategory.communication: return Icons.chat;
    case AppCategory.education: return Icons.school;
    case AppCategory.health: return Icons.favorite;
    case AppCategory.finance: return Icons.attach_money;
    case AppCategory.news: return Icons.newspaper;
    case AppCategory.gaming: return Icons.sports_esports;
    case AppCategory.utilities: return Icons.settings;
    case AppCategory.shopping: return Icons.shopping_bag;
    case AppCategory.travel: return Icons.flight;
    case AppCategory.other: return Icons.more_horiz;
  }
}

Color _categoryColor(AppCategory c) {
  switch (c) {
    case AppCategory.social: return Colors.pink;
    case AppCategory.entertainment: return Colors.red;
    case AppCategory.productivity: return Colors.blue;
    case AppCategory.communication: return Colors.teal;
    case AppCategory.education: return Colors.indigo;
    case AppCategory.health: return Colors.green;
    case AppCategory.finance: return Colors.amber;
    case AppCategory.news: return Colors.brown;
    case AppCategory.gaming: return Colors.purple;
    case AppCategory.utilities: return Colors.grey;
    case AppCategory.shopping: return Colors.orange;
    case AppCategory.travel: return Colors.cyan;
    case AppCategory.other: return Colors.blueGrey;
  }
}

String _categoryLabel(AppCategory c) {
  switch (c) {
    case AppCategory.social: return 'Social';
    case AppCategory.entertainment: return 'Entertainment';
    case AppCategory.productivity: return 'Productivity';
    case AppCategory.communication: return 'Communication';
    case AppCategory.education: return 'Education';
    case AppCategory.health: return 'Health';
    case AppCategory.finance: return 'Finance';
    case AppCategory.news: return 'News';
    case AppCategory.gaming: return 'Gaming';
    case AppCategory.utilities: return 'Utilities';
    case AppCategory.shopping: return 'Shopping';
    case AppCategory.travel: return 'Travel';
    case AppCategory.other: return 'Other';
  }
}
