import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:everything/views/home/parking_spot_screen.dart';

void main() {
  Widget createApp() {
    return const MaterialApp(home: ParkingSpotScreen());
  }

  group('ParkingSpotScreen', () {
    testWidgets('renders empty state initially', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('No active parking spot'), findsOneWidget);
      expect(find.text('Save Spot'), findsOneWidget);
    });

    testWidgets('shows save dialog on FAB tap', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Save Spot'));
      await tester.pumpAndSettle();
      expect(find.text('Save Parking Spot'), findsOneWidget);
      expect(find.text('Location *'), findsOneWidget);
      expect(find.text('Level/Floor'), findsOneWidget);
      expect(find.text('Spot #'), findsOneWidget);
      expect(find.text('Notes'), findsOneWidget);
    });

    testWidgets('cancel button dismisses dialog', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Save Spot'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Save Parking Spot'), findsNothing);
    });

    testWidgets('does not save with empty location', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Save Spot'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // Dialog should still be visible
      expect(find.text('Save Parking Spot'), findsOneWidget);
    });

    testWidgets('saves a spot with location only', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Save Spot'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Location *'), 'Mall Garage');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Mall Garage'), findsOneWidget);
      expect(find.text('No active parking spot'), findsNothing);
    });

    testWidgets('saves spot with all fields', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Save Spot'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Location *'), 'Airport');
      await tester.enterText(
          find.widgetWithText(TextField, 'Level/Floor'), 'P3');
      await tester.enterText(
          find.widgetWithText(TextField, 'Spot #'), 'B-12');
      await tester.enterText(
          find.widgetWithText(TextField, 'Notes'), 'Near elevator');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Airport'), findsOneWidget);
      expect(find.text('Level P3'), findsOneWidget);
      expect(find.text('Spot B-12'), findsOneWidget);
      expect(find.text('Near elevator'), findsOneWidget);
    });

    testWidgets('shows Found Car button when spot is active', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Found Car'), findsNothing);
      await tester.tap(find.text('Save Spot'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Location *'), 'Street');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Found Car'), findsOneWidget);
    });

    testWidgets('Found Car moves spot to history', (tester) async {
      await tester.pumpWidget(createApp());
      // Save a spot
      await tester.tap(find.text('Save Spot'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Location *'), 'Downtown');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // Tap Found Car
      await tester.tap(find.text('Found Car'));
      await tester.pumpAndSettle();
      expect(find.text('No active parking spot'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Downtown'), findsOneWidget);
    });

    testWidgets('meter toggle shows preset chips', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Save Spot'));
      await tester.pumpAndSettle();
      // Initially no presets
      expect(find.text('1h'), findsNothing);
      // Toggle meter on
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.text('15m'), findsOneWidget);
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('1h'), findsOneWidget);
    });

    testWidgets('saving with meter shows countdown', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Save Spot'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Location *'), 'Meter St');
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      // Select 30m preset
      await tester.tap(find.text('30m'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Meter Time Left'), findsOneWidget);
      expect(find.text('Add Time'), findsOneWidget);
    });

    testWidgets('Add Time button shows dialog', (tester) async {
      await tester.pumpWidget(createApp());
      // Save with meter
      await tester.tap(find.text('Save Spot'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Location *'), 'Test');
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // Tap Add Time
      await tester.tap(find.text('Add Time'));
      await tester.pumpAndSettle();
      expect(find.text('Add Meter Time'), findsOneWidget);
      expect(find.text('45m'), findsOneWidget);
    });

    testWidgets('FAB shows New Spot when active spot exists', (tester) async {
      await tester.pumpWidget(createApp());
      await tester.tap(find.text('Save Spot'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Location *'), 'First');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('New Spot'), findsOneWidget);
    });

    testWidgets('saving new spot moves old to history', (tester) async {
      await tester.pumpWidget(createApp());
      // Save first spot
      await tester.tap(find.text('Save Spot'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Location *'), 'First Place');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      // Save second spot
      await tester.tap(find.text('New Spot'));
      await tester.pumpAndSettle();
      await tester.enterText(
          find.widgetWithText(TextField, 'Location *'), 'Second Place');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('Second Place'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      // First Place should be in history
      expect(find.text('First Place'), findsOneWidget);
    });

    testWidgets('AppBar title is Parking Spot', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.text('Parking Spot'), findsOneWidget);
    });

    testWidgets('shows parking icon in empty state', (tester) async {
      await tester.pumpWidget(createApp());
      expect(find.byIcon(Icons.local_parking), findsWidgets);
    });
  });

  group('ParkingSpot model', () {
    test('hasMeter returns false when no expiry', () {
      final spot = ParkingSpot(
        id: '1',
        locationName: 'Test',
        savedAt: DateTime.now(),
      );
      expect(spot.hasMeter, false);
      expect(spot.isMeterExpired, false);
    });

    test('hasMeter returns true when expiry set', () {
      final spot = ParkingSpot(
        id: '1',
        locationName: 'Test',
        savedAt: DateTime.now(),
        meterExpiry: DateTime.now().add(const Duration(hours: 1)),
      );
      expect(spot.hasMeter, true);
      expect(spot.isMeterExpired, false);
    });

    test('isMeterExpired returns true for past expiry', () {
      final spot = ParkingSpot(
        id: '1',
        locationName: 'Test',
        savedAt: DateTime.now(),
        meterExpiry: DateTime.now().subtract(const Duration(minutes: 5)),
      );
      expect(spot.isMeterExpired, true);
    });

    test('timeRemaining is zero when expired', () {
      final spot = ParkingSpot(
        id: '1',
        locationName: 'Test',
        savedAt: DateTime.now(),
        meterExpiry: DateTime.now().subtract(const Duration(minutes: 1)),
      );
      expect(spot.timeRemaining, Duration.zero);
    });

    test('timeRemaining is positive when not expired', () {
      final spot = ParkingSpot(
        id: '1',
        locationName: 'Test',
        savedAt: DateTime.now(),
        meterExpiry: DateTime.now().add(const Duration(minutes: 30)),
      );
      expect(spot.timeRemaining.inMinutes, greaterThanOrEqualTo(29));
    });
  });
}
