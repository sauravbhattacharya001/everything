import 'package:flutter/material.dart';
import '../../core/services/kanban_board_service.dart';

/// Kanban Board Screen — visual task management with draggable columns and cards.
///
/// Features:
/// - Multiple boards with custom columns
/// - Cards with priority, labels, due dates, descriptions
/// - Drag-and-drop cards between columns (via long-press move)
/// - WIP limits with visual warnings
/// - Add/edit/archive cards inline
/// - Board stats summary
/// - Filter by label or priority
class KanbanBoardScreen extends StatefulWidget {
  const KanbanBoardScreen({super.key});

  @override
  State<KanbanBoardScreen> createState() => _KanbanBoardScreenState();
}

class _KanbanBoardScreenState extends State<KanbanBoardScreen> {
  final KanbanBoardService _service = KanbanBoardService();
  KanbanBoard? _currentBoard;
  String? _filterLabel;
  KanbanPriority? _filterPriority;
  bool _showStats = false;

  static const _priorityColors = {
    KanbanPriority.low: Color(0xFF81C784),
    KanbanPriority.medium: Color(0xFF64B5F6),
    KanbanPriority.high: Color(0xFFFFB74D),
    KanbanPriority.urgent: Color(0xFFEF5350),
  };

  static const _priorityIcons = {
    KanbanPriority.low: Icons.arrow_downward,
    KanbanPriority.medium: Icons.remove,
    KanbanPriority.high: Icons.arrow_upward,
    KanbanPriority.urgent: Icons.priority_high,
  };

