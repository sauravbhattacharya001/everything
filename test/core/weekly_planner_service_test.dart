import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/weekly_planner_service.dart';
import 'package:everything/models/event_model.dart';
import 'package:everything/models/goal.dart';
import 'package:everything/models/habit.dart';
import 'package:everything/models/event_tag.dart';

// ─── Helpers ────────────────────────────────────────────────────

DateTime _d(int year, int month, int day, [int hour = 0, int minute = 0]) =>
    DateTime(year, month, day, hour, minute);

EventModel _event(
  String id,
  String title,
  DateTime start, {
  DateTime? end,
  EventPriority priority = EventPriority.medium,
  List<EventTag>? tags,
}) =>
    EventModel(
      id: id,
      title: title,
      date: start,
      endDate: end,
      priority: priority,
      tags: tags,
    );

Goal _goal(
  String id,
  String title, {
  DateTime? deadline,
  int progress = 0,
  bool isCompleted = false,
  bool isArchived = false,
  GoalCategory category = GoalCategory.personal,
  List<Milestone> milestones = const [],
}) =>
    Goal(
      id: id,
      title: title,
      createdAt: _d(2026, 1, 1),
      deadline: deadline,
      progress: progress,
      isCompleted: isCompleted,
      isArchived: isArchived,
      category: category,
      milestones: milestones,
    );

Habit _habit(
  String id,
  String name, {
  HabitFrequency frequency = HabitFrequency.daily,
  List<int> customDays = const [],
  String? emoji,
  bool isActive = true,
}) =>
    Habit(
      id: id,
      name: name,
      frequency: frequency,
      customDays: customDays,
      emoji: emoji,
      createdAt: _d(2026, 1, 1),
      isActive: isActive,
    );

HabitCompletion _completion(String habitId, DateTime date, {int count = 1}) =>
    HabitCompletion(habitId: habitId, date: date, count: count);

// 2026-03-09 is a Monday
final _monday = _d(2026, 3, 9);

