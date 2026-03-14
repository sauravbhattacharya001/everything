import 'package:flutter/material.dart';
import '../../core/services/decision_journal_service.dart';
import '../../core/services/screen_persistence.dart';
import '../../models/decision_entry.dart';

/// Decision Journal Screen — log important decisions, track outcomes,
/// analyze confidence calibration, and learn from past choices.
///
/// Four tabs:
///   1. **Log** — Record a new decision with context, alternatives,
///      and confidence level.
///   2. **Journal** — Browse, search, and filter all decisions.
///   3. **Review** — Overdue and pending outcome reviews.
///   4. **Insights** — Calibration report, quality score, category
///      breakdown, and lessons learned.
class DecisionJournalScreen extends StatefulWidget {
  const DecisionJournalScreen({super.key});

  @override
  State<DecisionJournalScreen> createState() => _DecisionJournalScreenState();
}

class _DecisionJournalScreenState extends State<DecisionJournalScreen>
    with SingleTickerProviderStateMixin {
  final DecisionJournalService _service = DecisionJournalService();
  final _persistence = ScreenPersistence<DecisionEntry>(
    storageKey: 'decision_journal_entries',
    toJson: (e) => e.toJson(),
    fromJson: DecisionEntry.fromJson,
  );
  late TabController _tabController;
  int _nextId = 1;

  // Log tab state
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _expectedController = TextEditingController();
  final _contextController = TextEditingController();
  DecisionCategory _selectedCategory = DecisionCategory.other;
  ConfidenceLevel _selectedConfidence = ConfidenceLevel.moderate;
  final List<Alternative> _alternatives = [];
  final _altDescController = TextEditingController();
  final _altReasonController = TextEditingController();
  int _reviewDays = 30;

  // Journal tab state
  String _searchQuery = '';
  DecisionCategory? _filterCategory;
  final _searchController = TextEditingController();

  // Review tab state — outcome recording
  DecisionOutcome _reviewOutcome = DecisionOutcome.asExpected;
  final _reflectionController = TextEditingController();
  final _lessonsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final saved = await _persistence.load();
    if (saved.isNotEmpty) {
      final jsonStr = DecisionEntry.encodeList(saved);
      _service.importFromJson(jsonStr);
      if (mounted) setState(() {});
    }
  }

  Future<void> _save() async {
    await _persistence.save(_service.entries);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _expectedController.dispose();
    _contextController.dispose();
    _altDescController.dispose();
    _altReasonController.dispose();
    _searchController.dispose();
    _reflectionController.dispose();
    _lessonsController.dispose();
    super.dispose();
  }

  String _genId() => 'd${_nextId++}';

  // ═══════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Decision Journal'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Log'),
            Tab(icon: Icon(Icons.menu_book), text: 'Journal'),
            Tab(icon: Icon(Icons.rate_review), text: 'Review'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLogTab(),
          _buildJournalTab(),
          _buildReviewTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 1: LOG — Record a new decision
  // ═══════════════════════════════════════════════════════════

  Widget _buildLogTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Record a Decision',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Capture your thinking now — review the outcome later.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 20),

          // Title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Decision Title *',
              hintText: 'e.g., Switch to new tech stack',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
          ),
          const SizedBox(height: 12),

          // Description
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'What are you deciding? *',
              hintText: 'Describe the decision and its stakes...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 12),

          // Category
          DropdownButtonFormField<DecisionCategory>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: DecisionCategory.values
                .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text('${c.emoji} ${c.label}'),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedCategory = v!),
          ),
          const SizedBox(height: 12),

          // Confidence
          Text(
            'Confidence: ${_selectedConfidence.label}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Row(
            children: ConfidenceLevel.values.map((level) {
              final isSelected = level == _selectedConfidence;
              return Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _selectedConfidence = level),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _confidenceColor(level)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${level.value}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Very Low',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('Very High',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 12),

          // Expected outcome
          TextField(
            controller: _expectedController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Expected Outcome *',
              hintText: 'What do you think will happen?',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.trending_up),
            ),
          ),
          const SizedBox(height: 12),

          // Context
          TextField(
            controller: _contextController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Context (optional)',
              hintText: 'Emotional state, time pressure, etc.',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.psychology),
            ),
          ),
          const SizedBox(height: 16),

          // Alternatives
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alternatives Considered',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add'),
                onPressed: _showAddAlternativeDialog,
              ),
            ],
          ),
          if (_alternatives.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'No alternatives added yet.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          else
            ..._alternatives.asMap().entries.map((entry) {
              final alt = entry.value;
              return Card(
                child: ListTile(
                  dense: true,
                  title: Text(alt.description),
                  subtitle: alt.reason != null
                      ? Text('Why not: ${alt.reason}')
                      : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => setState(
                        () => _alternatives.removeAt(entry.key)),
                  ),
                ),
              );
            }),
          const SizedBox(height: 12),

          // Review period
          Row(
            children: [
              const Icon(Icons.schedule, size: 20),
              const SizedBox(width: 8),
              Text('Review in $_reviewDays days'),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: _reviewDays.toDouble(),
                  min: 7,
                  max: 90,
                  divisions: 83,
                  label: '$_reviewDays days',
                  onChanged: (v) =>
                      setState(() => _reviewDays = v.round()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Log Decision'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: _logDecision,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAlternativeDialog() {
    _altDescController.clear();
    _altReasonController.clear();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Alternative'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _altDescController,
              decoration: const InputDecoration(
                labelText: 'What was the alternative?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _altReasonController,
              decoration: const InputDecoration(
                labelText: 'Why did you not choose it?',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_altDescController.text.trim().isNotEmpty) {
                setState(() {
                  _alternatives.add(Alternative(
                    description: _altDescController.text.trim(),
                    reason: _altReasonController.text.trim().isEmpty
                        ? null
                        : _altReasonController.text.trim(),
                  ));
                });
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _logDecision() {
    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final expected = _expectedController.text.trim();

    if (title.isEmpty || desc.isEmpty || expected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required fields.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _service.addDecision(
        id: _genId(),
        title: title,
        description: desc,
        category: _selectedCategory,
        confidence: _selectedConfidence,
        expectedOutcome: expected,
        alternatives: List.of(_alternatives),
        context: _contextController.text.trim().isEmpty
            ? null
            : _contextController.text.trim(),
        reviewDate:
            DateTime.now().add(Duration(days: _reviewDays)),
        setDefaultReview: false,
      );

      // Reset form
      _titleController.clear();
      _descController.clear();
      _expectedController.clear();
      _contextController.clear();
      _alternatives.clear();
      _selectedCategory = DecisionCategory.other;
      _selectedConfidence = ConfidenceLevel.moderate;
      _reviewDays = 30;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Logged: $title'),
        backgroundColor: Colors.green,
      ),
    );

    _tabController.animateTo(1); // Switch to Journal
    _save();
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 2: JOURNAL — Browse, search, filter
  // ═══════════════════════════════════════════════════════════

  Widget _buildJournalTab() {
    List<DecisionEntry> entries;
    if (_searchQuery.isNotEmpty) {
      entries = _service.search(_searchQuery);
    } else {
      entries = _service.entries.toList();
    }

    if (_filterCategory != null) {
      entries = entries
          .where((e) => e.category == _filterCategory)
          .toList();
    }

    entries.sort((a, b) => b.decidedAt.compareTo(a.decidedAt));

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search decisions...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),

        // Category filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _filterCategory == null,
                onSelected: (_) =>
                    setState(() => _filterCategory = null),
              ),
              const SizedBox(width: 6),
              ...DecisionCategory.values.map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text('${cat.emoji} ${cat.label}'),
                      selected: _filterCategory == cat,
                      onSelected: (_) => setState(
                          () => _filterCategory = _filterCategory == cat ? null : cat),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Stats strip
        if (entries.isNotEmpty)
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _miniStat(
                    '${entries.length}', 'decisions', Icons.menu_book),
                _miniStat(
                    '${entries.where((e) => e.isReviewed).length}',
                    'reviewed',
                    Icons.check_circle),
                _miniStat(
                    '${entries.where((e) => e.isReviewDue).length}',
                    'overdue',
                    Icons.warning),
              ],
            ),
          ),

        // List
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty
                            ? 'No matching decisions.'
                            : 'No decisions logged yet.\nUse the Log tab to get started!',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) =>
                      _buildDecisionCard(entries[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildDecisionCard(DecisionEntry entry) {
    final daysAgo = entry.daysSinceDecision;
    final isOverdue = entry.isReviewDue;

    return Card(
      elevation: isOverdue ? 3 : 1,
      color: isOverdue ? Colors.red.shade50 : null,
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _categoryColor(entry.category),
          child: Text(entry.category.emoji,
              style: const TextStyle(fontSize: 18)),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Row(
          children: [
            Text('$daysAgo days ago'),
            const SizedBox(width: 8),
            _confidenceBadge(entry.confidence),
            if (entry.isReviewed) ...[
              const SizedBox(width: 6),
              Text(
                entry.outcome!.emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ],
            if (isOverdue) ...[
              const SizedBox(width: 6),
              const Icon(Icons.warning,
                  size: 16, color: Colors.red),
            ],
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                _detailRow('Description', entry.description),
                _detailRow('Expected Outcome', entry.expectedOutcome),
                if (entry.context != null)
                  _detailRow('Context', entry.context!),
                if (entry.alternatives.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Alternatives:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700)),
                  ...entry.alternatives.map((alt) => Padding(
                        padding: const EdgeInsets.only(left: 12, top: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(
                              child: Text(
                                alt.reason != null
                                    ? '${alt.description} (${alt.reason})'
                                    : alt.description,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
                if (entry.isReviewed) ...[
                  const Divider(),
                  _detailRow(
                      'Outcome',
                      '${entry.outcome!.emoji} ${entry.outcome!.label}'),
                  if (entry.reflection != null)
                    _detailRow('Reflection', entry.reflection!),
                  if (entry.lessonsLearned != null)
                    _detailRow('Lessons', entry.lessonsLearned!),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!entry.isReviewed)
                      TextButton.icon(
                        icon: const Icon(Icons.rate_review, size: 18),
                        label: const Text('Review'),
                        onPressed: () =>
                            _showRecordOutcomeDialog(entry),
                      ),
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline,
                          size: 18, color: Colors.red),
                      label: const Text('Delete',
                          style: TextStyle(color: Colors.red)),
                      onPressed: () {
                        setState(() => _service.removeDecision(entry.id));
                        _save();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Removed: ${entry.title}')),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 3: REVIEW — Overdue & pending reviews
  // ═══════════════════════════════════════════════════════════

  Widget _buildReviewTab() {
    final overdue = _service.overdueReviews;
    final pending = _service.pendingReviews
        .where((e) => !e.isReviewDue)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overdue section
          _sectionHeader(
            'Overdue Reviews',
            Icons.warning_amber,
            Colors.red,
            count: overdue.length,
          ),
          if (overdue.isEmpty)
            _emptyState('No overdue reviews — nice!', Icons.check_circle)
          else
            ...overdue.map(_buildReviewCard),

          const SizedBox(height: 24),

          // Pending section
          _sectionHeader(
            'Upcoming Reviews',
            Icons.schedule,
            Colors.blue,
            count: pending.length,
          ),
          if (pending.isEmpty)
            _emptyState('No upcoming reviews.', Icons.event_available)
          else
            ...pending.map(_buildReviewCard),

          const SizedBox(height: 24),

          // Streak
          _buildStreakCard(),
        ],
      ),
    );
  }

  Widget _buildReviewCard(DecisionEntry entry) {
    final isOverdue = entry.isReviewDue;
    final daysUntil = entry.reviewDate != null
        ? entry.reviewDate!.difference(DateTime.now()).inDays
        : 0;

    return Card(
      elevation: isOverdue ? 3 : 1,
      color: isOverdue ? Colors.red.shade50 : Colors.blue.shade50,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOverdue ? Colors.red : Colors.blue,
          child: Text(entry.category.emoji,
              style: const TextStyle(fontSize: 18)),
        ),
        title: Text(entry.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          isOverdue
              ? 'Overdue by ${-daysUntil} days'
              : 'Due in $daysUntil days',
        ),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isOverdue ? Colors.red : Colors.blue,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _showRecordOutcomeDialog(entry),
          child: const Text('Review'),
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    final streak = _service.getReviewStreak();
    return Card(
      color: Colors.amber.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.local_fire_department,
                color: Colors.orange, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review Streak: ${streak.current}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text('Longest: ${streak.longest}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showRecordOutcomeDialog(DecisionEntry entry) {
    _reviewOutcome = DecisionOutcome.asExpected;
    _reflectionController.clear();
    _lessonsController.clear();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Review: ${entry.title}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You expected: "${entry.expectedOutcome}"',
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),

                const Text('What actually happened?'),
                const SizedBox(height: 8),
                ...DecisionOutcome.values.map((o) => RadioListTile<DecisionOutcome>(
                      title: Text('${o.emoji} ${o.label}'),
                      value: o,
                      groupValue: _reviewOutcome,
                      onChanged: (v) =>
                          setDialogState(() => _reviewOutcome = v!),
                      dense: true,
                    )),

                const SizedBox(height: 12),
                TextField(
                  controller: _reflectionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reflection',
                    hintText: 'What went well or poorly?',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _lessonsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Lessons Learned',
                    hintText: 'What would you do differently?',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _service.recordOutcome(
                    entry.id,
                    outcome: _reviewOutcome,
                    reflection: _reflectionController.text.trim().isEmpty
                        ? null
                        : _reflectionController.text.trim(),
                    lessonsLearned:
                        _lessonsController.text.trim().isEmpty
                            ? null
                            : _lessonsController.text.trim(),
                  );
                });
                Navigator.pop(ctx);
                _save();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Reviewed: ${entry.title} — ${_reviewOutcome.emoji} ${_reviewOutcome.label}'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              child: const Text('Save Review'),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // TAB 4: INSIGHTS — Analytics & calibration
  // ═══════════════════════════════════════════════════════════

  Widget _buildInsightsTab() {
    final stats = _service.getStats();
    final quality = _service.getQualityScore();
    final calibration = _service.getCalibrationReport();
    final topCats = _service.topCategories(limit: 5);
    final lessons = _service.allLessonsLearned();

    if (stats.totalDecisions == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              'Log some decisions first\nto see insights here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quality score card
          Card(
            color: _qualityColor(quality.overall).withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Decision Quality',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    '${quality.overall.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _qualityColor(quality.overall),
                    ),
                  ),
                  Text(quality.label,
                      style: TextStyle(
                          color: _qualityColor(quality.overall),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  // Score breakdown
                  _scoreBar('Calibration', quality.calibration),
                  _scoreBar('Outcomes', quality.outcomes),
                  _scoreBar('Review Rate', quality.reviewCompletion),
                  _scoreBar('Reflection', quality.reflectionDepth),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats overview
          Row(
            children: [
              _statCard('Total', '${stats.totalDecisions}',
                  Icons.menu_book, Colors.blue),
              const SizedBox(width: 8),
              _statCard('Reviewed', '${stats.reviewedDecisions}',
                  Icons.check_circle, Colors.green),
              const SizedBox(width: 8),
              _statCard('Pending', '${stats.pendingReviews}',
                  Icons.schedule, Colors.orange),
              const SizedBox(width: 8),
              _statCard('Overdue', '${stats.overdueReviews}',
                  Icons.warning, Colors.red),
            ],
          ),
          const SizedBox(height: 20),

          // Calibration report
          _sectionHeader(
              'Confidence Calibration', Icons.tune, Colors.purple),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        calibration.calibrationLabel,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _calibrationColor(
                              calibration.calibrationRate),
                        ),
                      ),
                      Text(
                        '${(calibration.calibrationRate * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (calibration.sampleSize > 0) ...[
                    _calibrationRow(
                        'Calibrated', calibration.calibratedCount,
                        color: Colors.green),
                    _calibrationRow(
                        'Overconfident', calibration.overconfidentCount,
                        color: Colors.red),
                    _calibrationRow(
                        'Underconfident', calibration.underconfidentCount,
                        color: Colors.orange),
                    const SizedBox(height: 4),
                    Text(
                      'Based on ${calibration.sampleSize} reviewed decisions',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ] else
                    Text(
                      'Review more decisions to see calibration data.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Category breakdown
          if (topCats.isNotEmpty) ...[
            _sectionHeader(
                'Top Categories', Icons.pie_chart, Colors.teal),
            ...topCats.map((entry) {
              final cat = entry.key;
              final count = entry.value;
              final maxCount =
                  topCats.first.value > 0 ? topCats.first.value : 1;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text('${cat.emoji} ${cat.label}'),
                    ),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: count / maxCount,
                        backgroundColor: Colors.grey.shade200,
                        color: _categoryColor(cat),
                        minHeight: 12,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('$count',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),
          ],

          // Lessons learned
          if (lessons.isNotEmpty) ...[
            _sectionHeader(
                'Lessons Learned', Icons.lightbulb, Colors.amber),
            ...lessons.take(10).map((lesson) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.lightbulb_outline,
                        color: Colors.amber),
                    title: Text(lesson),
                    dense: true,
                  ),
                )),
          ],
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // Shared widgets & helpers
  // ═══════════════════════════════════════════════════════════

  Widget _miniStat(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade600),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                  fontSize: 12)),
          Text(value),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, Color color,
      {int? count}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold)),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('$count',
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(text,
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }

  Widget _confidenceBadge(ConfidenceLevel level) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _confidenceColor(level).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        level.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: _confidenceColor(level),
        ),
      ),
    );
  }

  Widget _scoreBar(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label)),
          Expanded(
            child: LinearProgressIndicator(
              value: value / 100,
              backgroundColor: Colors.grey.shade200,
              color: _qualityColor(value),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text('${value.toStringAsFixed(0)}%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text(label,
                  style: const TextStyle(fontSize: 11),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ),
    );
  }

  Widget _calibrationRow(String label, int count, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color ?? Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text('$count',
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _confidenceColor(ConfidenceLevel level) {
    switch (level) {
      case ConfidenceLevel.veryLow:
        return Colors.red;
      case ConfidenceLevel.low:
        return Colors.orange;
      case ConfidenceLevel.moderate:
        return Colors.blue;
      case ConfidenceLevel.high:
        return Colors.teal;
      case ConfidenceLevel.veryHigh:
        return Colors.green;
    }
  }

  Color _categoryColor(DecisionCategory cat) {
    switch (cat) {
      case DecisionCategory.career:
        return Colors.blue;
      case DecisionCategory.finance:
        return Colors.green;
      case DecisionCategory.health:
        return Colors.red;
      case DecisionCategory.relationships:
        return Colors.pink;
      case DecisionCategory.education:
        return Colors.purple;
      case DecisionCategory.technology:
        return Colors.indigo;
      case DecisionCategory.lifestyle:
        return Colors.teal;
      case DecisionCategory.business:
        return Colors.amber;
      case DecisionCategory.creative:
        return Colors.deepOrange;
      case DecisionCategory.other:
        return Colors.grey;
    }
  }

  Color _qualityColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _calibrationColor(double rate) {
    if (rate >= 0.8) return Colors.green;
    if (rate >= 0.6) return Colors.blue;
    if (rate >= 0.4) return Colors.orange;
    return Colors.red;
  }
}
