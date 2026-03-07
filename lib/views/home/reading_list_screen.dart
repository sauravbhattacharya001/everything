import 'package:flutter/material.dart';
import '../../core/services/reading_list_service.dart';
import '../../models/book.dart';

/// Reading List screen — track books, log reading sessions, view stats,
/// and manage a reading challenge.
class ReadingListScreen extends StatefulWidget {
  const ReadingListScreen({super.key});

  @override
  State<ReadingListScreen> createState() => _ReadingListScreenState();
}

class _ReadingListScreenState extends State<ReadingListScreen>
    with SingleTickerProviderStateMixin {
  final ReadingListService _service = ReadingListService();
  late TabController _tabController;
  ReadingStatus? _statusFilter;
  String _searchQuery = '';
  int _nextId = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _addSampleBooks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _addSampleBooks() {
    final samples = [
      Book(
        id: 'b1',
        title: 'Dune',
        author: 'Frank Herbert',
        genre: BookGenre.sciFi,
        totalPages: 688,
        status: ReadingStatus.reading,
        currentPage: 342,
        dateAdded: DateTime.now().subtract(const Duration(days: 14)),
        dateStarted: DateTime.now().subtract(const Duration(days: 10)),
        sessions: [
          ReadingSession(
            date: DateTime.now().subtract(const Duration(days: 10)),
            pagesRead: 120,
            minutesSpent: 90,
          ),
          ReadingSession(
            date: DateTime.now().subtract(const Duration(days: 7)),
            pagesRead: 130,
            minutesSpent: 85,
          ),
          ReadingSession(
            date: DateTime.now().subtract(const Duration(days: 2)),
            pagesRead: 92,
            minutesSpent: 65,
          ),
        ],
      ),
      Book(
        id: 'b2',
        title: 'Sapiens',
        author: 'Yuval Noah Harari',
        genre: BookGenre.nonFiction,
        totalPages: 443,
        status: ReadingStatus.finished,
        currentPage: 443,
        rating: 5,
        dateAdded: DateTime.now().subtract(const Duration(days: 60)),
        dateStarted: DateTime.now().subtract(const Duration(days: 50)),
        dateFinished: DateTime.now().subtract(const Duration(days: 30)),
      ),
      Book(
        id: 'b3',
        title: 'Project Hail Mary',
        author: 'Andy Weir',
        genre: BookGenre.sciFi,
        totalPages: 476,
        status: ReadingStatus.wantToRead,
        dateAdded: DateTime.now().subtract(const Duration(days: 5)),
        tags: ['recommended', 'space'],
      ),
      Book(
        id: 'b4',
        title: 'Thinking, Fast and Slow',
        author: 'Daniel Kahneman',
        genre: BookGenre.science,
        totalPages: 499,
        status: ReadingStatus.wantToRead,
        dateAdded: DateTime.now().subtract(const Duration(days: 20)),
        tags: ['psychology', 'classic'],
      ),
    ];
    for (final b in samples) {
      _service.addBook(b);
    }
    _nextId = 5;
  }

  List<Book> get _filteredBooks {
    var books = _service.books;
    if (_statusFilter != null) {
      books = books.where((b) => b.status == _statusFilter).toList();
    }
    if (_searchQuery.isNotEmpty) {
      books = _service.search(_searchQuery);
      if (_statusFilter != null) {
        books = books.where((b) => b.status == _statusFilter).toList();
      }
    }
    return books;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('📚 Reading List'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Library'),
            Tab(text: 'Stats'),
            Tab(text: 'Challenge'),
            Tab(text: 'Recommend'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLibraryTab(theme),
          _buildStatsTab(theme),
          _buildChallengeTab(theme),
          _buildRecommendTab(theme),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBookDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  // ── Library Tab ────────────────────────────────

  Widget _buildLibraryTab(ThemeData theme) {
    final books = _filteredBooks;
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(12),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search books...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        // Status filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _filterChip('All', null, theme),
              const SizedBox(width: 8),
              for (final status in ReadingStatus.values) ...[
                _filterChip(
                  '${status.emoji} ${status.label}',
                  status,
                  theme,
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Book count
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${books.length} book${books.length == 1 ? '' : 's'}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        // Book list
        Expanded(
          child: books.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.menu_book,
                          size: 64,
                          color: theme.colorScheme.onSurfaceVariant
                              .withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text('No books yet',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                      const SizedBox(height: 8),
                      Text('Tap + to add your first book',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withOpacity(0.7),
                          )),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: books.length,
                  itemBuilder: (ctx, i) => _buildBookCard(books[i], theme),
                ),
        ),
      ],
    );
  }

  Widget _filterChip(String label, ReadingStatus? status, ThemeData theme) {
    final selected = _statusFilter == status;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: selected,
      onSelected: (_) => setState(() => _statusFilter = status),
      selectedColor: theme.colorScheme.primaryContainer,
    );
  }

  Widget _buildBookCard(Book book, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showBookDetail(book),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Genre icon
              Container(
                width: 48,
                height: 64,
                decoration: BoxDecoration(
                  color: _genreColor(book.genre).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(book.genre.emoji, style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              // Book info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      book.author,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (book.status == ReadingStatus.reading) ...[
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: book.progressPercent / 100,
                          minHeight: 6,
                          backgroundColor:
                              theme.colorScheme.surfaceContainerHighest,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${book.currentPage}/${book.totalPages} pages (${book.progressPercent.toStringAsFixed(0)}%)',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ] else ...[
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _statusColor(book.status).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${book.status.emoji} ${book.status.label}',
                              style: TextStyle(
                                fontSize: 11,
                                color: _statusColor(book.status),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (book.rating != null) ...[
                            const SizedBox(width: 8),
                            ...List.generate(
                              book.rating!,
                              (_) => const Icon(Icons.star,
                                  size: 14, color: Colors.amber),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                itemBuilder: (_) => [
                  if (book.status == ReadingStatus.wantToRead)
                    const PopupMenuItem(
                        value: 'start', child: Text('📖 Start Reading')),
                  if (book.status == ReadingStatus.reading) ...[
                    const PopupMenuItem(
                        value: 'session', child: Text('📝 Log Session')),
                    const PopupMenuItem(
                        value: 'finish', child: Text('✅ Finish')),
                    const PopupMenuItem(
                        value: 'abandon', child: Text('🚫 Abandon')),
                  ],
                  const PopupMenuItem(
                      value: 'delete', child: Text('🗑️ Remove')),
                ],
                onSelected: (action) => _handleBookAction(book, action),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Stats Tab ─────────────────────────────────

  Widget _buildStatsTab(ThemeData theme) {
    final report = _service.generateReport(asOf: DateTime.now());
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          Row(
            children: [
              _statCard('📚', 'Total', '${report.totalBooks}', theme),
              const SizedBox(width: 8),
              _statCard('✅', 'Finished', '${report.booksFinished}', theme),
              const SizedBox(width: 8),
              _statCard('📖', 'Reading', '${report.booksReading}', theme),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statCard('📄', 'Pages',
                  '${report.totalPagesRead}', theme),
              const SizedBox(width: 8),
              _statCard('⏱️', 'Hours',
                  report.totalHoursRead.toStringAsFixed(1), theme),
              const SizedBox(width: 8),
              _statCard(
                  '⭐',
                  'Avg Rating',
                  report.averageRating > 0
                      ? report.averageRating.toStringAsFixed(1)
                      : '—',
                  theme),
            ],
          ),
          const SizedBox(height: 16),
          // Streak
          _sectionCard(
            theme,
            '🔥 Reading Streak',
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _streakStat('Current', '${report.streak.currentDays}',
                        'days', theme),
                    _streakStat('Longest', '${report.streak.longestDays}',
                        'days', theme),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Genre breakdown
          if (report.genreBreakdown.isNotEmpty) ...[
            _sectionCard(
              theme,
              '📊 Genre Breakdown',
              Column(
                children: report.genreBreakdown.take(6).map((g) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(g.genre.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(g.genre.label,
                                  style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 2),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: g.percentage / 100,
                                  minHeight: 6,
                                  backgroundColor:
                                      theme.colorScheme.surfaceContainerHighest,
                                  color: _genreColor(g.genre),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text('${g.count} (${g.percentage.toStringAsFixed(0)}%)',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Top authors
          if (report.topAuthors.isNotEmpty)
            _sectionCard(
              theme,
              '✍️ Top Authors',
              Column(
                children: report.topAuthors.take(5).map((a) {
                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(a.author),
                    subtitle: Text(
                        '${a.bookCount} book${a.bookCount == 1 ? '' : 's'} · ${a.pagesRead} pages'),
                    trailing: a.averageRating != null
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star,
                                  size: 16, color: Colors.amber),
                              Text(
                                  ' ${a.averageRating!.toStringAsFixed(1)}'),
                            ],
                          )
                        : null,
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(
      String emoji, String label, String value, ThemeData theme) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(value,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: theme.textTheme.labelSmall),
            ],
          ),
        ),
      ),
    );
  }

  Widget _streakStat(
      String label, String value, String unit, ThemeData theme) {
    return Column(
      children: [
        Text(value,
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        Text(unit, style: theme.textTheme.bodySmall),
        Text(label,
            style: theme.textTheme.labelSmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }

  Widget _sectionCard(ThemeData theme, String title, Widget child) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  // ── Challenge Tab ─────────────────────────────

  Widget _buildChallengeTab(ThemeData theme) {
    final now = DateTime.now();
    final challenge = _service.getChallenge(now.year);
    if (challenge == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎯', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('No reading challenge set for ${now.year}',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _showSetChallengeDialog,
              icon: const Icon(Icons.flag),
              label: const Text('Set Challenge'),
            ),
          ],
        ),
      );
    }
    final ahead = challenge.isAhead(now);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text('${now.year} Reading Challenge',
                      style: theme.textTheme.titleLarge),
                  const SizedBox(height: 24),
                  // Circular progress
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 180,
                          height: 180,
                          child: CircularProgressIndicator(
                            value: challenge.progressPercent / 100,
                            strokeWidth: 12,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${challenge.booksFinished}',
                              style: theme.textTheme.headlineLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'of ${challenge.goalBooks}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text('books',
                                style: theme.textTheme.labelSmall),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Pace indicator
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: (ahead ? Colors.green : Colors.orange)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      ahead
                          ? '🚀 Ahead of schedule!'
                          : '📈 ${challenge.booksRemaining} books to go',
                      style: TextStyle(
                        color: ahead ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Expected by now: ${challenge.expectedByNow(now).toStringAsFixed(1)} books',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _showSetChallengeDialog,
            icon: const Icon(Icons.edit),
            label: const Text('Update Goal'),
          ),
        ],
      ),
    );
  }

  // ── Recommend Tab ─────────────────────────────

  Widget _buildRecommendTab(ThemeData theme) {
    final recs = _service.getRecommendations(limit: 5);
    if (recs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💡', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('Add books to your "Want to Read" list',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Recommendations will appear based\non your reading history',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('📖 Suggested Next Reads',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text('Based on your genre preferences and ratings',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            )),
        const SizedBox(height: 16),
        ...recs.asMap().entries.map((e) {
          final i = e.key;
          final book = e.value;
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    _genreColor(book.genre).withOpacity(0.15),
                child: Text('${i + 1}',
                    style: TextStyle(
                        color: _genreColor(book.genre),
                        fontWeight: FontWeight.bold)),
              ),
              title: Text(book.title),
              subtitle: Text(
                  '${book.author} · ${book.genre.emoji} ${book.genre.label} · ${book.totalPages}p'),
              trailing: FilledButton.tonal(
                onPressed: () {
                  _service.startReading(book.id);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Started reading "${book.title}"!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Start'),
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Dialogs & Actions ─────────────────────────

  void _showAddBookDialog() {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final pagesCtrl = TextEditingController();
    final tagsCtrl = TextEditingController();
    BookGenre selectedGenre = BookGenre.fiction;
    ReadingStatus selectedStatus = ReadingStatus.wantToRead;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Book'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Title *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: authorCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Author *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pagesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Total Pages *',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BookGenre>(
                  value: selectedGenre,
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                    border: OutlineInputBorder(),
                  ),
                  items: BookGenre.values
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text('${g.emoji} ${g.label}'),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedGenre = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<ReadingStatus>(
                  value: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                  ),
                  items: ReadingStatus.values
                      .map((s) => DropdownMenuItem(
                            value: s,
                            child: Text('${s.emoji} ${s.label}'),
                          ))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => selectedStatus = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tagsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tags (comma-separated)',
                    border: OutlineInputBorder(),
                    hintText: 'sci-fi, classic, recommended',
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
                final title = titleCtrl.text.trim();
                final author = authorCtrl.text.trim();
                final pages = int.tryParse(pagesCtrl.text.trim());
                if (title.isEmpty || author.isEmpty || pages == null || pages <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all required fields'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                final tags = tagsCtrl.text
                    .split(',')
                    .map((t) => t.trim())
                    .where((t) => t.isNotEmpty)
                    .toList();
                final book = Book(
                  id: 'b${_nextId++}',
                  title: title,
                  author: author,
                  genre: selectedGenre,
                  totalPages: pages,
                  status: selectedStatus,
                  dateAdded: DateTime.now(),
                  dateStarted: selectedStatus == ReadingStatus.reading
                      ? DateTime.now()
                      : null,
                  tags: tags,
                );
                _service.addBook(book);
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added "${book.title}"'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBookDetail(Book book) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) {
          final theme = Theme.of(ctx);
          return SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                // Title & author
                Text(book.genre.emoji,
                    style: const TextStyle(fontSize: 40)),
                const SizedBox(height: 8),
                Text(book.title,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('by ${book.author}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    )),
                const SizedBox(height: 12),
                // Status & rating
                Wrap(
                  spacing: 8,
                  children: [
                    Chip(
                      label: Text('${book.status.emoji} ${book.status.label}'),
                      backgroundColor:
                          _statusColor(book.status).withOpacity(0.1),
                    ),
                    Chip(
                      label:
                          Text('${book.genre.emoji} ${book.genre.label}'),
                    ),
                    if (book.rating != null)
                      Chip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ...List.generate(
                              book.rating!,
                              (_) => const Icon(Icons.star,
                                  size: 14, color: Colors.amber),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (book.tags.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 4,
                    children: book.tags
                        .map((t) => Chip(
                              label: Text(t,
                                  style: const TextStyle(fontSize: 11)),
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ))
                        .toList(),
                  ),
                ],
                const SizedBox(height: 16),
                // Progress
                if (book.status == ReadingStatus.reading ||
                    book.status == ReadingStatus.finished) ...[
                  _sectionCard(
                    theme,
                    '📊 Progress',
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '${book.currentPage} / ${book.totalPages} pages'),
                            Text(
                                '${book.progressPercent.toStringAsFixed(0)}%'),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: book.progressPercent / 100,
                            minHeight: 8,
                            backgroundColor:
                                theme.colorScheme.surfaceContainerHighest,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (book.totalMinutesRead > 0)
                          Text(
                            '${(book.totalMinutesRead / 60).toStringAsFixed(1)} hours read · '
                            '${book.averagePagesPerMinute.toStringAsFixed(1)} pages/min',
                            style: theme.textTheme.bodySmall,
                          ),
                        if (book.estimatedMinutesToFinish.isFinite &&
                            book.status == ReadingStatus.reading)
                          Text(
                            '~${(book.estimatedMinutesToFinish / 60).toStringAsFixed(1)} hours to finish',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Sessions
                if (book.sessions.isNotEmpty) ...[
                  _sectionCard(
                    theme,
                    '📝 Reading Sessions (${book.sessions.length})',
                    Column(
                      children: book.sessions.reversed.take(10).map((s) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                '${s.date.month}/${s.date.day}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text('${s.pagesRead}p',
                                  style: theme.textTheme.bodySmall),
                              const SizedBox(width: 8),
                              Text('${s.minutesSpent}min',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  )),
                              if (s.notes != null) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(s.notes!,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: theme
                                            .colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                // Review
                if (book.review != null) ...[
                  const SizedBox(height: 12),
                  _sectionCard(
                    theme,
                    '💬 Review',
                    Text(book.review!, style: theme.textTheme.bodyMedium),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showLogSessionDialog(Book book) {
    final pagesCtrl = TextEditingController();
    final minutesCtrl = TextEditingController();
    final notesCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Log Session — ${book.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pagesCtrl,
              decoration: const InputDecoration(
                labelText: 'Pages read',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minutesCtrl,
              decoration: const InputDecoration(
                labelText: 'Minutes spent',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              final pages = int.tryParse(pagesCtrl.text.trim());
              final minutes = int.tryParse(minutesCtrl.text.trim());
              if (pages == null || minutes == null || pages <= 0 || minutes <= 0) {
                return;
              }
              _service.logSession(
                book.id,
                ReadingSession(
                  date: DateTime.now(),
                  pagesRead: pages,
                  minutesSpent: minutes,
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                ),
              );
              setState(() {});
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Logged ${pages}p in ${minutes}min ✅'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Log'),
          ),
        ],
      ),
    );
  }

  void _showFinishDialog(Book book) {
    int rating = 4;
    final reviewCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Finish "${book.title}"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate this book:'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return IconButton(
                    icon: Icon(
                      i < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                    onPressed: () =>
                        setDialogState(() => rating = i + 1),
                  );
                }),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: reviewCtrl,
                decoration: const InputDecoration(
                  labelText: 'Review (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                _service.finishBook(
                  book.id,
                  rating: rating,
                  review: reviewCtrl.text.trim().isEmpty
                      ? null
                      : reviewCtrl.text.trim(),
                );
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Finished "${book.title}"! ${'⭐' * rating}'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Finish'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSetChallengeDialog() {
    final goalCtrl = TextEditingController(text: '12');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${DateTime.now().year} Reading Challenge'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('How many books do you want to read this year?'),
            const SizedBox(height: 16),
            TextField(
              controller: goalCtrl,
              decoration: const InputDecoration(
                labelText: 'Book goal',
                border: OutlineInputBorder(),
                suffixText: 'books',
              ),
              keyboardType: TextInputType.number,
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
              final goal = int.tryParse(goalCtrl.text.trim());
              if (goal == null || goal <= 0) return;
              _service.setChallenge(DateTime.now().year, goal);
              setState(() {});
              Navigator.pop(ctx);
            },
            child: const Text('Set Goal'),
          ),
        ],
      ),
    );
  }

  void _handleBookAction(Book book, String action) {
    switch (action) {
      case 'start':
        _service.startReading(book.id);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Started reading "${book.title}" 📖'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case 'session':
        _showLogSessionDialog(book);
        break;
      case 'finish':
        _showFinishDialog(book);
        break;
      case 'abandon':
        _service.abandonBook(book.id);
        setState(() {});
        break;
      case 'delete':
        _service.removeBook(book.id);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${book.title}"'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
    }
  }

  // ── Helpers ───────────────────────────────────

  Color _genreColor(BookGenre genre) {
    switch (genre) {
      case BookGenre.fiction:
        return Colors.blue;
      case BookGenre.nonFiction:
        return Colors.green;
      case BookGenre.sciFi:
        return Colors.purple;
      case BookGenre.fantasy:
        return Colors.deepPurple;
      case BookGenre.mystery:
        return Colors.brown;
      case BookGenre.biography:
        return Colors.teal;
      case BookGenre.selfHelp:
        return Colors.orange;
      case BookGenre.technical:
        return Colors.indigo;
      case BookGenre.history:
        return Colors.amber;
      case BookGenre.philosophy:
        return Colors.blueGrey;
      case BookGenre.science:
        return Colors.cyan;
      case BookGenre.business:
        return Colors.red;
      case BookGenre.poetry:
        return Colors.pink;
      case BookGenre.other:
        return Colors.grey;
    }
  }

  Color _statusColor(ReadingStatus status) {
    switch (status) {
      case ReadingStatus.wantToRead:
        return Colors.blue;
      case ReadingStatus.reading:
        return Colors.orange;
      case ReadingStatus.finished:
        return Colors.green;
      case ReadingStatus.abandoned:
        return Colors.red;
    }
  }
}
