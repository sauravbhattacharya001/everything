import 'dart:convert';

/// Blood type classification.
enum BloodType {
  aPositive,
  aNegative,
  bPositive,
  bNegative,
  abPositive,
  abNegative,
  oPositive,
  oNegative,
  unknown;

  String get label {
    switch (this) {
      case BloodType.aPositive:
        return 'A+';
      case BloodType.aNegative:
        return 'A-';
      case BloodType.bPositive:
        return 'B+';
      case BloodType.bNegative:
        return 'B-';
      case BloodType.abPositive:
        return 'AB+';
      case BloodType.abNegative:
        return 'AB-';
      case BloodType.oPositive:
        return 'O+';
      case BloodType.oNegative:
        return 'O-';
      case BloodType.unknown:
        return 'Unknown';
    }
  }

  String get emoji => this == BloodType.unknown ? '❓' : '🩸';
}

/// Severity of a medical condition.
enum ConditionSeverity {
  mild,
  moderate,
  severe,
  critical;

  String get label {
    switch (this) {
      case ConditionSeverity.mild:
        return 'Mild';
      case ConditionSeverity.moderate:
        return 'Moderate';
      case ConditionSeverity.severe:
        return 'Severe';
      case ConditionSeverity.critical:
        return 'Critical';
    }
  }

  String get emoji {
    switch (this) {
      case ConditionSeverity.mild:
        return '🟢';
      case ConditionSeverity.moderate:
        return '🟡';
      case ConditionSeverity.severe:
        return '🟠';
      case ConditionSeverity.critical:
        return '🔴';
    }
  }
}

/// Allergy severity level.
enum AllergySeverity {
  mild,
  moderate,
  severe,
  anaphylactic;

  String get label {
    switch (this) {
      case AllergySeverity.mild:
        return 'Mild';
      case AllergySeverity.moderate:
        return 'Moderate';
      case AllergySeverity.severe:
        return 'Severe';
      case AllergySeverity.anaphylactic:
        return 'Anaphylactic';
    }
  }

  String get emoji {
    switch (this) {
      case AllergySeverity.mild:
        return '🟢';
      case AllergySeverity.moderate:
        return '🟡';
      case AllergySeverity.severe:
        return '🟠';
      case AllergySeverity.anaphylactic:
        return '🔴';
    }
  }
}

/// Type of insurance coverage.
enum InsuranceType {
  health,
  dental,
  vision,
  life,
  auto,
  home,
  travel,
  pet,
  other;

  String get label {
    switch (this) {
      case InsuranceType.health:
        return 'Health';
      case InsuranceType.dental:
        return 'Dental';
      case InsuranceType.vision:
        return 'Vision';
      case InsuranceType.life:
        return 'Life';
      case InsuranceType.auto:
        return 'Auto';
      case InsuranceType.home:
        return 'Home';
      case InsuranceType.travel:
        return 'Travel';
      case InsuranceType.pet:
        return 'Pet';
      case InsuranceType.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case InsuranceType.health:
        return '🏥';
      case InsuranceType.dental:
        return '🦷';
      case InsuranceType.vision:
        return '👁️';
      case InsuranceType.life:
        return '🛡️';
      case InsuranceType.auto:
        return '🚗';
      case InsuranceType.home:
        return '🏠';
      case InsuranceType.travel:
        return '✈️';
      case InsuranceType.pet:
        return '🐾';
      case InsuranceType.other:
        return '📋';
    }
  }
}

/// Relationship to the user for emergency contacts.
enum ContactRelationship {
  spouse,
  parent,
  child,
  sibling,
  friend,
  doctor,
  neighbor,
  coworker,
  other;

