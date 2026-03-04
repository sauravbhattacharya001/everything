import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/book.dart';
import 'package:everything/core/services/reading_list_service.dart';

Book _makeBook({
  String id = 'b1',
  String title = 'Test Book',
  String author = 'Author A',
  BookGenre genre = BookGenre.fiction,
  int totalPages = 300,
  ReadingStatus status = ReadingStatus.wantToRead,
  int currentPage = 0,
  int? rating,
  String? review,
  DateTime? dateAdded,
  DateTime? dateStarted,
  DateTime? dateFinished,
  List<ReadingSession> sessions = const [],
  List<String> tags = const [],
}) {
  return Book(
    id: id,
    title: title,
    author: author,
    genre: genre,
    totalPages: totalPages,
    status: status,
    currentPage: currentPage,
    rating: rating,
    review: review,
    dateAdded: dateAdded ?? DateTime(2026, 1, 1),
    dateStarted: dateStarted,
    dateFinished: dateFinished,
    sessions: sessions,
    tags: tags,
  );
}

void main() {
  group('Book model', () {
    test('progressPercent calculates correctly', () {
      final book = _makeBook(currentPage: 150, totalPages: 300);
      expect(book.progressPercent, 50.0);
    });

    test('progressPercent clamps to 100', () {
      final book = _makeBook(currentPage: 400, totalPages: 300);
      expect(book.progressPercent, 100.0);
    });

    test('progressPercent is 0 for 0-page book', () {
      final book = _makeBook(totalPages: 0);
      expect(book.progressPercent, 0);
    });

    test('pagesRemaining is correct', () {
      final book = _makeBook(currentPage: 120, totalPages: 300);
      expect(book.pagesRemaining, 180);
    });

    test('totalMinutesRead sums sessions', () {
      final book = _makeBook(sessions: [
        ReadingSession(date: DateTime(2026, 1, 1), pagesRead: 20, minutesSpent: 30),
        ReadingSession(date: DateTime(2026, 1, 2), pagesRead: 30, minutesSpent: 45),
      ]);
      expect(book.totalMinutesRead, 75);
    });

    test('averagePagesPerMinute calculates correctly', () {
      final book = _makeBook(sessions: [
        ReadingSession(date: DateTime(2026, 1, 1), pagesRead: 20, minutesSpent: 40),
      ]);
      expect(book.averagePagesPerMinute, 0.5);
    });

    test('estimatedMinutesToFinish with pace', () {
      final book = _makeBook(
        currentPage: 100,
        totalPages: 300,
        sessions: [
          ReadingSession(date: DateTime(2026, 1, 1), pagesRead: 100, minutesSpent: 200),
        ],
      );
      // 200 pages remaining, 0.5 pages/min = 400 min
      expect(book.estimatedMinutesToFinish, 400);
    });

    test('estimatedMinutesToFinish is infinity with no sessions', () {
      final book = _makeBook(currentPage: 50, totalPages: 300);
      expect(book.estimatedMinutesToFinish, double.infinity);
    });

    test('toJson and fromJson roundtrip', () {
      final book = _makeBook(
        rating: 4,
        review: 'Great book',
        dateStarted: DateTime(2026, 1, 5),
        dateFinished: DateTime(2026, 1, 20),
        status: ReadingStatus.finished,
        currentPage: 300,
        tags: ['classic', 'must-read'],
        sessions: [
          ReadingSession(date: DateTime(2026, 1, 5), pagesRead: 50, minutesSpent: 60, notes: 'Good start'),
        ],
      );
      final json = book.toJson();
      final restored = Book.fromJson(json);
      expect(restored.id, book.id);
      expect(restored.title, book.title);
      expect(restored.author, book.author);
      expect(restored.genre, book.genre);
      expect(restored.totalPages, book.totalPages);
      expect(restored.status, book.status);
      expect(restored.currentPage, book.currentPage);
      expect(restored.rating, book.rating);
      expect(restored.review, book.review);
      expect(restored.tags, book.tags);
      expect(restored.sessions.length, 1);
      expect(restored.sessions[0].notes, 'Good start');
    });

    test('copyWith preserves unchanged fields', () {
      final book = _makeBook(rating: 3, tags: ['a']);
      final updated = book.copyWith(rating: 5);
      expect(updated.rating, 5);
      expect(updated.title, book.title);
      expect(updated.tags, ['a']);
    });

    test('toString includes key info', () {
      final book = _makeBook(
        genre: BookGenre.sciFi,
        status: ReadingStatus.reading,
        currentPage: 150,
        totalPages: 300,
      );
      expect(book.toString(), contains('Sci-Fi'));
      expect(book.toString(), contains('50%'));
    });
  });

  group('ReadingSession', () {
    test('pagesPerMinute calculates correctly', () {
      final s = ReadingSession(date: DateTime(2026, 1, 1), pagesRead: 30, minutesSpent: 60);
      expect(s.pagesPerMinute, 0.5);
    });

    test('pagesPerMinute is 0 for zero minutes', () {
      final s = ReadingSession(date: DateTime(2026, 1, 1), pagesRead: 30, minutesSpent: 0);
      expect(s.pagesPerMinute, 0);
    });
  });

  group('ReadingStatus', () {
    test('all statuses have labels', () {
      for (final s in ReadingStatus.values) {
        expect(s.label.isNotEmpty, true);
        expect(s.emoji.isNotEmpty, true);
      }
    });
  });

  group('BookGenre', () {
    test('all genres have labels and emojis', () {
      for (final g in BookGenre.values) {
        expect(g.label.isNotEmpty, true);
        expect(g.emoji.isNotEmpty, true);
      }
    });
  });

  group('ReadingListService - CRUD', () {
    late ReadingListService service;

    setUp(() {
      service = ReadingListService();
    });

    test('addBook and getBook', () {
      service.addBook(_makeBook());
      expect(service.books.length, 1);
      expect(service.getBook('b1')?.title, 'Test Book');
    });

    test('addBook rejects duplicates', () {
      service.addBook(_makeBook());
      expect(() => service.addBook(_makeBook()), throwsArgumentError);
    });

    test('removeBook', () {
      service.addBook(_makeBook());
      service.removeBook('b1');
      expect(service.books.isEmpty, true);
    });

    test('getBook returns null for missing', () {
      expect(service.getBook('nope'), isNull);
    });

    test('updateBook works', () {
      service.addBook(_makeBook());
      service.updateBook(_makeBook(title: 'Updated'));
      expect(service.getBook('b1')?.title, 'Updated');
    });

    test('updateBook throws for missing book', () {
      expect(() => service.updateBook(_makeBook(id: 'nope')), throwsArgumentError);
    });
  });

  group('ReadingListService - Status transitions', () {
    late ReadingListService service;

    setUp(() {
      service = ReadingListService();
      service.addBook(_makeBook());
    });

    test('startReading sets status and date', () {
      service.startReading('b1', date: DateTime(2026, 2, 1));
      final book = service.getBook('b1')!;
      expect(book.status, ReadingStatus.reading);
      expect(book.dateStarted, DateTime(2026, 2, 1));
    });

    test('finishBook sets status, page, rating', () {
      service.finishBook('b1', rating: 5, review: 'Amazing', date: DateTime(2026, 3, 1));
      final book = service.getBook('b1')!;
      expect(book.status, ReadingStatus.finished);
      expect(book.currentPage, 300);
      expect(book.rating, 5);
      expect(book.review, 'Amazing');
    });

    test('abandonBook sets status', () {
      service.abandonBook('b1');
      expect(service.getBook('b1')!.status, ReadingStatus.abandoned);
    });

    test('startReading throws for missing book', () {
      expect(() => service.startReading('nope'), throwsArgumentError);
    });
  });

  group('ReadingListService - Sessions', () {
    late ReadingListService service;

    setUp(() {
      service = ReadingListService();
      service.addBook(_makeBook());
    });

    test('logSession updates page and adds session', () {
      service.logSession('b1', ReadingSession(
        date: DateTime(2026, 1, 10),
        pagesRead: 50,
        minutesSpent: 60,
      ));
      final book = service.getBook('b1')!;
      expect(book.currentPage, 50);
      expect(book.sessions.length, 1);
      expect(book.status, ReadingStatus.reading);
    });

    test('logSession clamps to totalPages', () {
      service.logSession('b1', ReadingSession(
        date: DateTime(2026, 1, 10),
        pagesRead: 500,
        minutesSpent: 600,
      ));
      expect(service.getBook('b1')!.currentPage, 300);
    });

    test('logSession sets dateStarted if not set', () {
      service.logSession('b1', ReadingSession(
        date: DateTime(2026, 2, 15),
        pagesRead: 10,
        minutesSpent: 15,
      ));
      expect(service.getBook('b1')!.dateStarted, DateTime(2026, 2, 15));
    });
  });

  group('ReadingListService - Filtering', () {
    late ReadingListService service;

    setUp(() {
      service = ReadingListService();
      service.addBook(_makeBook(id: 'b1', genre: BookGenre.fiction, author: 'Alice', tags: ['classic']));
      service.addBook(_makeBook(id: 'b2', genre: BookGenre.sciFi, author: 'Bob', tags: ['new']));
      service.addBook(_makeBook(id: 'b3', genre: BookGenre.fiction, author: 'Alice', status: ReadingStatus.reading));
    });

    test('byStatus filters correctly', () {
      expect(service.byStatus(ReadingStatus.wantToRead).length, 2);
      expect(service.byStatus(ReadingStatus.reading).length, 1);
    });

    test('byGenre filters correctly', () {
      expect(service.byGenre(BookGenre.fiction).length, 2);
      expect(service.byGenre(BookGenre.sciFi).length, 1);
    });

    test('byAuthor is case-insensitive', () {
      expect(service.byAuthor('alice').length, 2);
      expect(service.byAuthor('ALICE').length, 2);
    });

    test('byTag filters correctly', () {
      expect(service.byTag('classic').length, 1);
    });

    test('search matches title', () {
      expect(service.search('Test').length, 3);
    });

    test('byRating filters rated books', () {
      service.updateBook(_makeBook(id: 'b1', rating: 4));
      service.updateBook(_makeBook(id: 'b2', rating: 2));
      expect(service.byRating(minRating: 3).length, 1);
    });
  });

  group('ReadingListService - Sorting', () {
    late ReadingListService service;

    setUp(() {
      service = ReadingListService();
      service.addBook(_makeBook(id: 'b1', title: 'Zebra', dateAdded: DateTime(2026, 1, 1)));
      service.addBook(_makeBook(id: 'b2', title: 'Alpha', dateAdded: DateTime(2026, 3, 1)));
    });

    test('sortedByTitle ascending', () {
      final sorted = service.sortedByTitle();
      expect(sorted.first.title, 'Alpha');
    });

    test('sortedByTitle descending', () {
      final sorted = service.sortedByTitle(ascending: false);
      expect(sorted.first.title, 'Zebra');
    });

    test('sortedByDateAdded default is descending', () {
      final sorted = service.sortedByDateAdded();
      expect(sorted.first.title, 'Alpha');
    });

    test('sortedByRating', () {
      service.updateBook(_makeBook(id: 'b1', title: 'Zebra', rating: 5));
      service.updateBook(_makeBook(id: 'b2', title: 'Alpha', rating: 3));
      final sorted = service.sortedByRating();
      expect(sorted.first.rating, 5);
    });
  });

  group('ReadingListService - Streak', () {
    late ReadingListService service;

    setUp(() {
      service = ReadingListService();
    });

    test('empty books gives zero streak', () {
      final streak = service.getStreak();
      expect(streak.currentDays, 0);
      expect(streak.longestDays, 0);
    });

    test('consecutive days streak', () {
      final today = DateTime(2026, 3, 4);
      service.addBook(_makeBook(sessions: [
        ReadingSession(date: DateTime(2026, 3, 4), pagesRead: 10, minutesSpent: 15),
        ReadingSession(date: DateTime(2026, 3, 3), pagesRead: 10, minutesSpent: 15),
        ReadingSession(date: DateTime(2026, 3, 2), pagesRead: 10, minutesSpent: 15),
      ]));
      final streak = service.getStreak(asOf: today);
      expect(streak.currentDays, 3);
      expect(streak.longestDays, 3);
    });

    test('broken streak resets current', () {
      final today = DateTime(2026, 3, 4);
      service.addBook(_makeBook(sessions: [
        ReadingSession(date: DateTime(2026, 3, 4), pagesRead: 10, minutesSpent: 15),
        // gap on Mar 3
        ReadingSession(date: DateTime(2026, 3, 2), pagesRead: 10, minutesSpent: 15),
        ReadingSession(date: DateTime(2026, 3, 1), pagesRead: 10, minutesSpent: 15),
      ]));
      final streak = service.getStreak(asOf: today);
      expect(streak.currentDays, 1);
      expect(streak.longestDays, 2);
    });
  });

  group('ReadingListService - Genre stats', () {
    late ReadingListService service;

    setUp(() {
      service = ReadingListService();
      service.addBook(_makeBook(id: 'b1', genre: BookGenre.fiction, rating: 4));
      service.addBook(_makeBook(id: 'b2', genre: BookGenre.fiction, rating: 2));
      service.addBook(_makeBook(id: 'b3', genre: BookGenre.sciFi));
    });

    test('getGenreBreakdown returns sorted stats', () {
      final stats = service.getGenreBreakdown();
      expect(stats.length, 2);
      expect(stats.first.genre, BookGenre.fiction);
      expect(stats.first.count, 2);
      expect(stats.first.averageRating, 3.0);
    });

    test('empty list gives empty breakdown', () {
      final s = ReadingListService();
      expect(s.getGenreBreakdown(), isEmpty);
    });
  });

  group('ReadingListService - Author stats', () {
    test('getTopAuthors aggregates correctly', () {
      final service = ReadingListService();
      service.addBook(_makeBook(id: 'b1', author: 'Alice', currentPage: 100, rating: 4));
      service.addBook(_makeBook(id: 'b2', author: 'Alice', currentPage: 200, rating: 5));
      service.addBook(_makeBook(id: 'b3', author: 'Bob', currentPage: 50));
      final authors = service.getTopAuthors();
      expect(authors.first.author, 'Alice');
      expect(authors.first.bookCount, 2);
      expect(authors.first.pagesRead, 300);
      expect(authors.first.averageRating, 4.5);
    });
  });

  group('ReadingListService - Monthly summaries', () {
    test('groups by month', () {
      final service = ReadingListService();
      service.addBook(_makeBook(
        id: 'b1', status: ReadingStatus.finished,
        dateFinished: DateTime(2026, 1, 15), totalPages: 200,
      ));
      service.addBook(_makeBook(
        id: 'b2', status: ReadingStatus.finished,
        dateFinished: DateTime(2026, 1, 25), totalPages: 300,
      ));
      service.addBook(_makeBook(
        id: 'b3', status: ReadingStatus.finished,
        dateFinished: DateTime(2026, 2, 10), totalPages: 150,
      ));
      final summaries = service.getMonthlySummaries();
      expect(summaries.length, 2);
      expect(summaries[0].booksFinished, 2);
      expect(summaries[0].monthLabel, 'Jan 2026');
      expect(summaries[1].booksFinished, 1);
    });

    test('filter by year', () {
      final service = ReadingListService();
      service.addBook(_makeBook(
        id: 'b1', status: ReadingStatus.finished,
        dateFinished: DateTime(2025, 6, 1),
      ));
      service.addBook(_makeBook(
        id: 'b2', status: ReadingStatus.finished,
        dateFinished: DateTime(2026, 1, 1),
      ));
      expect(service.getMonthlySummaries(year: 2026).length, 1);
    });
  });

  group('ReadingListService - Challenge', () {
    test('setChallenge and getChallenge', () {
      final service = ReadingListService();
      service.addBook(_makeBook(
        id: 'b1', status: ReadingStatus.finished,
        dateFinished: DateTime(2026, 2, 1),
      ));
      service.addBook(_makeBook(
        id: 'b2', status: ReadingStatus.finished,
        dateFinished: DateTime(2026, 5, 1),
      ));
      service.setChallenge(2026, 12);
      final challenge = service.getChallenge(2026)!;
      expect(challenge.booksFinished, 2);
      expect(challenge.goalBooks, 12);
      expect(challenge.progressPercent, closeTo(16.67, 0.1));
      expect(challenge.booksRemaining, 10);
    });

    test('getChallenge returns null for wrong year', () {
      final service = ReadingListService();
      service.setChallenge(2026, 10);
      expect(service.getChallenge(2025), isNull);
    });

    test('isAhead check works', () {
      final challenge = ReadingChallenge(year: 2026, goalBooks: 12, booksFinished: 6);
      // By June, expected ~6 books, so should be on track
      expect(challenge.isAhead(DateTime(2026, 7, 1)), true);
      expect(challenge.isAhead(DateTime(2026, 2, 1)), true);
    });
  });

  group('ReadingListService - Recommendations', () {
    test('recommends based on genre preference', () {
      final service = ReadingListService();
      // User loves sci-fi
      service.addBook(_makeBook(id: 'b1', genre: BookGenre.sciFi, rating: 5,
          status: ReadingStatus.finished, dateFinished: DateTime(2026, 1, 1)));
      service.addBook(_makeBook(id: 'b2', genre: BookGenre.sciFi, rating: 4,
          status: ReadingStatus.finished, dateFinished: DateTime(2026, 1, 15)));
      // Want to read: one scifi, one fiction
      service.addBook(_makeBook(id: 'b3', genre: BookGenre.sciFi, title: 'SciFi Pick'));
      service.addBook(_makeBook(id: 'b4', genre: BookGenre.fiction, title: 'Fiction Pick'));

      final recs = service.getRecommendations();
      expect(recs.first.title, 'SciFi Pick');
    });

    test('empty want-to-read gives empty recommendations', () {
      final service = ReadingListService();
      service.addBook(_makeBook(status: ReadingStatus.reading));
      expect(service.getRecommendations(), isEmpty);
    });
  });

  group('ReadingListService - Report', () {
    test('generateReport returns comprehensive data', () {
      final service = ReadingListService();
      service.addBook(_makeBook(id: 'b1', genre: BookGenre.fiction, rating: 4,
          status: ReadingStatus.finished, currentPage: 300,
          dateFinished: DateTime(2026, 1, 20), sessions: [
            ReadingSession(date: DateTime(2026, 1, 10), pagesRead: 150, minutesSpent: 180),
            ReadingSession(date: DateTime(2026, 1, 15), pagesRead: 150, minutesSpent: 180),
          ]));
      service.addBook(_makeBook(id: 'b2', genre: BookGenre.sciFi,
          status: ReadingStatus.reading, currentPage: 100));
      service.addBook(_makeBook(id: 'b3'));

      service.setChallenge(2026, 10);
      final report = service.generateReport(challengeYear: 2026, asOf: DateTime(2026, 3, 4));
      expect(report.totalBooks, 3);
      expect(report.booksFinished, 1);
      expect(report.booksReading, 1);
      expect(report.booksWantToRead, 1);
      expect(report.totalPagesRead, 400); // 300 + 100 + 0
      expect(report.totalMinutesRead, 360);
      expect(report.averageRating, 4.0);
      expect(report.genreBreakdown.isNotEmpty, true);
      expect(report.challenge, isNotNull);
      expect(report.monthlySummaries.length, 1);
    });

    test('report toTextSummary generates readable output', () {
      final service = ReadingListService();
      service.addBook(_makeBook(id: 'b1', rating: 5,
          status: ReadingStatus.finished, dateFinished: DateTime(2026, 1, 1)));
      final report = service.generateReport();
      final text = report.toTextSummary();
      expect(text, contains('Reading Report'));
      expect(text, contains('Finished: 1'));
    });
  });

  group('ReadingListService - Serialization', () {
    test('toJson and loadFromJson roundtrip', () {
      final service = ReadingListService();
      service.addBook(_makeBook(id: 'b1', rating: 4, tags: ['great']));
      service.addBook(_makeBook(id: 'b2', genre: BookGenre.mystery));
      service.setChallenge(2026, 20);

      final json = service.toJson();
      final restored = ReadingListService();
      restored.loadFromJson(json);

      expect(restored.books.length, 2);
      expect(restored.getBook('b1')?.rating, 4);
      expect(restored.getBook('b2')?.genre, BookGenre.mystery);
      expect(restored.getChallenge(2026), isNotNull);
    });
  });

  group('ReadingListService - Edge cases', () {
    test('search returns empty for no match', () {
      final service = ReadingListService();
      service.addBook(_makeBook());
      expect(service.search('xyz123'), isEmpty);
    });

    test('multiple sessions across books for streak', () {
      final service = ReadingListService();
      final today = DateTime(2026, 3, 4);
      service.addBook(_makeBook(id: 'b1', sessions: [
        ReadingSession(date: DateTime(2026, 3, 4), pagesRead: 10, minutesSpent: 15),
      ]));
      service.addBook(_makeBook(id: 'b2', sessions: [
        ReadingSession(date: DateTime(2026, 3, 3), pagesRead: 20, minutesSpent: 25),
      ]));
      final streak = service.getStreak(asOf: today);
      expect(streak.currentDays, 2);
    });

    test('sortedByProgress', () {
      final service = ReadingListService();
      service.addBook(_makeBook(id: 'b1', currentPage: 50, totalPages: 100));
      service.addBook(_makeBook(id: 'b2', currentPage: 90, totalPages: 100));
      final sorted = service.sortedByProgress();
      expect(sorted.first.id, 'b2');
    });
  });
}
