import 'package:flutter/material.dart';
import '../../core/services/accountability_service.dart';

/// Smart Accountability Partner — autonomous cross-tracker commitment
/// monitoring with proactive nudges, risk prediction, and trend analysis.
class AccountabilityScreen extends StatefulWidget {
  const AccountabilityScreen({super.key});

  @override
  State<AccountabilityScreen> createState() => _AccountabilityScreenState();
}

class _AccountabilityScreenState extends State<AccountabilityScreen> {
  final _service = AccountabilityService();
  late List<Commitment> _commitments;
  CommitmentStatus? _filter; // null = all

  @override
  void initState() {
    super.initState();
    _commitments = _service.getSampleCommitments();
  }

  List<Commitment> get _filtered {
    if (_filter == null) return _commitments;
    return _commitments.where((c) => c.status == _filter).toList();
  }

  List<Commitment> get _atRisk => _service.predictAtRisk(_commitments);

  IconData _iconForSource(IconSource src) {
    switch (src) {
      case IconSource.fitness: return Icons.fitness_center;
      case IconSource.goal: return Icons.flag;
      case IconSource.journal: return Icons.book;
      case IconSource.health: return Icons.favorite;
      case IconSource.finance: return Icons.attach_money;
      case IconSource.learning: return Icons.school;
      case IconSource.social: return Icons.people;
    }
  }

  Color _colorForStatus(CommitmentStatus status) {
    switch (status) {
      case CommitmentStatus.overdue: return Colors.red;
      case CommitmentStatus.pending: return Colors.orange;
      case CommitmentStatus.completed: return Colors.green;
      case CommitmentStatus.abandoned: return Colors.grey;
    }
  }

  Color _colorForPriority(CommitmentPriority priority) {
    switch (priority) {
      case CommitmentPriority.high: return Colors.red;
      case CommitmentPriority.medium: return Colors.amber;
      case CommitmentPriority.low: return Colors.blue;
    }
  }

  Color _colorForSeverity(NudgeSeverity severity) {
    switch (severity) {
      case NudgeSeverity.critical: return Colors.red;
      case NudgeSeverity.warning: return Colors.orange;
      case NudgeSeverity.info: return Colors.blue;
    }
  }

  IconData _iconForSeverity(NudgeSeverity severity) {
    switch (severity) {
      case NudgeSeverity.critical: return Icons.error;
      case NudgeSeverity.warning: return Icons.warning_amber;
      case NudgeSeverity.info: return Icons.info_outline;
    }
  }

  String _statusLabel(CommitmentStatus s) {
    switch (s) {
      case CommitmentStatus.overdue: return 'Overdue';
      case CommitmentStatus.pending: return 'Pending';
      case CommitmentStatus.completed: return 'Done';
      case CommitmentStatus.abandoned: return 'Abandoned';
    }
  }

  String _dueLabel(DateTime due) {
    final diff = due.difference(DateTime.now()).inDays;
    if (diff < -1) return '${-diff} days ago';
    if (diff == -1) return 'Yesterday';
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Tomorrow';
    return 'In $diff days';
  }

