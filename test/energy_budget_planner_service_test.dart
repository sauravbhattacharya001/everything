import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/energy_budget_planner_service.dart';

DateTime _today() => DateTime(2026, 5, 18, 7, 0);

EnergyBudgetPlannerService _svc({
  double budget = 100,
  int maxBuffers = 2,
}) =>
    EnergyBudgetPlannerService(
      now: _today,
      dailyBudget: budget,
      maxBufferInserts: maxBuffers,
    );

PlannedEvent _ev(
  String id,
  int hour, {
  int minutes = 60,
  EventKind kind = EventKind.meeting,
  int priority = 3,
  bool isAnchor = false,
  String? title,
}) {
  final base = DateTime(2026, 5, 18, hour);
  return PlannedEvent(
    id: id,
    title: title ?? id,
    start: base,
    duration: Duration(minutes: minutes),
    kind: kind,
    priority: priority,
    isAnchor: isAnchor,
  );
}

void main() {
  group('EnergyBudgetPlannerService', () {
    test('empty events => UNDER_USED, grade B, no playbook clutter', () {
      final svc = _svc();
      final plan = svc.analyze(const []);
      expect(plan.items, isEmpty);
      expect(plan.band, EnergyDayBand.underUsed);
      expect(plan.grade, 'B');
      expect(plan.consumedEnergy, 0);
      expect(plan.insights, isNotEmpty);
    });

    test('light day stays BALANCED or UNDER_USED with grade A or B', () {
      final svc = _svc();
      final events = [
        _ev('m1', 9, minutes: 60, kind: EventKind.meeting, priority: 3),
        _ev('dw', 14, minutes: 60, kind: EventKind.deepWork, priority: 4),
      ];
      final plan = svc.analyze(events);
      expect(plan.band,
          anyOf(EnergyDayBand.balanced, EnergyDayBand.underUsed));
      expect(plan.grade, anyOf('A', 'B'));
      // No anchors used, so all KEEP.
      expect(
          plan.items.every((d) =>
              d.verdict == EnergyEventVerdict.keep ||
              d.verdict == EnergyEventVerdict.bufferInsert),
          isTrue);
    });

    test('8h of back-to-back meetings => OVERLOADED+ with playbook actions',
        () {
      final svc = _svc();
      final events = [
        for (int i = 0; i < 8)
          _ev('m$i', 9 + i, minutes: 60, kind: EventKind.meeting, priority: 2),
      ];
      final plan = svc.analyze(events);
      expect(
          plan.band,
          anyOf(EnergyDayBand.overloaded, EnergyDayBand.unsafe,
              EnergyDayBand.tight));
      final codes = plan.playbook.map((a) => a.code).toSet();
      expect(codes.contains('RESCHEDULE_LOW_PRIORITY'), isTrue);
      // Buffer insertion happened (low priority => some get rescheduled,
      // but several remain back-to-back).
      final buffers = plan.items
          .where((d) => d.verdict == EnergyEventVerdict.bufferInsert)
          .toList();
      expect(buffers.length, lessThanOrEqualTo(2));
    });

    test('sleep<5h shrinks effective budget vs well-rested', () {
      final svc = _svc();
      final events = [
        _ev('m1', 9, minutes: 60, kind: EventKind.meeting, priority: 3),
        _ev('m2', 11, minutes: 60, kind: EventKind.meeting, priority: 3),
        _ev('m3', 14, minutes: 60, kind: EventKind.meeting, priority: 3),
      ];
      final rested = svc.analyze(events,
          context: const EnergyContext(sleepHoursLastNight: 8));
      final tired = svc.analyze(events,
          context: const EnergyContext(sleepHoursLastNight: 4.5));
      expect(tired.effectiveBudget, lessThan(rested.effectiveBudget));
      expect(tired.dayLoadScore, greaterThan(rested.dayLoadScore));
    });

    test('mood<=2 shrinks effective budget', () {
      final svc = _svc();
      final events = [
        _ev('m1', 10, minutes: 90, kind: EventKind.meeting, priority: 3),
      ];
      final happy = svc.analyze(events,
          context: const EnergyContext(mood: 4));
      final sad =
          svc.analyze(events, context: const EnergyContext(mood: 1));
      expect(sad.effectiveBudget, lessThan(happy.effectiveBudget));
    });

    test('anchor events never get RESCHEDULE / SHORTEN / DECLINE verdicts',
        () {
      final svc = _svc(budget: 40); // very tight budget
      final events = [
        _ev('a1', 9,
            minutes: 120,
            kind: EventKind.deepWork,
            priority: 5,
            isAnchor: true),
        _ev('a2', 12,
            minutes: 120,
            kind: EventKind.meeting,
            priority: 5,
            isAnchor: true),
        _ev('extra', 15,
            minutes: 60, kind: EventKind.meeting, priority: 2),
      ];
      final plan = svc.analyze(events);
      for (final d in plan.items) {
        if (d.isAnchor) {
          expect(d.verdict, EnergyEventVerdict.keepAnchor,
              reason: 'anchor ${d.id} got ${d.verdict}');
        }
      }
    });

    test(
        'cautious appetite produces >= dayLoadScore than aggressive on same input',
        () {
      final svc = _svc();
      final events = [
        _ev('m1', 9, minutes: 60, kind: EventKind.meeting, priority: 3),
        _ev('m2', 11, minutes: 60, kind: EventKind.meeting, priority: 3),
        _ev('m3', 14, minutes: 60, kind: EventKind.meeting, priority: 3),
      ];
      final cautious = svc.analyze(events,
          appetite: EnergyRiskAppetite.cautious);
      final aggressive = svc.analyze(events,
          appetite: EnergyRiskAppetite.aggressive);
      expect(cautious.dayLoadScore,
          greaterThanOrEqualTo(aggressive.dayLoadScore));
    });

    test('deep-work outside chronotype peak fires MOVE_DEEP_WORK_TO_PEAK',
        () {
      final svc = _svc();
      final events = [
        // peak=10, deep-work at 16 => far outside
        _ev('dw', 16, minutes: 90, kind: EventKind.deepWork, priority: 4),
      ];
      final plan = svc.analyze(events,
          context: const EnergyContext(chronotypePeakHour: 10));
      final codes = plan.playbook.map((a) => a.code).toSet();
      expect(codes.contains('MOVE_DEEP_WORK_TO_PEAK'), isTrue);
    });

    test('4+ back-to-back events fire cascade-risk insight', () {
      final svc = _svc(maxBuffers: 0); // disable buffers so run is intact
      final events = [
        for (int i = 0; i < 5)
          _ev('m$i', 9 + i, minutes: 60, kind: EventKind.meeting, priority: 4),
      ];
      final plan = svc.analyze(events);
      final hasCascade =
          plan.insights.any((i) => i.toLowerCase().contains('cascade'));
      expect(hasCascade, isTrue,
          reason: 'insights: ${plan.insights.join(" | ")}');
    });

    test('markdown renderer contains required sections', () {
      final svc = _svc();
      final events = [
        _ev('m1', 9, minutes: 60, kind: EventKind.meeting, priority: 2),
        _ev('m2', 10, minutes: 60, kind: EventKind.meeting, priority: 2),
        _ev('m3', 11, minutes: 60, kind: EventKind.meeting, priority: 2),
        _ev('m4', 12, minutes: 60, kind: EventKind.meeting, priority: 2),
      ];
      final plan = svc.analyze(events);
      final md = svc.formatMarkdown(plan);
      expect(md, contains('## Day load'));
      expect(md, contains('## Events'));
      expect(md, contains('## Playbook'));
    });

    test('text renderer non-empty and contains grade letter', () {
      final svc = _svc();
      final events = [
        _ev('m1', 10, minutes: 60, kind: EventKind.meeting, priority: 3),
      ];
      final plan = svc.analyze(events);
      final txt = svc.formatText(plan);
      expect(txt, isNotEmpty);
      expect(txt, contains('Grade: ${plan.grade}'));
    });

    test('buffer inserts count <= maxBufferInserts', () {
      final svc = _svc(maxBuffers: 2);
      final events = [
        for (int i = 0; i < 7)
          _ev('m$i', 9 + i, minutes: 60, kind: EventKind.meeting, priority: 4),
      ];
      final plan = svc.analyze(events);
      final buffers = plan.items
          .where((d) => d.verdict == EnergyEventVerdict.bufferInsert)
          .toList();
      expect(buffers.length, lessThanOrEqualTo(2));
      for (final b in buffers) {
        expect(b.synthetic, isTrue);
        expect(b.id, startsWith('buffer_'));
      }
    });

    test('input list is never mutated', () {
      final svc = _svc();
      final events = [
        _ev('m2', 11),
        _ev('m1', 9),
      ];
      final before = events.map((e) => e.id).toList();
      svc.analyze(events);
      final after = events.map((e) => e.id).toList();
      expect(after, equals(before));
    });
  });
}
