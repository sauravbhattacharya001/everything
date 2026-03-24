import 'dart:convert';
import 'package:everything/core/utils/date_utils.dart';

/// Category of the document being tracked.
enum DocumentCategory {
  identification,
  travel,
  insurance,
  financial,
  vehicle,
  medical,
  education,
  professional,
  property,
  other;

  String get label {
    switch (this) {
      case DocumentCategory.identification: return 'Identification';
      case DocumentCategory.travel: return 'Travel';
      case DocumentCategory.insurance: return 'Insurance';
      case DocumentCategory.financial: return 'Financial';
      case DocumentCategory.vehicle: return 'Vehicle';
      case DocumentCategory.medical: return 'Medical';
      case DocumentCategory.education: return 'Education';
      case DocumentCategory.professional: return 'Professional';
      case DocumentCategory.property: return 'Property';
      case DocumentCategory.other: return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case DocumentCategory.identification: return '🪪';
      case DocumentCategory.travel: return '✈️';
      case DocumentCategory.insurance: return '🛡️';
      case DocumentCategory.financial: return '💳';
      case DocumentCategory.vehicle: return '🚗';
      case DocumentCategory.medical: return '🏥';
      case DocumentCategory.education: return '🎓';
      case DocumentCategory.professional: return '💼';
      case DocumentCategory.property: return '🏠';
      case DocumentCategory.other: return '📄';
    }
  }
}

/// Urgency level based on days until expiry.
enum DocumentUrgency {
  expired,
  critical,   // < 30 days
  warning,    // < 90 days
  upcoming,   // < 180 days
  safe;       // >= 180 days

  String get label {
    switch (this) {
      case DocumentUrgency.expired: return 'Expired';
      case DocumentUrgency.critical: return 'Critical';
      case DocumentUrgency.warning: return 'Warning';
      case DocumentUrgency.upcoming: return 'Upcoming';
      case DocumentUrgency.safe: return 'Safe';
    }
  }

  String get emoji {
    switch (this) {
      case DocumentUrgency.expired: return '🔴';
      case DocumentUrgency.critical: return '🟠';
      case DocumentUrgency.warning: return '🟡';
      case DocumentUrgency.upcoming: return '🔵';
      case DocumentUrgency.safe: return '🟢';
    }
  }
}

/// A tracked document with expiry date.
class DocumentEntry {
  final String id;
  final String name;
  final DocumentCategory category;
  final DateTime issueDate;
  final DateTime expiryDate;
  final String? issuer;
  final String? documentNumber;
  final String? notes;
  final int reminderDaysBefore;
  final bool renewed;
  final DateTime? renewedDate;

  const DocumentEntry({
    required this.id,
    required this.name,
    required this.category,
    required this.issueDate,
    required this.expiryDate,
    this.issuer,
    this.documentNumber,
    this.notes,
    this.reminderDaysBefore = 30,
    this.renewed = false,
    this.renewedDate,
  });

  /// Days until expiry (negative = expired).
  int get daysUntilExpiry {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    return expiry.difference(today).inDays;
  }

  /// Current urgency level.
  DocumentUrgency get urgency {
    if (renewed) return DocumentUrgency.safe;
    final days = daysUntilExpiry;
    if (days < 0) return DocumentUrgency.expired;
    if (days < 30) return DocumentUrgency.critical;
    if (days < 90) return DocumentUrgency.warning;
    if (days < 180) return DocumentUrgency.upcoming;
    return DocumentUrgency.safe;
  }

  /// Whether the reminder threshold has been reached.
  bool get isReminderDue => daysUntilExpiry <= reminderDaysBefore && !renewed;

  /// How long the document is valid for (in days).
  int get validityPeriodDays =>
      expiryDate.difference(issueDate).inDays;

  /// Percentage of validity used.
  double get validityUsedPercent {
    final total = validityPeriodDays;
    if (total <= 0) return 1.0;
    final elapsed = DateTime.now().difference(issueDate).inDays;
    return (elapsed / total).clamp(0.0, 1.0);
  }

  DocumentEntry copyWith({
    String? id,
    String? name,
    DocumentCategory? category,
    DateTime? issueDate,
    DateTime? expiryDate,
    String? issuer,
    String? documentNumber,
    String? notes,
    int? reminderDaysBefore,
    bool? renewed,
    DateTime? renewedDate,
  }) {
    return DocumentEntry(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      issuer: issuer ?? this.issuer,
      documentNumber: documentNumber ?? this.documentNumber,
      notes: notes ?? this.notes,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      renewed: renewed ?? this.renewed,
      renewedDate: renewedDate ?? this.renewedDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.index,
    'issueDate': issueDate.toIso8601String(),
    'expiryDate': expiryDate.toIso8601String(),
    'issuer': issuer,
    'documentNumber': documentNumber,
    'notes': notes,
    'reminderDaysBefore': reminderDaysBefore,
    'renewed': renewed,
    'renewedDate': renewedDate?.toIso8601String(),
  };

  factory DocumentEntry.fromJson(Map<String, dynamic> json) => DocumentEntry(
    id: json['id'] as String,
    name: json['name'] as String,
    category: DocumentCategory.values[json['category'] as int],
    issueDate: AppDateUtils.safeParse(json['issueDate'] as String?),
    expiryDate: AppDateUtils.safeParse(json['expiryDate'] as String?),
    issuer: json['issuer'] as String?,
    documentNumber: json['documentNumber'] as String?,
    notes: json['notes'] as String?,
    reminderDaysBefore: json['reminderDaysBefore'] as int? ?? 30,
    renewed: json['renewed'] as bool? ?? false,
    renewedDate: AppDateUtils.safeParseNullable(json['renewedDate'] as String?),
  );
}
