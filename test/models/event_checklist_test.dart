import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/event_checklist.dart';

void main() {
  // ============================================================
  // ChecklistItem Tests
  // ============================================================

  group('ChecklistItem', () {
    test('create factory generates unique IDs', () {
      final a = ChecklistItem.create(title: 'A');
      // Small delay to ensure different microsecond timestamps
      final b = ChecklistItem.create(title: 'B');
      expect(a.id, isNot(equals(b.id)));
    });

    test('create sets defaults correctly', () {
      final item = ChecklistItem.create(title: 'Test');
      expect(item.title, 'Test');
      expect(item.note, '');
      expect(item.completed, false);
      expect(item.completedAt, isNull);
    });

    test('create with note', () {
      final item = ChecklistItem.create(title: 'Task', note: 'Some detail');
      expect(item.note, 'Some detail');
    });

    test('toggleCompleted sets completed true and completedAt', () {
      final item = ChecklistItem.create(title: 'Task');
      final toggled = item.toggleCompleted();
      expect(toggled.completed, true);
      expect(toggled.completedAt, isNotNull);
    });

    test('toggleCompleted twice returns to uncompleted', () {
      final item = ChecklistItem.create(title: 'Task');
      final toggled = item.toggleCompleted().toggleCompleted();
      expect(toggled.completed, false);
      expect(toggled.completedAt, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      final item = ChecklistItem(
        id: '1',
        title: 'Original',
        note: 'Note',
        completed: true,
        completedAt: DateTime(2026, 1, 1),
      );
      final copy = item.copyWith(title: 'Changed');
      expect(copy.id, '1');
      expect(copy.title, 'Changed');
      expect(copy.note, 'Note');
      expect(copy.completed, true);
    });

    test('copyWith clearCompletedAt', () {
      final item = ChecklistItem(
        id: '1',
        title: 'Task',
        completed: false,
        completedAt: DateTime(2026, 1, 1),
      );
      final cleared = item.copyWith(clearCompletedAt: true);
      expect(cleared.completedAt, isNull);
    });

    test('toJson produces correct map', () {
      final item = ChecklistItem(
        id: '42',
        title: 'Buy milk',
        note: 'Whole milk',
        completed: true,
        createdAt: DateTime.utc(2026, 2, 22, 12, 0),
        completedAt: DateTime.utc(2026, 2, 22, 13, 0),
      );
      final json = item.toJson();
      expect(json['id'], '42');
      expect(json['title'], 'Buy milk');
      expect(json['note'], 'Whole milk');
      expect(json['completed'], true);
      expect(json['createdAt'], contains('2026-02-22'));
      expect(json['completedAt'], contains('2026-02-22'));
    });

    test('toJson omits completedAt when null', () {
      final item = ChecklistItem.create(title: 'Task');
      final json = item.toJson();
      expect(json.containsKey('completedAt'), false);
    });

    test('fromJson round-trips correctly', () {
      final original = ChecklistItem(
        id: '99',
        title: 'Pack bags',
        note: 'Check weather first',
        completed: true,
        createdAt: DateTime.utc(2026, 3, 1),
        completedAt: DateTime.utc(2026, 3, 2),
      );
      final json = original.toJson();
      final restored = ChecklistItem.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.note, original.note);
      expect(restored.completed, original.completed);
    });

    test('fromJson handles missing optional fields', () {
      final json = {'title': 'Minimal'};
      final item = ChecklistItem.fromJson(json);
      expect(item.title, 'Minimal');
      expect(item.note, '');
      expect(item.completed, false);
      expect(item.completedAt, isNull);
    });

    test('equality by id, title, note, completed', () {
      final a = ChecklistItem(id: '1', title: 'X', note: 'N', completed: false);
      final b = ChecklistItem(id: '1', title: 'X', note: 'N', completed: false);
      expect(a, equals(b));
    });

    test('inequality when completed differs', () {
      final a = ChecklistItem(id: '1', title: 'X', completed: false);
      final b = ChecklistItem(id: '1', title: 'X', completed: true);
      expect(a, isNot(equals(b)));
    });

    test('toString includes key info', () {
      final item = ChecklistItem(id: '1', title: 'Test', completed: true);
      expect(item.toString(), contains('Test'));
      expect(item.toString(), contains('true'));
    });
  });

  // ============================================================
  // EventChecklist Tests
  // ============================================================

  group('EventChecklist', () {
    group('construction', () {
      test('empty checklist has no items', () {
        const cl = EventChecklist.empty;
        expect(cl.hasItems, false);
        expect(cl.totalCount, 0);
      });

      test('constructor with items', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A'),
          ChecklistItem(id: '2', title: 'B'),
        ]);
        expect(cl.totalCount, 2);
        expect(cl.hasItems, true);
      });
    });

    group('addItem', () {
      test('adds item to end', () {
        var cl = const EventChecklist();
        cl = cl.addItem(ChecklistItem(id: '1', title: 'First'));
        cl = cl.addItem(ChecklistItem(id: '2', title: 'Second'));
        expect(cl.totalCount, 2);
        expect(cl.items.last.title, 'Second');
      });

      test('respects max items limit', () {
        var cl = const EventChecklist();
        for (var i = 0; i < EventChecklist.maxItems; i++) {
          cl = cl.addItem(ChecklistItem(id: '$i', title: 'Item $i'));
        }
        expect(cl.totalCount, EventChecklist.maxItems);

        // Adding one more should be ignored
        cl = cl.addItem(ChecklistItem(id: 'overflow', title: 'Too many'));
        expect(cl.totalCount, EventChecklist.maxItems);
      });
    });

    group('removeItem', () {
      test('removes by ID', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A'),
          ChecklistItem(id: '2', title: 'B'),
          ChecklistItem(id: '3', title: 'C'),
        ]);
        final result = cl.removeItem('2');
        expect(result.totalCount, 2);
        expect(result.items.map((i) => i.id).toList(), ['1', '3']);
      });

      test('removing non-existent ID returns same', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A'),
        ]);
        final result = cl.removeItem('999');
        expect(result.totalCount, 1);
      });
    });

    group('toggleItem', () {
      test('toggles completion status', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'Task', completed: false),
        ]);
        final toggled = cl.toggleItem('1');
        expect(toggled.items.first.completed, true);
      });

      test('toggle non-existent ID is safe', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'Task'),
        ]);
        final result = cl.toggleItem('999');
        expect(result.items.first.completed, false);
      });
    });

    group('updateItem', () {
      test('replaces item by ID', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'Old'),
        ]);
        final updated = cl.updateItem(
          '1',
          ChecklistItem(id: '1', title: 'New'),
        );
        expect(updated.items.first.title, 'New');
      });
    });

    group('reorderItem', () {
      test('moves item from old to new index', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A'),
          ChecklistItem(id: '2', title: 'B'),
          ChecklistItem(id: '3', title: 'C'),
        ]);
        // Move C (index 2) to front (index 0)
        final reordered = cl.reorderItem(2, 0);
        expect(reordered.items.map((i) => i.id).toList(), ['3', '1', '2']);
      });

      test('same index returns unchanged', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A'),
          ChecklistItem(id: '2', title: 'B'),
        ]);
        final result = cl.reorderItem(0, 0);
        expect(result.items.map((i) => i.id).toList(), ['1', '2']);
      });

      test('invalid indices return unchanged', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A'),
        ]);
        expect(cl.reorderItem(-1, 0).totalCount, 1);
        expect(cl.reorderItem(0, 5).totalCount, 1);
      });
    });

    group('completeAll / uncompleteAll', () {
      test('completeAll marks all done', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A', completed: false),
          ChecklistItem(id: '2', title: 'B', completed: true),
          ChecklistItem(id: '3', title: 'C', completed: false),
        ]);
        final result = cl.completeAll();
        expect(result.completedCount, 3);
        expect(result.isAllCompleted, true);
      });

      test('uncompleteAll marks all undone', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A', completed: true),
          ChecklistItem(id: '2', title: 'B', completed: true),
        ]);
        final result = cl.uncompleteAll();
        expect(result.completedCount, 0);
      });
    });

    group('clearCompleted', () {
      test('removes only completed items', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'Done', completed: true),
          ChecklistItem(id: '2', title: 'Pending', completed: false),
          ChecklistItem(id: '3', title: 'Also done', completed: true),
        ]);
        final result = cl.clearCompleted();
        expect(result.totalCount, 1);
        expect(result.items.first.id, '2');
      });

      test('no completed items → unchanged count', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A', completed: false),
        ]);
        final result = cl.clearCompleted();
        expect(result.totalCount, 1);
      });
    });

    group('progress tracking', () {
      test('empty checklist progress is 0.0', () {
        expect(EventChecklist.empty.progress, 0.0);
      });

      test('no items completed → progress 0.0', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A'),
          ChecklistItem(id: '2', title: 'B'),
        ]);
        expect(cl.progress, 0.0);
        expect(cl.completedCount, 0);
        expect(cl.pendingCount, 2);
      });

      test('half completed → progress 0.5', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A', completed: true),
          ChecklistItem(id: '2', title: 'B', completed: false),
        ]);
        expect(cl.progress, 0.5);
      });

      test('all completed → progress 1.0', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A', completed: true),
          ChecklistItem(id: '2', title: 'B', completed: true),
        ]);
        expect(cl.progress, 1.0);
        expect(cl.isAllCompleted, true);
      });

      test('isAllCompleted false when empty', () {
        expect(EventChecklist.empty.isAllCompleted, false);
      });

      test('progressText for empty', () {
        expect(EventChecklist.empty.progressText, 'No items');
      });

      test('progressText for partial', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A', completed: true),
          ChecklistItem(id: '2', title: 'B', completed: false),
          ChecklistItem(id: '3', title: 'C', completed: false),
        ]);
        expect(cl.progressText, '1/3 completed');
      });

      test('progressText for all completed', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A', completed: true),
          ChecklistItem(id: '2', title: 'B', completed: true),
        ]);
        expect(cl.progressText, 'All 2 completed ✓');
      });

      test('shortProgress for items', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A', completed: true),
          ChecklistItem(id: '2', title: 'B'),
        ]);
        expect(cl.shortProgress, '1/2');
      });

      test('shortProgress for empty', () {
        expect(EventChecklist.empty.shortProgress, '');
      });
    });

    group('serialization', () {
      test('toJsonString produces valid JSON', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A', note: 'Note A', completed: false),
          ChecklistItem(id: '2', title: 'B', completed: true),
        ]);
        final json = cl.toJsonString();
        final decoded = jsonDecode(json) as List;
        expect(decoded.length, 2);
        expect(decoded[0]['title'], 'A');
        expect(decoded[1]['completed'], true);
      });

      test('fromJsonString round-trip', () {
        final original = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'Pack bags', note: 'Check weather'),
          ChecklistItem(id: '2', title: 'Print tickets', completed: true),
        ]);
        final json = original.toJsonString();
        final restored = EventChecklist.fromJsonString(json);
        expect(restored.totalCount, 2);
        expect(restored.items[0].title, 'Pack bags');
        expect(restored.items[0].note, 'Check weather');
        expect(restored.items[1].completed, true);
      });

      test('fromJsonString null returns empty', () {
        final result = EventChecklist.fromJsonString(null);
        expect(result.hasItems, false);
      });

      test('fromJsonString empty string returns empty', () {
        final result = EventChecklist.fromJsonString('');
        expect(result.hasItems, false);
      });

      test('fromJsonString malformed JSON returns empty', () {
        final result = EventChecklist.fromJsonString('not json');
        expect(result.hasItems, false);
      });

      test('fromJsonString empty array', () {
        final result = EventChecklist.fromJsonString('[]');
        expect(result.hasItems, false);
        expect(result.totalCount, 0);
      });
    });

    group('equality', () {
      test('two equal checklists are equal', () {
        final a = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'X', completed: true),
        ]);
        final b = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'X', completed: true),
        ]);
        expect(a, equals(b));
      });

      test('different items are not equal', () {
        final a = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'X'),
        ]);
        final b = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'Y'),
        ]);
        expect(a, isNot(equals(b)));
      });

      test('different lengths are not equal', () {
        final a = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'X'),
        ]);
        final b = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'X'),
          ChecklistItem(id: '2', title: 'Y'),
        ]);
        expect(a, isNot(equals(b)));
      });

      test('hashCode consistency', () {
        final a = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'X'),
        ]);
        final b = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'X'),
        ]);
        expect(a.hashCode, b.hashCode);
      });
    });

    group('toString', () {
      test('includes progress info', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A', completed: true),
          ChecklistItem(id: '2', title: 'B'),
        ]);
        expect(cl.toString(), contains('1/2'));
      });
    });

    group('edge cases', () {
      test('adding and removing same item', () {
        final item = ChecklistItem(id: '1', title: 'Temp');
        var cl = const EventChecklist();
        cl = cl.addItem(item);
        expect(cl.totalCount, 1);
        cl = cl.removeItem('1');
        expect(cl.totalCount, 0);
      });

      test('toggle all items individually', () {
        var cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A'),
          ChecklistItem(id: '2', title: 'B'),
          ChecklistItem(id: '3', title: 'C'),
        ]);
        cl = cl.toggleItem('1');
        cl = cl.toggleItem('2');
        cl = cl.toggleItem('3');
        expect(cl.isAllCompleted, true);
        expect(cl.progress, 1.0);
      });

      test('reorder preserves completion status', () {
        final cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'A', completed: true),
          ChecklistItem(id: '2', title: 'B', completed: false),
          ChecklistItem(id: '3', title: 'C', completed: true),
        ]);
        final reordered = cl.reorderItem(0, 2);
        expect(reordered.items[2].completed, true);
        expect(reordered.completedCount, 2);
      });

      test('clearCompleted then addItem', () {
        var cl = EventChecklist(items: [
          ChecklistItem(id: '1', title: 'Done', completed: true),
        ]);
        cl = cl.clearCompleted();
        expect(cl.totalCount, 0);
        cl = cl.addItem(ChecklistItem(id: '2', title: 'New'));
        expect(cl.totalCount, 1);
        expect(cl.items.first.title, 'New');
      });

      test('completeAll on empty checklist', () {
        final cl = EventChecklist.empty.completeAll();
        expect(cl.totalCount, 0);
      });

      test('large checklist serialization round-trip', () {
        var cl = const EventChecklist();
        for (var i = 0; i < 30; i++) {
          cl = cl.addItem(ChecklistItem(
            id: 'item_$i',
            title: 'Task $i',
            note: 'Note for task $i',
            completed: i % 2 == 0,
          ));
        }
        final json = cl.toJsonString();
        final restored = EventChecklist.fromJsonString(json);
        expect(restored.totalCount, 30);
        expect(restored.completedCount, 15);
      });
    });
  });
}
