/// Model classes for the Sun & Moon Tracker feature.

/// Moon phase names.
enum MoonPhase {
  newMoon('New Moon', '🌑'),
  waxingCrescent('Waxing Crescent', '🌒'),
  firstQuarter('First Quarter', '🌓'),
  waxingGibbous('Waxing Gibbous', '🌔'),
  fullMoon('Full Moon', '🌕'),
  waningGibbous('Waning Gibbous', '🌖'),
  lastQuarter('Last Quarter', '🌗'),
  waningCrescent('Waning Crescent', '🌘');

  final String label;
  final String emoji;
  const MoonPhase(this.label, this.emoji);
}

/// Sun & moon data for a specific date and location.
class SunMoonData {
  final DateTime date;
  final double latitude;
  final double longitude;
  final DateTime sunrise;
  final DateTime sunset;
  final Duration daylight;
  final DateTime goldenHourMorningStart;
  final DateTime goldenHourMorningEnd;
  final DateTime goldenHourEveningStart;
  final DateTime goldenHourEveningEnd;
  final DateTime solarNoon;
  final MoonPhase moonPhase;
  final double moonIllumination; // 0.0 - 1.0
  final int moonAge; // days into lunar cycle (0-29)

  const SunMoonData({
    required this.date,
    required this.latitude,
    required this.longitude,
    required this.sunrise,
    required this.sunset,
    required this.daylight,
    required this.goldenHourMorningStart,
    required this.goldenHourMorningEnd,
    required this.goldenHourEveningStart,
    required this.goldenHourEveningEnd,
    required this.solarNoon,
    required this.moonPhase,
    required this.moonIllumination,
    required this.moonAge,
  });

  /// Formatted daylight duration string.
  String get daylightFormatted {
    final h = daylight.inHours;
    final m = daylight.inMinutes % 60;
    return '${h}h ${m}m';
  }

  /// Whether it's currently golden hour.
  bool get isGoldenHourNow {
    final now = DateTime.now();
    return (now.isAfter(goldenHourMorningStart) &&
            now.isBefore(goldenHourMorningEnd)) ||
        (now.isAfter(goldenHourEveningStart) &&
            now.isBefore(goldenHourEveningEnd));
  }

  /// Whether the sun is currently up.
  bool get isSunUp {
    final now = DateTime.now();
    return now.isAfter(sunrise) && now.isBefore(sunset);
  }
}

/// A saved location for quick access.
class SavedLocation {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final bool isDefault;

  const SavedLocation({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'isDefault': isDefault,
      };

  factory SavedLocation.fromJson(Map<String, dynamic> json) => SavedLocation(
        id: json['id'] as String,
        name: json['name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        isDefault: json['isDefault'] as bool? ?? false,
      );
}
