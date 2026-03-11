import 'dart:convert';
import '../../models/warranty_entry.dart';

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
class WarrantyTrackerService {
  final List<WarrantyEntry> _warranties = [];

  List<WarrantyEntry> get warranties => List.unmodifiable(_warranties);

  // ── CRUD ──

  void addWarranty(WarrantyEntry entry) {
    _warranties.add(entry);
  }

  void updateWarranty(WarrantyEntry entry) {
    final idx = _warranties.indexWhere((w) => w.id == entry.id);
    if (idx >= 0) _warranties[idx] = entry;
  }

  void removeWarranty(String id) {
    _warranties.removeWhere((w) => w.id == id);
  }

  WarrantyEntry? getById(String id) {
    try {
      return _warranties.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Claims ──

  void addClaim(String warrantyId, WarrantyClaim claim) {
    final w = getById(warrantyId);
    if (w == null) return;
    updateWarranty(w.copyWith(claims: [...w.claims, claim]));
  }

  void updateClaim(String warrantyId, WarrantyClaim claim) {
    final w = getById(warrantyId);
    if (w == null) return;
    final updated = w.claims.map((c) => c.id == claim.id ? claim : c).toList();
    updateWarranty(w.copyWith(claims: updated));
  }

  // ── Filtering ──

  List<WarrantyEntry> getActive() =>
      _warranties.where((w) => w.isValid).toList();

  List<WarrantyEntry> getExpired() =>
      _warranties.where((w) => w.isExpired).toList();

  List<WarrantyEntry> getExpiringSoon({int withinDays = 30}) =>
      _warranties
          .where((w) => !w.isExpired && w.daysRemaining <= withinDays)
          .toList()
        ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));

  List<WarrantyEntry> getByCategory(WarrantyCategory category) =>
      _warranties.where((w) => w.category == category).toList();

  List<WarrantyEntry> getByType(WarrantyType type) =>
      _warranties.where((w) => w.type == type).toList();

  List<WarrantyEntry> searchByName(String query) {
    final q = query.toLowerCase();
    return _warranties
        .where((w) =>
            w.productName.toLowerCase().contains(q) ||
            (w.brand?.toLowerCase().contains(q) ?? false) ||
            (w.retailer?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  List<WarrantyEntry> getWithOpenClaims() =>
      _warranties.where((w) => w.openClaimCount > 0).toList();

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
        _warranties.fold<double>(0, (s, w) => s + w.purchasePrice);
    final protectedVal =
        active.fold<double>(0, (s, w) => s + w.purchasePrice);

    // Category breakdown
    final catMap = <WarrantyCategory, List<WarrantyEntry>>{};
    for (final w in _warranties) {
      catMap.putIfAbsent(w.category, () => []).add(w);
    }
    final breakdown = catMap.entries.map((e) {
      final items = e.value;
      final catActive = items.where((w) => w.isValid).length;
      final catExpired = items.where((w) => w.isExpired).length;
      final catValue =
          items.fold<double>(0, (s, w) => s + w.purchasePrice);
      return WarrantyCategoryBreakdown(
        category: e.key,
        count: items.length,
        activeCount: catActive,
        expiredCount: catExpired,
        totalPurchaseValue: catValue,
        percentOfTotal: totalValue > 0 ? (catValue / totalValue) * 100 : 0,
      );
    }).toList()
      ..sort((a, b) => b.totalPurchaseValue.compareTo(a.totalPurchaseValue));

    final totalClaims =
        _warranties.fold<int>(0, (s, w) => s + w.claimCount);
    final openClaims =
        _warranties.fold<int>(0, (s, w) => s + w.openClaimCount);

    return WarrantySummary(
      totalWarranties: _warranties.length,
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
    if (_warranties.isEmpty) return 0;
    final totalValue =
        _warranties.fold<double>(0, (s, w) => s + w.purchasePrice);
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

  // ── Persistence ──

  String exportToJson() =>
      jsonEncode(_warranties.map((w) => w.toJson()).toList());

  void importFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    _warranties.clear();
    for (final item in list) {
      _warranties.add(
          WarrantyEntry.fromJson(item as Map<String, dynamic>));
    }
  }
}
