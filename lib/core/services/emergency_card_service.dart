import '../../models/emergency_profile.dart';

/// Service for emergency info card analytics and utilities.
///
/// Provides query, filtering, validation, and export methods for
/// emergency profiles. Stateless — all data is passed as arguments.
class EmergencyCardService {
  const EmergencyCardService();

  // ---------------------------------------------------------------------------
  // Contact helpers
  // ---------------------------------------------------------------------------

  /// Get the primary contact, or the first contact if none is marked primary.
  EmergencyContact? primaryContact(EmergencyProfile profile) {
    return profile.primaryContact;
  }

  /// Contacts sorted by relationship priority (doctor > spouse > parent > ...).
  List<EmergencyContact> contactsByPriority(EmergencyProfile profile) {
    const order = [
      ContactRelationship.doctor,
      ContactRelationship.spouse,
      ContactRelationship.parent,
      ContactRelationship.sibling,
      ContactRelationship.child,
      ContactRelationship.friend,
      ContactRelationship.neighbor,
      ContactRelationship.coworker,
      ContactRelationship.other,
    ];
    final sorted = List<EmergencyContact>.from(profile.contacts);
    sorted.sort((a, b) {
      if (a.isPrimary && !b.isPrimary) return -1;
      if (!a.isPrimary && b.isPrimary) return 1;
      return order.indexOf(a.relationship).compareTo(
            order.indexOf(b.relationship),
          );
    });
    return sorted;
  }

  /// Get contacts by relationship type.
  List<EmergencyContact> contactsByRelationship(
      EmergencyProfile profile, ContactRelationship relationship) {
    return profile.contacts
        .where((c) => c.relationship == relationship)
        .toList();
  }

  // ---------------------------------------------------------------------------
  // Allergy helpers
  // ---------------------------------------------------------------------------

  /// Allergies sorted by severity (most severe first).
  List<Allergy> allergiesBySeverity(EmergencyProfile profile) {
    final sorted = List<Allergy>.from(profile.allergies);
    sorted.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return sorted;
  }

  /// Whether the profile has any life-threatening allergies.
  bool hasAnaphylacticAllergies(EmergencyProfile profile) {
    return profile.allergies
        .any((a) => a.severity == AllergySeverity.anaphylactic);
  }

  /// Get all unique allergen names.
  List<String> allergenList(EmergencyProfile profile) {
    return profile.allergies.map((a) => a.allergen).toSet().toList()..sort();
  }

  // ---------------------------------------------------------------------------
  // Condition helpers
  // ---------------------------------------------------------------------------

  /// Conditions sorted by severity (most severe first).
  List<MedicalCondition> conditionsBySeverity(EmergencyProfile profile) {
    final sorted = List<MedicalCondition>.from(profile.conditions);
    sorted.sort((a, b) => b.severity.index.compareTo(a.severity.index));
    return sorted;
  }

  /// Whether the profile has any critical conditions.
  bool hasCriticalConditions(EmergencyProfile profile) {
    return profile.conditions
        .any((c) => c.severity == ConditionSeverity.critical);
  }

  // ---------------------------------------------------------------------------
  // Insurance helpers
  // ---------------------------------------------------------------------------

  /// Active (non-expired) insurance policies.
  List<InsurancePolicy> activePolicies(EmergencyProfile profile) {
    return profile.insurancePolicies.where((p) => !p.isExpired).toList();
  }

  /// Policies by type.
  List<InsurancePolicy> policiesByType(
      EmergencyProfile profile, InsuranceType type) {
    return profile.insurancePolicies.where((p) => p.type == type).toList();
  }

  /// Policies expiring within the given number of days.
  List<InsurancePolicy> expiringPolicies(EmergencyProfile profile,
      {int withinDays = 30}) {
    return profile.policiesExpiringSoon(withinDays: withinDays);
  }

