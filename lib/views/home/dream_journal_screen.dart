import 'package:flutter/material.dart';
import '../../core/services/storage_backend.dart';
import '../../core/services/dream_journal_service.dart';
import '../../models/dream_entry.dart';

/// Dream Journal screen — log dreams, track patterns, browse entries,
/// view stats on dream types, moods, and recurring themes.
class DreamJournalScreen extends StatefulWidget {
  const DreamJournalScreen({super.key});

  @override
  State<DreamJournalScreen> createState() => _DreamJournalScreenState();
}

class _DreamJournalScreenState extends State<DreamJournalScreen>
    with SingleTickerProviderStateMixin {
  static const _storageKey = 'dream_journal_data';
  final DreamJournalService _service = DreamJournalService();
  late TabController _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final json = await StorageBackend.read(_storageKey);
    if (json != null && json.isNotEmpty) {
      try {
        _service.importFromJson(json);
        setState(() {});
      } catch (_) {}
    }
  }

  Future<void> _saveData() async {
    await StorageBackend.write(_storageKey, _service.exportToJson());
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
        title: const Text('Dream Journal'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.nightlight_round), text: 'Dreams'),
            Tab(icon: Icon(Icons.star), text: 'Favorites'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDreamsList(),
          _buildFavorites(),
          _buildInsights(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDreamDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDreamsList() {
    final entries = _searchQuery.isEmpty
        ? _service.entries
        : _service.searchByText(_searchQuery);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search dreams...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.nightlight_round,
                          size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty
                            ? 'No dreams recorded yet'
                            : 'No matching dreams',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      if (_searchQuery.isEmpty) ...[
                        const SizedBox(height: 8),
                        const Text('Tap + to log your first dream'),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) => _buildDreamCard(entries[i]),
                ),
        ),
      ],
    );
  }

  Widget _buildDreamCard(DreamEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Text(entry.type.emoji, style: const TextStyle(fontSize: 28)),
        title: Text(entry.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatDate(entry.date)} · ${entry.mood.emoji} ${entry.mood.label}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (entry.tags.isNotEmpty)
              Wrap(
                spacing: 4,
                children: entry.tags
                    .take(3)
                    .map((t) => Chip(
                          label: Text(t, style: const TextStyle(fontSize: 10)),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ))
                    .toList(),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                5,
                (i) => Icon(
                  i < entry.clarity ? Icons.star : Icons.star_border,
                  size: 12,
                  color: Colors.amber,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                entry.isFavorite ? Icons.star : Icons.star_border,
                color: entry.isFavorite ? Colors.amber : null,
              ),
              onPressed: () {
                _service.toggleFavorite(entry.id);
                _saveData();
                setState(() {});
              },
            ),
          ],
        ),
        onTap: () => _showDreamDetail(entry),
        onLongPress: () => _confirmDelete(entry),
      ),
    );
  }

  Widget _buildFavorites() {
    final favs = _service.favorites;
    if (favs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('No favorite dreams yet',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: favs.length,
      itemBuilder: (ctx, i) => _buildDreamCard(favs[i]),
    );
  }

  Widget _buildInsights() {
    final stats = _service.getStats();
    if (stats.totalDreams == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insights, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('Log dreams to see insights',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              _statCard('Total', '${stats.totalDreams}', Icons.nightlight_round),
              const SizedBox(width: 8),
              _statCard('Lucid', '${stats.lucidCount}', Icons.auto_awesome),
              const SizedBox(width: 8),
              _statCard('Clarity', stats.avgClarity.toStringAsFixed(1), Icons.visibility),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('Streak', '${stats.currentStreak}d', Icons.local_fire_department),
              const SizedBox(width: 8),
              _statCard('Best', '${stats.longestStreak}d', Icons.emoji_events),
              const SizedBox(width: 8),
              _statCard('Nightmares', '${stats.nightmareCount}', Icons.warning_amber),
            ],
          ),
          const SizedBox(height: 24),

          // Dream types breakdown
          const Text('Dream Types',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...stats.typeBreakdown.entries.map((e) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Text('${e.key.emoji} ${e.key.label}'),
                    const Spacer(),
                    Text('${e.value}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 100,
                      child: LinearProgressIndicator(
                        value: e.value / stats.totalDreams,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 24),

          // Waking moods
          const Text('Waking Moods',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: stats.moodBreakdown.entries
                .map((e) => Chip(
                      avatar: Text(e.key.emoji),
                      label: Text('${e.key.label} (${e.value})'),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),

          // Top tags
          if (stats.topTags.isNotEmpty) ...[
            const Text('Recurring Themes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...stats.topTags.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Text('#${p.tag}'),
                      const Spacer(),
                      Text('${p.count}x (${p.percentage.toStringAsFixed(0)}%)'),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 4),
              Text(value,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold)),
              Text(label,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddDreamDialog() {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    final tagsCtl = TextEditingController();
    DreamType selectedType = DreamType.normal;
    WakingMood selectedMood = WakingMood.neutral;
    int clarity = 3;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Log a Dream',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: titleCtl,
                  decoration: const InputDecoration(
                    labelText: 'Dream Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtl,
                  decoration: const InputDecoration(
                    labelText: 'What happened?',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<DreamType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Dream Type',
                    border: OutlineInputBorder(),
                  ),
                  items: DreamType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text('${t.emoji} ${t.label}'),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setModalState(() => selectedType = v ?? DreamType.normal),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<WakingMood>(
                  value: selectedMood,
                  decoration: const InputDecoration(
                    labelText: 'Waking Mood',
                    border: OutlineInputBorder(),
                  ),
                  items: WakingMood.values
                      .map((m) => DropdownMenuItem(
                            value: m,
                            child: Text('${m.emoji} ${m.label}'),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setModalState(() => selectedMood = v ?? WakingMood.neutral),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Clarity: '),
                    ...List.generate(
                      5,
                      (i) => IconButton(
                        icon: Icon(
                          i < clarity ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                        onPressed: () =>
                            setModalState(() => clarity = i + 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagsCtl,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma separated)',
                    hintText: 'flying, water, school',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    if (titleCtl.text.trim().isEmpty) return;
                    final tags = tagsCtl.text
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList();
                    final entry = DreamEntry(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      date: DateTime.now(),
                      title: titleCtl.text.trim(),
                      description: descCtl.text.trim(),
                      type: selectedType,
                      mood: selectedMood,
                      clarity: clarity,
                      tags: tags,
                    );
                    _service.addEntry(entry);
                    _saveData();
                    setState(() {});
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Dream'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDreamDetail(DreamEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(entry.type.emoji,
                      style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(entry.title,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold)),
                        Text(
                          '${_formatDate(entry.date)} · ${entry.type.label}',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Text('${entry.mood.emoji} ${entry.mood.label}'),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < entry.clarity ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.amber,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Text(entry.description.isEmpty
                  ? '(No description)'
                  : entry.description),
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: entry.tags
                      .map((t) => Chip(label: Text('#$t')))
                      .toList(),
                ),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(DreamEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Dream?'),
        content: Text('Remove "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _service.deleteEntry(entry.id);
              _saveData();
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
