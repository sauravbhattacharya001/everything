import '../../models/travel_entry.dart';

/// Service for computing travel log statistics and insights.
class TravelLogService {
  const TravelLogService();

  /// Compute aggregate travel statistics.
  TravelStats computeStats(List<TravelEntry> entries) {
    if (entries.isEmpty) {
      return const TravelStats(
        totalTrips: 0,
        totalDays: 0,
        countriesVisited: 0,
        citiesVisited: 0,
        totalSpent: 0,
        avgTripDuration: 0,
        avgRating: 0,
        typeBreakdown: {},
        transportBreakdown: {},
        longestTripDays: 0,
      );
    }

    final completed = entries.where((e) => e.isCompleted).toList();
    int totalDays = 0;
    double totalCost = 0;
    double ratingSum = 0;
    int ratedCount = 0;
    int longestTrip = 0;
    final countries = <String>{};
    final cities = <String>{};
    final typeMap = <TripType, int>{};
    final transportMap = <TripTransport, int>{};
    final destCount = <String, int>{};

    for (final e in completed) {
      totalDays += e.durationDays;
      totalCost += e.totalCost ?? 0;
      if (e.rating != null) {
        ratingSum += e.rating!.value;
        ratedCount++;
      }
      if (e.durationDays > longestTrip) longestTrip = e.durationDays;
      if (e.country != null && e.country!.isNotEmpty) {
        countries.add(e.country!);
      }
      cities.add(e.destination);
      typeMap[e.type] = (typeMap[e.type] ?? 0) + 1;
      transportMap[e.transport] = (transportMap[e.transport] ?? 0) + 1;
      destCount[e.destination] = (destCount[e.destination] ?? 0) + 1;
    }

    String? favDest;
    int favCount = 0;
    for (final entry in destCount.entries) {
      if (entry.value > favCount) {
        favCount = entry.value;
        favDest = entry.key;
      }
    }

    return TravelStats(
      totalTrips: completed.length,
      totalDays: totalDays,
      countriesVisited: countries.length,
      citiesVisited: cities.length,
      totalSpent: totalCost,
      avgTripDuration:
          completed.isEmpty ? 0 : totalDays / completed.length,
      avgRating: ratedCount == 0 ? 0 : ratingSum / ratedCount,
      typeBreakdown: typeMap,
      transportBreakdown: transportMap,
      favoriteDestination: favDest,
      longestTripDays: longestTrip,
    );
  }

  /// Get monthly cost breakdown.
  List<TravelMonthlyCost> getMonthlyCosts(List<TravelEntry> entries) {
    final completed =
        entries.where((e) => e.isCompleted && e.totalCost != null).toList();
    final monthMap = <String, _MonthAccum>{};

    for (final e in completed) {
      final key = '${e.startDate.year}-${e.startDate.month}';
      final accum = monthMap.putIfAbsent(
        key,
        () => _MonthAccum(e.startDate.year, e.startDate.month),
      );
      accum.total += e.totalCost!;
      accum.count++;
    }

    final result = monthMap.values
        .map((a) => TravelMonthlyCost(
              year: a.year,
              month: a.month,
              total: a.total,
              tripCount: a.count,
            ))
        .toList()
      ..sort((a, b) {
        final y = a.year.compareTo(b.year);
        return y != 0 ? y : a.month.compareTo(b.month);
      });
    return result;
  }

  /// Get upcoming trips sorted by start date.
  List<TravelEntry> getUpcoming(List<TravelEntry> entries) {
    final now = DateTime.now();
    return entries
        .where((e) => e.startDate.isAfter(now) && !e.isCompleted)
        .toList()
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
  }

  /// Get trips filtered by year.
  List<TravelEntry> getByYear(List<TravelEntry> entries, int year) {
    return entries
        .where((e) => e.startDate.year == year)
        .toList()
      ..sort((a, b) => b.startDate.compareTo(a.startDate));
  }

  /// Get unique years from entries.
  List<int> getYears(List<TravelEntry> entries) {
    final years = entries.map((e) => e.startDate.year).toSet().toList()
      ..sort((a, b) => b.compareTo(a));
    return years;
  }

  /// Generate travel insights.
  List<TravelInsight> generateInsights(List<TravelEntry> entries) {
    final insights = <TravelInsight>[];
    final stats = computeStats(entries);

    if (stats.totalTrips == 0) return insights;

    insights.add(TravelInsight(
      title: 'Total Travel',
      value: '${stats.totalDays} days across ${stats.totalTrips} trips',
      emoji: '🌍',
    ));

    if (stats.countriesVisited > 0) {
      insights.add(TravelInsight(
        title: 'Countries',
        value: '${stats.countriesVisited} countries explored',
        emoji: '🗺️',
      ));
    }

    if (stats.avgRating > 0) {
      insights.add(TravelInsight(
        title: 'Avg Rating',
        value: '${stats.avgRating.toStringAsFixed(1)} / 5.0',
        emoji: '⭐',
      ));
    }

    if (stats.totalSpent > 0) {
      final avg = stats.totalSpent / stats.totalTrips;
      insights.add(TravelInsight(
        title: 'Avg Trip Cost',
        value: '\$${avg.toStringAsFixed(0)}',
        emoji: '💰',
      ));
    }

    if (stats.longestTripDays > 1) {
      insights.add(TravelInsight(
        title: 'Longest Trip',
        value: '${stats.longestTripDays} days',
        emoji: '📅',
      ));
    }

    if (stats.favoriteDestination != null) {
      insights.add(TravelInsight(
        title: 'Most Visited',
        value: stats.favoriteDestination!,
        emoji: '📍',
      ));
    }

    // Best-rated transport
    if (stats.transportBreakdown.isNotEmpty) {
      final topTransport = stats.transportBreakdown.entries
          .reduce((a, b) => a.value >= b.value ? a : b);
      insights.add(TravelInsight(
        title: 'Preferred Transport',
        value: topTransport.key.label,
        emoji: topTransport.key.emoji,
      ));
    }

    return insights;
  }
}

class _MonthAccum {
  final int year;
  final int month;
  double total = 0;
  int count = 0;
  _MonthAccum(this.year, this.month);
}

/// A single travel insight.
class TravelInsight {
  final String title;
  final String value;
  final String emoji;

  const TravelInsight({
    required this.title,
    required this.value,
    required this.emoji,
  });
}