  @override
  void initState() {
    super.initState();
    _currentBoard = _service.createSampleBoard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentBoard?.name ?? 'Kanban Board'),
        actions: [
          // Filter by label
          PopupMenuButton<String?>(
            icon: Badge(
              isLabelVisible: _filterLabel != null,
              child: const Icon(Icons.label_outline),
            ),
            tooltip: 'Filter by label',
            onSelected: (v) => setState(() => _filterLabel = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All Labels')),
              ...KanbanLabel.defaultLabels.map((l) => PopupMenuItem(
                    value: l.name,
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: l.color,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(l.name),
                      ],
                    ),
                  )),
            ],
          ),
          // Filter by priority
          PopupMenuButton<KanbanPriority?>(
            icon: Badge(
              isLabelVisible: _filterPriority != null,
              child: const Icon(Icons.flag_outlined),
            ),
            tooltip: 'Filter by priority',
            onSelected: (v) => setState(() => _filterPriority = v),
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('All Priorities')),
              ...KanbanPriority.values.map((p) => PopupMenuItem(
                    value: p,
                    child: Row(
                      children: [
                        Icon(_priorityIcons[p], color: _priorityColors[p], size: 18),
                        const SizedBox(width: 8),
                        Text(p.name[0].toUpperCase() + p.name.substring(1)),
                      ],
                    ),
                  )),
            ],
          ),
          // Stats toggle
          IconButton(
            icon: Icon(_showStats ? Icons.bar_chart : Icons.bar_chart_outlined),
            onPressed: () => setState(() => _showStats = !_showStats),
            tooltip: 'Board stats',
          ),
          // Add column
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: _showAddColumnDialog,
            tooltip: 'Add column',
          ),
        ],
      ),
      body: _currentBoard == null
          ? const Center(child: Text('No board'))
          : Column(
              children: [
                if (_showStats) _buildStatsBar(),
                Expanded(child: _buildBoard()),
              ],
            ),
    );
  }

  Widget _buildStatsBar() {
    final stats = _service.getBoardStats(_currentBoard!);
    final columnCounts = stats['columnCounts'] as Map<String, int>;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          _statChip('Total', '${stats['totalCards']}', Colors.blue),
          const SizedBox(width: 8),
          _statChip('Overdue', '${stats['overdueCards']}', Colors.red),
          const SizedBox(width: 8),
          _statChip('Archived', '${stats['archivedCards']}', Colors.grey),
          const Spacer(),
          ...columnCounts.entries.map((e) => Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Chip(
                  label: Text('${e.key}: ${e.value}',
                      style: const TextStyle(fontSize: 11)),
                  visualDensity: VisualDensity.compact,
                ),
              )),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color,
        child: Text(value,
            style: const TextStyle(fontSize: 11, color: Colors.white)),
      ),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildBoard() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8),
      itemCount: _currentBoard!.columns.length,
      itemBuilder: (context, index) {
        final column = _currentBoard!.columns[index];
        return _buildColumn(column);
      },
    );
  }

  Widget _buildColumn(KanbanColumn column) {
    var cards = column.activeCards;

    // Apply filters
    if (_filterLabel != null) {
      cards = cards
          .where((c) => c.labels.any((l) => l.name == _filterLabel))
          .toList();
    }
    if (_filterPriority != null) {
      cards = cards.where((c) => c.priority == _filterPriority).toList();
    }

    final isOverWip = column.isOverWipLimit;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isOverWip
              ? const BorderSide(color: Colors.red, width: 2)
              : BorderSide.none,
        ),
        child: Column(
          children: [
            // Column header
            Container(
              decoration: BoxDecoration(
                color: column.color.withOpacity(0.3),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          column.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          '${cards.length} cards'
                          '${column.wipLimit != null ? ' / ${column.wipLimit} limit' : ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isOverWip ? Colors.red : Colors.grey,
                            fontWeight:
                                isOverWip ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 20),
                    onPressed: () => _showAddCardDialog(column),
                    tooltip: 'Add card',
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
            // Cards list
            Expanded(
              child: cards.isEmpty
                  ? Center(
                      child: Text(
                        'No cards',
                        style: TextStyle(
                            color: Colors.grey.shade400, fontSize: 13),
                      ),
                    )
                  : ReorderableListView.builder(
                      padding: const EdgeInsets.all(4),
                      itemCount: cards.length,
                      onReorder: (oldIdx, newIdx) {
                        setState(() {
                          _service.reorderCard(column, oldIdx, newIdx);
                        });
                      },
                      itemBuilder: (context, index) {
                        return _buildCard(
                          key: ValueKey(cards[index].id),
                          card: cards[index],
                          column: column,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({
    required Key key,
    required KanbanCard card,
    required KanbanColumn column,
  }) {
    final priorityColor = _priorityColors[card.priority]!;
    final isOverdue = card.isOverdue;

    return Card(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isOverdue ? Colors.red.shade300 : Colors.transparent,
          width: isOverdue ? 1.5 : 0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _showCardDetail(card, column),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Labels row
              if (card.labels.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Wrap(
                    spacing: 4,
                    children: card.labels
                        .map((l) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: l.color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(l.name,
                                  style: TextStyle(
                                      fontSize: 10, color: l.color)),
                            ))
                        .toList(),
                  ),
                ),
              // Title + priority
              Row(
                children: [
                  Icon(_priorityIcons[card.priority],
                      size: 14, color: priorityColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      card.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
              // Description preview
              if (card.description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    card.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              // Due date
              if (card.dueDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        size: 12,
                        color: isOverdue ? Colors.red : Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(card.dueDate!),
                        style: TextStyle(
                          fontSize: 11,
                          color: isOverdue ? Colors.red : Colors.grey,
                          fontWeight:
                              isOverdue ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCardDetail(KanbanCard card, KanbanColumn fromColumn) {
    final otherColumns =
        _currentBoard!.columns.where((c) => c.id != fromColumn.id).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            // Header
            Row(
              children: [
                Icon(_priorityIcons[card.priority],
                    color: _priorityColors[card.priority]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(card.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Labels
            if (card.labels.isNotEmpty)
              Wrap(
                spacing: 6,
                children: card.labels
                    .map((l) => Chip(
                          label: Text(l.name, style: const TextStyle(fontSize: 12)),
                          backgroundColor: l.color.withOpacity(0.2),
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
            const SizedBox(height: 12),
            // Description
            if (card.description.isNotEmpty) ...[
              const Text('Description',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Text(card.description),
              const SizedBox(height: 12),
            ],
            // Due date
            if (card.dueDate != null) ...[
              Row(
                children: [
                  Icon(Icons.calendar_today,
                      size: 16,
                      color: card.isOverdue ? Colors.red : Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Due: ${_formatDate(card.dueDate!)}',
                    style: TextStyle(
                      color: card.isOverdue ? Colors.red : null,
                      fontWeight:
                          card.isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (card.isOverdue) ...[
                    const SizedBox(width: 6),
                    const Text('OVERDUE',
                        style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 11)),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
            // Column info
            Text('Column: ${fromColumn.name}',
                style: const TextStyle(color: Colors.grey)),
            const Divider(height: 24),
            // Move to column
            if (otherColumns.isNotEmpty) ...[
              const Text('Move to:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                children: otherColumns
                    .map((col) => ActionChip(
                          avatar: CircleAvatar(
                            backgroundColor: col.color,
                            radius: 8,
                          ),
                          label: Text(col.name),
                          onPressed: () {
                            setState(() {
                              _service.moveCard(card, fromColumn, col);
                            });
                            Navigator.pop(ctx);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 12),
            ],
            // Archive button
            OutlinedButton.icon(
              onPressed: () {
                setState(() => _service.archiveCard(card));
                Navigator.pop(ctx);
              },
              icon: const Icon(Icons.archive_outlined),
              label: const Text('Archive'),
              style: OutlinedButton.styleFrom(foregroundColor: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCardDialog(KanbanColumn column) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    var priority = KanbanPriority.medium;
    final selectedLabels = <KanbanLabel>[];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Add card to ${column.name}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                // Priority selector
                DropdownButtonFormField<KanbanPriority>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: KanbanPriority.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Row(
                              children: [
                                Icon(_priorityIcons[p],
                                    color: _priorityColors[p], size: 16),
                                const SizedBox(width: 8),
                                Text(p.name[0].toUpperCase() +
                                    p.name.substring(1)),
                              ],
                            ),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => priority = v ?? priority),
                ),
                const SizedBox(height: 12),
                // Labels
                Wrap(
                  spacing: 6,
                  children: KanbanLabel.defaultLabels
                      .map((l) => FilterChip(
                            label: Text(l.name, style: const TextStyle(fontSize: 12)),
                            selected: selectedLabels.contains(l),
                            selectedColor: l.color.withOpacity(0.3),
                            onSelected: (sel) {
                              setDialogState(() {
                                sel
                                    ? selectedLabels.add(l)
                                    : selectedLabels.remove(l);
                              });
                            },
                          ))
                      .toList(),
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
                if (titleCtrl.text.trim().isEmpty) return;
                setState(() {
                  _service.addCard(
                    column,
                    title: titleCtrl.text.trim(),
                    description: descCtrl.text.trim(),
                    priority: priority,
                    labels: List.of(selectedLabels),
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddColumnDialog() {
    final nameCtrl = TextEditingController();
    var selectedColor = Colors.blue;
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Column'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Column name',
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: colors
                    .map((c) => GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: c,
                            child: selectedColor == c
                                ? const Icon(Icons.check,
                                    size: 16, color: Colors.white)
                                : null,
                          ),
                        ))
                    .toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) return;
                setState(() {
                  _service.addColumn(
                    _currentBoard!,
                    nameCtrl.text.trim(),
                    selectedColor,
                  );
                });
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
