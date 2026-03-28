import 'dart:convert';

/// Genre categories for movies.
enum MovieGenre {
  action,
  comedy,
  drama,
  horror,
  sciFi,
  thriller,
  romance,
  animation,
  documentary,
  fantasy,
  mystery,
  other;

  String get label {
    switch (this) {
      case MovieGenre.action:
        return 'Action';
      case MovieGenre.comedy:
        return 'Comedy';
      case MovieGenre.drama:
        return 'Drama';
      case MovieGenre.horror:
        return 'Horror';
      case MovieGenre.sciFi:
        return 'Sci-Fi';
      case MovieGenre.thriller:
        return 'Thriller';
      case MovieGenre.romance:
        return 'Romance';
      case MovieGenre.animation:
        return 'Animation';
      case MovieGenre.documentary:
        return 'Documentary';
      case MovieGenre.fantasy:
        return 'Fantasy';
      case MovieGenre.mystery:
        return 'Mystery';
      case MovieGenre.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case MovieGenre.action:
        return '💥';
      case MovieGenre.comedy:
        return '😂';
      case MovieGenre.drama:
        return '🎭';
      case MovieGenre.horror:
        return '👻';
      case MovieGenre.sciFi:
        return '🚀';
      case MovieGenre.thriller:
        return '🔪';
      case MovieGenre.romance:
        return '❤️';
      case MovieGenre.animation:
        return '🎨';
      case MovieGenre.documentary:
        return '📹';
      case MovieGenre.fantasy:
        return '🧙';
      case MovieGenre.mystery:
        return '🔍';
      case MovieGenre.other:
        return '🎬';
    }
  }
}

/// Watch status for a movie.
enum WatchStatus {
  watched,
  watchlist,
  watching;

  String get label {
    switch (this) {
      case WatchStatus.watched:
        return 'Watched';
      case WatchStatus.watchlist:
        return 'Watchlist';
      case WatchStatus.watching:
        return 'Watching';
    }
  }

  String get emoji {
    switch (this) {
      case WatchStatus.watched:
        return '✅';
      case WatchStatus.watchlist:
        return '📋';
      case WatchStatus.watching:
        return '▶️';
    }
  }
}

/// A single movie log entry.
class MovieEntry {
  final String id;
  final String title;
  final MovieGenre genre;
  final WatchStatus status;
  final double rating; // 0-5 stars, 0.5 increments
  final DateTime dateAdded;
  final DateTime? dateWatched;
  final String? director;
  final int? year;
  final String? note;
  final bool favorite;

  const MovieEntry({
    required this.id,
    required this.title,
    required this.genre,
    required this.status,
    this.rating = 0,
    required this.dateAdded,
    this.dateWatched,
    this.director,
    this.year,
    this.note,
    this.favorite = false,
  });

  MovieEntry copyWith({
    String? id,
    String? title,
    MovieGenre? genre,
    WatchStatus? status,
    double? rating,
    DateTime? dateAdded,
    DateTime? dateWatched,
    String? director,
    int? year,
    String? note,
    bool? favorite,
  }) {
    return MovieEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      dateAdded: dateAdded ?? this.dateAdded,
      dateWatched: dateWatched ?? this.dateWatched,
      director: director ?? this.director,
      year: year ?? this.year,
      note: note ?? this.note,
      favorite: favorite ?? this.favorite,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'genre': genre.name,
      'status': status.name,
      'rating': rating,
      'dateAdded': dateAdded.toIso8601String(),
      'dateWatched': dateWatched?.toIso8601String(),
      'director': director,
      'year': year,
      'note': note,
      'favorite': favorite,
    };
  }

  factory MovieEntry.fromJson(Map<String, dynamic> json) {
    return MovieEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      genre: MovieGenre.values.firstWhere(
        (g) => g.name == json['genre'],
        orElse: () => MovieGenre.other,
      ),
      status: WatchStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => WatchStatus.watchlist,
      ),
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      dateAdded:
          DateTime.tryParse(json['dateAdded'] as String? ?? '') ?? DateTime.now(),
      dateWatched: json['dateWatched'] != null
          ? DateTime.tryParse(json['dateWatched'] as String)
          : null,
      director: json['director'] as String?,
      year: json['year'] as int?,
      note: json['note'] as String?,
      favorite: json['favorite'] as bool? ?? false,
    );
  }

  static String encodeList(List<MovieEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<MovieEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => MovieEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
