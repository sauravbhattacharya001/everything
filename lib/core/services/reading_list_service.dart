import '../../models/book.dart';

/// Reading challenge / annual goal.
class ReadingChallenge {
  final int year;
  final int goalBooks;
  final int booksFinished;

  const ReadingChallenge({
    required this.year,
    required this.goalBooks,
    required this.booksFinished,
  });

  double get progressPercent =>
      goalBooks > 0 ? (booksFinished / goalBooks * 100).clamp(0, 100) : 0;

  bool get isCompleted => booksFinished >= goalBooks;

  int get booksRemaining => (goalBooks - booksFinished).clamp(0, goalBooks);

  /// Expected books by this point in the year (linear pace).
  double expectedByNow(DateTime now) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31);
    final totalDays = end.difference(start).inDays;
    final elapsed = now.difference(start).inDays.clamp(0, totalDays);
    return goalBooks * elapsed / totalDays;
  }

  /// Whether ahead of schedule.
  bool isAhead(DateTime now) => booksFinished >= expectedByNow(now);
}

/// Reading streak info.
class ReadingStreak {
  final int currentDays;
  final int longestDays;
  final DateTime? lastReadDate;

  const ReadingStreak({
    this.currentDays = 0,
    this.longestDays = 0,
    this.lastReadDate,
  });
}

/// Genre distribution stats.
class GenreStats {
  final BookGenre genre;
  final int count;
  final double percentage;
  final double? averageRating;

  const GenreStats({
    required this.genre,
    required this.count,
    required this.percentage,
    this.averageRating,
  });
}

/// Author statistics.
class AuthorStats {
  final String author;
  final int bookCount;
  final int pagesRead;
  final double? averageRating;

  const AuthorStats({
    required this.author,
    required this.bookCount,
    required this.pagesRead,
    this.averageRating,
  });
}

/// Monthly reading summary.
class MonthlySummary {
  final int year;
  final int month;
  final int booksFinished;
  final int pagesRead;
  final int minutesRead;
  final List<Book> books;

  const MonthlySummary({
    required this.year,
    required this.month,
    required this.booksFinished,
    required this.pagesRead,
    required this.minutesRead,
    required this.books,
  });

  String get monthLabel {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[month - 1]} $year';
  }
}

/// Full reading stats report.
class ReadingReport {
  final int totalBooks;
  final int booksFinished;
  final int booksReading;
  final int booksWantToRead;
  final int booksAbandoned;
  final int totalPagesRead;
  final int totalMinutesRead;
  final double averageRating;
  final double averagePagesPerBook;
  final List<GenreStats> genreBreakdown;
  final List<AuthorStats> topAuthors;
  final ReadingStreak streak;
  final ReadingChallenge? challenge;
  final List<MonthlySummary> monthlySummaries;

  const ReadingReport({
    required this.totalBooks,
    required this.booksFinished,
    required this.booksReading,
    required this.booksWantToRead,
    required this.booksAbandoned,
    required this.totalPagesRead,
    required this.totalMinutesRead,
    required this.averageRating,
    required this.averagePagesPerBook,
    required this.genreBreakdown,
    required this.topAuthors,
    required this.streak,
    this.challenge,
    required this.monthlySummaries,
  });

  double get totalHoursRead => totalMinutesRead / 60;

  String toTextSummary() {
    final buf = StringBuffer();
    buf.writeln('📚 Reading Report');
    buf.writeln('═══════════════════════════════');
    buf.writeln('Total books: $totalBooks');
    buf.writeln('  ✅ Finished: $booksFinished');
    buf.writeln('  📖 Reading: $booksReading');
    buf.writeln('  📋 Want to Read: $booksWantToRead');
    buf.writeln('  🚫 Abandoned: $booksAbandoned');
    buf.writeln('');
    buf.writeln('📄 Pages read: $totalPagesRead');
    buf.writeln('⏱️ Time read: ${totalHoursRead.toStringAsFixed(1)} hours');
    buf.writeln(
        '⭐ Avg rating: ${averageRating > 0 ? averageRating.toStringAsFixed(1) : "N/A"}');
    buf.writeln(
        '📏 Avg pages/book: ${averagePagesPerBook.toStringAsFixed(0)}');
    buf.writeln('');
    buf.writeln('🔥 Current streak: ${streak.currentDays} days');
    buf.writeln('🏆 Longest streak: ${streak.longestDays} days');

    if (challenge != null) {
      buf.writeln('');
      buf.writeln(
          '🎯 Challenge: ${challenge!.booksFinished}/${challenge!.goalBooks} (${challenge!.progressPercent.toStringAsFixed(0)}%)');
    }

    if (genreBreakdown.isNotEmpty) {
      buf.writeln('');
      buf.writeln('📊 Genre breakdown:');
      for (final g in genreBreakdown.take(5)) {
        buf.writeln(
            '  ${g.genre.emoji} ${g.genre.label}: ${g.count} (${g.percentage.toStringAsFixed(0)}%)');
      }
    }

    if (topAuthors.isNotEmpty) {
      buf.writeln('');
      buf.writeln('✍️ Top authors:');
      for (final a in topAuthors.take(5)) {
        buf.writeln('  ${a.author}: ${a.bookCount} books');
      }
    }

    return buf.toString();
  }
}

