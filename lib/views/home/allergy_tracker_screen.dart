import 'package:flutter/material.dart';
import '../../models/allergy_entry.dart';
import '../../core/services/allergy_tracker_service.dart';
import 'dart:math';

/// Allergy Tracker – log allergic reactions with allergen, category, severity,
/// symptoms, treatment, and notes. View history and insights.
class AllergyTrackerScreen extends StatefulWidget {
  const AllergyTrackerScreen({super.key});

  @override
  State<AllergyTrackerScreen> createState() => _AllergyTrackerScreenState();
}

class _AllergyTrackerScreenState extends State<AllergyTrackerScreen> {
  final _service = AllergyTrackerService();
  bool _loading = true;
  int _tabIndex = 0; // 0 = Log, 1 = History, 2 = Insights

  // Form state
  final _allergenController = TextEditingController();
  final _treatmentController = TextEditingController();
  final _noteController = TextEditingController();
  final _symptomController = TextEditingController();
  final _durationController = TextEditingController();
  AllergenCategory _category = AllergenCategory.food;
  ReactionSeverity _severity = ReactionSeverity.mild;
  final List<String> _symptoms = [];

  static const _commonSymptoms = [
    'Hives',
    'Itching',
    'Swelling',
    'Sneezing',
    'Runny nose',
    'Watery eyes',
    'Cough',
    'Rash',
    'Stomach pain',
    'Nausea',
    'Vomiting',
    'Diarrhea',
    'Shortness of breath',
    'Wheezing',
    'Dizziness',
    'Tingling',
  ];

