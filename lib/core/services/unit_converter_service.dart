/// Unit converter service supporting multiple measurement categories.
///
/// Each category contains a set of units with conversion factors relative
/// to a base unit. Temperature uses custom formulas instead.

/// A single unit definition within a category.
class UnitDef {
  final String name;
  final String abbrev;

  /// Factor to convert **from** this unit **to** the base unit of its category.
  /// For temperature units this is ignored — special formulas apply.
  final double toBaseFactor;

  const UnitDef({
    required this.name,
    required this.abbrev,
    this.toBaseFactor = 1.0,
  });
}

/// A measurement category (e.g. Length, Weight).
class UnitCategory {
  final String name;
  final String icon; // Material icon name hint (not used at runtime)
  final List<UnitDef> units;

  const UnitCategory({
    required this.name,
    required this.icon,
    required this.units,
  });
}

class UnitConverterService {
  UnitConverterService._();

  // ── Categories ──

  static final List<UnitCategory> categories = [
    // Length – base: meter
    UnitCategory(name: 'Length', icon: 'straighten', units: [
      UnitDef(name: 'Millimeter', abbrev: 'mm', toBaseFactor: 0.001),
      UnitDef(name: 'Centimeter', abbrev: 'cm', toBaseFactor: 0.01),
      UnitDef(name: 'Meter', abbrev: 'm', toBaseFactor: 1),
      UnitDef(name: 'Kilometer', abbrev: 'km', toBaseFactor: 1000),
      UnitDef(name: 'Inch', abbrev: 'in', toBaseFactor: 0.0254),
      UnitDef(name: 'Foot', abbrev: 'ft', toBaseFactor: 0.3048),
      UnitDef(name: 'Yard', abbrev: 'yd', toBaseFactor: 0.9144),
      UnitDef(name: 'Mile', abbrev: 'mi', toBaseFactor: 1609.344),
    ]),

    // Weight – base: kilogram
    UnitCategory(name: 'Weight', icon: 'scale', units: [
      UnitDef(name: 'Milligram', abbrev: 'mg', toBaseFactor: 0.000001),
      UnitDef(name: 'Gram', abbrev: 'g', toBaseFactor: 0.001),
      UnitDef(name: 'Kilogram', abbrev: 'kg', toBaseFactor: 1),
      UnitDef(name: 'Metric Ton', abbrev: 't', toBaseFactor: 1000),
      UnitDef(name: 'Ounce', abbrev: 'oz', toBaseFactor: 0.0283495),
      UnitDef(name: 'Pound', abbrev: 'lb', toBaseFactor: 0.453592),
      UnitDef(name: 'Stone', abbrev: 'st', toBaseFactor: 6.35029),
    ]),

    // Temperature – base: Celsius (special handling)
    UnitCategory(name: 'Temperature', icon: 'thermostat', units: [
      UnitDef(name: 'Celsius', abbrev: '°C'),
      UnitDef(name: 'Fahrenheit', abbrev: '°F'),
      UnitDef(name: 'Kelvin', abbrev: 'K'),
    ]),

    // Volume – base: liter
    UnitCategory(name: 'Volume', icon: 'local_drink', units: [
      UnitDef(name: 'Milliliter', abbrev: 'mL', toBaseFactor: 0.001),
      UnitDef(name: 'Liter', abbrev: 'L', toBaseFactor: 1),
      UnitDef(name: 'Gallon (US)', abbrev: 'gal', toBaseFactor: 3.78541),
      UnitDef(name: 'Quart (US)', abbrev: 'qt', toBaseFactor: 0.946353),
      UnitDef(name: 'Pint (US)', abbrev: 'pt', toBaseFactor: 0.473176),
      UnitDef(name: 'Cup (US)', abbrev: 'cup', toBaseFactor: 0.236588),
      UnitDef(name: 'Fluid Ounce (US)', abbrev: 'fl oz', toBaseFactor: 0.0295735),
      UnitDef(name: 'Tablespoon', abbrev: 'tbsp', toBaseFactor: 0.0147868),
      UnitDef(name: 'Teaspoon', abbrev: 'tsp', toBaseFactor: 0.00492892),
    ]),

    // Speed – base: m/s
    UnitCategory(name: 'Speed', icon: 'speed', units: [
      UnitDef(name: 'Meters/sec', abbrev: 'm/s', toBaseFactor: 1),
      UnitDef(name: 'Km/hour', abbrev: 'km/h', toBaseFactor: 0.277778),
      UnitDef(name: 'Miles/hour', abbrev: 'mph', toBaseFactor: 0.44704),
      UnitDef(name: 'Knots', abbrev: 'kn', toBaseFactor: 0.514444),
      UnitDef(name: 'Feet/sec', abbrev: 'ft/s', toBaseFactor: 0.3048),
    ]),

    // Data Storage – base: byte
    UnitCategory(name: 'Data', icon: 'storage', units: [
      UnitDef(name: 'Bit', abbrev: 'b', toBaseFactor: 0.125),
      UnitDef(name: 'Byte', abbrev: 'B', toBaseFactor: 1),
      UnitDef(name: 'Kilobyte', abbrev: 'KB', toBaseFactor: 1024),
      UnitDef(name: 'Megabyte', abbrev: 'MB', toBaseFactor: 1048576),
      UnitDef(name: 'Gigabyte', abbrev: 'GB', toBaseFactor: 1073741824),
      UnitDef(name: 'Terabyte', abbrev: 'TB', toBaseFactor: 1099511627776),
    ]),

    // Area – base: sq meter
    UnitCategory(name: 'Area', icon: 'square_foot', units: [
      UnitDef(name: 'Sq Millimeter', abbrev: 'mm²', toBaseFactor: 0.000001),
      UnitDef(name: 'Sq Centimeter', abbrev: 'cm²', toBaseFactor: 0.0001),
      UnitDef(name: 'Sq Meter', abbrev: 'm²', toBaseFactor: 1),
      UnitDef(name: 'Hectare', abbrev: 'ha', toBaseFactor: 10000),
      UnitDef(name: 'Sq Kilometer', abbrev: 'km²', toBaseFactor: 1000000),
      UnitDef(name: 'Sq Inch', abbrev: 'in²', toBaseFactor: 0.00064516),
      UnitDef(name: 'Sq Foot', abbrev: 'ft²', toBaseFactor: 0.092903),
      UnitDef(name: 'Acre', abbrev: 'ac', toBaseFactor: 4046.86),
      UnitDef(name: 'Sq Mile', abbrev: 'mi²', toBaseFactor: 2589988.11),
    ]),

    // Time – base: second
    UnitCategory(name: 'Time', icon: 'schedule', units: [
      UnitDef(name: 'Millisecond', abbrev: 'ms', toBaseFactor: 0.001),
      UnitDef(name: 'Second', abbrev: 's', toBaseFactor: 1),
      UnitDef(name: 'Minute', abbrev: 'min', toBaseFactor: 60),
      UnitDef(name: 'Hour', abbrev: 'h', toBaseFactor: 3600),
      UnitDef(name: 'Day', abbrev: 'd', toBaseFactor: 86400),
      UnitDef(name: 'Week', abbrev: 'wk', toBaseFactor: 604800),
      UnitDef(name: 'Year', abbrev: 'yr', toBaseFactor: 31557600),
    ]),
  ];

