/// Kanban Board Service — manage boards with customizable columns and cards.
///
/// Features:
/// - Multiple boards with custom names and colors
/// - Configurable columns (default: To Do, In Progress, Done)
/// - Cards with title, description, labels, priority, due date
/// - Move cards between columns
/// - Reorder cards within columns
/// - Card filtering by label or priority
/// - Board statistics (cards per column, overdue count)
/// - Archive completed cards

import 'package:flutter/material.dart';

/// Priority levels for kanban cards.
enum KanbanPriority { low, medium, high, urgent }

/// A label with name and color for categorizing cards.
class KanbanLabel {
  final String name;
  final Color color;

  const KanbanLabel({required this.name, required this.color});

  static const defaultLabels = [
    KanbanLabel(name: 'Bug', color: Color(0xFFEF5350)),
    KanbanLabel(name: 'Feature', color: Color(0xFF42A5F5)),
    KanbanLabel(name: 'Chore', color: Color(0xFFFFCA28)),
    KanbanLabel(name: 'Idea', color: Color(0xFF66BB6A)),
    KanbanLabel(name: 'Urgent', color: Color(0xFFAB47BC)),
  ];
}

/// A single card on the kanban board.
class KanbanCard {
  final String id;
  String title;
  String description;
  List<KanbanLabel> labels;
  KanbanPriority priority;
  DateTime? dueDate;
  DateTime createdAt;
  bool archived;

  KanbanCard({
    required this.id,
    required this.title,
    this.description = '',
    this.labels = const [],
    this.priority = KanbanPriority.medium,
    this.dueDate,
    DateTime? createdAt,
    this.archived = false,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isOverdue =>
      dueDate != null && dueDate!.isBefore(DateTime.now()) && !archived;
}

/// A column on the kanban board.
class KanbanColumn {
  final String id;
  String name;
  Color color;
  List<KanbanCard> cards;
  int? wipLimit; // Work-in-progress limit

  KanbanColumn({
    required this.id,
    required this.name,
    required this.color,
    List<KanbanCard>? cards,
    this.wipLimit,
  }) : cards = cards ?? [];

  bool get isOverWipLimit =>
      wipLimit != null && cards.where((c) => !c.archived).length > wipLimit!;

  List<KanbanCard> get activeCards => cards.where((c) => !c.archived).toList();
}

/// A kanban board containing columns.
class KanbanBoard {
  final String id;
  String name;
  List<KanbanColumn> columns;
  DateTime createdAt;

  KanbanBoard({
    required this.id,
    required this.name,
    List<KanbanColumn>? columns,
    DateTime? createdAt,
  })  : columns = columns ?? [],
        createdAt = createdAt ?? DateTime.now();
}

/// Service for managing kanban boards.
class KanbanBoardService {
  final List<KanbanBoard> _boards = [];

  List<KanbanBoard> get boards => List.unmodifiable(_boards);

  /// Create a new board with default columns.
  KanbanBoard createBoard(String name) {
    final board = KanbanBoard(
      id: 'board_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      columns: [
        KanbanColumn(
          id: 'col_todo',
          name: 'To Do',
          color: const Color(0xFF90CAF9),
        ),
        KanbanColumn(
          id: 'col_progress',
          name: 'In Progress',
          color: const Color(0xFFFFCC02),
          wipLimit: 5,
        ),
        KanbanColumn(
          id: 'col_done',
          name: 'Done',
          color: const Color(0xFF81C784),
        ),
      ],
    );
    _boards.add(board);
    return board;
  }

  /// Add a column to a board.
  KanbanColumn addColumn(KanbanBoard board, String name, Color color,
      {int? wipLimit}) {
    final col = KanbanColumn(
      id: 'col_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      color: color,
      wipLimit: wipLimit,
    );
    board.columns.add(col);
    return col;
  }

  /// Remove a column (moves its cards to the first column).
  void removeColumn(KanbanBoard board, KanbanColumn column) {
    if (board.columns.length <= 1) return;
    final target =
        board.columns.firstWhere((c) => c.id != column.id);
    target.cards.addAll(column.cards);
    board.columns.remove(column);
  }

  /// Add a card to a column.
  KanbanCard addCard(
    KanbanColumn column, {
    required String title,
    String description = '',
    List<KanbanLabel> labels = const [],
    KanbanPriority priority = KanbanPriority.medium,
    DateTime? dueDate,
  }) {
    final card = KanbanCard(
      id: 'card_${DateTime.now().millisecondsSinceEpoch}_${column.cards.length}',
      title: title,
      description: description,
      labels: labels,
      priority: priority,
      dueDate: dueDate,
    );
    column.cards.add(card);
    return card;
  }

  /// Move a card to another column at a given position.
  void moveCard(KanbanCard card, KanbanColumn from, KanbanColumn to,
      [int? position]) {
    from.cards.remove(card);
    final pos = position ?? to.cards.length;
    to.cards.insert(pos.clamp(0, to.cards.length), card);
  }

  /// Reorder a card within its column.
  void reorderCard(KanbanColumn column, int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= column.cards.length) return;
    if (newIndex < 0 || newIndex > column.cards.length) return;
    final card = column.cards.removeAt(oldIndex);
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    column.cards.insert(adjusted.clamp(0, column.cards.length), card);
  }

