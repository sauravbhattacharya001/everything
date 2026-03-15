import 'package:flutter/material.dart';
import '../../models/gift_item.dart';
import '../../core/services/gift_service.dart';
import '../../core/services/screen_persistence.dart';

/// Gift Tracker Screen — 4-tab UI for tracking gifts to give and receive.
///
/// Tabs:
///   Add: Form with name, person, occasion, direction, status, budget, date, tags
///   List: Searchable/filterable gift list with status chips and swipe-to-delete
///   Calendar: Upcoming occasions with countdown and reminders
///   Insights: Spending breakdown, person stats, occasion chart, auto-insights
class GiftTrackerScreen extends StatefulWidget {
  const GiftTrackerScreen({super.key});

  @override
  State<GiftTrackerScreen> createState() => _GiftTrackerScreenState();
}

enum _SortMode { newest, soonest, costHigh, costLow, person }

class _GiftTrackerScreenState extends State<GiftTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _service = const GiftService();
  final _persistence = ScreenPersistence<GiftItem>(
    storageKey: 'gift_tracker_entries',
    toJson: (e) => e.toJson(),
    fromJson: GiftItem.fromJson,
  );
  final List<GiftItem> _items = [];
  String _searchQuery = '';
  GiftDirection? _filterDirection;
  GiftStatus? _filterStatus;
  GiftOccasion? _filterOccasion;
  _SortMode _sortMode = _SortMode.newest;

  // Add-tab form
  final _nameController = TextEditingController();
  final _personController = TextEditingController();
  final _budgetController = TextEditingController();
  final _costController = TextEditingController();
  final _notesController = TextEditingController();
  final _urlController = TextEditingController();
  final _tagController = TextEditingController();
  GiftOccasion _selectedOccasion = GiftOccasion.birthday;
  GiftDirection _selectedDirection = GiftDirection.giving;
  GiftStatus _selectedStatus = GiftStatus.idea;
  DateTime? _selectedDate;
  final List<String> _selectedTags = [];

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
    _nameController.dispose();
    _personController.dispose();
    _budgetController.dispose();
    _costController.dispose();
    _notesController.dispose();
    _urlController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _addGift() {
    if (_nameController.text.trim().isEmpty ||
        _personController.text.trim().isEmpty) return;

    final item = GiftItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      recipientOrGiver: _personController.text.trim(),
      occasion: _selectedOccasion,
      status: _selectedStatus,
      direction: _selectedDirection,
      budget: double.tryParse(_budgetController.text),
      actualCost: double.tryParse(_costController.text),
      occasionDate: _selectedDate,
      createdAt: DateTime.now(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      tags: List.from(_selectedTags),
      url: _urlController.text.trim().isEmpty
          ? null
          : _urlController.text.trim(),
    );

    setState(() {
      _items.add(item);
      _nameController.clear();
      _personController.clear();
      _budgetController.clear();
      _costController.clear();
      _notesController.clear();
      _urlController.clear();
      _tagController.clear();
      _selectedTags.clear();
      _selectedOccasion = GiftOccasion.birthday;
      _selectedDirection = GiftDirection.giving;
      _selectedStatus = GiftStatus.idea;
      _selectedDate = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "${item.name}" for ${item.recipientOrGiver}')),
    );
    _tabController.animateTo(1);
    _saveItems();
  }

  void _deleteItem(String id) {
    setState(() => _items.removeWhere((i) => i.id == id));
    _saveItems();
  }

  void _updateStatus(String id, GiftStatus newStatus) {
    setState(() {
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx >= 0) _items[idx] = _items[idx].copyWith(status: newStatus);
    });
    _saveItems();
  }

  void _toggleThankYou(String id) {
    setState(() {
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx >= 0) _items[idx] = _items[idx].toggleThankYou();
    });
    _saveItems();
  }

  void _rateGift(String id, int rating) {
    setState(() {
      final idx = _items.indexWhere((i) => i.id == id);
      if (idx >= 0) _items[idx] = _items[idx].copyWith(rating: rating);
    });
    _saveItems();
  }

  List<GiftItem> get _filteredItems {
    var items = List<GiftItem>.from(_items);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      items = items
          .where((i) =>
              i.name.toLowerCase().contains(q) ||
              i.recipientOrGiver.toLowerCase().contains(q) ||
              i.tags.any((t) => t.toLowerCase().contains(q)))
          .toList();
    }

    if (_filterDirection != null) {
      items = items.where((i) => i.direction == _filterDirection).toList();
    }
    if (_filterStatus != null) {
      items = items.where((i) => i.status == _filterStatus).toList();
    }
    if (_filterOccasion != null) {
      items = items.where((i) => i.occasion == _filterOccasion).toList();
    }

    switch (_sortMode) {
      case _SortMode.newest:
        items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortMode.soonest:
        items.sort((a, b) {
          if (a.occasionDate == null && b.occasionDate == null) return 0;
          if (a.occasionDate == null) return 1;
          if (b.occasionDate == null) return -1;
          return a.occasionDate!.compareTo(b.occasionDate!);
        });
        break;
      case _SortMode.costHigh:
        items.sort((a, b) =>
            (b.actualCost ?? b.budget ?? 0)
                .compareTo(a.actualCost ?? a.budget ?? 0));
        break;
      case _SortMode.costLow:
        items.sort((a, b) =>
            (a.actualCost ?? a.budget ?? 0)
                .compareTo(b.actualCost ?? b.budget ?? 0));
        break;
      case _SortMode.person:
        items.sort(
            (a, b) => a.recipientOrGiver.compareTo(b.recipientOrGiver));
        break;
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎁 Gift Tracker'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.add_circle_outline), text: 'Add'),
            Tab(icon: Icon(Icons.list_alt), text: 'List'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Calendar'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAddTab(),
          _buildListTab(),
          _buildCalendarTab(),
          _buildInsightsTab(),
        ],
      ),
    );
  }

  // ─── ADD TAB ───

  Widget _buildAddTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Gift name *',
              hintText: 'e.g., Wireless headphones',
              prefixIcon: Icon(Icons.card_giftcard),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _personController,
            decoration: InputDecoration(
              labelText: _selectedDirection == GiftDirection.giving
                  ? 'Recipient *'
                  : 'From *',
              hintText: 'e.g., Mom',
              prefixIcon: const Icon(Icons.person),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Direction toggle
          SegmentedButton<GiftDirection>(
            segments: GiftDirection.values
                .map((d) => ButtonSegment(
                    value: d, label: Text(d.label), icon: Text(d.emoji)))
                .toList(),
            selected: {_selectedDirection},
            onSelectionChanged: (s) =>
                setState(() => _selectedDirection = s.first),
          ),
          const SizedBox(height: 12),

          // Occasion dropdown
          DropdownButtonFormField<GiftOccasion>(
            value: _selectedOccasion,
            decoration: const InputDecoration(
              labelText: 'Occasion',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.celebration),
            ),
            items: GiftOccasion.values
                .map((o) => DropdownMenuItem(
                    value: o, child: Text('${o.emoji} ${o.label}')))
                .toList(),
            onChanged: (v) => setState(() => _selectedOccasion = v!),
          ),
          const SizedBox(height: 12),

          // Status dropdown
          DropdownButtonFormField<GiftStatus>(
            value: _selectedStatus,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.flag),
            ),
            items: GiftStatus.values
                .map((s) => DropdownMenuItem(
                    value: s, child: Text('${s.emoji} ${s.label}')))
                .toList(),
            onChanged: (v) => setState(() => _selectedStatus = v!),
          ),
          const SizedBox(height: 12),

          // Budget & cost
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Budget',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _costController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Actual cost',
                    prefixText: '\$ ',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Occasion date
          OutlinedButton.icon(
            icon: const Icon(Icons.event),
            label: Text(_selectedDate != null
                ? '${_selectedDate!.month}/${_selectedDate!.day}/${_selectedDate!.year}'
                : 'Set occasion date'),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) setState(() => _selectedDate = date);
            },
          ),
          const SizedBox(height: 12),

          // URL
          TextField(
            controller: _urlController,
            decoration: const InputDecoration(
              labelText: 'Link/URL',
              hintText: 'https://...',
              prefixIcon: Icon(Icons.link),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),

          // Tags
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _tagController,
                  decoration: const InputDecoration(
                    labelText: 'Add tag',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: _addTag,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _addTag(_tagController.text),
              ),
            ],
          ),
          if (_selectedTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: _selectedTags
                  .map((t) => Chip(
                        label: Text(t),
                        onDeleted: () =>
                            setState(() => _selectedTags.remove(t)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: 12),

          // Notes
          TextField(
            controller: _notesController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Notes',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note),
            ),
          ),
          const SizedBox(height: 16),

          FilledButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Gift'),
            onPressed: _addGift,
          ),
        ],
      ),
    );
  }

  void _addTag(String tag) {
    final t = tag.trim();
    if (t.isNotEmpty && !_selectedTags.contains(t)) {
      setState(() {
        _selectedTags.add(t);
        _tagController.clear();
      });
    }
  }

  // ─── LIST TAB ───

  Widget _buildListTab() {
    final items = _filteredItems;
    return Column(
      children: [
        // Search + filters
        Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Search gifts or people...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () =>
                              setState(() => _searchQuery = ''),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    // Direction filter
                    ...GiftDirection.values.map((d) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: FilterChip(
                            label: Text('${d.emoji} ${d.label}'),
                            selected: _filterDirection == d,
                            onSelected: (sel) => setState(
                                () => _filterDirection = sel ? d : null),
                          ),
                        )),
                    const SizedBox(width: 8),
                    // Status filter
                    ...GiftStatus.values.map((s) => Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: FilterChip(
                            label: Text(s.emoji),
                            selected: _filterStatus == s,
                            onSelected: (sel) => setState(
                                () => _filterStatus = sel ? s : null),
                            tooltip: s.label,
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              // Sort
              Row(
                children: [
                  const Text('Sort: ', style: TextStyle(fontSize: 12)),
                  ...{
                    _SortMode.newest: 'Newest',
                    _SortMode.soonest: 'Soonest',
                    _SortMode.costHigh: 'Cost ↓',
                    _SortMode.costLow: 'Cost ↑',
                    _SortMode.person: 'Person',
                  }.entries.map((e) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ChoiceChip(
                          label: Text(e.value,
                              style: const TextStyle(fontSize: 11)),
                          selected: _sortMode == e.key,
                          onSelected: (_) =>
                              setState(() => _sortMode = e.key),
                          visualDensity: VisualDensity.compact,
                        ),
                      )),
                ],
              ),
            ],
          ),
        ),

        // Summary strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('${items.length} gifts',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                  'Spent: \$${_service.totalSpent(_items).toStringAsFixed(0)}'),
              Text(
                  'Budget: \$${_service.totalBudget(_items).toStringAsFixed(0)}'),
            ],
          ),
        ),

        // List
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('No gifts yet. Start adding! 🎁'))
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (_, i) => _buildGiftCard(items[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildGiftCard(GiftItem item) {
    final daysText = item.daysUntil != null
        ? (item.daysUntil! > 0
            ? '${item.daysUntil}d away'
            : item.daysUntil == 0
                ? 'Today!'
                : '${-item.daysUntil!}d ago')
        : null;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) => _deleteItem(item.id),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: item.status.color.withValues(alpha: 0.2),
            child: Text(item.occasion.emoji),
          ),
          title: Text(item.name,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.direction.emoji} ${item.recipientOrGiver} · ${item.occasion.label}',
                style: TextStyle(
                    fontSize: 12, color: Theme.of(context).hintColor),
              ),
              Row(
                children: [
                  Chip(
                    label: Text(item.status.label,
                        style: const TextStyle(fontSize: 10)),
                    backgroundColor:
                        item.status.color.withValues(alpha: 0.15),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize:
                        MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    labelPadding:
                        const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  if (item.actualCost != null) ...[
                    const SizedBox(width: 4),
                    Text('\$${item.actualCost!.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 12,
                            color: item.isOverBudget
                                ? Colors.red
                                : Colors.green,
                            fontWeight: FontWeight.bold)),
                  ],
                  if (daysText != null) ...[
                    const SizedBox(width: 8),
                    Text(daysText,
                        style: TextStyle(
                            fontSize: 11,
                            color: (item.daysUntil ?? 0) <= 3
                                ? Colors.red
                                : null)),
                  ],
                  if (item.thankYouSent)
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.mark_email_read,
                          size: 14, color: Colors.green),
                    ),
                ],
              ),
            ],
          ),
          trailing: PopupMenuButton<String>(
            itemBuilder: (_) => [
              ...GiftStatus.values.map((s) => PopupMenuItem(
                  value: 'status_${s.name}',
                  child: Text('${s.emoji} ${s.label}'))),
              const PopupMenuDivider(),
              if (item.direction == GiftDirection.receiving)
                PopupMenuItem(
                  value: 'thank_you',
                  child: Text(item.thankYouSent
                      ? '✉️ Undo thank-you'
                      : '✉️ Mark thank-you sent'),
                ),
              const PopupMenuItem(
                  value: 'rate', child: Text('⭐ Rate gift')),
              const PopupMenuItem(
                  value: 'delete',
                  child:
                      Text('🗑️ Delete', style: TextStyle(color: Colors.red))),
            ],
            onSelected: (action) {
              if (action.startsWith('status_')) {
                final statusName = action.substring(7);
                final status = GiftStatus.values
                    .firstWhere((s) => s.name == statusName);
                _updateStatus(item.id, status);
              } else if (action == 'thank_you') {
                _toggleThankYou(item.id);
              } else if (action == 'rate') {
                _showRatingDialog(item);
              } else if (action == 'delete') {
                _deleteItem(item.id);
              }
            },
          ),
          isThreeLine: true,
        ),
      ),
    );
  }

  void _showRatingDialog(GiftItem item) {
    int tempRating = item.rating;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Rate "${item.name}"'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                5,
                (i) => IconButton(
                      icon: Icon(
                        i < tempRating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () =>
                          setDialogState(() => tempRating = i + 1),
                    )),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                _rateGift(item.id, tempRating);
                Navigator.pop(ctx);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── CALENDAR TAB ───

  Widget _buildCalendarTab() {
    final upcoming = _service.upcoming(_items, days: 90);
    final pending = _service.pendingThankYou(_items);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Upcoming section
          Text('📅 Upcoming Occasions',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (upcoming.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('No upcoming occasions in the next 90 days.',
                    textAlign: TextAlign.center),
              ),
            )
          else
            ...upcoming.map((item) {
              final days = item.daysUntil!;
              final urgency = days <= 3
                  ? Colors.red
                  : days <= 7
                      ? Colors.orange
                      : days <= 14
                          ? Colors.amber
                          : Colors.green;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: urgency.withValues(alpha: 0.2),
                    child: Text(item.occasion.emoji),
                  ),
                  title: Text(
                      '${item.name} for ${item.recipientOrGiver}'),
                  subtitle: Text(
                    '${item.occasion.label} · ${days == 0 ? "TODAY!" : "$days day${days == 1 ? "" : "s"} away"}'
                    '${item.status != GiftStatus.given ? " · ${item.status.emoji} ${item.status.label}" : ""}',
                  ),
                  trailing: days <= 7
                      ? const Icon(Icons.warning_amber,
                          color: Colors.orange)
                      : null,
                ),
              );
            }),

          const SizedBox(height: 24),

          // Pending thank-you notes
          Text('✉️ Pending Thank-You Notes',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (pending.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('All caught up! 🎉',
                    textAlign: TextAlign.center),
              ),
            )
          else
            ...pending.map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const CircleAvatar(child: Text('📬')),
                    title: Text(item.name),
                    subtitle: Text('From ${item.recipientOrGiver}'),
                    trailing: TextButton(
                      onPressed: () => _toggleThankYou(item.id),
                      child: const Text('Mark Sent'),
                    ),
                  ),
                )),
        ],
      ),
    );
  }

  // ─── INSIGHTS TAB ───

  Widget _buildInsightsTab() {
    final insights = _service.generateInsights(_items);
    final personSpend = _service.spendingPerPerson(_items);
    final occasionSpend = _service.spendingPerOccasion(_items);
    final statusCount = _service.statusBreakdown(_items);
    final monthly = _service.monthlySpending(_items);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Auto-insights
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('🔮 Insights',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ...insights.map((i) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(i),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Summary cards
          Row(
            children: [
              _summaryCard(
                  'Total Spent',
                  '\$${_service.totalSpent(_items).toStringAsFixed(0)}',
                  Icons.payments,
                  Colors.green),
              const SizedBox(width: 8),
              _summaryCard(
                  'Budget',
                  '\$${_service.totalBudget(_items).toStringAsFixed(0)}',
                  Icons.account_balance_wallet,
                  Colors.blue),
              const SizedBox(width: 8),
              _summaryCard(
                  'Gifts',
                  '${_items.length}',
                  Icons.card_giftcard,
                  Colors.pink),
            ],
          ),
          const SizedBox(height: 12),

          // Status breakdown
          if (statusCount.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📊 By Status',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...statusCount.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text('${e.key.emoji} ${e.key.label}'),
                              const Spacer(),
                              Text('${e.value}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Person spending
          if (personSpend.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('👤 Spending by Person',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ..._sortedMapEntries(personSpend).map((e) {
                      final maxVal = personSpend.values
                          .fold(0.0, (a, b) => a > b ? a : b);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(e.key),
                                const Spacer(),
                                Text(
                                    '\$${e.value.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            LinearProgressIndicator(
                              value: maxVal > 0 ? e.value / maxVal : 0,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Occasion spending
          if (occasionSpend.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('🎉 Spending by Occasion',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...occasionSpend.entries.map((e) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Text('${e.key.emoji} ${e.key.label}'),
                              const Spacer(),
                              Text(
                                  '\$${e.value.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Monthly spending
          if (monthly.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('📆 Monthly Spending (${DateTime.now().year})',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    ...List.generate(12, (i) {
                      final month = i + 1;
                      final amount = monthly[month] ?? 0;
                      final months = [
                        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                      ];
                      if (amount == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 40,
                                child: Text(months[i],
                                    style:
                                        const TextStyle(fontSize: 12))),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: amount /
                                    (monthly.values.fold(
                                            0.0, (a, b) => a > b ? a : b) +
                                        0.01),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('\$${amount.toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).hintColor)),
            ],
          ),
        ),
      ),
    );
  }

  List<MapEntry<String, double>> _sortedMapEntries(
          Map<String, double> map) =>
      map.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
}
