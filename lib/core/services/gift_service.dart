import '../../models/gift_item.dart';

/// Service for gift tracker analytics and management logic.
class GiftService {
  const GiftService();

  /// Total spent on gifts given.
  double totalSpent(List<GiftItem> items) => items
      .where((i) =>
          i.direction == GiftDirection.giving && i.actualCost != null)
      .fold(0.0, (sum, i) => sum + i.actualCost!);

  /// Total budget allocated across all giving gifts.
  double totalBudget(List<GiftItem> items) => items
      .where(
          (i) => i.direction == GiftDirection.giving && i.budget != null)
      .fold(0.0, (sum, i) => sum + i.budget!);

  /// Total saved (budget - actual for purchased/given items).
  double totalSaved(List<GiftItem> items) => items
      .where((i) =>
          i.direction == GiftDirection.giving &&
          i.budget != null &&
          i.actualCost != null)
      .fold(0.0, (sum, i) => sum + (i.budget! - i.actualCost!));

  /// Count by status.
  Map<GiftStatus, int> statusBreakdown(List<GiftItem> items) {
    final counts = <GiftStatus, int>{};
    for (final item in items) {
      counts[item.status] = (counts[item.status] ?? 0) + 1;
    }
    return counts;
  }

  /// Count by occasion.
  Map<GiftOccasion, int> occasionBreakdown(List<GiftItem> items) {
    final counts = <GiftOccasion, int>{};
    for (final item in items) {
      counts[item.occasion] = (counts[item.occasion] ?? 0) + 1;
    }
    return counts;
  }

  /// Count by recipient/giver.
  Map<String, int> personBreakdown(List<GiftItem> items) {
    final counts = <String, int>{};
    for (final item in items) {
      counts[item.recipientOrGiver] =
          (counts[item.recipientOrGiver] ?? 0) + 1;
    }
    return counts;
  }

  /// Spending per person.
  Map<String, double> spendingPerPerson(List<GiftItem> items) {
    final spending = <String, double>{};
    for (final item in items.where(
        (i) => i.direction == GiftDirection.giving && i.actualCost != null)) {
      spending[item.recipientOrGiver] =
          (spending[item.recipientOrGiver] ?? 0) + item.actualCost!;
    }
    return spending;
  }

  /// Spending per occasion.
  Map<GiftOccasion, double> spendingPerOccasion(List<GiftItem> items) {
    final spending = <GiftOccasion, double>{};
    for (final item in items.where(
        (i) => i.direction == GiftDirection.giving && i.actualCost != null)) {
      spending[item.occasion] =
          (spending[item.occasion] ?? 0) + item.actualCost!;
    }
    return spending;
  }

  /// Items with upcoming occasions (sorted by date).
  List<GiftItem> upcoming(List<GiftItem> items, {int days = 30}) {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: days));
    return items
        .where((i) =>
            i.occasionDate != null &&
            i.occasionDate!.isAfter(now) &&
            i.occasionDate!.isBefore(cutoff))
        .toList()
      ..sort((a, b) => a.occasionDate!.compareTo(b.occasionDate!));
  }

  /// Items over budget.
  List<GiftItem> overBudget(List<GiftItem> items) =>
      items.where((i) => i.isOverBudget).toList();

  /// Gifts received without thank-you note sent.
  List<GiftItem> pendingThankYou(List<GiftItem> items) => items
      .where((i) =>
          i.direction == GiftDirection.receiving &&
          i.status == GiftStatus.received &&
          !i.thankYouSent)
      .toList();

  /// Average rating for received gifts.
  double avgRating(List<GiftItem> items) {
    final rated = items.where((i) => i.rating > 0).toList();
    if (rated.isEmpty) return 0;
    return rated.fold(0, (sum, i) => sum + i.rating) / rated.length;
  }

  /// Most generous person (highest total spent on giving to them).
  String? topRecipient(List<GiftItem> items) {
    final spending = spendingPerPerson(items);
    if (spending.isEmpty) return null;
    return spending.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  /// Monthly spending for the current year.
  Map<int, double> monthlySpending(List<GiftItem> items) {
    final spending = <int, double>{};
    final year = DateTime.now().year;
    for (final item in items.where((i) =>
        i.direction == GiftDirection.giving &&
        i.actualCost != null &&
        i.createdAt.year == year)) {
      final month = item.createdAt.month;
      spending[month] = (spending[month] ?? 0) + item.actualCost!;
    }
    return spending;
  }

  /// Gift ideas (status == idea) count.
  int ideaCount(List<GiftItem> items) =>
      items.where((i) => i.status == GiftStatus.idea).length;

  /// Generate insights list.
  List<String> generateInsights(List<GiftItem> items) {
    final insights = <String>[];
    if (items.isEmpty) return ['Start tracking gifts to see insights!'];

    final spent = totalSpent(items);
    final saved = totalSaved(items);
    final pending = pendingThankYou(items);
    final over = overBudget(items);
    final ideas = ideaCount(items);
    final top = topRecipient(items);

    if (spent > 0) {
      insights.add(
          '💰 You\'ve spent \$${spent.toStringAsFixed(2)} on gifts this cycle.');
    }
    if (saved > 0) {
      insights.add(
          '🎯 You saved \$${saved.toStringAsFixed(2)} vs your budget — nice!');
    } else if (saved < 0) {
      insights.add(
          '⚠️ You\'re \$${(-saved).toStringAsFixed(2)} over budget overall.');
    }
    if (pending.isNotEmpty) {
      insights.add(
          '✉️ ${pending.length} received gift(s) still need a thank-you note.');
    }
    if (over.isNotEmpty) {
      insights.add('🔴 ${over.length} gift(s) went over budget.');
    }
    if (ideas > 0) {
      insights.add('💡 You have $ideas gift idea(s) saved for later.');
    }
    if (top != null) {
      insights.add('👑 Your top recipient is $top.');
    }

    final avgR = avgRating(items);
    if (avgR > 0) {
      insights.add(
          '⭐ Average gift rating: ${avgR.toStringAsFixed(1)}/5.');
    }

    if (insights.isEmpty) {
      insights.add('Keep tracking to unlock insights!');
    }
    return insights;
  }
}