/// Reading list tracker service.
class ReadingListService {
  final List<Book> _books = [];
  ReadingChallenge? _challenge;

  List<Book> get books => List.unmodifiable(_books);

  // ── CRUD ──────────────────────────────────────────

  void addBook(Book book) {
    if (_books.any((b) => b.id == book.id)) {
      throw ArgumentError('Book with id ${book.id} already exists');
    }
    _books.add(book);
  }

  void removeBook(String bookId) {
    _books.removeWhere((b) => b.id == bookId);
  }

  Book? getBook(String bookId) {
    try {
      return _books.firstWhere((b) => b.id == bookId);
    } catch (_) {
      return null;
    }
  }

  void updateBook(Book updated) {
    final idx = _books.indexWhere((b) => b.id == updated.id);
    if (idx < 0) throw ArgumentError('Book ${updated.id} not found');
    _books[idx] = updated;
  }

  // ── Status transitions ───────────────────────────

  void startReading(String bookId, {DateTime? date}) {
    final book = getBook(bookId);
    if (book == null) throw ArgumentError('Book $bookId not found');
    updateBook(book.copyWith(
      status: ReadingStatus.reading,
      dateStarted: date ?? DateTime.now(),
    ));
  }

  void finishBook(String bookId, {int? rating, String? review, DateTime? date}) {
    final book = getBook(bookId);
    if (book == null) throw ArgumentError('Book $bookId not found');
    updateBook(book.copyWith(
      status: ReadingStatus.finished,
      currentPage: book.totalPages,
      dateFinished: date ?? DateTime.now(),
      rating: rating,
      review: review,
    ));
  }

  void abandonBook(String bookId) {
    final book = getBook(bookId);
    if (book == null) throw ArgumentError('Book $bookId not found');
    updateBook(book.copyWith(status: ReadingStatus.abandoned));
  }

  // ── Reading sessions ─────────────────────────────

  void logSession(String bookId, ReadingSession session) {
    final book = getBook(bookId);
    if (book == null) throw ArgumentError('Book $bookId not found');
    final sessions = [...book.sessions, session];
    final newPage =
        (book.currentPage + session.pagesRead).clamp(0, book.totalPages);
    var status = book.status;
    if (status == ReadingStatus.wantToRead) {
      status = ReadingStatus.reading;
    }
    updateBook(book.copyWith(
      sessions: sessions,
      currentPage: newPage,
      status: status,
      dateStarted: book.dateStarted ?? session.date,
    ));
  }

  // ── Filtering & search ───────────────────────────

  List<Book> byStatus(ReadingStatus status) =>
      _books.where((b) => b.status == status).toList();

  List<Book> byGenre(BookGenre genre) =>
      _books.where((b) => b.genre == genre).toList();

  List<Book> byAuthor(String author) =>
      _books.where((b) => b.author.toLowerCase() == author.toLowerCase())
          .toList();

  List<Book> byTag(String tag) =>
      _books.where((b) => b.tags.contains(tag)).toList();

  List<Book> search(String query) {
    final q = query.toLowerCase();
    return _books.where((b) =>
        b.title.toLowerCase().contains(q) ||
        b.author.toLowerCase().contains(q) ||
        b.tags.any((t) => t.toLowerCase().contains(q))).toList();
  }

  List<Book> byRating({int minRating = 1, int maxRating = 5}) =>
      _books.where((b) =>
          b.rating != null && b.rating! >= minRating && b.rating! <= maxRating)
          .toList();

  // ── Sorting ──────────────────────────────────────

  List<Book> sortedByTitle({bool ascending = true}) {
    final sorted = List<Book>.from(_books)
      ..sort((a, b) => a.title.compareTo(b.title));
    return ascending ? sorted : sorted.reversed.toList();
  }

  List<Book> sortedByDateAdded({bool ascending = false}) {
    final sorted = List<Book>.from(_books)
      ..sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
    return ascending ? sorted : sorted.reversed.toList();
  }

