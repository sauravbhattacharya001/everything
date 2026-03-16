import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/views/home/emergency_card_screen.dart';
import 'package:everything/models/emergency_profile.dart';
import 'package:everything/core/services/emergency_card_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const service = EmergencyCardService();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('EmergencyCardScreen widget', () {
    testWidgets('renders with 4 tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EmergencyCardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Contacts'), findsOneWidget);
      expect(find.text('Medical'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
    });

    testWidgets('shows profile completeness on first tab', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EmergencyCardScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profile Completeness'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);
      expect(find.text('Blood Type'), findsOneWidget);
    });

    testWidgets('contacts tab shows empty state', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EmergencyCardScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contacts'));
      await tester.pumpAndSettle();

      expect(find.text('No emergency contacts yet'), findsOneWidget);
      expect(find.text('Add Emergency Contact'), findsOneWidget);
    });

    testWidgets('medical tab shows empty sections', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EmergencyCardScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medical'));
      await tester.pumpAndSettle();

      expect(find.text('Allergies'), findsOneWidget);
      expect(find.text('Medical Conditions'), findsOneWidget);
      expect(find.text('Current Medications'), findsOneWidget);
      expect(find.text('Insurance Policies'), findsOneWidget);
    });

    testWidgets('card tab shows emergency card', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EmergencyCardScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Card'));
      await tester.pumpAndSettle();

      expect(find.text('EMERGENCY MEDICAL CARD'), findsOneWidget);
      expect(find.text('Shareable Text'), findsOneWidget);
    });

    testWidgets('add contact dialog opens', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EmergencyCardScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contacts'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Emergency Contact'));
      await tester.pumpAndSettle();

      expect(find.text('Add Emergency Contact'), findsNWidgets(2)); // button + dialog title
      expect(find.text('Name *'), findsOneWidget);
      expect(find.text('Phone *'), findsOneWidget);
    });

    testWidgets('can add a contact', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EmergencyCardScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Contacts'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add Emergency Contact'));
      await tester.pumpAndSettle();

      // Fill in name and phone
      await tester.enterText(find.widgetWithText(TextField, 'Name *'), 'Jane Doe');
      await tester.enterText(find.widgetWithText(TextField, 'Phone *'), '555-1234');
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add').last);
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('📞 555-1234'), findsOneWidget);
    });

    testWidgets('add allergy dialog opens from medical tab', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EmergencyCardScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medical'));
      await tester.pumpAndSettle();

      // Find the add button next to Allergies (first add_circle_outline)
      final addButtons = find.byIcon(Icons.add_circle_outline);
      expect(addButtons, findsWidgets);

      await tester.tap(addButtons.first);
      await tester.pumpAndSettle();

      expect(find.text('Add Allergy'), findsOneWidget);
      expect(find.text('Allergen *'), findsOneWidget);
    });

    testWidgets('add medication dialog opens', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: EmergencyCardScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Medical'));
      await tester.pumpAndSettle();

      // Medication add button is the 3rd add_circle_outline
      final addButtons = find.byIcon(Icons.add_circle_outline);
      await tester.tap(addButtons.at(2));
      await tester.pumpAndSettle();

      expect(find.text('Add Medication'), findsOneWidget);
    });
  });

  group('EmergencyCardService', () {
    test('contactsByPriority returns sorted contacts', () {
      final profile = EmergencyProfile(
        fullName: 'Test User',
        contacts: [
          const EmergencyContact(
            id: '1', name: 'Friend', phone: '111',
            relationship: ContactRelationship.friend,
          ),
          const EmergencyContact(
            id: '2', name: 'Doctor', phone: '222',
            relationship: ContactRelationship.doctor,
          ),
        ],
      );
      final sorted = service.contactsByPriority(profile);
      expect(sorted.first.name, 'Doctor');
    });

    test('generateTextCard includes name and blood type', () {
      final profile = EmergencyProfile(
        fullName: 'John Smith',
        bloodType: BloodType.oPositive,
      );
      final text = service.generateTextCard(profile);
      expect(text, contains('John Smith'));
      expect(text, contains('O+'));
    });

    test('validationWarnings flags missing contacts', () {
      final profile = EmergencyProfile(fullName: 'Test');
      final warnings = service.validationWarnings(profile);
      expect(warnings.any((w) => w.toLowerCase().contains('contact')), isTrue);
    });

    test('completenessScore increases with data', () {
      final empty = EmergencyProfile(fullName: '');
      final filled = EmergencyProfile(
        fullName: 'Jane',
        bloodType: BloodType.aPositive,
        contacts: [
          const EmergencyContact(
            id: '1', name: 'Mom', phone: '555',
            relationship: ContactRelationship.parent,
          ),
        ],
      );
      expect(filled.completenessScore, greaterThan(empty.completenessScore));
    });

    test('hasCriticalInfo detects anaphylactic allergies', () {
      final profile = EmergencyProfile(
        fullName: 'Test',
        allergies: [
          const Allergy(
            id: '1', allergen: 'Peanuts',
            severity: AllergySeverity.anaphylactic,
          ),
        ],
      );
      expect(profile.hasCriticalInfo, isTrue);
    });

    test('age calculation is correct', () {
      final profile = EmergencyProfile(
        fullName: 'Test',
        dateOfBirth: DateTime(1990, 1, 1),
      );
      expect(profile.age, greaterThanOrEqualTo(35));
    });

    test('primaryContact returns first primary', () {
      final profile = EmergencyProfile(
        fullName: 'Test',
        contacts: [
          const EmergencyContact(
            id: '1', name: 'A', phone: '111',
            relationship: ContactRelationship.friend,
          ),
          const EmergencyContact(
            id: '2', name: 'B', phone: '222',
            relationship: ContactRelationship.spouse, isPrimary: true,
          ),
        ],
      );
      expect(profile.primaryContact?.name, 'B');
    });

    test('EmergencyProfile JSON roundtrip', () {
      final profile = EmergencyProfile(
        fullName: 'Test User',
        bloodType: BloodType.bNegative,
        isOrganDonor: true,
        contacts: [
          const EmergencyContact(
            id: '1', name: 'Doc', phone: '555',
            relationship: ContactRelationship.doctor,
          ),
        ],
        allergies: [
          const Allergy(id: '1', allergen: 'Dust'),
        ],
      );
      final json = profile.toJsonString();
      final restored = EmergencyProfile.fromJsonString(json);
      expect(restored, isNotNull);
      expect(restored!.fullName, 'Test User');
      expect(restored.bloodType, BloodType.bNegative);
      expect(restored.isOrganDonor, isTrue);
      expect(restored.contacts.length, 1);
      expect(restored.allergies.length, 1);
    });

    test('InsurancePolicy expiry detection', () {
      final expired = InsurancePolicy(
        id: '1', type: InsuranceType.health,
        provider: 'Test', policyNumber: 'P001',
        expiresAt: DateTime.now().subtract(const Duration(days: 30)),
      );
      expect(expired.isExpired, isTrue);

      final active = InsurancePolicy(
        id: '2', type: InsuranceType.dental,
        provider: 'Test', policyNumber: 'P002',
        expiresAt: DateTime.now().add(const Duration(days: 90)),
      );
      expect(active.isExpired, isFalse);
    });
  });
}
