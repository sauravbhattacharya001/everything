import 'package:flutter/material.dart';
import '../../models/bucket_item.dart';
import '../../core/services/bucket_list_service.dart';
import '../../core/services/screen_persistence.dart';
import '../../core/utils/snackbar_helper.dart';

/// Bucket List screen — 4-tab UI for tracking life dreams and experiences.
class BucketListScreen extends StatefulWidget {
  const BucketListScreen({super.key});
  @override
  State<BucketListScreen> createState() => _BucketListScreenState();
}

class _BucketListScreenState extends State<BucketListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = const BucketListService();
  final _persistence = ScreenPersistence<BucketItem>(
    storageKey: 'bucket_list_entries',
    toJson: (e) => e.toJson(),
    fromJson: BucketItem.fromJson,
  );
  final List<BucketItem> _items = [];
  String _searchQuery = '';
  BucketCategory? _filterCategory;
  bool _showCompletedOnly = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadItems();
  }

  Future<void> _loadItems() async {
    final saved = await _persistence.load();
    if (saved.isNotEmpty) {
      setState(() => _items.addAll(saved));
    }
  }

  Future<void> _saveItems() => _persistence.save(_items);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addItem(BucketItem item) {
    setState(() => _items.add(item));
    _saveItems();
  }

  void _deleteItem(String id) {
    setState(() => _items.removeWhere((i) => i.id == id));
    _saveItems();
  }

  void _completeItem(String id, {String? notes, int? rating}) {
    setState(() {
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx >= 0) {
        _items[idx] = _items[idx].markComplete(notes: notes, rating: rating);
      }
    });
    _saveItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🪣 Bucket List'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.add_task), text: 'Add'),
            Tab(icon: Icon(Icons.list_alt), text: 'List'),
            Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
            Tab(icon: Icon(Icons.lightbulb_outline), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AddTab(onAdd: _addItem),
          _ListTab(
            items: _items,
            searchQuery: _searchQuery,
            filterCategory: _filterCategory,
            showCompletedOnly: _showCompletedOnly,
            onSearchChanged: (q) => setState(() => _searchQuery = q),
            onCategoryChanged: (c) => setState(() => _filterCategory = c),
            onToggleCompleted: () =>
                setState(() => _showCompletedOnly = !_showCompletedOnly),
            onDelete: _deleteItem,
            onComplete: _completeItem,
          ),
          _StatsTab(items: _items, service: _service),
          _InsightsTab(items: _items, service: _service),
        ],
      ),
    );
  }
}

// ─── Add Tab ───────────────────────────────────────────────────────────

class _AddTab extends StatefulWidget {
  final void Function(BucketItem) onAdd;
  const _AddTab({required this.onAdd});
  @override
  State<_AddTab> createState() => _AddTabState();
}