  List<Book> sortedByProgress({bool ascending = false}) {
    final sorted = List<Book>.from(_books)
      ..sort((a, b) => a.progressPercent.compareTo(b.progressPercent));
    return ascending ? sorted : sorted.reversed.toList();
  }

  List<Book> sortedByRating({bool ascending = false}) {
    final sorted = List<Book>.from(_books)
      ..sort((a, b) => (a.rating ?? 0).compareTo(b.rating ?? 0));
    return ascending ? sorted : sorted.reversed.toList();
  }

  // ── Reading challenge ────────────────────────────

  void setChallenge(int year, int goalBooks) {
    final finished = _books
        .where((b) =>
            b.status == ReadingStatus.finished &&
            b.dateFinished != null &&
            b.dateFinished!.year == year)
        .length;
    _challenge = ReadingChallenge(
      year: year,
      goalBooks: goalBooks,
      booksFinished: finished,
    );
  }

  ReadingChallenge? getChallenge(int year) {
    if (_challenge?.year == year) {
      // Recalculate
      final finished = _books
          .where((b) =>
              b.status == ReadingStatus.finished &&
              b.dateFinished != null &&
              b.dateFinished!.year == year)
          .length;
      return ReadingChallenge(
        year: year,
        goalBooks: _challenge!.goalBooks,
        booksFinished: finished,
      );
    }
    return null;
  }

  // ── Streak tracking ──────────────────────────────

