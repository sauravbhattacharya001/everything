import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/kanban_board_service.dart';

void main() {
  late KanbanBoardService service;

  setUp(() {
    service = KanbanBoardService();
  });

  group('KanbanBoardService', () {
    test('createBoard creates board with 3 default columns', () {
      final board = service.createBoard('Test Board');
      expect(board.name, 'Test Board');
      expect(board.columns.length, 3);
      expect(board.columns[0].name, 'To Do');
      expect(board.columns[1].name, 'In Progress');
      expect(board.columns[2].name, 'Done');
    });

    test('addColumn adds column to board', () {
      final board = service.createBoard('Test');
      service.addColumn(board, 'Review', Colors.purple);
      expect(board.columns.length, 4);
      expect(board.columns.last.name, 'Review');
    });

    test('removeColumn moves cards to first column', () {
      final board = service.createBoard('Test');
      final col = board.columns[1]; // In Progress
      service.addCard(col, title: 'Card A');
      service.removeColumn(board, col);
      expect(board.columns.length, 2);
      expect(board.columns[0].cards.length, 1);
      expect(board.columns[0].cards[0].title, 'Card A');
    });

    test('cannot remove last column', () {
      final board = service.createBoard('Test');
      board.columns.removeRange(1, 3);
      service.removeColumn(board, board.columns[0]);
      expect(board.columns.length, 1);
    });

    test('addCard creates card with correct properties', () {
      final board = service.createBoard('Test');
      final card = service.addCard(
        board.columns[0],
        title: 'My Task',
        description: 'Details',
        priority: KanbanPriority.high,
        labels: [KanbanLabel.defaultLabels[0]],
      );
      expect(card.title, 'My Task');
      expect(card.description, 'Details');
      expect(card.priority, KanbanPriority.high);
      expect(card.labels.length, 1);
      expect(card.labels[0].name, 'Bug');
    });

    test('moveCard moves card between columns', () {
      final board = service.createBoard('Test');
      final card = service.addCard(board.columns[0], title: 'Move me');
      service.moveCard(card, board.columns[0], board.columns[1]);
      expect(board.columns[0].cards.length, 0);
      expect(board.columns[1].cards.length, 1);
      expect(board.columns[1].cards[0].title, 'Move me');
    });

    test('moveCard inserts at specified position', () {
      final board = service.createBoard('Test');
      service.addCard(board.columns[1], title: 'Existing');
      final card = service.addCard(board.columns[0], title: 'Insert');
      service.moveCard(card, board.columns[0], board.columns[1], 0);
      expect(board.columns[1].cards[0].title, 'Insert');
      expect(board.columns[1].cards[1].title, 'Existing');
    });

    test('reorderCard reorders within column', () {
      final board = service.createBoard('Test');
      final col = board.columns[0];
      service.addCard(col, title: 'A');
      service.addCard(col, title: 'B');
      service.addCard(col, title: 'C');
      service.reorderCard(col, 0, 2);
      expect(col.cards[0].title, 'B');
      expect(col.cards[1].title, 'A');
    });

    test('archiveCard sets archived flag', () {
      final board = service.createBoard('Test');
      final card = service.addCard(board.columns[0], title: 'Archive me');
      service.archiveCard(card);
      expect(card.archived, true);
      expect(board.columns[0].activeCards.length, 0);
    });

    test('getBoardStats counts correctly', () {
      final board = service.createBoard('Test');
      service.addCard(board.columns[0], title: 'T1');
      service.addCard(board.columns[0], title: 'T2');
      service.addCard(board.columns[1], title: 'T3');
      final archived = service.addCard(board.columns[2], title: 'T4');
      service.archiveCard(archived);

      final stats = service.getBoardStats(board);
      expect(stats['totalCards'], 3);
      expect(stats['archivedCards'], 1);
    });

    test('filterByLabel returns matching cards', () {
      final board = service.createBoard('Test');
      service.addCard(board.columns[0],
          title: 'Bug card', labels: [KanbanLabel.defaultLabels[0]]);
      service.addCard(board.columns[0], title: 'No label');
      final results = service.filterByLabel(board, 'Bug');
      expect(results.length, 1);
      expect(results[0].title, 'Bug card');
    });

    test('filterByPriority returns matching cards', () {
      final board = service.createBoard('Test');
      service.addCard(board.columns[0],
          title: 'Urgent', priority: KanbanPriority.urgent);
      service.addCard(board.columns[0],
          title: 'Low', priority: KanbanPriority.low);
      final results = service.filterByPriority(board, KanbanPriority.urgent);
      expect(results.length, 1);
      expect(results[0].title, 'Urgent');
    });

    test('isOverdue detects overdue cards', () {
      final card = KanbanCard(
        id: 'test',
        title: 'Overdue',
        dueDate: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(card.isOverdue, true);
    });

    test('wipLimit violation detected', () {
      final col = KanbanColumn(
        id: 'c1',
        name: 'WIP',
        color: Colors.blue,
        wipLimit: 2,
      );
      col.cards.add(KanbanCard(id: '1', title: 'A'));
      col.cards.add(KanbanCard(id: '2', title: 'B'));
      expect(col.isOverWipLimit, false);
      col.cards.add(KanbanCard(id: '3', title: 'C'));
      expect(col.isOverWipLimit, true);
    });

    test('createSampleBoard has populated columns', () {
      final board = service.createSampleBoard();
      expect(board.name, 'My Project');
      expect(board.columns[0].cards.isNotEmpty, true);
      expect(board.columns[1].cards.isNotEmpty, true);
      expect(board.columns[2].cards.isNotEmpty, true);
    });

    test('boards list is maintained', () {
      expect(service.boards.length, 0);
      service.createBoard('Board 1');
      service.createBoard('Board 2');
      expect(service.boards.length, 2);
    });
  });
}
