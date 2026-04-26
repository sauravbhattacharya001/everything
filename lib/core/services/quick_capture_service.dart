import 'dart:convert';
import 'dart:math';
import '../../models/capture_item.dart';

/// Statistics for the capture inbox.
class InboxStats {
  final int totalCaptured;
  final int currentInbox;
  final int processedCount;
  final int archivedCount;
  final int staleCount;
  final int agingCount;
  final int pinnedCount;
  final double avgProcessingHours;
  final Map<CaptureCategory, int> categoryBreakdown;
  final Map<CapturePriority, int> priorityBreakdown;
  final Map<ProcessedDestination, int> destinationBreakdown;
  final double capturesPerDay;
  final double processingRate;

  InboxStats({
    required this.totalCaptured,
    required this.currentInbox,
    required this.processedCount,
    required this.archivedCount,
    required this.staleCount,
    required this.agingCount,
    required this.pinnedCount,
    required this.avgProcessingHours,
    required this.categoryBreakdown,
    required this.priorityBreakdown,
    required this.destinationBreakdown,
    required this.capturesPerDay,
    required this.processingRate,
  });
}

/// Weekly inbox report.
class WeeklyInboxReport {
  final DateTime weekStart;
  final DateTime weekEnd;
  final int captured;
  final int processed;
  final int archived;
  final int remaining;
  final double avgProcessingHours;
  final Map<CaptureCategory, int> topCategories;
  final String grade;

  WeeklyInboxReport({
    required this.weekStart,
    required this.weekEnd,
    required this.captured,
    required this.processed,
    required this.archived,
    required this.remaining,
    required this.avgProcessingHours,
    required this.topCategories,
    required this.grade,
  });
}

/// GTD-style quick-capture inbox service.
///
/// Provides low-friction capture of thoughts, ideas, and tasks with
/// processing workflow, aging alerts, and productivity statistics.
///
/// ```dart
/// final service = QuickCaptureService();
///
/// // Capture a thought
/// final item = service.capture('Read that ML paper from Arxiv',
///     category: CaptureCategory.task,
///     priority: CapturePriority.medium);
///
/// // Process it into a tracker
/// service.process(item.id, ProcessedDestination.reading,
///     note: 'Added to reading list');
///
/// // Check inbox health
/// final stats = service.getStats();
/// print('${stats.staleCount} items need attention');
/// ```
class QuickCaptureService {
  final List<CaptureItem> _items = [];
  final Random _random = Random();

  // ── Capture ─────────────────────────────────────────────────────

  /// Capture a new item into the inbox.
  CaptureItem capture(
    String text, {
    CaptureCategory category = CaptureCategory.note,
    CapturePriority priority = CapturePriority.none,
    List<String> tags = const [],
    String? note,
  }) {
    if (text.trim().isEmpty) {
      throw ArgumentError('Capture text cannot be empty.');
    }

    final item = CaptureItem(
      id: _generateId(),
      capturedAt: DateTime.now(),
      text: text.trim(),
      category: category,
      priority: priority,
      tags: tags,
      note: note,
    );
    _items.add(item);
    return item;
  }

  /// Quick capture with auto-category detection based on keywords.
  CaptureItem quickCapture(String text) {
    final lower = text.toLowerCase();
    CaptureCategory category;
    CapturePriority priority = CapturePriority.none;

    if (lower.startsWith('todo:') ||
        lower.startsWith('task:') ||
        lower.contains('need to') ||
        lower.contains('should ') ||
        lower.contains('must ')) {
      category = CaptureCategory.task;
      priority = CapturePriority.medium;
    } else if (lower.startsWith('idea:') ||
        lower.contains('what if') ||
        lower.contains('maybe ') ||
        lower.contains('could ')) {
      category = CaptureCategory.idea;
    } else if (lower.startsWith('?') ||
        lower.endsWith('?') ||
        lower.startsWith('why ') ||
        lower.startsWith('how ') ||
        lower.startsWith('what ')) {
      category = CaptureCategory.question;
    } else if (lower.startsWith('http://') ||
        lower.startsWith('https://') ||
        lower.contains('.com') ||
        lower.contains('.org')) {
      category = CaptureCategory.link;
    } else if (lower.startsWith('"') ||
        lower.startsWith('\u201c') ||
        lower.contains(' said ') ||
        lower.contains(' says ')) {
      category = CaptureCategory.quote;
    } else if (lower.startsWith('remind') ||
        lower.contains("don't forget") ||
        lower.contains('remember to')) {
      category = CaptureCategory.reminder;
      priority = CapturePriority.high;
    } else {
      category = CaptureCategory.note;
    }

    return capture(text, category: category, priority: priority);
  }