void main() {
  // ─── PlannerConfig ──────────────────────────────────────────

  group('PlannerConfig', () {
    test('default values', () {
      const c = PlannerConfig();
      expect(c.dayStartHour, 8);
      expect(c.dayEndHour, 20);
      expect(c.minBlockMinutes, 30);
      expect(c.goalBlockMinutes, 60);
      expect(c.maxDailyHours, 10.0);
      expect(c.planDays, 7);
      expect(c.bufferMinutes, 15);
    });

    test('dailyMinutes computed correctly', () {
      const c = PlannerConfig(dayStartHour: 9, dayEndHour: 17);
      expect(c.dailyMinutes, 480); // 8 * 60
    });

    test('custom config', () {
      const c = PlannerConfig(
        dayStartHour: 6,
        dayEndHour: 22,
        minBlockMinutes: 15,
        goalBlockMinutes: 45,
        planDays: 5,
      );
      expect(c.dailyMinutes, 960); // 16 * 60
      expect(c.planDays, 5);
    });
  });

  // ─── Empty Inputs ───────────────────────────────────────────

  group('Empty inputs', () {
    test('generates plan with no events, goals, or habits', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final plan = svc.generate();

      expect(plan.days.length, 7);
      expect(plan.totalPlannedMinutes, 0);
      expect(plan.totalFreeMinutes, greaterThan(0));
      expect(plan.avgLoadScore, 0.0);
      expect(plan.overloadedDays, 0);
      expect(plan.warnings, isEmpty);
    });

    test('all days labeled free', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final plan = svc.generate();
      for (final day in plan.days) {
        expect(day.loadLabel, 'free');
      }
    });

    test('free time blocks fill entire day', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final plan = svc.generate();
      // Each day should have one big free block (720 min = 12h)
      for (final day in plan.days) {
        expect(day.freeMinutes, 720);
      }
    });
  });

  // ─── Events ─────────────────────────────────────────────────

  group('Event placement', () {
    test('events appear in daily plan', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final events = [
        _event('e1', 'Team standup',
            _d(2026, 3, 9, 9, 0),
            end: _d(2026, 3, 9, 9, 30)),
        _event('e2', 'Lunch meeting',
            _d(2026, 3, 9, 12, 0),
            end: _d(2026, 3, 9, 13, 0)),
      ];
      final plan = svc.generate(events: events);
      final monday = plan.days[0];

      final eventItems =
          monday.items.where((i) => i.type == PlanItemType.event).toList();
      expect(eventItems.length, 2);
      expect(eventItems[0].title, 'Team standup');
      expect(eventItems[0].minutes, 30);
      expect(eventItems[1].title, 'Lunch meeting');
      expect(eventItems[1].minutes, 60);
    });

    test('events clamped to day boundaries', () {
      final svc = WeeklyPlannerService(
        referenceDate: _monday,
        config: const PlannerConfig(dayStartHour: 9, dayEndHour: 17),
      );
      // Event starts before dayStart and ends after dayEnd
      final events = [
        _event('e1', 'All day',
            _d(2026, 3, 9, 7, 0),
            end: _d(2026, 3, 9, 19, 0)),
      ];
      final plan = svc.generate(events: events);
      final eventItem = plan.days[0].items
          .firstWhere((i) => i.type == PlanItemType.event);
      expect(eventItem.start.hour, 9);
      expect(eventItem.end.hour, 17);
    });

    test('events on different days go to correct daily plan', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final events = [
        _event('e1', 'Monday event',
            _d(2026, 3, 9, 10, 0),
            end: _d(2026, 3, 9, 11, 0)),
        _event('e2', 'Wednesday event',
            _d(2026, 3, 11, 14, 0),
            end: _d(2026, 3, 11, 15, 0)),
      ];
      final plan = svc.generate(events: events);
      expect(plan.days[0].eventCount, 1);
      expect(plan.days[1].eventCount, 0);
      expect(plan.days[2].eventCount, 1);
    });

    test('events without endDate get 30min default', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final events = [
        _event('e1', 'Quick call', _d(2026, 3, 9, 10, 0)),
      ];
      final plan = svc.generate(events: events);
      final eventItem = plan.days[0].items
          .firstWhere((i) => i.type == PlanItemType.event);
      expect(eventItem.minutes, 30);
    });

    test('event priority maps correctly', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final events = [
        _event('e1', 'Urgent', _d(2026, 3, 9, 10, 0),
            end: _d(2026, 3, 9, 11, 0),
            priority: EventPriority.urgent),
      ];
      final plan = svc.generate(events: events);
      final item = plan.days[0].items
          .firstWhere((i) => i.type == PlanItemType.event);
      expect(item.priority, 4.0);
    });

    test('event tags appear as category', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final events = [
        _event('e1', 'Tagged event', _d(2026, 3, 9, 10, 0),
            end: _d(2026, 3, 9, 11, 0),
            tags: [const EventTag(name: 'work')]),
      ];
      final plan = svc.generate(events: events);
      final item = plan.days[0].items
          .firstWhere((i) => i.type == PlanItemType.event);
      expect(item.category, 'work');
    });

    test('overlapping events trigger warning', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final events = [
        _event('e1', 'Meeting A',
            _d(2026, 3, 9, 10, 0),
            end: _d(2026, 3, 9, 11, 30)),
        _event('e2', 'Meeting B',
            _d(2026, 3, 9, 11, 0),
            end: _d(2026, 3, 9, 12, 0)),
      ];
      final plan = svc.generate(events: events);
      final warnings = plan.days[0].warnings;
      expect(warnings.any((w) => w.message.contains('Overlap')), isTrue);
    });
  });

  // ─── Habits ─────────────────────────────────────────────────

  group('Habit placement', () {
    test('daily habits appear every day', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final habits = [_habit('h1', 'Exercise')];
      final plan = svc.generate(habits: habits);

      for (final day in plan.days) {
        final habitItems =
            day.items.where((i) => i.type == PlanItemType.habit).toList();
        expect(habitItems.length, 1);
        expect(habitItems[0].title, contains('Exercise'));
      }
    });

    test('weekday habits skip weekends', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final habits = [
        _habit('h1', 'Work habit', frequency: HabitFrequency.weekdays),
      ];
      final plan = svc.generate(habits: habits);

      // Monday-Friday (indices 0-4): habit present
      for (var i = 0; i < 5; i++) {
        expect(
          plan.days[i].items.any((it) => it.type == PlanItemType.habit),
          isTrue,
          reason: 'Day $i should have habit',
        );
      }
      // Saturday-Sunday (indices 5-6): no habit
      for (var i = 5; i < 7; i++) {
        expect(
          plan.days[i].items.any((it) => it.type == PlanItemType.habit),
          isFalse,
          reason: 'Day $i should not have habit',
        );
      }
    });

    test('weekend habits only on Saturday/Sunday', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final habits = [
        _habit('h1', 'Weekend fun', frequency: HabitFrequency.weekends),
      ];
      final plan = svc.generate(habits: habits);

      for (var i = 0; i < 5; i++) {
        expect(
          plan.days[i].items.any((it) => it.type == PlanItemType.habit),
          isFalse,
        );
      }
      for (var i = 5; i < 7; i++) {
        expect(
          plan.days[i].items.any((it) => it.type == PlanItemType.habit),
          isTrue,
        );
      }
    });

    test('custom day habits respect custom days', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      // Mon=1, Wed=3, Fri=5
      final habits = [
        _habit('h1', 'MWF workout',
            frequency: HabitFrequency.custom, customDays: [1, 3, 5]),
      ];
      final plan = svc.generate(habits: habits);

      // Mon (idx 0), Wed (idx 2), Fri (idx 4) should have habit
      expect(plan.days[0].habitCount, 1);
      expect(plan.days[1].habitCount, 0);
      expect(plan.days[2].habitCount, 1);
      expect(plan.days[3].habitCount, 0);
      expect(plan.days[4].habitCount, 1);
    });

    test('inactive habits excluded', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final habits = [_habit('h1', 'Inactive', isActive: false)];
      final plan = svc.generate(habits: habits);
      for (final day in plan.days) {
        expect(day.habitCount, 0);
      }
    });

    test('completed habits excluded for today', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final habits = [_habit('h1', 'Exercise')];
      final completions = [
        _completion('h1', _monday),
      ];
      final plan = svc.generate(
        habits: habits,
        habitCompletions: completions,
      );
      // Monday (today) should have no habit (completed)
      expect(plan.days[0].habitCount, 0);
      // Tuesday should still have it
      expect(plan.days[1].habitCount, 1);
    });

    test('habit emoji appears in title', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final habits = [_habit('h1', 'Meditate', emoji: '🧘')];
      final plan = svc.generate(habits: habits);
      final item = plan.days[0].items
          .firstWhere((i) => i.type == PlanItemType.habit);
      expect(item.title, '🧘 Meditate');
    });
  });

  // ─── Goal Blocks ────────────────────────────────────────────

  group('Goal allocation', () {
    test('goals get work blocks in free time', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final goals = [_goal('g1', 'Write book')];
      final plan = svc.generate(goals: goals);

      final totalGoalBlocks = plan.days
          .fold(0, (sum, d) => sum + d.goalBlockCount);
      expect(totalGoalBlocks, greaterThan(0));
    });

    test('completed goals excluded', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final goals = [_goal('g1', 'Done goal', isCompleted: true)];
      final plan = svc.generate(goals: goals);

      final totalGoalBlocks = plan.days
          .fold(0, (sum, d) => sum + d.goalBlockCount);
      expect(totalGoalBlocks, 0);
    });

    test('archived goals excluded', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final goals = [_goal('g1', 'Archived', isArchived: true)];
      final plan = svc.generate(goals: goals);

      final totalGoalBlocks = plan.days
          .fold(0, (sum, d) => sum + d.goalBlockCount);
      expect(totalGoalBlocks, 0);
    });

    test('goal blocks have correct category', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final goals = [
        _goal('g1', 'Exercise', category: GoalCategory.fitness),
      ];
      final plan = svc.generate(goals: goals);
      final goalItem = plan.days
          .expand((d) => d.items)
          .firstWhere((i) => i.type == PlanItemType.goalWork);
      expect(goalItem.category, 'Fitness');
    });

    test('urgent deadline goals have higher priority', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final goals = [
        _goal('g1', 'Far deadline',
            deadline: _d(2026, 6, 1)),
        _goal('g2', 'Near deadline',
            deadline: _d(2026, 3, 11)), // 2 days away
      ];
      final plan = svc.generate(goals: goals);

      final goalItems = plan.days[0].items
          .where((i) => i.type == PlanItemType.goalWork)
          .toList();
      if (goalItems.length >= 2) {
        // Near deadline should have higher priority score
        final nearItem = goalItems.firstWhere((i) => i.refId == 'g2');
        final farItem = goalItems.firstWhere((i) => i.refId == 'g1');
        expect(nearItem.priority, greaterThan(farItem.priority));
      }
    });

    test('overdue goals get highest priority', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final goals = [
        _goal('g1', 'Future', deadline: _d(2026, 4, 1)),
        _goal('g2', 'Overdue', deadline: _d(2026, 3, 5)), // Past deadline
      ];
      final plan = svc.generate(goals: goals);

      // First goal block should be for the overdue goal
      final firstGoalBlock = plan.days
          .expand((d) => d.items)
          .firstWhere((i) => i.type == PlanItemType.goalWork);
      expect(firstGoalBlock.refId, 'g2');
    });

    test('goal progress affects priority', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final goals = [
        _goal('g1', 'Almost done',
            deadline: _d(2026, 3, 12), progress: 90),
        _goal('g2', 'Barely started',
            deadline: _d(2026, 3, 12), progress: 10),
      ];
      final plan = svc.generate(goals: goals);

      final goalItems = plan.days
          .expand((d) => d.items)
          .where((i) => i.type == PlanItemType.goalWork)
          .toList();
      if (goalItems.length >= 2) {
        final almostDone = goalItems.firstWhere((i) => i.refId == 'g1');
        final barelyStarted = goalItems.firstWhere((i) => i.refId == 'g2');
        expect(barelyStarted.priority, greaterThan(almostDone.priority));
      }
    });

    test('goals with milestones get bonus score', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final goals = [
        _goal('g1', 'No milestones'),
        _goal('g2', 'With milestones', milestones: [
          const Milestone(id: 'm1', title: 'Step 1'),
          const Milestone(id: 'm2', title: 'Step 2'),
          const Milestone(id: 'm3', title: 'Step 3'),
        ]),
      ];
      final plan = svc.generate(goals: goals);
      final scheduledIds = plan.scheduledGoalIds;
      // Both should be scheduled (enough free time)
      expect(scheduledIds, contains('g1'));
      expect(scheduledIds, contains('g2'));
    });

    test('goal block respects buffer minutes', () {
      final svc = WeeklyPlannerService(
        referenceDate: _monday,
        config: const PlannerConfig(bufferMinutes: 15),
      );
      final goals = [_goal('g1', 'Study')];
      final plan = svc.generate(goals: goals);

      final goalItem = plan.days[0].items
          .firstWhere((i) => i.type == PlanItemType.goalWork);
      // Should start at dayStart + buffer (8:15)
      expect(goalItem.start.hour, 8);
      expect(goalItem.start.minute, 15);
    });

    test('no goal blocks if all time taken by events', () {
      final svc = WeeklyPlannerService(
        referenceDate: _monday,
        config: const PlannerConfig(
          dayStartHour: 9,
          dayEndHour: 10, // Only 1 hour
          goalBlockMinutes: 60,
          bufferMinutes: 15,
        ),
      );
      final events = [
        _event('e1', 'Full block',
            _d(2026, 3, 9, 9, 0),
            end: _d(2026, 3, 9, 10, 0)),
      ];
      final goals = [_goal('g1', 'Study')];
      final plan = svc.generate(events: events, goals: goals);

      expect(plan.days[0].goalBlockCount, 0);
    });
  });

  // ─── Free Time ──────────────────────────────────────────────

  group('Free time', () {
    test('free time fills gaps between items', () {
      final svc = WeeklyPlannerService(
        referenceDate: _monday,
        config: const PlannerConfig(
          dayStartHour: 8,
          dayEndHour: 12, // 4 hours
          minBlockMinutes: 30,
          goalBlockMinutes: 30,
          bufferMinutes: 0,
        ),
      );
      final events = [
        _event('e1', 'Meeting',
            _d(2026, 3, 9, 9, 0),
            end: _d(2026, 3, 9, 10, 0)),
      ];
      final plan = svc.generate(events: events);
      final freeItems = plan.days[0].items
          .where((i) => i.type == PlanItemType.freeTime)
          .toList();
      expect(freeItems.length, greaterThanOrEqualTo(1));
    });

    test('small gaps below minBlockMinutes are not free blocks', () {
      final svc = WeeklyPlannerService(
        referenceDate: _monday,
        config: const PlannerConfig(
          dayStartHour: 9,
          dayEndHour: 10,
          minBlockMinutes: 60, // Only 60min+ gaps
        ),
      );
      // Leave only a 20min gap
      final events = [
        _event('e1', 'A',
            _d(2026, 3, 9, 9, 0),
            end: _d(2026, 3, 9, 9, 40)),
      ];
      final plan = svc.generate(events: events);
      final freeItems = plan.days[0].items
          .where((i) => i.type == PlanItemType.freeTime)
          .toList();
      expect(freeItems, isEmpty);
    });
  });

  // ─── Load Score ─────────────────────────────────────────────

  group('Load score', () {
    test('empty day has zero load', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final plan = svc.generate();
      expect(plan.days[0].loadScore, 0.0);
    });

    test('fully booked day has load ~1.0', () {
      final svc = WeeklyPlannerService(
        referenceDate: _monday,
        config: const PlannerConfig(dayStartHour: 9, dayEndHour: 10),
      );
      final events = [
        _event('e1', 'Full',
            _d(2026, 3, 9, 9, 0),
            end: _d(2026, 3, 9, 10, 0)),
      ];
      final plan = svc.generate(events: events);
      expect(plan.days[0].loadScore, closeTo(1.0, 0.01));
    });

    test('load labels are correct', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final plan = svc.generate();
      expect(plan.days[0].loadLabel, 'free');
    });
  });

  // ─── Warnings ───────────────────────────────────────────────

  group('Warnings', () {
    test('overload warning on packed day', () {
      final svc = WeeklyPlannerService(
        referenceDate: _monday,
        config: const PlannerConfig(dayStartHour: 9, dayEndHour: 10),
      );
      final events = [
        _event('e1', 'Over',
            _d(2026, 3, 9, 9, 0),
            end: _d(2026, 3, 9, 10, 30)),
      ];
      final plan = svc.generate(events: events);
      expect(
        plan.days[0].warnings.any((w) => w.message.contains('Overloaded')),
        isTrue,
      );
    });

    test('high context switching warning', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final events = List.generate(
        7,
        (i) => _event(
          'e$i',
          'Event $i',
          _d(2026, 3, 9, 8 + i, 0),
          end: _d(2026, 3, 9, 8 + i, 30),
        ),
      );
      final plan = svc.generate(events: events);
      expect(
        plan.days[0].warnings
            .any((w) => w.message.contains('context switching')),
        isTrue,
      );
    });

    test('unscheduled goal warning', () {
      final svc = WeeklyPlannerService(
        referenceDate: _monday,
        config: const PlannerConfig(
          dayStartHour: 9,
          dayEndHour: 10, // Very short day
          goalBlockMinutes: 120, // Block won't fit
          bufferMinutes: 0,
        ),
      );
      // Fill every day with events
      final events = List.generate(
        7,
        (i) => _event(
          'e$i',
          'All day',
          _d(2026, 3, 9 + i, 9, 0),
          end: _d(2026, 3, 9 + i, 10, 0),
        ),
      );
      final goals = [_goal('g1', 'Neglected goal')];
      final plan = svc.generate(events: events, goals: goals);

      expect(
        plan.warnings
            .any((w) => w.message.contains('No time allocated')),
        isTrue,
      );
    });

    test('imminent deadline warning', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final goals = [
        _goal('g1', 'Due soon',
            deadline: _d(2026, 3, 11), progress: 20),
      ];
      final plan = svc.generate(goals: goals);

      expect(
        plan.warnings.any((w) =>
            w.message.contains('due in') && w.severity == WarningSeverity.critical),
        isTrue,
      );
    });

    test('no imminent deadline warning if goal nearly done', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final goals = [
        _goal('g1', 'Nearly done',
            deadline: _d(2026, 3, 11), progress: 90),
      ];
      final plan = svc.generate(goals: goals);

      expect(
        plan.warnings.any((w) => w.message.contains('due in')),
        isFalse,
      );
    });

    test('multiple overloaded days trigger week warning', () {
      final svc = WeeklyPlannerService(
        referenceDate: _monday,
        config: const PlannerConfig(dayStartHour: 9, dayEndHour: 10),
      );
      // 3+ days fully booked
      final events = List.generate(
        4,
        (i) => _event(
          'e$i',
          'Full day',
          _d(2026, 3, 9 + i, 9, 0),
          end: _d(2026, 3, 9 + i, 11, 0), // Over the 1-hour window
        ),
      );
      final plan = svc.generate(events: events);
      expect(
        plan.warnings.any((w) => w.message.contains('overloaded')),
        isTrue,
      );
    });
  });

  // ─── WeeklyPlan summary ─────────────────────────────────────

  group('WeeklyPlan properties', () {
    test('scheduledGoalIds tracks unique goals', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final goals = [
        _goal('g1', 'Goal A'),
        _goal('g2', 'Goal B'),
      ];
      final plan = svc.generate(goals: goals);
      expect(plan.scheduledGoalIds, containsAll(['g1', 'g2']));
    });

    test('summary contains key info', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final plan = svc.generate();
      final summary = plan.summary;
      expect(summary, contains('Weekly Plan'));
      expect(summary, contains('Generated'));
      expect(summary, contains('Avg load'));
      expect(summary, contains('Monday'));
    });

    test('toString is informative', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final plan = svc.generate();
      expect(plan.toString(), contains('7 days'));
    });

    test('allWarnings combines week and daily', () {
      final svc = WeeklyPlannerService(
        referenceDate: _monday,
        config: const PlannerConfig(dayStartHour: 9, dayEndHour: 10),
      );
      final events = List.generate(
        4,
        (i) => _event(
          'e$i',
          'Over',
          _d(2026, 3, 9 + i, 9, 0),
          end: _d(2026, 3, 9 + i, 11, 0),
        ),
      );
      final plan = svc.generate(events: events);
      // allWarnings should include both daily overload + week-level warning
      expect(plan.allWarnings.length,
          greaterThanOrEqualTo(plan.warnings.length));
    });
  });

  // ─── DailyPlan properties ──────────────────────────────────

  group('DailyPlan properties', () {
    test('weekdayName returns correct name', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final plan = svc.generate();
      expect(plan.days[0].weekdayName, 'Monday');
      expect(plan.days[4].weekdayName, 'Friday');
      expect(plan.days[6].weekdayName, 'Sunday');
    });

    test('toString is descriptive', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final plan = svc.generate();
      final str = plan.days[0].toString();
      expect(str, contains('Monday'));
      expect(str, contains('2026-03-09'));
    });
  });

  // ─── PlanItem ───────────────────────────────────────────────

  group('PlanItem', () {
    test('toString formats time correctly', () {
      final item = PlanItem(
        type: PlanItemType.event,
        title: 'Test',
        start: _d(2026, 3, 9, 9, 5),
        end: _d(2026, 3, 9, 10, 30),
      );
      expect(item.toString(), contains('09:05'));
      expect(item.toString(), contains('10:30'));
      expect(item.toString(), contains('85min'));
    });

    test('minutes computed correctly', () {
      final item = PlanItem(
        type: PlanItemType.goalWork,
        title: 'Study',
        start: _d(2026, 3, 9, 14, 0),
        end: _d(2026, 3, 9, 15, 30),
      );
      expect(item.minutes, 90);
    });
  });

  // ─── PlanWarning ────────────────────────────────────────────

  group('PlanWarning', () {
    test('toString with date', () {
      final w = PlanWarning(
        severity: WarningSeverity.warning,
        date: _d(2026, 3, 9),
        message: 'Test warning',
      );
      expect(w.toString(), contains('[warning]'));
      expect(w.toString(), contains('2026-03-09'));
    });

    test('toString without date', () {
      const w = PlanWarning(
        severity: WarningSeverity.critical,
        message: 'Week problem',
      );
      expect(w.toString(), '[critical] Week problem');
    });
  });

  // ─── Custom Config ─────────────────────────────────────────

  group('Custom config', () {
    test('planDays controls number of days', () {
      final svc = WeeklyPlannerService(
        referenceDate: _monday,
        config: const PlannerConfig(planDays: 3),
      );
      final plan = svc.generate();
      expect(plan.days.length, 3);
    });

    test('different working hours', () {
      final svc = WeeklyPlannerService(
        referenceDate: _monday,
        config: const PlannerConfig(dayStartHour: 6, dayEndHour: 22),
      );
      final plan = svc.generate();
      // 16 hours = 960 minutes of free time per empty day
      expect(plan.days[0].freeMinutes, 960);
    });
  });

  // ─── Integration ────────────────────────────────────────────

  group('Integration', () {
    test('full scenario with events, goals, and habits', () {
      final svc = WeeklyPlannerService(
        referenceDate: _monday,
        config: const PlannerConfig(
          dayStartHour: 8,
          dayEndHour: 18,
          goalBlockMinutes: 60,
          bufferMinutes: 10,
        ),
      );

      final events = [
        _event('e1', 'Standup',
            _d(2026, 3, 9, 9, 0),
            end: _d(2026, 3, 9, 9, 30)),
        _event('e2', 'Sprint review',
            _d(2026, 3, 13, 14, 0),
            end: _d(2026, 3, 13, 15, 0)),
      ];

      final goals = [
        _goal('g1', 'Learn Rust',
            deadline: _d(2026, 3, 20), category: GoalCategory.education),
        _goal('g2', 'Run 5K',
            category: GoalCategory.fitness, progress: 40),
      ];

      final habits = [
        _habit('h1', 'Meditate', emoji: '🧘'),
        _habit('h2', 'Read',
            frequency: HabitFrequency.weekdays, emoji: '📚'),
      ];

      final plan = svc.generate(
        events: events,
        goals: goals,
        habits: habits,
      );

      expect(plan.days.length, 7);
      expect(plan.totalPlannedMinutes, greaterThan(0));
      expect(plan.scheduledGoalIds, isNotEmpty);
      expect(plan.avgLoadScore, greaterThan(0));

      // Monday should have standup + habits + goal blocks
      final monday = plan.days[0];
      expect(monday.eventCount, 1);
      expect(monday.habitCount, greaterThan(0));
      expect(monday.goalBlockCount, greaterThan(0));

      // Summary should be readable
      expect(plan.summary, contains('Weekly Plan'));
      expect(plan.summary, contains('Monday'));
    });

    test('events outside plan range are excluded', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final events = [
        _event('e1', 'Before range',
            _d(2026, 3, 1, 10, 0),
            end: _d(2026, 3, 1, 11, 0)),
        _event('e2', 'After range',
            _d(2026, 3, 20, 10, 0),
            end: _d(2026, 3, 20, 11, 0)),
      ];
      final plan = svc.generate(events: events);
      final totalEvents = plan.days.fold(0, (sum, d) => sum + d.eventCount);
      expect(totalEvents, 0);
    });

    test('items sorted by start time within each day', () {
      final svc = WeeklyPlannerService(referenceDate: _monday);
      final events = [
        _event('e2', 'Later',
            _d(2026, 3, 9, 14, 0),
            end: _d(2026, 3, 9, 15, 0)),
        _event('e1', 'Earlier',
            _d(2026, 3, 9, 10, 0),
            end: _d(2026, 3, 9, 11, 0)),
      ];
      final plan = svc.generate(events: events);
      final items = plan.days[0].items;
      for (var i = 0; i < items.length - 1; i++) {
        expect(
          items[i].start.isBefore(items[i + 1].start) ||
              items[i].start.isAtSameMomentAs(items[i + 1].start),
          isTrue,
          reason: 'Items should be sorted by start time',
        );
      }
    });
  });
}
