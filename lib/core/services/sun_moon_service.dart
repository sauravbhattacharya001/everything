import 'dart:math' as math;
import '../../models/sun_moon_entry.dart';

/// Astronomical calculation service for sun/moon positions.
///
/// Uses standard solar position algorithms (simplified Meeus) for
/// sunrise/sunset and a basic lunar phase model. No external API needed.
class SunMoonService {
  const SunMoonService();

  /// Calculate sun & moon data for a given date and location.
  SunMoonData calculate({
    required DateTime date,
    required double latitude,
    required double longitude,
  }) {
    final jd = _julianDay(date);
    final sunrise = _calcSunrise(date, latitude, longitude, jd);
    final sunset = _calcSunset(date, latitude, longitude, jd);
    final daylight = sunset.difference(sunrise);
    final solarNoon = sunrise.add(Duration(milliseconds: daylight.inMilliseconds ~/ 2));

    // Golden hour: ~first/last hour of sunlight (sun < 6° above horizon)
    final goldenMorningStart = sunrise;
    final goldenMorningEnd = sunrise.add(const Duration(minutes: 60));
    final goldenEveningStart = sunset.subtract(const Duration(minutes: 60));
    final goldenEveningEnd = sunset;

    // Moon phase calculation
    final moonAge = _moonAge(date);
    final moonPhase = _moonPhaseFromAge(moonAge);
    final moonIllumination = _moonIllumination(moonAge);

    return SunMoonData(
      date: date,
      latitude: latitude,
      longitude: longitude,
      sunrise: sunrise,
      sunset: sunset,
      daylight: daylight,
      goldenHourMorningStart: goldenMorningStart,
      goldenHourMorningEnd: goldenMorningEnd,
      goldenHourEveningStart: goldenEveningStart,
      goldenHourEveningEnd: goldenEveningEnd,
      solarNoon: solarNoon,
      moonPhase: moonPhase,
      moonIllumination: moonIllumination,
      moonAge: moonAge.round(),
    );
  }

  /// Get data for a range of dates (for week/month views).
  List<SunMoonData> calculateRange({
    required DateTime start,
    required int days,
    required double latitude,
    required double longitude,
  }) {
    return List.generate(days, (i) {
      final date = start.add(Duration(days: i));
      return calculate(date: date, latitude: latitude, longitude: longitude);
    });
  }

  /// Next full moon from a given date.
  DateTime nextFullMoon(DateTime from) {
    var date = from;
    for (var i = 0; i < 30; i++) {
      final age = _moonAge(date);
      if ((age - 14.765).abs() < 0.5) return date;
      date = date.add(const Duration(days: 1));
    }
    return from.add(const Duration(days: 29)); // fallback
  }

  /// Next new moon from a given date.
  DateTime nextNewMoon(DateTime from) {
    var date = from;
    for (var i = 0; i < 30; i++) {
      final age = _moonAge(date);
      if (age < 1.0 || age > 28.5) return date;
      date = date.add(const Duration(days: 1));
    }
    return from.add(const Duration(days: 29));
  }

  // ── Private helpers ──

  double _julianDay(DateTime date) {
    final y = date.year;
    final m = date.month;
    final d = date.day;
    final a = (14 - m) ~/ 12;
    final yy = y + 4800 - a;
    final mm = m + 12 * a - 3;
    return d +
        (153 * mm + 2) ~/ 5 +
        365 * yy +
        yy ~/ 4 -
        yy ~/ 100 +
        yy ~/ 400 -
        32045.0;
  }

  DateTime _calcSunrise(DateTime date, double lat, double lon, double jd) {
    final t = _solarTime(date, lat, lon, true);
    return DateTime(date.year, date.month, date.day)
        .add(Duration(minutes: t.round()));
  }

  DateTime _calcSunset(DateTime date, double lat, double lon, double jd) {
    final t = _solarTime(date, lat, lon, false);
    return DateTime(date.year, date.month, date.day)
        .add(Duration(minutes: t.round()));
  }

  /// Simplified sunrise/sunset time in minutes from midnight (UTC adjusted).
  double _solarTime(DateTime date, double lat, double lon, bool isSunrise) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    final radLat = lat * math.pi / 180.0;

    // Solar declination (simplified)
    final declination =
        23.45 * math.sin(2 * math.pi * (284 + dayOfYear) / 365.0) *
            math.pi /
            180.0;

    // Hour angle
    final cosHourAngle = (math.cos(90.833 * math.pi / 180.0) -
            math.sin(radLat) * math.sin(declination)) /
        (math.cos(radLat) * math.cos(declination));

    // Clamp for polar regions
    final clampedCos = cosHourAngle.clamp(-1.0, 1.0);
    final hourAngle = math.acos(clampedCos) * 180.0 / math.pi;

    // Equation of time (simplified)
    final b = 2 * math.pi * (dayOfYear - 81) / 365.0;
    final eot = 9.87 * math.sin(2 * b) -
        7.53 * math.cos(b) -
        1.5 * math.sin(b);

    final solarNoonMinutes = 720 - 4 * lon - eot;

    // Timezone offset in minutes
    final tzOffset = date.timeZoneOffset.inMinutes;

    if (isSunrise) {
      return solarNoonMinutes - 4 * hourAngle + tzOffset;
    } else {
      return solarNoonMinutes + 4 * hourAngle + tzOffset;
    }
  }

  /// Moon age in days (0 = new moon, ~14.7 = full moon).
  double _moonAge(DateTime date) {
    // Reference new moon: Jan 6, 2000 18:14 UTC
    final reference = DateTime.utc(2000, 1, 6, 18, 14);
    final daysSince = date.difference(reference).inHours / 24.0;
    const synodicMonth = 29.53058868;
    final age = daysSince % synodicMonth;
    return age < 0 ? age + synodicMonth : age;
  }

  MoonPhase _moonPhaseFromAge(double age) {
    if (age < 1.845) return MoonPhase.newMoon;
    if (age < 5.536) return MoonPhase.waxingCrescent;
    if (age < 9.228) return MoonPhase.firstQuarter;
    if (age < 12.919) return MoonPhase.waxingGibbous;
    if (age < 16.611) return MoonPhase.fullMoon;
    if (age < 20.302) return MoonPhase.waningGibbous;
    if (age < 23.994) return MoonPhase.lastQuarter;
    if (age < 27.685) return MoonPhase.waningCrescent;
    return MoonPhase.newMoon;
  }

  double _moonIllumination(double age) {
    // Approximate illumination using cosine model
    const synodicMonth = 29.53058868;
    return (1 - math.cos(2 * math.pi * age / synodicMonth)) / 2.0;
  }

  /// Well-known locations for quick selection.
  static const defaultLocations = [
    SavedLocation(id: 'seattle', name: 'Seattle', latitude: 47.6062, longitude: -122.3321),
    SavedLocation(id: 'nyc', name: 'New York', latitude: 40.7128, longitude: -74.0060),
    SavedLocation(id: 'london', name: 'London', latitude: 51.5074, longitude: -0.1278),
    SavedLocation(id: 'tokyo', name: 'Tokyo', latitude: 35.6762, longitude: 139.6503),
    SavedLocation(id: 'sydney', name: 'Sydney', latitude: -33.8688, longitude: 151.2093),
    SavedLocation(id: 'paris', name: 'Paris', latitude: 48.8566, longitude: 2.3522),
  ];
}
