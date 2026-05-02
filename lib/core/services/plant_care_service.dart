import 'dart:convert';
import '../../models/plant_entry.dart';

/// Summary of a single plant's care status.
class PlantCareSummary {
  final PlantProfile plant;
  final DateTime? lastWatered;
  final DateTime? nextWatering;
  final int totalCareActions;
  final PlantHealth? lastHealth;
  final bool isOverdue;
  final int overdueDays;
  final Map<PlantCareAction, int> actionCounts;
  final int careStreak;

  const PlantCareSummary({
    required this.plant,
    this.lastWatered,
    this.nextWatering,
    required this.totalCareActions,
    this.lastHealth,
    required this.isOverdue,
    required this.overdueDays,
    required this.actionCounts,
    required this.careStreak,
  });
}

/// Fleet-level garden summary.
class GardenSummary {
  final int totalPlants;
  final int activePlants;
  final int archivedPlants;
  final int overduePlants;
  final int healthyPlants;
  final int needsAttention;
  final int totalCareActions;
  final Map<PlantType, int> byType;
  final Map<SunlightLevel, int> bySunlight;
  final Map<String, int> byLocation;
  final double overallHealthScore;
  final int careStreak;

  const GardenSummary({
    required this.totalPlants,
    required this.activePlants,
    required this.archivedPlants,
    required this.overduePlants,
    required this.healthyPlants,
    required this.needsAttention,
    required this.totalCareActions,
    required this.byType,
    required this.bySunlight,
    required this.byLocation,
    required this.overallHealthScore,
    required this.careStreak,
  });

  String get healthGrade {
    if (overallHealthScore >= 90) return 'A';
    if (overallHealthScore >= 75) return 'B';
    if (overallHealthScore >= 60) return 'C';
    if (overallHealthScore >= 40) return 'D';
    return 'F';
  }
}

/// Plant care tracker service — manages plant profiles, care logs,
/// watering schedules, health tracking, and garden insights.
class PlantCareService {
  final List<PlantProfile> _plants = [];
  final List<PlantCareEntry> _careLog = [];
  int _nextId = 1;

  List<PlantProfile> get plants => List.unmodifiable(_plants);
  List<PlantProfile> get activePlants =>
      _plants.where((p) => !p.isArchived).toList();
  List<PlantProfile> get archivedPlants =>
      _plants.where((p) => p.isArchived).toList();
  List<PlantCareEntry> get careLog => List.unmodifiable(_careLog);

  String _generateId() => 'plant_${_nextId++}';
  String _generateCareId() => 'care_${_nextId++}';

  // ─── Plant Management ───

  /// Registers a new plant in the garden.
  ///
  /// Creates a [PlantProfile] with an auto-generated id and adds it to the
  /// collection. If [wateringIntervalDays] is omitted, the default interval
  /// for the given [type] is used. Returns the newly created profile.
  PlantProfile addPlant({
    required String name,
    required PlantType type,
    SunlightLevel sunlight = SunlightLevel.indirect,
    String location = '',
    int? wateringIntervalDays,
    String? notes,
    DateTime? dateAdded,
  }) {
    final plant = PlantProfile(
      id: _generateId(),
      name: name.trim(),
      type: type,
      sunlight: sunlight,
      location: location.trim(),
      wateringIntervalDays: wateringIntervalDays ?? type.defaultWateringDays,
      dateAdded: dateAdded ?? DateTime.now(),
      notes: notes,
    );
    _plants.add(plant);
    return plant;
  }

