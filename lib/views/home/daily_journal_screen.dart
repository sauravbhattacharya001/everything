import 'package:flutter/material.dart';
import '../../core/services/daily_journal_service.dart';
import '../../models/journal_entry.dart';

/// Daily Journal screen — free-form diary with mood, tags, search,
/// writing streaks, and "On This Day" memories.
class DailyJournalScreen extends StatefulWidget {
  const DailyJournalScreen({super.key});

  @override
  State<DailyJournalScreen> createState() => _DailyJournalScreenState();
}

class _DailyJournalScreenState extends State<DailyJournalScreen> {
  final DailyJournalService _service = DailyJournalService();
  String _searchQuery = '';
  JournalMood? _moodFilter;
  String? _tagFilter;
  bool _showFavoritesOnly = false;

  List<JournalEntry> get _filteredEntries {
    var entries = _showFavoritesOnly ? _service.favorites : _service.entries;
    if (_moodFilter != null) {
      entries = entries.where((e) => e.mood == _moodFilter).toList();
    }
    if (_tagFilter != null) {
      entries = entries.where((e) => e.tags.contains(_tagFilter)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      entries = entries
          .where((e) =>
              e.title.toLowerCase().contains(q) ||
              e.body.toLowerCase().contains(q))
          .toList();
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = _filteredEntries;
    final onThisDay = _service.onThisDay();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Journal'),
        actions: [
          IconButton(
            icon: Icon(
              _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
              color: _showFavoritesOnly ? Colors.red : null,
            ),
            onPressed: () => setState(() => _showFavoritesOnly = !_showFavoritesOnly),
            tooltip: 'Favorites',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                if (value == 'clear') {
                  _moodFilter = null;
                  _tagFilter = null;
                } else if (value.startsWith('mood:')) {
                  _moodFilter = JournalMood.values[int.parse(value.split(':')[1])];
                  _tagFilter = null;
                } else if (value.startsWith('tag:')) {
                  _tagFilter = value.substring(4);
                  _moodFilter = null;
                }
              });
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'clear', child: Text('Clear filters')),
              const PopupMenuDivider(),
              ...JournalMood.values.map((m) => PopupMenuItem(
                    value: 'mood:${m.index}',
                    child: Text('${m.emoji} ${m.label}'),
                  )),
              if (_service.allTags.isNotEmpty) ...[
                const PopupMenuDivider(),
                ..._service.allTags.map((t) => PopupMenuItem(
                      value: 'tag:$t',
                      child: Text('#$t'),
                    )),
              ],
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatChip(
                  icon: Icons.book,
                  label: '${_service.totalEntries}',
                  subtitle: 'entries',
                ),
                _StatChip(
                  icon: Icons.local_fire_department,
                  label: '${_service.currentStreak}',
                  subtitle: 'streak',
                  color: _service.currentStreak > 0 ? Colors.orange : null,
                ),
                _StatChip(
                  icon: Icons.emoji_events,
                  label: '${_service.longestStreak}',
                  subtitle: 'best',
                ),
                _StatChip(
                  icon: Icons.text_fields,
                  label: '${_service.averageWordCount.round()}',
                  subtitle: 'avg words',
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search journal...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          const SizedBox(height: 8),
          // On This Day
          if (onThisDay.isNotEmpty)
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              color: theme.colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.history),
                title: const Text('On This Day'),
                subtitle: Text(
                  '${onThisDay.length} ${onThisDay.length == 1 ? "entry" : "entries"} from previous years',
                ),
                onTap: () => _showOnThisDay(onThisDay),
              ),
            ),
          // Active filter chips
          if (_moodFilter != null || _tagFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  if (_moodFilter != null)
                    Chip(
                      label: Text('${_moodFilter!.emoji} ${_moodFilter!.label}'),
                      onDeleted: () => setState(() => _moodFilter = null),
                    ),
                  if (_tagFilter != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text('#$_tagFilter'),
                      onDeleted: () => setState(() => _tagFilter = null),
                    ),
                  ],
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
                        Icon(Icons.auto_stories, size: 64, color: theme.disabledColor),
                        const SizedBox(height: 16),
                        Text(
                          _service.totalEntries == 0
                              ? 'Start your journal today!'
                              : 'No matching entries',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.disabledColor,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    itemBuilder: (context, index) =>
                        _buildEntryCard(entries[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openEditor(null),
        child: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry entry) {
    final theme = Theme.of(context);
    final dateStr =
        '${_monthName(entry.date.month)} ${entry.date.day}, ${entry.date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openEditor(entry),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (entry.mood != null) ...[
                    Text(entry.mood!.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      entry.title.isNotEmpty ? entry.title : dateStr,
                      style: theme.textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.isFavorite)
                    const Icon(Icons.favorite, size: 16, color: Colors.red),
                  const SizedBox(width: 4),
                  Text(
                    dateStr,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
                    ),
                  ),
                ],
              ),
              if (entry.body.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  entry.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: entry.tags
                      .map((t) => Chip(
                            label: Text('#$t', style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            padding: EdgeInsets.zero,
                          ))
                      .toList(),
                ),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '${entry.wordCount} words',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.disabledColor,
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

  void _openEditor(JournalEntry? existing) async {
    final result = await Navigator.push<JournalEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => _JournalEditorScreen(entry: existing),
      ),
    );
    if (result != null) {
      setState(() {
        if (existing != null) {
          _service.updateEntry(result);
        } else {
          _service.addEntry(result);
        }
      });
    }
  }

  void _showOnThisDay(List<JournalEntry> entries) {
    showModalBottomSheet(
      context: context,
      builder: (_) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('On This Day',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          ...entries.map((e) => ListTile(
                leading: Text(e.mood?.emoji ?? '📝', style: const TextStyle(fontSize: 24)),
                title: Text(e.title.isNotEmpty ? e.title : 'Untitled'),
                subtitle: Text(
                  '${e.date.year} — ${e.body.length > 80 ? '${e.body.substring(0, 80)}...' : e.body}',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _openEditor(e);
                },
              )),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color? color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 2),
        Text(label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: color)),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

/// Full-screen journal entry editor.
class _JournalEditorScreen extends StatefulWidget {
  final JournalEntry? entry;

  const _JournalEditorScreen({this.entry});

  @override
  State<_JournalEditorScreen> createState() => _JournalEditorScreenState();
}

class _JournalEditorScreenState extends State<_JournalEditorScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _bodyCtrl;
  late TextEditingController _tagCtrl;
  late DateTime _date;
  JournalMood? _mood;
  List<String> _tags = [];
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _bodyCtrl = TextEditingController(text: e?.body ?? '');
    _tagCtrl = TextEditingController();
    _date = e?.date ?? DateTime.now();
    _mood = e?.mood;
    _tags = e != null ? List.from(e.tags) : [];
    _isFavorite = e?.isFavorite ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final entry = JournalEntry(
      id: widget.entry?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: _date,
      title: _titleCtrl.text.trim(),
      body: _bodyCtrl.text.trim(),
      mood: _mood,
      tags: _tags,
      isFavorite: _isFavorite,
      createdAt: widget.entry?.createdAt,
    );
    Navigator.pop(context, entry);
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]'), '');
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
        _tagCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.entry != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Entry' : 'New Entry'),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: () => setState(() => _isFavorite = !_isFavorite),
          ),
          if (isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Discard',
            ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _save,
            tooltip: 'Save',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date picker
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now().add(const Duration(days: 1)),
                );
                if (picked != null) setState(() => _date = picked);
              },
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${_monthName(_date.month)} ${_date.day}, ${_date.year}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Mood selector
            Text('How are you feeling?',
                style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: JournalMood.values.map((m) {
                final selected = _mood == m;
                return GestureDetector(
                  onTap: () => setState(() => _mood = selected ? null : m),
                  child: Column(
                    children: [
                      Text(
                        m.emoji,
                        style: TextStyle(
                          fontSize: selected ? 32 : 24,
                        ),
                      ),
                      Text(
                        m.label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            // Title
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'Title (optional)',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            // Body
            TextField(
              controller: _bodyCtrl,
              decoration: const InputDecoration(
                hintText: 'Write about your day...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              maxLines: 15,
              minLines: 8,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            // Tags
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Add tag...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addTag(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addTag,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (_tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: _tags
                    .map((t) => Chip(
                          label: Text('#$t'),
                          onDeleted: () => setState(() => _tags.remove(t)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _monthName(int m) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[m];
  }
}
