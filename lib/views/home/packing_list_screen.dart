import 'package:flutter/material.dart';
import '../../core/services/packing_list_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/packing_item.dart';

/// Screen for managing packing lists with trip templates, category grouping,
/// progress tracking, weight breakdown, and readiness checks.
class PackingListScreen extends StatefulWidget {
  const PackingListScreen({super.key});

  @override
  State<PackingListScreen> createState() => _PackingListScreenState();
}

class _PackingListScreenState extends State<PackingListScreen>
    with PersistentStateMixin {
  @override
  String get storageKey => 'packing_list_data';
  @override
  String exportData() => _service.exportJson();
  @override
  void importData(String json) => _service.importJson(json);

  late final PackingListService _service;
  String? _selectedListId;
  PackingCategory? _filterCategory;

  @override
  void initState() {
    super.initState();
    _service = PackingListService();
    initPersistence();
  }

  PackingList? get _selectedList =>
      _selectedListId != null ? _service.getList(_selectedListId!) : null;

  // ── Create from template ────────────────────────────────────

  void _showCreateDialog() {
    final nameController = TextEditingController();
    final daysController = TextEditingController(text: '3');
    var selectedTemplate = PackingTemplateType.weekend;
    DateTime? departure;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('New Packing List'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Trip name',
                    hintText: 'e.g. Hawaii Vacation',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PackingTemplateType>(
                  value: selectedTemplate,
                  decoration: const InputDecoration(
                    labelText: 'Template',
                    border: OutlineInputBorder(),
                  ),
                  items: PackingTemplateType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text('${t.emoji} ${t.label}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedTemplate = v);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Trip days',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(departure != null
                      ? 'Departure: ${_formatDate(departure!)}'
                      : 'Set departure date'),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: DateTime.now().add(const Duration(days: 7)),
                      firstDate: DateTime.now(),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 2)),
                    );
                    if (picked != null) {
                      setDialogState(() => departure = picked);
                    }
                  },
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
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final days = int.tryParse(daysController.text) ?? 3;
                setState(() {
                  final list = selectedTemplate == PackingTemplateType.custom
                      ? _service.createEmpty(
                          name: name, departureDate: departure)
                      : _service.createFromTemplate(
                          name: name,
                          templateType: selectedTemplate,
                          tripDays: days,
                          departureDate: departure,
                        );
                  _selectedListId = list.id;
                });
                savePersistentState();
                Navigator.pop(ctx);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Add custom item ─────────────────────────────────────────

  void _showAddItemDialog() {
    if (_selectedListId == null) return;
    final nameController = TextEditingController();
    final weightController = TextEditingController();
    final notesController = TextEditingController();
    var category = PackingCategory.misc;
    var priority = PackingPriority.important;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Item'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Item name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PackingCategory>(
                  value: category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: PackingCategory.values
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text('${c.emoji} ${c.label}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => category = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<PackingPriority>(
                  value: priority,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    border: OutlineInputBorder(),
                  ),
                  items: PackingPriority.values
                      .map((p) => DropdownMenuItem(
                            value: p,
                            child: Text('${p.emoji} ${p.label}'),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => priority = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: weightController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weight (grams, optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (optional)',
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
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  _service.addItem(
                    _selectedListId!,
                    name: name,
                    category: category,
                    priority: priority,
                    weightGrams:
                        double.tryParse(weightController.text.trim()),
                    notes: notesController.text.trim().isEmpty
                        ? null
                        : notesController.text.trim(),
                  );
                });
                savePersistentState();
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Readiness dialog ────────────────────────────────────────

  void _showReadinessCheck() {
    if (_selectedListId == null) return;
    final check = _service.readinessCheck(_selectedListId!);
    if (check == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              check.isReady ? Icons.check_circle : Icons.warning,
              color: check.isReady ? Colors.green : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Expanded(child: Text('Readiness Check')),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: check.progressPercent / 100,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Text('${check.progressPercent.toStringAsFixed(1)}% packed'),
              if (check.daysUntilDeparture >= 0) ...[
                const SizedBox(height: 4),
                Text(
                  check.daysUntilDeparture == 0
                      ? '🚨 Departing TODAY!'
                      : '📅 ${check.daysUntilDeparture} day${check.daysUntilDeparture == 1 ? '' : 's'} until departure',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: check.daysUntilDeparture <= 1
                        ? Colors.red
                        : null,
                  ),
                ),
              ],
              if (check.essentialUnpacked.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('🔴 Essential items still unpacked:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700)),
                ...check.essentialUnpacked
                    .map((i) => Padding(
                          padding: const EdgeInsets.only(left: 16, top: 4),
                          child: Text('• ${i.name}'),
                        )),
              ],
              if (check.importantUnpacked.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text('🟡 Important items still unpacked:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700)),
                ...check.importantUnpacked
                    .take(5)
                    .map((i) => Padding(
                          padding: const EdgeInsets.only(left: 16, top: 4),
                          child: Text('• ${i.name}'),
                        )),
                if (check.importantUnpacked.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text(
                        '... and ${check.importantUnpacked.length - 5} more'),
                  ),
              ],
              if (check.isReady) ...[
                const SizedBox(height: 16),
                const Text('✅ All essentials packed — you\'re ready to go!',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Weight breakdown dialog ─────────────────────────────────

  void _showWeightBreakdown() {
    if (_selectedListId == null) return;
    final wb = _service.weightBreakdown(_selectedListId!);
    if (wb == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.scale, color: Colors.blueGrey),
            SizedBox(width: 8),
            Text('Weight Breakdown'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${wb.totalWeightKg} kg total',
                style: Theme.of(ctx)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ...wb.byCategory.entries.map((e) {
                final cat = e.key;
                final kg = e.value;
                final pct = wb.totalWeightKg > 0
                    ? (kg / wb.totalWeightKg * 100)
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text('${cat.emoji} ${cat.label}'),
                      const Spacer(),
                      Text('${kg} kg (${pct.toStringAsFixed(0)}%)'),
                    ],
                  ),
                );
              }),
              if (wb.heaviestItem.isNotEmpty) ...[
                const Divider(height: 24),
                Text('Heaviest: ${wb.heaviestItem} '
                    '(${wb.heaviestItemWeightGrams.toStringAsFixed(0)}g)'),
              ],
              if (wb.itemsWithoutWeight > 0)
                Text('${wb.itemsWithoutWeight} items without weight data',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Color _priorityColor(PackingPriority p) {
    switch (p) {
      case PackingPriority.essential:
        return Colors.red;
      case PackingPriority.important:
        return Colors.orange;
      case PackingPriority.optional:
        return Colors.green;
    }
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final lists = _service.allLists;
    final selected = _selectedList;

    return Scaffold(
      appBar: AppBar(
        title: Text(selected != null
            ? '${selected.templateType.emoji} ${selected.name}'
            : '🧳 Packing Lists'),
        actions: [
          if (selected != null) ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              tooltip: 'Readiness check',
              onPressed: _showReadinessCheck,
            ),
            IconButton(
              icon: const Icon(Icons.scale),
              tooltip: 'Weight breakdown',
              onPressed: _showWeightBreakdown,
            ),
            PopupMenuButton<String>(
              onSelected: (v) {
                setState(() {
                  switch (v) {
                    case 'pack_all':
                      _service.packAll(_selectedListId!);
                      break;
                    case 'unpack_all':
                      _service.unpackAll(_selectedListId!);
                      break;
                    case 'archive':
                      _service.archiveList(_selectedListId!);
                      _selectedListId = null;
                      break;
                    case 'duplicate':
                      final dup = _service.duplicateList(
                        _selectedListId!,
                        newName: '${selected.name} (copy)',
                      );
                      if (dup != null) _selectedListId = dup.id;
                      break;
                    case 'delete':
                      _service.deleteList(_selectedListId!);
                      _selectedListId = null;
                      break;
                    case 'back':
                      _selectedListId = null;
                      _filterCategory = null;
                      break;
                  }
                });
                savePersistentState();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'pack_all', child: Text('✅ Pack all')),
                const PopupMenuItem(
                    value: 'unpack_all', child: Text('↩️ Unpack all')),
                const PopupMenuItem(
                    value: 'duplicate', child: Text('📋 Duplicate list')),
                const PopupMenuItem(
                    value: 'archive', child: Text('📦 Archive')),
                const PopupMenuItem(
                    value: 'delete',
                    child:
                        Text('🗑️ Delete', style: TextStyle(color: Colors.red))),
                const PopupMenuDivider(),
                const PopupMenuItem(
                    value: 'back', child: Text('← All lists')),
              ],
            ),
          ],
        ],
      ),
      body: selected != null ? _buildListDetail(selected) : _buildListOverview(lists),
      floatingActionButton: FloatingActionButton(
        onPressed: selected != null ? _showAddItemDialog : _showCreateDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── List overview ───────────────────────────────────────────

  Widget _buildListOverview(List<PackingList> lists) {
    if (lists.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.luggage, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No packing lists yet',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text('Tap + to create one from a template'),
          ],
        ),
      );
    }

    final active = lists.where((l) => !l.isArchived).toList();
    final archived = lists.where((l) => l.isArchived).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (active.isNotEmpty) ...[
          Text('Active', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...active.map(_buildListCard),
        ],
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Archived', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...archived.map(_buildListCard),
        ],
      ],
    );
  }

  Widget _buildListCard(PackingList list) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(list.templateType.emoji),
        ),
        title: Text(list.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinearProgressIndicator(
              value: list.progressPercent / 100,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 4),
            Text(
              '${list.packedItems}/${list.totalItems} packed • '
              '${list.totalWeightKg.toStringAsFixed(1)} kg'
              '${list.departureDate != null ? ' • ${_formatDate(list.departureDate!)}' : ''}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: list.isArchived
            ? IconButton(
                icon: const Icon(Icons.unarchive),
                onPressed: () {
                  setState(() => _service.unarchiveList(list.id));
                  savePersistentState();
                },
              )
            : null,
        onTap: () {
          setState(() {
            _selectedListId = list.id;
            _filterCategory = null;
          });
        },
      ),
    );
  }

  // ── List detail ─────────────────────────────────────────────

  Widget _buildListDetail(PackingList list) {
    final grouped = _service.itemsByCategory(list.id);
    final categories = grouped.keys.toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    final filteredCategories = _filterCategory != null
        ? categories.where((c) => c == _filterCategory).toList()
        : categories;

    return Column(
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${list.packedItems}/${list.totalItems} packed',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${list.progressPercent.toStringAsFixed(0)}%',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: list.isFullyPacked ? Colors.green : null,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: list.progressPercent / 100,
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
            ],
          ),
        ),
        // Category filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All'),
                selected: _filterCategory == null,
                onSelected: (_) =>
                    setState(() => _filterCategory = null),
              ),
              const SizedBox(width: 8),
              ...categories.map((cat) {
                final count = grouped[cat]?.length ?? 0;
                final packed =
                    grouped[cat]?.where((i) => i.isPacked).length ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text('${cat.emoji} $packed/$count'),
                    selected: _filterCategory == cat,
                    onSelected: (_) => setState(() =>
                        _filterCategory =
                            _filterCategory == cat ? null : cat),
                  ),
                );
              }),
            ],
          ),
        ),
        // Items
        Expanded(
          child: filteredCategories.isEmpty
              ? const Center(child: Text('No items in this category'))
              : ListView(
                  padding: const EdgeInsets.only(bottom: 80),
                  children: filteredCategories.expand((cat) {
                    final items = grouped[cat]!;
                    return [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          '${cat.emoji} ${cat.label}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      ...items.map((item) => _buildItemTile(item, list.id)),
                    ];
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _buildItemTile(PackingItem item, String listId) {
    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        setState(() => _service.removeItem(listId, item.id));
        savePersistentState();
      },
      child: CheckboxListTile(
        value: item.isPacked,
        onChanged: (_) {
          setState(() => _service.togglePacked(listId, item.id));
          savePersistentState();
        },
        title: Text(
          '${item.name}${item.quantity > 1 ? ' ×${item.quantity}' : ''}',
          style: TextStyle(
            decoration: item.isPacked ? TextDecoration.lineThrough : null,
            color: item.isPacked ? Colors.grey : null,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                color: _priorityColor(item.priority),
                shape: BoxShape.circle,
              ),
            ),
            Text(item.priority.label,
                style: const TextStyle(fontSize: 12)),
            if (item.weightGrams != null) ...[
              const SizedBox(width: 12),
              Text(
                '${(item.weightGrams! * item.quantity / 1000).toStringAsFixed(2)} kg',
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (item.notes != null) ...[
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  item.notes!,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
        controlAffinity: ListTileControlAffinity.leading,
      ),
    );
  }
}
