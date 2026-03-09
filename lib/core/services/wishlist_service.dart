import '../../models/wishlist_item.dart';

/// Service for wishlist analytics and management.
class WishlistService {
  const WishlistService();

  /// Total estimated cost of all unpurchased items.
  double totalWishlistCost(List<WishlistItem> items) => items
      .where((i) => !i.isPurchased && i.estimatedPrice != null)
      .fold(0.0, (sum, i) => sum + i.estimatedPrice!);

  /// Total amount actually spent on purchased items.
  double totalSpent(List<WishlistItem> items) => items
      .where((i) => i.isPurchased && i.purchasedPrice != null)
      .fold(0.0, (sum, i) => sum + i.purchasedPrice!);

  /// Total saved (estimated - actual for purchased items).
  double totalSaved(List<WishlistItem> items) => items
      .where((i) =>
          i.isPurchased &&
          i.purchasedPrice != null &&
          i.estimatedPrice != null)
      .fold(
          0.0,
          (sum, i) =>
              sum + (i.estimatedPrice! - i.purchasedPrice!));

  /// Average satisfaction rating of purchased items.
  double avgSatisfaction(List<WishlistItem> items) {
    final rated = items.where((i) => i.isPurchased && i.rating > 0).toList();
    if (rated.isEmpty) return 0;
    return rated.fold(0, (sum, i) => sum + i.rating) / rated.length;
  }

  /// Items per category (unpurchased).
  Map<WishlistCategory, int> categoryBreakdown(List<WishlistItem> items) {
    final counts = <WishlistCategory, int>{};
    for (final item in items.where((i) => !i.isPurchased)) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  /// Spending per category (purchased).
  Map<WishlistCategory, double> spendingByCategory(List<WishlistItem> items) {
    final totals = <WishlistCategory, double>{};
    for (final item
        in items.where((i) => i.isPurchased && i.purchasedPrice != null)) {
      totals[item.category] =
          (totals[item.category] ?? 0) + item.purchasedPrice!;
    }
    return totals;
  }

  /// Items waiting longest (sorted by days on list, descending).
  List<WishlistItem> longestWaiting(List<WishlistItem> items,
      {int limit = 5}) {
    final unpurchased = items.where((i) => !i.isPurchased).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return unpurchased.take(limit).toList();
  }

  /// Items with falling prices (good time to buy).
  List<WishlistItem> fallingPrices(List<WishlistItem> items) => items
      .where((i) => !i.isPurchased && i.priceTrend == PriceTrend.falling)
      .toList();

  /// Monthly budget impact if all urgency <= threshold items were purchased.
  double budgetImpact(List<WishlistItem> items,
      {int urgencyThreshold = 2, int months = 3}) {
    final urgent = items
        .where((i) =>
            !i.isPurchased &&
            i.urgency.value <= urgencyThreshold &&
            i.estimatedPrice != null)
        .fold(0.0, (sum, i) => sum + i.estimatedPrice!);
    return months > 0 ? urgent / months : urgent;
  }

  /// Purchase rate: fraction of items that were actually bought.
  double purchaseRate(List<WishlistItem> items) {
    if (items.isEmpty) return 0;
    return items.where((i) => i.isPurchased).length / items.length;
  }

  /// Average days from add to purchase.
  double avgDaysToPurchase(List<WishlistItem> items) {
    final purchased = items
        .where((i) => i.isPurchased && i.purchasedAt != null)
        .toList();
    if (purchased.isEmpty) return 0;
    final totalDays = purchased.fold(
        0, (sum, i) => sum + i.purchasedAt!.difference(i.createdAt).inDays);
    return totalDays / purchased.length;
  }

  /// Items that have been on the list > threshold days without purchase.
  List<WishlistItem> staleItems(List<WishlistItem> items,
      {int thresholdDays = 90}) {
    return items
        .where((i) => !i.isPurchased && i.daysOnList > thresholdDays)
        .toList();
  }

  /// Smart suggestions based on data.
  List<String> suggestions(List<WishlistItem> items) {
    final tips = <String>[];

    final falling = fallingPrices(items);
    if (falling.isNotEmpty) {
      tips.add(
          '📉 ${falling.length} item(s) have falling prices — good time to buy!');
    }

    final stale = staleItems(items);
    if (stale.isNotEmpty) {
      tips.add(
          '⏰ ${stale.length} item(s) have been on your list 90+ days — still want them?');
    }

    final impulseCount =
        items.where((i) => !i.isPurchased && i.urgency == WishlistUrgency.impulse).length;
    if (impulseCount > 3) {
      tips.add(
          '⚡ $impulseCount impulse items — consider waiting 48h before buying');
    }

    final cost = totalWishlistCost(items);
    if (cost > 1000) {
      tips.add(
          '💰 Total wishlist: \$${cost.toStringAsFixed(0)} — prioritize your top picks');
    }

    final rate = purchaseRate(items);
    if (rate > 0 && rate < 0.3) {
      tips.add(
          '🎯 Only ${(rate * 100).toStringAsFixed(0)}% purchase rate — be more selective when adding');
    }

    if (tips.isEmpty) {
      tips.add('✨ Your wishlist looks well-managed!');
    }

    return tips;
  }
}
