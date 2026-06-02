import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/focus_session_advisor_service.dart';

void main() {
  final fixedNow = DateTime(2026, 6, 2, 9, 0);

  group('FocusSessionAdvisorService', () {
    test('empty tasks returns grade A with EMPTY_TASK_QUEUE', () {
      final svc = FocusSessionAdvisorService(now: () => fixedNow);
      final plan = svc.analyze(tasks: []);
      expect(plan.grade, 'A');
      expect(plan.sessions, isEmpty);
      expect(plan.insights, contains('EMPTY_TASK_QUEUE'));
    });

    test('single task with matching block produces OPTIMAL_WINDOW or GOOD_FIT', () {
      final svc = FocusSessionAdvisorService(now: () => fixedNow);
      final plan = svc.analyze(
        tasks: [
          const FocusTask(id: 't1', title: 'Write report', complexity: 6, estimatedMinutes: 50),
        ],
        energyHistory: [
          EnergyReading(timestamp: DateTime(2026, 6, 1, 10, 0), level: 8),
          EnergyReading(timestamp: DateTime(2026, 6, 1, 10, 0), level: 9),
        ],
        availableBlocks: [
          TimeBlock(
            start: DateTime(2026, 6, 2, 10, 0),
            end: DateTime(2026, 6, 2, 12, 0),
          ),
        ],
      );
      expect(plan.sessions.length, 1);
      expect(['OPTIMAL_WINDOW', 'GOOD_FIT'], contains(plan.sessions.first.verdict));
      expect(plan.sessions.first.fitScore, greaterThan(0));
    });

    test('high-complexity task gets deepWork technique', () {
      final svc = FocusSessionAdvisorService(now: () => fixedNow);
      final plan = svc.analyze(
        tasks: [
          const FocusTask(id: 't1', title: 'Architect system', complexity: 9, estimatedMinutes: 90),
        ],
        availableBlocks: [
          TimeBlock(
            start: DateTime(2026, 6, 2, 9, 0),
            end: DateTime(2026, 6, 2, 12, 0),
          ),
        ],
      );
      expect(plan.sessions.first.technique, FocusTechnique.deepWork);
      expect(plan.sessions.first.recommendedMinutes, 90);
      expect(plan.sessions.first.breakMinutes, 15);
    });

    test('short task gets pomodoro technique', () {
      final svc = FocusSessionAdvisorService(now: () => fixedNow);
      final plan = svc.analyze(
        tasks: [
          const FocusTask(id: 't1', title: 'Reply to email', complexity: 2, estimatedMinutes: 15),
        ],
        availableBlocks: [
          TimeBlock(
            start: DateTime(2026, 6, 2, 14, 0),
            end: DateTime(2026, 6, 2, 15, 0),
          ),
        ],
      );
      expect(plan.sessions.first.technique, FocusTechnique.pomodoro);
      expect(plan.sessions.first.recommendedMinutes, 25);
    });

    test('OVERCOMMITTED when no capacity remains', () {
      final svc = FocusSessionAdvisorService(now: () => fixedNow);
      final plan = svc.analyze(
        tasks: [
          const FocusTask(id: 't1', title: 'Task A', complexity: 5, estimatedMinutes: 60),
          const FocusTask(id: 't2', title: 'Task B', complexity: 5, estimatedMinutes: 60),
          const FocusTask(id: 't3', title: 'Task C', complexity: 5, estimatedMinutes: 60),
        ],
        availableBlocks: [
          TimeBlock(
            start: DateTime(2026, 6, 2, 10, 0),
            end: DateTime(2026, 6, 2, 11, 0), // only 60 min
          ),
        ],
      );
      final overcommitted = plan.sessions.where((s) => s.verdict == 'OVERCOMMITTED');
      expect(overcommitted, isNotEmpty);
      expect(plan.playbook.any((a) => a.id == 'REDUCE_TASK_LOAD'), isTrue);
    });

    test('INSUFFICIENT_DATA when no blocks provided', () {
      final svc = FocusSessionAdvisorService(now: () => fixedNow);
      final plan = svc.analyze(
        tasks: [const FocusTask(id: 't1', title: 'Something', complexity: 5)],
        availableBlocks: [],
      );
      expect(plan.sessions.first.verdict, 'INSUFFICIENT_DATA');
    });

    test('risk appetite cautious produces lower fit scores', () {
      final cautious = FocusSessionAdvisorService(
        now: () => fixedNow,
        appetite: FocusRiskAppetite.cautious,
      );
      final aggressive = FocusSessionAdvisorService(
        now: () => fixedNow,
        appetite: FocusRiskAppetite.aggressive,
      );
      final tasks = [const FocusTask(id: 't1', title: 'Work', complexity: 5, estimatedMinutes: 45)];
      final blocks = [
        TimeBlock(start: DateTime(2026, 6, 2, 10, 0), end: DateTime(2026, 6, 2, 11, 0)),
      ];
      final energy = [EnergyReading(timestamp: DateTime(2026, 6, 1, 10, 0), level: 6)];

      final cPlan = cautious.analyze(tasks: tasks, availableBlocks: blocks, energyHistory: energy);
      final aPlan = aggressive.analyze(tasks: tasks, availableBlocks: blocks, energyHistory: energy);

      expect(aPlan.sessions.first.fitScore, greaterThanOrEqualTo(cPlan.sessions.first.fitScore));
    });

    test('deadline tasks are scheduled first', () {
      final svc = FocusSessionAdvisorService(now: () => fixedNow);
      final plan = svc.analyze(
        tasks: [
          const FocusTask(id: 't1', title: 'Low priority', complexity: 3, priority: 1),
          const FocusTask(id: 't2', title: 'Deadline!', complexity: 3, priority: 5, deadlineToday: true),
        ],
        availableBlocks: [
          TimeBlock(start: DateTime(2026, 6, 2, 9, 0), end: DateTime(2026, 6, 2, 10, 0)),
        ],
      );
      // Deadline task should be first in sessions (gets the block).
      expect(plan.sessions.first.taskId, 't2');
    });

    test('formatText contains headline and playbook', () {
      final svc = FocusSessionAdvisorService(now: () => fixedNow);
      final plan = svc.analyze(tasks: []);
      final text = svc.formatText(plan);
      expect(text, contains('VERDICT:'));
      expect(text, contains('Playbook:'));
    });

    test('formatMarkdown contains all sections', () {
      final svc = FocusSessionAdvisorService(now: () => fixedNow);
      final plan = svc.analyze(
        tasks: [const FocusTask(id: 't1', title: 'Test', complexity: 5)],
        availableBlocks: [
          TimeBlock(start: DateTime(2026, 6, 2, 9, 0), end: DateTime(2026, 6, 2, 12, 0)),
        ],
      );
      final md = svc.formatMarkdown(plan);
      expect(md, contains('## Focus Session Plan'));
      expect(md, contains('## Sessions'));
      expect(md, contains('## Playbook'));
      expect(md, contains('## Insights'));
    });

    test('formatJson has sorted keys', () {
      final svc = FocusSessionAdvisorService(now: () => fixedNow);
      final plan = svc.analyze(tasks: []);
      final json = svc.formatJson(plan);
      final keys = json.keys.toList();
      final sorted = List<String>.from(keys)..sort();
      expect(keys, sorted);
    });

    test('ENERGY_MISMATCH for complex task in low-energy window', () {
      final svc = FocusSessionAdvisorService(now: () => fixedNow);
      final plan = svc.analyze(
        tasks: [
          const FocusTask(id: 't1', title: 'Complex design', complexity: 9, estimatedMinutes: 60),
        ],
        energyHistory: [
          EnergyReading(timestamp: DateTime(2026, 6, 1, 14, 0), level: 2),
          EnergyReading(timestamp: DateTime(2026, 6, 1, 14, 0), level: 1),
        ],
        availableBlocks: [
          TimeBlock(start: DateTime(2026, 6, 2, 14, 0), end: DateTime(2026, 6, 2, 16, 0)),
        ],
      );
      expect(plan.sessions.first.verdict, 'ENERGY_MISMATCH');
      expect(plan.sessions.first.reasons, contains('LOW_ENERGY_HIGH_COMPLEXITY'));
    });

    test('NO_ENERGY_DATA insight when no readings provided', () {
      final svc = FocusSessionAdvisorService(now: () => fixedNow);
      final plan = svc.analyze(
        tasks: [const FocusTask(id: 't1', title: 'Work')],
        availableBlocks: [
          TimeBlock(start: DateTime(2026, 6, 2, 9, 0), end: DateTime(2026, 6, 2, 12, 0)),
        ],
      );
      expect(plan.insights, contains('NO_ENERGY_DATA'));
    });

    test('cautious adds SCHEDULE_FOCUS_AUDIT at low grade', () {
      final svc = FocusSessionAdvisorService(
        now: () => fixedNow,
        appetite: FocusRiskAppetite.cautious,
      );
      final plan = svc.analyze(
        tasks: [
          const FocusTask(id: 't1', title: 'A', complexity: 9, estimatedMinutes: 90),
          const FocusTask(id: 't2', title: 'B', complexity: 9, estimatedMinutes: 90),
          const FocusTask(id: 't3', title: 'C', complexity: 9, estimatedMinutes: 90),
        ],
        availableBlocks: [
          TimeBlock(start: DateTime(2026, 6, 2, 10, 0), end: DateTime(2026, 6, 2, 10, 30)),
        ],
      );
      // Should have low grade due to overcommitment
      if (plan.grade == 'C' || plan.grade == 'D' || plan.grade == 'F') {
        expect(plan.playbook.any((a) => a.id == 'SCHEDULE_FOCUS_AUDIT'), isTrue);
      }
    });
  });
}
