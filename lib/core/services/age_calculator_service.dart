/// Service that computes a detailed age breakdown from a birth date.
///
/// In addition to exact years/months/days, it produces fun lifetime
/// statistics (heartbeats, breaths, steps walked, words spoken, etc.)
/// and determines the Western zodiac sign and birth day-of-week.
///
/// All methods are static; the constructor is private.
class AgeCalculatorService {
  AgeCalculatorService._();

  /// Calculate detailed age from [birthDate] to [now].
  static AgeResult calculate(DateTime birthDate, DateTime now) {
    if (birthDate.isAfter(now)) {
      return AgeResult.zero();
    }

    int years = now.year - birthDate.year;
    int months = now.month - birthDate.month;
    int days = now.day - birthDate.day;

    if (days < 0) {
      months--;
      // Days in previous month
      final prevMonth = DateTime(now.year, now.month, 0);
      days += prevMonth.day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    final totalDays = now.difference(birthDate).inDays;
    final totalWeeks = totalDays ~/ 7;
    final totalHours = totalDays * 24;

    // Next birthday
    var nextBirthday = DateTime(now.year, birthDate.month, birthDate.day);
    if (nextBirthday.isBefore(now) || nextBirthday == now) {
      nextBirthday = DateTime(now.year + 1, birthDate.month, birthDate.day);
    }
    final daysUntilBirthday = nextBirthday.difference(now).inDays;

    // Fun stats (approximate averages)
    final heartbeats = totalDays * 100800; // ~70 bpm avg
    final breaths = totalDays * 23040; // ~16/min avg
    final sleepHours = totalDays * 8; // ~8h/day avg
    final mealsEaten = totalDays * 3;
    final stepsWalked = totalDays * 7500; // avg steps/day
    final wordsSpoken = totalDays * 16000; // avg words/day

    // Zodiac sign
    final zodiac = _getZodiacSign(birthDate.month, birthDate.day);

    // Day of week born
    final dayOfWeek = _dayOfWeekName(birthDate.weekday);

    return AgeResult(
      years: years,
      months: months,
      days: days,
      totalDays: totalDays,
      totalWeeks: totalWeeks,
      totalHours: totalHours,
      daysUntilBirthday: daysUntilBirthday,
      heartbeats: heartbeats,
      breaths: breaths,
      sleepHours: sleepHours,
      mealsEaten: mealsEaten,
      stepsWalked: stepsWalked,
      wordsSpoken: wordsSpoken,
      zodiacSign: zodiac,
      dayOfWeekBorn: dayOfWeek,
      birthDate: birthDate,
    );
  }

  /// Returns the Western zodiac sign emoji + name for the given [month]/[day].
  ///
  /// Uses the tropical zodiac date boundaries. Edge cases on cusp dates
  /// follow the conventional cutoff (e.g. Jan 20 → Capricorn, Jan 21 → Aquarius).
  static String _getZodiacSign(int month, int day) {
    const signs = [
      (1, 20, '♑ Capricorn'),
      (2, 19, '♒ Aquarius'),
      (3, 20, '♓ Pisces'),
      (4, 20, '♈ Aries'),
      (5, 21, '♉ Taurus'),
      (6, 21, '♊ Gemini'),
      (7, 23, '♋ Cancer'),
      (8, 23, '♌ Leo'),
      (9, 23, '♍ Virgo'),
      (10, 23, '♎ Libra'),
      (11, 22, '♏ Scorpio'),
      (12, 22, '♐ Sagittarius'),
    ];
    for (int i = 0; i < signs.length; i++) {
      if (month == signs[i].$1 && day <= signs[i].$2) {
        return i == 0 ? signs[11].$3 : signs[i - 1].$3;
      }
    }
    // After Dec 22 = Capricorn
    return '♑ Capricorn';
  }

  /// Converts a Dart [DateTime.weekday] value (1 = Monday … 7 = Sunday)
  /// to its English name.
  static String _dayOfWeekName(int weekday) {
    const names = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return names[weekday - 1];
  }
}

/// Immutable result of an age calculation containing exact age components,
/// lifetime statistics, zodiac sign, and countdown to the next birthday.
class AgeResult {
  final int years;
  final int months;
  final int days;
  final int totalDays;
  final int totalWeeks;
  final int totalHours;
  final int daysUntilBirthday;
  final int heartbeats;
  final int breaths;
  final int sleepHours;
  final int mealsEaten;
  final int stepsWalked;
  final int wordsSpoken;
  final String zodiacSign;
  final String dayOfWeekBorn;
  final DateTime? birthDate;

  const AgeResult({
    required this.years,
    required this.months,
    required this.days,
    required this.totalDays,
    required this.totalWeeks,
    required this.totalHours,
    required this.daysUntilBirthday,
    required this.heartbeats,
    required this.breaths,
    required this.sleepHours,
    required this.mealsEaten,
    required this.stepsWalked,
    required this.wordsSpoken,
    required this.zodiacSign,
    required this.dayOfWeekBorn,
    this.birthDate,
  });

  /// Sentinel representing zero age (used when [birthDate] is in the future).
  factory AgeResult.zero() => const AgeResult(
        years: 0,
        months: 0,
        days: 0,
        totalDays: 0,
        totalWeeks: 0,
        totalHours: 0,
        daysUntilBirthday: 0,
        heartbeats: 0,
        breaths: 0,
        sleepHours: 0,
        mealsEaten: 0,
        stepsWalked: 0,
        wordsSpoken: 0,
        zodiacSign: '',
        dayOfWeekBorn: '',
      );

  /// Returns a human-readable age string, omitting leading zero components
  /// (e.g. "3 months, 12 days" instead of "0 years, 3 months, 12 days").
  String get formattedAge {
    if (years > 0) {
      return '$years years, $months months, $days days';
    } else if (months > 0) {
      return '$months months, $days days';
    }
    return '$days days';
  }
}
