import '../../models/warranty_entry.dart';
import 'crud_service.dart';

/// Alert for warranties expiring soon.
class WarrantyAlert {
  final WarrantyEntry warranty;
  final int daysUntilExpiry;
  final String message;
  const WarrantyAlert({
    required this.warranty,
    required this.daysUntilExpiry,
    required this.message,
  });
}

/// Breakdown of warranties by category.
class WarrantyCategoryBreakdown {
  final WarrantyCategory category;
  final int count;
  final int activeCount;
  final int expiredCount;
  final double totalPurchaseValue;
  final double percentOfTotal;
  const WarrantyCategoryBreakdown({
    required this.category,
    required this.count,
    required this.activeCount,
    required this.expiredCount,
    required this.totalPurchaseValue,
    required this.percentOfTotal,
  });
}

/// Overall warranty portfolio summary.
class WarrantySummary {
  final int totalWarranties;
  final int activeCount;
  final int expiredCount;
  final int expiringSoonCount;
  final double totalPurchaseValue;
  final double protectedValue;
  final double unprotectedValue;
  final int totalClaims;
  final int openClaims;
  final List<WarrantyCategoryBreakdown> categoryBreakdown;
  final List<WarrantyAlert> expiringAlerts;
  const WarrantySummary({
    required this.totalWarranties,
    required this.activeCount,
    required this.expiredCount,
    required this.expiringSoonCount,
    required this.totalPurchaseValue,
    required this.protectedValue,
    required this.unprotectedValue,
    required this.totalClaims,
    required this.openClaims,
    required this.categoryBreakdown,
    required this.expiringAlerts,
  });
}

/// Service for managing product warranties.
///
/// Extends [CrudService] to eliminate hand-rolled CRUD and JSON
/// serialization boilerplate. Domain-specific logic (claims, alerts,
/// coverage analysis) is preserved as-is.
class WarrantyTrackerService extends CrudService<WarrantyEntry> {
  @override
  String getId(WarrantyEntry item) => item.id;

  @override
  Map<String, dynamic> toJson(WarrantyEntry item) => item.toJson();

  @override
  WarrantyEntry fromJson(Map<String, dynamic> json) =>
      WarrantyEntry.fromJson(json);

  /// Backwards-compatible alias for [items].
  List<WarrantyEntry> get warranties => items;

  // ── Backwards-compatible CRUD aliases ──

  void addWarranty(WarrantyEntry entry) => add(entry);

  void updateWarranty(WarrantyEntry entry) => update(entry);

  void removeWarranty(String id) => remove(id);

  // ── Claims ──

  void addClaim(String warrantyId, WarrantyClaim claim) {
    final w = getById(warrantyId);
    if (w == null) return;
    update(w.copyWith(claims: [...w.claims, claim]));
  }

  void updateClaim(String warrantyId, WarrantyClaim claim) {
    final w = getById(warrantyId);
    if (w == null) return;
    final updated = w.claims.map((c) => c.id == claim.id ? claim : c).toList();
    update(w.copyWith(claims: updated));
  }

  // ── Filtering ──

  List<WarrantyEntry> getActive() =>
      items.where((w) => w.isValid).toList();

  List<WarrantyEntry> getExpired() =>
      items.where((w) => w.isExpired).toList();

  List<WarrantyEntry> getExpiringSoon({int withinDays = 30}) =>
      items
          .where((w) => !w.isExpired && w.daysRemaining <= withinDays)
          .toList()
        ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

  List<WarrantyEntry> getByCategory(WarrantyCategory category) =>
      items.where((w) => w.category == category).toList();

  List<WarrantyEntry> getByType(WarrantyType type) =>
      items.where((w) => w.type == type).toList();

  List<WarrantyEntry> searchByName(String query) {
    final q = query.toLowerCase();
    return items
        .where((w) =>
            w.productName.toLowerCase().contains(q) ||
            (w.brand?.toLowerCase().contains(q) ?? false) ||
            (w.retailer?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  List<WarrantyEntry> getWithOpenClaims() =>
      items.where((w) => w.openClaimCount > 0).toList();

  // ── Alerts ──

  List<WarrantyAlert> getExpiryAlerts({int withinDays = 30}) {
    return getExpiringSoon(withinDays: withinDays).map((w) {
      final days = w.daysRemaining;
      String msg;
      if (days <= 0) {
        msg = '${w.productName} warranty expires today!';
      } else if (days == 1) {
        msg = '${w.productName} warranty expires tomorrow!';
      } else if (days <= 7) {
        msg = '${w.productName} warranty expires in $days days!';
      } else {
        msg = '${w.productName} warranty expires in $days days';
      }
      return WarrantyAlert(warranty: w, daysUntilExpiry: days, message: msg);
    }).toList();
  }

  // ── Summary ──

  WarrantySummary getSummary() {
    final active = getActive();
    final expired = getExpired();
    final expiringSoon = getExpiringSoon();
    final totalValue =
        items.fold<double>(0, (s, w) => s + w.purchasePrice);
    final protectedVal =
        active.fold<double>(0, (s, w) => s + w.purchasePrice);

    // Category breakdown
    final catMap = <WarrantyCategory, List<WarrantyEntry>>{};
    for (final w in items) {
      catMap.putIfAbsent(w.category, () => []).add(w);
    }
    final breakdown = catMap.entries.map((e) {
      final catItems = e.value;
      final catActive = catItems.where((w) => w.isValid).length;
      final catExpired = catItems.where((w) => w.isExpired).length;
      final catValue =
          catItems.fold<double>(0, (s, w) => s + w.purchasePrice);
      return WarrantyCategoryBreakdown(
        category: e.key,
        count: catItems.length,
        activeCount: catActive,
        expiredCount: catExpired,
        totalPurchaseValue: catValue,
        percentOfTotal: totalValue > 0 ? (catValue / totalValue) * 100 : 0,
      );
    }).toList()
      ..sort((a, b) => b.totalPurchaseValue.compareTo(a.totalPurchaseValue));

    final totalClaims =
        items.fold<int>(0, (s, w) => s + w.claimCount);
    final openClaims =
        items.fold<int>(0, (s, w) => s + w.openClaimCount);

    return WarrantySummary(
      totalWarranties: length,
      activeCount: active.length,
      expiredCount: expired.length,
      expiringSoonCount: expiringSoon.length,
      totalPurchaseValue: totalValue,
      protectedValue: protectedVal,
      unprotectedValue: totalValue - protectedVal,
      totalClaims: totalClaims,
      openClaims: openClaims,
      categoryBreakdown: breakdown,
      expiringAlerts: getExpiryAlerts(),
    );
  }

  // ── Coverage Analysis ──

  /// Returns a coverage score (0-100) based on warranty status.
  double getCoverageScore() {
    if (isEmpty) return 0;
    final totalValue =
        items.fold<double>(0, (s, w) => s + w.purchasePrice);
    if (totalValue <= 0) return 0;
    final protectedVal =
        getActive().fold<double>(0, (s, w) => s + w.purchasePrice);
    return (protectedVal / totalValue * 100).clamp(0, 100);
  }

  /// Returns warranties sorted by expiration (soonest first).
  List<WarrantyEntry> getExpirationTimeline() {
    final active = getActive();
    active.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
    return active;
  }
}
