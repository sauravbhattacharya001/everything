import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/event_template.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/event_tag.dart';

void main() {
  group('EventTemplate', () {
    group('construction', () {
      test('creates with required fields', () {
        final template = EventTemplate(
          id: 'test1',
          name: 'Test',
          icon: '📝',
        );
        expect(template.id, 'test1');
        expect(template.name, 'Test');
        expect(template.icon, '📝');
        expect(template.defaultTitle, '');
        expect(template.defaultDescription, '');
        expect(template.defaultPriority, EventPriority.medium);
        expect(template.defaultTags, isEmpty);
        expect(template.defaultDuration, const Duration(hours: 1));
        expect(template.isBuiltIn, false);
      });

      test('creates with all fields', () {
        final tags = [const EventTag(name: 'Work', colorIndex: 0)];
        final template = EventTemplate(
          id: 'test2',
          name: 'Full Template',
          icon: '🎯',
          defaultTitle: 'My Title',
          defaultDescription: 'My Description',
          defaultPriority: EventPriority.high,
          defaultTags: tags,
          defaultDuration: const Duration(minutes: 45),
          isBuiltIn: true,
        );
        expect(template.defaultTitle, 'My Title');
        expect(template.defaultDescription, 'My Description');
        expect(template.defaultPriority, EventPriority.high);
        expect(template.defaultTags, tags);
        expect(template.defaultDuration, const Duration(minutes: 45));
        expect(template.isBuiltIn, true);
      });
    });

    group('presets', () {
      test('has 10 built-in presets', () {
        expect(EventTemplate.presets.length, 10);
      });

      test('all presets are built-in', () {
        for (final preset in EventTemplate.presets) {
          expect(preset.isBuiltIn, true, reason: '${preset.name} should be built-in');
        }
      });

      test('all presets have unique IDs', () {
        final ids = EventTemplate.presets.map((t) => t.id).toSet();
        expect(ids.length, EventTemplate.presets.length);
      });

      test('all presets have non-empty names and icons', () {
        for (final preset in EventTemplate.presets) {
          expect(preset.name.isNotEmpty, true, reason: 'Preset ${preset.id} needs name');
          expect(preset.icon.isNotEmpty, true, reason: 'Preset ${preset.id} needs icon');
        }
      });

      test('all presets have valid priorities', () {
        for (final preset in EventTemplate.presets) {
          expect(EventPriority.values.contains(preset.defaultPriority), true);
        }
      });

      test('preset IDs start with preset_', () {
        for (final preset in EventTemplate.presets) {
          expect(preset.id.startsWith('preset_'), true,
              reason: '${preset.id} should start with preset_');
        }
      });

      test('includes expected preset types', () {
        final names = EventTemplate.presets.map((t) => t.name).toSet();
        expect(names, contains('Meeting'));
        expect(names, contains('Birthday'));
        expect(names, contains('Doctor'));
        expect(names, contains('Workout'));
        expect(names, contains('Standup'));
        expect(names, contains('Lunch'));
        expect(names, contains('Travel'));
        expect(names, contains('Deadline'));
        expect(names, contains('Social'));
        expect(names, contains('Focus Time'));
      });

      test('deadline has urgent priority', () {
        final deadline = EventTemplate.presets.firstWhere((t) => t.name == 'Deadline');
        expect(deadline.defaultPriority, EventPriority.urgent);
      });

      test('standup has 15 minute duration', () {
        final standup = EventTemplate.presets.firstWhere((t) => t.name == 'Standup');
        expect(standup.defaultDuration, const Duration(minutes: 15));
      });

      test('meeting has agenda description template', () {
        final meeting = EventTemplate.presets.firstWhere((t) => t.name == 'Meeting');
        expect(meeting.defaultDescription, contains('Agenda'));
      });
    });

    group('createEvent', () {
      test('creates event with template defaults', () {
        final template = EventTemplate(
          id: 'tmpl1',
          name: 'Test',
          icon: '📝',
          defaultTitle: 'Default Title',
          defaultDescription: 'Default Desc',
          defaultPriority: EventPriority.high,
          defaultTags: [const EventTag(name: 'Work', colorIndex: 0)],
        );
        final now = DateTime.now();
        final event = template.createEvent(id: 'evt1', dateTime: now);

        expect(event.id, 'evt1');
        expect(event.title, 'Default Title');
        expect(event.description, 'Default Desc');
        expect(event.priority, EventPriority.high);
        expect(event.tags.length, 1);
        expect(event.tags[0].name, 'Work');
        expect(event.date, now);
      });

      test('allows overriding template defaults', () {
        final template = EventTemplate(
          id: 'tmpl2',
          name: 'Test',
          icon: '📝',
          defaultTitle: 'Default Title',
          defaultPriority: EventPriority.low,
        );
        final now = DateTime.now();
        final event = template.createEvent(
          id: 'evt2',
          dateTime: now,
          title: 'Custom Title',
          priority: EventPriority.urgent,
        );

        expect(event.title, 'Custom Title');
        expect(event.priority, EventPriority.urgent);
      });

      test('creates event from preset', () {
        final meeting = EventTemplate.presets.firstWhere((t) => t.name == 'Meeting');
        final date = DateTime(2026, 3, 15, 10, 0);
        final event = meeting.createEvent(id: 'mtg1', dateTime: date);

        expect(event.title, 'Meeting');
        expect(event.priority, EventPriority.high);
        expect(event.tags.isNotEmpty, true);
        expect(event.date, date);
      });

      test('creates independent tag list copies', () {
        final template = EventTemplate(
          id: 'tmpl3',
          name: 'Test',
          icon: '📝',
          defaultTags: [const EventTag(name: 'A', colorIndex: 0)],
        );
        final event1 = template.createEvent(id: 'e1', dateTime: DateTime.now());
        final event2 = template.createEvent(id: 'e2', dateTime: DateTime.now());

        // Should be separate list instances
        expect(identical(event1.tags, event2.tags), false);
      });
    });

    group('fromEvent', () {
      test('creates template from existing event', () {
        final event = EventModel(
          id: 'evt1',
          title: 'Team Sync',
          description: 'Weekly sync meeting',
          date: DateTime.now(),
          priority: EventPriority.high,
          tags: [const EventTag(name: 'Work', colorIndex: 0)],
        );

        final template = EventTemplate.fromEvent(
          id: 'custom1',
          name: 'Team Sync Template',
          icon: '🤝',
          event: event,
        );

        expect(template.id, 'custom1');
        expect(template.name, 'Team Sync Template');
        expect(template.icon, '🤝');
        expect(template.defaultTitle, 'Team Sync');
        expect(template.defaultDescription, 'Weekly sync meeting');
        expect(template.defaultPriority, EventPriority.high);
        expect(template.defaultTags.length, 1);
        expect(template.isBuiltIn, false);
      });

      test('creates independent copy of tags', () {
        final tags = [const EventTag(name: 'Work', colorIndex: 0)];
        final event = EventModel(
          id: 'evt1',
          title: 'Test',
          date: DateTime.now(),
          tags: tags,
        );

        final template = EventTemplate.fromEvent(
          id: 'tmpl1',
          name: 'Test',
          icon: '📝',
          event: event,
        );

        expect(identical(template.defaultTags, tags), false);
      });
    });

    group('copyWith', () {
      test('copies with changed name', () {
        final original = EventTemplate(
          id: 'tmpl1',
          name: 'Original',
          icon: '📝',
          defaultTitle: 'Title',
        );
        final copy = original.copyWith(name: 'Changed');

        expect(copy.id, 'tmpl1');
        expect(copy.name, 'Changed');
        expect(copy.defaultTitle, 'Title');
      });

      test('copies with changed priority', () {
        final original = EventTemplate(
          id: 'tmpl1',
          name: 'Test',
          icon: '📝',
          defaultPriority: EventPriority.low,
        );
        final copy = original.copyWith(defaultPriority: EventPriority.urgent);

        expect(copy.defaultPriority, EventPriority.urgent);
        expect(original.defaultPriority, EventPriority.low);
      });

      test('copies all fields when none specified', () {
        final original = EventTemplate(
          id: 'tmpl1',
          name: 'Test',
          icon: '📝',
          defaultTitle: 'Title',
          defaultDescription: 'Desc',
          defaultPriority: EventPriority.high,
          defaultDuration: const Duration(minutes: 30),
          isBuiltIn: true,
        );
        final copy = original.copyWith();

        expect(copy.id, original.id);
        expect(copy.name, original.name);
        expect(copy.icon, original.icon);
        expect(copy.defaultTitle, original.defaultTitle);
        expect(copy.defaultDescription, original.defaultDescription);
        expect(copy.defaultPriority, original.defaultPriority);
        expect(copy.defaultDuration, original.defaultDuration);
        expect(copy.isBuiltIn, original.isBuiltIn);
      });
    });

    group('JSON serialization', () {
      test('round-trips through JSON', () {
        final template = EventTemplate(
          id: 'tmpl1',
          name: 'Test Template',
          icon: '🎯',
          defaultTitle: 'My Event',
          defaultDescription: 'Description here',
          defaultPriority: EventPriority.high,
          defaultTags: [const EventTag(name: 'Work', colorIndex: 0)],
          defaultDuration: const Duration(minutes: 45),
          isBuiltIn: false,
        );

        final json = template.toJson();
        final restored = EventTemplate.fromJson(json);

        expect(restored.id, template.id);
        expect(restored.name, template.name);
        expect(restored.icon, template.icon);
        expect(restored.defaultTitle, template.defaultTitle);
        expect(restored.defaultDescription, template.defaultDescription);
        expect(restored.defaultPriority, template.defaultPriority);
        expect(restored.defaultTags.length, template.defaultTags.length);
        expect(restored.defaultDuration, template.defaultDuration);
        expect(restored.isBuiltIn, template.isBuiltIn);
      });

      test('fromJson handles missing optional fields', () {
        final json = {
          'id': 'tmpl1',
          'name': 'Minimal',
          'icon': '📝',
        };
        final template = EventTemplate.fromJson(json);

        expect(template.defaultTitle, '');
        expect(template.defaultDescription, '');
        expect(template.defaultPriority, EventPriority.medium);
        expect(template.defaultTags, isEmpty);
        expect(template.defaultDuration, const Duration(hours: 1));
        expect(template.isBuiltIn, false);
      });

      test('toJson includes all fields', () {
        final template = EventTemplate(
          id: 'tmpl1',
          name: 'Test',
          icon: '📝',
          defaultTitle: 'Title',
          defaultDuration: const Duration(minutes: 30),
        );
        final json = template.toJson();

        expect(json['id'], 'tmpl1');
        expect(json['name'], 'Test');
        expect(json['icon'], '📝');
        expect(json['defaultTitle'], 'Title');
        expect(json['defaultDurationMinutes'], 30);
        expect(json['isBuiltIn'], false);
      });
    });

    group('list serialization', () {
      test('toJsonString serializes list', () {
        final templates = [
          EventTemplate(id: 'a', name: 'A', icon: '🅰️'),
          EventTemplate(id: 'b', name: 'B', icon: '🅱️'),
        ];
        final jsonStr = EventTemplate.toJsonString(templates);
        expect(jsonStr, isNotEmpty);
        expect(jsonStr, contains('a'));
        expect(jsonStr, contains('b'));
      });

      test('fromJsonString restores list', () {
        final templates = [
          EventTemplate(id: 'a', name: 'A', icon: '🅰️'),
          EventTemplate(id: 'b', name: 'B', icon: '🅱️'),
        ];
        final jsonStr = EventTemplate.toJsonString(templates);
        final restored = EventTemplate.fromJsonString(jsonStr);

        expect(restored.length, 2);
        expect(restored[0].id, 'a');
        expect(restored[1].id, 'b');
      });

      test('fromJsonString handles null', () {
        expect(EventTemplate.fromJsonString(null), isEmpty);
      });

      test('fromJsonString handles empty string', () {
        expect(EventTemplate.fromJsonString(''), isEmpty);
      });

      test('fromJsonString handles malformed JSON', () {
        expect(EventTemplate.fromJsonString('not json'), isEmpty);
      });
    });

    group('equality', () {
      test('templates with same ID are equal', () {
        final a = EventTemplate(id: 'tmpl1', name: 'A', icon: '📝');
        final b = EventTemplate(id: 'tmpl1', name: 'B', icon: '🎯');
        expect(a, equals(b));
      });

      test('templates with different IDs are not equal', () {
        final a = EventTemplate(id: 'tmpl1', name: 'A', icon: '📝');
        final b = EventTemplate(id: 'tmpl2', name: 'A', icon: '📝');
        expect(a, isNot(equals(b)));
      });

      test('hashCode is based on ID', () {
        final a = EventTemplate(id: 'tmpl1', name: 'A', icon: '📝');
        final b = EventTemplate(id: 'tmpl1', name: 'B', icon: '🎯');
        expect(a.hashCode, b.hashCode);
      });
    });

    group('toString', () {
      test('includes key fields', () {
        final template = EventTemplate(id: 'tmpl1', name: 'Test', icon: '📝');
        final str = template.toString();
        expect(str, contains('tmpl1'));
        expect(str, contains('Test'));
      });
    });
  });
}
