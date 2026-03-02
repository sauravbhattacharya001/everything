import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/travel_time_estimator.dart';
import 'package:everything/models/event_location.dart';
import 'package:everything/models/event_model.dart';

/// Helper to create a simple event at a given time.
EventModel _event(
  String id,
  String title,
  DateTime start, {
  DateTime? end,
}) {
  return EventModel(
    id: id,
    title: title,
    date: start,
    endDate: end,
  );
}

void main() {
  late TravelTimeEstimator estimator;

  // Two locations ~5 km apart (downtown Seattle ↔ University District)
  const downtown =
      EventLocation(latitude: 47.6062, longitude: -122.3321, placeName: 'Downtown');
  const uDistrict =
      EventLocation(latitude: 47.6553, longitude: -122.3035, placeName: 'U-District');

  // Two locations far apart (Seattle ↔ Portland ~233 km)
  const seattle =
      EventLocation(latitude: 47.6062, longitude: -122.3321, placeName: 'Seattle');
  const portland =
      EventLocation(latitude: 45.5152, longitude: -122.6784, placeName: 'Portland');

  setUp(() {
    estimator = TravelTimeEstimator();
  });

  group('TravelMode', () {
    test('all modes have positive speed and detour', () {
      for (final mode in TravelMode.values) {
        expect(mode.averageSpeedKmh, greaterThan(0));
        expect(mode.detourFactor, greaterThanOrEqualTo(1.0));
        expect(mode.label, isNotEmpty);
      }
    });

    test('driving is faster than walking', () {
      expect(
        TravelMode.driving.averageSpeedKmh,
        greaterThan(TravelMode.walking.averageSpeedKmh),
      );
    });
  });

  group('TravelConflictSeverity', () {
    test('classifies shortfall correctly', () {
      expect(
        TravelConflictSeverity.fromShortfall(const Duration(minutes: 5)),
        TravelConflictSeverity.tight,
      );
      expect(
        TravelConflictSeverity.fromShortfall(const Duration(minutes: 30)),
        TravelConflictSeverity.unlikely,
      );
      expect(
        TravelConflictSeverity.fromShortfall(const Duration(minutes: 90)),
        TravelConflictSeverity.impossible,
      );
    });

    test('boundary: 14 min is tight, 15 min is unlikely, 60 min is impossible',
        () {
      expect(
        TravelConflictSeverity.fromShortfall(const Duration(minutes: 14)),
        TravelConflictSeverity.tight,
      );
      expect(
        TravelConflictSeverity.fromShortfall(const Duration(minutes: 15)),
        TravelConflictSeverity.unlikely,
      );
      expect(
        TravelConflictSeverity.fromShortfall(const Duration(minutes: 60)),
        TravelConflictSeverity.impossible,
      );
    });
  });

  group('Location management', () {
    test('setLocation and getLocation', () {
      estimator.setLocation('e1', downtown);
      expect(estimator.getLocation('e1'), downtown);
      expect(estimator.hasLocation('e1'), isTrue);
      expect(estimator.hasLocation('e2'), isFalse);
      expect(estimator.locationCount, 1);
    });

    test('removeLocation', () {
      estimator.setLocation('e1', downtown);
      estimator.removeLocation('e1');
      expect(estimator.hasLocation('e1'), isFalse);
      expect(estimator.locationCount, 0);
    });

    test('clearLocations', () {
      estimator.setLocation('e1', downtown);
      estimator.setLocation('e2', uDistrict);
      estimator.clearLocations();
      expect(estimator.locationCount, 0);
    });

    test('eventIdsWithLocations', () {
      estimator.setLocation('a', downtown);
      estimator.setLocation('b', uDistrict);
      expect(estimator.eventIdsWithLocations, containsAll(['a', 'b']));
    });
  });

  group('estimateBetween', () {
    test('nearby locations give short travel time', () {
      final from = _event(
        'e1',
        'Meeting',
        DateTime(2026, 3, 1, 9, 0),
        end: DateTime(2026, 3, 1, 10, 0),
      );
      final to = _event(
        'e2',
        'Lunch',
        DateTime(2026, 3, 1, 10, 30),
      );

      final est = estimator.estimateBetween(
        from,
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
      );

      // ~5 km straight line × 1.3 detour ≈ 6.5 km at 40 km/h ≈ 10 min + 10 buffer
      expect(est.straightLineDistanceKm, greaterThan(3));
      expect(est.straightLineDistanceKm, lessThan(10));
      expect(est.estimatedDistanceKm, greaterThan(est.straightLineDistanceKm));
      expect(est.estimatedTravelTime.inMinutes, greaterThan(0));
      expect(est.mode, TravelMode.driving);
    });

    test('feasible estimate has positive buffer', () {
      final from = _event(
        'e1',
        'A',
        DateTime(2026, 3, 1, 9, 0),
        end: DateTime(2026, 3, 1, 10, 0),
      );
      final to = _event(
        'e2',
        'B',
        DateTime(2026, 3, 1, 12, 0),
      );

      final est = estimator.estimateBetween(
        from,
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
      );

      expect(est.isFeasible, isTrue);
      expect(est.buffer, isNot(const Duration()));
      expect(est.shortfall, Duration.zero);
    });

    test('infeasible estimate for tight schedule with long distance', () {
      final from = _event(
        'e1',
        'Seattle Meeting',
        DateTime(2026, 3, 1, 9, 0),
        end: DateTime(2026, 3, 1, 10, 0),
      );
      final to = _event(
        'e2',
        'Portland Meeting',
        DateTime(2026, 3, 1, 10, 15), // Only 15 min gap
      );

      final est = estimator.estimateBetween(
        from,
        to,
        fromLocation: seattle,
        toLocation: portland,
      );

      expect(est.isFeasible, isFalse);
      expect(est.shortfall.inMinutes, greaterThan(0));
    });

    test('walking mode takes longer than driving', () {
      final from = _event(
        'e1',
        'A',
        DateTime(2026, 3, 1, 9, 0),
        end: DateTime(2026, 3, 1, 10, 0),
      );
      final to = _event(
        'e2',
        'B',
        DateTime(2026, 3, 1, 11, 0),
      );

      final driving = estimator.estimateBetween(
        from,
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
        mode: TravelMode.driving,
      );
      final walking = estimator.estimateBetween(
        from,
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
        mode: TravelMode.walking,
      );

      expect(
        walking.estimatedTravelTime,
        greaterThan(driving.estimatedTravelTime),
      );
    });

    test('availableGap uses endDate when present', () {
      final from = _event(
        'e1',
        'A',
        DateTime(2026, 3, 1, 9, 0),
        end: DateTime(2026, 3, 1, 10, 0),
      );
      final to = _event(
        'e2',
        'B',
        DateTime(2026, 3, 1, 11, 0),
      );

      final est = estimator.estimateBetween(
        from,
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
      );

      // Gap should be 1 hour (10:00 → 11:00)
      expect(est.availableGap, const Duration(hours: 1));
    });

    test('availableGap uses date when no endDate', () {
      final from = _event(
        'e1',
        'A',
        DateTime(2026, 3, 1, 9, 0),
      );
      final to = _event(
        'e2',
        'B',
        DateTime(2026, 3, 1, 10, 0),
      );

      final est = estimator.estimateBetween(
        from,
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
      );

      // Gap should be 1 hour (9:00 → 10:00) since no endDate
      expect(est.availableGap, const Duration(hours: 1));
    });

    test('summary contains key information', () {
      final from = _event(
        'e1',
        'A',
        DateTime(2026, 3, 1, 9, 0),
        end: DateTime(2026, 3, 1, 10, 0),
      );
      final to = _event(
        'e2',
        'B',
        DateTime(2026, 3, 1, 12, 0),
      );

      final est = estimator.estimateBetween(
        from,
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
      );

      expect(est.summary, contains('Driving'));
      expect(est.summary, contains('OK'));
    });
  });

  group('analyzeSchedule', () {
    test('empty events returns empty schedule', () {
      final schedule = estimator.analyzeSchedule([]);
      expect(schedule.estimates, isEmpty);
      expect(schedule.tripCount, 0);
      expect(schedule.hasConflicts, isFalse);
      expect(schedule.totalDistanceKm, 0.0);
      expect(schedule.totalTravelTime, Duration.zero);
    });

    test('single event returns no estimates', () {
      final event = _event('e1', 'Solo', DateTime(2026, 3, 1, 9, 0));
      estimator.setLocation('e1', downtown);
      final schedule = estimator.analyzeSchedule([event]);
      expect(schedule.estimates, isEmpty);
      expect(schedule.eventsWithLocations.length, 1);
    });

    test('events without locations are tracked separately', () {
      final e1 = _event('e1', 'A', DateTime(2026, 3, 1, 9, 0));
      final e2 = _event('e2', 'B', DateTime(2026, 3, 1, 10, 0));
      estimator.setLocation('e1', downtown);
      // e2 has no location

      final schedule = estimator.analyzeSchedule([e1, e2]);
      expect(schedule.eventsWithLocations.length, 1);
      expect(schedule.eventsWithoutLocations.length, 1);
      expect(schedule.estimates, isEmpty);
    });

    test('two events with locations produce one estimate', () {
      final e1 = _event(
        'e1',
        'Morning',
        DateTime(2026, 3, 1, 9, 0),
        end: DateTime(2026, 3, 1, 10, 0),
      );
      final e2 = _event(
        'e2',
        'Afternoon',
        DateTime(2026, 3, 1, 14, 0),
      );
      estimator.setLocation('e1', downtown);
      estimator.setLocation('e2', uDistrict);

      final schedule = estimator.analyzeSchedule([e2, e1]); // Unsorted
      expect(schedule.estimates.length, 1);
      expect(schedule.estimates[0].from.title, 'Morning'); // Sorted by date
      expect(schedule.estimates[0].to.title, 'Afternoon');
    });

    test('three events produce two estimates', () {
      final e1 = _event('e1', 'A', DateTime(2026, 3, 1, 9, 0),
          end: DateTime(2026, 3, 1, 10, 0));
      final e2 = _event('e2', 'B', DateTime(2026, 3, 1, 12, 0),
          end: DateTime(2026, 3, 1, 13, 0));
      final e3 = _event('e3', 'C', DateTime(2026, 3, 1, 16, 0));
      estimator.setLocation('e1', downtown);
      estimator.setLocation('e2', uDistrict);
      estimator.setLocation('e3', downtown);

      final schedule = estimator.analyzeSchedule([e1, e2, e3]);
      expect(schedule.estimates.length, 2);
      expect(schedule.tripCount, 2);
      expect(schedule.totalDistanceKm, greaterThan(0));
    });

    test('detects conflicts with tight schedules', () {
      // Seattle → Portland with only 30 min gap
      final e1 = _event('e1', 'Seattle', DateTime(2026, 3, 1, 9, 0),
          end: DateTime(2026, 3, 1, 10, 0));
      final e2 = _event('e2', 'Portland', DateTime(2026, 3, 1, 10, 30));
      estimator.setLocation('e1', seattle);
      estimator.setLocation('e2', portland);

      final schedule = estimator.analyzeSchedule([e1, e2]);
      expect(schedule.hasConflicts, isTrue);
      expect(schedule.conflicts.length, 1);
      expect(schedule.conflicts[0].description, contains('Seattle'));
      expect(schedule.conflicts[0].description, contains('Portland'));
    });

    test('no conflicts with generous gaps', () {
      final e1 = _event('e1', 'A', DateTime(2026, 3, 1, 9, 0),
          end: DateTime(2026, 3, 1, 10, 0));
      final e2 = _event('e2', 'B', DateTime(2026, 3, 1, 15, 0));
      estimator.setLocation('e1', downtown);
      estimator.setLocation('e2', uDistrict);

      final schedule = estimator.analyzeSchedule([e1, e2]);
      expect(schedule.hasConflicts, isFalse);
    });

    test('summary text is descriptive', () {
      final e1 = _event('e1', 'A', DateTime(2026, 3, 1, 9, 0),
          end: DateTime(2026, 3, 1, 10, 0));
      final e2 = _event('e2', 'B', DateTime(2026, 3, 1, 12, 0));
      estimator.setLocation('e1', downtown);
      estimator.setLocation('e2', uDistrict);

      final schedule = estimator.analyzeSchedule([e1, e2]);
      expect(schedule.summary, contains('trip'));
      expect(schedule.summary, contains('km'));
    });

    test('empty schedule summary', () {
      final schedule = estimator.analyzeSchedule([]);
      expect(schedule.summary, 'No travel needed');
    });
  });

  group('latestDepartureTime', () {
    test('returns time before event accounting for travel', () {
      final to = _event('e2', 'Meeting', DateTime(2026, 3, 1, 10, 0));

      final departure = estimator.latestDepartureTime(
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
      );

      expect(departure, isNotNull);
      expect(departure!.isBefore(to.date), isTrue);
    });

    test('walking departure is earlier than driving', () {
      final to = _event('e2', 'Meeting', DateTime(2026, 3, 1, 10, 0));

      final driveDep = estimator.latestDepartureTime(
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
        mode: TravelMode.driving,
      );
      final walkDep = estimator.latestDepartureTime(
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
        mode: TravelMode.walking,
      );

      expect(walkDep!.isBefore(driveDep!), isTrue);
    });
  });

  group('suggestFastestFeasibleMode', () {
    test('suggests driving for moderate distance and gap', () {
      final from = _event('e1', 'A', DateTime(2026, 3, 1, 9, 0),
          end: DateTime(2026, 3, 1, 10, 0));
      final to = _event('e2', 'B', DateTime(2026, 3, 1, 10, 30));

      final mode = estimator.suggestFastestFeasibleMode(
        from,
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
      );

      expect(mode, TravelMode.driving);
    });

    test('returns null when no mode is feasible', () {
      // Seattle → Portland with 5 min gap — nothing works
      final from = _event('e1', 'A', DateTime(2026, 3, 1, 9, 0),
          end: DateTime(2026, 3, 1, 10, 0));
      final to = _event('e2', 'B', DateTime(2026, 3, 1, 10, 5));

      final mode = estimator.suggestFastestFeasibleMode(
        from,
        to,
        fromLocation: seattle,
        toLocation: portland,
      );

      expect(mode, isNull);
    });
  });

  group('getStats', () {
    test('empty schedules return zero stats', () {
      final stats = estimator.getStats([]);
      expect(stats['days'], 0);
      expect(stats['totalTrips'], 0);
      expect(stats['totalDistanceKm'], 0.0);
    });

    test('aggregates across multiple schedules', () {
      final e1 = _event('e1', 'A', DateTime(2026, 3, 1, 9, 0),
          end: DateTime(2026, 3, 1, 10, 0));
      final e2 = _event('e2', 'B', DateTime(2026, 3, 1, 14, 0));
      estimator.setLocation('e1', downtown);
      estimator.setLocation('e2', uDistrict);

      final s1 = estimator.analyzeSchedule([e1, e2]);
      final s2 = estimator.analyzeSchedule([e1, e2]);

      final stats = estimator.getStats([s1, s2]);
      expect(stats['days'], 2);
      expect(stats['totalTrips'], 2);
      expect(stats['totalDistanceKm'], greaterThan(0));
      expect(stats['avgTripsPerDay'], 1.0);
    });
  });

  group('custom configuration', () {
    test('custom buffer time affects estimates', () {
      final noBuf = TravelTimeEstimator(bufferTime: Duration.zero);
      final bigBuf = TravelTimeEstimator(
        bufferTime: const Duration(minutes: 30),
      );

      final from = _event('e1', 'A', DateTime(2026, 3, 1, 9, 0),
          end: DateTime(2026, 3, 1, 10, 0));
      final to = _event('e2', 'B', DateTime(2026, 3, 1, 11, 0));

      final estNoBuf = noBuf.estimateBetween(
        from,
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
      );
      final estBigBuf = bigBuf.estimateBetween(
        from,
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
      );

      expect(
        estBigBuf.estimatedTravelTime,
        greaterThan(estNoBuf.estimatedTravelTime),
      );
    });

    test('default mode is used when not overridden', () {
      final walkEstimator = TravelTimeEstimator(
        defaultMode: TravelMode.walking,
      );

      final from = _event('e1', 'A', DateTime(2026, 3, 1, 9, 0),
          end: DateTime(2026, 3, 1, 10, 0));
      final to = _event('e2', 'B', DateTime(2026, 3, 1, 11, 0));

      final est = walkEstimator.estimateBetween(
        from,
        to,
        fromLocation: downtown,
        toLocation: uDistrict,
      );

      expect(est.mode, TravelMode.walking);
    });

    test('initial locations from constructor', () {
      final est = TravelTimeEstimator(
        locations: {'e1': downtown, 'e2': uDistrict},
      );
      expect(est.locationCount, 2);
      expect(est.hasLocation('e1'), isTrue);
      expect(est.hasLocation('e2'), isTrue);
    });
  });

  group('TravelConflict', () {
    test('description includes event titles and severity', () {
      final from = _event('e1', 'Seattle Meeting', DateTime(2026, 3, 1, 9, 0),
          end: DateTime(2026, 3, 1, 10, 0));
      final to =
          _event('e2', 'Portland Call', DateTime(2026, 3, 1, 10, 15));

      final est = estimator.estimateBetween(
        from,
        to,
        fromLocation: seattle,
        toLocation: portland,
      );

      final conflict = TravelConflict(
        estimate: est,
        severity: TravelConflictSeverity.fromShortfall(est.shortfall),
      );

      expect(conflict.description, contains('Seattle Meeting'));
      expect(conflict.description, contains('Portland Call'));
      expect(conflict.description, contains('short by'));
    });
  });
}
