import 'dart:convert';
import 'dart:math' as math;

/// Represents a geographic location attached to an event.
///
/// Stores latitude/longitude coordinates, an optional human-readable
/// address, and an optional place name. Provides Haversine distance
/// calculation for travel time estimation.
class EventLocation {
  /// Geographic latitude in decimal degrees (-90 to 90).
  final double latitude;

  /// Geographic longitude in decimal degrees (-180 to 180).
  final double longitude;

  /// Optional human-readable address (e.g. "123 Main St, Seattle, WA").
  final String address;

  /// Optional short name for the place (e.g. "Office", "Home", "Gym").
  final String placeName;

  /// Creates an [EventLocation] with the given coordinates.
  ///
  /// [latitude] must be between -90 and 90 (inclusive).
  /// [longitude] must be between -180 and 180 (inclusive).
  ///
  /// Invalid coordinates are accepted by the constructor (to allow
  /// intermediate construction), but [isValid] returns false and
  /// [distanceTo] returns 0.0 for safety.  Use [validated] for a
  /// throwing variant that rejects out-of-range values.
  const EventLocation({
    required this.latitude,
    required this.longitude,
    this.address = '',
    this.placeName = '',
  });

  /// Creates a validated [EventLocation], throwing [ArgumentError] if
  /// coordinates are outside the allowed geographic range.
  ///
  /// Prefer this over the default constructor when building locations
  /// from untrusted input (user forms, JSON APIs, etc.).
  factory EventLocation.validated({
    required double latitude,
    required double longitude,
    String address = '',
    String placeName = '',
  }) {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'Must be between -90 and 90 (inclusive)',
      );
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Must be between -180 and 180 (inclusive)',
      );
    }
    return EventLocation(
      latitude: latitude,
      longitude: longitude,
      address: address,
      placeName: placeName,
    );
  }

  /// Whether coordinates are within valid geographic ranges.
  bool get isValid =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  /// Display label: place name if available, otherwise address, otherwise
  /// coordinate pair.
  String get displayLabel {
    if (placeName.isNotEmpty) return placeName;
    if (address.isNotEmpty) return address;
    return '${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}';
  }

  /// Whether this location has a named place.
  bool get hasPlaceName => placeName.isNotEmpty;

  /// Whether this location has an address.
  bool get hasAddress => address.isNotEmpty;

  // ── Distance ───────────────────────────────────────────────────

  /// Earth's mean radius in kilometers.
  static const double _earthRadiusKm = 6371.0;

  /// Computes the great-circle (Haversine) distance to [other] in kilometers.
  ///
  /// Returns 0.0 if either location is invalid.
  double distanceTo(EventLocation other) {
    if (!isValid || !other.isValid) return 0.0;

    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(other.latitude);
    final dLat = _toRadians(other.latitude - latitude);
    final dLon = _toRadians(other.longitude - longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return _earthRadiusKm * c;
  }

  /// Distance in miles (1 km ≈ 0.621371 mi).
  double distanceToMiles(EventLocation other) => distanceTo(other) * 0.621371;

  static double _toRadians(double degrees) => degrees * math.pi / 180.0;

  // ── Serialization ──────────────────────────────────────────────

  /// Creates an [EventLocation] from a JSON map.
  ///
  /// Validates that coordinates are within valid geographic ranges.
  /// Throws [ArgumentError] if latitude or longitude is out of bounds.
  factory EventLocation.fromJson(Map<String, dynamic> json) {
    final lat = (json['latitude'] as num).toDouble();
    final lon = (json['longitude'] as num).toDouble();
    return EventLocation.validated(
      latitude: lat,
      longitude: lon,
      address: (json['address'] as String?) ?? '',
      placeName: (json['place_name'] as String?) ?? '',
    );
  }

  /// Converts this location to a JSON-compatible map.
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      if (address.isNotEmpty) 'address': address,
      if (placeName.isNotEmpty) 'place_name': placeName,
    };
  }

  /// Serializes to a JSON string.
  String toJsonString() => jsonEncode(toJson());

  /// Deserializes from a JSON string. Returns null if input is null,
  /// empty, malformed, or contains out-of-range coordinates.
  static EventLocation? fromJsonString(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return EventLocation.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  // ── Equality ───────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventLocation &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          address == other.address &&
          placeName == other.placeName;

  @override
  int get hashCode => Object.hash(latitude, longitude, address, placeName);

  @override
  String toString() =>
      'EventLocation($displayLabel @ $latitude, $longitude)';
}
