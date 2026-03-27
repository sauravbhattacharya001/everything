import 'dart:convert';
import '../../models/library_book_entry.dart';

/// Summary of library book activity.
class LibrarySummary {
  final int totalBooks;
  final int currentlyBorrowed;
  final int overdueCount;
  final int dueSoonCount;
  final int returnedCount;
  final int totalRenewals;
  final double totalLateFees;
  final Map<BookGenre, int> genreBreakdown;
  final Map<String, int> libraryBreakdown;

  const LibrarySummary({
    required this.totalBooks,
    required this.currentlyBorrowed,
    required this.overdueCount,
    required this.dueSoonCount,
    required this.returnedCount,
    required this.totalRenewals,
    required this.totalLateFees,
    required this.genreBreakdown,
    required this.libraryBreakdown,
  });
}

/// Service for managing library book borrowings.
class LibraryBookService {
  static const _storageKey = 'library_books';
  List<LibraryBookEntry> _books = [];

  List<LibraryBookEntry> get books => List.unmodifiable(_books);

  /// Currently borrowed (not returned/lost) books.
  List<LibraryBookEntry> get currentBooks => _books
      .where((b) =>
          b.status != LibraryBookStatus.returned &&
          b.status != LibraryBookStatus.lost)
      .toList();

  /// Overdue books.
  List<LibraryBookEntry> get overdueBooks =>
      currentBooks.where((b) => b.isOverdue).toList();

  /// Books due soon (within 3 days).
  List<LibraryBookEntry> get dueSoonBooks =>
      currentBooks.where((b) => b.isDueSoon).toList();

  /// Returned books.
  List<LibraryBookEntry> get returnedBooks =>
      _books.where((b) => b.status == LibraryBookStatus.returned).toList();

  /// Load books from JSON string.
  void loadFromJson(String? json) {
    if (json == null || json.isEmpty) {
      _books = [];
      return;
    }
    try {
      final list = jsonDecode(json) as List<dynamic>;
      _books = list
          .map((e) => LibraryBookEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      _updateOverdueStatuses();
    } catch (_) {
      _books = [];
    }
  }

  /// Serialize books to JSON string.
  String toJson() =>
      jsonEncode(_books.map((b) => b.toJson()).toList());

  /// Add a new book borrowing.
  void addBook(LibraryBookEntry book) {
    _books.insert(0, book);
  }

  /// Update an existing book.
  void updateBook(LibraryBookEntry updated) {
    final idx = _books.indexWhere((b) => b.id == updated.id);
    if (idx >= 0) _books[idx] = updated;
  }

  /// Remove a book entry.
  void removeBook(String id) {
    _books.removeWhere((b) => b.id == id);
  }

  /// Mark a book as returned.
  void returnBook(String id, {int? rating}) {
    final idx = _books.indexWhere((b) => b.id == id);
    if (idx >= 0) {
      _books[idx] = _books[idx].copyWith(
        status: LibraryBookStatus.returned,
        returnDate: DateTime.now(),
        rating: rating ?? _books[idx].rating,
      );
    }
  }

  /// Renew a book (extend due date by 14 days).
  bool renewBook(String id) {
    final idx = _books.indexWhere((b) => b.id == id);
    if (idx < 0) return false;
    final book = _books[idx];
    if (!book.canRenew) return false;
    _books[idx] = book.copyWith(
      dueDate: book.dueDate.add(const Duration(days: 14)),
      renewalCount: book.renewalCount + 1,
      status: LibraryBookStatus.renewed,
    );
    return true;
  }

  /// Mark a book as lost.
  void markLost(String id) {
    final idx = _books.indexWhere((b) => b.id == id);
    if (idx >= 0) {
      _books[idx] = _books[idx].copyWith(status: LibraryBookStatus.lost);
    }
  }

  /// Update statuses of overdue books.
  void _updateOverdueStatuses() {
    for (var i = 0; i < _books.length; i++) {
      final b = _books[i];
      if (b.status == LibraryBookStatus.borrowed ||
          b.status == LibraryBookStatus.renewed) {
        if (b.isOverdue) {
          _books[i] = b.copyWith(status: LibraryBookStatus.overdue);
        }
      }
    }
  }

  /// Get overall summary.
  LibrarySummary getSummary() {
    _updateOverdueStatuses();
    final genreMap = <BookGenre, int>{};
    final libMap = <String, int>{};
    double totalFees = 0;
    int totalRenewals = 0;

    for (final b in _books) {
      genreMap[b.genre] = (genreMap[b.genre] ?? 0) + 1;
      libMap[b.libraryName] = (libMap[b.libraryName] ?? 0) + 1;
      totalFees += b.estimatedLateFee;
      totalRenewals += b.renewalCount;
    }

    return LibrarySummary(
      totalBooks: _books.length,
      currentlyBorrowed: currentBooks.length,
      overdueCount: overdueBooks.length,
      dueSoonCount: dueSoonBooks.length,
      returnedCount: returnedBooks.length,
      totalRenewals: totalRenewals,
      totalLateFees: totalFees,
      genreBreakdown: genreMap,
      libraryBreakdown: libMap,
    );
  }

  /// Sort books by due date (soonest first).
  List<LibraryBookEntry> sortedByDueDate() {
    final sorted = List<LibraryBookEntry>.from(currentBooks);
    sorted.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return sorted;
  }

  /// Filter books by genre.
  List<LibraryBookEntry> filterByGenre(BookGenre genre) =>
      _books.where((b) => b.genre == genre).toList();

  /// Filter books by library.
  List<LibraryBookEntry> filterByLibrary(String libraryName) =>
      _books.where((b) => b.libraryName == libraryName).toList();

  /// Search books by title or author.
  List<LibraryBookEntry> search(String query) {
    final q = query.toLowerCase();
    return _books
        .where((b) =>
            b.title.toLowerCase().contains(q) ||
            (b.author?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  /// Average days a book is borrowed.
  double get averageBorrowDays {
    final returned = returnedBooks;
    if (returned.isEmpty) return 0;
    final total = returned.fold<int>(0, (sum, b) => sum + b.daysBorrowed);
    return total / returned.length;
  }

  /// Unique libraries used.
  List<String> get libraries =>
      _books.map((b) => b.libraryName).toSet().toList()..sort();

  String get storageKey => _storageKey;
}