class _AddTabState extends State<_AddTab> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _tagCtrl = TextEditingController();
  final _inspirationCtrl = TextEditingController();
  BucketCategory _category = BucketCategory.travel;
  BucketPriority _priority = BucketPriority.someday;
  BucketEffort _effort = BucketEffort.moderate;
  DateTime? _targetDate;
  final List<String> _tags = [];

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagCtrl.clear();
      });
    }
  }

  void _submit() {
    if (_titleCtrl.text.trim().isEmpty) {
      SnackBarHelper.error(context, 'Please enter a title');
      return;
    }

    final item = BucketItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleCtrl.text.trim(),
      description:
          _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      category: _category,
      priority: _priority,
      effort: _effort,
      estimatedCost: double.tryParse(_costCtrl.text),
      location:
          _locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim(),
      tags: List.from(_tags),
      createdAt: DateTime.now(),
      targetDate: _targetDate,
      inspiration: _inspirationCtrl.text.trim().isEmpty
          ? null
          : _inspirationCtrl.text.trim(),
    );

    widget.onAdd(item);
    _titleCtrl.clear();
    _descCtrl.clear();
    _costCtrl.clear();
    _locationCtrl.clear();
    _inspirationCtrl.clear();
    setState(() {
      _tags.clear();
      _targetDate = null;
    });

    SnackBarHelper.success(context, 'Added "${item.title}" to bucket list! 🎯');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _costCtrl.dispose();
    _locationCtrl.dispose();
    _tagCtrl.dispose();
    _inspirationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Title
        TextField(
          controller: _titleCtrl,
          decoration: const InputDecoration(
            labelText: 'Dream / Goal *',
            hintText: 'e.g., See the Northern Lights',
            prefixIcon: Icon(Icons.star_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // Description
        TextField(
          controller: _descCtrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Description',
            hintText: 'Why is this important to you?',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),

        // Category chips
        const Text('Category',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: BucketCategory.values.map((c) {
            final selected = c == _category;
            return FilterChip(
              label: Text('${c.emoji} ${c.label}'),
              selected: selected,
              onSelected: (_) => setState(() => _category = c),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Priority
        const Text('Priority',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: BucketPriority.values.map((p) {
            final selected = p == _priority;
            return ChoiceChip(
              label: Text('${p.emoji} ${p.label}'),
              selected: selected,
              onSelected: (_) => setState(() => _priority = p),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Effort
        const Text('Effort',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: BucketEffort.values.map((e) {
            final selected = e == _effort;
            return ChoiceChip(
              label: Text('${e.emoji} ${e.label}'),
              selected: selected,
              onSelected: (_) => setState(() => _effort = e),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Cost & Location row
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _costCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Est. Cost (\$)',
                  prefixIcon: Icon(Icons.attach_money),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _locationCtrl,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Inspiration
        TextField(
          controller: _inspirationCtrl,
          decoration: const InputDecoration(
            labelText: 'Inspiration',
            hintText: 'Book, movie, friend, etc.',
            prefixIcon: Icon(Icons.auto_awesome),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),

        // Target date
        ListTile(
          leading: const Icon(Icons.calendar_today),
          title: Text(_targetDate == null
              ? 'Set target date (optional)'
              : 'Target: ${_formatDate(_targetDate!)}'),
          trailing: _targetDate != null
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(() => _targetDate = null),
                )
              : null,
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 90)),
              firstDate: DateTime.now(),
              lastDate: DateTime(2099),
            );
            if (picked != null) setState(() => _targetDate = picked);
          },
        ),
        const SizedBox(height: 12),

        // Tags
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagCtrl,
                decoration: const InputDecoration(
                  labelText: 'Add tag',
                  hintText: 'e.g., solo, bucket2025',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add_circle),
              onPressed: _addTag,
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: _tags
                .map((t) => Chip(
                      label: Text('#$t'),
                      onDeleted: () =>
                          setState(() => _tags.remove(t)),
                    ))
                .toList(),
          ),
        ],
        const SizedBox(height: 24),

        // Submit
        FilledButton.icon(
          onPressed: _submit,
          icon: const Icon(Icons.add),
          label: const Text('Add to Bucket List'),
        ),
      ],
    );
  }
}

// ─── List Tab ──────────────────────────────────────────────────────────

class _ListTab extends StatelessWidget {
  final List<BucketItem> items;
  final String searchQuery;
  final BucketCategory? filterCategory;
  final bool showCompletedOnly;
  final void Function(String) onSearchChanged;
  final void Function(BucketCategory?) onCategoryChanged;
  final VoidCallback onToggleCompleted;
  final void Function(String) onDelete;
  final void Function(String, {String? notes, int? rating}) onComplete;

  const _ListTab({
    required this.items,
    required this.searchQuery,
    required this.filterCategory,
    required this.showCompletedOnly,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    required this.onToggleCompleted,
    required this.onDelete,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    var filtered = List<BucketItem>.from(items);

    // Search filter
    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = filtered
          .where((i) =>
              i.title.toLowerCase().contains(q) ||
              (i.description?.toLowerCase().contains(q) ?? false) ||
              i.tags.any((t) => t.toLowerCase().contains(q)) ||
              (i.location?.toLowerCase().contains(q) ?? false))
          .toList();
    }

    // Category filter
    if (filterCategory != null) {
      filtered =
          filtered.where((i) => i.category == filterCategory).toList();
    }

    // Completed filter
    if (showCompletedOnly) {
      filtered = filtered.where((i) => i.isCompleted).toList();
    }

    // Sort: overdue first, then by priority desc, then by creation
    filtered.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      if (a.isCompleted && !b.isCompleted) return 1;
      if (!a.isCompleted && b.isCompleted) return -1;
      final pc = b.priority.value.compareTo(a.priority.value);
      if (pc != 0) return pc;
      return b.createdAt.compareTo(a.createdAt);
    });

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search dreams...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              isDense: true,
            ),
            onChanged: onSearchChanged,
          ),
        ),

        // Filter chips
        SizedBox(
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              FilterChip(
                label: Text(showCompletedOnly ? '✅ Done' : '📋 All'),
                selected: showCompletedOnly,
                onSelected: (_) => onToggleCompleted(),
              ),
              const SizedBox(width: 6),
              ...BucketCategory.values.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(c.emoji),
                      selected: filterCategory == c,
                      onSelected: (_) =>
                          onCategoryChanged(filterCategory == c ? null : c),
                    ),
                  )),
            ],
          ),
        ),

        // Summary strip
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${filtered.length} items',
                  style: Theme.of(context).textTheme.bodySmall),
              Text(
                '${items.where((i) => i.isCompleted).length}/${items.length} done',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),

        // List
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🪣', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 8),
                      Text(
                        items.isEmpty
                            ? 'Your bucket list is empty!\nAdd your first dream.'
                            : 'No matching items.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemBuilder: (ctx, i) {
                    final item = filtered[i];
                    return _BucketItemCard(
                      item: item,
                      onDelete: () => onDelete(item.id),
                      onComplete: () => _showCompleteDialog(ctx, item),
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showCompleteDialog(BuildContext context, BucketItem item) {
    int rating = 0;
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('🎉 Mark as Done!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Completing: ${item.title}'),
              const SizedBox(height: 16),
              const Text('How was it?'),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () =>
                        setDialogState(() => rating = i + 1),
                  );
                }),
              ),
              TextField(
                controller: notesCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Completion notes',
                  hintText: 'How did it go?',
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
            FilledButton(
              onPressed: () {
                onComplete(
                  item.id,
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                  rating: rating > 0 ? rating : null,
                );
                Navigator.pop(ctx);
                SnackBarHelper.success(context, 'Completed "${item.title}"! 🎉');
              },
              child: const Text('Complete!'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BucketItemCard extends StatelessWidget {
  final BucketItem item;
  final VoidCallback onDelete;
  final VoidCallback onComplete;

  const _BucketItemCard({
    required this.item,
    required this.onDelete,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOverdue = item.isOverdue;

    return Dismissible(
      key: Key(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        color: item.isCompleted
            ? theme.colorScheme.surfaceContainerHighest
            : isOverdue
                ? Colors.red.shade50
                : null,
        child: ListTile(
          leading: CircleAvatar(
            child: Text(item.category.emoji),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              decoration:
                  item.isCompleted ? TextDecoration.lineThrough : null,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('${item.priority.emoji} ${item.priority.label}'),
                  const SizedBox(width: 8),
                  Text('${item.effort.emoji} ${item.effort.label}'),
                  if (item.estimatedCost != null) ...[
                    const SizedBox(width: 8),
                    Text('\$${item.estimatedCost!.toStringAsFixed(0)}'),
                  ],
                ],
              ),
              if (item.location != null)
                Text('📍 ${item.location}',
                    style: theme.textTheme.bodySmall),
              if (item.tags.isNotEmpty)
                Text(item.tags.map((t) => '#$t').join(' '),
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary)),
              if (item.isCompleted && item.rating > 0)
                Row(
                  children: List.generate(
                    5,
                    (i) => Icon(
                      i < item.rating ? Icons.star : Icons.star_border,
                      size: 14,
                      color: Colors.amber,
                    ),
                  ),
                ),
              if (isOverdue)
                Text('⚠️ Overdue by ${-item.daysUntilTarget} days',
                    style: TextStyle(
                        color: Colors.red.shade700, fontSize: 12)),
              if (!item.isCompleted &&
                  item.targetDate != null &&
                  !isOverdue)
                Text('🎯 ${item.daysUntilTarget} days left',
                    style: theme.textTheme.bodySmall),
            ],
          ),
          isThreeLine: true,
          trailing: item.isCompleted
              ? const Icon(Icons.check_circle, color: Colors.green)
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: onComplete,
                  tooltip: 'Mark complete',
                ),
        ),
      ),
    );
  }
}

