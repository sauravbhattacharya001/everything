import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/learning_tracker_service.dart';
import '../../models/learning_item.dart';

/// Learning Tracker screen for managing courses, books, tutorials,
/// and other learning resources with progress tracking and study analytics.
class LearningTrackerScreen extends StatefulWidget {
  const LearningTrackerScreen({super.key});

  @override
  State<LearningTrackerScreen> createState() => _LearningTrackerScreenState();
}

class _LearningTrackerScreenState extends State<LearningTrackerScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'learning_tracker_data';
  late TabController _tabController;
  late LearningTrackerService _service;
  bool _loading = true;
  String _searchQuery = '';
  LearningStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _service = LearningTrackerService();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null && json.isNotEmpty) {
      try {
        final data = jsonDecode(json) as List<dynamic>;
        _service = LearningTrackerService();
        for (final item in data) {
          _service.addItem(
              LearningItem.fromJson(item as Map<String, dynamic>));
        }
      } catch (_) {
        _service = LearningTrackerService();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _service.items.map((i) => i.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(data));
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
        title: const Text('Learning Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.library_books), text: 'Library'),
            Tab(icon: Icon(Icons.play_circle), text: 'In Progress'),
            Tab(icon: Icon(Icons.add_task), text: 'Log Study'),
            Tab(icon: Icon(Icons.analytics), text: 'Insights'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLibraryTab(),
                _buildInProgressTab(),
                _buildLogStudyTab(),
                _buildInsightsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddItemDialog,
        child: const Icon(Icons.add),
        tooltip: 'Add Learning Item',
      ),
    );
  }

  // ─── Library Tab ──────────────────────────────────────────

  Widget _buildLibraryTab() {
    var items = _service.items.toList();
    if (_statusFilter != null) {
      items = items.where((i) => i.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      items = items.where((i) =>
          i.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (i.source?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)).toList();
    }
    items.sort((a, b) => b.priority.compareTo(a.priority));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<LearningStatus?>(
                value: _statusFilter,
                hint: const Text('All'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All')),
                  ...LearningStatus.values.map((s) =>
                      DropdownMenuItem(value: s, child: Text(s.label))),
                ],
                onChanged: (v) => setState(() => _statusFilter = v),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No items yet. Tap + to add one!'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) => _buildItemCard(items[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildItemCard(LearningItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(item.type.emoji, style: const TextStyle(fontSize: 20)),
        ),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.source != null)
              Text(item.source!, style: const TextStyle(fontSize: 12)),
            Row(
              children: [
                Text('${item.status.emoji} ${item.status.label}',
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 8),
                if (item.totalUnits > 0)
                  Text('${item.progressPercent.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.progressPercent >= 100
                            ? Colors.green
                            : null,
                      )),
              ],
            ),
            if (item.totalUnits > 0)
              LinearProgressIndicator(
                value: item.progressPercent / 100,
                backgroundColor: Colors.grey[300],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.rating != null)
              Text('${'⭐' * item.rating!}',
                  style: const TextStyle(fontSize: 10)),
            PopupMenuButton<String>(
              onSelected: (v) => _handleItemAction(v, item),
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'status', child: Text('Change Status')),
                const PopupMenuItem(value: 'rate', child: Text('Rate')),
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.red))),
              ],
            ),
          ],
        ),
        onTap: () => _showItemDetail(item),
      ),
    );
  }

  // ─── In Progress Tab ──────────────────────────────────────

  Widget _buildInProgressTab() {
    final items = _service.inProgress;
    if (items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.school, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No items in progress',
                style: TextStyle(fontSize: 18, color: Colors.grey)),
            Text('Start learning something new!'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Streak banner
        Card(
          color: Colors.blue[50],
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
                    Text('${_service.currentStreak} day streak',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(
                        '${_service.totalHoursStudied.toStringAsFixed(1)} hours total'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => _buildProgressCard(item)),
      ],
    );
  }

  Widget _buildProgressCard(LearningItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(item.type.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(item.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                Chip(
                  label: Text('P${item.priority}'),
                  backgroundColor: _priorityColor(item.priority),
                  labelStyle: const TextStyle(fontSize: 12),
                ),
              ],
            ),
            if (item.source != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(item.source!,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          '${item.completedUnits}/${item.totalUnits} units • ${item.progressPercent.toStringAsFixed(0)}%'),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: item.progressPercent / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  children: [
                    Text('${item.hoursStudied.toStringAsFixed(1)}h',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const Text('studied', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
            if (item.sessions.isNotEmpty) ...[
              const Divider(),
              Text(
                  'Last session: ${_formatDate(item.sessions.last.date)} — ${item.sessions.last.minutesSpent} min',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Log Study Tab ──────────────────────────────────────

  Widget _buildLogStudyTab() {
    final active = _service.suggestedNext;
    if (active.isEmpty) {
      return const Center(
        child: Text('Add learning items first, then log study sessions here.'),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text('Tap an item to log a study session:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ),
        ...active.take(10).map((item) => Card(
              child: ListTile(
                leading: Text(item.type.emoji,
                    style: const TextStyle(fontSize: 24)),
                title: Text(item.title),
                subtitle: Text(
                    '${item.status.label} • ${item.progressPercent.toStringAsFixed(0)}%'),
                trailing: const Icon(Icons.add_circle, color: Colors.blue),
                onTap: () => _showLogSessionDialog(item),
              ),
            )),
      ],
    );
  }

  // ─── Insights Tab ──────────────────────────────────────

  Widget _buildInsightsTab() {
    final items = _service.items;
    if (items.isEmpty) {
      return const Center(child: Text('Add items to see insights.'));
    }

    final categoryMap = _service.categoryBreakdown;
    final typeMap = _service.typeBreakdown;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Summary cards
        Row(
          children: [
            _statCard('Total Items', '${items.length}', Icons.library_books),
            _statCard('Completed', '${_service.completedCount}', Icons.check_circle),
          ],
        ),
        Row(
          children: [
            _statCard('Hours Studied',
                _service.totalHoursStudied.toStringAsFixed(1), Icons.timer),
            _statCard('Streak',
                '${_service.currentStreak} days', Icons.local_fire_department),
          ],
        ),
        Row(
          children: [
            _statCard(
                'Completion Rate',
                '${_service.completionRate.toStringAsFixed(0)}%',
                Icons.pie_chart),
            _statCard(
                'Avg Rating',
                _service.averageRating > 0
                    ? _service.averageRating.toStringAsFixed(1)
                    : '—',
                Icons.star),
          ],
        ),
        const SizedBox(height: 16),
        // Category breakdown
        const Text('By Category',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...categoryMap.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  SizedBox(width: 100, child: Text(e.key.label)),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: e.value / items.length,
                      minHeight: 12,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${e.value}'),
                ],
              ),
            )),
        const SizedBox(height: 16),
        // Type breakdown
        const Text('By Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: typeMap.entries
              .map((e) => Chip(
                    avatar: Text(e.key.emoji),
                    label: Text('${e.key.label}: ${e.value}'),
                  ))
              .toList(),
        ),
        const SizedBox(height: 16),
        // Recent sessions
        const Text('Recent Sessions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ..._recentSessions().map((entry) => ListTile(
              dense: true,
              leading: Text(entry.$1.type.emoji),
              title: Text(entry.$1.title),
              subtitle: Text(
                  '${entry.$2.minutesSpent} min • ${_formatDate(entry.$2.date)}'),
              trailing: entry.$2.notes != null
                  ? const Icon(Icons.note, size: 16)
                  : null,
            )),
      ],
    );
  }

  List<(LearningItem, StudySession)> _recentSessions() {
    final all = <(LearningItem, StudySession)>[];
    for (final item in _service.items) {
      for (final session in item.sessions) {
        all.add((item, session));
      }
    }
    all.sort((a, b) => b.$2.date.compareTo(a.$2.date));
    return all.take(20).toList();
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 28, color: Colors.blue),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label, style: const TextStyle(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Dialogs ──────────────────────────────────────────

  void _showAddItemDialog() {
    final titleCtl = TextEditingController();
    final sourceCtl = TextEditingController();
    final unitsCtl = TextEditingController(text: '0');
    var type = LearningType.course;
    var category = LearningCategory.other;
    var priority = 3;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Learning Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtl,
                  decoration: const InputDecoration(labelText: 'Title *'),
                ),
                TextField(
                  controller: sourceCtl,
                  decoration: const InputDecoration(
                      labelText: 'Source (URL, platform, etc.)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<LearningType>(
                  value: type,
                  decoration: const InputDecoration(labelText: 'Type'),
                  items: LearningType.values
                      .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text('${t.emoji} ${t.label}')))
                      .toList(),
                  onChanged: (v) => setDialogState(() => type = v!),
                ),
                DropdownButtonFormField<LearningCategory>(
                  value: category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: LearningCategory.values
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text(c.label)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => category = v!),
                ),
                TextField(
                  controller: unitsCtl,
                  decoration: const InputDecoration(
                      labelText: 'Total Units (chapters, lessons, etc.)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Priority: '),
                    ...List.generate(
                        5,
                        (i) => IconButton(
                              icon: Icon(
                                i < priority
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              ),
                              onPressed: () =>
                                  setDialogState(() => priority = i + 1),
                            )),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (titleCtl.text.trim().isEmpty) return;
                final item = LearningItem(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleCtl.text.trim(),
                  source: sourceCtl.text.trim().isEmpty
                      ? null
                      : sourceCtl.text.trim(),
                  type: type,
                  category: category,
                  totalUnits: int.tryParse(unitsCtl.text) ?? 0,
                  priority: priority,
                  dateAdded: DateTime.now(),
                );
                _service.addItem(item);
                _save();
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogSessionDialog(LearningItem item) {
    final minCtl = TextEditingController(text: '30');
    final progressCtl = TextEditingController(text: '1');
    final notesCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Session: ${item.title}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: minCtl,
                decoration:
                    const InputDecoration(labelText: 'Minutes spent'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: progressCtl,
                decoration:
                    const InputDecoration(labelText: 'Units completed'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: notesCtl,
                decoration: const InputDecoration(labelText: 'Notes'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final minutes = int.tryParse(minCtl.text) ?? 0;
              final progress = int.tryParse(progressCtl.text) ?? 0;
              if (minutes <= 0) return;

              final session = StudySession(
                date: DateTime.now(),
                minutesSpent: minutes,
                progressDelta: progress,
                notes: notesCtl.text.trim().isEmpty
                    ? null
                    : notesCtl.text.trim(),
              );

              final updated = item.copyWith(
                sessions: [...item.sessions, session],
                completedUnits:
                    (item.completedUnits + progress).clamp(0, item.totalUnits > 0 ? item.totalUnits : item.completedUnits + progress),
                status: item.status == LearningStatus.planned
                    ? LearningStatus.inProgress
                    : item.status,
                dateStarted: item.dateStarted ?? DateTime.now(),
              );

              // Auto-complete if all units done
              final finalItem = updated.totalUnits > 0 &&
                      updated.completedUnits >= updated.totalUnits
                  ? updated.copyWith(
                      status: LearningStatus.completed,
                      dateCompleted: DateTime.now(),
                    )
                  : updated;

              _service.updateItem(finalItem);
              _save();
              setState(() {});
              Navigator.pop(ctx);

              if (finalItem.status == LearningStatus.completed) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 Completed "${item.title}"!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  void _handleItemAction(String action, LearningItem item) {
    switch (action) {
      case 'edit':
        _showEditDialog(item);
        break;
      case 'status':
        _showStatusDialog(item);
        break;
      case 'rate':
        _showRateDialog(item);
        break;
      case 'delete':
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Item'),
            content: Text('Delete "${item.title}"?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              TextButton(
                onPressed: () {
                  _service.removeItem(item.id);
                  _save();
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
        break;
    }
  }

  void _showEditDialog(LearningItem item) {
    final titleCtl = TextEditingController(text: item.title);
    final sourceCtl = TextEditingController(text: item.source ?? '');
    final unitsCtl = TextEditingController(text: '${item.totalUnits}');
    final completedCtl =
        TextEditingController(text: '${item.completedUnits}');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: titleCtl,
                  decoration: const InputDecoration(labelText: 'Title')),
              TextField(
                  controller: sourceCtl,
                  decoration: const InputDecoration(labelText: 'Source')),
              TextField(
                  controller: unitsCtl,
                  decoration:
                      const InputDecoration(labelText: 'Total Units'),
                  keyboardType: TextInputType.number),
              TextField(
                  controller: completedCtl,
                  decoration:
                      const InputDecoration(labelText: 'Completed Units'),
                  keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final updated = item.copyWith(
                title: titleCtl.text.trim(),
                source: sourceCtl.text.trim().isEmpty
                    ? null
                    : sourceCtl.text.trim(),
                totalUnits: int.tryParse(unitsCtl.text) ?? item.totalUnits,
                completedUnits:
                    int.tryParse(completedCtl.text) ?? item.completedUnits,
              );
              _service.updateItem(updated);
              _save();
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(LearningItem item) {
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Change Status'),
        children: LearningStatus.values
            .map((s) => SimpleDialogOption(
                  onPressed: () {
                    final updated = item.copyWith(
                      status: s,
                      dateStarted: s == LearningStatus.inProgress &&
                              item.dateStarted == null
                          ? DateTime.now()
                          : item.dateStarted,
                      dateCompleted: s == LearningStatus.completed
                          ? DateTime.now()
                          : null,
                    );
                    _service.updateItem(updated);
                    _save();
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: Text('${s.emoji} ${s.label}'),
                ))
            .toList(),
      ),
    );
  }

  void _showRateDialog(LearningItem item) {
    showDialog(
      context: context,
      builder: (ctx) {
        var rating = item.rating ?? 3;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Rate'),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (i) => IconButton(
                        icon: Icon(
                          i < rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () =>
                            setDialogState(() => rating = i + 1),
                      )),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel')),
              FilledButton(
                onPressed: () {
                  _service.updateItem(item.copyWith(rating: rating));
                  _save();
                  setState(() {});
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showItemDetail(LearningItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (ctx, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('${item.type.emoji} ${item.title}',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            if (item.source != null)
              Text(item.source!,
                  style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                Chip(label: Text(item.status.label)),
                Chip(label: Text(item.category.label)),
                Chip(label: Text(item.type.label)),
                Chip(label: Text('Priority ${item.priority}')),
              ],
            ),
            const SizedBox(height: 12),
            if (item.totalUnits > 0) ...[
              Text(
                  'Progress: ${item.completedUnits}/${item.totalUnits} (${item.progressPercent.toStringAsFixed(0)}%)'),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: item.progressPercent / 100,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 12),
            ],
            Text('Time studied: ${item.hoursStudied.toStringAsFixed(1)} hours'),
            Text('Sessions: ${item.sessions.length}'),
            if (item.sessions.isNotEmpty)
              Text(
                  'Avg session: ${item.averageSessionMinutes.toStringAsFixed(0)} min'),
            Text('Days active: ${item.daysActive}'),
            if (item.rating != null) ...[
              const SizedBox(height: 8),
              Row(
                children: List.generate(
                    5,
                    (i) => Icon(
                          i < item.rating! ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        )),
              ),
            ],
            if (item.notes != null) ...[
              const SizedBox(height: 12),
              Text('Notes: ${item.notes}'),
            ],
            if (item.sessions.isNotEmpty) ...[
              const Divider(),
              const Text('Study Sessions',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ...item.sessions.reversed.take(10).map((s) => ListTile(
                    dense: true,
                    title: Text(
                        '${s.minutesSpent} min • ${s.progressDelta} units'),
                    subtitle: Text(_formatDate(s.date)),
                    trailing: s.notes != null
                        ? Tooltip(
                            message: s.notes!,
                            child: const Icon(Icons.note, size: 16))
                        : null,
                  )),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────

  Color _priorityColor(int priority) {
    switch (priority) {
      case 5:
        return Colors.red[100]!;
      case 4:
        return Colors.orange[100]!;
      case 3:
        return Colors.yellow[100]!;
      case 2:
        return Colors.blue[100]!;
      default:
        return Colors.grey[200]!;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
