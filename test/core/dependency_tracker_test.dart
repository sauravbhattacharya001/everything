import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/dependency_tracker.dart';
import 'package:everything/models/event_model.dart';

EventModel _event(String id, String title) => EventModel(
      id: id, title: title, date: DateTime(2026, 3, 1));

void main() {
  group('EventDependency', () {
    test('toJson/fromJson round-trip', () {
      final dep = EventDependency(
          blockerId: 'a', dependentId: 'b', label: 'prerequisite',
          createdAt: DateTime(2026, 1, 1));
      final restored = EventDependency.fromJson(dep.toJson());
      expect(restored.blockerId, 'a');
      expect(restored.dependentId, 'b');
      expect(restored.label, 'prerequisite');
      expect(restored.createdAt, DateTime(2026, 1, 1));
    });

    test('equality is based on blockerId and dependentId', () {
      final d1 = EventDependency(blockerId: 'a', dependentId: 'b', createdAt: DateTime(2026));
      final d2 = EventDependency(blockerId: 'a', dependentId: 'b', label: 'x', createdAt: DateTime(2025));
      final d3 = EventDependency(blockerId: 'a', dependentId: 'c', createdAt: DateTime(2026));
      expect(d1, equals(d2));
      expect(d1, isNot(equals(d3)));
    });

    test('copyWith', () {
      final dep = EventDependency(blockerId: 'a', dependentId: 'b', createdAt: DateTime(2026));
      expect(dep.copyWith(label: 'updated').label, 'updated');
    });

    test('toString with/without label', () {
      final withLabel = EventDependency(blockerId: 'a', dependentId: 'b', label: 'test', createdAt: DateTime(2026));
      final noLabel = EventDependency(blockerId: 'a', dependentId: 'b', createdAt: DateTime(2026));
      expect(withLabel.toString(), contains('[test]'));
      expect(noLabel.toString(), isNot(contains('[')));
    });

    test('fromJson handles missing label', () {
      final dep = EventDependency.fromJson({'blocker_id': 'x', 'dependent_id': 'y', 'created_at': '2026-01-01T00:00:00.000'});
      expect(dep.label, '');
    });
  });

  group('EventDependencyInfo', () {
    test('isRoot/isLeaf/totalRelationships', () {
      const root = EventDependencyInfo(eventId: 'a', blockedBy: [], blocks: ['b'], status: DependencyStatus.ready, depth: 0);
      const leaf = EventDependencyInfo(eventId: 'b', blockedBy: ['a'], blocks: [], status: DependencyStatus.blocked, depth: 1);
      const mid = EventDependencyInfo(eventId: 'b', blockedBy: ['a'], blocks: ['c', 'd'], status: DependencyStatus.ready, depth: 1);
      expect(root.isRoot, isTrue);
      expect(root.isLeaf, isFalse);
      expect(leaf.isLeaf, isTrue);
      expect(leaf.isRoot, isFalse);
      expect(mid.totalRelationships, 3);
    });
  });

  group('CriticalPath', () {
    test('isEmpty and toString', () {
      const empty = CriticalPath(path: []);
      const cp = CriticalPath(path: ['a', 'b', 'c']);
      expect(empty.isEmpty, isTrue);
      expect(cp.length, 3);
      expect(cp.toString(), contains('a → b → c'));
    });
  });

  group('Tracker - addDependency', () {
    late EventDependencyTracker tracker;
    setUp(() => tracker = EventDependencyTracker());

    test('adds valid dependency', () {
      expect(tracker.addDependency('a', 'b'), isTrue);
      expect(tracker.dependencies.length, 1);
    });

    test('rejects self-reference', () {
      expect(tracker.addDependency('a', 'a'), isFalse);
    });

    test('rejects empty IDs', () {
      expect(tracker.addDependency('', 'b'), isFalse);
      expect(tracker.addDependency('a', ''), isFalse);
    });

    test('rejects duplicate', () {
      tracker.addDependency('a', 'b');
      expect(tracker.addDependency('a', 'b'), isFalse);
    });

    test('allows reverse direction', () {
      tracker.addDependency('a', 'b');
      expect(tracker.addDependency('b', 'a'), isTrue);
    });

    test('accepts optional label and createdAt', () {
      tracker.addDependency('a', 'b', label: 'test', createdAt: DateTime(2026));
      expect(tracker.dependencies.first.label, 'test');
    });
  });

  group('Tracker - remove', () {
    late EventDependencyTracker tracker;
    setUp(() {
      tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'c');
    });

    test('removeDependency', () {
      expect(tracker.removeDependency('a', 'b'), isTrue);
      expect(tracker.dependencies.length, 1);
      expect(tracker.removeDependency('x', 'y'), isFalse);
    });

    test('removeAllForEvent', () {
      tracker.addDependency('a', 'c');
      tracker.markCompleted('b');
      expect(tracker.removeAllForEvent('b'), 2);
      expect(tracker.dependencies.length, 1);
      expect(tracker.isCompleted('b'), isFalse);
      expect(tracker.removeAllForEvent('z'), 0);
    });
  });

  group('Tracker - completion', () {
    late EventDependencyTracker tracker;
    setUp(() => tracker = EventDependencyTracker());

    test('mark completed/incomplete', () {
      tracker.markCompleted('a');
      expect(tracker.isCompleted('a'), isTrue);
      tracker.markIncomplete('a');
      expect(tracker.isCompleted('a'), isFalse);
    });

    test('completedEvents', () {
      tracker.markCompleted('a');
      expect(tracker.completedEvents, contains('a'));
    });
  });

  group('Tracker - getBlockers/getDependents', () {
    late EventDependencyTracker tracker;
    setUp(() {
      tracker = EventDependencyTracker();
      tracker.addDependency('a', 'c');
      tracker.addDependency('b', 'c');
      tracker.addDependency('c', 'd');
    });

    test('getBlockers', () {
      expect(tracker.getBlockers('c'), containsAll(['a', 'b']));
      expect(tracker.getBlockers('a'), isEmpty);
    });

    test('getDependents', () {
      expect(tracker.getDependents('c'), ['d']);
      expect(tracker.getDependents('d'), isEmpty);
    });
  });

  group('Tracker - getDependenciesFor/From', () {
    late EventDependencyTracker tracker;
    setUp(() {
      tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b', label: 'first');
      tracker.addDependency('a', 'c', label: 'second');
    });

    test('getDependenciesFrom', () {
      final deps = tracker.getDependenciesFrom('a');
      expect(deps.length, 2);
      expect(deps.map((d) => d.dependentId), containsAll(['b', 'c']));
    });

    test('getDependenciesFor', () {
      expect(tracker.getDependenciesFor('b').first.blockerId, 'a');
    });
  });

  group('Tracker - wouldCreateCycle', () {
    late EventDependencyTracker tracker;
    setUp(() {
      tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'c');
    });

    test('detects cycles', () {
      expect(tracker.wouldCreateCycle('b', 'a'), isTrue);
      expect(tracker.wouldCreateCycle('c', 'a'), isTrue);
      expect(tracker.wouldCreateCycle('a', 'a'), isTrue);
    });

    test('no cycle for valid deps', () {
      expect(tracker.wouldCreateCycle('a', 'd'), isFalse);
      tracker.addDependency('x', 'y');
      expect(tracker.wouldCreateCycle('y', 'a'), isFalse);
    });
  });

  group('Tracker - findCircularDependencies', () {
    test('no cycles', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      expect(tracker.findCircularDependencies(), isEmpty);
    });

    test('2-node cycle', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'a');
      expect(tracker.findCircularDependencies(), containsAll(['a', 'b']));
    });

    test('3-node cycle', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'c');
      tracker.addDependency('c', 'a');
      expect(tracker.findCircularDependencies(), containsAll(['a', 'b', 'c']));
    });

    test('isolates cycle from non-cyclic nodes', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('x', 'a');
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'a');
      tracker.addDependency('b', 'y');
      final circular = tracker.findCircularDependencies();
      expect(circular, containsAll(['a', 'b']));
      expect(circular, isNot(contains('x')));
      expect(circular, isNot(contains('y')));
    });
  });

  group('Tracker - computeDepths', () {
    test('linear chain', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'c');
      final depths = tracker.computeDepths();
      expect(depths['a'], 0);
      expect(depths['b'], 1);
      expect(depths['c'], 2);
    });

    test('max depth from multiple blockers', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'c');
      tracker.addDependency('b', 'c');
      tracker.addDependency('a', 'b');
      expect(tracker.computeDepths()['c'], 2);
    });

    test('skips circular nodes', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'a');
      tracker.addDependency('x', 'y');
      final depths = tracker.computeDepths();
      expect(depths.containsKey('a'), isFalse);
      expect(depths['x'], 0);
      expect(depths['y'], 1);
    });
  });

  group('Tracker - getInfo', () {
    test('ready/blocked/completed/circular', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      expect(tracker.getInfo('a').status, DependencyStatus.ready);
      expect(tracker.getInfo('b').status, DependencyStatus.blocked);

      tracker.markCompleted('a');
      expect(tracker.getInfo('b').status, DependencyStatus.ready);

      tracker.markCompleted('b');
      expect(tracker.getInfo('b').status, DependencyStatus.completed);
    });

    test('circular status', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'a');
      expect(tracker.getInfo('a').status, DependencyStatus.circular);
    });
  });

  group('Tracker - findCriticalPath', () {
    test('empty when no dependencies', () {
      expect(EventDependencyTracker().findCriticalPath().isEmpty, isTrue);
    });

    test('finds longest chain', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'c');
      tracker.addDependency('x', 'c');
      expect(tracker.findCriticalPath().path, ['a', 'b', 'c']);
    });

    test('skips circular nodes', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'a');
      tracker.addDependency('x', 'y');
      expect(tracker.findCriticalPath().path, ['x', 'y']);
    });
  });

  group('Tracker - findReadyEvents/findBlockedEvents', () {
    late EventDependencyTracker tracker;
    setUp(() {
      tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'c');
    });

    test('findReadyEvents', () {
      expect(tracker.findReadyEvents(), ['a']);
      tracker.markCompleted('a');
      expect(tracker.findReadyEvents(), contains('b'));
      expect(tracker.findReadyEvents(), isNot(contains('a')));
    });

    test('findBlockedEvents', () {
      expect(tracker.findBlockedEvents(), containsAll(['b', 'c']));
      tracker.markCompleted('a');
      tracker.markCompleted('b');
      expect(tracker.findBlockedEvents(), isEmpty);
    });
  });

  group('Tracker - topologicalSort', () {
    test('valid ordering', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'c');
      tracker.addDependency('a', 'c');
      final sorted = tracker.topologicalSort()!;
      expect(sorted.indexOf('a'), lessThan(sorted.indexOf('b')));
      expect(sorted.indexOf('b'), lessThan(sorted.indexOf('c')));
    });

    test('null for cycles', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'a');
      expect(tracker.topologicalSort(), isNull);
    });

    test('handles independent events', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('x', 'y');
      expect(tracker.topologicalSort()!.length, 4);
    });
  });

  group('Tracker - analyze', () {
    test('complete summary', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'c');
      tracker.markCompleted('a');
      final summary = tracker.analyze([_event('a', 'A'), _event('b', 'B'), _event('c', 'C')]);
      expect(summary.totalEvents, 3);
      expect(summary.totalDependencies, 2);
      expect(summary.rootEvents, ['a']);
      expect(summary.leafEvents, ['c']);
      expect(summary.readyEvents, contains('b'));
      expect(summary.blockedEvents, contains('c'));
      expect(summary.hasCircularDependencies, isFalse);
      expect(summary.maxDepth, 2);
    });

    test('detects circular in summary', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'a');
      expect(tracker.analyze([]).hasCircularDependencies, isTrue);
    });
  });

  group('Tracker - formatSummary', () {
    test('includes sections', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      final text = tracker.formatSummary([_event('a', 'Setup'), _event('b', 'Build')]);
      expect(text, contains('Ready'));
      expect(text, contains('Setup'));
      expect(text, contains('Blocked'));
      expect(text, contains('Build'));
    });

    test('circular warning', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'a');
      expect(tracker.formatSummary([]), contains('Circular'));
    });

    test('critical path', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'c');
      expect(tracker.formatSummary([_event('a', 'A'), _event('b', 'B'), _event('c', 'C')]), contains('Critical Path'));
    });
  });

  group('Tracker - serialization', () {
    test('toJson/fromJson round-trip', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b', label: 'test');
      tracker.addDependency('b', 'c');
      tracker.markCompleted('a');
      final restored = EventDependencyTracker.fromJson(tracker.toJson());
      expect(restored.dependencies.length, 2);
      expect(restored.isCompleted('a'), isTrue);
      expect(restored.getBlockers('b'), ['a']);
    });

    test('fromJson empty', () {
      final tracker = EventDependencyTracker.fromJson({});
      expect(tracker.dependencies, isEmpty);
    });
  });

  group('Tracker - clear', () {
    test('clears all', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.markCompleted('a');
      tracker.clear();
      expect(tracker.dependencies, isEmpty);
      expect(tracker.completedEvents, isEmpty);
    });
  });

  group('Tracker - max limit', () {
    test('rejects at capacity', () {
      final tracker = EventDependencyTracker();
      for (var i = 0; i < EventDependencyTracker.maxDependencies; i++) {
        tracker.addDependency('b$i', 'd$i');
      }
      expect(tracker.addDependency('overflow', 'dep'), isFalse);
    });
  });

  group('DependencyGraphSummary', () {
    test('toString', () {
      const s = DependencyGraphSummary(
        totalEvents: 5, totalDependencies: 4, rootEvents: ['a'], leafEvents: ['e'],
        blockedEvents: ['c'], readyEvents: ['b'], criticalPath: CriticalPath(path: []),
        maxDepth: 3, hasCircularDependencies: false, circularEventIds: [],
      );
      expect(s.toString(), contains('events: 5'));
    });
  });

  group('Tracker - complex scenarios', () {
    test('diamond pattern', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('a', 'c');
      tracker.addDependency('b', 'd');
      tracker.addDependency('c', 'd');
      expect(tracker.computeDepths()['d'], 2);

      tracker.markCompleted('a');
      expect(tracker.findReadyEvents(), containsAll(['b', 'c']));
      expect(tracker.findBlockedEvents(), ['d']);

      tracker.markCompleted('b');
      expect(tracker.findBlockedEvents(), ['d']);
      tracker.markCompleted('c');
      expect(tracker.findReadyEvents(), ['d']);
    });

    test('fan-out', () {
      final tracker = EventDependencyTracker();
      for (var i = 0; i < 5; i++) tracker.addDependency('root', 'leaf_$i');
      expect(tracker.findReadyEvents(), ['root']);
      tracker.markCompleted('root');
      expect(tracker.findReadyEvents().length, 5);
    });

    test('fan-in', () {
      final tracker = EventDependencyTracker();
      for (var i = 0; i < 5; i++) tracker.addDependency('b$i', 'target');
      expect(tracker.getInfo('target').status, DependencyStatus.blocked);
      for (var i = 0; i < 4; i++) tracker.markCompleted('b$i');
      expect(tracker.getInfo('target').status, DependencyStatus.blocked);
      tracker.markCompleted('b4');
      expect(tracker.getInfo('target').status, DependencyStatus.ready);
    });
  });

  group('index consistency', () {
    test('getBlockers returns correct results after add and remove', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'c');
      tracker.addDependency('b', 'c');
      expect(tracker.getBlockers('c'), unorderedEquals(['a', 'b']));
      tracker.removeDependency('a', 'c');
      expect(tracker.getBlockers('c'), equals(['b']));
    });

    test('getDependents returns correct results after add and remove', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('a', 'c');
      tracker.addDependency('a', 'd');
      expect(tracker.getDependents('a'), unorderedEquals(['b', 'c', 'd']));
      tracker.removeDependency('a', 'c');
      expect(tracker.getDependents('a'), unorderedEquals(['b', 'd']));
    });

    test('removeAllForEvent cleans up indexes', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'c');
      tracker.addDependency('d', 'b');
      tracker.removeAllForEvent('b');
      expect(tracker.getBlockers('b'), isEmpty);
      expect(tracker.getDependents('b'), isEmpty);
      expect(tracker.getBlockers('c'), isEmpty);
      expect(tracker.getDependents('a'), isEmpty);
    });

    test('getDependenciesFor and getDependenciesFrom use indexes', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('x', 'y', label: 'dep1');
      tracker.addDependency('x', 'z', label: 'dep2');
      tracker.addDependency('w', 'y', label: 'dep3');
      final fromX = tracker.getDependenciesFrom('x');
      expect(fromX.length, 2);
      expect(fromX.map((d) => d.label), unorderedEquals(['dep1', 'dep2']));
      final forY = tracker.getDependenciesFor('y');
      expect(forY.length, 2);
      expect(forY.map((d) => d.label), unorderedEquals(['dep1', 'dep3']));
    });

    test('clear resets indexes', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('c', 'd');
      tracker.clear();
      expect(tracker.getBlockers('b'), isEmpty);
      expect(tracker.getDependents('a'), isEmpty);
      expect(tracker.dependencies, isEmpty);
    });

    test('fromJson rebuilds indexes correctly', () {
      final t1 = EventDependencyTracker();
      t1.addDependency('a', 'b');
      t1.addDependency('b', 'c');
      t1.markCompleted('a');
      final json = t1.toJson();
      final t2 = EventDependencyTracker.fromJson(json);
      expect(t2.getBlockers('b'), equals(['a']));
      expect(t2.getDependents('b'), equals(['c']));
      expect(t2.isCompleted('a'), isTrue);
    });

    test('wouldCreateCycle uses indexed lookups', () {
      final tracker = EventDependencyTracker();
      tracker.addDependency('a', 'b');
      tracker.addDependency('b', 'c');
      tracker.addDependency('c', 'd');
      expect(tracker.wouldCreateCycle('d', 'a'), isTrue);
      expect(tracker.wouldCreateCycle('d', 'e'), isFalse);
    });
  });
  });
}
