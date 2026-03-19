import 'package:flutter/material.dart';

/// Category of coupon/deal.
enum CouponCategory {
  grocery('Grocery', '🛒', Colors.green),
  restaurant('Restaurant', '🍽️', Colors.orange),
  clothing('Clothing', '👕', Colors.blue),
  electronics('Electronics', '💻', Colors.indigo),
  travel('Travel', '✈️', Colors.teal),
  entertainment('Entertainment', '🎬', Colors.purple),
  health('Health & Beauty', '💊', Colors.pink),
  home('Home & Garden', '🏠', Colors.brown),
  auto('Auto', '🚗', Colors.blueGrey),
  online('Online Shopping', '🌐', Colors.cyan),
  other('Other', '🏷️', Colors.grey);

  final String label;
  final String emoji;
  final Color color;
  const CouponCategory(this.label, this.emoji, this.color);
}

/// Type of discount.
enum DiscountType {
  percentage('Percentage Off', '%'),
  fixedAmount('Fixed Amount', '\$'),
  buyOneGetOne('Buy One Get One', 'BOGO'),
  freeShipping('Free Shipping', '📦'),
  freeItem('Free Item', '🎁'),
  other('Other', '•');

  final String label;
  final String symbol;
  const DiscountType(this.label, this.symbol);
}

/// Status of a coupon.
enum CouponStatus {
  active,
  redeemed,
  expired,
  archived;

  String get label {
    switch (this) {
      case CouponStatus.active:
        return 'Active';
      case CouponStatus.redeemed:
        return 'Redeemed';
      case CouponStatus.expired:
        return 'Expired';
      case CouponStatus.archived:
        return 'Archived';
    }
  }

  Color get color {
    switch (this) {
      case CouponStatus.active:
        return Colors.green;
      case CouponStatus.redeemed:
        return Colors.blue;
      case CouponStatus.expired:
        return Colors.red;
      case CouponStatus.archived:
        return Colors.grey;
    }
  }
}

/// A single coupon or deal entry.
class CouponEntry {
  final String id;
  final String title;
  final String? code;
  final String? store;
  final String? description;
  final CouponCategory category;
  final DiscountType discountType;
  final double? discountValue;
  final double? minimumPurchase;
  final DateTime? expirationDate;
  final DateTime createdAt;
  final DateTime? redeemedAt;
  final double? savedAmount;
  final bool isFavorite;
  final List<String> tags;
  final String? notes;
  final String? url;

  const CouponEntry({
    required this.id,
    required this.title,
    this.code,
    this.store,
    this.description,
    this.category = CouponCategory.other,
    this.discountType = DiscountType.percentage,
    this.discountValue,
    this.minimumPurchase,
    this.expirationDate,
    required this.createdAt,
    this.redeemedAt,
    this.savedAmount,
    this.isFavorite = false,
    this.tags = const [],
    this.notes,
    this.url,
  });

  /// Computed status based on dates and redemption.
  CouponStatus get status {
    if (redeemedAt != null) return CouponStatus.redeemed;
    if (expirationDate != null && DateTime.now().isAfter(expirationDate!)) {
      return CouponStatus.expired;
    }
    return CouponStatus.active;
  }

