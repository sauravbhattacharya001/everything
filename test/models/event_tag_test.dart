import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/event_tag.dart';

void main() {
  group('EventTag', () {
    group('construction', () {
      test('creates tag with name and default colorIndex', () {
        const tag = EventTag(name: 'Work');
        expect(tag.name, 'Work');
        expect(tag.colorIndex, 0);
      });

      test('creates tag with custom colorIndex', () {
        const tag = EventTag(name: 'Personal', colorIndex: 3);
        expect(tag.name, 'Personal');
        expect(tag.colorIndex, 3);
      });

      test('color resolves from palette', () {
        const tag = EventTag(name: 'Test', colorIndex: 1);
        expect(tag.color, EventTag.palette[1]);
      });

      test('color clamps out-of-range index', () {
        const tag = EventTag(name: 'Test', colorIndex: 99);
        expect(tag.color, EventTag.palette[EventTag.palette.length - 1]);
      });

      test('color clamps negative index', () {
        const tag = EventTag(name: 'Test', colorIndex: -1);
        expect(tag.color, EventTag.palette[0]);
      });
    });

    group('fromJson', () {
      test('creates tag from valid JSON', () {
        final tag = EventTag.fromJson({'name': 'Work', 'colorIndex': 2});
        expect(tag.name, 'Work');
        expect(tag.colorIndex, 2);
      });

      test('defaults colorIndex to 0 when missing', () {
        final tag = EventTag.fromJson({'name': 'Test'});
        expect(tag.colorIndex, 0);
      });
    });

    group('toJson', () {
      test('serializes to JSON map', () {
        const tag = EventTag(name: 'Meeting', colorIndex: 4);
        final json = tag.toJson();
        expect(json['name'], 'Meeting');
        expect(json['colorIndex'], 4);
      });

      test('round-trip preserves data', () {
        const original = EventTag(name: 'Health', colorIndex: 5);
        final restored = EventTag.fromJson(original.toJson());
        expect(restored.name, original.name);
        expect(restored.colorIndex, original.colorIndex);
      });
    });

    group('equality', () {
      test('same name (case-insensitive) is equal', () {
        const a = EventTag(name: 'Work', colorIndex: 0);
        const b = EventTag(name: 'work', colorIndex: 3);
        expect(a, b);
      });

      test('different names are not equal', () {
        const a = EventTag(name: 'Work');
        const b = EventTag(name: 'Personal');
        expect(a, isNot(b));
      });

      test('same name has same hashCode', () {
        const a = EventTag(name: 'Meeting');
        const b = EventTag(name: 'meeting');
        expect(a.hashCode, b.hashCode);
      });

      test('not equal to non-EventTag', () {
        const tag = EventTag(name: 'Test');
        // ignore: unrelated_type_equality_checks
        expect(tag == 'not a tag', isFalse);
      });
    });

    group('presets', () {
      test('has 8 preset tags', () {
        expect(EventTag.presets.length, 8);
      });

      test('preset names are unique', () {
        final names =
            EventTag.presets.map((t) => t.name.toLowerCase()).toSet();
        expect(names.length, EventTag.presets.length);
      });

      test('presets have valid colorIndex values', () {
        for (final preset in EventTag.presets) {
          expect(preset.colorIndex, greaterThanOrEqualTo(0));
          expect(preset.colorIndex, lessThan(EventTag.palette.length));
        }
      });
    });

    group('palette', () {
      test('has 8 colors', () {
        expect(EventTag.palette.length, 8);
      });

      test('has 8 palette names', () {
        expect(EventTag.paletteNames.length, 8);
      });

      test('palette and paletteNames have same length', () {
        expect(EventTag.palette.length, EventTag.paletteNames.length);
      });
    });

    group('toString', () {
      test('returns descriptive string', () {
        const tag = EventTag(name: 'Work', colorIndex: 2);
        expect(tag.toString(), contains('Work'));
        expect(tag.toString(), contains('2'));
      });
    });
  });
}
