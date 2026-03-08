import 'package:flutter/material.dart';
import '../../core/services/gratitude_journal_service.dart';
import '../../models/gratitude_entry.dart';

/// Gratitude Journal screen — log what you're grateful for, browse entries,
/// view favorites, and get insights on your gratitude practice.
class GratitudeJournalScreen extends StatefulWidget {
  const GratitudeJournalScreen({super.key});

  @override
  State<GratitudeJournalScreen> createState() => _GratitudeJournalScreenState();
}

class _GratitudeJournalScreenState extends State<GratitudeJournalScreen>
    with SingleTickerProviderStateMixin {
  final GratitudeJournalService _service = GratitudeJournalService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Gratitude Journal'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.edit_note), text: 'Log'),
            Tab(icon: Icon(Icons.book), text: 'Journal'),
            Tab(icon: Icon(Icons.star), text: 'Favorites'),
            Tab(icon: Icon(Icons.insights), text: 'Insights'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _LogTab(service: _service, onLogged: () => setState(() {})),
          _JournalTab(service: _service, onChanged: () => setState(() {})),
          _FavoritesTab(service: _service, onChanged: () => setState(() {})),
          _InsightsTab(service: _service),
        ],
      ),
    );
  }
}

// ─── LOG TAB ────────────────────────────────────────────────────────────────

class _LogTab extends StatefulWidget {
  final GratitudeJournalService service;
  final VoidCallback onLogged;

  const _LogTab({required this.service, required this.onLogged});

  @override
  State<_LogTab> createState() => _LogTabState();
}

class _LogTabState extends State<_LogTab> {
  final _textController = TextEditingController();
  final _noteController = TextEditingController();
  GratitudeCategory _category = GratitudeCategory.general;
  GratitudeIntensity _intensity = GratitudeIntensity.moderate;
  String _prompt = '';

  @override
  void initState() {
    super.initState();
    _prompt = widget.service.getRandomPrompt();
  }