  /// Returns the [PlantProfile] with the given [id], or `null` if not found.
  PlantProfile? getPlant(String id) {
    try {
      return _plants.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Applies partial updates to an existing plant profile.
  ///
  /// Only non-null parameters are changed. Returns the updated profile,
  /// or `null` if no plant with [id] exists.
  PlantProfile? updatePlant(String id, {
    String? name,
    PlantType? type,
    SunlightLevel? sunlight,
    String? location,
    int? wateringIntervalDays,
    String? notes,
    bool? isArchived,
  }) {
    final idx = _plants.indexWhere((p) => p.id == id);
    if (idx == -1) return null;
    _plants[idx] = _plants[idx].copyWith(
      name: name,
      type: type,
      sunlight: sunlight,
      location: location,
      wateringIntervalDays: wateringIntervalDays,
      notes: notes,
      isArchived: isArchived,
    );
    return _plants[idx];
  }

  /// Permanently removes a plant and all of its care log entries.
  ///
  /// Returns `true` if a plant was actually removed.
  bool removePlant(String id) {
    final before = _plants.length;
    _plants.removeWhere((p) => p.id == id);
    _careLog.removeWhere((e) => e.plantId == id);
    return _plants.length < before;
  }

  // ─── Care Logging ───

  /// Records a care action (watering, fertilizing, pruning, etc.) for a plant.
  ///
  /// If [timestamp] is omitted it defaults to now. An optional
  /// [healthObserved] snapshot can be attached to track the plant's
  /// condition at the time of care.
  PlantCareEntry logCare({
    required String plantId,
    required PlantCareAction action,
    DateTime? timestamp,
    PlantHealth? healthObserved,
    String? notes,
  }) {
    final entry = PlantCareEntry(
      id: _generateCareId(),
      plantId: plantId,
      action: action,
      timestamp: timestamp ?? DateTime.now(),
      healthObserved: healthObserved,
      notes: notes,
    );
    _careLog.add(entry);
    return entry;
  }

  /// Returns care entries for [plantId], most-recent first.
  ///
  /// When [limit] is provided only the latest *n* entries are returned.
  List<PlantCareEntry> getCareLog(String plantId, {int? limit}) {
    var entries = _careLog.where((e) => e.plantId == plantId).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (limit != null) entries = entries.take(limit).toList();
    return entries;
  }

  /// Deletes a single care log entry by its id.
  ///
  /// Returns `true` if the entry existed and was removed.
  bool removeCareEntry(String entryId) {
    final len = _careLog.length;
    _careLog.removeWhere((e) => e.id == entryId);
    return _careLog.length < len;
  }

  // ─── Watering Schedule ───

  /// Returns the timestamp of the most recent watering for [plantId],
  /// or `null` if the plant has never been watered.
  DateTime? getLastWatered(String plantId) {
    final waterings = _careLog
        .where((e) => e.plantId == plantId && e.action == PlantCareAction.watering)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return waterings.isNotEmpty ? waterings.first.timestamp : null;
  }

  /// Computes the next expected watering date based on the plant's
  /// watering interval and its last watering timestamp.
  ///
  /// Returns `null` if the plant doesn't exist. If the plant has never
  /// been watered, returns [DateTime.now] (i.e. already overdue).
  DateTime? getNextWatering(String plantId) {
    final plant = getPlant(plantId);
    if (plant == null) return null;
    final lastWatered = getLastWatered(plantId);
    if (lastWatered == null) return DateTime.now(); // overdue
    return lastWatered.add(Duration(days: plant.wateringIntervalDays));
  }

  /// Whether the plant's next watering date has already passed.
  bool isOverdue(String plantId, {DateTime? now}) {
    final next = getNextWatering(plantId);
    if (next == null) return false;
    return (now ?? DateTime.now()).isAfter(next);
  }

  /// Number of full days past the next watering date, or 0 if not overdue.
  int overdueDays(String plantId, {DateTime? now}) {
    final next = getNextWatering(plantId);
    if (next == null) return 0;
    final diff = (now ?? DateTime.now()).difference(next).inDays;
    return diff > 0 ? diff : 0;
  }

  /// Returns all active plants whose watering schedule is overdue.
  List<PlantProfile> getOverduePlants({DateTime? now}) {
    return activePlants.where((p) => isOverdue(p.id, now: now)).toList();
  }

  /// Returns active plants whose next watering falls within [withinDays]
  /// (inclusive), including those already overdue.
  List<PlantProfile> getPlantsNeedingWaterSoon({int withinDays = 2, DateTime? now}) {
    final ref = now ?? DateTime.now();
    return activePlants.where((p) {
      final next = getNextWatering(p.id);
      if (next == null) return true;
      return next.difference(ref).inDays <= withinDays;
    }).toList();
  }

  // ─── Health Tracking ───

  /// Returns the most recently observed [PlantHealth] for [plantId],
  /// or `null` if no health observations have been recorded.
  PlantHealth? getLastHealth(String plantId) {
    final entries = _careLog
        .where((e) => e.plantId == plantId && e.healthObserved != null)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries.isNotEmpty ? entries.first.healthObserved : null;
  }

  /// Returns the health observation timeline for [plantId], most-recent
  /// first, optionally capped at [limit] entries.
  List<PlantHealth> getHealthHistory(String plantId, {int? limit}) {
    var entries = _careLog
        .where((e) => e.plantId == plantId && e.healthObserved != null)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (limit != null) entries = entries.take(limit).toList();
    return entries.map((e) => e.healthObserved!).toList();
  }

  // ─── Streaks ───

  /// Calculates the current consecutive-day care streak for a single plant.
  ///
  /// A streak counts backward from today (or [now]) — each day with at
  /// least one care entry extends the streak by one.
  int getCareStreak(String plantId, {DateTime? now}) {
    final ref = now ?? DateTime.now();
    final entries = _careLog
        .where((e) => e.plantId == plantId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (entries.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime(ref.year, ref.month, ref.day);
    final entryDates = entries
        .map((e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    for (final date in entryDates) {
      if (date == checkDate || date == checkDate.subtract(const Duration(days: 1))) {
        streak++;
        checkDate = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  /// Calculates the consecutive-day care streak across the entire garden.
  ///
  /// Any care action on any plant counts toward the streak.
  int getGardenCareStreak({DateTime? now}) {
    final ref = now ?? DateTime.now();
    if (_careLog.isEmpty) return 0;

    int streak = 0;
    DateTime checkDate = DateTime(ref.year, ref.month, ref.day);
    final entryDates = _careLog
        .map((e) => DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day))
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));

    for (final date in entryDates) {
      if (date == checkDate || date == checkDate.subtract(const Duration(days: 1))) {
        streak++;
        checkDate = date.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  // ─── Per-Plant Summary ───

  /// Builds a comprehensive [PlantCareSummary] for one plant, aggregating
  /// watering schedule, health status, care action counts, and streak data.
  ///
  /// Throws [ArgumentError] if [plantId] doesn't exist.
  PlantCareSummary getPlantSummary(String plantId, {DateTime? now}) {
    final plant = getPlant(plantId);
    if (plant == null) throw ArgumentError('Plant not found: $plantId');
    final entries = _careLog.where((e) => e.plantId == plantId).toList();
    final actionCounts = <PlantCareAction, int>{};
    for (final e in entries) {
      actionCounts[e.action] = (actionCounts[e.action] ?? 0) + 1;
    }
    return PlantCareSummary(
      plant: plant,
      lastWatered: getLastWatered(plantId),
      nextWatering: getNextWatering(plantId),
      totalCareActions: entries.length,
      lastHealth: getLastHealth(plantId),
      isOverdue: isOverdue(plantId, now: now),
      overdueDays: overdueDays(plantId, now: now),
      actionCounts: actionCounts,
      careStreak: getCareStreak(plantId, now: now),
    );
  }

  // ─── Garden Summary ───

  /// Produces a fleet-level [GardenSummary] covering all active plants:
  /// overdue counts, health distribution, type/sunlight/location breakdowns,
  /// and an overall health score (0–100).
  GardenSummary getGardenSummary({DateTime? now}) {
    final active = activePlants;
    final overdue = getOverduePlants(now: now);
    final byType = <PlantType, int>{};
    final bySunlight = <SunlightLevel, int>{};
    final byLocation = <String, int>{};

    int healthyCount = 0;
    int needsAttentionCount = 0;
    double healthSum = 0;

    for (final p in active) {
      byType[p.type] = (byType[p.type] ?? 0) + 1;
      bySunlight[p.sunlight] = (bySunlight[p.sunlight] ?? 0) + 1;
      if (p.location.isNotEmpty) {
        byLocation[p.location] = (byLocation[p.location] ?? 0) + 1;
      }
      final health = getLastHealth(p.id);
      if (health != null) {
        final score = _healthToScore(health);
        healthSum += score;
        if (score >= 70) {
          healthyCount++;
        } else {
          needsAttentionCount++;
        }
      } else {
        healthSum += 50; // unknown = fair
      }
    }

    return GardenSummary(
      totalPlants: _plants.length,
      activePlants: active.length,
      archivedPlants: archivedPlants.length,
      overduePlants: overdue.length,
      healthyPlants: healthyCount,
      needsAttention: needsAttentionCount,
      totalCareActions: _careLog.length,
      byType: byType,
      bySunlight: bySunlight,
      byLocation: byLocation,
      overallHealthScore: active.isNotEmpty ? healthSum / active.length : 0,
      careStreak: getGardenCareStreak(now: now),
    );
  }

  double _healthToScore(PlantHealth health) {
    switch (health) {
      case PlantHealth.thriving: return 100;
      case PlantHealth.healthy: return 80;
      case PlantHealth.fair: return 60;
      case PlantHealth.struggling: return 35;
      case PlantHealth.critical: return 10;
    }
  }

  // ─── Recommendations ───

  /// Generates actionable care tips based on current garden state.
  ///
  /// Covers overdue waterings, upcoming watering needs, struggling plants,
  /// and nudges for empty care logs.
  List<String> getRecommendations({DateTime? now}) {
    final tips = <String>[];
    final overdue = getOverduePlants(now: now);
    if (overdue.isNotEmpty) {
      tips.add('💧 ${overdue.length} plant(s) overdue for watering: ${overdue.map((p) => p.name).join(", ")}');
    }
    final upcoming = getPlantsNeedingWaterSoon(withinDays: 1, now: now);
    final upcomingNotOverdue = upcoming.where((p) => !overdue.contains(p)).toList();
    if (upcomingNotOverdue.isNotEmpty) {
      tips.add('📅 Water soon: ${upcomingNotOverdue.map((p) => p.name).join(", ")}');
    }
    for (final p in activePlants) {
      final health = getLastHealth(p.id);
      if (health == PlantHealth.struggling || health == PlantHealth.critical) {
        tips.add('⚠️ ${p.name} is ${health!.label.toLowerCase()} — consider checking light, soil, and drainage');
      }
    }
    if (_careLog.isEmpty && _plants.isNotEmpty) {
      tips.add('🌱 Start logging care actions to track your garden health!');
    }
    return tips;
  }

  // ─── Serialization ───

  /// Serializes all plants, care entries, and the id counter to a JSON map.
  Map<String, dynamic> toJson() => {
        'plants': _plants.map((p) => p.toJson()).toList(),
        'careLog': _careLog.map((e) => e.toJson()).toList(),
        'nextId': _nextId,
      };

  /// Replaces the current state with data deserialized from [json].
  ///
  /// Clears existing plants and care log before importing.
  void loadFromJson(Map<String, dynamic> json) {
    _plants.clear();
    _careLog.clear();
    if (json['plants'] != null) {
      for (final p in json['plants'] as List) {
        _plants.add(PlantProfile.fromJson(p as Map<String, dynamic>));
      }
    }
    if (json['careLog'] != null) {
      for (final e in json['careLog'] as List) {
        _careLog.add(PlantCareEntry.fromJson(e as Map<String, dynamic>));
      }
    }
    _nextId = json['nextId'] as int? ?? (_plants.length + _careLog.length + 1);
  }

  /// Export all data as JSON string.
  String export() => jsonEncode(toJson());

  /// Import data from JSON string (replaces current data).
  void import(String jsonStr) {
    final data = jsonDecode(jsonStr) as Map<String, dynamic>;
    loadFromJson(data);
  }
}