  /// Archive a card.
  void archiveCard(KanbanCard card) {
    card.archived = true;
  }

  /// Get board statistics.
  Map<String, dynamic> getBoardStats(KanbanBoard board) {
    int totalCards = 0;
    int overdueCards = 0;
    int archivedCards = 0;
    final columnCounts = <String, int>{};

    for (final col in board.columns) {
      final active = col.activeCards;
      columnCounts[col.name] = active.length;
      totalCards += active.length;
      overdueCards += active.where((c) => c.isOverdue).length;
      archivedCards += col.cards.where((c) => c.archived).length;
    }

    return {
      'totalCards': totalCards,
      'overdueCards': overdueCards,
      'archivedCards': archivedCards,
      'columnCounts': columnCounts,
    };
  }

  /// Filter cards in a board by label name.
  List<KanbanCard> filterByLabel(KanbanBoard board, String labelName) {
    return board.columns
        .expand((col) => col.activeCards)
        .where((card) => card.labels.any((l) => l.name == labelName))
        .toList();
  }

  /// Filter cards by priority.
  List<KanbanCard> filterByPriority(KanbanBoard board, KanbanPriority priority) {
    return board.columns
        .expand((col) => col.activeCards)
        .where((card) => card.priority == priority)
        .toList();
  }

  /// Generate sample board for demo.
  KanbanBoard createSampleBoard() {
    final board = createBoard('My Project');

    final todo = board.columns[0];
    final inProgress = board.columns[1];
    final done = board.columns[2];

    addCard(todo,
        title: 'Design login page',
        description: 'Create mockups for the new login flow',
        labels: [KanbanLabel.defaultLabels[1]], // Feature
        priority: KanbanPriority.high,
        dueDate: DateTime.now().add(const Duration(days: 3)));

    addCard(todo,
        title: 'Fix navigation bug',
        description: 'Back button not working on settings screen',
        labels: [KanbanLabel.defaultLabels[0]], // Bug
        priority: KanbanPriority.urgent,
        dueDate: DateTime.now().add(const Duration(days: 1)));

    addCard(todo,
        title: 'Research analytics SDK',
        labels: [KanbanLabel.defaultLabels[3]], // Idea
        priority: KanbanPriority.low);

    addCard(inProgress,
        title: 'Implement dark mode',
        description: 'Add theme switching with system preference detection',
        labels: [KanbanLabel.defaultLabels[1]], // Feature
        priority: KanbanPriority.medium,
        dueDate: DateTime.now().add(const Duration(days: 5)));

    addCard(inProgress,
        title: 'Update dependencies',
        labels: [KanbanLabel.defaultLabels[2]], // Chore
        priority: KanbanPriority.low);

    addCard(done,
        title: 'Setup CI pipeline',
        labels: [KanbanLabel.defaultLabels[2]], // Chore
        priority: KanbanPriority.high);

    addCard(done,
        title: 'Write API documentation',
        labels: [KanbanLabel.defaultLabels[1]], // Feature
        priority: KanbanPriority.medium);

    return board;
  }
}
