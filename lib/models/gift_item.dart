import 'package:flutter/material.dart';

/// Model classes for the Gift Tracker feature.

/// The occasion for a gift.
enum GiftOccasion {
  birthday('Birthday', '🎂'),
  christmas('Christmas', '🎄'),
  anniversary('Anniversary', '💍'),
  wedding('Wedding', '💒'),
  babyShower('Baby Shower', '👶'),
  graduation('Graduation', '🎓'),
  valentines("Valentine's Day", '💝'),
  mothersDay("Mother's Day", '🌸'),
  fathersDay("Father's Day", '👔'),
  housewarming('Housewarming', '🏠'),
  thankYou('Thank You', '🙏'),
  justBecause('Just Because', '💫'),
  other('Other', '🎁');

  final String label;
  final String emoji;
  const GiftOccasion(this.label, this.emoji);
}

/// Gift status.
enum GiftStatus {
  idea('Idea', '💡', Colors.amber),
  planned('Planned', '📋', Colors.blue),
  purchased('Purchased', '🛒', Colors.orange),
  wrapped('Wrapped', '🎀', Colors.pink),
  given('Given', '🎉', Colors.green),
  received('Received', '📬', Colors.teal);

  final String label;
  final String emoji;
  final Color color;
  const GiftStatus(this.label, this.emoji, this.color);
}

/// Direction: giving or receiving.
enum GiftDirection {
  giving('Giving', '🎁'),
  receiving('Receiving', '📬');

  final String label;
  final String emoji;
  const GiftDirection(this.label, this.emoji);
}

/// A gift entry.
class GiftItem {
  final String id;
  final String name;
  final String recipientOrGiver;
  final GiftOccasion occasion;
  final GiftStatus status;
  final GiftDirection direction;
  final double? budget;
  final double? actualCost;
  final DateTime? occasionDate;
  final DateTime createdAt;
  final String? notes;
  final bool thankYouSent;
  final int rating; // 0-5 (0 = unrated)
  final List<String> tags;
  final String? url;

  const GiftItem({
    required this.id,
    required this.name,
    required this.recipientOrGiver,
    required this.occasion,
    required this.status,
    required this.direction,
    this.budget,
    this.actualCost,
    this.occasionDate,
    required this.createdAt,
    this.notes,
    this.thankYouSent = false,
    this.rating = 0,
    this.tags = const [],
    this.url,
  });

  GiftItem copyWith({
    String? name,
    String? recipientOrGiver,
    GiftOccasion? occasion,
    GiftStatus? status,
    GiftDirection? direction,
    double? budget,
    double? actualCost,
    DateTime? occasionDate,
    String? notes,
    bool? thankYouSent,
    int? rating,
    List<String>? tags,
    String? url,
  }) =>
      GiftItem(
        id: id,
        name: name ?? this.name,
        recipientOrGiver: recipientOrGiver ?? this.recipientOrGiver,
        occasion: occasion ?? this.occasion,
        status: status ?? this.status,
        direction: direction ?? this.direction,
        budget: budget ?? this.budget,
        actualCost: actualCost ?? this.actualCost,
        occasionDate: occasionDate ?? this.occasionDate,
        createdAt: createdAt,
        notes: notes ?? this.notes,
        thankYouSent: thankYouSent ?? this.thankYouSent,
        rating: rating ?? this.rating,
        tags: tags ?? this.tags,
        url: url ?? this.url,
      );

  GiftItem toggleThankYou() => copyWith(thankYouSent: !thankYouSent);

  bool get isOverBudget =>
      budget != null && actualCost != null && actualCost! > budget!;

  bool get isUpcoming =>
      occasionDate != null && occasionDate!.isAfter(DateTime.now());

  bool get isPast =>
      occasionDate != null && occasionDate!.isBefore(DateTime.now());

  int? get daysUntil => occasionDate != null
      ? occasionDate!.difference(DateTime.now()).inDays
      : null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'recipientOrGiver': recipientOrGiver,
        'occasion': occasion.name,
        'status': status.name,
        'direction': direction.name,
        'budget': budget,
        'actualCost': actualCost,
        'occasionDate': occasionDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'notes': notes,
        'thankYouSent': thankYouSent,
        'rating': rating,
        'tags': tags,
        'url': url,
      };

  factory GiftItem.fromJson(Map<String, dynamic> json) => GiftItem(
        id: json['id'] as String,
        name: json['name'] as String,
        recipientOrGiver: json['recipientOrGiver'] as String,
        occasion: GiftOccasion.values.firstWhere(
            (e) => e.name == json['occasion'],
            orElse: () => GiftOccasion.other),
        status: GiftStatus.values.firstWhere(
            (e) => e.name == json['status'],
            orElse: () => GiftStatus.idea),
        direction: GiftDirection.values.firstWhere(
            (e) => e.name == json['direction'],
            orElse: () => GiftDirection.giving),
        budget: (json['budget'] as num?)?.toDouble(),
        actualCost: (json['actualCost'] as num?)?.toDouble(),
        occasionDate: json['occasionDate'] != null
            ? DateTime.parse(json['occasionDate'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        notes: json['notes'] as String?,
        thankYouSent: json['thankYouSent'] as bool? ?? false,
        rating: json['rating'] as int? ?? 0,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            const [],
        url: json['url'] as String?,
      );
}
