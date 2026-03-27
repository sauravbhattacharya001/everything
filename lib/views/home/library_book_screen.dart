import 'package:flutter/material.dart';
import '../../core/services/library_book_service.dart';
import '../../core/services/persistent_state_mixin.dart';
import '../../models/library_book_entry.dart';

/// Library Book Tracker screen — manage borrowed library books, track due
/// dates, renewals, and reading history.
class LibraryBookScreen extends StatefulWidget {
  const LibraryBookScreen({super.key});

  @override
  State<LibraryBookScreen> createState() => _LibraryBookScreenState();
}

class _LibraryBookScreenState extends State<LibraryBookScreen>
    with SingleTickerProviderStateMixin, PersistentStateMixin {
  @override
  String get storageKey => 'library_books';
  @override
  String exportData() => _service.toJson();
  @override
  void importData(String json) {
    _service.loadFromJson(json);
    setState(() {});
  }

  final LibraryBookService _service = LibraryBookService();
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
    if (_service.books.isEmpty) {
      _loadSampleData();
    }
    if (_service.books.isNotEmpty) {
      _nextId = _service.books
              .map((b) => int.tryParse(b.id.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)
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

  void _loadSampleData() {
    final now = DateTime.now();
    final samples = [
      LibraryBookEntry(
        id: 'lb1',
        title: 'Dune',
        author: 'Frank Herbert',
        genre: BookGenre.fiction,
        libraryName: 'Seattle Public Library',
        borrowDate: now.subtract(const Duration(days: 10)),
        dueDate: now.add(const Duration(days: 4)),
        lateFeePerDay: 0.25,
      ),
      LibraryBookEntry(
        id: 'lb2',
        title: 'Sapiens',
        author: 'Yuval Noah Harari',
        genre: BookGenre.nonFiction,
        libraryName: 'King County Library',
        borrowDate: now.subtract(const Duration(days: 20)),
        dueDate: now.subtract(const Duration(days: 1)),
        lateFeePerDay: 0.10,
      ),
      LibraryBookEntry(
        id: 'lb3',
        title: 'Clean Code',
        author: 'Robert C. Martin',
        genre: BookGenre.technology,
        libraryName: 'Seattle Public Library',
        borrowDate: now.subtract(const Duration(days: 25)),
        dueDate: now.subtract(const Duration(days: 5)),
        status: LibraryBookStatus.returned,
        returnDate: now.subtract(const Duration(days: 7)),
        rating: 4,
      ),
    ];
    for (final s in samples) {
      _service.addBook(s);
    }
    _nextId = 4;
    _save();
  }

  void _save() {
    savePersistence();
  }

  List<LibraryBookEntry> _filtered(List<LibraryBookEntry> source) {
    if (_searchQuery.isEmpty) return source;
    final q = _searchQuery.toLowerCase();
    return source
        .where((b) =>
            b.title.toLowerCase().contains(q) ||
            (b.author?.toLowerCase().contains(q) ?? false) ||
            b.libraryName.toLowerCase().contains(q))
        .toList();
  }

  void _showAddDialog() {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final libraryCtrl = TextEditingController(text: 'Seattle Public Library');
    final isbnCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    var genre = BookGenre.fiction;
    var loanDays = 21;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: const Text('Borrow a Book'),
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
                    labelText: 'Author',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<BookGenre>(
                  value: genre,
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                    border: OutlineInputBorder(),
                  ),
                  items: BookGenre.values
                      .map((g) => DropdownMenuItem(
                            value: g,
                            child: Text(g.label),
                          ))
                      .toList(),
                  onChanged: (v) => setDlgState(() => genre = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: libraryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Library *',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: isbnCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ISBN',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Loan period: '),
                    DropdownButton<int>(
                      value: loanDays,
                      items: [7, 14, 21, 28, 42]
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text('$d days'),
                              ))
                          .toList(),
                      onChanged: (v) => setDlgState(() => loanDays = v!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
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
                if (titleCtrl.text.trim().isEmpty ||
                    libraryCtrl.text.trim().isEmpty) return;
                final now = DateTime.now();
                final book = LibraryBookEntry(
                  id: 'lb${_nextId++}',
                  title: titleCtrl.text.trim(),
                  author: authorCtrl.text.trim().isEmpty
                      ? null
                      : authorCtrl.text.trim(),
                  genre: genre,
                  isbn: isbnCtrl.text.trim().isEmpty
                      ? null
                      : isbnCtrl.text.trim(),
                  libraryName: libraryCtrl.text.trim(),
                  borrowDate: now,
                  dueDate: now.add(Duration(days: loanDays)),
                  lateFeePerDay: 0.25,
                  notes: notesCtrl.text.trim().isEmpty
                      ? null
                      : notesCtrl.text.trim(),
                );
                _service.addBook(book);
                _save();
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Borrow'),
            ),
          ],
        ),
      ),
    );
  }

  void _returnBook(LibraryBookEntry book) {
    int? rating;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Return "${book.title}"?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Rate this book (optional):'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final star = i + 1;
                  return IconButton(
                    icon: Icon(
                      star <= (rating ?? 0)
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () =>
                        setDlgState(() => rating = star),
                  );
                }),
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
                _service.returnBook(book.id, rating: rating);
                _save();
                setState(() {});
                Navigator.pop(ctx);
              },
              child: const Text('Return'),
            ),
          ],
        ),
      ),
    );
  }

  void _renewBook(LibraryBookEntry book) {
    final ok = _service.renewBook(book.id);
    _save();
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Renewed "${book.title}" — new due date extended by 14 days'
            : 'Cannot renew "${book.title}" — max renewals reached'),
      ),
    );
  }

  Color _statusColor(LibraryBookEntry book) {
    if (book.status == LibraryBookStatus.returned) return Colors.green;
    if (book.status == LibraryBookStatus.lost) return Colors.grey;
    if (book.isOverdue) return Colors.red;
    if (book.isDueSoon) return Colors.orange;
    return Colors.blue;
  }

  String _statusLabel(LibraryBookEntry book) {
    if (book.status == LibraryBookStatus.returned) return 'Returned';
    if (book.status == LibraryBookStatus.lost) return 'Lost';
    if (book.isOverdue) return 'Overdue (${-book.daysRemaining}d)';
    if (book.isDueSoon) return 'Due soon (${book.daysRemaining}d)';
    return '${book.daysRemaining}d left';
  }

  Widget _buildBookTile(LibraryBookEntry book) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(book).withOpacity(0.15),
          child: Icon(Icons.menu_book, color: _statusColor(book)),
        ),
        title: Text(book.title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (book.author != null) Text(book.author!),
            Row(
              children: [
                Text(book.libraryName,
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade600)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _statusColor(book).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _statusLabel(book),
                    style: TextStyle(
                      fontSize: 11,
                      color: _statusColor(book),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (book.rating != null)
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < book.rating! ? Icons.star : Icons.star_border,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: (book.status != LibraryBookStatus.returned &&
                book.status != LibraryBookStatus.lost)
            ? PopupMenuButton<String>(
                onSelected: (action) {
                  if (action == 'return') _returnBook(book);
                  if (action == 'renew') _renewBook(book);
                  if (action == 'lost') {
                    _service.markLost(book.id);
                    _save();
                    setState(() {});
                  }
                  if (action == 'delete') {
                    _service.removeBook(book.id);
                    _save();
                    setState(() {});
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                      value: 'return', child: Text('Return')),
                  if (book.canRenew)
                    PopupMenuItem(
                      value: 'renew',
                      child: Text(
                          'Renew (${book.renewalCount}/${book.maxRenewals})'),
                    ),
                  const PopupMenuItem(
                      value: 'lost', child: Text('Mark Lost')),
                  const PopupMenuItem(
                      value: 'delete', child: Text('Delete')),
                ],
              )
            : IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                onPressed: () {
                  _service.removeBook(book.id);
                  _save();
                  setState(() {});
                },
              ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    final summary = _service.getSummary();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCard('Currently Borrowed', '${summary.currentlyBorrowed}',
            Icons.book, Colors.blue),
        _summaryCard('Overdue', '${summary.overdueCount}',
            Icons.warning_amber, Colors.red),
        _summaryCard('Due Soon', '${summary.dueSoonCount}',
            Icons.access_time, Colors.orange),
        _summaryCard('Total Returned', '${summary.returnedCount}',
            Icons.check_circle, Colors.green),
        _summaryCard('Total Renewals', '${summary.totalRenewals}',
            Icons.autorenew, Colors.purple),
        if (summary.totalLateFees > 0)
          _summaryCard(
              'Est. Late Fees',
              '\$${summary.totalLateFees.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.red),
        if (_service.returnedBooks.isNotEmpty)
          _summaryCard(
              'Avg. Borrow Days',
              _service.averageBorrowDays.toStringAsFixed(1),
              Icons.calendar_today,
              Colors.teal),
        if (summary.libraryBreakdown.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Libraries Used',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ...summary.libraryBreakdown.entries.map((e) => ListTile(
                leading: const Icon(Icons.local_library),
                title: Text(e.key),
                trailing: Text('${e.value} books'),
              )),
        ],
      ],
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final current = _filtered(_service.sortedByDueDate());
    final history = _filtered(_service.returnedBooks);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Books'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Current'),
            Tab(text: 'History'),
            Tab(text: 'Summary'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search books...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                current.isEmpty
                    ? const Center(
                        child: Text('No books currently borrowed'))
                    : ListView.builder(
                        itemCount: current.length,
                        itemBuilder: (_, i) =>
                            _buildBookTile(current[i]),
                      ),
                history.isEmpty
                    ? const Center(
                        child: Text('No returned books yet'))
                    : ListView.builder(
                        itemCount: history.length,
                        itemBuilder: (_, i) =>
                            _buildBookTile(history[i]),
                      ),
                _buildSummaryTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}
