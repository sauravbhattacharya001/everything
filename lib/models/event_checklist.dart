import 'dart:convert';

/// A single item in an event checklist.
///
/// Each item has a [title] (what to do), an optional [note] (extra
/// detail), and a [completed] flag. Items are immutable — use
/// [copyWith] or [toggleCompleted] to create modified copies.
///
/// Example:
/// ```dart
/// final item = ChecklistItem(title: 'Book conference room');
/// final done = item.toggleCompleted(); // completed = true
/// ```
class ChecklistItem {
  /// Unique identifier for this item within a checklist.
  final String id;

  /// The task or item description.
  final String title;

  /// Optional additional note or context.
  final String note;

  /// Whether this item has been completed.
  final bool completed;

  /// When this item was created.
  final DateTime createdAt;

  /// When this item was marked completed, or null if not yet done.
  final DateTime? completedAt;

  ChecklistItem({
    required this.id,
    required this.title,
    this.note = '',
    this.completed = false,
    DateTime? createdAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a new item with a generated ID.
  factory ChecklistItem.create({
    required String title,
    String note = '',
  }) {
    return ChecklistItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      note: note,
    );
  }

  /// Returns a copy with [completed] toggled.
  ChecklistItem toggleCompleted() {
    final nowCompleted = !completed;
    return copyWith(
      completed: nowCompleted,
      completedAt: nowCompleted ? DateTime.now() : null,
      clearCompletedAt: !nowCompleted,
    );
  }

  /// Creates a copy with the given fields replaced.
  ChecklistItem copyWith({
    String? id,
    String? title,
    String? note,
    bool? completed,
    DateTime? createdAt,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return ChecklistItem(
      id: id ?? this.id,
      title: title ?? this.title,
      note: note ?? this.note,
      completed: completed ?? this.completed,
      createdAt: createdAt ?? this.createdAt,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  /// Serialize to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'completed': completed,
      'createdAt': createdAt.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
    };
  }

  /// Deserialize from a JSON map.
  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'] as String? ?? DateTime.now().microsecondsSinceEpoch.toString(),
      title: json['title'] as String,
      note: (json['note'] as String?) ?? '',
      completed: (json['completed'] as bool?) ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String? ?? '')
          : DateTime.now(),
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String? ?? '')
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChecklistItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          title == other.title &&
          note == other.note &&
          completed == other.completed;

  @override
  int get hashCode => Object.hash(id, title, note, completed);

  @override
  String toString() =>
      'ChecklistItem(id: $id, title: $title, completed: $completed)';
}

/// A checklist of [ChecklistItem]s attached to an event.
///
/// Provides methods for adding, removing, toggling, and reordering items,
/// plus progress tracking (completion count, percentage).
///
/// Example:
/// ```dart
/// var checklist = EventChecklist.empty();
/// checklist = checklist.addItem(ChecklistItem.create(title: 'Pack bags'));
/// checklist = checklist.addItem(ChecklistItem.create(title: 'Print tickets'));
/// checklist = checklist.toggleItem(checklist.items.first.id);
/// print(checklist.progressText); // "1/2 completed"
/// ```
class EventChecklist {
  /// Maximum items allowed per checklist to prevent abuse.
  static const int maxItems = 50;

  /// The ordered list of checklist items.
  final List<ChecklistItem> items;

  const EventChecklist({this.items = const []});

  /// Empty checklist.
  static const EventChecklist empty = EventChecklist();

  /// Whether the checklist has any items.
  bool get hasItems => items.isNotEmpty;

  /// Total number of items.
  int get totalCount => items.length;

  /// Number of completed items.
  int get completedCount => items.where((i) => i.completed).length;

  /// Number of incomplete items.
  int get pendingCount => totalCount - completedCount;

  /// Progress as a fraction (0.0 to 1.0). Returns 0.0 for empty checklists.
  double get progress => totalCount == 0 ? 0.0 : completedCount / totalCount;

  /// Whether all items are completed.
  bool get isAllCompleted => totalCount > 0 && completedCount == totalCount;

  /// Human-readable progress string (e.g., "3/5 completed").
  String get progressText {
    if (totalCount == 0) return 'No items';
    if (isAllCompleted) return 'All $totalCount completed ✓';
    return '$completedCount/$totalCount completed';
  }

  /// Short progress label for badges (e.g., "3/5").
  String get shortProgress {
    if (totalCount == 0) return '';
    return '$completedCount/$totalCount';
  }

  /// Add an item to the end of the checklist.
  /// Returns unchanged checklist if at max capacity.
  EventChecklist addItem(ChecklistItem item) {
    if (items.length >= maxItems) return this;
    return EventChecklist(items: [...items, item]);
  }

  /// Remove an item by ID.
  EventChecklist removeItem(String itemId) {
    return EventChecklist(
      items: items.where((i) => i.id != itemId).toList(),
    );
  }

  /// Toggle an item's completed status by ID.
  EventChecklist toggleItem(String itemId) {
    return EventChecklist(
      items: items.map((i) {
        if (i.id == itemId) return i.toggleCompleted();
        return i;
      }).toList(),
    );
  }

  /// Update an item by ID (replace with modified copy).
  EventChecklist updateItem(String itemId, ChecklistItem updated) {
    return EventChecklist(
      items: items.map((i) {
        if (i.id == itemId) return updated;
        return i;
      }).toList(),
    );
  }

  /// Move an item from [oldIndex] to [newIndex] (for drag-and-drop).
  EventChecklist reorderItem(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= items.length) return this;
    if (newIndex < 0 || newIndex >= items.length) return this;
    if (oldIndex == newIndex) return this;

    final list = List<ChecklistItem>.from(items);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    return EventChecklist(items: list);
  }

  /// Mark all items as completed.
  EventChecklist completeAll() {
    return EventChecklist(
      items: items.map((i) {
        if (!i.completed) return i.toggleCompleted();
        return i;
      }).toList(),
    );
  }

  /// Mark all items as not completed.
  EventChecklist uncompleteAll() {
    return EventChecklist(
      items: items.map((i) {
        if (i.completed) return i.toggleCompleted();
        return i;
      }).toList(),
    );
  }

  /// Remove all completed items.
  EventChecklist clearCompleted() {
    return EventChecklist(
      items: items.where((i) => !i.completed).toList(),
    );
  }

  /// Serialize to JSON string for DB storage.
  String toJsonString() {
    return jsonEncode(items.map((i) => i.toJson()).toList());
  }

  /// Deserialize from JSON string.
  factory EventChecklist.fromJsonString(String? json) {
    if (json == null || json.isEmpty) return EventChecklist.empty;
    try {
      final decoded = jsonDecode(json) as List<dynamic>;
      final items = decoded
          .map((i) => ChecklistItem.fromJson(i as Map<String, dynamic>))
          .toList();
      return EventChecklist(items: items);
    } catch (_) {
      // Gracefully handle malformed stored data
      return EventChecklist.empty;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventChecklist &&
          items.length == other.items.length &&
          _itemsEqual(items, other.items);

  static bool _itemsEqual(List<ChecklistItem> a, List<ChecklistItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(items);

  @override
  String toString() => 'EventChecklist(${progressText})';
}