  /// Whether all required insurance types are covered.
  List<InsuranceType> missingInsuranceTypes(EmergencyProfile profile,
      {List<InsuranceType> required = const [
        InsuranceType.health,
        InsuranceType.dental,
        InsuranceType.vision,
      ]}) {
    final activeTypes = activePolicies(profile).map((p) => p.type).toSet();
    return required.where((t) => !activeTypes.contains(t)).toList();
  }

  // ---------------------------------------------------------------------------
  // Validation
  // ---------------------------------------------------------------------------

  /// Items that are missing or incomplete in the profile.
  List<String> validationWarnings(EmergencyProfile profile) {
    final warnings = <String>[];
    if (profile.fullName.isEmpty) warnings.add('Full name is required');
    if (profile.dateOfBirth == null) warnings.add('Date of birth not set');
    if (profile.bloodType == BloodType.unknown) {
      warnings.add('Blood type not set');
    }
    if (profile.contacts.isEmpty) {
      warnings.add('No emergency contacts added');
    } else if (!profile.contacts.any((c) => c.isPrimary)) {
      warnings.add('No primary emergency contact designated');
    }
    if (profile.insurancePolicies.isEmpty) {
      warnings.add('No insurance policies added');
    }
    for (final p in profile.insurancePolicies) {
      if (p.isExpired) {
        warnings.add('${p.type.label} insurance (${p.provider}) has expired');
      }
    }
    if (profile.address == null || profile.address!.isEmpty) {
      warnings.add('Home address not set');
    }
    return warnings;
  }

