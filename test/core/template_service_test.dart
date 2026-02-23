import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:everything/core/services/template_service.dart';
import 'package:everything/models/event_template.dart';
import 'package:everything/models/event_tag.dart';
import 'package:everything/models/event_model.dart';

void main() {
  group('TemplateService', () {
    late TemplateService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      service = TemplateService(prefs);
    });

    group('initial state', () {
      test('has built-in presets', () {
        expect(service.presets.length, 10);
      });

      test('has no custom templates initially', () {
        expect(service.customTemplates, isEmpty);
        expect(service.customCount, 0);
      });

      test('allTemplates returns presets when no custom', () {
        expect(service.allTemplates.length, 10);
      });

      test('totalCount returns preset count initially', () {
        expect(service.totalCount, 10);
      });
    });

    group('addTemplate', () {
      test('adds a custom template', () {
        final template = EventTemplate(
          id: 'custom1',
          name: 'My Template',
          icon: '📝',
        );
        final result = service.addTemplate(template);

        expect(result, true);
        expect(service.customCount, 1);
        expect(service.totalCount, 11);
      });

      test('rejects duplicate ID', () {
        final template = EventTemplate(
          id: 'custom1',
          name: 'My Template',
          icon: '📝',
        );
        service.addTemplate(template);
        final result = service.addTemplate(template);

        expect(result, false);
        expect(service.customCount, 1);
      });

      test('rejects preset ID', () {
        final template = EventTemplate(
          id: 'preset_meeting',
          name: 'Fake Meeting',
          icon: '📝',
        );
        final result = service.addTemplate(template);

        expect(result, false);
        expect(service.customCount, 0);
      });

      test('respects max custom templates limit', () {
        for (int i = 0; i < TemplateService.maxCustomTemplates; i++) {
          service.addTemplate(EventTemplate(
            id: 'custom_$i',
            name: 'Template $i',
            icon: '📝',
          ));
        }

        final result = service.addTemplate(EventTemplate(
          id: 'one_too_many',
          name: 'Overflow',
          icon: '📝',
        ));

        expect(result, false);
        expect(service.customCount, TemplateService.maxCustomTemplates);
      });
    });

    group('updateTemplate', () {
      test('updates existing custom template', () {
        service.addTemplate(EventTemplate(
          id: 'custom1',
          name: 'Original',
          icon: '📝',
        ));

        final updated = EventTemplate(
          id: 'custom1',
          name: 'Updated',
          icon: '🎯',
        );
        final result = service.updateTemplate(updated);

        expect(result, true);
        expect(service.findById('custom1')!.name, 'Updated');
        expect(service.findById('custom1')!.icon, '🎯');
      });

      test('returns false for non-existent template', () {
        final result = service.updateTemplate(EventTemplate(
          id: 'nonexistent',
          name: 'Test',
          icon: '📝',
        ));
        expect(result, false);
      });

      test('cannot update built-in template', () {
        final result = service.updateTemplate(EventTemplate(
          id: 'preset_meeting',
          name: 'Hacked Meeting',
          icon: '📝',
        ));
        expect(result, false);
      });
    });

    group('removeTemplate', () {
      test('removes custom template', () {
        service.addTemplate(EventTemplate(
          id: 'custom1',
          name: 'Test',
          icon: '📝',
        ));
        expect(service.customCount, 1);

        service.removeTemplate('custom1');
        // Template should be gone
        expect(service.findById('custom1'), isNull);
      });
    });

    group('findById', () {
      test('finds built-in template', () {
        final template = service.findById('preset_meeting');
        expect(template, isNotNull);
        expect(template!.name, 'Meeting');
      });

      test('finds custom template', () {
        service.addTemplate(EventTemplate(
          id: 'custom1',
          name: 'My Custom',
          icon: '📝',
        ));
        final template = service.findById('custom1');
        expect(template, isNotNull);
        expect(template!.name, 'My Custom');
      });

      test('returns null for unknown ID', () {
        expect(service.findById('unknown'), isNull);
      });
    });

    group('search', () {
      test('returns all templates for empty query', () {
        expect(service.search(''), service.allTemplates);
      });

      test('searches by name (case-insensitive)', () {
        final results = service.search('meet');
        expect(results.any((t) => t.name == 'Meeting'), true);
      });

      test('searches by default title', () {
        final results = service.search('standup');
        expect(results.any((t) => t.name == 'Standup'), true);
      });

      test('returns empty for no matches', () {
        final results = service.search('zzzznotfound');
        expect(results, isEmpty);
      });

      test('searches custom templates too', () {
        service.addTemplate(EventTemplate(
          id: 'custom1',
          name: 'Sprint Review',
          icon: '📝',
        ));
        final results = service.search('sprint');
        expect(results.length, 1);
        expect(results[0].name, 'Sprint Review');
      });
    });

    group('clearCustomTemplates', () {
      test('removes all custom templates', () {
        service.addTemplate(EventTemplate(id: 'c1', name: 'A', icon: '📝'));
        service.addTemplate(EventTemplate(id: 'c2', name: 'B', icon: '📝'));
        service.addTemplate(EventTemplate(id: 'c3', name: 'C', icon: '📝'));

        service.clearCustomTemplates();

        expect(service.customCount, 0);
        expect(service.totalCount, 10); // Only presets
      });

      test('preserves built-in presets', () {
        service.addTemplate(EventTemplate(id: 'c1', name: 'A', icon: '📝'));
        service.clearCustomTemplates();

        expect(service.presets.length, 10);
        expect(service.findById('preset_meeting'), isNotNull);
      });
    });

    group('reorderTemplate', () {
      test('reorders custom templates', () {
        service.addTemplate(EventTemplate(id: 'c1', name: 'First', icon: '1️⃣'));
        service.addTemplate(EventTemplate(id: 'c2', name: 'Second', icon: '2️⃣'));
        service.addTemplate(EventTemplate(id: 'c3', name: 'Third', icon: '3️⃣'));

        final result = service.reorderTemplate(0, 2);
        expect(result, true);

        final custom = service.customTemplates;
        expect(custom[0].name, 'Second');
        expect(custom[1].name, 'Third');
        expect(custom[2].name, 'First');
      });

      test('rejects invalid indices', () {
        service.addTemplate(EventTemplate(id: 'c1', name: 'A', icon: '📝'));
        expect(service.reorderTemplate(-1, 0), false);
        expect(service.reorderTemplate(0, 5), false);
      });

      test('same index returns true without change', () {
        service.addTemplate(EventTemplate(id: 'c1', name: 'A', icon: '📝'));
        expect(service.reorderTemplate(0, 0), true);
      });
    });

    group('persistence', () {
      test('persists custom templates across instances', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final service1 = TemplateService(prefs);

        service1.addTemplate(EventTemplate(
          id: 'persist1',
          name: 'Persistent',
          icon: '💾',
          defaultTitle: 'Saved Event',
          defaultPriority: EventPriority.high,
        ));

        // Create new service with same prefs (simulates app restart)
        final service2 = TemplateService(prefs);

        expect(service2.customCount, 1);
        final restored = service2.findById('persist1');
        expect(restored, isNotNull);
        expect(restored!.name, 'Persistent');
        expect(restored.defaultTitle, 'Saved Event');
        expect(restored.defaultPriority, EventPriority.high);
      });

      test('clear persists', () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final service1 = TemplateService(prefs);

        service1.addTemplate(EventTemplate(id: 'c1', name: 'A', icon: '📝'));
        service1.clearCustomTemplates();

        final service2 = TemplateService(prefs);
        expect(service2.customCount, 0);
      });
    });

    group('max limit', () {
      test('maxCustomTemplates is 50', () {
        expect(TemplateService.maxCustomTemplates, 50);
      });
    });
  });
}