  String get label {
    switch (this) {
      case ContactRelationship.spouse:
        return 'Spouse/Partner';
      case ContactRelationship.parent:
        return 'Parent';
      case ContactRelationship.child:
        return 'Child';
      case ContactRelationship.sibling:
        return 'Sibling';
      case ContactRelationship.friend:
        return 'Friend';
      case ContactRelationship.doctor:
        return 'Doctor';
      case ContactRelationship.neighbor:
        return 'Neighbor';
      case ContactRelationship.coworker:
        return 'Coworker';
      case ContactRelationship.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case ContactRelationship.spouse:
        return '💍';
      case ContactRelationship.parent:
        return '👨‍👩‍👧';
      case ContactRelationship.child:
        return '👶';
      case ContactRelationship.sibling:
        return '👫';
      case ContactRelationship.friend:
        return '🤝';
      case ContactRelationship.doctor:
        return '👨‍⚕️';
      case ContactRelationship.neighbor:
        return '🏘️';
      case ContactRelationship.coworker:
        return '💼';
      case ContactRelationship.other:
        return '👤';
    }
  }
}

/// An emergency contact person.
class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String? email;
  final ContactRelationship relationship;
  final bool isPrimary;
  final String? notes;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.relationship = ContactRelationship.other,
    this.isPrimary = false,
    this.notes,
  });

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    ContactRelationship? relationship,
    bool? isPrimary,
    String? notes,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      relationship: relationship ?? this.relationship,
      isPrimary: isPrimary ?? this.isPrimary,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        'relationship': relationship.name,
        'isPrimary': isPrimary,
        'notes': notes,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String?,
      relationship: ContactRelationship.values.firstWhere(
        (e) => e.name == json['relationship'],
        orElse: () => ContactRelationship.other,
      ),
      isPrimary: json['isPrimary'] as bool? ?? false,
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyContact &&
          id == other.id &&
          name == other.name &&
          phone == other.phone;

  @override
  int get hashCode => Object.hash(id, name, phone);
}

/// A known allergy.
class Allergy {
  final String id;
  final String allergen;
  final AllergySeverity severity;
  final String? reaction;
  final String? notes;

  const Allergy({
    required this.id,
    required this.allergen,
    this.severity = AllergySeverity.moderate,
    this.reaction,
    this.notes,
  });

