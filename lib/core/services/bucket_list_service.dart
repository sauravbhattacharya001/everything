import '../../models/bucket_item.dart';

/// Service for bucket list analytics and insights.
class BucketListService {
  const BucketListService();

  /// Compute aggregate statistics.
  BucketStats computeStats(List<BucketItem> items) {
    if (items.isEmpty) {
      return const BucketStats(
        totalItems: 0,
        completedItems: 0,
        overdueItems: 0,
        completionRate: 0,
        totalEstimatedCost: 0,
        avgRating: 0,
        categoryBreakdown: {},
        categoryCompleted: {},
        priorityBreakdown: {},
        effortBreakdown: {},
        avgDaysToComplete: 0,
      );
    }

    final completed = items.where((i) => i.isCompleted).toList();
    final overdue = items.where((i) => i.isOverdue).toList();
    final rated = completed.where((i) => i.rating > 0);

    final catBreak = <BucketCategory, int>{};
    final catComp = <BucketCategory, int>{};
    final priBreak = <BucketPriority, int>{};
    final effBreak = <BucketEffort, int>{};
    final tagCount = <String, int>{};

    for (final item in items) {
      catBreak[item.category] = (catBreak[item.category] ?? 0) + 1;
      priBreak[item.priority] = (priBreak[item.priority] ?? 0) + 1;
      effBreak[item.effort] = (effBreak[item.effort] ?? 0) + 1;
      if (item.isCompleted) {
        catComp[item.category] = (catComp[item.category] ?? 0) + 1;
      }
      for (final tag in item.tags) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }

    BucketCategory? topCat;
    int topCatCount = 0;
    for (final e in catBreak.entries) {
      if (e.value > topCatCount) {
        topCatCount = e.value;
        topCat = e.key;
      }
    }

    String? topTag;
    int topTagCount = 0;
    for (final e in tagCount.entries) {
      if (e.value > topTagCount) {
        topTagCount = e.value;
        topTag = e.key;
      }
    }

    final totalCost = items
        .where((i) => i.estimatedCost != null)
        .fold<double>(0, (s, i) => s + i.estimatedCost!);

    int avgDays = 0;
    if (completed.isNotEmpty) {
      final totalDays = completed.fold<int>(
        0,
        (s, i) => s + i.completedAt!.difference(i.createdAt).inDays,
      );
      avgDays = totalDays ~/ completed.length;
    }

    return BucketStats(
      totalItems: items.length,
      completedItems: completed.length,
      overdueItems: overdue.length,
      completionRate:
          items.isEmpty ? 0 : completed.length / items.length * 100,
      totalEstimatedCost: totalCost,
      avgRating: rated.isEmpty
          ? 0
          : rated.fold<int>(0, (s, i) => s + i.rating) / rated.length,
      categoryBreakdown: catBreak,
      categoryCompleted: catComp,
      priorityBreakdown: priBreak,
      effortBreakdown: effBreak,
      avgDaysToComplete: avgDays,
      topCategory: topCat,
      mostUsedTag: topTag,
    );
  }

  /// Generate insights from bucket list data.
  List<BucketInsight> generateInsights(List<BucketItem> items) {
    final insights = <BucketInsight>[];
    if (items.isEmpty) return insights;

    final stats = computeStats(items);
    final completed = items.where((i) => i.isCompleted).toList();
    final pending = items.where((i) => !i.isCompleted).toList();

    // Completion rate insight
    if (stats.completionRate >= 50) {
      insights.add(BucketInsight(
        emoji: '🏆',
        title: 'Great Progress!',
        description:
            'You\'ve completed ${stats.completionRate.toStringAsFixed(0)}% of your bucket list. Keep it up!',
      ));
    } else if (items.length >= 5 && stats.completionRate < 20) {
      insights.add(const BucketInsight(
        emoji: '🚀',
        title: 'Time to Start!',
        description:
            'Most of your bucket list is still waiting. Pick one easy item and go for it!',
      ));
    }

    // Overdue items
    if (stats.overdueItems > 0) {
      insights.add(BucketInsight(
        emoji: '⏰',
        title: '${stats.overdueItems} Overdue',
        description:
            'You have ${stats.overdueItems} item${stats.overdueItems > 1 ? 's' : ''} past their target date. Time to revisit or reschedule!',
      ));
    }

    // Category balance
    if (stats.categoryBreakdown.length >= 3) {
      final cats = stats.categoryBreakdown.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final topCat = cats.first;
      final ratio = topCat.value / items.length;
      if (ratio > 0.5) {
        insights.add(BucketInsight(
          emoji: '📊',
          title: 'Category Focus',
          description:
              '${(ratio * 100).toStringAsFixed(0)}% of your items are ${topCat.key.label}. Consider diversifying!',
        ));
      }
    }

    // Cost insight
    if (stats.totalEstimatedCost > 0) {
      final completedCost = completed
          .where((i) => i.estimatedCost != null)
          .fold<double>(0, (s, i) => s + i.estimatedCost!);
      final pendingCost = stats.totalEstimatedCost - completedCost;
      if (pendingCost > 0) {
        insights.add(BucketInsight(
          emoji: '💰',
          title: 'Budget Needed',
          description:
              'Remaining items need ~\$${pendingCost.toStringAsFixed(0)} total. Plan ahead!',
        ));
      }
    }

    // Effort distribution
    final easyPending =
        pending.where((i) => i.effort == BucketEffort.easy).length;
    if (easyPending > 0) {
      insights.add(BucketInsight(
        emoji: '🟢',
        title: '$easyPending Quick Wins',
        description:
            'You have $easyPending easy items waiting. Great for building momentum!',
      ));
    }

    // Rating insight
    if (stats.avgRating >= 4) {
      insights.add(BucketInsight(
        emoji: '⭐',
        title: 'High Satisfaction',
        description:
            'Your completed items average ${stats.avgRating.toStringAsFixed(1)}/5. You\'re choosing well!',
      ));
    }

    // Longevity insight
    final oldItems = pending.where((i) => i.daysSinceCreated > 365).toList();
    if (oldItems.isNotEmpty) {
      insights.add(BucketInsight(
        emoji: '📜',
        title: '${oldItems.length} Year+ Old Dreams',
        description:
            'Some items have been on your list over a year. Still want them, or time to let go?',
      ));
    }

    // Tag insight
    if (stats.mostUsedTag != null) {
      insights.add(BucketInsight(
        emoji: '🏷️',
        title: 'Top Tag: #${stats.mostUsedTag}',
        description:
            'Your most common tag. It reflects what matters most to you.',
      ));
    }

    return insights;
  }

  /// Suggest next items to tackle based on priority and effort.
  List<BucketItem> suggestNext(List<BucketItem> items, {int limit = 3}) {
    final pending = items.where((i) => !i.isCompleted).toList();
    if (pending.isEmpty) return [];

    // Score: higher priority + lower effort = higher score
    pending.sort((a, b) {
      final scoreA = a.priority.value * 2 + (4 - a.effort.index);
      final scoreB = b.priority.value * 2 + (4 - b.effort.index);
      if (scoreA != scoreB) return scoreB.compareTo(scoreA);
      // Tie-break: overdue first, then by target date
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      if (a.targetDate != null && b.targetDate != null) {
        return a.targetDate!.compareTo(b.targetDate!);
      }
      return 0;
    });

    return pending.take(limit).toList();
  }
}
