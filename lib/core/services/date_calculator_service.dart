/// Date Calculator service — compute differences between dates and
/// add/subtract durations from a given date.
class DateCalculatorService {
  DateCalculatorService._();

  /// Calculate the difference between two dates.
  static DateDifference difference(DateTime from, DateTime to) {
    final earlier = from.isBefore(to) ? from : to;
    final later = from.isBefore(to) ? to : from;

    int years = later.year - earlier.year;
    int months = later.month - earlier.month;
    int days = later.day - earlier.day;

    if (days < 0) {
      months--;
      final prevMonth = DateTime(later.year, later.month, 0);
      days += prevMonth.day;
    }
    if (months < 0) {
      years--;
      months += 12;
    }

    final totalDays = later.difference(earlier).inDays;
    final totalWeeks = totalDays ~/ 7;
    final remainderDays = totalDays % 7;
    final totalHours = later.difference(earlier).inHours;
    final totalMinutes = later.difference(earlier).inMinutes;

    // Business days (Mon-Fri) approximation
    int businessDays = 0;
    var cursor = earlier;
    while (cursor.isBefore(later)) {
      if (cursor.weekday <= 5) businessDays++;
      cursor = cursor.add(const Duration(days: 1));
    }

    return DateDifference(
      years: years,
      months: months,
      days: days,
      totalDays: totalDays,
      totalWeeks: totalWeeks,
      remainderDays: remainderDays,
      totalHours: totalHours,
      totalMinutes: totalMinutes,
      businessDays: businessDays,
    );
  }

  /// Add or subtract a duration from a date.
  static DateTime offset(
    DateTime date, {
    int years = 0,
    int months = 0,
    int weeks = 0,
    int days = 0,
  }) {
    int newYear = date.year + years;
    int newMonth = date.month + months;

    // Normalize month overflow/underflow
    while (newMonth > 12) {
      newMonth -= 12;
      newYear++;
    }
    while (newMonth < 1) {
      newMonth += 12;
      newYear--;
    }

    // Clamp day to valid range for the target month
    final maxDay = DateTime(newYear, newMonth + 1, 0).day;
    final newDay = date.day > maxDay ? maxDay : date.day;

    return DateTime(newYear, newMonth, newDay).add(
      Duration(days: days + weeks * 7),
    );
  }

  /// Day of year (1-366).
  static int dayOfYear(DateTime date) {
    return date.difference(DateTime(date.year, 1, 1)).inDays + 1;
  }

  /// Week number (ISO 8601 approximation).
  static int weekOfYear(DateTime date) {
    final jan1 = DateTime(date.year, 1, 1);
    final dayOfYr = date.difference(jan1).inDays;
    return ((dayOfYr - date.weekday + 10) / 7).floor();
  }

  /// Whether [year] is a leap year.
  static bool isLeapYear(int year) {
    return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
  }

  /// Days remaining in the year from [date].
  static int daysRemainingInYear(DateTime date) {
    final endOfYear = DateTime(date.year, 12, 31);
    return endOfYear.difference(date).inDays;
  }

  static String dayOfWeekName(int weekday) {
    const names = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday',
    ];
    return names[(weekday - 1) % 7];
  }
}

class DateDifference {
  final int years;
  final int months;
  final int days;
  final int totalDays;
  final int totalWeeks;
  final int remainderDays;
  final int totalHours;
  final int totalMinutes;
  final int businessDays;

  const DateDifference({
    required this.years,
    required this.months,
    required this.days,
    required this.totalDays,
    required this.totalWeeks,
    required this.remainderDays,
    required this.totalHours,
    required this.totalMinutes,
    required this.businessDays,
  });

  String get humanReadable {
    final parts = <String>[];
    if (years > 0) parts.add('$years year${years == 1 ? '' : 's'}');
    if (months > 0) parts.add('$months month${months == 1 ? '' : 's'}');
    if (days > 0) parts.add('$days day${days == 1 ? '' : 's'}');
    return parts.isEmpty ? 'Same day' : parts.join(', ');
  }
}
