import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/task_batching_advisor_service.dart';

DateTime _now() => DateTime(2026, 5, 23, 9, 0);

TaskBatchingAdvisorService _svc() => const TaskBatchingAdvisorService();

BatchingOptions _opts({
  TaskBatchingRiskAppetite appetite = TaskBatchingRiskAppetite.balanced,
  Set<String> availableTools = const <String>{},
}) =>
    BatchingOptions(
      riskAppetite: appetite,
      availableTools: availableTools,
      now: _now,
    );

TaskSnapshot _t(
  String id, {
  String context = 'errand',
  String? location,
  String? requiredTool,
  int estimatedMinutes = 20,
  int priorityWeight = 3,
  int? dueInHours,
}) {
  final now = _now();
  return TaskSnapshot(
    id: id,
    title: id,
    context: context,
    location: location,
    requiredTool: requiredTool,
    estimatedMinutes: estimatedMinutes,
    dueAt: dueInHours == null ? null : now.add(Duration(hours: dueInHours)),
    priorityWeight: priorityWeight,
  );
}

void main() {
  group('TaskBatchingAdvisorService', () {
    test('empty list => grade A + EMPTY_PORTFOLIO', () {
      final r = _svc().recommend(const <TaskSnapshot>[], _opts());
      expect(r.grade, 'A');
      expect(r.totalTasks, 0);
      expect(r.headline, contains('EMPTY_PORTFOLIO'));
      expect(r.insights, contains('EMPTY_PORTFOLIO'));
      expect(r.playbook, isEmpty);
    });

    test('single low-priority isolated task => STANDALONE_DEFER', () {
      final r = _svc().recommend([
        _t('a', context: 'home', priorityWeight: 2),
      ], _opts());
      expect(r.forecasts.single.verdict, TaskBatchingVerdict.standaloneDefer);
    });

    test('single high-priority/due-soon isolated => STANDALONE_URGENT', () {
      final r = _svc().recommend([
        _t('a', context: 'home', priorityWeight: 5, dueInHours: 3),
      ], _opts());
      expect(
        r.forecasts.single.verdict,
        TaskBatchingVerdict.standaloneUrgent,
      );
    });

    test(
        '3 errand tasks same location => all BATCH_NOW + cluster + RUN_ERRAND_BATCH_NOW',
        () {
      final r = _svc().recommend([
        _t('a', context: 'errand', location: 'westgate', dueInHours: 5),
        _t('b', context: 'errand', location: 'westgate'),
        _t('c', context: 'errand', location: 'westgate'),
      ], _opts());
      for (final f in r.forecasts) {
        expect(f.verdict, TaskBatchingVerdict.batchNow);
        expect(f.clusterId, 'C01');
      }
      expect(r.clusters, hasLength(1));
      expect(r.clusters.first.memberIds, ['a', 'b', 'c']);
      expect(r.projectedSavedMinutes, 16);
      expect(
        r.playbook.any((a) => a.code == 'RUN_ERRAND_BATCH_NOW'),
        isTrue,
      );
    });

    test('120-min task => SPLIT_RECOMMENDED + BREAK_DOWN_LARGE_TASKS', () {
      final r = _svc().recommend([
        _t('big', context: 'deep_work', estimatedMinutes: 120),
      ], _opts());
      expect(
        r.forecasts.single.verdict,
        TaskBatchingVerdict.splitRecommended,
      );
      expect(
        r.playbook.any((a) => a.code == 'BREAK_DOWN_LARGE_TASKS'),
        isTrue,
      );
    });

    test('missing requiredTool => BLOCKED_TOOL_UNAVAILABLE + UNBLOCK action',
        () {
      final r = _svc().recommend([
        _t('drive', context: 'errand', requiredTool: 'car'),
      ], _opts(availableTools: const <String>{'laptop'}));
      expect(
        r.forecasts.single.verdict,
        TaskBatchingVerdict.blockedToolUnavailable,
      );
      expect(
        r.playbook.any((a) => a.code == 'UNBLOCK_TOOL_DEPENDENCIES'),
        isTrue,
      );
    });

    test('2 phone_call tasks => SCHEDULE_PHONE_CALL_BLOCK', () {
      final r = _svc().recommend([
        _t('p1', context: 'phone_call'),
        _t('p2', context: 'phone_call'),
      ], _opts());
      expect(
        r.playbook.any((a) => a.code == 'SCHEDULE_PHONE_CALL_BLOCK'),
        isTrue,
      );
    });

    test('2 deep_work tasks => BLOCK_DEEP_WORK_WINDOW', () {
      final r = _svc().recommend([
        _t('d1', context: 'deep_work'),
        _t('d2', context: 'deep_work'),
      ], _opts());
      expect(
        r.playbook.any((a) => a.code == 'BLOCK_DEEP_WORK_WINDOW'),
        isTrue,
      );
    });

    test('shopping cluster => BATCH_SHOPPING_TRIP', () {
      final r = _svc().recommend([
        _t('s1', context: 'shopping', location: 'grocery'),
        _t('s2', context: 'shopping', location: 'grocery'),
        _t('s3', context: 'shopping', location: 'grocery'),
      ], _opts());
      expect(
        r.playbook.any((a) => a.code == 'BATCH_SHOPPING_TRIP'),
        isTrue,
      );
    });

    test('aggressive trims P3 HEALTHY fallback when other actions exist', () {
      final r = _svc().recommend([
        _t('p1', context: 'phone_call'),
        _t('p2', context: 'phone_call'),
      ],
          _opts(
              appetite: TaskBatchingRiskAppetite.aggressive));
      expect(
        r.playbook.any((a) => a.priority == TaskBatchingPriority.p3),
        isFalse,
      );
    });

    test('cautious adds SCHEDULE_BATCHING_REVIEW when grade is C or worse',
        () {
      final tasks = <TaskSnapshot>[
        for (var i = 0; i < 6; i++)
          _t('iso$i', context: 'misc$i', priorityWeight: 2),
      ];
      final r = _svc().recommend(
        tasks,
        _opts(appetite: TaskBatchingRiskAppetite.cautious),
      );
      expect(['C', 'D', 'F'].contains(r.grade), isTrue);
      expect(
        r.playbook.any((a) => a.code == 'SCHEDULE_BATCHING_REVIEW'),
        isTrue,
      );
    });

    test('JSON byte-stable across calls', () {
      final tasks = [
        _t('a', context: 'errand', location: 'mall'),
        _t('b', context: 'errand', location: 'mall'),
        _t('c', context: 'errand', location: 'mall'),
      ];
      final j1 = _svc().recommend(tasks, _opts()).toJson();
      final j2 = _svc().recommend(tasks, _opts()).toJson();
      expect(j1, j2);
    });

    test('markdown contains all key sections', () {
      final md = _svc().recommend([
        _t('a', context: 'errand', location: 'mall'),
        _t('b', context: 'errand', location: 'mall'),
        _t('c', context: 'errand', location: 'mall'),
      ], _opts()).toMarkdown();
      expect(md, contains('## Summary'));
      expect(md, contains('## Tasks'));
      expect(md, contains('## Clusters'));
      expect(md, contains('## Playbook'));
      expect(md, contains('## Insights'));
    });

    test('input list is not mutated by recommend()', () {
      final tasks = <TaskSnapshot>[
        _t('a', context: 'errand', location: 'mall'),
        _t('b', context: 'errand', location: 'mall'),
      ];
      final ids = tasks.map((t) => t.id).toList();
      _svc().recommend(tasks, _opts());
      expect(tasks.map((t) => t.id).toList(), ids);
    });

    test('all-batched tasks yield HEALTHY_TASK_FLOW insight or no fragmentation',
        () {
      final r = _svc().recommend([
        _t('a', context: 'errand', location: 'mall'),
        _t('b', context: 'errand', location: 'mall'),
        _t('c', context: 'errand', location: 'mall'),
      ], _opts());
      expect(r.isolatedTaskCount, 0);
      expect(r.batchedTaskCount, 3);
      expect(r.grade, 'A');
    });

    test('deterministic generated_at via options.now', () {
      final r = _svc().recommend([
        _t('a', context: 'errand', location: 'mall'),
      ], _opts());
      expect(r.generatedAt, _now());
    });
  });
}