  ReadingStreak getStreak({DateTime? asOf}) {
    final now = asOf ?? DateTime.now();
    final allDates = <DateTime>{};
    for (final book in _books) {
      for (final session in book.sessions) {
        allDates.add(DateTime(
            session.date.year, session.date.month, session.date.day));
      }
    }
    if (allDates.isEmpty) return const ReadingStreak();

    final sorted = allDates.toList()..sort();
    final today = DateTime(now.year, now.month, now.day);

    // Current streak
    int current = 0;
    var checkDate = today;
    // Allow today or yesterday as the start
    if (allDates.contains(today)) {
      current = 1;
      checkDate = today.subtract(const Duration(days: 1));
    } else if (allDates.contains(today.subtract(const Duration(days: 1)))) {
      current = 1;
      checkDate = today.subtract(const Duration(days: 2));
    } else {
      return ReadingStreak(
        lastReadDate: sorted.last,
      );
    }
    while (allDates.contains(checkDate)) {
      current++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    // Longest streak
    int longest = 1;
    int run = 1;
    for (int i = 1; i < sorted.length; i++) {
      if (sorted[i].difference(sorted[i - 1]).inDays == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }
    if (current > longest) longest = current;

    return ReadingStreak(
      currentDays: current,
      longestDays: longest,
      lastReadDate: sorted.last,
    );
  }

  // ── Genre stats ──────────────────────────────────

  List<GenreStats> getGenreBreakdown() {
    if (_books.isEmpty) return [];
    final counts = <BookGenre, List<Book>>{};
    for (final b in _books) {
      counts.putIfAbsent(b.genre, () => []).add(b);
    }
    final stats = counts.entries.map((e) {
      final rated = e.value.where((b) => b.rating != null);
      final avgRating = rated.isNotEmpty
          ? rated.map((b) => b.rating!).reduce((a, b) => a + b) /
              rated.length
          : null;
      return GenreStats(
        genre: e.key,
        count: e.value.length,
        percentage: e.value.length / _books.length * 100,
        averageRating: avgRating,
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return stats;
  }

  // ── Author stats ─────────────────────────────────

  List<AuthorStats> getTopAuthors({int limit = 10}) {
    final groups = <String, List<Book>>{};
    for (final b in _books) {
      groups.putIfAbsent(b.author, () => []).add(b);
    }
    final stats = groups.entries.map((e) {
      final pages = e.value.fold<int>(0, (s, b) => s + b.currentPage);
      final rated = e.value.where((b) => b.rating != null);
      final avgRating = rated.isNotEmpty
          ? rated.map((b) => b.rating!).reduce((a, b) => a + b) /
              rated.length
          : null;
      return AuthorStats(
        author: e.key,
        bookCount: e.value.length,
        pagesRead: pages,
        averageRating: avgRating,
      );
    }).toList()
      ..sort((a, b) => b.bookCount.compareTo(a.bookCount));
    return stats.take(limit).toList();
  }

  // ── Monthly summaries ────────────────────────────

  List<MonthlySummary> getMonthlySummaries({int? year}) {
    final finished = _books.where((b) =>
        b.status == ReadingStatus.finished && b.dateFinished != null);
    final filtered = year != null
        ? finished.where((b) => b.dateFinished!.year == year)
        : finished;

    final groups = <String, List<Book>>{};
    for (final b in filtered) {
      final key = '${b.dateFinished!.year}-${b.dateFinished!.month}';
      groups.putIfAbsent(key, () => []).add(b);
    }

    return groups.entries.map((e) {
      final books = e.value;
      final parts = e.key.split('-');
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final pages = books.fold<int>(0, (s, b) => s + b.totalPages);
      final minutes = books.fold<int>(0, (s, b) => s + b.totalMinutesRead);
      return MonthlySummary(
        year: y,
        month: m,
        booksFinished: books.length,
        pagesRead: pages,
        minutesRead: minutes,
        books: books,
      );
    }).toList()
      ..sort((a, b) {
        final cmp = a.year.compareTo(b.year);
        return cmp != 0 ? cmp : a.month.compareTo(b.month);
      });
  }

  // ── Recommendations ──────────────────────────────

  /// Suggest next books to read based on genre preferences and ratings.
  List<Book> getRecommendations({int limit = 5}) {
    final wantToRead = byStatus(ReadingStatus.wantToRead);
    if (wantToRead.isEmpty) return [];

    // Score by genre preference (how many books of that genre user rated highly)
    final genreScores = <BookGenre, double>{};
    for (final b in _books.where((b) => b.rating != null)) {
      genreScores[b.genre] =
          (genreScores[b.genre] ?? 0) + (b.rating! / 5.0);
    }

    final scored = wantToRead.map((b) {
      final genreScore = genreScores[b.genre] ?? 0;
      // Also boost by author familiarity
      final authorBooks =
          _books.where((ob) => ob.author == b.author && ob.rating != null);
      final authorScore = authorBooks.isNotEmpty
          ? authorBooks.map((ob) => ob.rating!).reduce((a, b) => a + b) /
              authorBooks.length /
              5.0
          : 0.0;
      return MapEntry(b, genreScore * 0.7 + authorScore * 0.3);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return scored.take(limit).map((e) => e.key).toList();
  }

  // ── Full report ──────────────────────────────────

  ReadingReport generateReport({int? challengeYear, DateTime? asOf}) {
    final finished = byStatus(ReadingStatus.finished);
    final rated = finished.where((b) => b.rating != null);
    final avgRating = rated.isNotEmpty
        ? rated.map((b) => b.rating!).reduce((a, b) => a + b) / rated.length
        : 0.0;
    final totalPages =
        _books.fold<int>(0, (s, b) => s + b.currentPage);
    final totalMinutes =
        _books.fold<int>(0, (s, b) => s + b.totalMinutesRead);
    final avgPages = finished.isNotEmpty
        ? finished.fold<int>(0, (s, b) => s + b.totalPages) / finished.length
        : 0.0;

    return ReadingReport(
      totalBooks: _books.length,
      booksFinished: finished.length,
      booksReading: byStatus(ReadingStatus.reading).length,
      booksWantToRead: byStatus(ReadingStatus.wantToRead).length,
      booksAbandoned: byStatus(ReadingStatus.abandoned).length,
      totalPagesRead: totalPages,
      totalMinutesRead: totalMinutes,
      averageRating: avgRating,
      averagePagesPerBook: avgPages,
      genreBreakdown: getGenreBreakdown(),
      topAuthors: getTopAuthors(),
      streak: getStreak(asOf: asOf),
      challenge: challengeYear != null ? getChallenge(challengeYear) : null,
      monthlySummaries: getMonthlySummaries(),
    );
  }

  // ── Serialization ────────────────────────────────

  Map<String, dynamic> toJson() => {
        'books': _books.map((b) => b.toJson()).toList(),
        if (_challenge != null)
          'challenge': {
            'year': _challenge!.year,
            'goalBooks': _challenge!.goalBooks,
          },
      };

  /// Maximum books allowed via [loadFromJson].
  static const int maxImportBooks = 50000;

  void loadFromJson(Map<String, dynamic> json) {
    final bookList = json['books'] as List<dynamic>? ?? [];
    if (bookList.length > maxImportBooks) {
      throw ArgumentError(
        'Import exceeds maximum of $maxImportBooks books '
        '(got ${bookList.length}). This limit prevents memory exhaustion '
        'from corrupted or malicious data.',
      );
    }
    // Parse into temporary list first — preserve existing data on error.
    final parsed = <Book>[];
    for (final b in bookList) {
      parsed.add(Book.fromJson(b as Map<String, dynamic>));
    }
    // All parsed successfully — safe to apply.
    _books.clear();
    _books.addAll(parsed);
    if (json['challenge'] != null) {
      final c = json['challenge'] as Map<String, dynamic>;
      setChallenge(c['year'] as int, c['goalBooks'] as int);
    }
  }
}
