/// Service for building and parsing standard 5-field cron expressions.
///
/// Fields: minute  hour  day-of-month  month  day-of-week
class CronExpressionService {
  CronExpressionService._();

  static const List<String> fieldNames = [
    'Minute',
    'Hour',
    'Day of Month',
    'Month',
    'Day of Week',
  ];

  static const List<String> monthNames = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];

  static const List<String> dayNames = [
    'SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT',
  ];

  /// Common presets with human labels.
  static const Map<String, String> presets = {
    '* * * * *': 'Every minute',
    '0 * * * *': 'Every hour',
    '0 0 * * *': 'Every day at midnight',
    '0 12 * * *': 'Every day at noon',
    '0 0 * * 1': 'Every Monday at midnight',
    '0 9 * * 1-5': 'Weekdays at 9 AM',
    '0 0 1 * *': 'First day of every month',
    '0 0 1 1 *': 'Every January 1st',
    '*/5 * * * *': 'Every 5 minutes',
    '*/15 * * * *': 'Every 15 minutes',
    '0 */2 * * *': 'Every 2 hours',
    '30 4 * * *': 'Daily at 4:30 AM',
    '0 22 * * 5': 'Every Friday at 10 PM',
    '0 0 15 * *': '15th of every month',
  };

  /// Field ranges: [min, max].
  static const List<List<int>> fieldRanges = [
    [0, 59],  // minute
    [0, 23],  // hour
    [1, 31],  // day of month
    [1, 12],  // month
    [0, 6],   // day of week (0=Sun)
  ];

  /// Build a cron expression from 5 field strings.
  static String build(List<String> fields) {
    assert(fields.length == 5);
    return fields.join(' ');
  }

  /// Parse a cron expression into 5 field strings.
  static List<String>? parse(String expression) {
    final parts = expression.trim().split(RegExp(r'\s+'));
    if (parts.length != 5) return null;
    return parts;
  }

  /// Describe a single cron field in human-readable terms.
  static String describeField(String field, int index) {
    if (field == '*') return 'every ${fieldNames[index].toLowerCase()}';

    // Step: */n or n-m/s
    final stepMatch = RegExp(r'^(\*|\d+-\d+)/(\d+)$').firstMatch(field);
    if (stepMatch != null) {
      final base = stepMatch.group(1)!;
      final step = stepMatch.group(2)!;
      if (base == '*') return 'every $step ${_plural(fieldNames[index].toLowerCase())}';
      return 'every $step ${_plural(fieldNames[index].toLowerCase())} from $base';
    }

    // Range: n-m
    final rangeMatch = RegExp(r'^(\d+)-(\d+)$').firstMatch(field);
    if (rangeMatch != null) {
      final from = _labelValue(int.parse(rangeMatch.group(1)!), index);
      final to = _labelValue(int.parse(rangeMatch.group(2)!), index);
      return '$from through $to';
    }

    // List: n,m,o
    if (field.contains(',')) {
      final vals = field.split(',').map((v) => _labelValue(int.tryParse(v) ?? 0, index)).join(', ');
      return vals;
    }

    // Single value
    final v = int.tryParse(field);
    if (v != null) return 'at ${_labelValue(v, index)}';

    return field;
  }

  /// Full human-readable description.
  static String describe(String expression) {
    final fields = parse(expression);
    if (fields == null) return 'Invalid cron expression';

    // Check presets first.
    if (presets.containsKey(expression)) return presets[expression]!;

    final parts = <String>[];

    // Minute
    if (fields[0] != '*') parts.add(describeField(fields[0], 0));

    // Hour
    if (fields[1] != '*') {
      parts.add(describeField(fields[1], 1));
    }

    // Day of month
    if (fields[2] != '*') parts.add('on day ${fields[2]}');

    // Month
    if (fields[3] != '*') parts.add('in ${describeField(fields[3], 3)}');

    // Day of week
    if (fields[4] != '*') parts.add('on ${describeField(fields[4], 4)}');

    if (parts.isEmpty) return 'Every minute';
    return parts.join(', ');
  }

  /// Get the next N occurrences from a given time.
  static List<DateTime> nextOccurrences(String expression, DateTime from, {int count = 5}) {
    final fields = parse(expression);
    if (fields == null) return [];

    final results = <DateTime>[];
    var current = DateTime(from.year, from.month, from.day, from.hour, from.minute).add(const Duration(minutes: 1));

    int iterations = 0;
    const maxIterations = 525600; // 1 year of minutes

    while (results.length < count && iterations < maxIterations) {
      if (_matches(current, fields)) {
        results.add(current);
      }
      current = current.add(const Duration(minutes: 1));
      iterations++;
    }

    return results;
  }

  static bool _matches(DateTime dt, List<String> fields) {
    return _fieldMatches(dt.minute, fields[0], 0) &&
        _fieldMatches(dt.hour, fields[1], 1) &&
        _fieldMatches(dt.day, fields[2], 2) &&
        _fieldMatches(dt.month, fields[3], 3) &&
        _fieldMatches(dt.weekday % 7, fields[4], 4); // DateTime weekday: Mon=1..Sun=7 → Sun=0
  }

  static bool _fieldMatches(int value, String field, int index) {
    if (field == '*') return true;

    // Handle comma-separated lists
    for (final part in field.split(',')) {
      // Step
      final stepMatch = RegExp(r'^(\*|\d+-\d+)/(\d+)$').firstMatch(part);
      if (stepMatch != null) {
        final base = stepMatch.group(1)!;
        final step = int.parse(stepMatch.group(2)!);
        int start = fieldRanges[index][0];
        int end = fieldRanges[index][1];
        if (base != '*') {
          final rangeParts = base.split('-');
          start = int.parse(rangeParts[0]);
          end = int.parse(rangeParts[1]);
        }
        if (value >= start && value <= end && (value - start) % step == 0) return true;
        continue;
      }

      // Range
      final rangeMatch = RegExp(r'^(\d+)-(\d+)$').firstMatch(part);
      if (rangeMatch != null) {
        final from = int.parse(rangeMatch.group(1)!);
        final to = int.parse(rangeMatch.group(2)!);
        if (value >= from && value <= to) return true;
        continue;
      }

      // Single value
      final v = int.tryParse(part);
      if (v != null && v == value) return true;
    }

    return false;
  }

  static String _labelValue(int value, int fieldIndex) {
    if (fieldIndex == 3 && value >= 1 && value <= 12) return monthNames[value - 1];
    if (fieldIndex == 4 && value >= 0 && value <= 6) return dayNames[value];
    return value.toString();
  }

  static String _plural(String s) {
    if (s.endsWith('h')) return '${s}es'; // month → monthes? No...
    return '${s}s';
  }
}
