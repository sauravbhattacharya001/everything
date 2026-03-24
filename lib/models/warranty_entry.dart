import 'dart:convert';
import 'package:everything/core/utils/date_utils.dart';

/// Category of warranted product.
enum WarrantyCategory {
  electronics,
  appliance,
  furniture,
  vehicle,
  tool,
  clothing,
  jewelry,
  sporting,
  home,
  other;

  String get label {
    switch (this) {
      case WarrantyCategory.electronics:
        return 'Electronics';
      case WarrantyCategory.appliance:
        return 'Appliance';
      case WarrantyCategory.furniture:
        return 'Furniture';
      case WarrantyCategory.vehicle:
        return 'Vehicle';
      case WarrantyCategory.tool:
        return 'Tool';
      case WarrantyCategory.clothing:
        return 'Clothing';
      case WarrantyCategory.jewelry:
        return 'Jewelry';
      case WarrantyCategory.sporting:
        return 'Sporting Goods';
      case WarrantyCategory.home:
        return 'Home';
      case WarrantyCategory.other:
        return 'Other';
    }
  }
}

/// Type of warranty coverage.
enum WarrantyType {
  manufacturer,
  extended,
  retailer,
  lifetime,
  limited;

  String get label {
    switch (this) {
      case WarrantyType.manufacturer:
        return 'Manufacturer';
      case WarrantyType.extended:
        return 'Extended';
      case WarrantyType.retailer:
        return 'Retailer';
      case WarrantyType.lifetime:
        return 'Lifetime';
      case WarrantyType.limited:
        return 'Limited';
    }
  }
}

/// Status of a warranty claim.
enum ClaimStatus {
  submitted,
  inProgress,
  approved,
  denied,
  completed;

  String get label {
    switch (this) {
      case ClaimStatus.submitted:
        return 'Submitted';
      case ClaimStatus.inProgress:
        return 'In Progress';
      case ClaimStatus.approved:
        return 'Approved';
      case ClaimStatus.denied:
        return 'Denied';
      case ClaimStatus.completed:
        return 'Completed';
    }
  }
}

/// A single warranty claim record.
class WarrantyClaim {
  final String id;
  final DateTime dateSubmitted;
  final String issue;
  final ClaimStatus status;
  final String? resolution;
  final DateTime? dateResolved;

  const WarrantyClaim({
    required this.id,
    required this.dateSubmitted,
    required this.issue,
    this.status = ClaimStatus.submitted,
    this.resolution,
    this.dateResolved,
  });

  bool get isResolved =>
      status == ClaimStatus.completed ||
      status == ClaimStatus.denied;

  int get daysToResolve {
    if (dateResolved == null) return -1;
    return dateResolved!.difference(dateSubmitted).inDays;
  }

  WarrantyClaim copyWith({
    String? id,
    DateTime? dateSubmitted,
    String? issue,
    ClaimStatus? status,
    String? resolution,
    DateTime? dateResolved,
  }) =>
      WarrantyClaim(
        id: id ?? this.id,
        dateSubmitted: dateSubmitted ?? this.dateSubmitted,
        issue: issue ?? this.issue,
        status: status ?? this.status,
        resolution: resolution ?? this.resolution,
        dateResolved: dateResolved ?? this.dateResolved,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'dateSubmitted': dateSubmitted.toIso8601String(),
        'issue': issue,
        'status': status.name,
        'resolution': resolution,
        'dateResolved': dateResolved?.toIso8601String(),
      };

  factory WarrantyClaim.fromJson(Map<String, dynamic> json) => WarrantyClaim(
        id: json['id'] as String,
        dateSubmitted: AppDateUtils.safeParse(json['dateSubmitted'] as String?),
        issue: json['issue'] as String,
        status: ClaimStatus.values.firstWhere(
          (v) => v.name == json['status'],
          orElse: () => ClaimStatus.submitted,
        ),
        resolution: json['resolution'] as String?,
        dateResolved: AppDateUtils.safeParseNullable(json['dateResolved'] as String?),
      );
}

/// A product warranty entry.
class WarrantyEntry {
  final String id;
  final String productName;
  final String? brand;
  final WarrantyCategory category;
  final WarrantyType type;
  final DateTime purchaseDate;
  final DateTime expirationDate;
  final double purchasePrice;
  final String? retailer;
  final String? serialNumber;
  final String? receiptReference;
  final String? notes;
  final List<String> tags;
  final List<WarrantyClaim> claims;
  final bool isActive;

