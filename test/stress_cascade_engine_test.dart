import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/stress_cascade_engine_service.dart';

void main() {
  group('StressCascadeEngineService', () {
    late StressCascadeEngineService service;

    setUp(() {
      service = StressCascadeEngineService();
    });

    // -----------------------------------------------------------------------
    // Empty state
    // -----------------------------------------------------------------------

    test('empty state returns safe defaults', () {
      final report = service.analyze();
      expect(report.compositeStressScore, 0);
      expect(report.cascadePhase, CascadePhase.dormant);
      expect(report.resilienceTier, ResilienceTier.resilient);
      expect(report.domainProfiles.length, StressDomain.values.length);
      expect(report.cascadeEdges, isEmpty);
      expect(report.bufferStatus, isEmpty);
      expect(report.tippingPoints, isEmpty);
      expect(report.recoveryForecasts, isEmpty);
      expect(report.insights, isNotEmpty); // "No data" insight.
    });

    test('empty state domain profiles have zero levels', () {
      final report = service.analyze();
      for (final p in report.domainProfiles) {
        expect(p.currentLevel, 0);
        expect(p.eventCount, 0);
        expect(p.averageSeverity, 0.0);
      }
    });

    // -----------------------------------------------------------------------
    // Single event
    // -----------------------------------------------------------------------

    test('single event produces non-zero analysis', () {
      service.addEvent(StressEvent(
        domain: StressDomain.work,
        severity: StressSeverity.moderate,
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        description: 'Test event',
      ));
      final report = service.analyze();
      expect(report.domainProfiles
          .firstWhere((p) => p.domain == StressDomain.work)
          .eventCount, 1);
    });

    test('single event does not produce cascade edges', () {
      service.addEvent(StressEvent(
        domain: StressDomain.work,
        severity: StressSeverity.severe,
        timestamp: DateTime.now(),
        description: 'Solo event',
      ));
      final report = service.analyze();
      expect(report.cascadeEdges, isEmpty);
    });

    // -----------------------------------------------------------------------
    // Sample data
    // -----------------------------------------------------------------------

    test('loadSampleData populates events', () {
      service.loadSampleData();
      expect(service.events, isNotEmpty);
      expect(service.events.length, greaterThan(30));
    });

    test('loadSampleData is deterministic', () {
      service.loadSampleData();
      final count1 = service.events.length;
      service.loadSampleData();
      expect(service.events.length, count1);
    });

    test('sample data covers multiple domains', () {
      service.loadSampleData();
      final domains = service.events.map((e) => e.domain).toSet();
      expect(domains.length, greaterThanOrEqualTo(4));
    });

    test('sample data spans multiple days', () {
      service.loadSampleData();
      final dates = service.events
          .map((e) => DateTime(
              e.timestamp.year, e.timestamp.month, e.timestamp.day))
          .toSet();
      expect(dates.length, greaterThan(10));
    });

    // -----------------------------------------------------------------------
    // Full analysis with sample data
    // -----------------------------------------------------------------------

    test('full analysis with sample data produces valid report', () {
      service.loadSampleData();
      final report = service.analyze();
      expect(report.compositeStressScore, inInclusiveRange(0, 100));
      expect(report.domainProfiles.length, StressDomain.values.length);
      expect(report.insights, isNotEmpty);
    });

    test('sample data produces cascade edges', () {
      service.loadSampleData();
      final report = service.analyze();
      expect(report.cascadeEdges, isNotEmpty);
    });

    test('sample data produces buffer status', () {
      service.loadSampleData();
      final report = service.analyze();
      expect(report.bufferStatus, isNotEmpty);
      expect(report.bufferStatus.length, 6); // 6 buffer categories.
    });

    // -----------------------------------------------------------------------
    // Domain profiles
    // -----------------------------------------------------------------------

    test('domain profiles have valid current levels', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final p in report.domainProfiles) {
        expect(p.currentLevel, inInclusiveRange(0, 100));
      }
    });

    test('domain profiles have valid average severity', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final p in report.domainProfiles) {
        if (p.eventCount > 0) {
          expect(p.averageSeverity, inInclusiveRange(1.0, 5.0));
        }
      }
    });

    test('domain profiles have valid recovery rate', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final p in report.domainProfiles) {
        expect(p.recoveryRatePerDay, greaterThan(0));
      }
    });

    test('domain event counts sum to total events', () {
      service.loadSampleData();
      final report = service.analyze();
      final sum =
          report.domainProfiles.map((p) => p.eventCount).reduce((a, b) => a + b);
      expect(sum, service.events.length);
    });

    // -----------------------------------------------------------------------
    // Cascade edges
    // -----------------------------------------------------------------------

    test('cascade edges have valid propagation strength', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final edge in report.cascadeEdges) {
        expect(edge.propagationStrength, inInclusiveRange(0.0, 1.0));
      }
    });

    test('cascade edges have positive delay', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final edge in report.cascadeEdges) {
        expect(edge.delayHours, greaterThanOrEqualTo(0));
      }
    });

    test('cascade edges are sorted by strength descending', () {
      service.loadSampleData();
      final report = service.analyze();
      for (int i = 1; i < report.cascadeEdges.length; i++) {
        expect(report.cascadeEdges[i].propagationStrength,
            lessThanOrEqualTo(report.cascadeEdges[i - 1].propagationStrength));
      }
    });

    test('cascade edges have positive evidence count', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final edge in report.cascadeEdges) {
        expect(edge.evidenceCount, greaterThan(0));
      }
    });

    test('cascade edges connect different domains', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final edge in report.cascadeEdges) {
        expect(edge.fromDomain, isNot(equals(edge.toDomain)));
      }
    });

    // -----------------------------------------------------------------------
    // Resilience tier classification
    // -----------------------------------------------------------------------

    test('resilience tier: antifragile >= 85', () {
      expect(StressCascadeEngineService.computeResilienceTier(85),
          ResilienceTier.antifragile);
      expect(StressCascadeEngineService.computeResilienceTier(100),
          ResilienceTier.antifragile);
    });

    test('resilience tier: resilient 70-84', () {
      expect(StressCascadeEngineService.computeResilienceTier(70),
          ResilienceTier.resilient);
      expect(StressCascadeEngineService.computeResilienceTier(84),
          ResilienceTier.resilient);
    });

    test('resilience tier: adequate 50-69', () {
      expect(StressCascadeEngineService.computeResilienceTier(50),
          ResilienceTier.adequate);
      expect(StressCascadeEngineService.computeResilienceTier(69),
          ResilienceTier.adequate);
    });

    test('resilience tier: fragile 30-49', () {
      expect(StressCascadeEngineService.computeResilienceTier(30),
          ResilienceTier.fragile);
      expect(StressCascadeEngineService.computeResilienceTier(49),
          ResilienceTier.fragile);
    });

    test('resilience tier: brittle < 30', () {
      expect(StressCascadeEngineService.computeResilienceTier(0),
          ResilienceTier.brittle);
      expect(StressCascadeEngineService.computeResilienceTier(29),
          ResilienceTier.brittle);
    });

    // -----------------------------------------------------------------------
    // Cascade phase classification
    // -----------------------------------------------------------------------

    test('cascade phase: dormant for low score', () {
      expect(
          StressCascadeEngineService.computeCascadePhase(10, 0, 0.0),
          CascadePhase.dormant);
    });

    test('cascade phase: building for moderate score', () {
      expect(
          StressCascadeEngineService.computeCascadePhase(40, 1, 1.0),
          CascadePhase.building);
    });

    test('cascade phase: spreading for high score + 3 domains', () {
      expect(
          StressCascadeEngineService.computeCascadePhase(55, 3, 1.0),
          CascadePhase.spreading);
    });

    test('cascade phase: peaking for very high score + 4 domains', () {
      expect(
          StressCascadeEngineService.computeCascadePhase(75, 4, 1.0),
          CascadePhase.peaking);
    });

    test('cascade phase: recovering for declining trend', () {
      expect(
          StressCascadeEngineService.computeCascadePhase(45, 2, -3.0),
          CascadePhase.recovering);
    });

    // -----------------------------------------------------------------------
    // Buffers
    // -----------------------------------------------------------------------

    test('buffer levels are in valid range', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final b in report.bufferStatus) {
        expect(b.currentLevel, inInclusiveRange(0, 100));
      }
    });

    test('buffer depletion rates are positive', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final b in report.bufferStatus) {
        expect(b.depletionRate, greaterThan(0));
      }
    });

    test('all buffer categories represented', () {
      service.loadSampleData();
      final report = service.analyze();
      final categories = report.bufferStatus.map((b) => b.category).toSet();
      expect(categories.length, BufferCategory.values.length);
    });

    // -----------------------------------------------------------------------
    // Tipping points
    // -----------------------------------------------------------------------

    test('tipping point alerts have valid fields', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final tp in report.tippingPoints) {
        expect(tp.threshold, 80);
        expect(tp.daysUntilBreach, greaterThan(0));
        expect(tp.confidence, inInclusiveRange(0.0, 1.0));
      }
    });

    test('tipping points sorted by days ascending', () {
      service.loadSampleData();
      final report = service.analyze();
      for (int i = 1; i < report.tippingPoints.length; i++) {
        expect(report.tippingPoints[i].daysUntilBreach,
            greaterThanOrEqualTo(report.tippingPoints[i - 1].daysUntilBreach));
      }
    });

    // -----------------------------------------------------------------------
    // Recovery forecasts
    // -----------------------------------------------------------------------

    test('recovery forecasts only for high-stress domains', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final rf in report.recoveryForecasts) {
        expect(rf.currentLevel, greaterThanOrEqualTo(40));
      }
    });

    test('recovery forecasts have recommended actions', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final rf in report.recoveryForecasts) {
        expect(rf.recommendedActions, isNotEmpty);
      }
    });

    test('recovery forecasts have positive projected days', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final rf in report.recoveryForecasts) {
        expect(rf.projectedDays, greaterThan(0));
      }
    });

    // -----------------------------------------------------------------------
    // Insights
    // -----------------------------------------------------------------------

    test('insights are generated from sample data', () {
      service.loadSampleData();
      final report = service.analyze();
      expect(report.insights, isNotEmpty);
    });

    test('insights have valid categories', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final insight in report.insights) {
        expect(CascadeInsightCategory.values, contains(insight.category));
      }
    });

    test('insights are sorted by priority', () {
      service.loadSampleData();
      final report = service.analyze();
      final priorityOrder = {
        CascadeInsightPriority.critical: 0,
        CascadeInsightPriority.high: 1,
        CascadeInsightPriority.medium: 2,
        CascadeInsightPriority.low: 3,
      };
      for (int i = 1; i < report.insights.length; i++) {
        expect(priorityOrder[report.insights[i].priority],
            greaterThanOrEqualTo(
                priorityOrder[report.insights[i - 1].priority]));
      }
    });

    test('insights have non-empty titles and descriptions', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final insight in report.insights) {
        expect(insight.title, isNotEmpty);
        expect(insight.description, isNotEmpty);
      }
    });

    // -----------------------------------------------------------------------
    // Enum properties
    // -----------------------------------------------------------------------

    test('all StressDomain values have labels and emojis', () {
      for (final d in StressDomain.values) {
        expect(d.label, isNotEmpty);
        expect(d.emoji, isNotEmpty);
        expect(d.colorHex, isNonZero);
      }
    });

    test('all StressSeverity values have correct numeric values', () {
      for (int i = 0; i < StressSeverity.values.length; i++) {
        expect(StressSeverity.values[i].numericValue, i + 1);
      }
    });

    test('all CascadePhase values have labels and descriptions', () {
      for (final p in CascadePhase.values) {
        expect(p.label, isNotEmpty);
        expect(p.emoji, isNotEmpty);
        expect(p.description, isNotEmpty);
      }
    });

    test('all ResilienceTier values have labels and descriptions', () {
      for (final t in ResilienceTier.values) {
        expect(t.label, isNotEmpty);
        expect(t.emoji, isNotEmpty);
        expect(t.description, isNotEmpty);
      }
    });

    test('all BufferCategory values have labels and emojis', () {
      for (final c in BufferCategory.values) {
        expect(c.label, isNotEmpty);
        expect(c.emoji, isNotEmpty);
      }
    });

    // -----------------------------------------------------------------------
    // Edge cases
    // -----------------------------------------------------------------------

    test('all events in same domain produces no cascade edges', () {
      for (int i = 0; i < 10; i++) {
        service.addEvent(StressEvent(
          domain: StressDomain.work,
          severity: StressSeverity.moderate,
          timestamp:
              DateTime.now().subtract(Duration(days: i)),
          description: 'Work event $i',
        ));
      }
      final report = service.analyze();
      expect(report.cascadeEdges, isEmpty);
    });

    test('all extreme severity produces high composite score', () {
      for (final domain in StressDomain.values) {
        for (int i = 0; i < 5; i++) {
          service.addEvent(StressEvent(
            domain: domain,
            severity: StressSeverity.extreme,
            timestamp:
                DateTime.now().subtract(Duration(hours: i * 2)),
            description: 'Extreme ${domain.label}',
          ));
        }
      }
      final report = service.analyze();
      expect(report.compositeStressScore, greaterThan(50));
    });

    test('very old events do not affect current level', () {
      service.addEvent(StressEvent(
        domain: StressDomain.work,
        severity: StressSeverity.extreme,
        timestamp: DateTime.now().subtract(const Duration(days: 60)),
        description: 'Ancient stress',
      ));
      final report = service.analyze();
      final workProfile =
          report.domainProfiles.firstWhere((p) => p.domain == StressDomain.work);
      expect(workProfile.currentLevel, 0);
    });

    test('insight emoji matches category', () {
      service.loadSampleData();
      final report = service.analyze();
      for (final insight in report.insights) {
        expect(insight.emoji, insight.category.emoji);
      }
    });

    test('composite score is average of active domain levels', () {
      service.loadSampleData();
      final report = service.analyze();
      final activeDomains =
          report.domainProfiles.where((p) => p.currentLevel > 0).toList();
      if (activeDomains.isNotEmpty) {
        final expectedScore = (activeDomains
                    .map((p) => p.currentLevel)
                    .reduce((a, b) => a + b) /
                activeDomains.length)
            .round()
            .clamp(0, 100);
        expect(report.compositeStressScore, expectedScore);
      }
    });
  });
}