  // ── Processing ──────────────────────────────────────────────────

  /// Process an inbox item — mark it as handled and record destination.
  CaptureItem process(
    String id,
    ProcessedDestination destination, {
    String? note,
  }) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw ArgumentError('Capture item not found: $id');
    }
    final item = _items[index];
    if (item.status != CaptureStatus.inbox) {
      throw StateError(
          'Item is already ${item.status.label}, cannot process.');
    }

    final processed = item.copyWith(
      status: CaptureStatus.processed,
      processedAt: DateTime.now(),
      destination: destination,
      note: note ?? item.note,
    );
    _items[index] = processed;
    return processed;
  }

  /// Archive an item (keep for reference but remove from inbox).
  CaptureItem archive(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw ArgumentError('Capture item not found: $id');
    }
    final item = _items[index];
    if (item.status == CaptureStatus.deleted) {
      throw StateError('Cannot archive a deleted item.');
    }

    final archived = item.copyWith(
      status: CaptureStatus.archived,
      processedAt: item.processedAt ?? DateTime.now(),
    );
    _items[index] = archived;
    return archived;
  }

  /// Soft-delete an item.
  CaptureItem delete(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw ArgumentError('Capture item not found: $id');
    }
    final deleted = _items[index].copyWith(status: CaptureStatus.deleted);
    _items[index] = deleted;
    return deleted;
  }

  /// Pin/unpin an item to keep it at the top.
  CaptureItem togglePin(String id) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw ArgumentError('Capture item not found: $id');
    }
    final toggled = _items[index].copyWith(
      isPinned: !_items[index].isPinned,
    );
    _items[index] = toggled;
    return toggled;
  }

  /// Update a capture item's text, category, priority, or tags.
  CaptureItem update(
    String id, {
    String? text,
    CaptureCategory? category,
    CapturePriority? priority,
    List<String>? tags,
    String? note,
  }) {
    final index = _items.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw ArgumentError('Capture item not found: $id');
    }
    if (text != null && text.trim().isEmpty) {
      throw ArgumentError('Capture text cannot be empty.');
    }

    final updated = _items[index].copyWith(
      text: text?.trim(),
      category: category,
      priority: priority,
      tags: tags,
      note: note,
    );
    _items[index] = updated;
    return updated;
  }

  // ── Queries ─────────────────────────────────────────────────────

  /// Get all inbox items (not processed, archived, or deleted).
  List<CaptureItem> getInbox({bool sortByPriority = true}) {
    final inbox = _items
        .where((i) => i.status == CaptureStatus.inbox)
        .toList();

    if (sortByPriority) {
      inbox.sort((a, b) {
        // Pinned first
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        // Then by priority (urgent first)
        final pCmp = a.priority.sortOrder.compareTo(b.priority.sortOrder);
        if (pCmp != 0) return pCmp;
        // Then by age (oldest first)
        return a.capturedAt.compareTo(b.capturedAt);
      });
    }
    return inbox;
  }

  /// Get items that are stale (>3 days in inbox).
  List<CaptureItem> getStaleItems() =>
      _items.where((i) => i.isStale).toList();

  /// Get items that are aging (>1 day but <3 days).
  List<CaptureItem> getAgingItems() =>
      _items.where((i) => i.isAging).toList();

  /// Get processed items.
  List<CaptureItem> getProcessed() =>
      _items.where((i) => i.status == CaptureStatus.processed).toList();

  /// Get archived items.
  List<CaptureItem> getArchived() =>
      _items.where((i) => i.status == CaptureStatus.archived).toList();

  /// Get all items (excluding deleted).
  List<CaptureItem> getAll() =>
      _items.where((i) => i.status != CaptureStatus.deleted).toList();

  /// Get item by ID.
  CaptureItem? getById(String id) {
    try {
      return _items.firstWhere((i) => i.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Search items by text content.
  List<CaptureItem> search(String query) {
    if (query.trim().isEmpty) return [];
    final lower = query.toLowerCase();
    return _items
        .where((i) =>
            i.status != CaptureStatus.deleted &&
            (i.text.toLowerCase().contains(lower) ||
                (i.note?.toLowerCase().contains(lower) ?? false) ||
                i.tags.any((t) => t.toLowerCase().contains(lower))))
        .toList();
  }

  /// Filter inbox by category.
  List<CaptureItem> filterByCategory(CaptureCategory category) =>
      getInbox().where((i) => i.category == category).toList();

  /// Filter inbox by priority.
  List<CaptureItem> filterByPriority(CapturePriority priority) =>
      getInbox().where((i) => i.priority == priority).toList();

  /// Get items captured on a specific date.
  List<CaptureItem> getByDate(DateTime date) =>
      _items
          .where((i) =>
              i.status != CaptureStatus.deleted &&
              i.capturedAt.year == date.year &&
              i.capturedAt.month == date.month &&
              i.capturedAt.day == date.day)
          .toList();

  // ── Statistics ──────────────────────────────────────────────────

  /// Get comprehensive inbox statistics.
  ///
  /// Single-pass aggregation over [_items] — collects all counters,
  /// breakdowns, and processing-time sums in one traversal instead of
  /// 9+ separate `.where()` / `.map()` / `.reduce()` passes that each
  /// re-iterated the full list (previously O(9·N), now O(N)).
  InboxStats getStats() {
    int activeCount = 0;
    int inboxCount = 0;
    int processedCount = 0;
    int archivedCount = 0;
    int staleCount = 0;
    int agingCount = 0;
    int pinnedCount = 0;
    double processingHoursSum = 0;
    int processingTimeCount = 0;
    DateTime? earliest;

    final catBreakdown = <CaptureCategory, int>{};
    final prioBreakdown = <CapturePriority, int>{};
    final destBreakdown = <ProcessedDestination, int>{};

    for (final item in _items) {
      if (item.status == CaptureStatus.deleted) continue;
      activeCount++;

      // Track earliest capturedAt for captures-per-day calculation
      if (earliest == null || item.capturedAt.isBefore(earliest)) {
        earliest = item.capturedAt;
      }

      switch (item.status) {
        case CaptureStatus.inbox:
          inboxCount++;
          catBreakdown[item.category] =
              (catBreakdown[item.category] ?? 0) + 1;
          prioBreakdown[item.priority] =
              (prioBreakdown[item.priority] ?? 0) + 1;
          if (item.isStale) staleCount++;
          if (item.isAging) agingCount++;
          if (item.isPinned) pinnedCount++;
          break;
        case CaptureStatus.processed:
          processedCount++;
          if (item.destination != null) {
            destBreakdown[item.destination!] =
                (destBreakdown[item.destination!] ?? 0) + 1;
          }
          if (item.processedAt != null) {
            processingHoursSum +=
                item.processedAt!.difference(item.capturedAt).inMinutes / 60.0;
            processingTimeCount++;
          }
          break;
        case CaptureStatus.archived:
          archivedCount++;
          break;
        default:
          break;
      }
    }

    final avgHours =
        processingTimeCount > 0 ? processingHoursSum / processingTimeCount : 0.0;

    double perDay = 0;
    if (activeCount > 0 && earliest != null) {
      final days = DateTime.now().difference(earliest).inDays + 1;
      perDay = activeCount / days;
    }

    final rate = activeCount > 0
        ? (processedCount + archivedCount) / activeCount
        : 0.0;

    return InboxStats(
      totalCaptured: activeCount,
      currentInbox: inboxCount,
      processedCount: processedCount,
      archivedCount: archivedCount,
      staleCount: staleCount,
      agingCount: agingCount,
      pinnedCount: pinnedCount,
      avgProcessingHours: double.parse(avgHours.toStringAsFixed(1)),
      categoryBreakdown: catBreakdown,
      priorityBreakdown: prioBreakdown,
      destinationBreakdown: destBreakdown,
      capturesPerDay: double.parse(perDay.toStringAsFixed(1)),
      processingRate: double.parse(rate.toStringAsFixed(2)),
    );
  }

  /// Generate a weekly inbox report.
  ///
  /// Single-pass over [_items] — collects status counts, processing
  /// time, and category breakdown in one traversal instead of 5
  /// separate `.where()` passes plus a `.map().reduce()` chain
  /// (previously O(6·N), now O(N)).
  WeeklyInboxReport getWeeklyReport({DateTime? weekStart}) {
    final start = weekStart ??
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final weekStartDate = DateTime(start.year, start.month, start.day);
    final weekEndDate = weekStartDate.add(const Duration(days: 7));

    int captured = 0;
    int processedCount = 0;
    int archivedCount = 0;
    int remaining = 0;
    double processingHoursSum = 0;
    int processingTimeCount = 0;
    final catCount = <CaptureCategory, int>{};

    for (final item in _items) {
      if (item.status == CaptureStatus.deleted) continue;
      if (!item.capturedAt.isAfter(weekStartDate) ||
          !item.capturedAt.isBefore(weekEndDate)) continue;

      captured++;
      catCount[item.category] = (catCount[item.category] ?? 0) + 1;

      switch (item.status) {
        case CaptureStatus.processed:
          processedCount++;
          if (item.processedAt != null) {
            processingHoursSum +=
                item.processedAt!.difference(item.capturedAt).inMinutes / 60.0;
            processingTimeCount++;
          }
          break;
        case CaptureStatus.archived:
          archivedCount++;
          break;
        case CaptureStatus.inbox:
          remaining++;
          break;
        default:
          break;
      }
    }

    final avgHours =
        processingTimeCount > 0 ? processingHoursSum / processingTimeCount : 0.0;

    final processRate =
        captured > 0 ? (processedCount + archivedCount) / captured : 1.0;
    String grade;
    if (processRate >= 0.9) {
      grade = 'A';
    } else if (processRate >= 0.75) {
      grade = 'B';
    } else if (processRate >= 0.5) {
      grade = 'C';
    } else if (processRate >= 0.25) {
      grade = 'D';
    } else {
      grade = 'F';
    }

    return WeeklyInboxReport(
      weekStart: weekStartDate,
      weekEnd: weekEndDate,
      captured: captured,
      processed: processedCount,
      archived: archivedCount,
      remaining: remaining,
      avgProcessingHours:
          double.parse(avgHours.toStringAsFixed(1)),
      topCategories: catCount,
      grade: grade,
    );
  }

  // ── Bulk operations ─────────────────────────────────────────────

  /// Archive all stale items at once.
  int archiveStale() {
    final stale = getStaleItems();
    for (final item in stale) {
      archive(item.id);
    }
    return stale.length;
  }

  /// Process multiple items to the same destination.
  int bulkProcess(
    List<String> ids,
    ProcessedDestination destination, {
    String? note,
  }) {
    int count = 0;
    for (final id in ids) {
      try {
        process(id, destination, note: note);
        count++;
      } catch (_) {
        // Skip invalid items
      }
    }
    return count;
  }

  /// Purge all deleted items permanently.
  int purgeDeleted() {
    final before = _items.length;
    _items.removeWhere((i) => i.status == CaptureStatus.deleted);
    return before - _items.length;
  }

  // ── Serialization ───────────────────────────────────────────────

  /// Export all items as JSON string.
  String exportJson() {
    final data = _items.map((i) => i.toJson()).toList();
    return jsonEncode(data);
  }

  /// Import items from JSON string.
  int importJson(String json) {
    final List<dynamic> data = jsonDecode(json) as List<dynamic>;
    int count = 0;
    for (final item in data) {
      try {
        final capture = CaptureItem.fromJson(
            item as Map<String, dynamic>);
        // Skip duplicates
        if (!_items.any((i) => i.id == capture.id)) {
          _items.add(capture);
          count++;
        }
      } catch (_) {
        // Skip malformed entries
      }
    }
    return count;
  }

  /// Number of items currently in system.
  int get totalItems => _items.length;

  /// Number of items in inbox.
  int get inboxCount =>
      _items.where((i) => i.status == CaptureStatus.inbox).length;

  // ── Internal ────────────────────────────────────────────────────

  String _generateId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final rand = _random.nextInt(99999).toString().padLeft(5, '0');
    return 'cap_${now}_$rand';
  }
}
