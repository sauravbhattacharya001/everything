import '../../models/coupon_entry.dart';
import 'crud_service.dart';

/// Summary statistics for the coupon collection.
class CouponSummary {
  final int totalCoupons;
  final int activeCount;
  final int redeemedCount;
  final int expiredCount;
  final int expiringSoonCount;
  final double totalSaved;
  final Map<CouponCategory, int> categoryBreakdown;
  final Map<String, int> storeBreakdown;

  const CouponSummary({
    required this.totalCoupons,
    required this.activeCount,
    required this.redeemedCount,
    required this.expiredCount,
    required this.expiringSoonCount,
    required this.totalSaved,
    required this.categoryBreakdown,
    required this.storeBreakdown,
  });
}

/// Service for managing coupons, promo codes, and deals.
///
/// Extends [CrudService] for standard CRUD + JSON persistence,
/// adding coupon-specific actions, filtering, sorting, and analytics.
class CouponTrackerService extends CrudService<CouponEntry> {
  @override
  String getId(CouponEntry item) => item.id;
  @override
  Map<String, dynamic> toJson(CouponEntry item) => item.toJson();
  @override
  CouponEntry fromJson(Map<String, dynamic> json) =>
      CouponEntry.fromJson(json);

  /// Backward-compatible accessors.
  List<CouponEntry> get coupons => items;
  int get totalCoupons => length;

  // ── Legacy CRUD wrappers (delegate to CrudService) ──

  void addCoupon(CouponEntry coupon) => add(coupon);
  bool updateCoupon(CouponEntry updated) => update(updated);
  bool removeCoupon(String id) => remove(id);

  // ── Actions ──

  CouponEntry? toggleFavorite(String id) {
    final idx = indexById(id);
    if (idx < 0) return null;
    updateAt(idx, itemsMutable[idx].toggleFavorite());
    return itemsMutable[idx];
  }

  CouponEntry? markRedeemed(String id, {double? savedAmount}) {
    final idx = indexById(id);
    if (idx < 0) return null;
    updateAt(idx, itemsMutable[idx].markRedeemed(saved: savedAmount));
    return itemsMutable[idx];
  }

  CouponEntry? unmarkRedeemed(String id) {
    final idx = indexById(id);
    if (idx < 0) return null;
    updateAt(idx, itemsMutable[idx].unmarkRedeemed());
    return itemsMutable[idx];
  }

  // ── Filtering ──

  List<CouponEntry> getActive() =>
      items.where((c) => c.status == CouponStatus.active).toList();

  List<CouponEntry> getRedeemed() =>
      items.where((c) => c.status == CouponStatus.redeemed).toList();

  List<CouponEntry> getExpired() =>
      items.where((c) => c.status == CouponStatus.expired).toList();

  List<CouponEntry> getExpiringSoon({int withinDays = 3}) =>
      items
          .where((c) =>
              c.status == CouponStatus.active &&
              c.daysUntilExpiry != null &&
              c.daysUntilExpiry! <= withinDays &&
              c.daysUntilExpiry! >= 0)
          .toList()
        ..sort((a, b) =>
            (a.daysUntilExpiry ?? 999).compareTo(b.daysUntilExpiry ?? 999));

  List<CouponEntry> getFavorites() =>
      items.where((c) => c.isFavorite).toList();

  List<CouponEntry> getByCategory(CouponCategory category) =>
      items.where((c) => c.category == category).toList();

  List<CouponEntry> getByStore(String store) {
    final s = store.toLowerCase();
    return items.where((c) => c.store?.toLowerCase() == s).toList();
  }

  List<CouponEntry> search(String query) {
    if (query.trim().isEmpty) return coupons;
    final q = query.toLowerCase();
    return items.where((c) {
      return c.title.toLowerCase().contains(q) ||
          (c.code?.toLowerCase().contains(q) ?? false) ||
          (c.store?.toLowerCase().contains(q) ?? false) ||
          (c.description?.toLowerCase().contains(q) ?? false) ||
          c.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  // ── Stats ──

  double get totalSaved =>
      items.fold<double>(0, (s, c) => s + (c.savedAmount ?? 0));

  List<String> get stores {
    final set = <String>{};
    for (final c in items) {
      if (c.store != null && c.store!.isNotEmpty) set.add(c.store!);
    }
    return set.toList()..sort();
  }

  List<String> get allTags {
    final set = <String>{};
    for (final c in items) {
      set.addAll(c.tags);
    }
    return set.toList()..sort();
  }

  CouponSummary getSummary() {
    final active = getActive();
    final redeemed = getRedeemed();
    final expired = getExpired();
    final expiringSoon = getExpiringSoon();

    final catMap = <CouponCategory, int>{};
    for (final c in items) {
      catMap[c.category] = (catMap[c.category] ?? 0) + 1;
    }

    final storeMap = <String, int>{};
    for (final c in items) {
      if (c.store != null && c.store!.isNotEmpty) {
        storeMap[c.store!] = (storeMap[c.store!] ?? 0) + 1;
      }
    }

    return CouponSummary(
      totalCoupons: length,
      activeCount: active.length,
      redeemedCount: redeemed.length,
      expiredCount: expired.length,
      expiringSoonCount: expiringSoon.length,
      totalSaved: totalSaved,
      categoryBreakdown: catMap,
      storeBreakdown: storeMap,
    );
  }

  // ── Sorting ──

  List<CouponEntry> sortedByExpiry({bool ascending = true}) {
    final list = List<CouponEntry>.from(items);
    list.sort((a, b) {
      final aExp = a.expirationDate ?? DateTime(2999);
      final bExp = b.expirationDate ?? DateTime(2999);
      return ascending ? aExp.compareTo(bExp) : bExp.compareTo(aExp);
    });
    return list;
  }

  List<CouponEntry> sortedByDiscount({bool ascending = false}) {
    final list = List<CouponEntry>.from(items);
    list.sort((a, b) {
      final aVal = a.discountValue ?? 0;
      final bVal = b.discountValue ?? 0;
      return ascending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
    });
    return list;
  }

  List<CouponEntry> sortedByDate({bool ascending = false}) {
    final list = List<CouponEntry>.from(items);
    list.sort((a, b) => ascending
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
