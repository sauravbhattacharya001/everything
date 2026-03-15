import 'package:test/test.dart';
import '../lib/models/emergency_profile.dart';
import '../lib/core/services/emergency_card_service.dart';

void main() {
  late EmergencyCardService service;

  EmergencyContact _contact({
    String id = 'c1',
    String name = 'Jane Doe',
    String phone = '555-0100',
    ContactRelationship relationship = ContactRelationship.spouse,
    bool isPrimary = false,
  }) {
    return EmergencyContact(
      id: id,
      name: name,
      phone: phone,
      relationship: relationship,
      isPrimary: isPrimary,
    );
  }

  Allergy _allergy({
    String id = 'a1',
    String allergen = 'Peanuts',
    AllergySeverity severity = AllergySeverity.moderate,
    String? reaction,
  }) {
    return Allergy(
      id: id, allergen: allergen, severity: severity, reaction: reaction);
  }

  MedicalCondition _condition({
    String id = 'mc1',
    String name = 'Asthma',
    ConditionSeverity severity = ConditionSeverity.moderate,
  }) {
    return MedicalCondition(id: id, name: name, severity: severity);
  }

  InsurancePolicy _policy({
    String id = 'p1',
    InsuranceType type = InsuranceType.health,
    String provider = 'BlueCross',
    String policyNumber = 'BC-12345',
    DateTime? expiresAt,
  }) {
    return InsurancePolicy(
      id: id,
      type: type,
      provider: provider,
      policyNumber: policyNumber,
      expiresAt: expiresAt,
    );
  }

  EmergencyProfile _profile({
    String fullName = 'John Smith',
    DateTime? dateOfBirth,
    BloodType bloodType = BloodType.oPositive,
    List<EmergencyContact>? contacts,
    List<Allergy>? allergies,
    List<MedicalCondition>? conditions,
    List<String> currentMedications = const [],
    List<InsurancePolicy>? insurancePolicies,
    bool isOrganDonor = false,
    String? address,
    String? specialInstructions,
  }) {
    return EmergencyProfile(
      fullName: fullName,
      dateOfBirth: dateOfBirth ?? DateTime(1990, 6, 15),
      bloodType: bloodType,
      contacts: contacts ?? [_contact(isPrimary: true)],
      allergies: allergies ?? [],
      conditions: conditions ?? [],
      currentMedications: currentMedications,
      insurancePolicies: insurancePolicies ?? [],
      isOrganDonor: isOrganDonor,
      address: address,
      specialInstructions: specialInstructions,
      updatedAt: DateTime(2026, 3, 15),
    );
  }

  setUp(() {
    service = const EmergencyCardService();
  });

  // -------------------------------------------------------------------------
  // Model tests
  // -------------------------------------------------------------------------

  group('EmergencyProfile model', () {
    test('age calculates correctly', () {
      final p = _profile(dateOfBirth: DateTime(1990, 6, 15));
      final age = p.age!;
      // Should be 35 or 36 depending on current date vs Jun 15
      expect(age, greaterThanOrEqualTo(35));
      expect(age, lessThanOrEqualTo(36));
    });

    test('age returns null when no DOB', () {
      final p = EmergencyProfile(fullName: 'Test');
      expect(p.age, isNull);
    });

    test('primaryContact returns primary-flagged contact', () {
      final p = _profile(contacts: [
        _contact(id: 'c1', isPrimary: false),
        _contact(id: 'c2', name: 'Dr. Bob', isPrimary: true),
      ]);
      expect(p.primaryContact!.name, 'Dr. Bob');
    });

    test('primaryContact falls back to first when none marked', () {
      final p = _profile(contacts: [_contact(id: 'c1', name: 'First')]);
      expect(p.primaryContact!.name, 'First');
    });

    test('hasCriticalInfo detects anaphylactic allergies', () {
      final p = _profile(allergies: [
        _allergy(severity: AllergySeverity.anaphylactic),
      ]);
      expect(p.hasCriticalInfo, isTrue);
    });

    test('hasCriticalInfo detects critical conditions', () {
      final p = _profile(conditions: [
        _condition(severity: ConditionSeverity.critical),
      ]);
      expect(p.hasCriticalInfo, isTrue);
    });

    test('hasCriticalInfo false when mild', () {
      final p = _profile(
        allergies: [_allergy(severity: AllergySeverity.mild)],
        conditions: [_condition(severity: ConditionSeverity.mild)],
      );
      expect(p.hasCriticalInfo, isFalse);
    });

    test('completenessScore reflects filled fields', () {
      final minimal = EmergencyProfile(fullName: 'X');
      expect(minimal.completenessScore, 15); // just name

      final full = _profile(
        address: '123 Main St',
        contacts: [_contact(), _contact(id: 'c2')],
        allergies: [_allergy()],
        currentMedications: ['Aspirin'],
        insurancePolicies: [_policy()],
      );
      expect(full.completenessScore, greaterThanOrEqualTo(85));
    });

    test('completenessLabel maps ranges', () {
      expect(EmergencyProfile(fullName: '').completenessLabel, 'Incomplete');
      expect(EmergencyProfile(fullName: 'X').completenessLabel, 'Incomplete');
    });
  });

  group('InsurancePolicy', () {
    test('isExpired detects expired policy', () {
      final p = _policy(
          expiresAt: DateTime.now().subtract(const Duration(days: 10)));
      expect(p.isExpired, isTrue);
    });

    test('isExpired false for future date', () {
      final p =
          _policy(expiresAt: DateTime.now().add(const Duration(days: 365)));
      expect(p.isExpired, isFalse);
    });

    test('daysUntilExpiry returns correct positive value', () {
      final p =
          _policy(expiresAt: DateTime.now().add(const Duration(days: 30)));
      expect(p.daysUntilExpiry, closeTo(30, 1));
    });

    test('daysUntilExpiry returns null when no expiry', () {
      expect(_policy().daysUntilExpiry, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // JSON round-trip
  // -------------------------------------------------------------------------

  group('JSON serialization', () {
    test('EmergencyProfile round-trips through JSON', () {
      final original = _profile(
        fullName: 'Alice',
        bloodType: BloodType.abNegative,
        contacts: [
          _contact(name: 'Bob', isPrimary: true, email: 'bob@test.com'),
        ],
        allergies: [
          _allergy(
              allergen: 'Shellfish',
              severity: AllergySeverity.severe,
              reaction: 'Hives'),
        ],
        conditions: [
          _condition(name: 'Diabetes', severity: ConditionSeverity.severe),
        ],
        currentMedications: ['Insulin', 'Metformin'],
        insurancePolicies: [_policy(provider: 'Aetna')],
        isOrganDonor: true,
        address: '42 Elm St',
        specialInstructions: 'Has service dog',
      );
      final json = original.toJson();
      final restored = EmergencyProfile.fromJson(json);

      expect(restored.fullName, 'Alice');
      expect(restored.bloodType, BloodType.abNegative);
      expect(restored.contacts.length, 1);
      expect(restored.contacts.first.email, 'bob@test.com');
      expect(restored.allergies.first.allergen, 'Shellfish');
      expect(restored.conditions.first.name, 'Diabetes');
      expect(restored.currentMedications, ['Insulin', 'Metformin']);
      expect(restored.insurancePolicies.first.provider, 'Aetna');
      expect(restored.isOrganDonor, isTrue);
      expect(restored.specialInstructions, 'Has service dog');
    });

    test('EmergencyContact round-trips', () {
      final c = _contact(
        name: 'Alice',
        phone: '555-9999',
        relationship: ContactRelationship.doctor,
        isPrimary: true,
      );
      final restored = EmergencyContact.fromJson(c.toJson());
      expect(restored.name, 'Alice');
      expect(restored.relationship, ContactRelationship.doctor);
      expect(restored.isPrimary, isTrue);
    });

    test('fromJsonString handles invalid input', () {
      expect(EmergencyProfile.fromJsonString('not json'), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Service tests
  // -------------------------------------------------------------------------

  group('EmergencyCardService', () {
    group('contacts', () {
      test('contactsByPriority puts primary first', () {
        final p = _profile(contacts: [
          _contact(id: 'c1', name: 'Friend', relationship: ContactRelationship.friend),
          _contact(id: 'c2', name: 'Spouse', relationship: ContactRelationship.spouse, isPrimary: true),
          _contact(id: 'c3', name: 'Doctor', relationship: ContactRelationship.doctor),
        ]);
        final sorted = service.contactsByPriority(p);
        expect(sorted.first.name, 'Spouse'); // primary
        expect(sorted[1].name, 'Doctor'); // highest priority non-primary
      });

      test('contactsByRelationship filters', () {
        final p = _profile(contacts: [
          _contact(id: 'c1', relationship: ContactRelationship.doctor),
          _contact(id: 'c2', relationship: ContactRelationship.friend),
          _contact(id: 'c3', relationship: ContactRelationship.doctor),
        ]);
        final docs =
            service.contactsByRelationship(p, ContactRelationship.doctor);
        expect(docs.length, 2);
      });
    });

    group('allergies', () {
      test('allergiesBySeverity sorts most severe first', () {
        final p = _profile(allergies: [
          _allergy(id: 'a1', severity: AllergySeverity.mild),
          _allergy(id: 'a2', severity: AllergySeverity.anaphylactic),
          _allergy(id: 'a3', severity: AllergySeverity.moderate),
        ]);
        final sorted = service.allergiesBySeverity(p);
        expect(sorted.first.severity, AllergySeverity.anaphylactic);
        expect(sorted.last.severity, AllergySeverity.mild);
      });

      test('hasAnaphylacticAllergies detects correctly', () {
        expect(service.hasAnaphylacticAllergies(_profile()), isFalse);
        expect(
          service.hasAnaphylacticAllergies(_profile(allergies: [
            _allergy(severity: AllergySeverity.anaphylactic),
          ])),
          isTrue,
        );
      });

      test('allergenList deduplicates and sorts', () {
        final p = _profile(allergies: [
          _allergy(id: 'a1', allergen: 'Peanuts'),
          _allergy(id: 'a2', allergen: 'Dust'),
          _allergy(id: 'a3', allergen: 'Peanuts'),
        ]);
        expect(service.allergenList(p), ['Dust', 'Peanuts']);
      });
    });

    group('insurance', () {
      test('activePolicies excludes expired', () {
        final p = _profile(insurancePolicies: [
          _policy(id: 'p1', expiresAt: DateTime.now().add(const Duration(days: 365))),
          _policy(id: 'p2', expiresAt: DateTime.now().subtract(const Duration(days: 30))),
        ]);
        final active = service.activePolicies(p);
        expect(active.length, 1);
        expect(active.first.id, 'p1');
      });

      test('missingInsuranceTypes identifies gaps', () {
        final p = _profile(insurancePolicies: [
          _policy(type: InsuranceType.health, expiresAt: DateTime.now().add(const Duration(days: 365))),
        ]);
        final missing = service.missingInsuranceTypes(p);
        expect(missing, contains(InsuranceType.dental));
        expect(missing, contains(InsuranceType.vision));
        expect(missing, isNot(contains(InsuranceType.health)));
      });
    });

    group('validation', () {
      test('isMinimallyComplete requires name and contacts', () {
        expect(service.isMinimallyComplete(_profile()), isTrue);
        expect(
          service.isMinimallyComplete(
              _profile(fullName: '', contacts: [])),
          isFalse,
        );
      });

      test('validationWarnings flags missing data', () {
        final p = _profile(
          fullName: '',
          bloodType: BloodType.unknown,
          contacts: [],
          insurancePolicies: [],
        );
        final warnings = service.validationWarnings(p);
        expect(warnings, contains('Full name is required'));
        expect(warnings, contains('Blood type not set'));
        expect(warnings, contains('No emergency contacts added'));
        expect(warnings, contains('No insurance policies added'));
      });

      test('validationWarnings flags expired insurance', () {
        final p = _profile(insurancePolicies: [
          _policy(expiresAt: DateTime.now().subtract(const Duration(days: 5))),
        ]);
        final warnings = service.validationWarnings(p);
        expect(warnings.any((w) => w.contains('expired')), isTrue);
      });
    });

    group('alertLevel', () {
      test('returns incomplete for empty profile', () {
        expect(
          service.alertLevel(EmergencyProfile(fullName: '')),
          'incomplete',
        );
      });

      test('returns critical for anaphylactic allergies', () {
        final p = _profile(
          allergies: [_allergy(severity: AllergySeverity.anaphylactic)],
          address: '123 St',
        );
        expect(service.alertLevel(p), 'critical');
      });

      test('returns warning for missing fields', () {
        final p = _profile(bloodType: BloodType.unknown);
        expect(service.alertLevel(p), 'warning');
      });

      test('returns good for complete healthy profile', () {
        final p = _profile(
          address: '123 St',
          insurancePolicies: [
            _policy(expiresAt: DateTime.now().add(const Duration(days: 365))),
          ],
        );
        expect(service.alertLevel(p), 'good');
      });
    });

    group('export', () {
      test('generateTextCard includes all sections', () {
        final p = _profile(
          fullName: 'John Smith',
          bloodType: BloodType.aPositive,
          contacts: [_contact(name: 'Jane', isPrimary: true)],
          allergies: [_allergy(allergen: 'Penicillin', reaction: 'Rash')],
          conditions: [_condition(name: 'Asthma')],
          currentMedications: ['Albuterol'],
          insurancePolicies: [
            _policy(
              provider: 'UHC',
              policyNumber: 'UHC-999',
              expiresAt: DateTime.now().add(const Duration(days: 365)),
            ),
          ],
          isOrganDonor: true,
          address: '42 Elm Street',
          specialInstructions: 'Wears glasses',
        );
        final card = service.generateTextCard(p);
        expect(card, contains('EMERGENCY INFORMATION CARD'));
        expect(card, contains('John Smith'));
        expect(card, contains('A+'));
        expect(card, contains('Jane'));
        expect(card, contains('Penicillin'));
        expect(card, contains('Rash'));
        expect(card, contains('Asthma'));
        expect(card, contains('Albuterol'));
        expect(card, contains('UHC'));
        expect(card, contains('Organ Donor: Yes'));
        expect(card, contains('42 Elm Street'));
        expect(card, contains('Wears glasses'));
      });

      test('quickSummary gives compact overview', () {
        final p = _profile(
          fullName: 'Alice',
          bloodType: BloodType.bNegative,
          contacts: [_contact(name: 'Bob', isPrimary: true)],
          allergies: [_allergy()],
          currentMedications: ['Med1', 'Med2'],
        );
        final summary = service.quickSummary(p);
        expect(summary, contains('Alice'));
        expect(summary, contains('B-'));
        expect(summary, contains('1 allergy'));
        expect(summary, contains('2 med(s)'));
        expect(summary, contains('ICE: Bob'));
      });
    });

    group('categoryCounts', () {
      test('returns correct counts', () {
        final p = _profile(
          contacts: [_contact(), _contact(id: 'c2')],
          allergies: [_allergy()],
          conditions: [_condition(), _condition(id: 'mc2')],
          currentMedications: ['A', 'B', 'C'],
          insurancePolicies: [_policy()],
        );
        final counts = service.categoryCounts(p);
        expect(counts['contacts'], 2);
        expect(counts['allergies'], 1);
        expect(counts['conditions'], 2);
        expect(counts['medications'], 3);
        expect(counts['insurance'], 1);
      });
    });

    group('mergeProfiles', () {
      test('merges contacts without duplicates', () {
        final p1 = _profile(contacts: [_contact(id: 'c1', name: 'Alice')]);
        final p2 = _profile(contacts: [
          _contact(id: 'c1', name: 'Alice'),
          _contact(id: 'c2', name: 'Bob'),
        ]);
        final merged = service.mergeProfiles(p1, p2);
        expect(merged.contacts.length, 2);
      });

      test('merges medications as set', () {
        final p1 = _profile(currentMedications: ['Aspirin', 'Tylenol']);
        final p2 = _profile(currentMedications: ['Aspirin', 'Advil']);
        final merged = service.mergeProfiles(p1, p2);
        expect(merged.currentMedications.length, 3);
        expect(merged.currentMedications, containsAll(['Aspirin', 'Tylenol', 'Advil']));
      });

      test('preserves primary profile values', () {
        final p1 = _profile(fullName: 'Alice', bloodType: BloodType.aPositive);
        final p2 = _profile(fullName: 'Bob', bloodType: BloodType.bNegative);
        final merged = service.mergeProfiles(p1, p2);
        expect(merged.fullName, 'Alice');
        expect(merged.bloodType, BloodType.aPositive);
      });
    });
  });

  // -------------------------------------------------------------------------
  // Enum tests
  // -------------------------------------------------------------------------

  group('Enums', () {
    test('BloodType labels', () {
      expect(BloodType.aPositive.label, 'A+');
      expect(BloodType.oNegative.label, 'O-');
      expect(BloodType.unknown.label, 'Unknown');
    });

    test('AllergySeverity ordering', () {
      expect(AllergySeverity.mild.index, lessThan(AllergySeverity.anaphylactic.index));
    });

    test('InsuranceType has emoji', () {
      for (final t in InsuranceType.values) {
        expect(t.emoji, isNotEmpty);
      }
    });

    test('ContactRelationship has label and emoji', () {
      for (final r in ContactRelationship.values) {
        expect(r.label, isNotEmpty);
        expect(r.emoji, isNotEmpty);
      }
    });
  });
}
