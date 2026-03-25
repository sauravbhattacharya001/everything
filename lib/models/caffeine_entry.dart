import 'dart:convert';
import 'dart:math' show pow;

/// Source of caffeine with typical mg per serving.
enum CaffeineSource {
  espresso,
  drip,
  latte,
  coldBrew,
  greenTea,
  blackTea,
  matcha,
  energyDrink,
  soda,
  preworkout,
  chocolate,
  custom;

  String get label {
    switch (this) {
      case CaffeineSource.espresso:
        return 'Espresso';
      case CaffeineSource.drip:
        return 'Drip Coffee';
      case CaffeineSource.latte:
        return 'Latte';
      case CaffeineSource.coldBrew:
        return 'Cold Brew';
      case CaffeineSource.greenTea:
        return 'Green Tea';
      case CaffeineSource.blackTea:
        return 'Black Tea';
      case CaffeineSource.matcha:
        return 'Matcha';
      case CaffeineSource.energyDrink:
        return 'Energy Drink';
      case CaffeineSource.soda:
        return 'Soda';
      case CaffeineSource.preworkout:
        return 'Pre-Workout';
      case CaffeineSource.chocolate:
        return 'Chocolate';
      case CaffeineSource.custom:
        return 'Custom';
    }
  }

  String get emoji {
    switch (this) {
      case CaffeineSource.espresso:
        return '☕';
      case CaffeineSource.drip:
        return '☕';
      case CaffeineSource.latte:
        return '🥛';
      case CaffeineSource.coldBrew:
        return '🧊';
      case CaffeineSource.greenTea:
        return '🍵';
      case CaffeineSource.blackTea:
        return '🫖';
      case CaffeineSource.matcha:
        return '🍃';
      case CaffeineSource.energyDrink:
        return '⚡';
      case CaffeineSource.soda:
        return '🥤';
      case CaffeineSource.preworkout:
        return '💪';
      case CaffeineSource.chocolate:
        return '🍫';
      case CaffeineSource.custom:
        return '🔧';
    }
  }

  /// Typical caffeine content in mg per serving.
  int get defaultMg {
    switch (this) {
      case CaffeineSource.espresso:
        return 63;
      case CaffeineSource.drip:
        return 95;
      case CaffeineSource.latte:
        return 63;
      case CaffeineSource.coldBrew:
        return 200;
      case CaffeineSource.greenTea:
        return 28;
      case CaffeineSource.blackTea:
        return 47;
      case CaffeineSource.matcha:
        return 70;
      case CaffeineSource.energyDrink:
        return 160;
      case CaffeineSource.soda:
        return 34;
      case CaffeineSource.preworkout:
        return 200;
      case CaffeineSource.chocolate:
        return 12;
      case CaffeineSource.custom:
        return 50;
    }
  }
}

/// A single caffeine intake entry.
class CaffeineEntry {
  final String id;
  final DateTime timestamp;
  final int caffeineMg;
  final CaffeineSource source;
  final String? note;

  const CaffeineEntry({
    required this.id,
    required this.timestamp,
    required this.caffeineMg,
    this.source = CaffeineSource.drip,
    this.note,
  });

  /// Caffeine half-life is ~5 hours. Returns remaining mg at [atTime].
  double remainingMgAt(DateTime atTime) {
    final hours = atTime.difference(timestamp).inMinutes / 60.0;
    if (hours < 0) return caffeineMg.toDouble();
    const halfLifeHours = 5.0;
    return caffeineMg * pow(0.5, hours / halfLifeHours);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'caffeineMg': caffeineMg,
        'source': source.name,
        'note': note,
      };

  factory CaffeineEntry.fromJson(Map<String, dynamic> json) {
    return CaffeineEntry(
      id: json['id'] as String,
      timestamp:
          DateTime.tryParse(json['timestamp'] as String? ?? '') ?? DateTime.now(),
      caffeineMg: json['caffeineMg'] as int? ?? 0,
      source: CaffeineSource.values.firstWhere(
        (v) => v.name == json['source'],
        orElse: () => CaffeineSource.custom,
      ),
      note: json['note'] as String?,
    );
  }

  static String encodeList(List<CaffeineEntry> entries) {
    return jsonEncode(entries.map((e) => e.toJson()).toList());
  }

  static List<CaffeineEntry> decodeList(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    return list
        .map((e) => CaffeineEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