// ─── Stats Tab ─────────────────────────────────────────────────────────

class _StatsTab extends StatelessWidget {
  final List<BucketItem> items;
  final BucketListService service;

  const _StatsTab({required this.items, required this.service});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Add items to see stats 📊'),
      );
    }

    final stats = service.computeStats(items);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(
          children: [
            _StatCard('Total', '${stats.totalItems}', '🪣'),
            _StatCard('Done', '${stats.completedItems}', '✅'),
            _StatCard('Overdue', '${stats.overdueItems}', '⏰'),
          ].map((w) => Expanded(child: w)).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _StatCard(
                'Rate', '${stats.completionRate.toStringAsFixed(0)}%', '📈'),
            _StatCard(
                'Avg Rating',
                stats.avgRating > 0
                    ? stats.avgRating.toStringAsFixed(1)
                    : '-',
                '⭐'),
            _StatCard(
                'Avg Days',
                stats.avgDaysToComplete > 0
                    ? '${stats.avgDaysToComplete}'
                    : '-',
                '📅'),
          ].map((w) => Expanded(child: w)).toList(),
        ),
        const SizedBox(height: 16),

        // Cost summary
        if (stats.totalEstimatedCost > 0) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('💰 Total Estimated Cost',
                      style: theme.textTheme.titleMedium),
                  Text(
                    '\$${stats.totalEstimatedCost.toStringAsFixed(0)}',
                    style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.primary),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Category breakdown
        Text('Categories', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        ...stats.categoryBreakdown.entries.map((e) {
          final total = e.value;
          final done = stats.categoryCompleted[e.key] ?? 0;
          final pct = total > 0 ? done / total : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${e.key.emoji} ${e.key.label}'),
                    Text('$done/$total'),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: pct,
                  backgroundColor: Colors.grey.shade200,
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),

        // Priority breakdown
        Text('Priority Distribution', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stats.priorityBreakdown.entries.map((e) {
            return Chip(
              avatar: Text(e.key.emoji),
              label: Text('${e.key.label}: ${e.value}'),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Effort breakdown
        Text('Effort Distribution', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: stats.effortBreakdown.entries.map((e) {
            return Chip(
              avatar: Text(e.key.emoji),
              label: Text('${e.key.label}: ${e.value}'),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String emoji;

  const _StatCard(this.label, this.value, this.emoji);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

// ─── Insights Tab ──────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final List<BucketItem> items;
  final BucketListService service;

  const _InsightsTab({required this.items, required this.service});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(
        child: Text('Add items to get insights 💡'),
      );
    }

    final insights = service.generateInsights(items);
    final suggestions = service.suggestNext(items);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Next up suggestions
        if (suggestions.isNotEmpty) ...[
          Text('🎯 Tackle Next', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...suggestions.map((item) => Card(
                color: theme.colorScheme.primaryContainer,
                child: ListTile(
                  leading: CircleAvatar(child: Text(item.category.emoji)),
                  title: Text(item.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                      '${item.priority.emoji} ${item.priority.label} · ${item.effort.emoji} ${item.effort.label}'),
                ),
              )),
          const SizedBox(height: 24),
        ],

        // Insights
        if (insights.isNotEmpty) ...[
          Text('💡 Insights', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ...insights.map((insight) => Card(
                child: ListTile(
                  leading: Text(insight.emoji,
                      style: const TextStyle(fontSize: 28)),
                  title: Text(insight.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(insight.description),
                ),
              )),
        ],
      ],
    );
  }
}

// ─── Helpers ───────────────────────────────────────────────────────────

String _formatDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
