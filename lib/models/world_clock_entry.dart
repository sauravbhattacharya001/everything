/// A saved time zone entry for the World Clock feature.
///
/// The [utcOffset] field carries the zone's *standard-time* offset from UTC.
/// For zones that observe daylight saving time, the [dstRule] determines
/// whether one extra hour should be added at any given moment; use
/// [currentOffset] and [currentAbbreviation] instead of the raw
/// [utcOffset] / [timeZoneName] when displaying live data.
class WorldClockEntry {
  final String id;
  final String label;

  /// Slash-separated standard/daylight abbreviation pair, e.g. `EST/EDT`,
  /// `GMT/BST`, `CET/CEST`. A single token (e.g. `IST`, `JST`) is used for
  /// zones without DST.
  final String timeZoneName;

  /// Standard-time offset from UTC. The *current* offset (which may include
  /// a one-hour DST shift) is computed by [currentOffset].
  final Duration utcOffset;
  final String? emoji;

  /// DST rule that applies to this zone. Defaults to [DstRule.none] for
  /// zones that do not observe daylight saving time.
  final DstRule dstRule;

  const WorldClockEntry({
    required this.id,
    required this.label,
    required this.timeZoneName,
    required this.utcOffset,
    this.emoji,
    this.dstRule = DstRule.none,
  });

  /// True when the zone is currently observing daylight saving time.
  ///
  /// [utcNow] defaults to [DateTime.now] (UTC). It is exposed as a parameter
  /// purely so tests can pin a known instant.
  bool isDstActive([DateTime? utcNow]) {
    final now = (utcNow ?? DateTime.now()).toUtc();
    return DstRules.isActive(dstRule, now, utcOffset);
  }

  /// The zone's effective UTC offset *at this moment*, accounting for DST.
  Duration currentOffset([DateTime? utcNow]) {
    if (dstRule == DstRule.none) return utcOffset;
    return isDstActive(utcNow)
        ? utcOffset + const Duration(hours: 1)
        : utcOffset;
  }

  /// Returns the standard or daylight portion of [timeZoneName] for the
  /// current moment (e.g. `EST` vs `EDT`). When the name is not a
  /// slash-separated pair, it is returned unchanged.
  String currentAbbreviation([DateTime? utcNow]) {
    final parts = timeZoneName.split('/');
    if (parts.length != 2) return timeZoneName;
    return isDstActive(utcNow) ? parts[1] : parts[0];
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'timeZoneName': timeZoneName,
        'utcOffsetMinutes': utcOffset.inMinutes,
        'emoji': emoji,
        'dstRule': dstRule.name,
      };

  factory WorldClockEntry.fromJson(Map<String, dynamic> json) {
    final ruleName = json['dstRule'] as String?;
    final rule = ruleName == null
        ? DstRule.none
        : DstRule.values.firstWhere(
            (r) => r.name == ruleName,
            orElse: () => DstRule.none,
          );
    return WorldClockEntry(
      id: json['id'] as String,
      label: json['label'] as String,
      timeZoneName: json['timeZoneName'] as String,
      utcOffset: Duration(minutes: json['utcOffsetMinutes'] as int),
      emoji: json['emoji'] as String?,
      dstRule: rule,
    );
  }
}

/// Daylight-saving-time schedule family. Each enum value identifies a
/// well-known transition rule shared by a group of jurisdictions.
///
/// We deliberately keep this list small and tied to the curated World Clock
/// preset set. For arbitrary IANA zone support, swap in `package:timezone`.
enum DstRule {
  /// Zone does not observe DST.
  none,

  /// United States / Canada rule: 2nd Sunday of March 02:00 local standard
  /// time through 1st Sunday of November 02:00 local daylight time
  /// (== 01:00 local standard time). +1 hour while active.
  usNorthAmerica,

  /// European Union / United Kingdom rule: last Sunday of March 01:00 UTC
  /// through last Sunday of October 01:00 UTC. +1 hour while active.
  europe,

