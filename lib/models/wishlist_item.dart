import 'package:flutter/material.dart';

/// Model classes for the Wishlist feature.

/// Wishlist item category.
enum WishlistCategory {
  electronics('Electronics', '📱'),
  fashion('Fashion', '👗'),
  home('Home & Garden', '🏠'),
  books('Books & Media', '📚'),
  gaming('Gaming', '🎮'),
  sports('Sports & Outdoors', '⚽'),
  beauty('Beauty & Health', '💄'),
  food('Food & Drink', '🍽️'),
  travel('Travel & Experiences', '✈️'),
  education('Education & Courses', '🎓'),
  gifts('Gifts for Others', '🎁'),
  other('Other', '📦');

  final String label;
  final String emoji;
  const WishlistCategory(this.label, this.emoji);
}

/// How urgently you want the item.
enum WishlistUrgency {
  impulse(1, 'Impulse', '⚡', Colors.red),
  want(2, 'Want', '💛', Colors.orange),
  considering(3, 'Considering', '🤔', Colors.amber),
  someday(4, 'Someday', '🌙', Colors.blue),
  dreaming(5, 'Just Dreaming', '☁️', Colors.grey);

  final int value;
  final String label;
  final String emoji;
  final Color color;
  const WishlistUrgency(this.value, this.label, this.emoji, this.color);
}

/// Price trend direction.
enum PriceTrend { rising, falling, stable, unknown }

/// A single price observation.
class PricePoint {
  final DateTime date;
  final double price;
  final String? note;

  const PricePoint({
    required this.date,
    required this.price,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'date': date.toIso8601String(),
        'price': price,
        if (note != null) 'note': note,
      };

  factory PricePoint.fromJson(Map<String, dynamic> json) => PricePoint(
        date: DateTime.parse(json['date'] as String),
        price: (json['price'] as num).toDouble(),
        note: json['note'] as String?,
      );
}

/// A single wishlist item.
class WishlistItem {
  final String id;
  final String name;
  final String? description;
  final WishlistCategory category;
  final WishlistUrgency urgency;
  final double? estimatedPrice;
  final String? url;
  final String? imageUrl;
  final List<PricePoint> priceHistory;
  final DateTime createdAt;
  final DateTime? purchasedAt;
  final double? purchasedPrice;
  final bool isPurchased;
  final int rating; // 1-5 satisfaction after purchase, 0 = not rated
  final List<String> tags;
  final String? notes;
  final bool isFavorite;

  const WishlistItem({
    required this.id,
    required this.name,
    this.description,
    required this.category,
    required this.urgency,
    this.estimatedPrice,
    this.url,
    this.imageUrl,
    this.priceHistory = const [],
    required this.createdAt,
    this.purchasedAt,
    this.purchasedPrice,
    this.isPurchased = false,
    this.rating = 0,
    this.tags = const [],
    this.notes,
    this.isFavorite = false,
  });

  /// Days since this item was added.
  int get daysOnList =>
      DateTime.now().difference(createdAt).inDays;

  /// Current price trend based on history.
  PriceTrend get priceTrend {
    if (priceHistory.length < 2) return PriceTrend.unknown;
    final sorted = [...priceHistory]..sort((a, b) => a.date.compareTo(b.date));
    final recent = sorted.last.price;
    final previous = sorted[sorted.length - 2].price;
    final diff = recent - previous;
    if (diff.abs() < recent * 0.02) return PriceTrend.stable;
    return diff > 0 ? PriceTrend.rising : PriceTrend.falling;
  }

  /// Lowest observed price.
  double? get lowestPrice {
    if (priceHistory.isEmpty) return estimatedPrice;
    return priceHistory
        .map((p) => p.price)
        .reduce((a, b) => a < b ? a : b);
  }

  /// Highest observed price.
  double? get highestPrice {
    if (priceHistory.isEmpty) return estimatedPrice;
    return priceHistory
        .map((p) => p.price)
        .reduce((a, b) => a > b ? a : b);
  }

  /// Savings from buying at lowest vs current/estimated price.
  double? get potentialSavings {
    final low = lowestPrice;
    final current = estimatedPrice;
    if (low == null || current == null) return null;
    final diff = current - low;
    return diff > 0 ? diff : 0;
  }

  /// Mark as purchased.
  WishlistItem markPurchased({double? price, int rating = 0}) => WishlistItem(
        id: id,
        name: name,
        description: description,
        category: category,
        urgency: urgency,
        estimatedPrice: estimatedPrice,
        url: url,
        imageUrl: imageUrl,
        priceHistory: priceHistory,
        createdAt: createdAt,
        purchasedAt: DateTime.now(),
        purchasedPrice: price ?? estimatedPrice,
        isPurchased: true,
        rating: rating,
        tags: tags,
        notes: notes,
        isFavorite: isFavorite,
      );

  /// Add a price observation.
  WishlistItem addPricePoint(double price, {String? note}) => WishlistItem(
        id: id,
        name: name,
        description: description,
        category: category,
        urgency: urgency,
        estimatedPrice: price,
        url: url,
        imageUrl: imageUrl,
        priceHistory: [
          ...priceHistory,
          PricePoint(date: DateTime.now(), price: price, note: note),
        ],
        createdAt: createdAt,
        purchasedAt: purchasedAt,
        purchasedPrice: purchasedPrice,
        isPurchased: isPurchased,
        rating: rating,
        tags: tags,
        notes: notes,
        isFavorite: isFavorite,
      );

  /// Toggle favorite status.
  WishlistItem toggleFavorite() => WishlistItem(
        id: id,
        name: name,
        description: description,
        category: category,
        urgency: urgency,
        estimatedPrice: estimatedPrice,
        url: url,
        imageUrl: imageUrl,
        priceHistory: priceHistory,
        createdAt: createdAt,
        purchasedAt: purchasedAt,
        purchasedPrice: purchasedPrice,
        isPurchased: isPurchased,
        rating: rating,
        tags: tags,
        notes: notes,
        isFavorite: !isFavorite,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (description != null) 'description': description,
        'category': category.name,
        'urgency': urgency.name,
        if (estimatedPrice != null) 'estimatedPrice': estimatedPrice,
        if (url != null) 'url': url,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'priceHistory': priceHistory.map((p) => p.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        if (purchasedAt != null) 'purchasedAt': purchasedAt!.toIso8601String(),
        if (purchasedPrice != null) 'purchasedPrice': purchasedPrice,
        'isPurchased': isPurchased,
        'rating': rating,
        'tags': tags,
        if (notes != null) 'notes': notes,
        'isFavorite': isFavorite,
      };

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String?,
        category: WishlistCategory.values.byName(json['category'] as String),
        urgency: WishlistUrgency.values.byName(json['urgency'] as String),
        estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble(),
        url: json['url'] as String?,
        imageUrl: json['imageUrl'] as String?,
        priceHistory: (json['priceHistory'] as List<dynamic>?)
                ?.map((p) => PricePoint.fromJson(p as Map<String, dynamic>))
                .toList() ??
            const [],
        createdAt: DateTime.parse(json['createdAt'] as String),
        purchasedAt: json['purchasedAt'] != null
            ? DateTime.parse(json['purchasedAt'] as String)
            : null,
        purchasedPrice: (json['purchasedPrice'] as num?)?.toDouble(),
        isPurchased: json['isPurchased'] as bool? ?? false,
        rating: json['rating'] as int? ?? 0,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((t) => t as String)
                .toList() ??
            const [],
        notes: json['notes'] as String?,
        isFavorite: json['isFavorite'] as bool? ?? false,
      );
}
