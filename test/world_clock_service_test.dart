import 'package:everything/core/services/world_clock_service.dart';
import 'package:everything/models/world_clock_entry.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression tests for issue #146 — WorldClockService DST handling.
//
// Every assertion pins a specific UTC instant so the test is deterministic
// regardless of the host clock or local time zone.

void main() {
  // Pull presets by id for clarity.
  final byId = {for (final p in WorldClockService.presets) p.id: p};

  group('WorldClockEntry.isDstActive — US/North America', () {
    final nyc = byId['nyc']!;

    test('mid-January 2025 → standard time (EST)', () {
      // 2025-01-15 12:00 UTC = 07:00 EST.
      final t = DateTime.utc(2025, 1, 15, 12);
      expect(nyc.isDstActive(t), isFalse);
      expect(nyc.currentOffset(t), const Duration(hours: -5));
      expect(nyc.currentAbbreviation(t), 'EST');
    });

    test('mid-July 2025 → daylight time (EDT)', () {
      final t = DateTime.utc(2025, 7, 15, 12);
      expect(nyc.isDstActive(t), isTrue);
      expect(nyc.currentOffset(t), const Duration(hours: -4));
      expect(nyc.currentAbbreviation(t), 'EDT');
    });

    test('2025 spring-forward exact boundary: 2025-03-09 07:00 UTC', () {
      // 2025-03-09 02:00 EST = 2025-03-09 07:00 UTC → DST begins.
      final justBefore = DateTime.utc(2025, 3, 9, 6, 59);
      final atBoundary = DateTime.utc(2025, 3, 9, 7);
      expect(nyc.isDstActive(justBefore), isFalse);
      expect(nyc.isDstActive(atBoundary), isTrue);
    });

    test('2025 fall-back exact boundary: 2025-11-02 06:00 UTC', () {
      // 2025-11-02 02:00 EDT = 06:00 UTC → DST ends.
      final justBefore = DateTime.utc(2025, 11, 2, 5, 59);
      final atBoundary = DateTime.utc(2025, 11, 2, 6);
      expect(nyc.isDstActive(justBefore), isTrue);
      expect(nyc.isDstActive(atBoundary), isFalse);
    });

    test('Los Angeles also follows USA rule', () {
      final lax = byId['lax']!;
      expect(lax.currentOffset(DateTime.utc(2025, 7, 15, 12)),
          const Duration(hours: -7));
      expect(lax.currentOffset(DateTime.utc(2025, 1, 15, 12)),
          const Duration(hours: -8));
    });
  });

  group('WorldClockEntry.isDstActive — Europe', () {
    final lon = byId['lon']!;
    final par = byId['par']!;

    test('London mid-January → GMT', () {
      final t = DateTime.utc(2025, 1, 15, 12);
      expect(lon.isDstActive(t), isFalse);
      expect(lon.currentOffset(t), Duration.zero);
      expect(lon.currentAbbreviation(t), 'GMT');
    });

    test('London mid-July → BST (UTC+1)', () {
      final t = DateTime.utc(2025, 7, 15, 12);
      expect(lon.isDstActive(t), isTrue);
      expect(lon.currentOffset(t), const Duration(hours: 1));
      expect(lon.currentAbbreviation(t), 'BST');
    });

    test('EU spring boundary: 2025-03-30 01:00 UTC', () {
      final justBefore = DateTime.utc(2025, 3, 30, 0, 59);
      final atBoundary = DateTime.utc(2025, 3, 30, 1);
      expect(lon.isDstActive(justBefore), isFalse);
      expect(lon.isDstActive(atBoundary), isTrue);
    });

    test('EU fall boundary: 2025-10-26 01:00 UTC', () {
      final justBefore = DateTime.utc(2025, 10, 26, 0, 59);
      final atBoundary = DateTime.utc(2025, 10, 26, 1);
      expect(lon.isDstActive(justBefore), isTrue);
      expect(lon.isDstActive(atBoundary), isFalse);
    });

    test('Paris mid-July → CEST (UTC+2)', () {
      final t = DateTime.utc(2025, 7, 15, 12);
      expect(par.currentOffset(t), const Duration(hours: 2));
      expect(par.currentAbbreviation(t), 'CEST');
    });
  });

  group('WorldClockEntry.isDstActive — Southern hemisphere', () {
    final syd = byId['syd']!;
    final akl = byId['akl']!;

    test('Sydney mid-January (austral summer) → AEDT (UTC+11)', () {
      final t = DateTime.utc(2025, 1, 15, 0); // 11:00 AEDT
      expect(syd.isDstActive(t), isTrue);
      expect(syd.currentOffset(t), const Duration(hours: 11));
      expect(syd.currentAbbreviation(t), 'AEDT');
    });

    test('Sydney mid-July (austral winter) → AEST (UTC+10)', () {
      final t = DateTime.utc(2025, 7, 15, 0);
      expect(syd.isDstActive(t), isFalse);
      expect(syd.currentOffset(t), const Duration(hours: 10));
      expect(syd.currentAbbreviation(t), 'AEST');
    });

    test('Sydney fall-back: 1st Sunday of April 2025 = April 6 03:00 local',
        () {
      // 03:00 AEDT (UTC+11) = 16:00 UTC on April 5.
      final justBefore = DateTime.utc(2025, 4, 5, 15, 59);
      final atBoundary = DateTime.utc(2025, 4, 5, 16);
      expect(syd.isDstActive(justBefore), isTrue);
      expect(syd.isDstActive(atBoundary), isFalse);
    });

    test('Sydney spring-forward: 1st Sunday of October 2025 = Oct 5 02:00 local',
        () {
      // 02:00 AEST (UTC+10) = 16:00 UTC on October 4.
      final justBefore = DateTime.utc(2025, 10, 4, 15, 59);
      final atBoundary = DateTime.utc(2025, 10, 4, 16);
      expect(syd.isDstActive(justBefore), isFalse);
      expect(syd.isDstActive(atBoundary), isTrue);
    });

    test('Auckland mid-January → NZDT (UTC+13)', () {
      final t = DateTime.utc(2025, 1, 15, 0);
      expect(akl.isDstActive(t), isTrue);
      expect(akl.currentOffset(t), const Duration(hours: 13));
      expect(akl.currentAbbreviation(t), 'NZDT');
    });

    test('Auckland mid-July → NZST (UTC+12)', () {
      final t = DateTime.utc(2025, 7, 15, 0);
      expect(akl.isDstActive(t), isFalse);
      expect(akl.currentOffset(t), const Duration(hours: 12));
    });
  });

  group('Non-DST zones never shift', () {
    test('Tokyo, Kolkata, Singapore, Honolulu, Dubai stay fixed all year', () {
      for (final id in ['tyo', 'kol', 'sin', 'hon', 'dxb', 'sao', 'jnb']) {
        final p = byId[id]!;
        expect(p.dstRule, DstRule.none, reason: '$id should have no DST rule');
        expect(p.isDstActive(DateTime.utc(2025, 1, 15)), isFalse);
        expect(p.isDstActive(DateTime.utc(2025, 7, 15)), isFalse);
        expect(p.currentOffset(DateTime.utc(2025, 7, 15)), p.utcOffset);
        expect(p.currentAbbreviation(), p.timeZoneName);
      }
    });
  });

  group('WorldClockService.nowInEntry', () {
    test('renders the right wall-clock instant in summer for NYC', () {
      // 2025-07-15 16:00 UTC == 12:00 EDT.
      final utc = DateTime.utc(2025, 7, 15, 16);
      final nyc = byId['nyc']!;
      final shown = WorldClockService.nowInEntry(nyc, utc);
      expect(shown.hour, 12);
      expect(shown.day, 15);
      expect(shown.month, 7);
    });

    test('renders the right wall-clock instant in winter for London', () {
      final utc = DateTime.utc(2025, 1, 15, 9);
      final lon = byId['lon']!;
      final shown = WorldClockService.nowInEntry(lon, utc);
      expect(shown.hour, 9);
    });
  });

  group('WorldClockService.formatCurrentOffset', () {
    test('shows UTC-4 for NYC in summer, UTC-5 in winter', () {
      final nyc = byId['nyc']!;
      expect(WorldClockService.formatCurrentOffset(
              nyc, DateTime.utc(2025, 7, 15, 12)),
          'UTC-4');
      expect(WorldClockService.formatCurrentOffset(
              nyc, DateTime.utc(2025, 1, 15, 12)),
          'UTC-5');
    });

    test('Kolkata always UTC+5:30', () {
      final kol = byId['kol']!;
      expect(WorldClockService.formatCurrentOffset(
              kol, DateTime.utc(2025, 7, 15, 12)),
          'UTC+5:30');
    });
  });

  group('WorldClockService.timeDiffFromLocal', () {
    test('reports "Same as local" when offsets match', () {
      expect(
        WorldClockService.timeDiffFromLocal(
          const Duration(hours: -8),
          localOffsetOverride: const Duration(hours: -8),
        ),
        'Same as local',
      );
    });

    test('formats positive whole-hour diff', () {
      // Target = UTC+5, local = UTC-8 => +13h.
      expect(
        WorldClockService.timeDiffFromLocal(
          const Duration(hours: 5),
          localOffsetOverride: const Duration(hours: -8),
        ),
        '+13h from local',
      );
    });

    test('formats negative whole-hour diff with explicit minus sign', () {
      // Target = UTC-8, local = UTC+0 => -8h. Previously printed "-8h";
      // still does, but the test pins the behaviour.
      expect(
        WorldClockService.timeDiffFromLocal(
          const Duration(hours: -8),
          localOffsetOverride: Duration.zero,
        ),
        '-8h from local',
      );
    });

    test('formats positive hour+minute diff (e.g. Kolkata from PST)', () {
      // Target = UTC+5:30, local = UTC-8 => +13h 30m.
      expect(
        WorldClockService.timeDiffFromLocal(
          const Duration(hours: 5, minutes: 30),
          localOffsetOverride: const Duration(hours: -8),
        ),
        '+13h 30m from local',
      );
    });

    test('regression: sub-hour negative diff keeps minus sign and omits 0h',
        () {
      // Target = UTC+0, local = UTC+0:30 => -30 minutes. Before the fix
      // this returned "0h 30m from local" with no sign at all, telling the
      // user nothing about the direction. After the fix we drop the empty
      // hours component and keep the minus sign.
      expect(
        WorldClockService.timeDiffFromLocal(
          Duration.zero,
          localOffsetOverride: const Duration(minutes: 30),
        ),
        '-30m from local',
      );
    });

    test('positive sub-hour diff also drops the 0h component', () {
      // Target = UTC+0:30, local = UTC+0 => +30m.
      expect(
        WorldClockService.timeDiffFromLocal(
          const Duration(minutes: 30),
          localOffsetOverride: Duration.zero,
        ),
        '+30m from local',
      );
    });

    test('negative diff with hour+minute components keeps minus on hour', () {
      // Target = UTC-9:30 (NMT), local = UTC+0 => -9h 30m.
      expect(
        WorldClockService.timeDiffFromLocal(
          const Duration(hours: -9, minutes: -30),
          localOffsetOverride: Duration.zero,
        ),
        '-9h 30m from local',
      );
    });

    test('timeDiffFromLocalForEntry uses DST-aware offset and override', () {
      final nyc =
          WorldClockService.presets.firstWhere((p) => p.id == 'nyc');
      // Mid-July => EDT (UTC-4). Local pinned to UTC+0 => -4h.
      expect(
        WorldClockService.timeDiffFromLocalForEntry(
          nyc,
          utcNow: DateTime.utc(2025, 7, 15, 12),
          localOffsetOverride: Duration.zero,
        ),
        '-4h from local',
      );
      // Mid-January => EST (UTC-5).
      expect(
        WorldClockService.timeDiffFromLocalForEntry(
          nyc,
          utcNow: DateTime.utc(2025, 1, 15, 12),
          localOffsetOverride: Duration.zero,
        ),
        '-5h from local',
      );
    });
  });

  group('WorldClockEntry JSON round-trip', () {
    test('preserves dstRule', () {
      final original = byId['nyc']!;
      final restored =
          WorldClockEntry.fromJson(Map<String, dynamic>.from(original.toJson()));
      expect(restored.id, original.id);
      expect(restored.dstRule, DstRule.usNorthAmerica);
      expect(restored.utcOffset, original.utcOffset);
    });

    test('legacy JSON without dstRule decodes as no-DST', () {
      final legacy = {
        'id': 'legacy',
        'label': 'Legacy',
        'timeZoneName': 'XYZ',
        'utcOffsetMinutes': 60,
        'emoji': null,
      };
      final restored = WorldClockEntry.fromJson(legacy);
      expect(restored.dstRule, DstRule.none);
      expect(restored.utcOffset, const Duration(hours: 1));
    });

    test('unknown dstRule name falls back to none', () {
      final exotic = {
        'id': 'exotic',
        'label': 'Exotic',
        'timeZoneName': 'XYZ',
        'utcOffsetMinutes': 0,
        'emoji': null,
        'dstRule': 'someRuleThatDoesNotExist',
      };
      expect(WorldClockEntry.fromJson(exotic).dstRule, DstRule.none);
    });
  });
}
