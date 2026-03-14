import 'dart:convert';

/// Category of document.
enum DocumentCategory {
  passport, driversLicense, visa, insurance, certification, membership,
  medicalCard, vehicleRegistration, permit, subscription, contract, other;

  String get label {
    switch (this) {
      case DocumentCategory.passport: return 'Passport';
      case DocumentCategory.driversLicense: return "Driver's License";
      case DocumentCategory.visa: return 'Visa';
      case DocumentCategory.insurance: return 'Insurance';
      case DocumentCategory.certification: return 'Certification';
      case DocumentCategory.membership: return 'Membership';
      case DocumentCategory.medicalCard: return 'Medical Card';
      case DocumentCategory.vehicleRegistration: return 'Vehicle Registration';
      case DocumentCategory.permit: return 'Permit';
      case DocumentCategory.subscription: return 'Subscription';
      case DocumentCategory.contract: return 'Contract';
      case DocumentCategory.other: return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case DocumentCategory.passport: return '🛂';
      case DocumentCategory.driversLicense: return '🪪';
      case DocumentCategory.visa: return '✈️';
      case DocumentCategory.insurance: return '🛡️';
      case DocumentCategory.certification: return '📜';
      case DocumentCategory.membership: return '🏷️';
      case DocumentCategory.medicalCard: return '🏥';
      case DocumentCategory.vehicleRegistration: return '🚗';
      case DocumentCategory.permit: return '📋';
      case DocumentCategory.subscription: return '🔄';
      case DocumentCategory.contract: return '📝';
      case DocumentCategory.other: return '📄';
    }
  }
}

enum ExpiryUrgency {
  expired, critical, warning, upcoming, safe;

  String get label {
    switch (this) {
      case ExpiryUrgency.expired: return 'Expired';
      case ExpiryUrgency.critical: return 'Critical';
      case ExpiryUrgency.warning: return 'Warning';
      case ExpiryUrgency.upcoming: return 'Upcoming';
      case ExpiryUrgency.safe: return 'Safe';
    }
  }
}

class RenewalRecord {
  final String id;
  final DateTime renewedOn;
  final DateTime previousExpiry;
  final DateTime newExpiry;
  final double? cost;
  final String? notes;

  const RenewalRecord({required this.id, required this.renewedOn,
    required this.previousExpiry, required this.newExpiry, this.cost, this.notes});

  Map<String, dynamic> toJson() => {
    'id': id, 'renewedOn': renewedOn.toIso8601String(),
    'previousExpiry': previousExpiry.toIso8601String(),
    'newExpiry': newExpiry.toIso8601String(), 'cost': cost, 'notes': notes,
  };

  factory RenewalRecord.fromJson(Map<String, dynamic> json) => RenewalRecord(
    id: json['id'] as String, renewedOn: DateTime.parse(json['renewedOn'] as String),
    previousExpiry: DateTime.parse(json['previousExpiry'] as String),
    newExpiry: DateTime.parse(json['newExpiry'] as String),
    cost: (json['cost'] as num?)?.toDouble(), notes: json['notes'] as String?,
  );
}

class DocumentEntry {
  final String id;
  final String name;
  final DocumentCategory category;
  final String? issuer;
  final String? documentNumber;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? holder;
  final String? notes;
  final List<String> tags;
  final List<RenewalRecord> renewalHistory;
  final int reminderDaysBefore;
  final bool isActive;

  const DocumentEntry({required this.id, required this.name,
    this.category = DocumentCategory.other, this.issuer, this.documentNumber,
    required this.issueDate, required this.expiryDate,
    this.holder, this.notes, this.tags = const [],
    this.renewalHistory = const [], this.reminderDaysBefore = 30, this.isActive = true});

  int get daysRemaining {
    final now = DateTime.now();
    return expiryDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  bool get isExpired => daysRemaining < 0;
  bool get isValid => isActive && !isExpired;
  int get totalValidityDays => expiryDate.difference(issueDate).inDays;

  double get percentElapsed {
    if (totalValidityDays <= 0) return 100;
    final elapsed = DateTime.now().difference(issueDate).inDays;
    return (elapsed / totalValidityDays * 100).clamp(0, 100);
  }

  ExpiryUrgency get urgency {
    final d = daysRemaining;
    if (d < 0) return ExpiryUrgency.expired;
    if (d < 7) return ExpiryUrgency.critical;
    if (d < 30) return ExpiryUrgency.warning;
    if (d < 90) return ExpiryUrgency.upcoming;
    return ExpiryUrgency.safe;
  }

  bool get shouldRemind => !isExpired && daysRemaining <= reminderDaysBefore;
  double get totalRenewalCost => renewalHistory.fold(0, (s, r) => s + (r.cost ?? 0));
  int get renewalCount => renewalHistory.length;

  DocumentEntry copyWith({String? id, String? name, DocumentCategory? category,
    String? issuer, String? documentNumber, DateTime? issueDate, DateTime? expiryDate,
    String? holder, String? notes, List<String>? tags,
    List<RenewalRecord>? renewalHistory, int? reminderDaysBefore, bool? isActive}) =>
    DocumentEntry(id: id ?? this.id, name: name ?? this.name,
      category: category ?? this.category, issuer: issuer ?? this.issuer,
      documentNumber: documentNumber ?? this.documentNumber,
      issueDate: issueDate ?? this.issueDate, expiryDate: expiryDate ?? this.expiryDate,
      holder: holder ?? this.holder, notes: notes ?? this.notes,
      tags: tags ?? this.tags, renewalHistory: renewalHistory ?? this.renewalHistory,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      isActive: isActive ?? this.isActive);

  Map<String, dynamic> toJson() => {
    'id': id, 'name': name, 'category': category.name, 'issuer': issuer,
    'documentNumber': documentNumber, 'issueDate': issueDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(), 'holder': holder, 'notes': notes,
    'tags': tags, 'renewalHistory': renewalHistory.map((r) => r.toJson()).toList(),
    'reminderDaysBefore': reminderDaysBefore, 'isActive': isActive,
  };

  factory DocumentEntry.fromJson(Map<String, dynamic> j) => DocumentEntry(
    id: j['id'] as String, name: j['name'] as String,
    category: DocumentCategory.values.firstWhere((v) => v.name == j['category'],
      orElse: () => DocumentCategory.other),
    issuer: j['issuer'] as String?, documentNumber: j['documentNumber'] as String?,
    issueDate: DateTime.parse(j['issueDate'] as String),
    expiryDate: DateTime.parse(j['expiryDate'] as String),
    holder: j['holder'] as String?, notes: j['notes'] as String?,
    tags: (j['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    renewalHistory: (j['renewalHistory'] as List<dynamic>?)
      ?.map((r) => RenewalRecord.fromJson(r as Map<String, dynamic>)).toList() ?? [],
    reminderDaysBefore: j['reminderDaysBefore'] as int? ?? 30,
    isActive: j['isActive'] as bool? ?? true);

  @override
  String toString() => 'DocumentEntry($name, ${daysRemaining}d remaining)';
}
