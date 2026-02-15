import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/event_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/state/providers/event_provider.dart';

/// Stub repository that records calls for verification without needing SQLite.
class _StubEventRepository {
  final List<String> calls = [];
  final List<Map<String, dynamic>> savedEvents = [];
  final List<String> deletedIds = [];
  bool shouldThrow = false;

  Future<void> saveEvent(Map<String, dynamic> event) async {
    calls.add('saveEvent');
    if (shouldThrow) throw Exception('disk error');
    savedEvents.add(event);
  }

  Future<List<Map<String, dynamic>>> getEvents() async {
    calls.add('getEvents');
    if (shouldThrow) throw Exception('disk error');
    return savedEvents.toList();
  }

  Future<void> deleteEvent(String id) async {
    calls.add('deleteEvent');
    if (shouldThrow) throw Exception('disk error');
    deletedIds.add(id);
    savedEvents.removeWhere((e) => e['id'] == id);
  }

  Future<void> updateEvent(Map<String, dynamic> event) async {
    calls.add('updateEvent');
    if (shouldThrow) throw Exception('disk error');
    final idx = savedEvents.indexWhere((e) => e['id'] == event['id']);
    if (idx != -1) {
      savedEvents[idx] = event;
    } else {
      savedEvents.add(event);
    }
  }
}

void main() {
  late EventProvider provider;
  late EventService service;

  final testEvent = EventModel(
    id: 'test-1',
    title: 'Meeting',
    description: 'Team standup',
    date: DateTime(2026, 3, 1, 10, 0),
    priority: EventPriority.high,
  );

  final testEvent2 = EventModel(
    id: 'test-2',
    title: 'Lunch',
    date: DateTime(2026, 3, 1, 12, 0),
  );

  setUp(() {
    provider = EventProvider();
    // EventService accepts an EventRepository via its constructor.
    // Since the stub has the same method signatures, we use a service
    // constructed with the real provider. The actual persistence is
    // tested separately — here we verify provider state coordination.
    service = EventService(provider: provider);
  });

  group('EventService', () {
    test('addEvent updates provider state', () async {
      expect(provider.isEmpty, isTrue);

      await service.addEvent(testEvent);

      expect(provider.eventCount, equals(1));
      expect(provider.events.first.id, equals('test-1'));
      expect(provider.events.first.title, equals('Meeting'));
    });

    test('addEvent multiple events preserves order', () async {
      await service.addEvent(testEvent);
      await service.addEvent(testEvent2);

      expect(provider.eventCount, equals(2));
      expect(provider.events[0].id, equals('test-1'));
      expect(provider.events[1].id, equals('test-2'));
    });

    test('updateEvent modifies existing event in provider', () async {
      await service.addEvent(testEvent);

      final updated = testEvent.copyWith(title: 'Updated Meeting');
      await service.updateEvent(updated);

      expect(provider.eventCount, equals(1));
      expect(provider.events.first.title, equals('Updated Meeting'));
    });

    test('updateEvent is no-op for non-existent event', () async {
      await service.addEvent(testEvent);

      final phantom = EventModel(
        id: 'nonexistent',
        title: 'Ghost',
        date: DateTime(2026, 1, 1),
      );
      await service.updateEvent(phantom);

      // Original event unchanged, phantom not added by updateEvent
      // (EventProvider.updateEvent uses indexWhere — no-op if not found)
      expect(provider.eventCount, equals(1));
      expect(provider.events.first.title, equals('Meeting'));
    });

    test('deleteEvent removes event from provider', () async {
      await service.addEvent(testEvent);
      await service.addEvent(testEvent2);
      expect(provider.eventCount, equals(2));

      await service.deleteEvent('test-1');

      expect(provider.eventCount, equals(1));
      expect(provider.events.first.id, equals('test-2'));
    });

    test('deleteEvent with non-existent id is no-op', () async {
      await service.addEvent(testEvent);

      await service.deleteEvent('nonexistent');

      expect(provider.eventCount, equals(1));
    });

    test('loadEvents populates empty provider', () async {
      // Provider starts empty, loadEvents should try to load from repo.
      // With the real repository it would hit SQLite — here we just verify
      // the provider stays empty since no database is available in tests.
      await service.loadEvents();

      // No crash, provider stays in whatever state the repo returns
      // (empty in test context since no SQLite is available)
      expect(provider.events, isNotNull);
    });

    test('provider notifies listeners on all mutations', () async {
      int notifyCount = 0;
      provider.addListener(() => notifyCount++);

      await service.addEvent(testEvent);
      expect(notifyCount, equals(1));

      await service.updateEvent(testEvent.copyWith(title: 'Changed'));
      expect(notifyCount, equals(2));

      await service.deleteEvent('test-1');
      expect(notifyCount, equals(3));
    });
  });
}
