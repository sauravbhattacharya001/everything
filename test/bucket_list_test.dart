import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/bucket_item.dart';
import 'package:everything/core/services/bucket_list_service.dart';

void main() {
  final service = const BucketListService();

  group('BucketItem', () {
    test('isCompleted returns true when completedAt is set', () {
      final item = _makeItem(completedAt: DateTime.now());
      expect(item.isCompleted, isTrue);
    });

    test('isCompleted returns false when completedAt is null', () {
      final item = _makeItem();
      expect(item.isCompleted, isFalse);
    });

    test('isOverdue when target date is past and not completed', () {
      final item = _makeItem(
        targetDate: DateTime.now().subtract(const Duration(days: 10)),
      );
      expect(item.isOverdue, isTrue);
    });

    test('not overdue when completed even if target is past', () {
      final item = _makeItem(
        targetDate: DateTime.now().subtract(const Duration(days: 10)),
        completedAt: DateTime.now(),
      );
      expect(item.isOverdue, isFalse);
    });

    test('not overdue when target is in future', () {
      final item = _makeItem(
        targetDate: DateTime.now().add(const Duration(days: 30)),
      );
      expect(item.isOverdue, isFalse);
    });

    test('daysUntilTarget returns correct value', () {
      final item = _makeItem(
        targetDate: DateTime.now().add(const Duration(days: 15)),
      );
      expect(item.daysUntilTarget, closeTo(15, 1));
    });

    test('daysUntilTarget returns -1 when no target', () {
      final item = _makeItem();
      expect(item.daysUntilTarget, -1);
    });

    test('daysSinceCreated is non-negative', () {
      final item = _makeItem();
      expect(item.daysSinceCreated, greaterThanOrEqualTo(0));
    });

    test('markComplete sets completedAt and optional fields', () {
      final item = _makeItem();
      final completed = item.markComplete(notes: 'Amazing!', rating: 5);
      expect(completed.isCompleted, isTrue);
      expect(completed.completionNotes, 'Amazing!');
      expect(completed.rating, 5);
      expect(completed.id, item.id);
    });

    test('copyWith preserves unchanged fields', () {
      final item = _makeItem(title: 'Original', location: 'Paris');
      final copy = item.copyWith(title: 'Updated');
      expect(copy.title, 'Updated');
      expect(copy.location, 'Paris');
      expect(copy.category, item.category);
    });
  });

  group('BucketCategory', () {
    test('all categories have label and emoji', () {
      for (final c in BucketCategory.values) {
        expect(c.label, isNotEmpty);
        expect(c.emoji, isNotEmpty);
      }
    });

    test('has 12 categories', () {
      expect(BucketCategory.values.length, 12);
    });
  });

  group('BucketPriority', () {
    test('values are ordered 1-5', () {
      expect(BucketPriority.dream.value, 1);
      expect(BucketPriority.urgent.value, 5);
    });
  });

  group('BucketListService.computeStats', () {
    test('empty list returns zero stats', () {
      final stats = service.computeStats([]);
      expect(stats.totalItems, 0);
      expect(stats.completedItems, 0);
      expect(stats.completionRate, 0);
    });

    test('counts completed and overdue items', () {
      final items = [
        _makeItem(completedAt: DateTime.now()),
        _makeItem(completedAt: DateTime.now()),
        _makeItem(targetDate: DateTime.now().subtract(const Duration(days: 5))),
        _makeItem(),
      ];
      final stats = service.computeStats(items);
      expect(stats.totalItems, 4);
      expect(stats.completedItems, 2);
      expect(stats.overdueItems, 1);
      expect(stats.completionRate, 50.0);
    });

    test('calculates category breakdown', () {
      final items = [
        _makeItem(category: BucketCategory.travel),
        _makeItem(category: BucketCategory.travel),
        _makeItem(category: BucketCategory.career),
      ];
      final stats = service.computeStats(items);
      expect(stats.categoryBreakdown[BucketCategory.travel], 2);
      expect(stats.categoryBreakdown[BucketCategory.career], 1);
    });

    test('calculates total estimated cost', () {
      final items = [
        _makeItem(estimatedCost: 500),
        _makeItem(estimatedCost: 1500),
        _makeItem(), // no cost
      ];
      final stats = service.computeStats(items);
      expect(stats.totalEstimatedCost, 2000);
    });

    test('calculates average rating from completed items only', () {
      final items = [
        _makeItem(completedAt: DateTime.now(), rating: 4),
        _makeItem(completedAt: DateTime.now(), rating: 5),
        _makeItem(rating: 3), // not completed, ignored
      ];
      final stats = service.computeStats(items);
      expect(stats.avgRating, 4.5);
    });

    test('finds top category', () {
      final items = [
        _makeItem(category: BucketCategory.adventure),
        _makeItem(category: BucketCategory.adventure),
        _makeItem(category: BucketCategory.adventure),
        _makeItem(category: BucketCategory.food),
      ];
      final stats = service.computeStats(items);
      expect(stats.topCategory, BucketCategory.adventure);
    });

    test('finds most used tag', () {
      final items = [
        _makeItem(tags: ['solo', 'epic']),
        _makeItem(tags: ['solo']),
        _makeItem(tags: ['epic']),
        _makeItem(tags: ['solo']),
      ];
      final stats = service.computeStats(items);
      expect(stats.mostUsedTag, 'solo');
    });

    test('priority breakdown counts correctly', () {
      final items = [
        _makeItem(priority: BucketPriority.urgent),
        _makeItem(priority: BucketPriority.urgent),
        _makeItem(priority: BucketPriority.dream),
      ];
      final stats = service.computeStats(items);
      expect(stats.priorityBreakdown[BucketPriority.urgent], 2);
      expect(stats.priorityBreakdown[BucketPriority.dream], 1);
    });

    test('effort breakdown counts correctly', () {
      final items = [
        _makeItem(effort: BucketEffort.easy),
        _makeItem(effort: BucketEffort.epic),
        _makeItem(effort: BucketEffort.easy),
      ];
      final stats = service.computeStats(items);
      expect(stats.effortBreakdown[BucketEffort.easy], 2);
      expect(stats.effortBreakdown[BucketEffort.epic], 1);
    });

    test('average days to complete calculated', () {
      final now = DateTime.now();
      final items = [
        _makeItem(
          createdAt: now.subtract(const Duration(days: 10)),
          completedAt: now,
        ),
        _makeItem(
          createdAt: now.subtract(const Duration(days: 20)),
          completedAt: now,
        ),
      ];
      final stats = service.computeStats(items);
      expect(stats.avgDaysToComplete, 15);
    });
  });

  group('BucketListService.generateInsights', () {
    test('empty list returns no insights', () {
      expect(service.generateInsights([]), isEmpty);
    });

    test('high completion rate generates congratulatory insight', () {
      final items = [
        _makeItem(completedAt: DateTime.now()),
        _makeItem(completedAt: DateTime.now()),
        _makeItem(completedAt: DateTime.now()),
      ];
      final insights = service.generateInsights(items);
      expect(insights.any((i) => i.title == 'Great Progress!'), isTrue);
    });

    test('overdue items generate alert insight', () {
      final items = [
        _makeItem(targetDate: DateTime.now().subtract(const Duration(days: 5))),
        _makeItem(),
      ];
      final insights = service.generateInsights(items);
      expect(insights.any((i) => i.title.contains('Overdue')), isTrue);
    });

    test('easy pending items generate quick wins insight', () {
      final items = [
        _makeItem(effort: BucketEffort.easy),
        _makeItem(effort: BucketEffort.easy),
      ];
      final insights = service.generateInsights(items);
      expect(insights.any((i) => i.title.contains('Quick Wins')), isTrue);
    });

    test('old items generate longevity insight', () {
      final items = [
        _makeItem(createdAt: DateTime.now().subtract(const Duration(days: 400))),
      ];
      final insights = service.generateInsights(items);
      expect(insights.any((i) => i.title.contains('Year+')), isTrue);
    });

    test('low completion rate with many items generates start insight', () {
      final items = List.generate(6, (_) => _makeItem());
      final insights = service.generateInsights(items);
      expect(insights.any((i) => i.title == 'Time to Start!'), isTrue);
    });

    test('high avg rating generates satisfaction insight', () {
      final items = [
        _makeItem(completedAt: DateTime.now(), rating: 5),
        _makeItem(completedAt: DateTime.now(), rating: 4),
      ];
      final insights = service.generateInsights(items);
      expect(insights.any((i) => i.title == 'High Satisfaction'), isTrue);
    });

    test('cost insight generated when items have costs', () {
      final items = [
        _makeItem(estimatedCost: 5000),
      ];
      final insights = service.generateInsights(items);
      expect(insights.any((i) => i.title == 'Budget Needed'), isTrue);
    });

    test('category focus insight when >50% in one category', () {
      final items = [
        _makeItem(category: BucketCategory.travel),
        _makeItem(category: BucketCategory.travel),
        _makeItem(category: BucketCategory.travel),
        _makeItem(category: BucketCategory.career),
        _makeItem(category: BucketCategory.food),
      ];
      final insights = service.generateInsights(items);
      expect(insights.any((i) => i.title == 'Category Focus'), isTrue);
    });

    test('tag insight when tags exist', () {
      final items = [
        _makeItem(tags: ['bucket2025']),
        _makeItem(tags: ['bucket2025']),
      ];
      final insights = service.generateInsights(items);
      expect(insights.any((i) => i.title.contains('Top Tag')), isTrue);
    });
  });

  group('BucketListService.suggestNext', () {
    test('empty list returns empty suggestions', () {
      expect(service.suggestNext([]), isEmpty);
    });

    test('only returns pending items', () {
      final items = [
        _makeItem(completedAt: DateTime.now()),
        _makeItem(title: 'Pending'),
      ];
      final suggestions = service.suggestNext(items);
      expect(suggestions.length, 1);
      expect(suggestions.first.title, 'Pending');
    });

    test('higher priority items come first', () {
      final items = [
        _makeItem(title: 'Low', priority: BucketPriority.dream),
        _makeItem(title: 'High', priority: BucketPriority.urgent),
        _makeItem(title: 'Med', priority: BucketPriority.soon),
      ];
      final suggestions = service.suggestNext(items);
      expect(suggestions.first.title, 'High');
    });

    test('respects limit parameter', () {
      final items = List.generate(10, (i) => _makeItem(title: 'Item $i'));
      expect(service.suggestNext(items, limit: 2).length, 2);
    });

    test('overdue items prioritized among same priority', () {
      final items = [
        _makeItem(
          title: 'Overdue',
          priority: BucketPriority.soon,
          targetDate: DateTime.now().subtract(const Duration(days: 5)),
        ),
        _makeItem(title: 'Normal', priority: BucketPriority.soon),
      ];
      final suggestions = service.suggestNext(items);
      expect(suggestions.first.title, 'Overdue');
    });
  });

  group('BucketInsight', () {
    test('holds emoji, title, description', () {
      const insight = BucketInsight(
        emoji: '🎯',
        title: 'Test',
        description: 'A test insight',
      );
      expect(insight.emoji, '🎯');
      expect(insight.title, 'Test');
      expect(insight.description, 'A test insight');
    });
  });
}

// ─── Helpers ───────────────────────────────────────────────────────────

int _idCounter = 0;

BucketItem _makeItem({
  String? title,
  BucketCategory category = BucketCategory.travel,
  BucketPriority priority = BucketPriority.someday,
  BucketEffort effort = BucketEffort.moderate,
  double? estimatedCost,
  String? location,
  List<String> tags = const [],
  DateTime? createdAt,
  DateTime? targetDate,
  DateTime? completedAt,
  int rating = 0,
}) {
  return BucketItem(
    id: 'test-${_idCounter++}',
    title: title ?? 'Test Item $_idCounter',
    category: category,
    priority: priority,
    effort: effort,
    estimatedCost: estimatedCost,
    location: location,
    tags: tags,
    createdAt: createdAt ?? DateTime.now(),
    targetDate: targetDate,
    completedAt: completedAt,
    rating: rating,
  );
}
