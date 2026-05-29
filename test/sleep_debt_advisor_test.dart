import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/sleep_debt_advisor_service.dart';

void main() {
  final fixedNow = DateTime(2026, 5, 28, 8, 0);

  SleepDebtAdvisorService makeService({
    SleepDebtRiskAppetite appetite = SleepDebtRiskAppetite.balanced,
    double target = 8.0,
  }) {
    return SleepDebtAdvisorService(
      targetHours: target,
      riskAppetite: appetite,
      nowFn: () => fixedNow,
    );
  }

  List<SleepNight> makeNights({
    required int count,
    required double hoursPerNight,
    int quality = 3,
    List<String> factors = const [],
  }) {
    return List.generate(count, (i) {
      final wake = fixedNow.subtract(Duration(days: count - 1 - i));
      final bed = wake.subtract(Duration(minutes: (hoursPerNight * 60).round()));
      return SleepNight(bedtime: bed, wakeTime: wake, quality: quality, factors: factors);
    });
  }

  group('SleepDebtAdvisorService', () {
    test('empty input returns INSUFFICIENT_DATA', () {
      final svc = makeService();
      final report = svc.analyze([]);
      expect(report.grade, 'A');
      expect(report.insights, contains('INSUFFICIENT_DATA'));
      expect(report.playbook.first.id, 'START_TRACKING');
    });

    test('full sleep returns grade A with no debt', () {
      final svc = makeService();
      final nights = makeNights(count: 7, hoursPerNight: 8.0);
      final report = svc.analyze(nights);
      expect(report.grade, 'A');
      expect(report.totalDebtHours, closeTo(0, 0.5));
      expect(report.insights, contains('HEALTHY_SLEEP_PATTERN'));
    });

    test('chronic 6h sleep accumulates debt and grades poorly', () {
      final svc = makeService();
      final nights = makeNights(count: 14, hoursPerNight: 6.0);
      final report = svc.analyze(nights);
      // 2h deficit per night x 14 = 28h debt
      expect(report.totalDebtHours, greaterThan(20));
      expect(report.grade, anyOf('D', 'F'));
      expect(report.playbook.any((a) => a.priority == 0), isTrue);
    });

    test('surplus nights reduce debt', () {
      final svc = makeService();
      // 5 nights of 6h then 5 nights of 10h
      final deficitNights = makeNights(count: 5, hoursPerNight: 6.0);
      final surplusNights = List.generate(5, (i) {
        final wake = fixedNow.subtract(Duration(days: 4 - i));
        final bed = wake.subtract(const Duration(hours: 10));
        return SleepNight(bedtime: bed, wakeTime: wake);
      });
      final report = svc.analyze([...deficitNights, ...surplusNights]);
      // Debt should be partially recovered
      expect(report.totalDebtHours, lessThan(10));
    });

    test('worsening trend detected', () {
      final svc = makeService();
      // First half at 7.5h, second half at 5.5h
      final nights = <SleepNight>[];
      for (int i = 0; i < 14; i++) {
        final hours = i < 7 ? 7.5 : 5.5;
        final wake = fixedNow.subtract(Duration(days: 13 - i));
        final bed = wake.subtract(Duration(minutes: (hours * 60).round()));
        nights.add(SleepNight(bedtime: bed, wakeTime: wake));
      }
      final report = svc.analyze(nights);
      expect(report.trend, 'worsening');
      expect(report.insights, contains('WORSENING_TREND'));
    });

    test('improving trend detected', () {
      final svc = makeService();
      final nights = <SleepNight>[];
      for (int i = 0; i < 14; i++) {
        final hours = i < 7 ? 5.5 : 8.5;
        final wake = fixedNow.subtract(Duration(days: 13 - i));
        final bed = wake.subtract(Duration(minutes: (hours * 60).round()));
        nights.add(SleepNight(bedtime: bed, wakeTime: wake));
      }
      final report = svc.analyze(nights);
      expect(report.trend, 'improving');
      expect(report.insights, contains('IMPROVING_TREND'));
    });

    test('inconsistent schedule lowers consistency score', () {
      final svc = makeService();
      final nights = <SleepNight>[];
      for (int i = 0; i < 7; i++) {
        final wake = fixedNow.subtract(Duration(days: 6 - i));
        // Wildly varying bedtimes: 9pm, 2am, 10pm, 3am, ...
        final bedHour = i.isEven ? 21 : 2;
        final bed = DateTime(wake.year, wake.month, wake.day - (bedHour < 12 ? 0 : 1), bedHour, 0);
        nights.add(SleepNight(bedtime: bed, wakeTime: wake));
      }
      final report = svc.analyze(nights);
      expect(report.consistencyScore, lessThan(60));
      expect(report.insights, contains('IRREGULAR_SCHEDULE'));
    });

    test('caffeine factor triggers curfew action', () {
      final svc = makeService();
      final nights = makeNights(count: 10, hoursPerNight: 6.5, factors: ['caffeine']);
      final report = svc.analyze(nights);
      expect(report.playbook.any((a) => a.id == 'CAFFEINE_CURFEW'), isTrue);
    });

    test('screen time factor triggers screen curfew', () {
      final svc = makeService();
      final nights = makeNights(count: 10, hoursPerNight: 6.5, factors: ['screenTime']);
      final report = svc.analyze(nights);
      expect(report.playbook.any((a) => a.id == 'SCREEN_CURFEW'), isTrue);
    });

    test('cautious appetite increases debt score', () {
      final cautious = SleepDebtAdvisorService(
        riskAppetite: SleepDebtRiskAppetite.cautious,
        nowFn: () => fixedNow,
      );
      final aggressive = SleepDebtAdvisorService(
        riskAppetite: SleepDebtRiskAppetite.aggressive,
        nowFn: () => fixedNow,
      );
      final nights = makeNights(count: 7, hoursPerNight: 6.5);
      final cr = cautious.analyze(nights);
      final ar = aggressive.analyze(nights);
      expect(cr.debtScore, greaterThan(ar.debtScore));
    });

    test('aggressive trims P3 actions when P0/P1 present', () {
      final svc = SleepDebtAdvisorService(
        riskAppetite: SleepDebtRiskAppetite.aggressive,
        nowFn: () => fixedNow,
      );
      final nights = makeNights(count: 14, hoursPerNight: 5.5);
      final report = svc.analyze(nights);
      expect(report.playbook.any((a) => a.priority <= 1), isTrue);
      expect(report.playbook.any((a) => a.priority == 3), isFalse);
    });

    test('cautious + low grade adds SCHEDULE_SLEEP_AUDIT', () {
      final svc = SleepDebtAdvisorService(
        riskAppetite: SleepDebtRiskAppetite.cautious,
        nowFn: () => fixedNow,
      );
      final nights = makeNights(count: 14, hoursPerNight: 5.5);
      final report = svc.analyze(nights);
      expect(report.playbook.any((a) => a.id == 'SCHEDULE_SLEEP_AUDIT'), isTrue);
    });

    test('weekend rebound pattern detected', () {
      final svc = makeService();
      final nights = <SleepNight>[];
      for (int i = 0; i < 14; i++) {
        final wake = fixedNow.subtract(Duration(days: 13 - i));
        final isWeekend = wake.weekday == DateTime.saturday || wake.weekday == DateTime.sunday;
        final hours = isWeekend ? 10.5 : 6.0;
        final bed = wake.subtract(Duration(minutes: (hours * 60).round()));
        nights.add(SleepNight(bedtime: bed, wakeTime: wake));
      }
      final report = svc.analyze(nights);
      expect(report.insights, contains('WEEKEND_REBOUND_PATTERN'));
    });

    test('low quality nights trigger environment audit', () {
      final svc = makeService();
      final nights = makeNights(count: 10, hoursPerNight: 7.0, quality: 1);
      final report = svc.analyze(nights);
      expect(report.playbook.any((a) => a.id == 'INVESTIGATE_SLEEP_ENVIRONMENT'), isTrue);
    });

    test('formatText includes headline and playbook', () {
      final svc = makeService();
      final report = svc.analyze(makeNights(count: 7, hoursPerNight: 6.5));
      final text = svc.formatText(report);
      expect(text, contains('VERDICT:'));
      expect(text, contains('Playbook:'));
    });

    test('formatMarkdown includes all sections', () {
      final svc = makeService();
      final report = svc.analyze(makeNights(count: 7, hoursPerNight: 6.5));
      final md = svc.formatMarkdown(report);
      expect(md, contains('## Summary'));
      expect(md, contains('## Playbook'));
      expect(md, contains('## Insights'));
    });

    test('recovery days estimate is reasonable', () {
      final svc = makeService();
      final nights = makeNights(count: 14, hoursPerNight: 6.0);
      final report = svc.analyze(nights);
      // 28h debt / 0.75 recovery rate ≈ 37 days
      expect(report.estimatedRecoveryDays, greaterThan(20));
      expect(report.estimatedRecoveryDays, lessThan(60));
    });

    test('stress correlated insight fires with enough stress nights', () {
      final svc = makeService();
      final nights = makeNights(count: 7, hoursPerNight: 6.0, factors: ['stress']);
      final report = svc.analyze(nights);
      expect(report.insights, contains('STRESS_CORRELATED_DEFICIT'));
    });

    test('playbook sorted by priority then id', () {
      final svc = makeService();
      final nights = makeNights(count: 14, hoursPerNight: 5.0, factors: ['caffeine', 'screenTime']);
      final report = svc.analyze(nights);
      for (int i = 1; i < report.playbook.length; i++) {
        final prev = report.playbook[i - 1];
        final curr = report.playbook[i];
        expect(
          prev.priority < curr.priority ||
              (prev.priority == curr.priority && prev.id.compareTo(curr.id) <= 0),
          isTrue,
        );
      }
    });
  });
}