  Allergy copyWith({
    String? id,
    String? allergen,
    AllergySeverity? severity,
    String? reaction,
    String? notes,
  }) {
    return Allergy(
      id: id ?? this.id,
      allergen: allergen ?? this.allergen,
      severity: severity ?? this.severity,
      reaction: reaction ?? this.reaction,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'allergen': allergen,
        'severity': severity.name,
        'reaction': reaction,
        'notes': notes,
      };

  factory Allergy.fromJson(Map<String, dynamic> json) {
    return Allergy(
      id: json['id'] as String,
      allergen: json['allergen'] as String,
      severity: AllergySeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => AllergySeverity.moderate,
      ),
      reaction: json['reaction'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Allergy && id == other.id && allergen == other.allergen;

  @override
  int get hashCode => Object.hash(id, allergen);
}

/// A medical condition.
class MedicalCondition {
  final String id;
  final String name;
  final ConditionSeverity severity;
  final DateTime? diagnosedDate;
  final String? treatingDoctor;
  final String? notes;

  const MedicalCondition({
    required this.id,
    required this.name,
    this.severity = ConditionSeverity.moderate,
    this.diagnosedDate,
    this.treatingDoctor,
    this.notes,
  });

  MedicalCondition copyWith({
    String? id,
    String? name,
    ConditionSeverity? severity,
    DateTime? diagnosedDate,
    String? treatingDoctor,
    String? notes,
  }) {
    return MedicalCondition(
      id: id ?? this.id,
      name: name ?? this.name,
      severity: severity ?? this.severity,
      diagnosedDate: diagnosedDate ?? this.diagnosedDate,
      treatingDoctor: treatingDoctor ?? this.treatingDoctor,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'severity': severity.name,
        'diagnosedDate': diagnosedDate?.toIso8601String(),
        'treatingDoctor': treatingDoctor,
        'notes': notes,
      };

  factory MedicalCondition.fromJson(Map<String, dynamic> json) {
    return MedicalCondition(
      id: json['id'] as String,
      name: json['name'] as String,
      severity: ConditionSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => ConditionSeverity.moderate,
      ),
      diagnosedDate: json['diagnosedDate'] != null
          ? DateTime.parse(json['diagnosedDate'] as String)
          : null,
      treatingDoctor: json['treatingDoctor'] as String?,
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MedicalCondition && id == other.id && name == other.name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// An insurance policy.
class InsurancePolicy {
  final String id;
  final InsuranceType type;
  final String provider;
  final String policyNumber;
  final String? groupNumber;
  final String? memberId;
  final String? phone;
  final DateTime? expiresAt;
  final String? notes;

  const InsurancePolicy({
    required this.id,
    required this.type,
    required this.provider,
    required this.policyNumber,
    this.groupNumber,
    this.memberId,
    this.phone,
    this.expiresAt,
    this.notes,
  });

  /// Whether this policy has expired.
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  /// Days until expiry (negative if expired, null if no expiry date).
  int? get daysUntilExpiry {
    if (expiresAt == null) return null;
    return expiresAt!.difference(DateTime.now()).inDays;
  }

  InsurancePolicy copyWith({
    String? id,
    InsuranceType? type,
    String? provider,
    String? policyNumber,
    String? groupNumber,
    String? memberId,
    String? phone,
    DateTime? expiresAt,
    String? notes,
  }) {
    return InsurancePolicy(
      id: id ?? this.id,
      type: type ?? this.type,
      provider: provider ?? this.provider,
      policyNumber: policyNumber ?? this.policyNumber,
      groupNumber: groupNumber ?? this.groupNumber,
      memberId: memberId ?? this.memberId,
      phone: phone ?? this.phone,
      expiresAt: expiresAt ?? this.expiresAt,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'provider': provider,
        'policyNumber': policyNumber,
        'groupNumber': groupNumber,
        'memberId': memberId,
        'phone': phone,
        'expiresAt': expiresAt?.toIso8601String(),
        'notes': notes,
      };

  factory InsurancePolicy.fromJson(Map<String, dynamic> json) {
    return InsurancePolicy(
      id: json['id'] as String,
      type: InsuranceType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => InsuranceType.other,
      ),
      provider: json['provider'] as String,
      policyNumber: json['policyNumber'] as String,
      groupNumber: json['groupNumber'] as String?,
      memberId: json['memberId'] as String?,
      phone: json['phone'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      notes: json['notes'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InsurancePolicy &&
          id == other.id &&
          policyNumber == other.policyNumber;

  @override
  int get hashCode => Object.hash(id, policyNumber);
}

/// Complete emergency information profile.
class EmergencyProfile {
  final String fullName;
  final DateTime? dateOfBirth;
  final BloodType bloodType;
  final String? primaryLanguage;
  final String? address;
  final List<EmergencyContact> contacts;
  final List<Allergy> allergies;
  final List<MedicalCondition> conditions;
  final List<String> currentMedications;
  final List<InsurancePolicy> insurancePolicies;
  final bool isOrganDonor;
  final String? specialInstructions;
  final DateTime updatedAt;

  EmergencyProfile({
    required this.fullName,
    this.dateOfBirth,
    this.bloodType = BloodType.unknown,
    this.primaryLanguage,
    this.address,
    this.contacts = const [],
    this.allergies = const [],
    this.conditions = const [],
    this.currentMedications = const [],
    this.insurancePolicies = const [],
    this.isOrganDonor = false,
    this.specialInstructions,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  /// Age calculated from date of birth.
  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int years = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      years--;
    }
    return years;
  }

  /// The primary emergency contact (first one marked as primary, or first overall).
  EmergencyContact? get primaryContact {
    final primary = contacts.where((c) => c.isPrimary);
    return primary.isNotEmpty ? primary.first : contacts.isNotEmpty ? contacts.first : null;
  }

  /// Whether the profile has critical medical info.
  bool get hasCriticalInfo =>
      allergies.any((a) => a.severity == AllergySeverity.anaphylactic) ||
      conditions.any((c) => c.severity == ConditionSeverity.critical);

  /// Completeness score (0-100) based on how much info is filled in.
  int get completenessScore {
    int score = 0;
    if (fullName.isNotEmpty) score += 15;
    if (dateOfBirth != null) score += 10;
    if (bloodType != BloodType.unknown) score += 10;
    if (contacts.isNotEmpty) score += 20;
    if (contacts.length >= 2) score += 5;
    if (allergies.isNotEmpty || conditions.isNotEmpty) score += 10;
    if (currentMedications.isNotEmpty) score += 10;
    if (insurancePolicies.isNotEmpty) score += 10;
    if (address != null && address!.isNotEmpty) score += 5;
    if (primaryLanguage != null && primaryLanguage!.isNotEmpty) score += 5;
    return score.clamp(0, 100);
  }

  /// Completeness as a descriptive label.
  String get completenessLabel {
    final s = completenessScore;
    if (s >= 90) return 'Excellent';
    if (s >= 70) return 'Good';
    if (s >= 50) return 'Partial';
    if (s >= 25) return 'Minimal';
    return 'Incomplete';
  }

  /// Insurance policies expiring within the given number of days.
  List<InsurancePolicy> policiesExpiringSoon({int withinDays = 30}) {
    return insurancePolicies.where((p) {
      final days = p.daysUntilExpiry;
      return days != null && days >= 0 && days <= withinDays;
    }).toList();
  }

  /// All expired insurance policies.
  List<InsurancePolicy> get expiredPolicies =>
      insurancePolicies.where((p) => p.isExpired).toList();

  EmergencyProfile copyWith({
    String? fullName,
    DateTime? dateOfBirth,
    BloodType? bloodType,
    String? primaryLanguage,
    String? address,
    List<EmergencyContact>? contacts,
    List<Allergy>? allergies,
    List<MedicalCondition>? conditions,
    List<String>? currentMedications,
    List<InsurancePolicy>? insurancePolicies,
    bool? isOrganDonor,
    String? specialInstructions,
    DateTime? updatedAt,
  }) {
    return EmergencyProfile(
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodType: bloodType ?? this.bloodType,
      primaryLanguage: primaryLanguage ?? this.primaryLanguage,
      address: address ?? this.address,
      contacts: contacts ?? this.contacts,
      allergies: allergies ?? this.allergies,
      conditions: conditions ?? this.conditions,
      currentMedications: currentMedications ?? this.currentMedications,
      insurancePolicies: insurancePolicies ?? this.insurancePolicies,
      isOrganDonor: isOrganDonor ?? this.isOrganDonor,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'bloodType': bloodType.name,
        'primaryLanguage': primaryLanguage,
        'address': address,
        'contacts': contacts.map((c) => c.toJson()).toList(),
        'allergies': allergies.map((a) => a.toJson()).toList(),
        'conditions': conditions.map((c) => c.toJson()).toList(),
        'currentMedications': currentMedications,
        'insurancePolicies': insurancePolicies.map((p) => p.toJson()).toList(),
        'isOrganDonor': isOrganDonor,
        'specialInstructions': specialInstructions,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory EmergencyProfile.fromJson(Map<String, dynamic> json) {
    return EmergencyProfile(
      fullName: json['fullName'] as String,
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.parse(json['dateOfBirth'] as String)
          : null,
      bloodType: BloodType.values.firstWhere(
        (e) => e.name == json['bloodType'],
        orElse: () => BloodType.unknown,
      ),
      primaryLanguage: json['primaryLanguage'] as String?,
      address: json['address'] as String?,
      contacts: (json['contacts'] as List<dynamic>?)
              ?.map((e) =>
                  EmergencyContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      allergies: (json['allergies'] as List<dynamic>?)
              ?.map((e) => Allergy.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      conditions: (json['conditions'] as List<dynamic>?)
              ?.map((e) =>
                  MedicalCondition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentMedications:
          (json['currentMedications'] as List<dynamic>?)
                  ?.cast<String>() ??
              [],
      insurancePolicies: (json['insurancePolicies'] as List<dynamic>?)
              ?.map((e) =>
                  InsurancePolicy.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      isOrganDonor: json['isOrganDonor'] as bool? ?? false,
      specialInstructions: json['specialInstructions'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  /// Serialize to JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string.
  static EmergencyProfile? fromJsonString(String json) {
    try {
      return EmergencyProfile.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmergencyProfile &&
          fullName == other.fullName &&
          dateOfBirth == other.dateOfBirth;

  @override
  int get hashCode => Object.hash(fullName, dateOfBirth);
}
