import 'package:flutter/material.dart';

/// Genre categories for movies and TV shows.
enum WatchlistGenre {
  action('Action', '💥'),
  comedy('Comedy', '😂'),
  drama('Drama', '🎭'),
  horror('Horror', '👻'),
  scifi('Sci-Fi', '🚀'),
  fantasy('Fantasy', '🧙'),
  thriller('Thriller', '😰'),
  romance('Romance', '💕'),
  documentary('Documentary', '📹'),
  animation('Animation', '🎨'),
  mystery('Mystery', '🔍'),
  crime('Crime', '🔫'),
  family('Family', '👨‍👩‍👧‍👦'),
  musical('Musical', '🎵'),
  western('Western', '🤠'),
  war('War', '⚔️'),
  biography('Biography', '📖'),
  sport('Sport', '🏆'),
  other('Other', '🎬');

  final String label;
  final String emoji;
  const WatchlistGenre(this.label, this.emoji);
}

/// Type of media.
enum WatchlistMediaType {
  movie('Movie', Icons.movie_outlined),
  tvShow('TV Show', Icons.tv_outlined),
  miniseries('Miniseries', Icons.view_list_outlined),
  documentary('Documentary', Icons.videocam_outlined),
  anime('Anime', Icons.animation_outlined);

  final String label;
  final IconData icon;
  const WatchlistMediaType(this.label, this.icon);
}

/// Watch status.
enum WatchStatus {
  planToWatch(0, 'Plan to Watch', '📋', Colors.blue),
  watching(1, 'Watching', '▶️', Colors.green),
  completed(2, 'Completed', '✅', Colors.teal),
  onHold(3, 'On Hold', '⏸️', Colors.orange),
  dropped(4, 'Dropped', '❌', Colors.red);

  final int value;
  final String label;
  final String emoji;
  final Color color;
  const WatchStatus(this.value, this.label, this.emoji, this.color);
}

/// A single watchlist entry.
class WatchlistItem {
  final String id;
  final String title;
  final WatchlistMediaType mediaType;
  final List<WatchlistGenre> genres;
  final WatchStatus status;
  final double rating; // 0-10, 0 = unrated
  final int? year;
  final int? totalEpisodes;
  final int episodesWatched;
  final String? director;
  final String? platform; // where to watch
  final String? notes;
  final DateTime addedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final bool isFavorite;
  final String? imageUrl;

  const WatchlistItem({
    required this.id,
    required this.title,
    required this.mediaType,
    this.genres = const [],
    required this.status,
    this.rating = 0,
    this.year,
    this.totalEpisodes,
    this.episodesWatched = 0,
    this.director,
    this.platform,
    this.notes,
    required this.addedAt,
    this.startedAt,
    this.completedAt,
    this.isFavorite = false,
    this.imageUrl,
  });

  /// Progress percentage for TV shows.
  double get progress {
    if (totalEpisodes == null || totalEpisodes == 0) return 0;
    return (episodesWatched / totalEpisodes!).clamp(0.0, 1.0);
  }

  /// Days since added.
  int get daysOnList => DateTime.now().difference(addedAt).inDays;

  WatchlistItem copyWith({
    String? id,
    String? title,
    WatchlistMediaType? mediaType,
    List<WatchlistGenre>? genres,
    WatchStatus? status,
    double? rating,
    int? year,
    int? totalEpisodes,
    int? episodesWatched,
    String? director,
    String? platform,
    String? notes,
    DateTime? addedAt,
    DateTime? startedAt,
    DateTime? completedAt,
    bool? isFavorite,
    String? imageUrl,
  }) =>
      WatchlistItem(
        id: id ?? this.id,
        title: title ?? this.title,
        mediaType: mediaType ?? this.mediaType,
        genres: genres ?? this.genres,
        status: status ?? this.status,
        rating: rating ?? this.rating,
        year: year ?? this.year,
        totalEpisodes: totalEpisodes ?? this.totalEpisodes,
        episodesWatched: episodesWatched ?? this.episodesWatched,
        director: director ?? this.director,
        platform: platform ?? this.platform,
        notes: notes ?? this.notes,
        addedAt: addedAt ?? this.addedAt,
        startedAt: startedAt ?? this.startedAt,
        completedAt: completedAt ?? this.completedAt,
        isFavorite: isFavorite ?? this.isFavorite,
        imageUrl: imageUrl ?? this.imageUrl,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'mediaType': mediaType.name,
        'genres': genres.map((g) => g.name).toList(),
        'status': status.name,
        'rating': rating,
        if (year != null) 'year': year,
        if (totalEpisodes != null) 'totalEpisodes': totalEpisodes,
        'episodesWatched': episodesWatched,
        if (director != null) 'director': director,
        if (platform != null) 'platform': platform,
        if (notes != null) 'notes': notes,
        'addedAt': addedAt.toIso8601String(),
        if (startedAt != null) 'startedAt': startedAt!.toIso8601String(),
        if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
        'isFavorite': isFavorite,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

  factory WatchlistItem.fromJson(Map<String, dynamic> json) => WatchlistItem(
        id: json['id'] as String,
        title: json['title'] as String,
        mediaType:
            WatchlistMediaType.values.byName(json['mediaType'] as String),
        genres: (json['genres'] as List<dynamic>?)
                ?.map((g) => WatchlistGenre.values.byName(g as String))
                .toList() ??
            const [],
        status: WatchStatus.values.byName(json['status'] as String),
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        year: json['year'] as int?,
        totalEpisodes: json['totalEpisodes'] as int?,
        episodesWatched: json['episodesWatched'] as int? ?? 0,
        director: json['director'] as String?,
        platform: json['platform'] as String?,
        notes: json['notes'] as String?,
        addedAt: DateTime.parse(json['addedAt'] as String),
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        isFavorite: json['isFavorite'] as bool? ?? false,
        imageUrl: json['imageUrl'] as String?,
      );
}
