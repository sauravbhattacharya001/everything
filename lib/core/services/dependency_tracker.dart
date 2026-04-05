import '../../models/event_model.dart';

/// Represents a dependency relationship between two events.
///
/// [blockerId] is the event that must be completed before [dependentId].
class EventDependency {
  /// The event that blocks (must finish first).
  final String blockerId;

  /// The event that is blocked (waits for blocker).
  final String dependentId;

  /// Optional label describing the relationship.
  final String label;

  /// When this dependency was created.
  final DateTime createdAt;

  const EventDependency({
    required this.blockerId,
    required this.dependentId,
    this.label = '',
    required this.createdAt,
  });

  EventDependency copyWith({
    String? blockerId,
    String? dependentId,
    String? label,
    DateTime? createdAt,
  }) {
    return EventDependency(
      blockerId: blockerId ?? this.blockerId,
      dependentId: dependentId ?? this.dependentId,
      label: label ?? this.label,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'blocker_id': blockerId,
        'dependent_id': dependentId,
        'label': label,
        'created_at': createdAt.toIso8601String(),
      };

  factory EventDependency.fromJson(Map<String, dynamic> json) {
    return EventDependency(
      blockerId: json['blocker_id'] as String,
      dependentId: json['dependent_id'] as String,
      label: (json['label'] as String?) ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventDependency &&
          blockerId == other.blockerId &&
          dependentId == other.dependentId;

  @override
  int get hashCode => Object.hash(blockerId, dependentId);

  @override
  String toString() =>
      'EventDependency($blockerId → $dependentId${label.isNotEmpty ? " [$label]" : ""})';
}

/// Status of an event within the dependency graph.
enum DependencyStatus {
  ready,
  blocked,
  completed,
  circular,
}

/// Information about a single event's position in the dependency graph.
class EventDependencyInfo {
  final String eventId;
  final List<String> blockedBy;
  final List<String> blocks;
  final DependencyStatus status;
  final int depth;

  const EventDependencyInfo({
    required this.eventId,
    required this.blockedBy,
    required this.blocks,
    required this.status,
    required this.depth,
  });

  bool get isRoot => blockedBy.isEmpty;
  bool get isLeaf => blocks.isEmpty;
  int get totalRelationships => blockedBy.length + blocks.length;

  @override
  String toString() =>
      'EventDependencyInfo($eventId, status: $status, depth: $depth, '
      'blockedBy: ${blockedBy.length}, blocks: ${blocks.length})';
}

/// Result of a critical path analysis.
class CriticalPath {
  final List<String> path;
  int get length => path.length;
  bool get isEmpty => path.isEmpty;

  const CriticalPath({required this.path});

  @override
  String toString() => 'CriticalPath(${path.join(" → ")})';
}

/// Summary of the entire dependency graph.
class DependencyGraphSummary {
  final int totalEvents;
  final int totalDependencies;
  final List<String> rootEvents;
  final List<String> leafEvents;
  final List<String> blockedEvents;
  final List<String> readyEvents;
  final CriticalPath criticalPath;
  final int maxDepth;
  final bool hasCircularDependencies;
  final List<String> circularEventIds;

  const DependencyGraphSummary({
    required this.totalEvents,
    required this.totalDependencies,
    required this.rootEvents,
    required this.leafEvents,
    required this.blockedEvents,
    required this.readyEvents,
    required this.criticalPath,
    required this.maxDepth,
    required this.hasCircularDependencies,
    required this.circularEventIds,
  });

  @override
  String toString() =>
      'DependencyGraphSummary(events: $totalEvents, deps: $totalDependencies, '
      'blocked: ${blockedEvents.length}, ready: ${readyEvents.length}, '
      'circular: $hasCircularDependencies, maxDepth: $maxDepth)';
}

/// Tracks dependency relationships between events, detects circular
/// dependencies, computes critical paths, and identifies blocked/ready events.
class EventDependencyTracker {
  final List<EventDependency> _dependencies = [];
  final Set<String> _completedEvents = {};

  /// Adjacency index: blockerId -> list of dependencies where this ID is the blocker.
  final Map<String, List<EventDependency>> _byBlocker = {};
  /// Adjacency index: dependentId -> list of dependencies where this ID is the dependent.
  final Map<String, List<EventDependency>> _byDependent = {};

  /// Rebuild adjacency indexes from the dependency list.
  void _rebuildIndexes() {
    _byBlocker.clear();
    _byDependent.clear();
    for (final dep in _dependencies) {
      _byBlocker.putIfAbsent(dep.blockerId, () => []).add(dep);
      _byDependent.putIfAbsent(dep.dependentId, () => []).add(dep);
    }
  }

  /// Add a single dependency to the indexes.
  void _indexAdd(EventDependency dep) {
    _byBlocker.putIfAbsent(dep.blockerId, () => []).add(dep);
    _byDependent.putIfAbsent(dep.dependentId, () => []).add(dep);
  }

  /// Remove entries matching a predicate from the indexes.
  void _indexRemoveWhere(bool Function(EventDependency) test) {
    for (final list in _byBlocker.values) {
      list.removeWhere(test);
    }
    _byBlocker.removeWhere((_, v) => v.isEmpty);
    for (final list in _byDependent.values) {
      list.removeWhere(test);
    }
    _byDependent.removeWhere((_, v) => v.isEmpty);
  }

  static const int maxDependencies = 500;

  List<EventDependency> get dependencies => List.unmodifiable(_dependencies);
  Set<String> get completedEvents => Set.unmodifiable(_completedEvents);

  /// Adds a dependency: [blockerId] must complete before [dependentId].
  bool addDependency(
    String blockerId,
    String dependentId, {
    String label = '',
    DateTime? createdAt,
  }) {
    if (blockerId.isEmpty || dependentId.isEmpty) return false;
    if (blockerId == dependentId) return false;
    if (_dependencies.length >= maxDependencies) return false;

    final dep = EventDependency(
      blockerId: blockerId,
      dependentId: dependentId,
      label: label,
      createdAt: createdAt ?? DateTime.now(),
    );

    if (_dependencies.contains(dep)) return false;
    _dependencies.add(dep);
    _indexAdd(dep);
    return true;
  }

  bool removeDependency(String blockerId, String dependentId) {
    final before = _dependencies.length;
    final test = (EventDependency d) => d.blockerId == blockerId && d.dependentId == dependentId;
    _dependencies.removeWhere(test);
    if (_dependencies.length < before) {
      _indexRemoveWhere(test);
      return true;
    }
    return false;
  }

  int removeAllForEvent(String eventId) {
    final before = _dependencies.length;
    final test = (EventDependency d) => d.blockerId == eventId || d.dependentId == eventId;
    _dependencies.removeWhere(test);
    _indexRemoveWhere(test);
    _completedEvents.remove(eventId);
    return before - _dependencies.length;
  }

  void markCompleted(String eventId) => _completedEvents.add(eventId);
  void markIncomplete(String eventId) => _completedEvents.remove(eventId);
  bool isCompleted(String eventId) => _completedEvents.contains(eventId);

  List<String> getBlockers(String eventId) {
    return (_byDependent[eventId] ?? const [])
        .map((d) => d.blockerId)
        .toList();
  }

  List<String> getDependents(String eventId) {
    return (_byBlocker[eventId] ?? const [])
        .map((d) => d.dependentId)
        .toList();
  }

  List<EventDependency> getDependenciesFor(String eventId) {
    return List.of(_byDependent[eventId] ?? const []);
  }

  List<EventDependency> getDependenciesFrom(String eventId) {
    return List.of(_byBlocker[eventId] ?? const []);
  }

  /// Checks if adding blockerId→dependentId would create a cycle.
  ///
  /// A cycle exists iff blockerId is reachable from dependentId by
  /// following existing dependency edges forward. A single forward BFS
  /// from dependentId is sufficient — the previous backward BFS from
  /// blockerId was redundant because reachability in a directed graph
  /// is symmetric with respect to cycle detection through the proposed
  /// edge (if blockerId is reachable from dependentId going forward,
  /// that's the cycle; if not, no backward search can find one either).
  bool wouldCreateCycle(String blockerId, String dependentId) {
    if (blockerId == dependentId) return true;

    // BFS forward from dependentId — check if blockerId is reachable.
    // Uses an index pointer instead of removeAt(0) to avoid O(n)
    // list shifting at each dequeue, reducing total cost from O(V²)
    // to O(V + E).
    final visited = <String>{dependentId};
    final queue = <String>[dependentId];
    var head = 0;
    while (head < queue.length) {
      final current = queue[head++];
      for (final dep in (_byBlocker[current] ?? const [])) {
        if (dep.dependentId == blockerId) return true;
        if (visited.add(dep.dependentId)) {
          queue.add(dep.dependentId);
        }
      }
    }

    return false;
  }

  /// Detects all event IDs involved in circular dependencies (3-color DFS).
  List<String> findCircularDependencies() {
    final circularIds = <String>{};
    final allIds = _allEventIds();
    final color = <String, int>{};
    for (final id in allIds) color[id] = 0;

    // Track which nodes are on the current DFS path in a Set for O(1)
    // cycle-start detection, replacing the previous O(n) path.indexOf().
    final onPath = <String>{};

    void dfs(String node, List<String> path) {
      color[node] = 1;
      path.add(node);
      onPath.add(node);
      for (final dep in (_byBlocker[node] ?? const [])) {
        final next = dep.dependentId;
        if (color[next] == 1 && onPath.contains(next)) {
          final cycleStart = path.indexOf(next);
          if (cycleStart >= 0) {
            for (var i = cycleStart; i < path.length; i++) {
              circularIds.add(path[i]);
            }
          }
        } else if (color[next] == 0) {
          dfs(next, path);
        }
      }
      path.removeLast();
      onPath.remove(node);
      color[node] = 2;
    }

    for (final id in allIds) {
      if (color[id] == 0) dfs(id, []);
    }
    return circularIds.toList()..sort();
  }

  /// Computes depth of each event (0 = root, skips circular nodes).
  Map<String, int> computeDepths({Set<String>? circularCache}) {
    final allIds = _allEventIds();
    final depths = <String, int>{};
    final circular = circularCache ?? findCircularDependencies().toSet();

    for (final id in allIds) {
      if (circular.contains(id)) continue;
      if (getBlockers(id).isEmpty) depths[id] = 0;
    }

    var changed = true;
    var iterations = 0;
    while (changed && iterations < allIds.length + 1) {
      changed = false;
      iterations++;
      for (final id in allIds) {
        if (circular.contains(id) || depths.containsKey(id)) continue;
        final blockers = getBlockers(id);
        if (blockers.every((b) => depths.containsKey(b))) {
          depths[id] = blockers.map((b) => depths[b]!).reduce((a, b) => a > b ? a : b) + 1;
          changed = true;
        }
      }
    }
    return depths;
  }

  EventDependencyInfo getInfo(String eventId, {Set<String>? circularCache, Map<String, int>? depthCache}) {
    final blockers = getBlockers(eventId);
    final dependents = getDependents(eventId);
    final circularSet = circularCache ?? findCircularDependencies().toSet();
    final depths = depthCache ?? computeDepths();

    DependencyStatus status;
    if (circularSet.contains(eventId)) {
      status = DependencyStatus.circular;
    } else if (_completedEvents.contains(eventId)) {
      status = DependencyStatus.completed;
    } else if (blockers.isEmpty || blockers.every((b) => _completedEvents.contains(b))) {
      status = DependencyStatus.ready;
    } else {
      status = DependencyStatus.blocked;
    }

    return EventDependencyInfo(
      eventId: eventId, blockedBy: blockers, blocks: dependents,
      status: status, depth: depths[eventId] ?? 0,
    );
  }

  CriticalPath findCriticalPath({Set<String>? circularCache, Map<String, int>? depthCache}) {
    final circular = circularCache ?? findCircularDependencies().toSet();
    final depths = depthCache ?? computeDepths();
    final allIds = _allEventIds().where((id) => !circular.contains(id));
    if (allIds.isEmpty) return const CriticalPath(path: []);

    String? deepest;
    int maxDepth = -1;
    for (final id in allIds) {
      final d = depths[id] ?? 0;
      if (d > maxDepth) { maxDepth = d; deepest = id; }
    }
    if (deepest == null) return const CriticalPath(path: []);

    final path = <String>[deepest];
    var current = deepest;
    while (true) {
      final blockers = getBlockers(current);
      if (blockers.isEmpty) break;
      String? best; int bestD = -1;
      for (final b in blockers) {
        final d = depths[b] ?? 0;
        if (d > bestD) { bestD = d; best = b; }
      }
      if (best == null) break;
      path.insert(0, best);
      current = best;
    }
    return CriticalPath(path: path);
  }

  List<String> findReadyEvents({Set<String>? circularCache}) {
    final circular = circularCache ?? findCircularDependencies().toSet();
    final ready = <String>[];
    for (final id in _allEventIds()) {
      if (_completedEvents.contains(id) || circular.contains(id)) continue;
      final blockers = getBlockers(id);
      if (blockers.isEmpty || blockers.every((b) => _completedEvents.contains(b))) {
        ready.add(id);
      }
    }
    return ready..sort();
  }

  List<String> findBlockedEvents({Set<String>? circularCache}) {
    final circular = circularCache ?? findCircularDependencies().toSet();
    final blocked = <String>[];
    for (final id in _allEventIds()) {
      if (_completedEvents.contains(id) || circular.contains(id)) continue;
      final blockers = getBlockers(id);
      if (blockers.isNotEmpty && !blockers.every((b) => _completedEvents.contains(b))) {
        blocked.add(id);
      }
    }
    return blocked..sort();
  }

  DependencyGraphSummary analyze(List<EventModel> events) {
    final circular = findCircularDependencies();
    final circularSet = circular.toSet();
    final depths = computeDepths(circularCache: circularSet);
    final allIds = _allEventIds();
    final rootEvents = <String>[];
    final leafEvents = <String>[];
    for (final id in allIds) {
      if (getBlockers(id).isEmpty) rootEvents.add(id);
      if (getDependents(id).isEmpty) leafEvents.add(id);
    }
    return DependencyGraphSummary(
      totalEvents: allIds.length,
      totalDependencies: _dependencies.length,
      rootEvents: rootEvents..sort(),
      leafEvents: leafEvents..sort(),
      blockedEvents: findBlockedEvents(circularCache: circularSet),
      readyEvents: findReadyEvents(circularCache: circularSet),
      criticalPath: findCriticalPath(circularCache: circularSet, depthCache: depths),
      maxDepth: depths.values.isEmpty ? 0 : depths.values.reduce((a, b) => a > b ? a : b),
      hasCircularDependencies: circular.isNotEmpty,
      circularEventIds: circular,
    );
  }

  /// Topological sort (Kahn's algorithm). Returns null if cycles exist.
  List<String>? topologicalSort() {
    if (findCircularDependencies().isNotEmpty) return null;
    final allIds = _allEventIds();
    final inDegree = <String, int>{};
    for (final id in allIds) inDegree[id] = 0;
    for (final dep in _dependencies) {
      inDegree[dep.dependentId] = (inDegree[dep.dependentId] ?? 0) + 1;
    }
    // Use an index pointer for O(1) dequeue and collect zero-in-degree
    // nodes unsorted, then sort the final result.  The previous approach
    // did O(n) sorted insertion per node (O(n²) total) plus O(n) removeAt.
    final queue = <String>[for (final id in allIds) if (inDegree[id] == 0) id];
    final result = <String>[];
    var head = 0;
    while (head < queue.length) {
      final current = queue[head++];
      result.add(current);
      for (final dep in (_byBlocker[current] ?? const [])) {
        inDegree[dep.dependentId] = (inDegree[dep.dependentId] ?? 1) - 1;
        if (inDegree[dep.dependentId] == 0) {
          queue.add(dep.dependentId);
        }
      }
    }
    if (result.length != allIds.length) return null;
    // Stable lexicographic sort for deterministic output
    result.sort();
    return result;
  }

  String formatSummary(List<EventModel> events) {
    final summary = analyze(events);
    final eventMap = {for (final e in events) e.id: e.title};
    String name(String id) => eventMap[id] ?? id;

    final buf = StringBuffer();
    buf.writeln('=== Event Dependency Summary ===');
    buf.writeln('Events: ${summary.totalEvents}');
    buf.writeln('Dependencies: ${summary.totalDependencies}');
    buf.writeln('Max Depth: ${summary.maxDepth}');
    buf.writeln();
    if (summary.readyEvents.isNotEmpty) {
      buf.writeln('✅ Ready (${summary.readyEvents.length}):');
      for (final id in summary.readyEvents) buf.writeln('  • ${name(id)}');
      buf.writeln();
    }
    if (summary.blockedEvents.isNotEmpty) {
      buf.writeln('🚫 Blocked (${summary.blockedEvents.length}):');
      for (final id in summary.blockedEvents) {
        buf.writeln('  • ${name(id)} ← blocked by: ${getBlockers(id).map(name).join(', ')}');
      }
      buf.writeln();
    }
    if (summary.hasCircularDependencies) {
      buf.writeln('⚠️ Circular Dependencies:');
      for (final id in summary.circularEventIds) buf.writeln('  • ${name(id)}');
      buf.writeln();
    }
    if (!summary.criticalPath.isEmpty) {
      buf.writeln('📐 Critical Path (${summary.criticalPath.length} events):');
      buf.writeln('  ${summary.criticalPath.path.map(name).join(' → ')}');
    }
    return buf.toString().trimRight();
  }

  Map<String, dynamic> toJson() => {
        'dependencies': _dependencies.map((d) => d.toJson()).toList(),
        'completed': _completedEvents.toList()..sort(),
      };

  factory EventDependencyTracker.fromJson(Map<String, dynamic> json) {
    final tracker = EventDependencyTracker();
    for (final d in (json['dependencies'] as List<dynamic>? ?? [])) {
      tracker._dependencies.add(EventDependency.fromJson(d as Map<String, dynamic>));
    }
    for (final id in (json['completed'] as List<dynamic>? ?? [])) {
      tracker._completedEvents.add(id as String);
    }
    tracker._rebuildIndexes();
    return tracker;
  }

  void clear() {
    _dependencies.clear();
    _completedEvents.clear();
    _byBlocker.clear();
    _byDependent.clear();
  }

  Set<String> _allEventIds() {
    final ids = <String>{};
    for (final dep in _dependencies) {
      ids.add(dep.blockerId);
      ids.add(dep.dependentId);
    }
    return ids;
  }
}
