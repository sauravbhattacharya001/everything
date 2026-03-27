import 'package:flutter/material.dart';
import '../../core/services/wiki_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/wiki_page_entry.dart';

/// Personal Wiki screen — create interlinked knowledge pages with tags,
/// search, backlinks, and [[wiki-style]] internal linking.
class WikiScreen extends StatefulWidget {
  const WikiScreen({super.key});

  @override
  State<WikiScreen> createState() => _WikiScreenState();
}

class _WikiScreenState extends State<WikiScreen>
    with SingleTickerProviderStateMixin, PersistentStateMixin {
  @override
  String get storageKey => 'personal_wiki';
  @override
  String exportData() => _service.toJson();
  @override
  void importData(String json) {
    _service.loadFromJson(json);
    setState(() {});
  }

  final WikiService _service = WikiService();
  late TabController _tabController;
  String _searchQuery = '';
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initData();
  }

  Future<void> _initData() async {
    await initPersistence();
    if (_service.pages.isEmpty) _loadSamples();
    if (_service.pages.isNotEmpty) {
      _nextId = _service.pages
              .map((p) =>
                  int.tryParse(p.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
              .reduce((a, b) => a > b ? a : b) +
          1;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _loadSamples() {
    _service.addPage(WikiPageEntry(
      id: 'w1',
      title: 'Getting Started',
      content:
          'Welcome to your Personal Wiki! Create pages, link them with [[Wiki Syntax]], and organize with tags.\n\nTry linking to [[Flutter Tips]] or [[Reading Notes]].',
      tags: ['meta', 'guide'],
      isPinned: true,
    ));
    _service.addPage(WikiPageEntry(
      id: 'w2',
      title: 'Wiki Syntax',
      content:
          'Use double brackets to link pages: [[Page Title]].\n\nLinks to non-existent pages will offer to create them. See [[Getting Started]] for more.',
      tags: ['meta', 'syntax'],
    ));
    _service.addPage(WikiPageEntry(
      id: 'w3',
      title: 'Flutter Tips',
      content:
          'Collection of useful Flutter tips:\n\n- Use const constructors when possible\n- Prefer StatelessWidget over StatefulWidget\n- See also [[Reading Notes]]',
      tags: ['dev', 'flutter'],
    ));
    _service.addPage(WikiPageEntry(
      id: 'w4',
      title: 'Reading Notes',
      content:
          'Notes from books and articles.\n\nCurrently reading about design patterns. Related: [[Flutter Tips]].',
      tags: ['notes', 'reading'],
    ));
    savePersistence();
  }

  List<WikiPageEntry> get _filteredPages {
    var pages = _service.pages.toList();
    if (_searchQuery.isNotEmpty) {
      pages = _service.search(_searchQuery);
    }
    // Pinned first, then by updated date
    pages.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return pages;
  }

  void _createPage() {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Wiki Page'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                    labelText: 'Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: contentCtrl,
                decoration: const InputDecoration(
                    labelText: 'Content',
                    hintText: 'Use [[Page Title]] to link pages',
                    border: OutlineInputBorder()),
                maxLines: 6,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: tagsCtrl,
                decoration: const InputDecoration(
                    labelText: 'Tags (comma-separated)',
                    border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (titleCtrl.text.trim().isEmpty) return;
              final page = WikiPageEntry(
                id: 'w${_nextId++}',
                title: titleCtrl.text.trim(),
                content: contentCtrl.text,
                tags: tagsCtrl.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList(),
              );
              _service.addPage(page);
              savePersistence();
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _openPage(WikiPageEntry page) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _WikiPageDetail(
          page: page,
          service: _service,
          onUpdate: () {
            savePersistence();
            setState(() {});
          },
        ),
      ),
    );
  }

  void _deletePage(WikiPageEntry page) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Page?'),
        content: Text('Delete "${page.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _service.removePage(page.id);
              savePersistence();
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summary = _service.summary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Wiki'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.article), text: 'Pages'),
            Tab(icon: Icon(Icons.label), text: 'Tags'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createPage,
        child: const Icon(Icons.add),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Pages Tab ──
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search pages, content, tags…',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () =>
                                setState(() => _searchQuery = ''))
                        : null,
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v),
                ),
              ),
              Expanded(
                child: _filteredPages.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.auto_stories,
                                size: 64,
                                color: theme.colorScheme.primary
                                    .withAlpha(100)),
                            const SizedBox(height: 12),
                            Text('No pages yet',
                                style: theme.textTheme.titleMedium),
                            const SizedBox(height: 4),
                            const Text(
                                'Tap + to create your first wiki page'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filteredPages.length,
                        itemBuilder: (_, i) {
                          final page = _filteredPages[i];
                          final links = page.internalLinks;
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                page.isPinned
                                    ? Icons.push_pin
                                    : Icons.description,
                                color: page.isPinned
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                              title: Text(page.title,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  if (page.tags.isNotEmpty)
                                    Wrap(
                                      spacing: 4,
                                      children: page.tags
                                          .map((t) => Chip(
                                                label: Text(t,
                                                    style: const TextStyle(
                                                        fontSize: 11)),
                                                materialTapTargetSize:
                                                    MaterialTapTargetSize
                                                        .shrinkWrap,
                                                visualDensity:
                                                    VisualDensity.compact,
                                              ))
                                          .toList(),
                                    ),
                                  Text(
                                      '${page.wordCount} words · ${links.length} links',
                                      style: theme.textTheme.bodySmall),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (v) {
                                  if (v == 'pin') {
                                    page.isPinned = !page.isPinned;
                                    savePersistence();
                                    setState(() {});
                                  } else if (v == 'delete') {
                                    _deletePage(page);
                                  }
                                },
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'pin',
                                    child: Text(page.isPinned
                                        ? 'Unpin'
                                        : 'Pin'),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete',
                                        style:
                                            TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                              onTap: () => _openPage(page),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),

          // ── Tags Tab ──
          _service.allTags.isEmpty
              ? const Center(child: Text('No tags yet'))
              : ListView(
                  padding: const EdgeInsets.all(12),
                  children: _service.allTags.map((tag) {
                    final count = summary.tagBreakdown[tag] ?? 0;
                    return ListTile(
                      leading: const Icon(Icons.label),
                      title: Text(tag),
                      trailing: Chip(label: Text('$count')),
                      onTap: () => setState(() {
                        _searchQuery = tag;
                        _tabController.animateTo(0);
                      }),
                    );
                  }).toList(),
                ),

          // ── Stats Tab ──
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _statCard('Total Pages', '${summary.totalPages}',
                  Icons.article, theme),
              _statCard('Total Words', '${summary.totalWords}',
                  Icons.text_fields, theme),
              _statCard('Internal Links', '${summary.totalLinks}',
                  Icons.link, theme),
              _statCard('Pinned', '${summary.pinnedCount}',
                  Icons.push_pin, theme),
              _statCard('Unique Tags', '${_service.allTags.length}',
                  Icons.label, theme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statCard(
      String label, String value, IconData icon, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: theme.colorScheme.primary),
        title: Text(label),
        trailing:
            Text(value, style: theme.textTheme.headlineSmall),
      ),
    );
  }
}

