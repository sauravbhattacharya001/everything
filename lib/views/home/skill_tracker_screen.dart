import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/skill_tracker_service.dart';
import '../../models/skill_entry.dart';

/// Skill Tracker screen for managing learning goals, logging practice
/// sessions, tracking milestones, and viewing learning portfolio insights.
class SkillTrackerScreen extends StatefulWidget {
  const SkillTrackerScreen({super.key});

  @override
  State<SkillTrackerScreen> createState() => _SkillTrackerScreenState();
}

class _SkillTrackerScreenState extends State<SkillTrackerScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'skill_tracker_data';
  late TabController _tabController;
  late SkillTrackerService _service;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _service = SkillTrackerService();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null && json.isNotEmpty) {
      try {
        final data = jsonDecode(json) as List<dynamic>;
        _service = SkillTrackerService();
        for (final item in data) {
          _service.addSkill(
              SkillEntry.fromJson(item as Map<String, dynamic>));
        }
      } catch (_) {
        _service = SkillTrackerService();
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final data = _service.skills.map((s) => s.toJson()).toList();
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
        title: const Text('Skill Tracker'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.school), text: 'Skills'),
            Tab(icon: Icon(Icons.timer), text: 'Practice'),
            Tab(icon: Icon(Icons.flag), text: 'Milestones'),
            Tab(icon: Icon(Icons.insights), text: 'Portfolio'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _SkillsTab(
                  service: _service,
                  onChanged: () {
                    _save();
                    setState(() {});
                  },
                ),
                _PracticeTab(
                  service: _service,
                  onChanged: () {
                    _save();
                    setState(() {});
                  },
                ),
                _MilestonesTab(
                  service: _service,
                  onChanged: () {
                    _save();
                    setState(() {});
                  },
                ),
                _PortfolioTab(service: _service),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  Tab 1: Skills — manage skills being learned
// ─────────────────────────────────────────────────────────────────────

class _SkillsTab extends StatefulWidget {
  final SkillTrackerService service;
  final VoidCallback onChanged;

  const _SkillsTab({required this.service, required this.onChanged});

  @override
  State<_SkillsTab> createState() => _SkillsTabState();
}

class _SkillsTabState extends State<_SkillsTab> {
  bool _showArchived = false;
  SkillCategory? _filterCategory;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    var skills = _showArchived
        ? widget.service.archivedSkills
        : widget.service.activeSkills;
    if (_filterCategory != null) {
      skills = skills.where((s) => s.category == _filterCategory).toList();
    }

    return Column(
      children: [
        // Filter row
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Category filter
              Expanded(
                child: DropdownButtonFormField<SkillCategory?>(
                  value: _filterCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Categories')),
                    ...SkillCategory.values.map(
                      (c) => DropdownMenuItem(
                          value: c, child: Text('${c.emoji} ${c.label}')),
                    ),
                  ],
                  onChanged: (v) => setState(() => _filterCategory = v),
                ),
              ),
              const SizedBox(width: 8),
              // Toggle archived
              FilterChip(
                label: Text(_showArchived ? 'Archived' : 'Active'),
                selected: _showArchived,
                onSelected: (v) => setState(() => _showArchived = v),
              ),
            ],
          ),
        ),
        // Skills list
        Expanded(
          child: skills.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.school_outlined, size: 64, color: cs.outline),
                      const SizedBox(height: 12),
                      Text(
                        _showArchived
                            ? 'No archived skills'
                            : 'No skills yet — tap + to start learning!',
                        style: TextStyle(color: cs.outline),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: skills.length,
                  itemBuilder: (ctx, i) =>
                      _SkillCard(skill: skills[i], onAction: _handleAction),
                ),
        ),
        // Add button
        Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _addSkill,
            icon: const Icon(Icons.add),
            label: const Text('Add Skill'),
          ),
        ),
      ],
    );
  }

  void _handleAction(SkillEntry skill, String action) {
    switch (action) {
      case 'archive':
        widget.service.archiveSkill(skill.id);
        widget.onChanged();
        break;
      case 'unarchive':
        widget.service.unarchiveSkill(skill.id);
        widget.onChanged();
        break;
      case 'delete':
        widget.service.removeSkill(skill.id);
        widget.onChanged();
        break;
      case 'levelUp':
        final nextVal = skill.currentLevel.value + 1;
        if (nextVal <= ProficiencyLevel.master.value) {
          widget.service.updateSkill(skill.copyWith(
            currentLevel: ProficiencyLevel.fromValue(nextVal),
          ));
          widget.onChanged();
        }
        break;
    }
    setState(() {});
  }

  Future<void> _addSkill() async {
    final nameCtl = TextEditingController();
    var category = SkillCategory.other;
    var targetLevel = ProficiencyLevel.advanced;
    var weeklyGoal = 120;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add New Skill'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtl,
                  decoration: const InputDecoration(
                    labelText: 'Skill name',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<SkillCategory>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: SkillCategory.values
                      .map((c) => DropdownMenuItem(
                          value: c, child: Text('${c.emoji} ${c.label}')))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => category = v ?? category),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ProficiencyLevel>(
                  value: targetLevel,
                  decoration: const InputDecoration(
                    labelText: 'Target level',
                    border: OutlineInputBorder(),
                  ),
                  items: ProficiencyLevel.values
                      .map((l) =>
                          DropdownMenuItem(value: l, child: Text(l.label)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => targetLevel = v ?? targetLevel),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Weekly goal (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  controller:
                      TextEditingController(text: weeklyGoal.toString()),
                  onChanged: (v) =>
                      weeklyGoal = int.tryParse(v) ?? weeklyGoal,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Add')),
          ],
        ),
      ),
    );

    if (result == true && nameCtl.text.trim().isNotEmpty) {
      final skill = SkillEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: nameCtl.text.trim(),
        category: category,
        targetLevel: targetLevel,
        startedAt: DateTime.now(),
        weeklyGoalMinutes: weeklyGoal,
      );
      widget.service.addSkill(skill);
      widget.onChanged();
      setState(() {});
    }
    nameCtl.dispose();
  }
}

