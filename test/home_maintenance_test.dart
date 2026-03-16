import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/home_maintenance_service.dart';
import 'package:everything/models/home_maintenance_entry.dart';

void main() {
  late HomeMaintenanceService service;

  HomeMaintenanceEntry _task({
    String id = 't1',
    String name = 'Test Task',
    MaintenanceCategory category = MaintenanceCategory.hvac,
    MaintenancePriority priority = MaintenancePriority.medium,
    RecurrenceInterval recurrence = RecurrenceInterval.monthly,
    int recurrenceDays = 30,
    DateTime? nextDueDate,
    List<MaintenanceCompletion>? completions,
    String? location,
    double? estimatedCost,
  }) {
    return HomeMaintenanceEntry(
      id: id,
      name: name,
      category: category,
      priority: priority,
      recurrence: recurrence,
      recurrenceDays: recurrenceDays,
      nextDueDate: nextDueDate ?? DateTime.now().add(const Duration(days: 30)),
      completions: completions ?? [],
      location: location,
      estimatedCost: estimatedCost,
    );
  }

  setUp(() {
    service = HomeMaintenanceService();
  });

  group('CRUD', () {
    test('add and list tasks', () {
      service.addTask(_task(id: 't1'));
      service.addTask(_task(id: 't2', name: 'Task 2'));
      expect(service.tasks.length, 2);
    });

    test('update task', () {
      service.addTask(_task(id: 't1', name: 'Old'));
      service.updateTask('t1', _task(id: 't1', name: 'New'));
      expect(service.tasks.first.name, 'New');
    });

    test('remove task', () {
      service.addTask(_task(id: 't1'));
      service.removeTask('t1');
      expect(service.tasks, isEmpty);
    });

    test('tasks list is unmodifiable', () {
      service.addTask(_task());
      expect(() => service.tasks.add(_task(id: 'x')), throwsA(anything));
    });
  });

  group('Status', () {
    test('overdue task', () {
      final t = _task(nextDueDate: DateTime.now().subtract(const Duration(days: 5)));
      expect(t.status, MaintenanceStatus.overdue);
      expect(t.daysUntilDue, lessThan(0));
    });

    test('due soon task (within 7 days)', () {
      final t = _task(nextDueDate: DateTime.now().add(const Duration(days: 3)));
      expect(t.status, MaintenanceStatus.dueSoon);
    });

    test('upcoming task (within 30 days)', () {
      final t = _task(nextDueDate: DateTime.now().add(const Duration(days: 15)));
      expect(t.status, MaintenanceStatus.upcoming);
    });

    test('on track task (> 30 days)', () {
      final t = _task(nextDueDate: DateTime.now().add(const Duration(days: 60)));
      expect(t.status, MaintenanceStatus.onTrack);
    });
  });

  group('Filtering', () {
    test('by category', () {
      service.addTask(_task(id: 't1', category: MaintenanceCategory.hvac));
      service.addTask(_task(id: 't2', category: MaintenanceCategory.plumbing));
      expect(service.byCategory(MaintenanceCategory.hvac).length, 1);
    });

    test('by priority', () {
      service.addTask(_task(id: 't1', priority: MaintenancePriority.urgent));
      service.addTask(_task(id: 't2', priority: MaintenancePriority.low));
      expect(service.byPriority(MaintenancePriority.urgent).length, 1);
    });

    test('by location', () {
      service.addTask(_task(id: 't1', location: 'Kitchen'));
      service.addTask(_task(id: 't2', location: 'Garage'));
      expect(service.byLocation('kitchen').length, 1);
    });

    test('search by name', () {
      service.addTask(_task(id: 't1', name: 'Replace HVAC Filter'));
      service.addTask(_task(id: 't2', name: 'Clean Gutters'));
      expect(service.search('hvac').length, 1);
    });

    test('search by location', () {
      service.addTask(_task(id: 't1', location: 'Basement'));
      expect(service.search('base').length, 1);
    });
  });

  group('Alerts', () {
    test('overdue tasks appear in alerts', () {
      service.addTask(_task(id: 't1',
          nextDueDate: DateTime.now().subtract(const Duration(days: 3))));
      service.addTask(_task(id: 't2',
          nextDueDate: DateTime.now().add(const Duration(days: 60))));
      expect(service.alertTasks.length, 1);
    });

    test('due soon tasks appear in alerts', () {
      service.addTask(_task(id: 't1',
          nextDueDate: DateTime.now().add(const Duration(days: 5))));
      expect(service.alertTasks.length, 1);
    });

    test('sorted by urgency', () {
      service.addTask(_task(id: 't1',
          nextDueDate: DateTime.now().add(const Duration(days: 60))));
      service.addTask(_task(id: 't2',
          nextDueDate: DateTime.now().subtract(const Duration(days: 2))));
      final sorted = service.sortedByUrgency;
      expect(sorted.first.id, 't2');
    });
  });

  group('Completion', () {
    test('complete task advances due date', () {
      service.addTask(_task(id: 't1', recurrenceDays: 30,
          nextDueDate: DateTime.now()));
      service.completeTask('t1', cost: 50, vendor: 'Bob');
      final t = service.tasks.first;
      expect(t.completions.length, 1);
      expect(t.daysUntilDue, greaterThanOrEqualTo(29));
    });

    test('completion records cost and vendor', () {
      service.addTask(_task(id: 't1'));
      service.completeTask('t1', cost: 100, vendor: 'Plumber Joe', notes: 'Fixed leak');
      final c = service.tasks.first.completions.first;
      expect(c.cost, 100);
      expect(c.vendor, 'Plumber Joe');
      expect(c.notes, 'Fixed leak');
    });

    test('total spent across completions', () {
      final t = _task(completions: [
        MaintenanceCompletion(completedDate: DateTime.now(), cost: 50),
        MaintenanceCompletion(completedDate: DateTime.now(), cost: 30),
      ]);
      expect(t.totalSpent, 80);
    });

    test('average cost', () {
      final t = _task(completions: [
        MaintenanceCompletion(completedDate: DateTime.now(), cost: 100),
        MaintenanceCompletion(completedDate: DateTime.now(), cost: 200),
      ]);
      expect(t.averageCost, 150);
    });

    test('never completed tasks', () {
      service.addTask(_task(id: 't1'));
      service.addTask(_task(id: 't2', completions: [
        MaintenanceCompletion(completedDate: DateTime.now()),
      ]));
      expect(service.neverCompleted.length, 1);
    });
  });

  group('Analytics', () {
    test('spending by category', () {
      service.addTask(_task(id: 't1', category: MaintenanceCategory.hvac,
          completions: [MaintenanceCompletion(completedDate: DateTime.now(), cost: 50)]));
      service.addTask(_task(id: 't2', category: MaintenanceCategory.plumbing,
          completions: [MaintenanceCompletion(completedDate: DateTime.now(), cost: 200)]));
      final spending = service.spendingByCategory;
      expect(spending[MaintenanceCategory.hvac], 50);
      expect(spending[MaintenanceCategory.plumbing], 200);
    });

    test('count by status', () {
      service.addTask(_task(id: 't1',
          nextDueDate: DateTime.now().subtract(const Duration(days: 5))));
      service.addTask(_task(id: 't2',
          nextDueDate: DateTime.now().add(const Duration(days: 60))));
      final counts = service.countByStatus;
      expect(counts[MaintenanceStatus.overdue], 1);
      expect(counts[MaintenanceStatus.onTrack], 1);
    });

    test('completion rate', () {
      service.addTask(_task(id: 't1', completions: [
        MaintenanceCompletion(completedDate: DateTime.now()),
      ]));
      service.addTask(_task(id: 't2'));
      expect(service.completionRate, 0.5);
    });

    test('total spent across service', () {
      service.addTask(_task(id: 't1', completions: [
        MaintenanceCompletion(completedDate: DateTime.now(), cost: 100),
      ]));
      service.addTask(_task(id: 't2', completions: [
        MaintenanceCompletion(completedDate: DateTime.now(), cost: 50),
      ]));
      expect(service.totalSpent, 150);
    });

    test('locations list', () {
      service.addTask(_task(id: 't1', location: 'Kitchen'));
      service.addTask(_task(id: 't2', location: 'Garage'));
      service.addTask(_task(id: 't3', location: 'Kitchen'));
      expect(service.locations, ['Garage', 'Kitchen']);
    });

    test('upcoming tasks within N days', () {
      service.addTask(_task(id: 't1',
          nextDueDate: DateTime.now().add(const Duration(days: 10))));
      service.addTask(_task(id: 't2',
          nextDueDate: DateTime.now().add(const Duration(days: 60))));
      expect(service.upcomingTasks(days: 30).length, 1);
    });
  });

  group('Serialization', () {
    test('export and import JSON', () {
      service.addTask(_task(id: 't1', name: 'Filter', location: 'Basement',
          completions: [MaintenanceCompletion(completedDate: DateTime.now(), cost: 25)]));
      final json = service.exportToJson();
      final service2 = HomeMaintenanceService();
      service2.importFromJson(json);
      expect(service2.tasks.length, 1);
      expect(service2.tasks.first.name, 'Filter');
      expect(service2.tasks.first.location, 'Basement');
      expect(service2.tasks.first.completions.length, 1);
    });

    test('model toJson/fromJson roundtrip', () {
      final original = _task(
        id: 'x1',
        name: 'Test',
        category: MaintenanceCategory.safety,
        priority: MaintenancePriority.urgent,
        location: 'Hall',
        estimatedCost: 99.50,
        completions: [
          MaintenanceCompletion(
            completedDate: DateTime(2026, 1, 15),
            cost: 50,
            vendor: 'Bob',
            notes: 'Done',
          ),
        ],
      );
      final json = original.toJson();
      final restored = HomeMaintenanceEntry.fromJson(json);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.category, original.category);
      expect(restored.priority, original.priority);
      expect(restored.location, original.location);
      expect(restored.estimatedCost, original.estimatedCost);
      expect(restored.completions.length, 1);
      expect(restored.completions.first.vendor, 'Bob');
    });
  });

  group('Enums', () {
    test('category labels and emojis', () {
      for (final c in MaintenanceCategory.values) {
        expect(c.label.isNotEmpty, true);
        expect(c.emoji.isNotEmpty, true);
      }
    });

    test('priority labels and emojis', () {
      for (final p in MaintenancePriority.values) {
        expect(p.label.isNotEmpty, true);
        expect(p.emoji.isNotEmpty, true);
      }
    });

    test('recurrence default days', () {
      expect(RecurrenceInterval.weekly.defaultDays, 7);
      expect(RecurrenceInterval.quarterly.defaultDays, 90);
      expect(RecurrenceInterval.annually.defaultDays, 365);
    });

    test('status labels and emojis', () {
      for (final s in MaintenanceStatus.values) {
        expect(s.label.isNotEmpty, true);
        expect(s.emoji.isNotEmpty, true);
      }
    });
  });
}