  /// Whether the profile passes minimum viability (name + at least 1 contact).
  bool isMinimallyComplete(EmergencyProfile profile) {
    return profile.fullName.isNotEmpty && profile.contacts.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // Export
  // ---------------------------------------------------------------------------

  /// Generate a plain-text emergency card suitable for printing or sharing.
  String generateTextCard(EmergencyProfile profile) {
    final buf = StringBuffer();
    buf.writeln('=== EMERGENCY INFORMATION CARD ===');
    buf.writeln();
    buf.writeln('Name: ${profile.fullName}');
    if (profile.age != null) buf.writeln('Age: ${profile.age}');
    if (profile.dateOfBirth != null) {
      buf.writeln(
          'DOB: ${_formatDate(profile.dateOfBirth!)}');
    }
    buf.writeln('Blood Type: ${profile.bloodType.label}');
    if (profile.primaryLanguage != null) {
      buf.writeln('Language: ${profile.primaryLanguage}');
    }
    if (profile.address != null) {
      buf.writeln('Address: ${profile.address}');
    }
    buf.writeln('Organ Donor: ${profile.isOrganDonor ? "Yes" : "No"}');

    if (profile.contacts.isNotEmpty) {
      buf.writeln();
      buf.writeln('--- EMERGENCY CONTACTS ---');
      for (final c in contactsByPriority(profile)) {
        final primary = c.isPrimary ? ' [PRIMARY]' : '';
        buf.writeln(
            '${c.relationship.label}: ${c.name} — ${c.phone}$primary');
        if (c.email != null) buf.writeln('  Email: ${c.email}');
      }
    }

    if (profile.allergies.isNotEmpty) {
      buf.writeln();
      buf.writeln('--- ALLERGIES ---');
      for (final a in allergiesBySeverity(profile)) {
        buf.write('${a.severity.label}: ${a.allergen}');
        if (a.reaction != null) buf.write(' → ${a.reaction}');
        buf.writeln();
      }
    }

    if (profile.conditions.isNotEmpty) {
      buf.writeln();
      buf.writeln('--- MEDICAL CONDITIONS ---');
      for (final c in conditionsBySeverity(profile)) {
        buf.write('${c.severity.label}: ${c.name}');
        if (c.treatingDoctor != null) buf.write(' (Dr. ${c.treatingDoctor})');
        buf.writeln();
      }
    }

    if (profile.currentMedications.isNotEmpty) {
      buf.writeln();
      buf.writeln('--- CURRENT MEDICATIONS ---');
      for (final med in profile.currentMedications) {
        buf.writeln('• $med');
      }
    }

    if (profile.insurancePolicies.isNotEmpty) {
      buf.writeln();
      buf.writeln('--- INSURANCE ---');
      for (final p in activePolicies(profile)) {
        buf.writeln('${p.type.label}: ${p.provider} — #${p.policyNumber}');
        if (p.memberId != null) buf.writeln('  Member ID: ${p.memberId}');
        if (p.phone != null) buf.writeln('  Phone: ${p.phone}');
      }
    }

    if (profile.specialInstructions != null &&
        profile.specialInstructions!.isNotEmpty) {
      buf.writeln();
      buf.writeln('--- SPECIAL INSTRUCTIONS ---');
      buf.writeln(profile.specialInstructions);
    }

    buf.writeln();
    buf.writeln('Last updated: ${_formatDate(profile.updatedAt)}');

    return buf.toString();
  }

  /// Generate a compact one-line summary for quick reference.
  String quickSummary(EmergencyProfile profile) {
    final parts = <String>[profile.fullName];
    if (profile.bloodType != BloodType.unknown) {
      parts.add(profile.bloodType.label);
    }
    if (profile.allergies.isNotEmpty) {
      final count = profile.allergies.length;
      parts.add('$count allerg${count == 1 ? "y" : "ies"}');
    }
    if (profile.currentMedications.isNotEmpty) {
      parts.add('${profile.currentMedications.length} med(s)');
    }
    final primary = primaryContact(profile);
    if (primary != null) {
      parts.add('ICE: ${primary.name}');
    }
    return parts.join(' | ');
  }

  /// Category breakdown of all emergency data for dashboard display.
  Map<String, int> categoryCounts(EmergencyProfile profile) {
    return {
      'contacts': profile.contacts.length,
      'allergies': profile.allergies.length,
      'conditions': profile.conditions.length,
      'medications': profile.currentMedications.length,
      'insurance': profile.insurancePolicies.length,
    };
  }

  /// Overall alert level based on profile content.
  /// Returns 'critical', 'warning', 'good', or 'incomplete'.
  String alertLevel(EmergencyProfile profile) {
    if (!isMinimallyComplete(profile)) return 'incomplete';
    if (hasCriticalConditions(profile) || hasAnaphylacticAllergies(profile)) {
      return 'critical';
    }
    final warnings = validationWarnings(profile);
    if (warnings.isNotEmpty) return 'warning';
    return 'good';
  }

  // ---------------------------------------------------------------------------
  // Merge / diff
  // ---------------------------------------------------------------------------

  /// Merge two profiles, preferring values from [primary] and adding
  /// non-duplicate entries from [secondary].
  EmergencyProfile mergeProfiles(
      EmergencyProfile primary, EmergencyProfile secondary) {
    final mergedContacts = List<EmergencyContact>.from(primary.contacts);
    for (final c in secondary.contacts) {
      if (!mergedContacts.any((e) => e.id == c.id)) {
        mergedContacts.add(c);
      }
    }

    final mergedAllergies = List<Allergy>.from(primary.allergies);
    for (final a in secondary.allergies) {
      if (!mergedAllergies.any((e) => e.id == a.id)) {
        mergedAllergies.add(a);
      }
    }

    final mergedConditions =
        List<MedicalCondition>.from(primary.conditions);
    for (final c in secondary.conditions) {
      if (!mergedConditions.any((e) => e.id == c.id)) {
        mergedConditions.add(c);
      }
    }

    final mergedMeds = primary.currentMedications.toSet()
      ..addAll(secondary.currentMedications);

    final mergedPolicies =
        List<InsurancePolicy>.from(primary.insurancePolicies);
    for (final p in secondary.insurancePolicies) {
      if (!mergedPolicies.any((e) => e.id == p.id)) {
        mergedPolicies.add(p);
      }
    }

    return primary.copyWith(
      contacts: mergedContacts,
      allergies: mergedAllergies,
      conditions: mergedConditions,
      currentMedications: mergedMeds.toList(),
      insurancePolicies: mergedPolicies,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}
