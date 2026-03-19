import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/unit_converter_service.dart';

void main() {
  group('UnitConverterService', () {
    group('categories', () {
      test('has expected category count', () {
        expect(UnitConverterService.categories.length, 8);
      });

      test('all categories have at least 2 units', () {
        for (final cat in UnitConverterService.categories) {
          expect(cat.units.length, greaterThanOrEqualTo(2),
              reason: '${cat.name} should have at least 2 units');
        }
      });

      test('all units have non-empty names and abbreviations', () {
        for (final cat in UnitConverterService.categories) {
          for (final unit in cat.units) {
            expect(unit.name, isNotEmpty);
            expect(unit.abbrev, isNotEmpty);
          }
        }
      });
    });

    group('Length conversions', () {
      late UnitCategory length;
      setUp(() {
        length = UnitConverterService.categories
            .firstWhere((c) => c.name == 'Length');
      });

      test('1 km = 1000 m', () {
        final km = length.units.firstWhere((u) => u.abbrev == 'km');
        final m = length.units.firstWhere((u) => u.abbrev == 'm');
        final result = UnitConverterService.convert(
            category: length, fromUnit: km, toUnit: m, value: 1);
        expect(result, closeTo(1000, 0.001));
      });

      test('1 mile = 1.609344 km', () {
        final mi = length.units.firstWhere((u) => u.abbrev == 'mi');
        final km = length.units.firstWhere((u) => u.abbrev == 'km');
        final result = UnitConverterService.convert(
            category: length, fromUnit: mi, toUnit: km, value: 1);
        expect(result, closeTo(1.609344, 0.0001));
      });

      test('1 foot = 12 inches', () {
        final ft = length.units.firstWhere((u) => u.abbrev == 'ft');
        final inch = length.units.firstWhere((u) => u.abbrev == 'in');
        final result = UnitConverterService.convert(
            category: length, fromUnit: ft, toUnit: inch, value: 1);
        expect(result, closeTo(12, 0.01));
      });

      test('identity conversion (m to m)', () {
        final m = length.units.firstWhere((u) => u.abbrev == 'm');
        final result = UnitConverterService.convert(
            category: length, fromUnit: m, toUnit: m, value: 42);
        expect(result, closeTo(42, 0.001));
      });
    });

    group('Weight conversions', () {
      late UnitCategory weight;
      setUp(() {
        weight = UnitConverterService.categories
            .firstWhere((c) => c.name == 'Weight');
      });

      test('1 kg = 1000 g', () {
        final kg = weight.units.firstWhere((u) => u.abbrev == 'kg');
        final g = weight.units.firstWhere((u) => u.abbrev == 'g');
        final result = UnitConverterService.convert(
            category: weight, fromUnit: kg, toUnit: g, value: 1);
        expect(result, closeTo(1000, 0.01));
      });

      test('1 lb ≈ 0.4536 kg', () {
        final lb = weight.units.firstWhere((u) => u.abbrev == 'lb');
        final kg = weight.units.firstWhere((u) => u.abbrev == 'kg');
        final result = UnitConverterService.convert(
            category: weight, fromUnit: lb, toUnit: kg, value: 1);
        expect(result, closeTo(0.453592, 0.0001));
      });

      test('1 stone = 14 lb', () {
        final st = weight.units.firstWhere((u) => u.abbrev == 'st');
        final lb = weight.units.firstWhere((u) => u.abbrev == 'lb');
        final result = UnitConverterService.convert(
            category: weight, fromUnit: st, toUnit: lb, value: 1);
        expect(result, closeTo(14, 0.01));
      });
    });

    group('Temperature conversions', () {
      late UnitCategory temp;
      setUp(() {
        temp = UnitConverterService.categories
            .firstWhere((c) => c.name == 'Temperature');
      });

      test('0°C = 32°F', () {
        final c = temp.units.firstWhere((u) => u.abbrev == '°C');
        final f = temp.units.firstWhere((u) => u.abbrev == '°F');
        final result = UnitConverterService.convert(
            category: temp, fromUnit: c, toUnit: f, value: 0);
        expect(result, closeTo(32, 0.01));
      });

      test('100°C = 212°F', () {
        final c = temp.units.firstWhere((u) => u.abbrev == '°C');
        final f = temp.units.firstWhere((u) => u.abbrev == '°F');
        final result = UnitConverterService.convert(
            category: temp, fromUnit: c, toUnit: f, value: 100);
        expect(result, closeTo(212, 0.01));
      });

      test('0°C = 273.15K', () {
        final c = temp.units.firstWhere((u) => u.abbrev == '°C');
        final k = temp.units.firstWhere((u) => u.abbrev == 'K');
        final result = UnitConverterService.convert(
            category: temp, fromUnit: c, toUnit: k, value: 0);
        expect(result, closeTo(273.15, 0.01));
      });

      test('°F to K round-trip', () {
        final f = temp.units.firstWhere((u) => u.abbrev == '°F');
        final k = temp.units.firstWhere((u) => u.abbrev == 'K');
        final toK = UnitConverterService.convert(
            category: temp, fromUnit: f, toUnit: k, value: 72);
        final backToF = UnitConverterService.convert(
            category: temp, fromUnit: k, toUnit: f, value: toK);
        expect(backToF, closeTo(72, 0.01));
      });

      test('identity (°C to °C)', () {
        final c = temp.units.firstWhere((u) => u.abbrev == '°C');
        final result = UnitConverterService.convert(
            category: temp, fromUnit: c, toUnit: c, value: -40);
        expect(result, closeTo(-40, 0.01));
      });

      test('-40 is the same in °C and °F', () {
        final c = temp.units.firstWhere((u) => u.abbrev == '°C');
        final f = temp.units.firstWhere((u) => u.abbrev == '°F');
        final result = UnitConverterService.convert(
            category: temp, fromUnit: c, toUnit: f, value: -40);
        expect(result, closeTo(-40, 0.01));
      });
    });

    group('Data storage conversions', () {
      late UnitCategory data;
      setUp(() {
        data = UnitConverterService.categories
            .firstWhere((c) => c.name == 'Data');
      });

      test('1 KB = 1024 bytes', () {
        final kb = data.units.firstWhere((u) => u.abbrev == 'KB');
        final b = data.units.firstWhere((u) => u.abbrev == 'B');
        final result = UnitConverterService.convert(
            category: data, fromUnit: kb, toUnit: b, value: 1);
        expect(result, closeTo(1024, 0.01));
      });

      test('1 GB = 1024 MB', () {
        final gb = data.units.firstWhere((u) => u.abbrev == 'GB');
        final mb = data.units.firstWhere((u) => u.abbrev == 'MB');
        final result = UnitConverterService.convert(
            category: data, fromUnit: gb, toUnit: mb, value: 1);
        expect(result, closeTo(1024, 0.01));
      });

      test('1 byte = 8 bits', () {
        final byte = data.units.firstWhere((u) => u.abbrev == 'B');
        final bit = data.units.firstWhere((u) => u.abbrev == 'b');
        final result = UnitConverterService.convert(
            category: data, fromUnit: byte, toUnit: bit, value: 1);
        expect(result, closeTo(8, 0.01));
      });
    });

    group('Volume conversions', () {
      late UnitCategory volume;
      setUp(() {
        volume = UnitConverterService.categories
            .firstWhere((c) => c.name == 'Volume');
      });

      test('1 gallon ≈ 3.785 liters', () {
        final gal = volume.units.firstWhere((u) => u.abbrev == 'gal');
        final l = volume.units.firstWhere((u) => u.abbrev == 'L');
        final result = UnitConverterService.convert(
            category: volume, fromUnit: gal, toUnit: l, value: 1);
        expect(result, closeTo(3.78541, 0.001));
      });

      test('1 cup = 16 tablespoons', () {
        final cup = volume.units.firstWhere((u) => u.abbrev == 'cup');
        final tbsp = volume.units.firstWhere((u) => u.abbrev == 'tbsp');
        final result = UnitConverterService.convert(
            category: volume, fromUnit: cup, toUnit: tbsp, value: 1);
        expect(result, closeTo(16, 0.1));
      });
    });

    group('formatResult', () {
      test('zero returns "0"', () {
        expect(UnitConverterService.formatResult(0), '0');
      });

      test('whole numbers have no decimals', () {
        expect(UnitConverterService.formatResult(42.0), '42');
      });

      test('trims trailing zeros', () {
        expect(UnitConverterService.formatResult(3.5), '3.5');
      });

      test('very large numbers use scientific notation', () {
        final result = UnitConverterService.formatResult(1e15);
        expect(result, contains('e'));
      });

      test('very small numbers use scientific notation', () {
        final result = UnitConverterService.formatResult(1e-9);
        expect(result, contains('e'));
      });
    });

    group('Speed conversions', () {
      late UnitCategory speed;
      setUp(() {
        speed = UnitConverterService.categories
            .firstWhere((c) => c.name == 'Speed');
      });

      test('1 km/h ≈ 0.6214 mph', () {
        final kmh = speed.units.firstWhere((u) => u.abbrev == 'km/h');
        final mph = speed.units.firstWhere((u) => u.abbrev == 'mph');
        final result = UnitConverterService.convert(
            category: speed, fromUnit: kmh, toUnit: mph, value: 1);
        expect(result, closeTo(0.6214, 0.001));
      });
    });
  });
}
