/// Model classes for the Travel Log feature.

/// Type of trip.
enum TripType {
  leisure('Leisure', '🏖️'),
  business('Business', '💼'),
  adventure('Adventure', '🏔️'),
  roadTrip('Road Trip', '🚗'),
  weekend('Weekend Getaway', '🌅'),
  family('Family Visit', '👨‍👩‍👧‍👦'),
  solo('Solo Travel', '🎒'),
  cultural('Cultural', '🏛️');

  final String label;
  final String emoji;
  const TripType(this.label, this.emoji);
}

/// Primary transport mode used for the trip.
enum TripTransport {
  flight('Flight', '✈️'),
  car('Car', '🚗'),
  train('Train', '🚆'),
  bus('Bus', '🚌'),
  cruise('Cruise', '🚢'),
  bike('Bike', '🚲'),
  mixed('Mixed', '🔀');

  final String label;
  final String emoji;
  const TripTransport(this.label, this.emoji);
}

/// Trip rating.
enum TripRating {
  amazing(5, 'Amazing', '🤩'),
  great(4, 'Great', '😄'),
  good(3, 'Good', '🙂'),
  okay(2, 'Okay', '😐'),
  disappointing(1, 'Disappointing', '😕');

  final int value;
  final String label;
  final String emoji;
  const TripRating(this.value, this.label, this.emoji);
}

/// A single travel log entry.
class TravelEntry {
  final String id;
  final String destination;
  final String? country;
  final DateTime startDate;
  final DateTime endDate;
  final TripType type;
  final TripTransport transport;
  final TripRating? rating;
  final double? totalCost;
  final String? currency;
  final List<String> highlights;
  final String? notes;
  final bool isCompleted;

  const TravelEntry({
    required this.id,
    required this.destination,
    this.country,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.transport,
    this.rating,
    this.totalCost,
    this.currency,
    this.highlights = const [],
    this.notes,
    this.isCompleted = true,
  });

  /// Trip duration in days.
  int get durationDays {
    final diff = endDate.difference(startDate).inDays;
    return diff < 1 ? 1 : diff + 1;
  }

  /// Cost per day (if cost provided).
  double? get costPerDay =>
      totalCost != null ? totalCost! / durationDays : null;

  /// Whether trip is currently happening.
  bool get isOngoing {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate) && !isCompleted;
  }

  /// Whether trip is in the future.
  bool get isUpcoming =>
      startDate.isAfter(DateTime.now()) && !isCompleted;

  Map<String, dynamic> toJson() => {
        'id': id,
        'destination': destination,
        'country': country,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'type': type.name,
        'transport': transport.name,
        'rating': rating?.name,
        'totalCost': totalCost,
        'currency': currency,
        'highlights': highlights,
        'notes': notes,
        'isCompleted': isCompleted,
      };

  factory TravelEntry.fromJson(Map<String, dynamic> json) {
    return TravelEntry(
      id: json['id'] as String,
      destination: json['destination'] as String,
      country: json['country'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      type: TripType.values.firstWhere((e) => e.name == json['type'],
          orElse: () => TripType.leisure),
      transport: TripTransport.values.firstWhere(
          (e) => e.name == json['transport'],
          orElse: () => TripTransport.mixed),
      rating: json['rating'] != null
          ? TripRating.values.firstWhere((e) => e.name == json['rating'],
              orElse: () => TripRating.good)
          : null,
      totalCost: (json['totalCost'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      notes: json['notes'] as String?,
      isCompleted: json['isCompleted'] as bool? ?? true,
    );
  }

  TravelEntry copyWith({
    String? destination,
    String? country,
    DateTime? startDate,
    DateTime? endDate,
    TripType? type,
    TripTransport? transport,
    TripRating? rating,
    double? totalCost,
    String? currency,
    List<String>? highlights,
    String? notes,
    bool? isCompleted,
  }) {
    return TravelEntry(
      id: id,
      destination: destination ?? this.destination,
      country: country ?? this.country,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      type: type ?? this.type,
      transport: transport ?? this.transport,
      rating: rating ?? this.rating,
      totalCost: totalCost ?? this.totalCost,
      currency: currency ?? this.currency,
      highlights: highlights ?? this.highlights,
      notes: notes ?? this.notes,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// Travel statistics summary.
class TravelStats {
  final int totalTrips;
  final int totalDays;
  final int countriesVisited;
  final int citiesVisited;
  final double totalSpent;
  final double avgTripDuration;
  final double avgRating;
  final Map<TripType, int> typeBreakdown;
  final Map<TripTransport, int> transportBreakdown;
  final String? favoriteDestination;
  final int longestTripDays;

  const TravelStats({
    required this.totalTrips,
    required this.totalDays,
    required this.countriesVisited,
    required this.citiesVisited,
    required this.totalSpent,
    required this.avgTripDuration,
    required this.avgRating,
    required this.typeBreakdown,
    required this.transportBreakdown,
    this.favoriteDestination,
    required this.longestTripDays,
  });
}

/// Monthly travel cost summary.
class TravelMonthlyCost {
  final int year;
  final int month;
  final double total;
  final int tripCount;

  const TravelMonthlyCost({
    required this.year,
    required this.month,
    required this.total,
    required this.tripCount,
  });

  String get label => '${_monthName(month)} $year';

  static String _monthName(int m) {
    const names = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return names[m.clamp(1, 12)];
  }
}
