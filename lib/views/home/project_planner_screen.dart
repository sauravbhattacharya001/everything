import 'package:flutter/material.dart';
import '../../core/services/project_planner_service.dart';

/// Project Planner – manage projects with milestones and tasks.
///
/// Each project contains milestones, and each milestone contains tasks.
/// Progress bars show completion at every level.
class ProjectPlannerScreen extends StatefulWidget {
  const ProjectPlannerScreen({super.key});

  @override
  State<ProjectPlannerScreen> createState() => _ProjectPlannerScreenState();
}

class _ProjectPlannerScreenState extends State<ProjectPlannerScreen> {
  final _service = ProjectPlannerService();
  bool _loading = true;

  static const _palette = [
    'FF6750A4', 'FF2196F3', 'FF4CAF50', 'FFF44336',
    'FFFF9800', 'FF9C27B0', 'FF00BCD4', 'FF795548',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await _service.load();
    if (mounted) setState(() => _loading = false);
  }

  // ── Project CRUD ──────────────────────────────────────────────

  void _addProject() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String colorHex = _palette[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('New Project'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Project Name'),
                  autofocus: true,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: _palette.map((c) {
                    final selected = c == colorHex;
                    return GestureDetector(
                      onTap: () => setDlg(() => colorHex = c),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(int.parse(c, radix: 16)),
                        child: selected
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (nameCtrl.text.trim().isEmpty) return;
                await _service.addProject(Project(
                  id: _service.nextId(),
                  name: nameCtrl.text.trim(),
                  description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                  createdAt: DateTime.now(),
                  colorHex: colorHex,
                ));
                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteProject(Project project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text('This will permanently delete "${project.name}" and all its milestones.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _service.deleteProject(project.id);
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  // ── Milestone CRUD ────────────────────────────────────────────

  void _addMilestone(Project project) {
    final ctrl = TextEditingController();
    DateTime? target;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('New Milestone'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: ctrl,
                decoration: const InputDecoration(labelText: 'Milestone Title'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(target != null
                    ? 'Target: ${_fmtDate(target!)}'
                    : 'No target date'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final d = await showDatePicker(
                    context: ctx,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (d != null) setDlg(() => target = d);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                if (ctrl.text.trim().isEmpty) return;
                project.milestones.add(Milestone(
                  id: _service.nextId(),
                  title: ctrl.text.trim(),
                  targetDate: target,
                ));
                await _service.updateProject(project);
                if (mounted) {
                  Navigator.pop(ctx);
                  setState(() {});
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMilestone(Project project, Milestone milestone) async {
    project.milestones.removeWhere((m) => m.id == milestone.id);
    await _service.updateProject(project);
    if (mounted) setState(() {});
  }

  // ── Task CRUD ─────────────────────────────────────────────────

  void _addTask(Project project, Milestone milestone) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Task'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Task'),
          autofocus: true,
          onSubmitted: (_) => _submitTask(ctx, ctrl, project, milestone),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => _submitTask(ctx, ctrl, project, milestone),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitTask(
      BuildContext ctx, TextEditingController ctrl, Project project, Milestone milestone) async {
    if (ctrl.text.trim().isEmpty) return;
    milestone.tasks.add(ProjectTask(
      id: _service.nextId(),
      title: ctrl.text.trim(),
    ));
    await _service.updateProject(project);
    if (mounted) {
      Navigator.pop(ctx);
      setState(() {});
    }
  }

  void _toggleTask(Project project, Milestone milestone, ProjectTask task) async {
    task.completed = !task.completed;
    await _service.updateProject(project);
    if (mounted) setState(() {});
  }

  void _deleteTask(Project project, Milestone milestone, ProjectTask task) async {
    milestone.tasks.removeWhere((t) => t.id == task.id);
    await _service.updateProject(project);
    if (mounted) setState(() {});
  }

  // ── Helpers ───────────────────────────────────────────────────

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Project Planner')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addProject,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _service.projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.rocket_launch, size: 64, color: theme.colorScheme.primary.withAlpha(120)),
                      const SizedBox(height: 16),
                      Text('No projects yet', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      const Text('Tap + to create your first project'),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: _service.projects.length,
                  itemBuilder: (_, i) => _buildProjectCard(_service.projects[i], theme),
                ),
    );
  }

  Widget _buildProjectCard(Project project, ThemeData theme) {
    final color = Color(int.parse(project.colorHex, radix: 16));
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        leading: CircleAvatar(backgroundColor: color, radius: 18,
          child: Text(project.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (project.description != null)
              Text(project.description!, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall),
            const SizedBox(height: 4),
            Row(children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: project.progress,
                    backgroundColor: color.withAlpha(40),
                    color: color,
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text('${project.completedTasks}/${project.totalTasks}',
                style: theme.textTheme.labelSmall),
            ]),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'milestone') _addMilestone(project);
            if (v == 'delete') _deleteProject(project);
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'milestone', child: Text('Add Milestone')),
            const PopupMenuItem(value: 'delete', child: Text('Delete Project')),
          ],
        ),
        children: project.milestones.isEmpty
            ? [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('No milestones — add one from the menu above',
                    style: theme.textTheme.bodySmall),
                ),
              ]
            : project.milestones
                .map((m) => _buildMilestone(project, m, theme, color))
                .toList(),
      ),
    );
  }

  Widget _buildMilestone(Project project, Milestone milestone, ThemeData theme, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withAlpha(80),
        child: ExpansionTile(
          title: Row(
            children: [
              Expanded(child: Text(milestone.title,
                style: const TextStyle(fontWeight: FontWeight.w500))),
              if (milestone.targetDate != null)
                Chip(
                  label: Text(_fmtDate(milestone.targetDate!),
                    style: const TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          subtitle: milestone.tasks.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: LinearProgressIndicator(
                    value: milestone.progress,
                    backgroundColor: color.withAlpha(30),
                    color: color,
                    minHeight: 4,
                  ),
                )
              : null,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.add_task, size: 20),
                onPressed: () => _addTask(project, milestone),
                tooltip: 'Add Task',
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () => _deleteMilestone(project, milestone),
                tooltip: 'Delete Milestone',
              ),
            ],
          ),
          children: milestone.tasks.map((t) {
            return ListTile(
              dense: true,
              leading: Checkbox(
                value: t.completed,
                onChanged: (_) => _toggleTask(project, milestone, t),
              ),
              title: Text(t.title,
                style: TextStyle(
                  decoration: t.completed ? TextDecoration.lineThrough : null,
                  color: t.completed ? theme.colorScheme.outline : null,
                )),
              trailing: IconButton(
                icon: const Icon(Icons.close, size: 16),
                onPressed: () => _deleteTask(project, milestone, t),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