// ── Page Detail View ──

class _WikiPageDetail extends StatefulWidget {
  final WikiPageEntry page;
  final WikiService service;
  final VoidCallback onUpdate;

  const _WikiPageDetail({
    required this.page,
    required this.service,
    required this.onUpdate,
  });

  @override
  State<_WikiPageDetail> createState() => _WikiPageDetailState();
}

class _WikiPageDetailState extends State<_WikiPageDetail> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  late TextEditingController _tagsCtrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.page.title);
    _contentCtrl = TextEditingController(text: widget.page.content);
    _tagsCtrl =
        TextEditingController(text: widget.page.tags.join(', '));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  void _save() {
    widget.page.title = _titleCtrl.text.trim();
    widget.page.content = _contentCtrl.text;
    widget.page.tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
    widget.page.updatedAt = DateTime.now();
    widget.service.updatePage(widget.page);
    widget.onUpdate();
    setState(() => _editing = false);
  }

  void _navigateToLink(String title) {
    final target = widget.service.findByTitle(title);
    if (target != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _WikiPageDetail(
            page: target,
            service: widget.service,
            onUpdate: widget.onUpdate,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Page "$title" not found')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backlinks = widget.service.backlinks(widget.page.title);
    final links = widget.page.internalLinks;

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Editing' : widget.page.title),
        actions: [
          if (_editing)
            IconButton(
                icon: const Icon(Icons.check), onPressed: _save)
          else
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _editing = true),
            ),
        ],
      ),
      body: _editing
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: TextField(
                      controller: _contentCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        hintText: 'Use [[Page Title]] to link',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _tagsCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Tags (comma-separated)',
                        border: OutlineInputBorder()),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Content with clickable wiki links
                _buildRichContent(widget.page.content, theme),
                const SizedBox(height: 16),
                // Tags
                if (widget.page.tags.isNotEmpty) ...[
                  Text('Tags',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: widget.page.tags
                        .map((t) => Chip(label: Text(t)))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                // Outgoing links
                if (links.isNotEmpty) ...[
                  Text('Links to',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: links
                        .map((l) => ActionChip(
                              label: Text(l),
                              onPressed: () => _navigateToLink(l),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                // Backlinks
                if (backlinks.isNotEmpty) ...[
                  Text('Linked from',
                      style: theme.textTheme.titleSmall),
                  const SizedBox(height: 4),
                  ...backlinks.map((p) => ListTile(
                        leading: const Icon(Icons.subdirectory_arrow_left),
                        title: Text(p.title),
                        onTap: () => _navigateToLink(p.title),
                      )),
                ],
                const SizedBox(height: 8),
                Text(
                  '${widget.page.wordCount} words · Updated ${_formatDate(widget.page.updatedAt)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
    );
  }

  /// Render content with [[wiki links]] as tappable spans.
  Widget _buildRichContent(String text, ThemeData theme) {
    final regex = RegExp(r'\[\[([^\]]+)\]\]');
    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      final linkTitle = match.group(1)!.trim();
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: GestureDetector(
          onTap: () => _navigateToLink(linkTitle),
          child: Text(
            linkTitle,
            style: TextStyle(
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ));
      lastEnd = match.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: theme.textTheme.bodyLarge,
        children: spans,
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
