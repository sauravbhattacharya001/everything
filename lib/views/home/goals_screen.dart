import 'package:flutter/material.dart';
import '../../core/services/goal_tracker_service.dart';
import '../../models/goal.dart';

/// Goals Tracker screen for managing long-term goals with milestones,
/// progress tracking, deadlines, and category organization.
class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen>
    with SingleTickerProviderStateMixin {
  late final GoalTrackerService _service;
  late final TabController _tabController;
  GoalCategory? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _service = GoalTrackerService();
    _tabController = TabController(length: 3, vsync: this);

    // Add some sample goals for demo
    _service.addGoal(Goal(
      id: 'goal_1',
      title: 'Learn Flutter Advanced',
      description: 'Master state management, animations, and testing',
      category: GoalCategory.education,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      deadline: DateTime.now().add(const Duration(days: 60)),
      progress: 45,
      milestones: [
        Milestone(id: 'ms_1', title: 'Complete Provider tutorial', isCompleted: true, completedAt: DateTime.now().subtract(const Duration(days: 10))),
        Milestone(id: 'ms_2', title: 'Build animation demos', isCompleted: true, completedAt: DateTime.now().subtract(const Duration(days: 5))),
        Milestone(id: 'ms_3', title: 'Write widget tests'),
        Milestone(id: 'ms_4', title: 'Integration testing'),
        Milestone(id: 'ms_5', title: 'Build final project'),
      ],
    ));
    _service.addGoal(Goal(
      id: 'goal_2',
      title: 'Run a half marathon',
      description: 'Train for and complete a 21K race',
      category: GoalCategory.fitness,
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      deadline: DateTime.now().add(const Duration(days: 90)),
      progress: 30,
      milestones: [
        Milestone(id: 'ms_6', title: 'Run 5K without stopping', isCompleted: true),
        Milestone(id: 'ms_7', title: 'Run 10K'),
        Milestone(id: 'ms_8', title: 'Run 15K'),
        Milestone(id: 'ms_9', title: 'Complete half marathon'),
      ],
    ));
    _service.addGoal(Goal(
      id: 'goal_3',
      title: 'Save emergency fund',
      category: GoalCategory.finance,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      progress: 70,
    ));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addGoal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GoalFormSheet(
        onSave: (goal) {
          setState(() => _service.addGoal(goal));
        },
      ),
    );
  }

  void _editGoal(Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GoalFormSheet(
        goal: goal,
        onSave: (updated) {
          setState(() => _service.updateGoal(updated));
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _service.getSummary();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Active (${_service.inProgressGoals.length})'),
            Tab(text: 'Completed (${_service.completedGoals.length})'),
            const Tab(text: 'Overview'),
          ],
        ),
        actions: [
          if (_categoryFilter != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => setState(() => _categoryFilter = null),
              tooltip: 'Clear filter',
            ),
          PopupMenuButton<GoalCategory>(
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter by category',
            onSelected: (cat) => setState(() => _categoryFilter = cat),
            itemBuilder: (_) => GoalCategory.values
                .map((c) => PopupMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Text(c.emoji),
                          const SizedBox(width: 8),
                          Text(c.label),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildGoalList(_filterByCategory(_service.inProgressGoals)),
          _buildGoalList(_filterByCategory(_service.completedGoals)),
          _buildOverview(summary),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addGoal,
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
      ),
    );
  }

  List<Goal> _filterByCategory(List<Goal> goals) {
    if (_categoryFilter == null) return goals;
    return goals.where((g) => g.category == _categoryFilter).toList();
  }

  Widget _buildGoalList(List<Goal> goals) {
    if (goals.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _categoryFilter != null
                  ? 'No goals in this category'
                  : 'No goals yet',
              style: TextStyle(fontSize: 18, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: goals.length,
      itemBuilder: (context, index) => _GoalCard(
        goal: goals[index],
        onTap: () => _showGoalDetail(goals[index]),
        onToggleMilestone: (milestoneId) {
          setState(() => _service.toggleMilestone(goals[index].id, milestoneId));
        },
        onComplete: () {
          setState(() => _service.completeGoal(goals[index].id));
        },
        onEdit: () => _editGoal(goals[index]),
        onArchive: () {
          setState(() => _service.archiveGoal(goals[index].id));
        },
      ),
    );
  }

  void _showGoalDetail(Goal goal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _GoalDetailSheet(
        goal: goal,
        onToggleMilestone: (milestoneId) {
          setState(() => _service.toggleMilestone(goal.id, milestoneId));
          // Refresh the detail sheet
          Navigator.of(ctx).pop();
          final updated = _service.allGoals.firstWhere((g) => g.id == goal.id);
          _showGoalDetail(updated);
        },
        onAddMilestone: (milestone) {
          setState(() => _service.addMilestone(goal.id, milestone));
          Navigator.of(ctx).pop();
          final updated = _service.allGoals.firstWhere((g) => g.id == goal.id);
          _showGoalDetail(updated);
        },
        onUpdateProgress: (progress) {
          setState(() => _service.updateProgress(goal.id, progress));
          Navigator.of(ctx).pop();
          final updated = _service.allGoals.firstWhere((g) => g.id == goal.id);
          _showGoalDetail(updated);
        },
      ),
    );
  }

  Widget _buildOverview(GoalSummary summary) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats cards
          Row(
            children: [
              _StatCard(
                label: 'Active',
                value: '${summary.activeGoals}',
                color: Colors.blue,
                icon: Icons.flag,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Completed',
                value: '${summary.completedGoals}',
                color: Colors.green,
                icon: Icons.check_circle,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StatCard(
                label: 'Overdue',
                value: '${summary.overdueGoals}',
                color: Colors.red,
                icon: Icons.warning,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Avg Progress',
                value: '${(summary.averageProgress * 100).toStringAsFixed(0)}%',
                color: Colors.orange,
                icon: Icons.trending_up,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // By category
          const Text(
            'Goals by Category',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...summary.byCategory.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(entry.key.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(entry.key.label,
                          style: const TextStyle(fontSize: 16)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('${entry.value}',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 24),

          // Urgent goals
          if (_service.overdueGoals.isNotEmpty) ...[
            const Text(
              '⚠️ Overdue Goals',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red),
            ),
            const SizedBox(height: 8),
            ..._service.overdueGoals.map((g) => ListTile(
                  leading: Text(g.category.emoji,
                      style: const TextStyle(fontSize: 24)),
                  title: Text(g.title),
                  subtitle: Text(
                    '${g.daysRemaining!.abs()} days overdue',
                    style: const TextStyle(color: Colors.red),
                  ),
                  trailing: Text(
                    '${(g.effectiveProgress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

// ── Goal Card Widget ────────────────────────────────────────────────

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final VoidCallback onTap;
  final void Function(String) onToggleMilestone;
  final VoidCallback onComplete;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  const _GoalCard({
    required this.goal,
    required this.onTap,
    required this.onToggleMilestone,
    required this.onComplete,
    required this.onEdit,
    required this.onArchive,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal.effectiveProgress;
    final daysLeft = goal.daysRemaining;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: category emoji + title + menu
              Row(
                children: [
                  Text(goal.category.emoji,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: goal.isCompleted
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        if (goal.description.isNotEmpty)
                          Text(
                            goal.description,
                            style: TextStyle(
                                fontSize: 13, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      switch (action) {
                        case 'complete':
                          onComplete();
                          break;
                        case 'edit':
                          onEdit();
                          break;
                        case 'archive':
                          onArchive();
                          break;
                      }
                    },
                    itemBuilder: (_) => [
                      if (!goal.isCompleted)
                        const PopupMenuItem(
                          value: 'complete',
                          child: Row(
                            children: [
                              Icon(Icons.check, size: 18),
                              SizedBox(width: 8),
                              Text('Mark complete'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 18),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'archive',
                        child: Row(
                          children: [
                            Icon(Icons.archive, size: 18),
                            SizedBox(width: 8),
                            Text('Archive'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Progress bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation(
                          goal.isOverdue
                              ? Colors.red
                              : progress >= 1.0
                                  ? Colors.green
                                  : Colors.blue,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Footer: deadline + milestones count
              Row(
                children: [
                  if (daysLeft != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: goal.isOverdue
                            ? Colors.red.withAlpha(25)
                            : Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        goal.isOverdue
                            ? '${daysLeft.abs()}d overdue'
                            : '${daysLeft}d left',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: goal.isOverdue ? Colors.red : Colors.blue,
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (goal.milestones.isNotEmpty) ...[
                    Icon(Icons.checklist, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      '${goal.milestones.where((m) => m.isCompleted).length}/${goal.milestones.length}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      goal.category.label,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stat Card ───────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: color)),
                Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Goal Detail Sheet ───────────────────────────────────────────────

class _GoalDetailSheet extends StatelessWidget {
  final Goal goal;
  final void Function(String) onToggleMilestone;
  final void Function(Milestone) onAddMilestone;
  final void Function(int) onUpdateProgress;

  const _GoalDetailSheet({
    required this.goal,
    required this.onToggleMilestone,
    required this.onAddMilestone,
    required this.onUpdateProgress,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal.effectiveProgress;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Text(goal.category.emoji,
                    style: const TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(goal.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (goal.description.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(goal.description,
                  style: TextStyle(fontSize: 15, color: Colors.grey[600])),
            ],

            const SizedBox(height: 20),

            // Progress
            Text('Progress',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700])),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 12,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation(
                        progress >= 1.0 ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),

            // Manual progress slider (only if no milestones)
            if (goal.milestones.isEmpty) ...[
              const SizedBox(height: 8),
              Slider(
                value: goal.progress.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: '${goal.progress}%',
                onChanged: (v) => onUpdateProgress(v.round()),
              ),
            ],

            const SizedBox(height: 20),

            // Deadline info
            if (goal.deadline != null) ...[
              Row(
                children: [
                  Icon(
                    goal.isOverdue ? Icons.warning : Icons.calendar_today,
                    size: 18,
                    color: goal.isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Deadline: ${_formatDate(goal.deadline!)}',
                    style: TextStyle(
                      color: goal.isOverdue ? Colors.red : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (goal.daysRemaining != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      goal.isOverdue
                          ? '(${goal.daysRemaining!.abs()} days overdue)'
                          : '(${goal.daysRemaining} days left)',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            goal.isOverdue ? Colors.red[300] : Colors.grey[500],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Milestones
            Row(
              children: [
                const Text('Milestones',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _addMilestoneDialog(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add'),
                ),
              ],
            ),
            if (goal.milestones.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No milestones yet. Add milestones to track progress automatically.',
                  style: TextStyle(color: Colors.grey[500], fontSize: 14),
                ),
              )
            else
              ...goal.milestones.map((m) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Checkbox(
                      value: m.isCompleted,
                      onChanged: (_) => onToggleMilestone(m.id),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4)),
                    ),
                    title: Text(
                      m.title,
                      style: TextStyle(
                        decoration: m.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: m.isCompleted ? Colors.grey : null,
                      ),
                    ),
                    subtitle: m.completedAt != null
                        ? Text(
                            'Completed ${_formatDate(m.completedAt!)}',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          )
                        : null,
                  )),

            const SizedBox(height: 24),

            // Meta info
            Text(
              'Created ${_formatDate(goal.createdAt)}  •  ${goal.category.label}',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _addMilestoneDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Milestone'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Milestone title',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.of(ctx).pop();
                onAddMilestone(Milestone(
                  id: 'ms_${DateTime.now().millisecondsSinceEpoch}',
                  title: controller.text.trim(),
                ));
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ── Goal Form Sheet ─────────────────────────────────────────────────

class _GoalFormSheet extends StatefulWidget {
  final Goal? goal;
  final void Function(Goal) onSave;

  const _GoalFormSheet({this.goal, required this.onSave});

  @override
  State<_GoalFormSheet> createState() => _GoalFormSheetState();
}

class _GoalFormSheetState extends State<_GoalFormSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late GoalCategory _category;
  DateTime? _deadline;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.goal?.title ?? '');
    _descController =
        TextEditingController(text: widget.goal?.description ?? '');
    _category = widget.goal?.category ?? GoalCategory.personal;
    _deadline = widget.goal?.deadline;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.goal != null;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isEditing ? 'Edit Goal' : 'New Goal',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _titleController,
              autofocus: !isEditing,
              decoration: const InputDecoration(
                labelText: 'Goal title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Category picker
            DropdownButtonFormField<GoalCategory>(
              value: _category,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: GoalCategory.values
                  .map((c) => DropdownMenuItem(
                        value: c,
                        child: Row(
                          children: [
                            Text(c.emoji),
                            const SizedBox(width: 8),
                            Text(c.label),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 12),

            // Deadline picker
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today),
              title: Text(_deadline != null
                  ? 'Deadline: ${_GoalDetailSheet._formatDate(_deadline!)}'
                  : 'Set deadline (optional)'),
              trailing: _deadline != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _deadline = null),
                    )
                  : null,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                );
                if (picked != null) {
                  if (!mounted) return;
                  setState(() => _deadline = picked);
                }
              },
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final title = _titleController.text.trim();
                  if (title.isEmpty) return;

                  final goal = widget.goal != null
                      ? widget.goal!.copyWith(
                          title: title,
                          description: _descController.text.trim(),
                          category: _category,
                          deadline: _deadline,
                          clearDeadline: _deadline == null,
                        )
                      : Goal(
                          id: 'goal_${DateTime.now().millisecondsSinceEpoch}',
                          title: title,
                          description: _descController.text.trim(),
                          category: _category,
                          createdAt: DateTime.now(),
                          deadline: _deadline,
                        );

                  widget.onSave(goal);
                  Navigator.of(context).pop();
                },
                child: Text(isEditing ? 'Save Changes' : 'Create Goal'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