class _SkillCard extends StatelessWidget {
  final SkillEntry skill;
  final void Function(SkillEntry, String) onAction;

  const _SkillCard({required this.skill, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final days = skill.daysSinceStart(now);
    final lastPractice = skill.daysSinceLastPractice(now);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(skill.category.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(skill.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${skill.category.label} · $days days',
                          style:
                              TextStyle(color: cs.outline, fontSize: 12)),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (action) => onAction(skill, action),
                  itemBuilder: (_) => [
                    if (skill.currentLevel.value < ProficiencyLevel.master.value)
                      const PopupMenuItem(
                          value: 'levelUp', child: Text('⬆ Level Up')),
                    if (!skill.isArchived)
                      const PopupMenuItem(
                          value: 'archive', child: Text('📦 Archive')),
                    if (skill.isArchived)
                      const PopupMenuItem(
                          value: 'unarchive', child: Text('📤 Unarchive')),
                    const PopupMenuItem(
                        value: 'delete', child: Text('🗑 Delete')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Level progress
            Row(
              children: [
                Text(skill.currentLevel.label,
                    style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 12),
                const SizedBox(width: 4),
                Text(skill.targetLevel.label,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.primary,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: skill.levelProgress,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            // Stats row
            Row(
              children: [
                _StatChip(
                    icon: Icons.timer, label: '${skill.totalHours}h total'),
                const SizedBox(width: 8),
                _StatChip(
                    icon: Icons.repeat,
                    label: '${skill.sessions.length} sessions'),
                const SizedBox(width: 8),
                if (lastPractice != null)
                  _StatChip(
                    icon: Icons.calendar_today,
                    label: lastPractice == 0
                        ? 'Today'
                        : '${lastPractice}d ago',
                  ),
              ],
            ),
            // Milestones mini-progress
            if (skill.milestones.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.flag, size: 14, color: cs.outline),
                  const SizedBox(width: 4),
                  Text(
                    '${skill.milestones.where((m) => m.completed).length}/${skill.milestones.length} milestones',
                    style: TextStyle(fontSize: 11, color: cs.outline),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: skill.milestoneProgress,
                      borderRadius: BorderRadius.circular(3),
                      minHeight: 4,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.outline),
        const SizedBox(width: 2),
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.outline)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  Tab 2: Practice — log and view practice sessions
// ─────────────────────────────────────────────────────────────────────

class _PracticeTab extends StatefulWidget {
  final SkillTrackerService service;
  final VoidCallback onChanged;

  const _PracticeTab({required this.service, required this.onChanged});

  @override
  State<_PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<_PracticeTab> {
  String? _selectedSkillId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = widget.service.activeSkills;

    if (active.isEmpty) {
      return Center(
        child: Text('Add a skill first to log practice sessions',
            style: TextStyle(color: cs.outline)),
      );
    }

    final selected = _selectedSkillId != null
        ? widget.service.getSkill(_selectedSkillId!)
        : null;
    final sessions = selected?.sessions ?? [];
    final recentSessions =
        List<PracticeSession>.from(sessions)
          ..sort((a, b) => b.startTime.compareTo(a.startTime));

    return Column(
      children: [
        // Skill selector
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            value: _selectedSkillId,
            decoration: const InputDecoration(
              labelText: 'Select skill',
              border: OutlineInputBorder(),
            ),
            items: active
                .map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text('${s.category.emoji} ${s.name}')))
                .toList(),
            onChanged: (v) => setState(() => _selectedSkillId = v),
          ),
        ),
        // Quick stats for selected skill
        if (selected != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _QuickStat(
                    value: '${selected.totalHours}h', label: 'Total'),
                _QuickStat(
                    value: '${selected.sessions.length}',
                    label: 'Sessions'),
                _QuickStat(
                    value: selected.averageQuality.toStringAsFixed(1),
                    label: 'Avg Quality'),
                _QuickStat(
                    value: '${selected.weeklyGoalMinutes ~/ 60}h',
                    label: 'Weekly Goal'),
              ],
            ),
          ),
        // Log practice button
        if (selected != null)
          Padding(
            padding: const EdgeInsets.all(12),
            child: FilledButton.icon(
              onPressed: () => _logPractice(selected),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Log Practice Session'),
            ),
          ),
        // Recent sessions
        Expanded(
          child: recentSessions.isEmpty
              ? Center(
                  child: Text('No practice sessions yet',
                      style: TextStyle(color: cs.outline)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: recentSessions.length,
                  itemBuilder: (ctx, i) {
                    final s = recentSessions[i];
                    final date =
                        '${s.startTime.month}/${s.startTime.day}/${s.startTime.year}';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text('${s.quality}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                        ),
                        title: Text(s.topic ?? 'Practice Session'),
                        subtitle: Text('$date · ${s.durationMinutes} min'),
                        trailing:
                            Text('⭐ ${s.quality}/5',
                                style: const TextStyle(fontSize: 12)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _logPractice(SkillEntry skill) async {
    final durationCtl = TextEditingController(text: '30');
    final topicCtl = TextEditingController();
    final notesCtl = TextEditingController();
    var quality = 3;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Log Practice: ${skill.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: durationCtl,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: topicCtl,
                  decoration: const InputDecoration(
                    labelText: 'Topic/focus (optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtl,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Quality: '),
                    Expanded(
                      child: Slider(
                        value: quality.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        label: '$quality',
                        onChanged: (v) =>
                            setDialogState(() => quality = v.round()),
                      ),
                    ),
                    Text('$quality/5',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel')),
            FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Log')),
          ],
        ),
      ),
    );

    if (result == true) {
      final session = PracticeSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        startTime: DateTime.now(),
        durationMinutes: int.tryParse(durationCtl.text) ?? 30,
        topic: topicCtl.text.isNotEmpty ? topicCtl.text : null,
        notes: notesCtl.text.isNotEmpty ? notesCtl.text : null,
        quality: quality,
      );
      widget.service.logPractice(skill.id, session);
      widget.onChanged();
      setState(() {});
    }
    durationCtl.dispose();
    topicCtl.dispose();
    notesCtl.dispose();
  }
}

class _QuickStat extends StatelessWidget {
  final String value;
  final String label;

  const _QuickStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.outline)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  Tab 3: Milestones — track milestones per skill
// ─────────────────────────────────────────────────────────────────────

class _MilestonesTab extends StatefulWidget {
  final SkillTrackerService service;
  final VoidCallback onChanged;

  const _MilestonesTab({required this.service, required this.onChanged});

  @override
  State<_MilestonesTab> createState() => _MilestonesTabState();
}

class _MilestonesTabState extends State<_MilestonesTab> {
  String? _selectedSkillId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final active = widget.service.activeSkills;

    if (active.isEmpty) {
      return Center(
        child: Text('Add a skill first to track milestones',
            style: TextStyle(color: cs.outline)),
      );
    }

    final selected = _selectedSkillId != null
        ? widget.service.getSkill(_selectedSkillId!)
        : null;
    final milestones = selected?.milestones ?? [];
    final completed = milestones.where((m) => m.completed).length;

    return Column(
      children: [
        // Skill selector
        Padding(
          padding: const EdgeInsets.all(12),
          child: DropdownButtonFormField<String>(
            value: _selectedSkillId,
            decoration: const InputDecoration(
              labelText: 'Select skill',
              border: OutlineInputBorder(),
            ),
            items: active
                .map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text('${s.category.emoji} ${s.name}')))
                .toList(),
            onChanged: (v) => setState(() => _selectedSkillId = v),
          ),
        ),
        // Progress header
        if (selected != null && milestones.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('$completed / ${milestones.length} completed',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                        '${(selected.milestoneProgress * 100).round()}%',
                        style: TextStyle(
                            color: cs.primary,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: selected.milestoneProgress,
                  borderRadius: BorderRadius.circular(4),
                  minHeight: 8,
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        // Milestone list
        Expanded(
          child: selected == null
              ? Center(
                  child: Text('Select a skill',
                      style: TextStyle(color: cs.outline)))
              : milestones.isEmpty
                  ? Center(
                      child: Text('No milestones yet — tap + to add one',
                          style: TextStyle(color: cs.outline)))
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: milestones.length,
                      onReorder: (oldIdx, newIdx) {
                        _reorderMilestone(selected, oldIdx, newIdx);
                      },
                      itemBuilder: (ctx, i) {
                        final m = milestones[i];
                        return Card(
                          key: ValueKey(m.id),
                          margin: const EdgeInsets.only(bottom: 6),
                          child: CheckboxListTile(
                            value: m.completed,
                            onChanged: (v) =>
                                _toggleMilestone(selected, m, v ?? false),
                            title: Text(
                              m.title,
                              style: TextStyle(
                                decoration: m.completed
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: m.description != null
                                ? Text(m.description!,
                                    style: TextStyle(
                                        fontSize: 12, color: cs.outline))
                                : null,
                            secondary: m.completed
                                ? Icon(Icons.check_circle,
                                    color: cs.primary)
                                : Icon(Icons.circle_outlined,
                                    color: cs.outline),
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        );
                      },
                    ),
        ),
        // Add milestone button
        if (selected != null)
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () => _addMilestone(selected),
              icon: const Icon(Icons.add),
              label: const Text('Add Milestone'),
            ),
          ),
      ],
    );
  }

  void _toggleMilestone(SkillEntry skill, SkillMilestone milestone, bool completed) {
    if (completed) {
      widget.service.completeMilestone(skill.id, milestone.id, DateTime.now());
    } else {
      widget.service.uncompleteMilestone(skill.id, milestone.id);
    }
    widget.onChanged();
    setState(() {});
  }

  void _reorderMilestone(SkillEntry skill, int oldIdx, int newIdx) {
    if (newIdx > oldIdx) newIdx--;
    final milestones = List<SkillMilestone>.from(skill.milestones);
    final item = milestones.removeAt(oldIdx);
    milestones.insert(newIdx, item);
    final reordered = <SkillMilestone>[];
    for (var i = 0; i < milestones.length; i++) {
      reordered.add(milestones[i].copyWith(orderIndex: i));
    }
    widget.service.updateSkill(skill.copyWith(milestones: reordered));
    widget.onChanged();
    setState(() {});
  }

  Future<void> _addMilestone(SkillEntry skill) async {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Milestone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtl,
              decoration: const InputDecoration(
                labelText: 'Milestone title',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtl,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Add')),
        ],
      ),
    );

    if (result == true && titleCtl.text.trim().isNotEmpty) {
      final milestone = SkillMilestone(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: titleCtl.text.trim(),
        description: descCtl.text.isNotEmpty ? descCtl.text : null,
        orderIndex: skill.milestones.length,
      );
      final milestones = List<SkillMilestone>.from(skill.milestones)
        ..add(milestone);
      widget.service.updateSkill(skill.copyWith(milestones: milestones));
      widget.onChanged();
      setState(() {});
    }
    titleCtl.dispose();
    descCtl.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────
//  Tab 4: Portfolio — learning portfolio insights and reports
// ─────────────────────────────────────────────────────────────────────

class _PortfolioTab extends StatelessWidget {
  final SkillTrackerService service;

  const _PortfolioTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();
    final report = service.generatePortfolioReport(now);
    final streak = service.calculateStreak(now);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Overview card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('📊 Learning Portfolio',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _PortfolioStat(
                        value: '${report.totalSkills}', label: 'Skills'),
                    _PortfolioStat(
                        value: '${report.activeSkills}', label: 'Active'),
                    _PortfolioStat(
                        value: '${report.totalHoursAllTime}h',
                        label: 'Total Hours'),
                    _PortfolioStat(
                        value: '${report.totalSessions}',
                        label: 'Sessions'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Practice streak
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${streak.currentStreak} day streak',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text('Best: ${streak.longestStreak} days',
                        style:
                            TextStyle(color: cs.outline, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Skills by category
        if (report.skillsByCategory.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📂 By Category',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  ...report.skillsByCategory.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${e.key.emoji} ${e.key.label}'),
                            Text('${e.value}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: cs.primary)),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Skills by level
        if (report.skillsByLevel.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📈 By Level',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  ...report.skillsByLevel.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key.label),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text('${e.value}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: cs.onPrimaryContainer)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Individual skill reports
        if (report.skillReports.isNotEmpty) ...[
          const Text('📋 Skill Reports',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          ...report.skillReports.map((sr) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(sr.category.emoji),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(sr.skillName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _gradeColor(sr.grade),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(sr.grade,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                          '${sr.currentLevel.label} → ${sr.targetLevel.label} · ${sr.totalHours}h · ${sr.sessionCount} sessions',
                          style: TextStyle(
                              fontSize: 12, color: cs.outline)),
                      if (sr.insights.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        ...sr.insights.take(2).map((insight) => Text(
                              '💡 $insight',
                              style: TextStyle(
                                  fontSize: 11, color: cs.outline),
                            )),
                      ],
                    ],
                  ),
                ),
              )),
        ],
        const SizedBox(height: 12),
        // Recommendations
        if (report.recommendations.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡 Recommendations',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  ...report.recommendations.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• '),
                            Expanded(child: Text(r,
                                style: const TextStyle(fontSize: 13))),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
      ],
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'A':
        return Colors.green;
      case 'B+':
      case 'B':
        return Colors.teal;
      case 'C+':
      case 'C':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}

class _PortfolioStat extends StatelessWidget {
  final String value;
  final String label;

  const _PortfolioStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 20)),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.outline)),
        ],
      ),
    );
  }
}
