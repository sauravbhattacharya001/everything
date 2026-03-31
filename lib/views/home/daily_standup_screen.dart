import 'package:flutter/material.dart';
import '../../models/standup_entry.dart';
import '../../core/services/daily_standup_service.dart';
import '../../core/services/persistent_state_mixin.dart';

/// Daily Standup screen — quick morning check-in answering
/// "What did I do yesterday?", "What will I do today?", and
/// "Any blockers?" with streak tracking and history.
class DailyStandupScreen extends StatefulWidget {
  const DailyStandupScreen({super.key});
  @override
  State<DailyStandupScreen> createState() => _DailyStandupScreenState();
}

class _DailyStandupScreenState extends State<DailyStandupScreen>
    with PersistentStateMixin {
  final _service = DailyStandupService();
  final _yesterdayController = TextEditingController();
  final _todayController = TextEditingController();
  final _blockersController = TextEditingController();
  late StandupEntry _current;
  int _energyLevel = 3;
  bool _showHistory = false;

  @override
  String get storageKey => 'daily_standup_data';

  @override
  String exportData() => _service.toJsonString();

  @override
  void importData(String json) {
    _service.loadFromJson(json);
    _loadToday();
  }

  @override
  void initState() {
    super.initState();
    _current = _service.getOrCreateToday();
    _syncControllers();
    initPersistence();
  }

  void _loadToday() {
    _current = _service.getOrCreateToday();
    _syncControllers();
  }

  void _syncControllers() {
    _yesterdayController.text = _current.yesterday;
    _todayController.text = _current.today;
    _blockersController.text = _current.blockers;
    _energyLevel = _current.energy;
  }

  @override
  void dispose() {
    _yesterdayController.dispose();
    _todayController.dispose();
    _blockersController.dispose();
    super.dispose();
  }

  void _saveStandup() {
    setState(() {
      _current.yesterday = _yesterdayController.text;
      _current.today = _todayController.text;
      _current.blockers = _blockersController.text;
      _current.energy = _energyLevel;
      _service.save(_current);
    });
    saveState();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Standup saved! 🎯'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _markDone() {
    setState(() {
      _service.markGoalsCompleted(_current.id);
    });
    saveState();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Goals completed! 🎉'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 Daily Standup'),
        actions: [
          IconButton(
            icon: Icon(_showHistory ? Icons.edit : Icons.history),
            tooltip: _showHistory ? 'Today' : 'History',
            onPressed: () => setState(() => _showHistory = !_showHistory),
          ),
        ],
      ),
      body: _showHistory ? _buildHistory(theme) : _buildToday(theme),
    );
  }

  Widget _buildToday(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats bar
          _buildStatsBar(theme),
          const SizedBox(height: 20),

          // Energy level
          _buildEnergyPicker(theme),
          const SizedBox(height: 20),

          // Yesterday
          _buildQuestionCard(
            theme,
            icon: Icons.arrow_back,
            label: 'What did I do yesterday?',
            controller: _yesterdayController,
            hint: 'Finished the API integration, reviewed 3 PRs...',
          ),
          const SizedBox(height: 16),

          // Today
          _buildQuestionCard(
            theme,
            icon: Icons.today,
            label: 'What will I do today?',
            controller: _todayController,
            hint: 'Deploy to staging, write tests for auth module...',
          ),
          const SizedBox(height: 16),

          // Blockers
          _buildQuestionCard(
            theme,
            icon: Icons.block,
            label: 'Any blockers?',
            controller: _blockersController,
            hint: 'Waiting on design review, CI pipeline is slow...',
            isBlocker: true,
          ),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _saveStandup,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Standup'),
                ),
              ),
              const SizedBox(width: 12),
              if (_current.isComplete && !_current.goalsCompleted)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _markDone,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Goals Done'),
                  ),
                ),
              if (_current.goalsCompleted)
                Expanded(
                  child: Chip(
                    avatar: const Icon(Icons.check_circle, color: Colors.green),
                    label: const Text('Completed'),
                    backgroundColor: Colors.green.withOpacity(0.1),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStat(
              theme,
              '🔥',
              '${_service.currentStreak}',
              'Streak',
            ),
            _buildStat(
              theme,
              '✅',
              '${(_service.completionRate() * 100).toStringAsFixed(0)}%',
              'Goals Done',
            ),
            _buildStat(
              theme,
              '⚡',
              _service.averageEnergy().toStringAsFixed(1),
              'Avg Energy',
            ),
            _buildStat(
              theme,
              '🚧',
              '${_service.blockerCount()}',
              'Blockers',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(ThemeData theme, String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }

  Widget _buildEnergyPicker(ThemeData theme) {
    const labels = ['😴', '😐', '🙂', '😊', '🚀'];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Energy Level', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(5, (i) {
                final level = i + 1;
                final isSelected = _energyLevel == level;
                return GestureDetector(
                  onTap: () => setState(() => _energyLevel = level),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.primary)
                          : null,
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(fontSize: isSelected ? 28 : 24),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required String hint,
    bool isBlocker = false,
  }) {
    return Card(
      color: isBlocker && controller.text.trim().isNotEmpty
          ? Colors.orange.withOpacity(0.05)
          : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label, style: theme.textTheme.titleSmall),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: hint,
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(ThemeData theme) {
    final entries = _service.entries.where((e) => e.isComplete).toList();
    if (entries.isEmpty) {
      return const Center(child: Text('No standups yet. Start your first one!'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _buildHistoryCard(theme, entry);
      },
    );
  }

  Widget _buildHistoryCard(ThemeData theme, StandupEntry entry) {
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateStr =
        '${dayNames[entry.date.weekday - 1]}, ${monthNames[entry.date.month - 1]} ${entry.date.day}';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateStr, style: theme.textTheme.titleSmall),
                Row(
                  children: [
                    if (entry.goalsCompleted)
                      const Icon(Icons.check_circle,
                          color: Colors.green, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      ['', '😴', '😐', '🙂', '😊', '🚀'][entry.energy],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(),
            if (entry.yesterday.isNotEmpty) ...[
              _buildSection('Yesterday', entry.yesterday, Icons.arrow_back),
              const SizedBox(height: 8),
            ],
            if (entry.today.isNotEmpty) ...[
              _buildSection('Today', entry.today, Icons.today),
              const SizedBox(height: 8),
            ],
            if (entry.hasBlockers)
              _buildSection('Blockers', entry.blockers, Icons.block,
                  color: Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String label, String text, IconData icon,
      {Color? color}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color ?? Colors.grey)),
              Text(text),
            ],
          ),
        ),
      ],
    );
  }
}
