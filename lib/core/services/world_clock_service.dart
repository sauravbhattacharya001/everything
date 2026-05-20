import '../services/persistent_state_mixin.dart';
import '../../models/world_clock_entry.dart';

/// Service that manages saved world-clock time zones with persistence.
///
/// Each preset carries both its *standard-time* UTC offset and an optional
/// [DstRule] so that the displayed wall-clock time tracks daylight saving
/// transitions automatically (see issue #146). When you need the live
/// offset / abbreviation, prefer the `*ForEntry` helpers below over the
/// legacy [nowIn] / [formatOffset] / [timeDiffFromLocal] forms (which now
/// assume the supplied [Duration] is already the *current* effective
/// offset).
class WorldClockService with PersistentStateMixin {
  WorldClockService._();
  static final WorldClockService instance = WorldClockService._();

  @override
  String get stateKey => 'world_clock';

  List<WorldClockEntry> _clocks = [];
  List<WorldClockEntry> get clocks => List.unmodifiable(_clocks);

  // ── Predefined popular time zones ──
  //
  // Each entry's `utcOffset` is the *standard-time* offset; the `dstRule`
  // field tells the renderer whether to add an hour during the local
  // daylight-saving window.

  static final List<WorldClockEntry> presets = [
    WorldClockEntry(id: 'utc', label: 'UTC', timeZoneName: 'UTC', utcOffset: Duration.zero, emoji: '🌐'),
    WorldClockEntry(id: 'nyc', label: 'New York', timeZoneName: 'EST/EDT', utcOffset: const Duration(hours: -5), emoji: '🗽', dstRule: DstRule.usNorthAmerica),
    WorldClockEntry(id: 'lax', label: 'Los Angeles', timeZoneName: 'PST/PDT', utcOffset: const Duration(hours: -8), emoji: '🌴', dstRule: DstRule.usNorthAmerica),
    WorldClockEntry(id: 'chi', label: 'Chicago', timeZoneName: 'CST/CDT', utcOffset: const Duration(hours: -6), emoji: '🏙', dstRule: DstRule.usNorthAmerica),
    WorldClockEntry(id: 'den', label: 'Denver', timeZoneName: 'MST/MDT', utcOffset: const Duration(hours: -7), emoji: '🏔', dstRule: DstRule.usNorthAmerica),
    WorldClockEntry(id: 'lon', label: 'London', timeZoneName: 'GMT/BST', utcOffset: Duration.zero, emoji: '🇬🇧', dstRule: DstRule.europe),
    WorldClockEntry(id: 'par', label: 'Paris', timeZoneName: 'CET/CEST', utcOffset: const Duration(hours: 1), emoji: '🇫🇷', dstRule: DstRule.europe),
    WorldClockEntry(id: 'ber', label: 'Berlin', timeZoneName: 'CET/CEST', utcOffset: const Duration(hours: 1), emoji: '🇩🇪', dstRule: DstRule.europe),
    WorldClockEntry(id: 'mow', label: 'Moscow', timeZoneName: 'MSK', utcOffset: const Duration(hours: 3), emoji: '🇷🇺'),
    WorldClockEntry(id: 'dxb', label: 'Dubai', timeZoneName: 'GST', utcOffset: const Duration(hours: 4), emoji: '🇦🇪'),
    WorldClockEntry(id: 'kol', label: 'Kolkata', timeZoneName: 'IST', utcOffset: const Duration(hours: 5, minutes: 30), emoji: '🇮🇳'),
    WorldClockEntry(id: 'bkk', label: 'Bangkok', timeZoneName: 'ICT', utcOffset: const Duration(hours: 7), emoji: '🇹🇭'),
    WorldClockEntry(id: 'sha', label: 'Shanghai', timeZoneName: 'CST', utcOffset: const Duration(hours: 8), emoji: '🇨🇳'),
    WorldClockEntry(id: 'tyo', label: 'Tokyo', timeZoneName: 'JST', utcOffset: const Duration(hours: 9), emoji: '🇯🇵'),
    WorldClockEntry(id: 'syd', label: 'Sydney', timeZoneName: 'AEST/AEDT', utcOffset: const Duration(hours: 10), emoji: '🇦🇺', dstRule: DstRule.australiaEast),
    WorldClockEntry(id: 'akl', label: 'Auckland', timeZoneName: 'NZST/NZDT', utcOffset: const Duration(hours: 12), emoji: '🇳🇿', dstRule: DstRule.newZealand),
    WorldClockEntry(id: 'hon', label: 'Honolulu', timeZoneName: 'HST', utcOffset: const Duration(hours: -10), emoji: '🌺'),
    WorldClockEntry(id: 'sao', label: 'Sao Paulo', timeZoneName: 'BRT', utcOffset: const Duration(hours: -3), emoji: '🇧🇷'),
    WorldClockEntry(id: 'jnb', label: 'Johannesburg', timeZoneName: 'SAST', utcOffset: const Duration(hours: 2), emoji: '🇿🇦'),
    WorldClockEntry(id: 'sin', label: 'Singapore', timeZoneName: 'SGT', utcOffset: const Duration(hours: 8), emoji: '🇸🇬'),
    WorldClockEntry(id: 'sel', label: 'Seoul', timeZoneName: 'KST', utcOffset: const Duration(hours: 9), emoji: '🇰🇷'),
  ];

