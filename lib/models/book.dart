import 'dart:convert';

/// Reading status of a book.
enum ReadingStatus {
  wantToRead,
  reading,
  finished,
  abandoned;

  String get label {
    switch (this) {
      case ReadingStatus.wantToRead:
        return 'Want to Read';
      case ReadingStatus.reading:
        return 'Currently Reading';
      case ReadingStatus.finished:
        return 'Finished';
      case ReadingStatus.abandoned:
        return 'Abandoned';
    }
  }

  String get emoji {
    switch (this) {
      case ReadingStatus.wantToRead:
        return '📋';
      case ReadingStatus.reading:
        return '📖';
      case ReadingStatus.finished:
        return '✅';
      case ReadingStatus.abandoned:
        return '🚫';
    }
  }
}

/// Book genre/category.
enum BookGenre {
  fiction,
  nonFiction,
  sciFi,
  fantasy,
  mystery,
  biography,
  selfHelp,
  technical,
  history,
  philosophy,
  science,
  business,
  poetry,
  other;

  String get label {
    switch (this) {
      case BookGenre.fiction:
        return 'Fiction';
      case BookGenre.nonFiction:
        return 'Non-Fiction';
      case BookGenre.sciFi:
        return 'Sci-Fi';
      case BookGenre.fantasy:
        return 'Fantasy';
      case BookGenre.mystery:
        return 'Mystery';
      case BookGenre.biography:
        return 'Biography';
      case BookGenre.selfHelp:
        return 'Self-Help';
      case BookGenre.technical:
        return 'Technical';
      case BookGenre.history:
        return 'History';
      case BookGenre.philosophy:
        return 'Philosophy';
      case BookGenre.science:
        return 'Science';
      case BookGenre.business:
        return 'Business';
      case BookGenre.poetry:
        return 'Poetry';
      case BookGenre.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case BookGenre.fiction:
        return '📕';
      case BookGenre.nonFiction:
        return '📗';
      case BookGenre.sciFi:
        return '🚀';
      case BookGenre.fantasy:
        return '🧙';
      case BookGenre.mystery:
        return '🔍';
      case BookGenre.biography:
        return '👤';
      case BookGenre.selfHelp:
        return '💪';
      case BookGenre.technical:
        return '💻';
      case BookGenre.history:
        return '🏛️';
      case BookGenre.philosophy:
        return '🤔';
      case BookGenre.science:
        return '🔬';
      case BookGenre.business:
        return '💼';
      case BookGenre.poetry:
        return '🌹';
      case BookGenre.other:
        return '📚';
    }
  }
}

/// A reading session log entry.
class ReadingSession {
  final DateTime date;
  final int pagesRead;
  final int minutesSpent;
  final String? notes;

  const ReadingSession({
    required this.date,
    required this.pagesRead,
    required this.minutesSpent,
    this.notes,
  });

  double get pagesPerMinute =>
      minutesSpent > 0 ? pagesRead / minutesSpent : 0;

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'pagesRead': pagesRead,
        'minutesSpent': minutesSpent,
        if (notes != null) 'notes': notes,
      };

  factory ReadingSession.fromJson(Map<String, dynamic> json) {
    return ReadingSession(
      date: DateTime.parse(json['date'] as String),
      pagesRead: json['pagesRead'] as int,
      minutesSpent: json['minutesSpent'] as int,
      notes: json['notes'] as String?,
    );
  }
}

/// A book in the reading list.
class Book {
  final String id;
  final String title;
  final String author;
  final BookGenre genre;
  final int totalPages;
  final ReadingStatus status;
  final int currentPage;
  final int? rating; // 1-5 stars, null if not rated
  final String? review;
  final DateTime dateAdded;
  final DateTime? dateStarted;
  final DateTime? dateFinished;
  final List<ReadingSession> sessions;
  final List<String> tags;

  const Book({
    required this.id,
    required this.title,
    required this.author,
    this.genre = BookGenre.other,
    required this.totalPages,
    this.status = ReadingStatus.wantToRead,
    this.currentPage = 0,
    this.rating,
    this.review,
    required this.dateAdded,
    this.dateStarted,
    this.dateFinished,
    this.sessions = const [],
    this.tags = const [],
  });

  double get progressPercent =>
      totalPages > 0 ? (currentPage / totalPages * 100).clamp(0, 100) : 0;

  int get pagesRemaining => (totalPages - currentPage).clamp(0, totalPages);

  int get totalMinutesRead =>
      sessions.fold(0, (sum, s) => sum + s.minutesSpent);

  int get totalPagesLogged =>
      sessions.fold(0, (sum, s) => sum + s.pagesRead);

  double get averagePagesPerMinute {
    final totalMin = totalMinutesRead;
    if (totalMin == 0) return 0;
    return totalPagesLogged / totalMin;
  }

  /// Estimated minutes to finish based on reading pace.
  double get estimatedMinutesToFinish {
    final pace = averagePagesPerMinute;
    if (pace <= 0) return double.infinity;
    return pagesRemaining / pace;
  }

  Book copyWith({
    String? id,
    String? title,
    String? author,
    BookGenre? genre,
    int? totalPages,
    ReadingStatus? status,
    int? currentPage,
    int? rating,
    String? review,
    DateTime? dateAdded,
    DateTime? dateStarted,
    DateTime? dateFinished,
    List<ReadingSession>? sessions,
    List<String>? tags,
  }) {
    return Book(
      id: id ?? this.id,
      title: title ?? this.title,
      author: author ?? this.author,
      genre: genre ?? this.genre,
      totalPages: totalPages ?? this.totalPages,
      status: status ?? this.status,
      currentPage: currentPage ?? this.currentPage,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      dateAdded: dateAdded ?? this.dateAdded,
      dateStarted: dateStarted ?? this.dateStarted,
      dateFinished: dateFinished ?? this.dateFinished,
      sessions: sessions ?? this.sessions,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'genre': genre.name,
        'totalPages': totalPages,
        'status': status.name,
        'currentPage': currentPage,
        if (rating != null) 'rating': rating,
        if (review != null) 'review': review,
        'dateAdded': dateAdded.toIso8601String(),
        if (dateStarted != null) 'dateStarted': dateStarted!.toIso8601String(),
        if (dateFinished != null)
          'dateFinished': dateFinished!.toIso8601String(),
        'sessions': sessions.map((s) => s.toJson()).toList(),
        'tags': tags,
      };

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String,
      genre: BookGenre.values.firstWhere(
        (g) => g.name == json['genre'],
        orElse: () => BookGenre.other,
      ),
      totalPages: json['totalPages'] as int,
      status: ReadingStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => ReadingStatus.wantToRead,
      ),
      currentPage: json['currentPage'] as int? ?? 0,
      rating: json['rating'] as int?,
      review: json['review'] as String?,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      dateStarted: json['dateStarted'] != null
          ? DateTime.parse(json['dateStarted'] as String)
          : null,
      dateFinished: json['dateFinished'] != null
          ? DateTime.parse(json['dateFinished'] as String)
          : null,
      sessions: (json['sessions'] as List<dynamic>?)
              ?.map((s) => ReadingSession.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
      tags: (json['tags'] as List<dynamic>?)
              ?.map((t) => t as String)
              .toList() ??
          [],
    );
  }

  @override
  String toString() =>
      '${genre.emoji} "$title" by $author (${status.label}, ${progressPercent.toStringAsFixed(0)}%)';
}