  const WarrantyEntry({
    required this.id,
    required this.productName,
    this.brand,
    this.category = WarrantyCategory.other,
    this.type = WarrantyType.manufacturer,
    required this.purchaseDate,
    required this.expirationDate,
    this.purchasePrice = 0,
    this.retailer,
    this.serialNumber,
    this.receiptReference,
    this.notes,
    this.tags = const [],
    this.claims = const [],
    this.isActive = true,
  });

  /// Whether the warranty has expired based on current date.
  bool get isExpired => DateTime.now().isAfter(expirationDate);

  /// Whether the warranty is currently valid (active and not expired).
  bool get isValid => isActive && !isExpired;

  /// Days remaining until expiration (negative if expired).
  int get daysRemaining {
    final now = DateTime.now();
    return expirationDate
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  /// Total warranty duration in days.
  int get totalDurationDays =>
      expirationDate.difference(purchaseDate).inDays;

  /// Percentage of warranty period elapsed.
  double get percentElapsed {
    if (totalDurationDays <= 0) return 100;
    final elapsed = DateTime.now().difference(purchaseDate).inDays;
    final pct = (elapsed / totalDurationDays) * 100;
    return pct.clamp(0, 100);
  }

  /// Whether warranty is expiring soon (within 30 days).
  bool get isExpiringSoon => !isExpired && daysRemaining <= 30;

  /// Number of claims filed.
  int get claimCount => claims.length;

  /// Number of open (unresolved) claims.
  int get openClaimCount =>
      claims.where((c) => !c.isResolved).length;

  WarrantyEntry copyWith({
    String? id,
    String? productName,
    String? brand,
    WarrantyCategory? category,
    WarrantyType? type,
    DateTime? purchaseDate,
    DateTime? expirationDate,
    double? purchasePrice,
    String? retailer,
    String? serialNumber,
    String? receiptReference,
    String? notes,
    List<String>? tags,
    List<WarrantyClaim>? claims,
    bool? isActive,
  }) =>
      WarrantyEntry(
        id: id ?? this.id,
        productName: productName ?? this.productName,
        brand: brand ?? this.brand,
        category: category ?? this.category,
        type: type ?? this.type,
        purchaseDate: purchaseDate ?? this.purchaseDate,
        expirationDate: expirationDate ?? this.expirationDate,
        purchasePrice: purchasePrice ?? this.purchasePrice,
        retailer: retailer ?? this.retailer,
        serialNumber: serialNumber ?? this.serialNumber,
        receiptReference: receiptReference ?? this.receiptReference,
        notes: notes ?? this.notes,
        tags: tags ?? this.tags,
        claims: claims ?? this.claims,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'productName': productName,
        'brand': brand,
        'category': category.name,
        'type': type.name,
        'purchaseDate': purchaseDate.toIso8601String(),
        'expirationDate': expirationDate.toIso8601String(),
        'purchasePrice': purchasePrice,
        'retailer': retailer,
        'serialNumber': serialNumber,
        'receiptReference': receiptReference,
        'notes': notes,
        'tags': tags,
        'claims': claims.map((c) => c.toJson()).toList(),
        'isActive': isActive,
      };

  factory WarrantyEntry.fromJson(Map<String, dynamic> json) => WarrantyEntry(
        id: json['id'] as String,
        productName: json['productName'] as String,
        brand: json['brand'] as String?,
        category: WarrantyCategory.values.firstWhere(
          (v) => v.name == json['category'],
          orElse: () => WarrantyCategory.other,
        ),
        type: WarrantyType.values.firstWhere(
          (v) => v.name == json['type'],
          orElse: () => WarrantyType.manufacturer,
        ),
        purchaseDate: AppDateUtils.safeParse(json['purchaseDate'] as String?),
        expirationDate: AppDateUtils.safeParse(json['expirationDate'] as String?),
        purchasePrice:
            (json['purchasePrice'] as num?)?.toDouble() ?? 0,
        retailer: json['retailer'] as String?,
        serialNumber: json['serialNumber'] as String?,
        receiptReference: json['receiptReference'] as String?,
        notes: json['notes'] as String?,
        tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
        claims: (json['claims'] as List<dynamic>?)
                ?.map((c) =>
                    WarrantyClaim.fromJson(c as Map<String, dynamic>))
                .toList() ??
            [],
        isActive: json['isActive'] as bool? ?? true,
      );

  @override
  String toString() =>
      'WarrantyEntry($productName, ${daysRemaining}d remaining)';
}