  void _showAddCommitment() {
    final titleCtrl = TextEditingController();
    var priority = CommitmentPriority.medium;
    var daysUntilDue = 7;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'New Commitment',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'What are you committing to?',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Priority: '),
                  const SizedBox(width: 8),
                  ...CommitmentPriority.values.map((p) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(p.name),
                      selected: priority == p,
                      selectedColor: _colorForPriority(p).withAlpha(51),
                      onSelected: (sel) {
                        if (sel) setSheetState(() => priority = p);
                      },
                    ),
                  )),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text('Due in: '),
                  Expanded(
                    child: Slider(
                      value: daysUntilDue.toDouble(),
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '$daysUntilDue days',
                      onChanged: (v) => setSheetState(() => daysUntilDue = v.round()),
                    ),
                  ),
                  Text('$daysUntilDue d'),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.handshake),
                  label: const Text('Commit'),
                  onPressed: () {
                    if (titleCtrl.text.trim().isEmpty) return;
                    final now = DateTime.now();
                    setState(() {
                      _commitments.add(Commitment(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleCtrl.text.trim(),
                        source: 'Manual',
                        sourceIcon: IconSource.goal,
                        createdDate: now,
                        dueDate: now.add(Duration(days: daysUntilDue)),
                        status: CommitmentStatus.pending,
                        priority: priority,
                      ));
                    });
                    Navigator.pop(ctx);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = _service.getAccountabilityScore(_commitments);
    final nudges = _service.getProactiveNudges(_commitments);
    final atRisk = _atRisk;
    final trend = _service.getWeeklyTrend();
    final categories = _service.getCategoryBreakdown(_commitments);
    final filtered = _filtered;
    final maxTrendScore = trend.map((t) => t.score).reduce((a, b) => a > b ? a : b);

    return Scaffold(
      appBar: AppBar(title: const Text('Accountability Partner')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCommitment,
        icon: const Icon(Icons.add),
        label: const Text('Commit'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        children: [
          // ── Score Gauge ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Accountability Score',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 140,
                          height: 140,
                          child: CircularProgressIndicator(
                            value: score / 100,
                            strokeWidth: 12,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(
                              score >= 80 ? Colors.green : score >= 50 ? Colors.orange : Colors.red,
                            ),
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$score',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                                color: score >= 80 ? Colors.green : score >= 50 ? Colors.orange : Colors.red,
                              ),
                            ),
                            Text('/100', style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statChip('Completed', _commitments.where((c) => c.status == CommitmentStatus.completed).length.toString(), Colors.green),
                      _statChip('Pending', _commitments.where((c) => c.status == CommitmentStatus.pending).length.toString(), Colors.orange),
                      _statChip('Overdue', _commitments.where((c) => c.status == CommitmentStatus.overdue).length.toString(), Colors.red),
                      _statChip('At Risk', atRisk.length.toString(), Colors.deepOrange),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Proactive Nudges ──
          if (nudges.isNotEmpty) ...[
            Card(
              child: ExpansionTile(
                leading: Icon(Icons.psychology, color: theme.colorScheme.primary),
                title: Text('Proactive Nudges (${nudges.length})',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
                initiallyExpanded: true,
                children: nudges.map((n) => ListTile(
                  leading: Icon(_iconForSeverity(n.severity), color: _colorForSeverity(n.severity)),
                  title: Text(n.message, style: const TextStyle(fontSize: 13)),
                  subtitle: Text('→ ${n.action}',
                    style: TextStyle(fontSize: 12, color: theme.colorScheme.primary, fontStyle: FontStyle.italic)),
                  dense: true,
                )).toList(),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // ── At-Risk Commitments ──
          if (atRisk.isNotEmpty) ...[
            Text('⚠️ At Risk', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...atRisk.map((c) => Card(
              color: Colors.red.withAlpha(15),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.red.withAlpha(30),
                  child: Icon(_iconForSource(c.sourceIcon), color: Colors.red, size: 20),
                ),
                title: Text(c.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text('${c.source} · Due ${_dueLabel(c.dueDate)}'),
                trailing: FilledButton.tonal(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Recommitted to: ${c.title}')),
                    );
                  },
                  child: const Text('Recommit', style: TextStyle(fontSize: 12)),
                ),
              ),
            )),
            const SizedBox(height: 12),
          ],

          // ── Weekly Trend ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Weekly Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 100,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: trend.map((t) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 3),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${t.score}', style: const TextStyle(fontSize: 10)),
                              const SizedBox(height: 4),
                              Container(
                                height: maxTrendScore > 0 ? (t.score / maxTrendScore) * 70 : 0,
                                decoration: BoxDecoration(
                                  color: t.score >= 75 ? Colors.green : t.score >= 50 ? Colors.orange : Colors.red,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(t.label, style: const TextStyle(fontSize: 9)),
                            ],
                          ),
                        ),
                      )).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Category Breakdown ──
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('By Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...categories.map((cat) {
                    final pct = cat.count > 0 ? cat.completed / cat.count : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(width: 110, child: Text(cat.name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis)),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: pct,
                                minHeight: 8,
                                backgroundColor: Colors.grey[200],
                                valueColor: AlwaysStoppedAnimation(
                                  pct >= 0.8 ? Colors.green : pct >= 0.5 ? Colors.orange : Colors.red,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${cat.completed}/${cat.count}', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── Filter Chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(label: const Text('All'), selected: _filter == null,
                  onSelected: (_) => setState(() => _filter = null)),
                const SizedBox(width: 6),
                ...CommitmentStatus.values.map((s) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(_statusLabel(s)),
                    selected: _filter == s,
                    selectedColor: _colorForStatus(s).withAlpha(40),
                    onSelected: (_) => setState(() => _filter = _filter == s ? null : s),
                  ),
                )),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ── Commitment List ──
          ...filtered.map((c) => Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _colorForStatus(c.status).withAlpha(30),
                child: Icon(_iconForSource(c.sourceIcon), size: 20, color: _colorForStatus(c.status)),
              ),
              title: Text(c.title, style: TextStyle(
                fontWeight: FontWeight.w500,
                decoration: c.status == CommitmentStatus.completed ? TextDecoration.lineThrough : null,
              )),
              subtitle: Row(
                children: [
                  Text(c.source, style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: _colorForPriority(c.priority).withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(c.priority.name, style: TextStyle(fontSize: 10, color: _colorForPriority(c.priority))),
                  ),
                  const SizedBox(width: 8),
                  Text(_dueLabel(c.dueDate), style: TextStyle(fontSize: 11, color: _colorForStatus(c.status))),
                ],
              ),
              trailing: c.status == CommitmentStatus.pending
                ? IconButton(
                    icon: const Icon(Icons.check_circle_outline),
                    onPressed: () => setState(() => c.status = CommitmentStatus.completed),
                  )
                : Icon(
                    c.status == CommitmentStatus.completed ? Icons.check_circle :
                    c.status == CommitmentStatus.overdue ? Icons.schedule :
                    Icons.cancel,
                    color: _colorForStatus(c.status),
                    size: 20,
                  ),
            ),
          )),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
      ],
    );
  }
}