  /// Days until expiration (null if no expiry, negative if expired).
  int? get daysUntilExpiry {
    if (expirationDate == null) return null;
    final now = DateTime.now();
    return expirationDate!
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  /// Whether the coupon is expiring soon (within 3 days).
  bool get isExpiringSoon {
    final days = daysUntilExpiry;
    return days != null && days >= 0 && days <= 3;
  }

  /// Display string for the discount.
  String get discountDisplay {
    if (discountValue == null) return discountType.label;
    switch (discountType) {
      case DiscountType.percentage:
        return '${discountValue!.toStringAsFixed(discountValue! == discountValue!.roundToDouble() ? 0 : 1)}% off';
      case DiscountType.fixedAmount:
        return '\$${discountValue!.toStringAsFixed(2)} off';
      case DiscountType.buyOneGetOne:
        return 'BOGO';
      case DiscountType.freeShipping:
        return 'Free Shipping';
      case DiscountType.freeItem:
        return 'Free Item';
      case DiscountType.other:
        return discountValue!.toStringAsFixed(0);
    }
  }

  CouponEntry copyWith({
    String? title,
    String? code,
    String? store,
    String? description,
    CouponCategory? category,
    DiscountType? discountType,
    double? discountValue,
    double? minimumPurchase,
    DateTime? expirationDate,
    DateTime? redeemedAt,
    double? savedAmount,
    bool? isFavorite,
    List<String>? tags,
    String? notes,
    String? url,
    bool clearExpiration = false,
    bool clearRedemption = false,
  }) =>
      CouponEntry(
        id: id,
        title: title ?? this.title,
        code: code ?? this.code,
        store: store ?? this.store,
        description: description ?? this.description,
        category: category ?? this.category,
        discountType: discountType ?? this.discountType,
        discountValue: discountValue ?? this.discountValue,
        minimumPurchase: minimumPurchase ?? this.minimumPurchase,
        expirationDate:
            clearExpiration ? null : (expirationDate ?? this.expirationDate),
        createdAt: createdAt,
        redeemedAt:
            clearRedemption ? null : (redeemedAt ?? this.redeemedAt),
        savedAmount: savedAmount ?? this.savedAmount,
        isFavorite: isFavorite ?? this.isFavorite,
        tags: tags ?? this.tags,
        notes: notes ?? this.notes,
        url: url ?? this.url,
      );

  CouponEntry toggleFavorite() => copyWith(isFavorite: !isFavorite);

  CouponEntry markRedeemed({double? saved}) => copyWith(
        redeemedAt: DateTime.now(),
        savedAmount: saved,
      );

  CouponEntry unmarkRedeemed() => CouponEntry(
        id: id,
        title: title,
        code: code,
        store: store,
        description: description,
        category: category,
        discountType: discountType,
        discountValue: discountValue,
        minimumPurchase: minimumPurchase,
        expirationDate: expirationDate,
        createdAt: createdAt,
        redeemedAt: null,
        savedAmount: null,
        isFavorite: isFavorite,
        tags: tags,
        notes: notes,
        url: url,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        if (code != null) 'code': code,
        if (store != null) 'store': store,
        if (description != null) 'description': description,
        'category': category.name,
        'discountType': discountType.name,
        if (discountValue != null) 'discountValue': discountValue,
        if (minimumPurchase != null) 'minimumPurchase': minimumPurchase,
        if (expirationDate != null)
          'expirationDate': expirationDate!.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        if (redeemedAt != null) 'redeemedAt': redeemedAt!.toIso8601String(),
        if (savedAmount != null) 'savedAmount': savedAmount,
        'isFavorite': isFavorite,
        'tags': tags,
        if (notes != null) 'notes': notes,
        if (url != null) 'url': url,
      };

  factory CouponEntry.fromJson(Map<String, dynamic> json) => CouponEntry(
        id: json['id'] as String,
        title: json['title'] as String,
        code: json['code'] as String?,
        store: json['store'] as String?,
        description: json['description'] as String?,
        category: CouponCategory.values.firstWhere(
          (v) => v.name == json['category'],
          orElse: () => CouponCategory.other,
        ),
        discountType: DiscountType.values.firstWhere(
          (v) => v.name == json['discountType'],
          orElse: () => DiscountType.percentage,
        ),
        discountValue: (json['discountValue'] as num?)?.toDouble(),
        minimumPurchase: (json['minimumPurchase'] as num?)?.toDouble(),
        expirationDate: json['expirationDate'] != null
            ? DateTime.parse(json['expirationDate'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        redeemedAt: json['redeemedAt'] != null
            ? DateTime.parse(json['redeemedAt'] as String)
            : null,
        savedAmount: (json['savedAmount'] as num?)?.toDouble(),
        isFavorite: json['isFavorite'] as bool? ?? false,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        notes: json['notes'] as String?,
        url: json['url'] as String?,
      );
}