  @override
  void initState() {
    super.initState();
    _service.init().then((_) {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _allergenController.dispose();
    _treatmentController.dispose();
    _noteController.dispose();
    _symptomController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _addSymptom([String? symptom]) {
    final text = (symptom ?? _symptomController.text).trim();
    if (text.isNotEmpty && !_symptoms.contains(text)) {
      setState(() {
        _symptoms.add(text);
        _symptomController.clear();
      });
    }
  }

  Future<void> _logReaction() async {
    final allergen = _allergenController.text.trim();
    if (allergen.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an allergen name')),
      );
      return;
    }
    final entry = AllergyEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      timestamp: DateTime.now(),
      allergen: allergen,
      category: _category,
      severity: _severity,
      symptoms: List.from(_symptoms),
      treatment: _treatmentController.text.isNotEmpty
          ? _treatmentController.text
          : null,
      note: _noteController.text.isNotEmpty ? _noteController.text : null,
      durationMinutes: int.tryParse(_durationController.text) ?? 0,
    );
    await _service.addEntry(entry);
    setState(() {
      _allergenController.clear();
      _treatmentController.clear();
      _noteController.clear();
      _symptomController.clear();
      _durationController.clear();
      _symptoms.clear();
      _category = AllergenCategory.food;
      _severity = ReactionSeverity.mild;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reaction logged ✓')),
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
      appBar: AppBar(title: const Text('Allergy Tracker')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabBar(theme),
                Expanded(child: _buildTabContent(theme)),
              ],
            ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    const tabs = ['Log', 'History', 'Insights'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final selected = _tabIndex == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tabIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.horizontal(
                    left: i == 0 ? const Radius.circular(10) : Radius.zero,
                    right: i == tabs.length - 1
                        ? const Radius.circular(10)
                        : Radius.zero,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  tabs[i],
                  style: TextStyle(
                    color: selected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme) {
    switch (_tabIndex) {
      case 0:
        return _buildLogTab(theme);
      case 1:
        return _buildHistoryTab(theme);
      case 2:
        return _buildInsightsTab(theme);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLogTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Allergen name
          TextField(
            controller: _allergenController,
            decoration: const InputDecoration(
              labelText: 'Allergen',
              hintText: 'e.g., Peanuts, Pollen, Penicillin',
              prefixIcon: Icon(Icons.warning_amber),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Category
          Text('Category', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: AllergenCategory.values.map((cat) {
              final selected = _category == cat;
              return ChoiceChip(
                label: Text('${cat.emoji} ${cat.label}'),
                selected: selected,
                onSelected: (_) => setState(() => _category = cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Severity
          Text('Reaction Severity', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ReactionSeverity.values.map((sev) {
              final selected = _severity == sev;
              return ChoiceChip(
                label: Text('${sev.emoji} ${sev.label}'),
                selected: selected,
                onSelected: (_) => setState(() => _severity = sev),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Symptoms - quick picks
          Text('Symptoms', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _commonSymptoms.map((s) {
              final active = _symptoms.contains(s);
              return FilterChip(
                label: Text(s, style: const TextStyle(fontSize: 12)),
                selected: active,
                onSelected: (_) {
                  setState(() {
                    if (active) {
                      _symptoms.remove(s);
                    } else {
                      _symptoms.add(s);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _symptomController,
                  decoration: const InputDecoration(
                    labelText: 'Custom symptom',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _addSymptom(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle),
                onPressed: _addSymptom,
              ),
            ],
          ),
          if (_symptoms.where((s) => !_commonSymptoms.contains(s)).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 6,
                children: _symptoms
                    .where((s) => !_commonSymptoms.contains(s))
                    .map((s) => Chip(
                          label: Text(s),
                          onDeleted: () =>
                              setState(() => _symptoms.remove(s)),
                        ))
                    .toList(),
              ),
            ),
          const SizedBox(height: 16),

          // Duration
          TextField(
            controller: _durationController,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              hintText: 'How long did the reaction last?',
              prefixIcon: Icon(Icons.timer),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),

          // Treatment
          TextField(
            controller: _treatmentController,
            decoration: const InputDecoration(
              labelText: 'Treatment',
              hintText: 'e.g., Antihistamine, EpiPen',
              prefixIcon: Icon(Icons.medical_services),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),

          // Notes
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Additional observations...',
              prefixIcon: Icon(Icons.note),
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),

          FilledButton.icon(
            onPressed: _logReaction,
            icon: const Icon(Icons.add),
            label: const Text('Log Reaction'),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(ThemeData theme) {
    final entries = _service.entries;
    if (entries.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('No reactions logged yet'),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(e.category.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.allergen,
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _severityColor(e.severity).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${e.severity.emoji} ${e.severity.label}',
                        style: TextStyle(
                          fontSize: 12,
                          color: _severityColor(e.severity),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => _deleteEntry(e.id),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${e.category.label} · ${_formatDate(e.timestamp)}',
                  style: theme.textTheme.bodySmall,
                ),
                if (e.symptoms.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: e.symptoms
                        .map((s) => Chip(
                              label: Text(s,
                                  style: const TextStyle(fontSize: 11)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                            ))
                        .toList(),
                  ),
                ],
                if (e.durationMinutes > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('⏱ ${e.durationMinutes} min',
                        style: theme.textTheme.bodySmall),
                  ),
                if (e.treatment != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('💊 ${e.treatment}',
                        style: theme.textTheme.bodySmall),
                  ),
                if (e.note != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text('📝 ${e.note}',
                        style: theme.textTheme.bodySmall),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInsightsTab(ThemeData theme) {
    final entries = _service.entries;
    if (entries.isEmpty) {
      return const Center(child: Text('Log reactions to see insights'));
    }

    final allergenFreq = _service.allergenFrequency();
    final symptomFreq = _service.symptomFrequency();
    final catDist = _service.categoryDistribution();
    final sevDist = _service.severityDistribution();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statColumn('Total', '${entries.length}', Icons.list),
                  _statColumn('Allergens',
                      '${_service.knownAllergens.length}', Icons.warning),
                  _statColumn(
                    'Severe+',
                    '${entries.where((e) => e.severity.value >= 3).length}',
                    Icons.error,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Top allergens
          Text('Top Allergens', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...allergenFreq.entries.take(8).map((e) => _barRow(
                e.key,
                e.value,
                entries.length,
                theme.colorScheme.error,
              )),
          const SizedBox(height: 20),

          // Category breakdown
          Text('By Category', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...catDist.entries.map((e) => _barRow(
                '${e.key.emoji} ${e.key.label}',
                e.value,
                entries.length,
                theme.colorScheme.primary,
              )),
          const SizedBox(height: 20),

          // Severity breakdown
          Text('By Severity', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...sevDist.entries.map((e) => _barRow(
                '${e.key.emoji} ${e.key.label}',
                e.value,
                entries.length,
                _severityColor(e.key),
              )),
          const SizedBox(height: 20),

          // Common symptoms
          Text('Common Symptoms', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: symptomFreq.entries.take(10).map((e) {
              return Chip(label: Text('${e.key} (${e.value})'));
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _statColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _barRow(String label, int count, int total, Color color) {
    final pct = total > 0 ? count / total : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, overflow: TextOverflow.ellipsis)),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          Text('$count', style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _severityColor(ReactionSeverity severity) {
    switch (severity) {
      case ReactionSeverity.mild:
        return Colors.amber;
      case ReactionSeverity.moderate:
        return Colors.orange;
      case ReactionSeverity.severe:
        return Colors.red;
      case ReactionSeverity.anaphylaxis:
        return Colors.red.shade900;
    }
  }

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $h:${dt.minute.toString().padLeft(2, '0')} $ampm';
  }
}
