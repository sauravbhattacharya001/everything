import 'dart:convert';
import '../../models/coupon_entry.dart';

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
class CouponTrackerService {
  final List<CouponEntry> _coupons = [];

  List<CouponEntry> get coupons => List.unmodifiable(_coupons);
  int get totalCoupons => _coupons.length;

  // ── CRUD ──

  void addCoupon(CouponEntry coupon) {
    _coupons.add(coupon);
  }

  bool updateCoupon(CouponEntry updated) {
    final idx = _coupons.indexWhere((c) => c.id == updated.id);
    if (idx >= 0) {
      _coupons[idx] = updated;
      return true;
    }
    return false;
  }

  bool removeCoupon(String id) {
    final idx = _coupons.indexWhere((c) => c.id == id);
    if (idx >= 0) {
      _coupons.removeAt(idx);
      return true;
    }
    return false;
  }

  CouponEntry? getById(String id) {
    try {
      return _coupons.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  // ── Actions ──

  CouponEntry? toggleFavorite(String id) {
    final idx = _coupons.indexWhere((c) => c.id == id);
    if (idx < 0) return null;
    _coupons[idx] = _coupons[idx].toggleFavorite();
    return _coupons[idx];
  }

  CouponEntry? markRedeemed(String id, {double? savedAmount}) {
    final idx = _coupons.indexWhere((c) => c.id == id);
    if (idx < 0) return null;
    _coupons[idx] = _coupons[idx].markRedeemed(saved: savedAmount);
    return _coupons[idx];
  }

  CouponEntry? unmarkRedeemed(String id) {
    final idx = _coupons.indexWhere((c) => c.id == id);
    if (idx < 0) return null;
    _coupons[idx] = _coupons[idx].unmarkRedeemed();
    return _coupons[idx];
  }

  // ── Filtering ──

  List<CouponEntry> getActive() =>
      _coupons.where((c) => c.status == CouponStatus.active).toList();

  List<CouponEntry> getRedeemed() =>
      _coupons.where((c) => c.status == CouponStatus.redeemed).toList();

  List<CouponEntry> getExpired() =>
      _coupons.where((c) => c.status == CouponStatus.expired).toList();

  List<CouponEntry> getExpiringSoon({int withinDays = 3}) =>
      _coupons
          .where((c) =>
              c.status == CouponStatus.active &&
              c.daysUntilExpiry != null &&
              c.daysUntilExpiry! <= withinDays &&
              c.daysUntilExpiry! >= 0)
          .toList()
        ..sort((a, b) =>
            (a.daysUntilExpiry ?? 999).compareTo(b.daysUntilExpiry ?? 999));

  List<CouponEntry> getFavorites() =>
      _coupons.where((c) => c.isFavorite).toList();

  List<CouponEntry> getByCategory(CouponCategory category) =>
      _coupons.where((c) => c.category == category).toList();

  List<CouponEntry> getByStore(String store) {
    final s = store.toLowerCase();
    return _coupons
        .where((c) => c.store?.toLowerCase() == s)
        .toList();
  }

  List<CouponEntry> search(String query) {
    if (query.trim().isEmpty) return coupons;
    final q = query.toLowerCase();
    return _coupons.where((c) {
      return c.title.toLowerCase().contains(q) ||
          (c.code?.toLowerCase().contains(q) ?? false) ||
          (c.store?.toLowerCase().contains(q) ?? false) ||
          (c.description?.toLowerCase().contains(q) ?? false) ||
          c.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();
  }

  // ── Stats ──

  double get totalSaved =>
      _coupons.fold<double>(0, (s, c) => s + (c.savedAmount ?? 0));

  /// Unique stores across all coupons.
  List<String> get stores {
    final set = <String>{};
    for (final c in _coupons) {
      if (c.store != null && c.store!.isNotEmpty) set.add(c.store!);
    }
    final list = set.toList()..sort();
    return list;
  }

  /// All unique tags.
  List<String> get allTags {
    final set = <String>{};
    for (final c in _coupons) {
      set.addAll(c.tags);
    }
    final list = set.toList()..sort();
    return list;
  }

  CouponSummary getSummary() {
    final active = getActive();
    final redeemed = getRedeemed();
    final expired = getExpired();
    final expiringSoon = getExpiringSoon();

    final catMap = <CouponCategory, int>{};
    for (final c in _coupons) {
      catMap[c.category] = (catMap[c.category] ?? 0) + 1;
    }

    final storeMap = <String, int>{};
    for (final c in _coupons) {
      if (c.store != null && c.store!.isNotEmpty) {
        storeMap[c.store!] = (storeMap[c.store!] ?? 0) + 1;
      }
    }

    return CouponSummary(
      totalCoupons: _coupons.length,
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
    final list = List<CouponEntry>.from(_coupons);
    list.sort((a, b) {
      final aExp = a.expirationDate ?? DateTime(2999);
      final bExp = b.expirationDate ?? DateTime(2999);
      return ascending ? aExp.compareTo(bExp) : bExp.compareTo(aExp);
    });
    return list;
  }

  List<CouponEntry> sortedByDiscount({bool ascending = false}) {
    final list = List<CouponEntry>.from(_coupons);
    list.sort((a, b) {
      final aVal = a.discountValue ?? 0;
      final bVal = b.discountValue ?? 0;
      return ascending ? aVal.compareTo(bVal) : bVal.compareTo(aVal);
    });
    return list;
  }

  List<CouponEntry> sortedByDate({bool ascending = false}) {
    final list = List<CouponEntry>.from(_coupons);
    list.sort((a, b) => ascending
        ? a.createdAt.compareTo(b.createdAt)
        : b.createdAt.compareTo(a.createdAt));
    return list;
  }

  // ── Persistence ──

  String exportToJson() =>
      jsonEncode(_coupons.map((c) => c.toJson()).toList());

  /// Maximum entries allowed via [importFromJson] to prevent memory exhaustion.
  static const int maxImportEntries = 50000;

  void importFromJson(String jsonStr) {
    final list = jsonDecode(jsonStr) as List<dynamic>;
    if (list.length > maxImportEntries) {
      throw ArgumentError(
        'Import exceeds maximum of $maxImportEntries entries '
        '(got ${list.length}). This limit prevents memory exhaustion '
        'from corrupted or malicious data.',
      );
    }
    _coupons.clear();
    for (final item in list) {
      _coupons.add(CouponEntry.fromJson(item as Map<String, dynamic>));
    }
  }
}