  // ── Conversion ──

  /// Convert [value] from [fromUnit] to [toUnit] within [category].
  ///
  /// Temperature uses explicit formulas; everything else uses
  /// base-unit factors.
  static double convert({
    required UnitCategory category,
    required UnitDef fromUnit,
    required UnitDef toUnit,
    required double value,
  }) {
    if (category.name == 'Temperature') {
      return _convertTemperature(value, fromUnit.abbrev, toUnit.abbrev);
    }
    // value → base → target
    final baseValue = value * fromUnit.toBaseFactor;
    return baseValue / toUnit.toBaseFactor;
  }

  static double _convertTemperature(double v, String from, String to) {
    if (from == to) return v;
    // Convert to Celsius first
    double celsius;
    switch (from) {
      case '°C':
        celsius = v;
        break;
      case '°F':
        celsius = (v - 32) * 5 / 9;
        break;
      case 'K':
        celsius = v - 273.15;
        break;
      default:
        celsius = v;
    }
    // Celsius to target
    switch (to) {
      case '°C':
        return celsius;
      case '°F':
        return celsius * 9 / 5 + 32;
      case 'K':
        return celsius + 273.15;
      default:
        return celsius;
    }
  }

  /// Smartly format a conversion result — avoids unnecessary decimals
  /// for whole-number results and uses scientific notation for very
  /// large/small numbers.
  static String formatResult(double value) {
    if (value == 0) return '0';
    final abs = value.abs();
    if (abs >= 1e12 || (abs > 0 && abs < 1e-6)) {
      return value.toStringAsExponential(4);
    }
    // Up to 8 decimal places, trimmed
    String s = value.toStringAsFixed(8);
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    return s;
  }
}
