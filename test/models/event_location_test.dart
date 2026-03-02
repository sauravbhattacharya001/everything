import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/event_location.dart';

void main() {
  group('EventLocation', () {
    test('constructor sets all fields', () {
      const loc = EventLocation(
        latitude: 47.6062,
        longitude: -122.3321,
        address: '123 Main St',
        placeName: 'Office',
      );
      expect(loc.latitude, 47.6062);
      expect(loc.longitude, -122.3321);
      expect(loc.address, '123 Main St');
      expect(loc.placeName, 'Office');
    });

    test('defaults to empty address and placeName', () {
      const loc = EventLocation(latitude: 0, longitude: 0);
      expect(loc.address, '');
      expect(loc.placeName, '');
    });

    test('isValid returns true for valid coordinates', () {
      const loc = EventLocation(latitude: 47.6062, longitude: -122.3321);
      expect(loc.isValid, isTrue);
    });

    test('isValid returns true for boundary values', () {
      expect(
        const EventLocation(latitude: 90, longitude: 180).isValid,
        isTrue,
      );
      expect(
        const EventLocation(latitude: -90, longitude: -180).isValid,
        isTrue,
      );
      expect(
        const EventLocation(latitude: 0, longitude: 0).isValid,
        isTrue,
      );
    });

    test('isValid returns false for out-of-range latitude', () {
      expect(
        const EventLocation(latitude: 91, longitude: 0).isValid,
        isFalse,
      );
      expect(
        const EventLocation(latitude: -91, longitude: 0).isValid,
        isFalse,
      );
    });

    test('isValid returns false for out-of-range longitude', () {
      expect(
        const EventLocation(latitude: 0, longitude: 181).isValid,
        isFalse,
      );
      expect(
        const EventLocation(latitude: 0, longitude: -181).isValid,
        isFalse,
      );
    });

    test('displayLabel prefers placeName', () {
      const loc = EventLocation(
        latitude: 47.6,
        longitude: -122.3,
        address: '123 Main',
        placeName: 'Home',
      );
      expect(loc.displayLabel, 'Home');
    });

    test('displayLabel falls back to address', () {
      const loc = EventLocation(
        latitude: 47.6,
        longitude: -122.3,
        address: '123 Main St',
      );
      expect(loc.displayLabel, '123 Main St');
    });

    test('displayLabel falls back to coordinates', () {
      const loc = EventLocation(latitude: 47.6062, longitude: -122.3321);
      expect(loc.displayLabel, '47.6062, -122.3321');
    });

    test('hasPlaceName and hasAddress', () {
      const loc1 = EventLocation(
        latitude: 0,
        longitude: 0,
        placeName: 'X',
      );
      expect(loc1.hasPlaceName, isTrue);
      expect(loc1.hasAddress, isFalse);

      const loc2 = EventLocation(
        latitude: 0,
        longitude: 0,
        address: 'Y',
      );
      expect(loc2.hasPlaceName, isFalse);
      expect(loc2.hasAddress, isTrue);
    });

    group('distanceTo', () {
      test('same point returns 0', () {
        const loc = EventLocation(latitude: 47.6, longitude: -122.3);
        expect(loc.distanceTo(loc), 0.0);
      });

      test('known distance Seattle to Portland (~233 km)', () {
        const seattle =
            EventLocation(latitude: 47.6062, longitude: -122.3321);
        const portland =
            EventLocation(latitude: 45.5152, longitude: -122.6784);
        final dist = seattle.distanceTo(portland);
        // Haversine straight-line ~233 km
        expect(dist, greaterThan(220));
        expect(dist, lessThan(250));
      });

      test('known distance NYC to London (~5570 km)', () {
        const nyc = EventLocation(latitude: 40.7128, longitude: -74.0060);
        const london = EventLocation(latitude: 51.5074, longitude: -0.1278);
        final dist = nyc.distanceTo(london);
        expect(dist, greaterThan(5500));
        expect(dist, lessThan(5700));
      });

      test('invalid location returns 0', () {
        const valid = EventLocation(latitude: 47.6, longitude: -122.3);
        const invalid = EventLocation(latitude: 100, longitude: 0);
        expect(valid.distanceTo(invalid), 0.0);
        expect(invalid.distanceTo(valid), 0.0);
      });

      test('distanceToMiles converts correctly', () {
        const seattle =
            EventLocation(latitude: 47.6062, longitude: -122.3321);
        const portland =
            EventLocation(latitude: 45.5152, longitude: -122.6784);
        final km = seattle.distanceTo(portland);
        final mi = seattle.distanceToMiles(portland);
        expect((mi / km - 0.621371).abs(), lessThan(0.001));
      });
    });

    group('serialization', () {
      test('toJson includes all fields', () {
        const loc = EventLocation(
          latitude: 47.6,
          longitude: -122.3,
          address: '123 Main',
          placeName: 'Office',
        );
        final json = loc.toJson();
        expect(json['latitude'], 47.6);
        expect(json['longitude'], -122.3);
        expect(json['address'], '123 Main');
        expect(json['place_name'], 'Office');
      });

      test('toJson omits empty optional fields', () {
        const loc = EventLocation(latitude: 0, longitude: 0);
        final json = loc.toJson();
        expect(json.containsKey('address'), isFalse);
        expect(json.containsKey('place_name'), isFalse);
      });

      test('fromJson round-trips', () {
        const original = EventLocation(
          latitude: 47.6,
          longitude: -122.3,
          address: '123 Main',
          placeName: 'Office',
        );
        final restored = EventLocation.fromJson(original.toJson());
        expect(restored, original);
      });

      test('fromJsonString round-trips', () {
        const original = EventLocation(
          latitude: 51.5,
          longitude: -0.1,
          placeName: 'London',
        );
        final restored = EventLocation.fromJsonString(original.toJsonString());
        expect(restored, original);
      });

      test('fromJsonString returns null for null/empty/malformed', () {
        expect(EventLocation.fromJsonString(null), isNull);
        expect(EventLocation.fromJsonString(''), isNull);
        expect(EventLocation.fromJsonString('not json'), isNull);
      });

      test('fromJson handles integer coordinates', () {
        final loc = EventLocation.fromJson({
          'latitude': 47,
          'longitude': -122,
        });
        expect(loc.latitude, 47.0);
        expect(loc.longitude, -122.0);
      });
    });

    group('equality', () {
      test('equal locations are equal', () {
        const a = EventLocation(latitude: 1, longitude: 2, address: 'X');
        const b = EventLocation(latitude: 1, longitude: 2, address: 'X');
        expect(a, b);
        expect(a.hashCode, b.hashCode);
      });

      test('different locations are not equal', () {
        const a = EventLocation(latitude: 1, longitude: 2);
        const b = EventLocation(latitude: 1, longitude: 3);
        expect(a, isNot(b));
      });

      test('different placeName makes unequal', () {
        const a = EventLocation(latitude: 1, longitude: 2, placeName: 'A');
        const b = EventLocation(latitude: 1, longitude: 2, placeName: 'B');
        expect(a, isNot(b));
      });
    });

    test('toString includes display label and coordinates', () {
      const loc = EventLocation(
        latitude: 47.6,
        longitude: -122.3,
        placeName: 'Office',
      );
      final str = loc.toString();
      expect(str, contains('Office'));
      expect(str, contains('47.6'));
      expect(str, contains('-122.3'));
    });
  });
}
