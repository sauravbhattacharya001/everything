import 'package:flutter/material.dart';
import '../../models/symptom_entry.dart';
import '../../core/services/symptom_tracker_service.dart';
import 'dart:math';

/// Symptom Tracker – log health symptoms with severity, body area, triggers,
/// and notes. View frequency insights and history for doctor visits.
class SymptomTrackerScreen extends StatefulWidget {
  const SymptomTrackerScreen({super.key});

  @override
  State<SymptomTrackerScreen> createState() => _SymptomTrackerScreenState();
}

class _SymptomTrackerScreenState extends State<SymptomTrackerScreen> {
  final _service = SymptomTrackerService();
  bool _loading = true;
  int _tabIndex = 0; // 0 = Log, 1 = History, 2 = Insights

  // Form state
  final _symptomController = TextEditingController();
  final _noteController = TextEditingController();
  final _triggerController = TextEditingController();
  SymptomSeverity _severity = SymptomSeverity.mild;
  BodyArea _bodyArea = BodyArea.general;
  final List<String> _triggers = [];

  @override
  void initState() {
    super.initState();
    _service.init().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _symptomController.dispose();
    _noteController.dispose();
    _triggerController.dispose();
    super.dispose();
  }

  void _addTrigger() {
    final text = _triggerController.text.trim();
    if (text.isNotEmpty && !_triggers.contains(text)) {
      setState(() {
        _triggers.add(text);
        _triggerController.clear();
      });
    }
  }

  Future<void> _logSymptom() async {
    final symptom = _symptomController.text.trim();
    if (symptom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a symptom name')),
      );
      return;
    }
    final entry = SymptomEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      timestamp: DateTime.now(),
      symptom: symptom,
      severity: _severity,
      bodyArea: _bodyArea,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      triggers: List.from(_triggers),
    );
    await _service.addEntry(entry);
    setState(() {
      _symptomController.clear();
      _noteController.clear();
      _triggerController.clear();
      _triggers.clear();
      _severity = SymptomSeverity.mild;
      _bodyArea = BodyArea.general;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Symptom logged ✓')),
      );
    }
  }

  Future<void> _deleteEntry(String id) async {
    await _service.deleteEntry(id);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Symptom Tracker'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              _tabButton('Log', 0, Icons.add_circle_outline),
              _tabButton('History', 1, Icons.history),
              _tabButton('Insights', 2, Icons.insights),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : IndexedStack(
              index: _tabIndex,
              children: [
                _buildLogTab(theme),
                _buildHistoryTab(theme),
                _buildInsightsTab(theme),
              ],
            ),
    );
  }

  Widget _tabButton(String label, int index, IconData icon) {
    final selected = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : null),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : null,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ── Log Tab ──

  Widget _buildLogTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _symptomController,
            decoration: const InputDecoration(
              labelText: 'Symptom *',
              hintText: 'e.g. Headache, Nausea, Fatigue...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.medical_services_outlined),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          // Severity
          Text('Severity', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          SegmentedButton<SymptomSeverity>(
            segments: SymptomSeverity.values
                .map((s) => ButtonSegment(
                      value: s,
                      label: Text('${s.emoji} ${s.label}'),
                    ))
                .toList(),
            selected: {_severity},
            onSelectionChanged: (v) => setState(() => _severity = v.first),
          ),
          const SizedBox(height: 16),
          // Body Area
          Text('Body Area', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: BodyArea.values.map((area) {
              final selected = _bodyArea == area;
              return ChoiceChip(
                label: Text('${area.emoji} ${area.label}'),
                selected: selected,
                onSelected: (_) => setState(() => _bodyArea = area),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          // Triggers
          Text('Triggers (optional)', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _triggerController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Stress, Lack of sleep...',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addTrigger(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addTrigger,
                icon: const Icon(Icons.add),
              ),
            ],
          ),
          if (_triggers.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _triggers
                  .map((t) => Chip(
                        label: Text(t),
                        onDeleted: () =>
                            setState(() => _triggers.remove(t)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          // Note
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note_outlined),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _logSymptom,
            icon: const Icon(Icons.check),
            label: const Text('Log Symptom'),
          ),
        ],
      ),
    );
  }

  // ── History Tab ──

  Widget _buildHistoryTab(ThemeData theme) {
    final entries = _service.entries;
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.healing, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No symptoms logged yet',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return Dismissible(
          key: Key(e.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          onDismissed: (_) => _deleteEntry(e.id),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _severityColor(e.severity).withAlpha(40),
                child: Text(e.bodyArea.emoji),
              ),
              title: Text(e.symptom),
              subtitle: Text(
                '${e.severity.emoji} ${e.severity.label} · ${e.bodyArea.label}'
                '${e.triggers.isNotEmpty ? '\nTriggers: ${e.triggers.join(", ")}' : ''}'
                '${e.note != null ? '\n${e.note}' : ''}',
              ),
              trailing: Text(
                _formatDate(e.timestamp),
                style: theme.textTheme.bodySmall,
              ),
              isThreeLine: e.triggers.isNotEmpty || e.note != null,
            ),
          ),
        );
      },
    );
  }

  // ── Insights Tab ──

  Widget _buildInsightsTab(ThemeData theme) {
    final entries = _service.entries;
    if (entries.isEmpty) {
      return const Center(
        child: Text('Log some symptoms to see insights',
            style: TextStyle(color: Colors.grey)),
      );
    }

    final symptomFreq = _service.symptomFrequency();
    final triggerFreq = _service.triggerFrequency();
    final areaCount = <BodyArea, int>{};
    for (final e in entries) {
      areaCount[e.bodyArea] = (areaCount[e.bodyArea] ?? 0) + 1;
    }

    // Recent 7-day count
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final recentCount = entries.where((e) => e.timestamp.isAfter(weekAgo)).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _statBubble('Total', '${entries.length}', Icons.list),
                      _statBubble('This Week', '$recentCount', Icons.date_range),
                      _statBubble('Unique',
                          '${symptomFreq.length}', Icons.category),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Top symptoms
          if (symptomFreq.isNotEmpty) ...[
            Text('Most Frequent Symptoms', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...symptomFreq.entries.take(5).map((e) => ListTile(
                  dense: true,
                  leading: const Icon(Icons.medical_services, size: 20),
                  title: Text(e.key),
                  trailing: Chip(label: Text('${e.value}x')),
                )),
          ],
          const SizedBox(height: 16),
          // Top triggers
          if (triggerFreq.isNotEmpty) ...[
            Text('Common Triggers', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: triggerFreq.entries.take(8).map((e) {
                return Chip(
                  avatar: const Icon(Icons.flash_on, size: 16),
                  label: Text('${e.key} (${e.value})'),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          // Body area distribution
          if (areaCount.isNotEmpty) ...[
            Text('By Body Area', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...(areaCount.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
                .map((e) => ListTile(
                      dense: true,
                      leading: Text(e.key.emoji, style: const TextStyle(fontSize: 20)),
                      title: Text(e.key.label),
                      trailing: Text('${e.value}'),
                    )),
          ],
        ],
      ),
    );
  }

  Widget _statBubble(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.headlineSmall),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Color _severityColor(SymptomSeverity s) {
    switch (s) {
      case SymptomSeverity.mild:
        return Colors.amber;
      case SymptomSeverity.moderate:
        return Colors.orange;
      case SymptomSeverity.severe:
        return Colors.red;
    }
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.month}/${dt.day}/${dt.year}';
  }
}
