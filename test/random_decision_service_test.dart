import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/random_decision_service.dart';
import 'package:everything/models/decision_list.dart';

void main() {
  late RandomDecisionService service;

  setUp(() {
    service = RandomDecisionService();
  });

  // ── List creation ───────────────────────────────────────────────

  group('createList', () {
    test('creates a list with title and options', () {
      final list = service.createList(
        title: 'Lunch',
        options: ['Pizza', 'Sushi', 'Tacos'],
      );
      expect(list.title, 'Lunch');
      expect(list.options.length, 3);
      expect(list.options[0].text, 'Pizza');
      expect(list.options[1].text, 'Sushi');
      expect(list.options[2].text, 'Tacos');
      expect(list.history, isEmpty);
    });

    test('creates a list with emoji', () {
      final list = service.createList(title: 'Food', emoji: '🍕');
      expect(list.emoji, '🍕');
    });

    test('creates an empty list when no options given', () {
      final list = service.createList(title: 'Empty');
      expect(list.options, isEmpty);
    });

    test('list appears in service lists', () {
      expect(service.lists, isEmpty);
      service.createList(title: 'Test');
      expect(service.lists.length, 1);
    });
  });

  // ── List deletion ─────────────────────────────────────────────

  group('deleteList', () {
    test('removes a list by id', () {
      final list = service.createList(title: 'Temp');
      expect(service.lists.length, 1);
      service.deleteList(list.id);
      expect(service.lists, isEmpty);
    });

    test('no-op for non-existent id', () {
      service.createList(title: 'Keep');
      service.deleteList('nonexistent');
      expect(service.lists.length, 1);
    });
  });

  // ── Option management ─────────────────────────────────────────

  group('addOption', () {
    test('adds an option to an existing list', () {
      final list = service.createList(title: 'Test');
      service.addOption(list.id, 'Option A');
      expect(service.lists.first.options.length, 1);
      expect(service.lists.first.options.first.text, 'Option A');
    });

    test('adds an option with weight', () {
      final list = service.createList(title: 'Test');
      service.addOption(list.id, 'Heavy', weight: 5);
      expect(service.lists.first.options.first.weight, 5);
    });

    test('no-op for non-existent list', () {
      service.addOption('fake', 'Option A');
      // no error thrown
    });
  });

  group('removeOption', () {
    test('removes an option by id', () {
      final list = service.createList(title: 'Test', options: ['A', 'B']);
      final optionId = service.lists.first.options.first.id;
      service.removeOption(list.id, optionId);
      expect(service.lists.first.options.length, 1);
      expect(service.lists.first.options.first.text, 'B');
    });

    test('no-op for non-existent option', () {
      final list = service.createList(title: 'Test', options: ['A']);
      service.removeOption(list.id, 'fake');
      expect(service.lists.first.options.length, 1);
    });
  });

  group('updateOption', () {
    test('updates option text', () {
      final list = service.createList(title: 'Test', options: ['Old']);
      final optionId = service.lists.first.options.first.id;
      service.updateOption(list.id, optionId, text: 'New');
      expect(service.lists.first.options.first.text, 'New');
    });

    test('updates option weight', () {
      final list = service.createList(title: 'Test', options: ['A']);
      final optionId = service.lists.first.options.first.id;
      service.updateOption(list.id, optionId, weight: 10);
      expect(service.lists.first.options.first.weight, 10);
    });

    test('no-op for non-existent list', () {
      service.updateOption('fake', 'fake', text: 'New');
      // no error thrown
    });
  });

  // ── Spin (random selection) ───────────────────────────────────

  group('spin', () {
    test('returns null for non-existent list', () {
      expect(service.spin('fake'), isNull);
    });

    test('returns null for empty list', () {
      final list = service.createList(title: 'Empty');
      expect(service.spin(list.id), isNull);
    });

    test('returns a result from the list options', () {
      final list = service.createList(
        title: 'Test',
        options: ['A', 'B', 'C'],
      );
      final result = service.spin(list.id);
      expect(result, isNotNull);
      expect(['A', 'B', 'C'], contains(result!.optionText));
    });

    test('adds result to history', () {
      final list = service.createList(title: 'Test', options: ['A']);
      service.spin(list.id);
      expect(service.lists.first.history.length, 1);
    });

    test('single option always returns that option', () {
      final list = service.createList(title: 'Solo', options: ['Only']);
      for (var i = 0; i < 10; i++) {
        final result = service.spin(list.id);
        expect(result!.optionText, 'Only');
      }
    });

    test('weighted selection respects weights', () {
      final list = service.createList(title: 'Weighted');
      // Add one option with weight 1000 and another with weight 1
      service.addOption(list.id, 'Heavy', weight: 1000);
      service.addOption(list.id, 'Light', weight: 1);

      // Spin many times — Heavy should win overwhelmingly
      final counts = <String, int>{};
      for (var i = 0; i < 100; i++) {
        final result = service.spin(list.id);
        counts[result!.optionText] = (counts[result.optionText] ?? 0) + 1;
      }
      expect(counts['Heavy']!, greaterThan(80));
    });
  });

  // ── History ───────────────────────────────────────────────────

  group('history', () {
    test('getHistory returns empty for non-existent list', () {
      expect(service.getHistory('fake'), isEmpty);
    });

    test('getHistory returns results in reverse chronological order', () {
      final list = service.createList(title: 'Test', options: ['A', 'B']);
      service.spin(list.id);
      service.spin(list.id);
      final history = service.getHistory(list.id);
      expect(history.length, 2);
      // Most recent first
      expect(
        history.first.decidedAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(history.last.decidedAt.millisecondsSinceEpoch),
      );
    });

    test('clearHistory removes all history', () {
      final list = service.createList(title: 'Test', options: ['A']);
      service.spin(list.id);
      service.spin(list.id);
      expect(service.getHistory(list.id).length, 2);
      service.clearHistory(list.id);
      expect(service.getHistory(list.id), isEmpty);
    });

    test('clearHistory no-op for non-existent list', () {
      service.clearHistory('fake');
      // no error thrown
    });
  });

  // ── Frequency stats ───────────────────────────────────────────

  group('getFrequencyStats', () {
    test('returns empty map for non-existent list', () {
      expect(service.getFrequencyStats('fake'), isEmpty);
    });

    test('counts option frequency correctly', () {
      final list = service.createList(title: 'Solo', options: ['A']);
      service.spin(list.id);
      service.spin(list.id);
      service.spin(list.id);
      final stats = service.getFrequencyStats(list.id);
      expect(stats['A'], 3);
    });
  });

  // ── Templates ─────────────────────────────────────────────────

  group('templates', () {
    test('has preset templates', () {
      expect(RandomDecisionService.templates, isNotEmpty);
      expect(RandomDecisionService.templates.containsKey('🍽️ Where to Eat'), isTrue);
    });

    test('createFromTemplate creates a working list', () {
      final list = service.createFromTemplate('🍽️ Where to Eat');
      expect(list.title, '🍽️ Where to Eat');
      expect(list.options.length, 8);
      // Should be spinnable
      final result = service.spin(list.id);
      expect(result, isNotNull);
    });

    test('createFromTemplate with unknown template creates empty list', () {
      final list = service.createFromTemplate('Unknown');
      expect(list.options, isEmpty);
    });
  });

  // ── DecisionList model ────────────────────────────────────────

  group('DecisionOption', () {
    test('default weight is 1', () {
      const option = DecisionOption(id: 'o1', text: 'Test');
      expect(option.weight, 1);
      expect(option.emoji, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      const option = DecisionOption(id: 'o1', text: 'Original', weight: 3);
      final copy = option.copyWith(text: 'Updated');
      expect(copy.id, 'o1');
      expect(copy.text, 'Updated');
      expect(copy.weight, 3);
    });
  });

  group('DecisionList', () {
    test('copyWith preserves unchanged fields', () {
      final list = DecisionList(
        id: 'l1',
        title: 'Original',
        options: const [],
        createdAt: DateTime(2026),
      );
      final copy = list.copyWith(title: 'Updated');
      expect(copy.id, 'l1');
      expect(copy.title, 'Updated');
      expect(copy.options, isEmpty);
      expect(copy.createdAt, DateTime(2026));
    });
  });
}
