import 'dart:convert';
import 'package:everything/core/utils/date_utils.dart';

/// Status of a library book.
enum LibraryBookStatus {
  borrowed,
  returned,
  overdue,
  renewed,
  lost;

  String get label {
    switch (this) {
      case LibraryBookStatus.borrowed:
        return 'Borrowed';
      case LibraryBookStatus.returned:
        return 'Returned';
      case LibraryBookStatus.overdue:
        return 'Overdue';
      case LibraryBookStatus.renewed:
        return 'Renewed';
      case LibraryBookStatus.lost:
        return 'Lost';
    }
  }
}

/// Genre of library book.
enum BookGenre {
  fiction,
  nonFiction,
  science,
  history,
  biography,
  selfHelp,
  technology,
  children,
  mystery,
  fantasy,
  romance,
  reference,
  other;

  String get label {
    switch (this) {
      case BookGenre.fiction:
        return 'Fiction';
      case BookGenre.nonFiction:
        return 'Non-Fiction';
      case BookGenre.science:
        return 'Science';
      case BookGenre.history:
        return 'History';
      case BookGenre.biography:
        return 'Biography';
      case BookGenre.selfHelp:
        return 'Self-Help';
      case BookGenre.technology:
        return 'Technology';
      case BookGenre.children:
        return 'Children';
      case BookGenre.mystery:
        return 'Mystery';
      case BookGenre.fantasy:
        return 'Fantasy';
      case BookGenre.romance:
        return 'Romance';
      case BookGenre.reference:
        return 'Reference';
      case BookGenre.other:
        return 'Other';
    }
  }
}

/// A library book borrowing entry.
class LibraryBookEntry {
  final String id;
  final String title;
  final String? author;
  final BookGenre genre;
  final String? isbn;
  final String libraryName;
  final String? libraryCardNumber;
  final DateTime borrowDate;
  final DateTime dueDate;
  final DateTime? returnDate;
  final LibraryBookStatus status;
  final int renewalCount;
  final int maxRenewals;
  final double? lateFeePerDay;
  final String? notes;
  final int? rating;

  const LibraryBookEntry({
    required this.id,
    required this.title,
    this.author,
    this.genre = BookGenre.other,
    this.isbn,
    required this.libraryName,
    this.libraryCardNumber,
    required this.borrowDate,
    required this.dueDate,
    this.returnDate,
    this.status = LibraryBookStatus.borrowed,
    this.renewalCount = 0,
    this.maxRenewals = 3,
    this.lateFeePerDay,
    this.notes,
    this.rating,
  });

  /// Days remaining until due (negative if overdue).
  int get daysRemaining {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return dueDate.difference(today).inDays;
  }

  /// Whether the book is currently overdue.
  bool get isOverdue =>
      status != LibraryBookStatus.returned &&
      status != LibraryBookStatus.lost &&
      DateTime.now().isAfter(dueDate);

  /// Whether the book is due soon (within 3 days).
  bool get isDueSoon =>
      !isOverdue &&
      status != LibraryBookStatus.returned &&
      status != LibraryBookStatus.lost &&
      daysRemaining <= 3;

  /// Whether the book can be renewed.
  bool get canRenew =>
      renewalCount < maxRenewals &&
      status != LibraryBookStatus.returned &&
      status != LibraryBookStatus.lost;

  /// Estimated late fee if overdue.
  double get estimatedLateFee {
    if (!isOverdue || lateFeePerDay == null) return 0;
    final overdueDays = -daysRemaining;
    return overdueDays * lateFeePerDay!;
  }

  /// Days the book has been borrowed.
  int get daysBorrowed {
    final end = returnDate ?? DateTime.now();
    return end.difference(borrowDate).inDays;
  }

  LibraryBookEntry copyWith({
    String? id,
    String? title,
    String? author,
    BookGenre? genre,
    String? isbn,
    String? libraryName,
    String? libraryCardNumber,
    DateTime? borrowDate,
    DateTime? dueDate,
    DateTime? returnDate,
    LibraryBookStatus? status,
    int? renewalCount,
    int? maxRenewals,
    double? lateFeePerDay,
    String? notes,
    int? rating,
  }) =>
      LibraryBookEntry(
        id: id ?? this.id,
        title: title ?? this.title,
        author: author ?? this.author,
        genre: genre ?? this.genre,
        isbn: isbn ?? this.isbn,
        libraryName: libraryName ?? this.libraryName,
        libraryCardNumber: libraryCardNumber ?? this.libraryCardNumber,
        borrowDate: borrowDate ?? this.borrowDate,
        dueDate: dueDate ?? this.dueDate,
        returnDate: returnDate ?? this.returnDate,
        status: status ?? this.status,
        renewalCount: renewalCount ?? this.renewalCount,
        maxRenewals: maxRenewals ?? this.maxRenewals,
        lateFeePerDay: lateFeePerDay ?? this.lateFeePerDay,
        notes: notes ?? this.notes,
        rating: rating ?? this.rating,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'genre': genre.name,
        'isbn': isbn,
        'libraryName': libraryName,
        'libraryCardNumber': libraryCardNumber,
        'borrowDate': borrowDate.toIso8601String(),
        'dueDate': dueDate.toIso8601String(),
        'returnDate': returnDate?.toIso8601String(),
        'status': status.name,
        'renewalCount': renewalCount,
        'maxRenewals': maxRenewals,
        'lateFeePerDay': lateFeePerDay,
        'notes': notes,
        'rating': rating,
      };

  factory LibraryBookEntry.fromJson(Map<String, dynamic> json) =>
      LibraryBookEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        author: json['author'] as String?,
        genre: BookGenre.values.firstWhere(
          (v) => v.name == json['genre'],
          orElse: () => BookGenre.other,
        ),
        isbn: json['isbn'] as String?,
        libraryName: json['libraryName'] as String,
        libraryCardNumber: json['libraryCardNumber'] as String?,
        borrowDate: AppDateUtils.safeParse(json['borrowDate'] as String?),
        dueDate: AppDateUtils.safeParse(json['dueDate'] as String?),
        returnDate:
            AppDateUtils.safeParseNullable(json['returnDate'] as String?),
        status: LibraryBookStatus.values.firstWhere(
          (v) => v.name == json['status'],
          orElse: () => LibraryBookStatus.borrowed,
        ),
        renewalCount: json['renewalCount'] as int? ?? 0,
        maxRenewals: json['maxRenewals'] as int? ?? 3,
        lateFeePerDay: (json['lateFeePerDay'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        rating: json['rating'] as int?,
      );

  @override
  String toString() => 'LibraryBookEntry($title, ${daysRemaining}d remaining)';
}