  @override
  void dispose() {
    _textController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write what you\'re grateful for')),
      );
      return;
    }
    widget.service.addEntry(
      text: text,
      category: _category,
      intensity: _intensity,
      note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
    );
    _textController.clear();
    _noteController.clear();
    setState(() {
      _category = GratitudeCategory.general;
      _intensity = GratitudeIntensity.moderate;
      _prompt = widget.service.getRandomPrompt();
    });
    widget.onLogged();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('🙏 Gratitude logged!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Prompt card
          Card(
            color: theme.colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '💡 Prompt',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _prompt,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _prompt = widget.service.getRandomPrompt();
                    }),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('New prompt'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Text field
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              labelText: 'I\'m grateful for...',
              hintText: 'Write what you\'re grateful for today',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.favorite_border),
            ),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),

          // Optional note
          TextField(
            controller: _noteController,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'Add more context or reflection',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.note_add),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),

          // Category selector
          Text('Category', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: GratitudeCategory.values.map((cat) {
              final selected = cat == _category;
              return FilterChip(
                selected: selected,
                label: Text('${cat.emoji} ${cat.label}'),
                onSelected: (_) => setState(() => _category = cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Intensity slider
          Text('Intensity: ${_intensity.label}', style: theme.textTheme.titleSmall),
          Slider(
            value: _intensity.value.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _intensity.label,
            onChanged: (v) => setState(() {
              _intensity = GratitudeIntensity.fromValue(v.round());
            }),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Slight', style: theme.textTheme.bodySmall),
              Text('Profound', style: theme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 24),

          // Submit
          FilledButton.icon(
            onPressed: _submit,
            icon: const Icon(Icons.add),
            label: const Text('Log Gratitude'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          // Today's count
          const SizedBox(height: 16),
          Builder(builder: (_) {
            final today = widget.service.getEntriesForDate(DateTime.now());
            final streak = widget.service.getStreak();
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _MiniStat(
                      icon: Icons.today,
                      label: 'Today',
                      value: '${today.length}',
                    ),
                    _MiniStat(
                      icon: Icons.local_fire_department,
                      label: 'Streak',
                      value: '${streak.currentStreak}d',
                    ),
                    _MiniStat(
                      icon: Icons.format_list_numbered,
                      label: 'Total',
                      value: '${widget.service.entryCount}',
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

// ─── JOURNAL TAB ────────────────────────────────────────────────────────────

class _JournalTab extends StatefulWidget {
  final GratitudeJournalService service;
  final VoidCallback onChanged;

  const _JournalTab({required this.service, required this.onChanged});

  @override
  State<_JournalTab> createState() => _JournalTabState();
}

class _JournalTabState extends State<_JournalTab> {
  GratitudeCategory? _filterCategory;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GratitudeEntry> get _filteredEntries {
    var entries = widget.service.allEntries.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (_filterCategory != null) {
      entries = entries.where((e) => e.category == _filterCategory).toList();
    }
    if (_searchQuery.isNotEmpty) {
      entries = entries.where((e) {
        final q = _searchQuery.toLowerCase();
        return e.text.toLowerCase().contains(q) ||
            (e.note?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final entries = _filteredEntries;
    return Column(
      children: [
        // Search + filter bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search entries...',
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        // Category chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FilterChip(
                  selected: _filterCategory == null,
                  label: const Text('All'),
                  onSelected: (_) => setState(() => _filterCategory = null),
                ),
              ),
              ...GratitudeCategory.values.map((cat) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      selected: _filterCategory == cat,
                      label: Text(cat.emoji),
                      onSelected: (_) => setState(() {
                        _filterCategory = _filterCategory == cat ? null : cat;
                      }),
                    ),
                  )),
            ],
          ),
        ),
        // Entry list
        Expanded(
          child: entries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.book, size: 64,
                          color: Theme.of(context).colorScheme.outline),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isNotEmpty || _filterCategory != null
                            ? 'No matching entries'
                            : 'No entries yet — start logging!',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: entries.length,
                  itemBuilder: (ctx, i) => _EntryCard(
                    entry: entries[i],
                    service: widget.service,
                    onChanged: () {
                      setState(() {});
                      widget.onChanged();
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

// ─── ENTRY CARD ─────────────────────────────────────────────────────────────

class _EntryCard extends StatelessWidget {
  final GratitudeEntry entry;
  final GratitudeJournalService service;
  final VoidCallback onChanged;

  const _EntryCard({
    required this.entry,
    required this.service,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = entry.timestamp;
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(entry.category.emoji, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    entry.text,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
                // Favorite toggle
                IconButton(
                  icon: Icon(
                    entry.isFavorite ? Icons.star : Icons.star_border,
                    color: entry.isFavorite ? Colors.amber : null,
                  ),
                  onPressed: () {
                    service.toggleFavorite(entry.id);
                    onChanged();
                  },
                  iconSize: 20,
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () {
                    service.deleteEntry(entry.id);
                    onChanged();
                  },
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
            // Note
            if (entry.note != null && entry.note!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                entry.note!,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 8),
            // Footer: date, intensity, category label
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  '$dateStr $timeStr',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    entry.intensity.label,
                    style: theme.textTheme.labelSmall,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  entry.category.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FAVORITES TAB ──────────────────────────────────────────────────────────

class _FavoritesTab extends StatelessWidget {
  final GratitudeJournalService service;
  final VoidCallback onChanged;

  const _FavoritesTab({required this.service, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final favorites = service.getFavorites()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star_border, size: 64,
                color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              'No favorites yet',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Tap the ⭐ on an entry to save it here',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: favorites.length,
      itemBuilder: (ctx, i) => _EntryCard(
        entry: favorites[i],
        service: service,
        onChanged: onChanged,
      ),
    );
  }
}

// ─── INSIGHTS TAB ───────────────────────────────────────────────────────────

class _InsightsTab extends StatelessWidget {
  final GratitudeJournalService service;

  const _InsightsTab({required this.service});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final report = service.getReport();
    final streak = report.streak;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stats row
          Row(
            children: [
              Expanded(child: _StatCard(
                icon: Icons.format_list_numbered,
                label: 'Total',
                value: '${report.totalEntries}',
              )),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(
                icon: Icons.local_fire_department,
                label: 'Streak',
                value: '${streak.currentStreak}d',
              )),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(
                icon: Icons.emoji_events,
                label: 'Best',
                value: '${streak.longestStreak}d',
              )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _StatCard(
                icon: Icons.speed,
                label: 'Avg/Day',
                value: report.averageEntriesPerDay.toStringAsFixed(1),
              )),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(
                icon: Icons.favorite,
                label: 'Intensity',
                value: '${report.averageIntensity.toStringAsFixed(1)}/5',
              )),
              const SizedBox(width: 8),
              Expanded(child: _StatCard(
                icon: Icons.star,
                label: 'Favorites',
                value: '${report.favoriteCount}',
              )),
            ],
          ),
          const SizedBox(height: 20),

          // Category breakdown
          if (report.categoryBreakdown.isNotEmpty) ...[
            Text('Category Breakdown', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...report.categoryBreakdown.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)),
            ..._buildCategoryBars(context, report),
            const SizedBox(height: 20),
          ],

          // Top tags
          if (report.tagFrequency.isNotEmpty) ...[
            Text('Top Tags', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: report.tagFrequency.entries
                  .toList()
                  .take(10)
                  .map((e) => Chip(label: Text('#${e.key} (${e.value})')))
                  .toList(),
            ),
            const SizedBox(height: 20),
          ],

          // Insights
          if (report.insights.isNotEmpty) ...[
            Text('Insights', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            ...report.insights.map((insight) => Card(
                  child: ListTile(
                    leading: const Text('💡', style: TextStyle(fontSize: 24)),
                    title: Text(insight.message),
                    subtitle: Text(insight.type,
                        style: theme.textTheme.labelSmall),
                  ),
                )),
          ],

          if (report.totalEntries == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Icon(Icons.auto_graph, size: 64,
                        color: theme.colorScheme.outline),
                    const SizedBox(height: 12),
                    Text(
                      'Start logging to see your insights!',
                      style: theme.textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryBars(BuildContext context, GratitudeReport report) {
    final theme = Theme.of(context);
    final sorted = report.categoryBreakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxVal = sorted.first.value;
    return sorted.map((entry) {
      final fraction = maxVal > 0 ? entry.value / maxVal : 0.0;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '${entry.key.emoji} ${entry.key.label}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 16,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text('${entry.value}', style: theme.textTheme.bodySmall),
          ],
        ),
      );
    }).toList();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: theme.colorScheme.primary),
            const SizedBox(height: 4),
            Text(value, style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            )),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