  /// Eastern Australia (NSW, VIC, TAS, ACT): 1st Sunday of October 02:00
  /// local standard time through 1st Sunday of April 03:00 local daylight
  /// time (== 02:00 local standard time). +1 hour while active.
  australiaEast,

  /// New Zealand: last Sunday of September 02:00 local standard time
  /// through 1st Sunday of April 03:00 local daylight time
  /// (== 02:00 local standard time). +1 hour while active.
  newZealand,
}

/// Pure-Dart implementation of the [DstRule] transitions.
///
/// All comparisons are done in UTC; when a rule is expressed in local
/// standard time we synthesise the local instant by adding [standardOffset]
/// to the UTC moment under test. This is exact because every rule below
/// switches at a time-of-day defined in local *standard* time (or in UTC).
class DstRules {
  const DstRules._();

  /// Whether [rule] is currently observed at [utcNow]. [standardOffset] is
  /// the zone's standard-time offset from UTC (e.g. `-5h` for New York).
  static bool isActive(
      DstRule rule, DateTime utcNow, Duration standardOffset) {
    final now = utcNow.toUtc();
    switch (rule) {
      case DstRule.none:
        return false;
      case DstRule.usNorthAmerica:
        final local = now.add(standardOffset);
        final year = local.year;
        final start = _nthWeekdayUtc(year, 3, DateTime.sunday, 2)
            .add(const Duration(hours: 2));
        final end = _nthWeekdayUtc(year, 11, DateTime.sunday, 1)
            .add(const Duration(hours: 1));
        return !local.isBefore(start) && local.isBefore(end);
      case DstRule.europe:
        final year = now.year;
        final start = _lastWeekdayUtc(year, 3, DateTime.sunday)
            .add(const Duration(hours: 1));
        final end = _lastWeekdayUtc(year, 10, DateTime.sunday)
            .add(const Duration(hours: 1));
        return !now.isBefore(start) && now.isBefore(end);
      case DstRule.australiaEast:
        final local = now.add(standardOffset);
        final year = local.year;
        final aprilEnd = _nthWeekdayUtc(year, 4, DateTime.sunday, 1)
            .add(const Duration(hours: 2));
        final octStart = _nthWeekdayUtc(year, 10, DateTime.sunday, 1)
            .add(const Duration(hours: 2));
        // Southern-hemisphere wrap: DST runs Oct..April.
        return local.isBefore(aprilEnd) || !local.isBefore(octStart);
      case DstRule.newZealand:
        final local = now.add(standardOffset);
        final year = local.year;
        final aprilEnd = _nthWeekdayUtc(year, 4, DateTime.sunday, 1)
            .add(const Duration(hours: 2));
        final sepStart = _lastWeekdayUtc(year, 9, DateTime.sunday)
            .add(const Duration(hours: 2));
        return local.isBefore(aprilEnd) || !local.isBefore(sepStart);
    }
  }

  /// UTC midnight on the [n]-th occurrence of [weekday] within
  /// (year, month). [n] is 1-based; [weekday] uses [DateTime] constants
  /// (Mon=1..Sun=7).
  static DateTime _nthWeekdayUtc(int year, int month, int weekday, int n) {
    final first = DateTime.utc(year, month, 1);
    final delta = ((weekday - first.weekday) % 7 + 7) % 7;
    return first.add(Duration(days: delta + (n - 1) * 7));
  }

  /// UTC midnight on the *last* occurrence of [weekday] within
  /// (year, month).
  static DateTime _lastWeekdayUtc(int year, int month, int weekday) {
    // First day of next month, minus one day = last day of (year, month).
    final last = DateTime.utc(year, month + 1, 1)
        .subtract(const Duration(days: 1));
    final delta = ((last.weekday - weekday) % 7 + 7) % 7;
    return last.subtract(Duration(days: delta));
  }
}
