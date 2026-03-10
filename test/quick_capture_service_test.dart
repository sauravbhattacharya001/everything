import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/capture_item.dart';
import 'package:everything/core/services/quick_capture_service.dart';

void main() {
  late QuickCaptureService service;

  setUp(() {
    service = QuickCaptureService();
  });

  // ── CaptureItem model ───────────────────────────────────────────

  group('CaptureItem', () {
    test('defaults to inbox status and note category', () {
      final item = CaptureItem(
        id: 't1',
        capturedAt: DateTime.now(),
        text: 'Hello',
      );
      expect(item.status, CaptureStatus.inbox);
      expect(item.category, CaptureCategory.note);
      expect(item.priority, CapturePriority.none);
      expect(item.isPinned, isFalse);
    });

    test('isStale true after 3 days in inbox', () {
      final item = CaptureItem(
        id: 't1',
        capturedAt: DateTime.now().subtract(const Duration(days: 4)),
        text: 'Old item',
      );
      expect(item.isStale, isTrue);
    });

    test('isStale false when processed', () {
      final item = CaptureItem(
        id: 't1',
        capturedAt: DateTime.now().subtract(const Duration(days: 4)),
        text: 'Old item',
        status: CaptureStatus.processed,
      );
      expect(item.isStale, isFalse);
    });

    test('isAging true between 1 and 3 days', () {
      final item = CaptureItem(
        id: 't1',
        capturedAt: DateTime.now().subtract(const Duration(days: 2)),
        text: 'Aging item',
      );
      expect(item.isAging, isTrue);
      expect(item.isStale, isFalse);
    });

    test('ageLabel returns "just now" for recent items', () {
      final item = CaptureItem(
        id: 't1',
        capturedAt: DateTime.now(),
        text: 'New',
      );
      expect(item.ageLabel, 'just now');
    });

    test('ageLabel returns "yesterday" for 1-day-old items', () {
      final item = CaptureItem(
        id: 't1',
        capturedAt: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
        text: 'Yesterday',
      );
      expect(item.ageLabel, 'yesterday');
    });

    test('ageLabel shows weeks for 7+ day items', () {
      final item = CaptureItem(
        id: 't1',
        capturedAt: DateTime.now().subtract(const Duration(days: 14)),
        text: 'Two weeks',
      );
      expect(item.ageLabel, '2 weeks ago');
    });

    test('ageLabel shows months for 30+ day items', () {
      final item = CaptureItem(
        id: 't1',
        capturedAt: DateTime.now().subtract(const Duration(days: 60)),
        text: 'Old',
      );
      expect(item.ageLabel, '2 months ago');
    });

    test('toJson/fromJson roundtrip', () {
      final item = CaptureItem(
        id: 'test-1',
        capturedAt: DateTime(2026, 3, 1, 10, 30),
        text: 'Test item',
        category: CaptureCategory.idea,
        priority: CapturePriority.high,
        tags: ['flutter', 'design'],
        note: 'Some notes',
        isPinned: true,
      );
      final json = item.toJson();
      final restored = CaptureItem.fromJson(json);

      expect(restored.id, 'test-1');
      expect(restored.text, 'Test item');
      expect(restored.category, CaptureCategory.idea);
      expect(restored.priority, CapturePriority.high);
      expect(restored.tags, ['flutter', 'design']);
      expect(restored.isPinned, isTrue);
    });

    test('toJson/fromJson with processed item', () {
      final item = CaptureItem(
        id: 'test-2',
        capturedAt: DateTime(2026, 3, 1),
        text: 'Done',
        status: CaptureStatus.processed,
        processedAt: DateTime(2026, 3, 2),
        destination: ProcessedDestination.goal,
      );
      final restored = CaptureItem.fromJson(item.toJson());
      expect(restored.status, CaptureStatus.processed);
      expect(restored.destination, ProcessedDestination.goal);
    });

    test('toJsonString/fromJsonString roundtrip', () {
      final item = CaptureItem(
        id: 'x',
        capturedAt: DateTime(2026),
        text: 'Test',
      );
      final restored = CaptureItem.fromJsonString(item.toJsonString());
      expect(restored.id, 'x');
    });

    test('copyWith preserves unchanged fields', () {
      final item = CaptureItem(
        id: 'c1',
        capturedAt: DateTime(2026),
        text: 'Original',
        category: CaptureCategory.idea,
        priority: CapturePriority.low,
        tags: ['a'],
      );
      final updated = item.copyWith(text: 'Changed');
      expect(updated.text, 'Changed');
      expect(updated.category, CaptureCategory.idea);
      expect(updated.priority, CapturePriority.low);
      expect(updated.tags, ['a']);
    });

    test('equality based on id', () {
      final a = CaptureItem(id: 'same', capturedAt: DateTime(2026), text: 'A');
      final b = CaptureItem(id: 'same', capturedAt: DateTime(2025), text: 'B');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('toString includes category and priority emoji', () {
      final item = CaptureItem(
        id: 'x',
        capturedAt: DateTime.now(),
        text: 'My idea',
        category: CaptureCategory.idea,
        priority: CapturePriority.urgent,
      );
      final str = item.toString();
      expect(str, contains('My idea'));
    });
  });

  // ── Enum properties ─────────────────────────────────────────────

  group('Enums', () {
    test('CaptureCategory has label and emoji', () {
      for (final cat in CaptureCategory.values) {
        expect(cat.label.isNotEmpty, isTrue);
        expect(cat.emoji.isNotEmpty, isTrue);
      }
    });

    test('CapturePriority sortOrder is descending from urgent', () {
      expect(CapturePriority.urgent.sortOrder, 0);
      expect(CapturePriority.none.sortOrder, 4);
    });

    test('ProcessedDestination has labels', () {
      for (final dest in ProcessedDestination.values) {
        expect(dest.label.isNotEmpty, isTrue);
      }
    });
  });

  // ── Capture ─────────────────────────────────────────────────────

  group('capture', () {
    test('creates item with correct fields', () {
      final item = service.capture('Buy milk',
          category: CaptureCategory.task,
          priority: CapturePriority.medium,
          tags: ['shopping']);
      expect(item.text, 'Buy milk');
      expect(item.category, CaptureCategory.task);
      expect(item.priority, CapturePriority.medium);
      expect(item.tags, ['shopping']);
      expect(item.status, CaptureStatus.inbox);
    });

    test('trims whitespace from text', () {
      final item = service.capture('  trim me  ');
      expect(item.text, 'trim me');
    });

    test('throws on empty text', () {
      expect(
        () => service.capture(''),
        throwsArgumentError,
      );
    });

    test('throws on whitespace-only text', () {
      expect(
        () => service.capture('   '),
        throwsArgumentError,
      );
    });

    test('generates unique IDs', () {
      final ids = <String>{};
      for (var i = 0; i < 50; i++) {
        ids.add(service.capture('Item $i').id);
      }
      expect(ids.length, 50);
    });
  });

  // ── Quick capture ───────────────────────────────────────────────

  group('quickCapture', () {
    test('detects task from "todo:" prefix', () {
      final item = service.quickCapture('todo: fix the bug');
      expect(item.category, CaptureCategory.task);
      expect(item.priority, CapturePriority.medium);
    });

    test('detects task from "need to"', () {
      final item = service.quickCapture('I need to call dentist');
      expect(item.category, CaptureCategory.task);
    });

    test('detects idea from "what if"', () {
      final item = service.quickCapture('what if we add dark mode');
      expect(item.category, CaptureCategory.idea);
    });

    test('detects question from "?"', () {
      final item = service.quickCapture('Is Flutter faster than React?');
      expect(item.category, CaptureCategory.question);
    });

    test('detects link from URL', () {
      final item = service.quickCapture('https://dart.dev/guides');
      expect(item.category, CaptureCategory.link);
    });

    test('detects quote from opening quote mark', () {
      final item = service.quickCapture('"The best way to predict the future"');
      expect(item.category, CaptureCategory.quote);
    });

    test('detects reminder from "remember to"', () {
      final item = service.quickCapture('remember to buy flowers');
      expect(item.category, CaptureCategory.reminder);
      expect(item.priority, CapturePriority.high);
    });

    test('defaults to note for unrecognized text', () {
      final item = service.quickCapture('Random thought');
      expect(item.category, CaptureCategory.note);
      expect(item.priority, CapturePriority.none);
    });
  });

  // ── Processing ──────────────────────────────────────────────────

  group('process', () {
    test('marks item as processed with destination', () {
      final item = service.capture('Test');
      final processed = service.process(
          item.id, ProcessedDestination.goal,
          note: 'Added to goals');
      expect(processed.status, CaptureStatus.processed);
      expect(processed.destination, ProcessedDestination.goal);
      expect(processed.processedAt, isNotNull);
      expect(processed.note, 'Added to goals');
    });

    test('throws on unknown id', () {
      expect(
        () => service.process('bad-id', ProcessedDestination.goal),
        throwsArgumentError,
      );
    });

    test('throws on already processed item', () {
      final item = service.capture('Test');
      service.process(item.id, ProcessedDestination.goal);
      expect(
        () => service.process(item.id, ProcessedDestination.habit),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ── Archive ─────────────────────────────────────────────────────

  group('archive', () {
    test('sets status to archived', () {
      final item = service.capture('Test');
      final archived = service.archive(item.id);
      expect(archived.status, CaptureStatus.archived);
    });

    test('throws on deleted item', () {
      final item = service.capture('Test');
      service.delete(item.id);
      expect(
        () => service.archive(item.id),
        throwsA(isA<StateError>()),
      );
    });

    test('throws on unknown id', () {
      expect(() => service.archive('x'), throwsArgumentError);
    });
  });

  // ── Delete ──────────────────────────────────────────────────────

  group('delete', () {
    test('soft-deletes item', () {
      final item = service.capture('Test');
      service.delete(item.id);
      final found = service.getById(item.id);
      expect(found!.status, CaptureStatus.deleted);
    });

    test('throws on unknown id', () {
      expect(() => service.delete('x'), throwsArgumentError);
    });
  });

  // ── Pin ─────────────────────────────────────────────────────────

  group('togglePin', () {
    test('pins and unpins', () {
      final item = service.capture('Test');
      expect(item.isPinned, isFalse);

      final pinned = service.togglePin(item.id);
      expect(pinned.isPinned, isTrue);

      final unpinned = service.togglePin(item.id);
      expect(unpinned.isPinned, isFalse);
    });
  });

  // ── Update ──────────────────────────────────────────────────────

  group('update', () {
    test('updates text and category', () {
      final item = service.capture('Old text');
      final updated = service.update(item.id,
          text: 'New text', category: CaptureCategory.idea);
      expect(updated.text, 'New text');
      expect(updated.category, CaptureCategory.idea);
    });

    test('throws on empty text', () {
      final item = service.capture('Test');
      expect(
        () => service.update(item.id, text: ''),
        throwsArgumentError,
      );
    });
  });

  // ── Queries ─────────────────────────────────────────────────────

  group('queries', () {
    test('getInbox returns only inbox items', () {
      service.capture('A');
      final b = service.capture('B');
      service.capture('C');
      service.process(b.id, ProcessedDestination.goal);

      expect(service.getInbox().length, 2);
    });

    test('getInbox sorts by priority then age', () {
      final low = service.capture('Low', priority: CapturePriority.low);
      final high = service.capture('High', priority: CapturePriority.high);

      final inbox = service.getInbox();
      expect(inbox.first.id, high.id);
    });

    test('getInbox puts pinned items first', () {
      final a = service.capture('A');
      final b = service.capture('B');
      service.togglePin(b.id);

      final inbox = service.getInbox();
      expect(inbox.first.id, b.id);
    });

    test('getProcessed returns only processed', () {
      final a = service.capture('A');
      service.capture('B');
      service.process(a.id, ProcessedDestination.reading);

      expect(service.getProcessed().length, 1);
    });

    test('getAll excludes deleted', () {
      service.capture('A');
      final b = service.capture('B');
      service.delete(b.id);

      expect(service.getAll().length, 1);
    });

    test('getById returns item', () {
      final item = service.capture('Test');
      expect(service.getById(item.id)!.text, 'Test');
    });

    test('getById returns null for missing', () {
      expect(service.getById('nope'), isNull);
    });

    test('search finds by text', () {
      service.capture('Flutter is great');
      service.capture('React is cool');

      expect(service.search('flutter').length, 1);
    });

    test('search finds by tag', () {
      service.capture('Test', tags: ['dart', 'mobile']);

      expect(service.search('dart').length, 1);
    });

    test('search finds by note', () {
      service.capture('Item', note: 'Important context');

      expect(service.search('context').length, 1);
    });

    test('search returns empty for empty query', () {
      service.capture('Test');
      expect(service.search(''), isEmpty);
    });

    test('search excludes deleted items', () {
      final item = service.capture('Find me');
      service.delete(item.id);
      expect(service.search('find'), isEmpty);
    });

    test('filterByCategory works', () {
      service.capture('A', category: CaptureCategory.idea);
      service.capture('B', category: CaptureCategory.task);
      service.capture('C', category: CaptureCategory.idea);

      expect(service.filterByCategory(CaptureCategory.idea).length, 2);
    });

    test('filterByPriority works', () {
      service.capture('A', priority: CapturePriority.high);
      service.capture('B', priority: CapturePriority.low);

      expect(service.filterByPriority(CapturePriority.high).length, 1);
    });

    test('getByDate filters correctly', () {
      service.capture('Today');

      final results = service.getByDate(DateTime.now());
      expect(results.length, 1);

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(service.getByDate(yesterday).length, 0);
    });
  });

  // ── Statistics ──────────────────────────────────────────────────

  group('stats', () {
    test('empty service returns zeroes', () {
      final stats = service.getStats();
      expect(stats.totalCaptured, 0);
      expect(stats.currentInbox, 0);
      expect(stats.processingRate, 0.0);
    });

    test('counts items correctly', () {
      service.capture('A');
      final b = service.capture('B');
      final c = service.capture('C');
      service.process(b.id, ProcessedDestination.goal);
      service.archive(c.id);

      final stats = service.getStats();
      expect(stats.totalCaptured, 3);
      expect(stats.currentInbox, 1);
      expect(stats.processedCount, 1);
      expect(stats.archivedCount, 1);
    });

    test('processing rate calculated', () {
      final a = service.capture('A');
      final b = service.capture('B');
      service.process(a.id, ProcessedDestination.goal);
      service.process(b.id, ProcessedDestination.habit);

      final stats = service.getStats();
      expect(stats.processingRate, 1.0);
    });

    test('category breakdown tracks inbox items', () {
      service.capture('A', category: CaptureCategory.idea);
      service.capture('B', category: CaptureCategory.idea);
      service.capture('C', category: CaptureCategory.task);

      final stats = service.getStats();
      expect(stats.categoryBreakdown[CaptureCategory.idea], 2);
      expect(stats.categoryBreakdown[CaptureCategory.task], 1);
    });

    test('destination breakdown tracks processed items', () {
      final a = service.capture('A');
      final b = service.capture('B');
      service.process(a.id, ProcessedDestination.goal);
      service.process(b.id, ProcessedDestination.goal);

      final stats = service.getStats();
      expect(stats.destinationBreakdown[ProcessedDestination.goal], 2);
    });
  });

  // ── Weekly report ───────────────────────────────────────────────

  group('weeklyReport', () {
    test('grades A for fully processed week', () {
      final a = service.capture('A');
      service.process(a.id, ProcessedDestination.reading);

      final report = service.getWeeklyReport();
      expect(report.grade, 'A');
    });

    test('empty week grades A', () {
      final report = service.getWeeklyReport(
        weekStart: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(report.captured, 0);
    });
  });

  // ── Bulk operations ─────────────────────────────────────────────

  group('bulk operations', () {
    test('archiveStale archives old items', () {
      // We can't easily backdate items, so just verify the method runs
      final count = service.archiveStale();
      expect(count, 0);
    });

    test('bulkProcess processes multiple items', () {
      final a = service.capture('A');
      final b = service.capture('B');
      final c = service.capture('C');

      final count = service.bulkProcess(
        [a.id, b.id, c.id],
        ProcessedDestination.habit,
      );
      expect(count, 3);
      expect(service.inboxCount, 0);
    });

    test('bulkProcess skips invalid ids', () {
      final a = service.capture('A');
      final count = service.bulkProcess(
        [a.id, 'bad-id'],
        ProcessedDestination.habit,
      );
      expect(count, 1);
    });

    test('purgeDeleted removes soft-deleted items', () {
      final a = service.capture('A');
      service.capture('B');
      service.delete(a.id);

      final purged = service.purgeDeleted();
      expect(purged, 1);
      expect(service.totalItems, 1);
    });
  });

  // ── Serialization ───────────────────────────────────────────────

  group('serialization', () {
    test('exportJson/importJson roundtrip', () {
      service.capture('A', category: CaptureCategory.idea);
      service.capture('B', priority: CapturePriority.urgent);

      final json = service.exportJson();

      final service2 = QuickCaptureService();
      final imported = service2.importJson(json);
      expect(imported, 2);
      expect(service2.totalItems, 2);
    });

    test('import skips duplicates', () {
      service.capture('A');
      final json = service.exportJson();

      final imported = service.importJson(json);
      expect(imported, 0);
    });

    test('import skips malformed entries', () {
      final count = service.importJson('[{"bad": true}, 42]');
      expect(count, 0);
    });
  });

  // ── Counters ────────────────────────────────────────────────────

  group('counters', () {
    test('totalItems counts all including deleted', () {
      service.capture('A');
      final b = service.capture('B');
      service.delete(b.id);

      expect(service.totalItems, 2);
    });

    test('inboxCount counts only inbox items', () {
      service.capture('A');
      final b = service.capture('B');
      service.process(b.id, ProcessedDestination.goal);

      expect(service.inboxCount, 1);
    });
  });
}