  /// Initialize from persisted state.
  Future<void> init() async {
    final data = await loadState();
    if (data != null && data['clocks'] is List) {
      _clocks = (data['clocks'] as List)
          .map((e) => WorldClockEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    if (_clocks.isEmpty) {
      // Default: show a few popular zones
      _clocks = [presets[0], presets[1], presets[2], presets[5], presets[13]];
      await _save();
    }
  }

  /// Add a clock. Returns false if already present (by id).
  Future<bool> addClock(WorldClockEntry entry) async {
    if (_clocks.any((c) => c.id == entry.id)) return false;
    _clocks.add(entry);
    await _save();
    return true;
  }

  /// Remove a clock by id.
  Future<void> removeClock(String id) async {
    _clocks.removeWhere((c) => c.id == id);
    await _save();
  }

  /// Reorder clocks.
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final item = _clocks.removeAt(oldIndex);
    _clocks.insert(newIndex, item);
    await _save();
  }

  /// Get current DateTime for a given UTC offset.
  ///
  /// **Prefer [nowInEntry] for preset zones** — this helper assumes
  /// [utcOffset] is already the live (DST-adjusted) offset and is kept for
  /// backward compatibility with callers that already do their own
  /// resolution.
  static DateTime nowIn(Duration utcOffset) {
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(utcOffset);
  }

  /// Get current DateTime for the given preset entry, applying any active
  /// DST shift. Pass [utcNow] in tests to pin a specific instant.
  static DateTime nowInEntry(WorldClockEntry entry, [DateTime? utcNow]) {
    final now = (utcNow ?? DateTime.now()).toUtc();
    return now.add(entry.currentOffset(now));
  }

  /// Format offset as e.g. "UTC+5:30" or "UTC-8".
  static String formatOffset(Duration offset) {
    final sign = offset.isNegative ? '-' : '+';
    final totalMinutes = offset.inMinutes.abs();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (minutes == 0) return 'UTC$sign$hours';
    return 'UTC$sign$hours:${minutes.toString().padLeft(2, '0')}';
  }

  /// Format the entry's *current* offset (DST-aware) as "UTC+1", "UTC-4".
  static String formatCurrentOffset(WorldClockEntry entry, [DateTime? utcNow]) =>
      formatOffset(entry.currentOffset(utcNow));

  /// Get time difference description from local.
  ///
  /// **Prefer [timeDiffFromLocalForEntry] for preset zones** — this helper
  /// treats [targetOffset] as already DST-adjusted.
  static String timeDiffFromLocal(Duration targetOffset) {
    final localOffset = DateTime.now().timeZoneOffset;
    final diff = targetOffset - localOffset;
    final totalMinutes = diff.inMinutes;
    if (totalMinutes == 0) return 'Same as local';
    final sign = totalMinutes > 0 ? '+' : '';
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes.abs() % 60;
    if (minutes == 0) return '${sign}${hours}h from local';
    return '${sign}${hours}h ${minutes}m from local';
  }

  /// DST-aware variant of [timeDiffFromLocal] for preset entries.
  static String timeDiffFromLocalForEntry(WorldClockEntry entry,
      [DateTime? utcNow]) {
    return timeDiffFromLocal(entry.currentOffset(utcNow));
  }

  Future<void> _save() async {
    await saveState({'clocks': _clocks.map((c) => c.toJson()).toList()});
  }
}
