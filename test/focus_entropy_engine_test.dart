import 'package:test/test.dart';
import 'dart:math';
import '../lib/core/services/focus_entropy_engine_service.dart';

void main() {
  group('FocusEntropyEngineService', () {
    late FocusEntropyEngineService service;

    setUp(() {
      service = FocusEntropyEngineService();
    });

    // -----------------------------------------------------------------------
    // Shannon entropy calculation
    // -----------------------------------------------------------------------

    group('Entropy Calculator', () {
      test('returns 0.0 for empty sessions', () {
        expect(FocusEntropyEngineService.computeEntropy([]), equals(0.0));
      });

      test('returns 0.0 for single-domain sessions', () {
        final sessions = [
          FocusSession(
            domain: 'Coding',
            startTime: DateTime(2026, 5, 1, 9, 0),
            durationMinutes: 60,
          ),
          FocusSession(
            domain: 'Coding',
            startTime: DateTime(2026, 5, 1, 10, 0),
            durationMinutes: 30,
          ),
        ];
        expect(
          FocusEntropyEngineService.computeEntropy(sessions),
          equals(0.0),
        );
      });

      test('returns log2(n) for uniform distribution', () {
        final sessions = [
          FocusSession(
            domain: 'A',
            startTime: DateTime(2026, 5, 1, 9, 0),
            durationMinutes: 60,
          ),
          FocusSession(
            domain: 'B',
            startTime: DateTime(2026, 5, 1, 10, 0),
            durationMinutes: 60,
          ),
          FocusSession(
            domain: 'C',
            startTime: DateTime(2026, 5, 1, 11, 0),
            durationMinutes: 60,
          ),
          FocusSession(
            domain: 'D',
            startTime: DateTime(2026, 5, 1, 12, 0),
            durationMinutes: 60,
          ),
        ];
        final entropy = FocusEntropyEngineService.computeEntropy(sessions);
        expect(entropy, closeTo(log(4) / ln2, 0.001)); // log2(4) = 2.0
      });

      test('entropy increases with more domains', () {
        final two = [
          FocusSession(domain: 'A', startTime: DateTime(2026, 5, 1, 9, 0), durationMinutes: 60),
          FocusSession(domain: 'B', startTime: DateTime(2026, 5, 1, 10, 0), durationMinutes: 60),
        ];
        final four = [
          FocusSession(domain: 'A', startTime: DateTime(2026, 5, 1, 9, 0), durationMinutes: 30),
          FocusSession(domain: 'B', startTime: DateTime(2026, 5, 1, 10, 0), durationMinutes: 30),
          FocusSession(domain: 'C', startTime: DateTime(2026, 5, 1, 11, 0), durationMinutes: 30),
          FocusSession(domain: 'D', startTime: DateTime(2026, 5, 1, 12, 0), durationMinutes: 30),
        ];
        expect(
          FocusEntropyEngineService.computeEntropy(four),
          greaterThan(FocusEntropyEngineService.computeEntropy(two)),
        );
      });

      test('skewed distribution has lower entropy than uniform', () {
        final skewed = [
          FocusSession(domain: 'A', startTime: DateTime(2026, 5, 1, 9, 0), durationMinutes: 180),
          FocusSession(domain: 'B', startTime: DateTime(2026, 5, 1, 12, 0), durationMinutes: 10),
          FocusSession(domain: 'C', startTime: DateTime(2026, 5, 1, 13, 0), durationMinutes: 10),
        ];
        final uniform = [
          FocusSession(domain: 'A', startTime: DateTime(2026, 5, 1, 9, 0), durationMinutes: 60),
          FocusSession(domain: 'B', startTime: DateTime(2026, 5, 1, 10, 0), durationMinutes: 60),
          FocusSession(domain: 'C', startTime: DateTime(2026, 5, 1, 11, 0), durationMinutes: 60),
        ];
        expect(
          FocusEntropyEngineService.computeEntropy(skewed),
          lessThan(FocusEntropyEngineService.computeEntropy(uniform)),
        );
      });

      test('entropy is non-negative', () {
        final sessions = [
          FocusSession(domain: 'X', startTime: DateTime(2026, 5, 1, 9, 0), durationMinutes: 1),
        ];
        expect(
          FocusEntropyEngineService.computeEntropy(sessions),
          greaterThanOrEqualTo(0.0),
        );
      });
    });

    // -----------------------------------------------------------------------
    // Context switch detection
    // -----------------------------------------------------------------------

    group('Context Switch Counter', () {
      test('no switches with single session', () {
        service.addSession(FocusSession(
          domain: 'Coding',
          startTime: DateTime(2026, 5, 1, 9, 0),
          durationMinutes: 60,
        ));
        final report = service.generateReport();
        expect(report.totalContextSwitches, equals(0));
      });

      test('no switches when same domain consecutive', () {
        service.addSession(FocusSession(
          domain: 'Coding',
          startTime: DateTime(2026, 5, 1, 9, 0),
          durationMinutes: 30,
        ));
        service.addSession(FocusSession(
          domain: 'Coding',
          startTime: DateTime(2026, 5, 1, 10, 0),
          durationMinutes: 30,
        ));
        final report = service.generateReport();
        expect(report.totalContextSwitches, equals(0));
      });

      test('counts switches between different domains', () {
        service.addSession(FocusSession(
          domain: 'Coding',
          startTime: DateTime(2026, 5, 1, 9, 0),
          durationMinutes: 30,
        ));
        service.addSession(FocusSession(
          domain: 'Email',
          startTime: DateTime(2026, 5, 1, 10, 0),
          durationMinutes: 30,
        ));
        service.addSession(FocusSession(
          domain: 'Coding',
          startTime: DateTime(2026, 5, 1, 11, 0),
          durationMinutes: 30,
        ));
        final report = service.generateReport();
        expect(report.totalContextSwitches, equals(2));
      });

      test('switch cost defaults to 23 minutes', () {
        expect(
          report(() {
            service.addSession(FocusSession(
              domain: 'A', startTime: DateTime(2026, 5, 1, 9, 0), durationMinutes: 30,
            ));
            service.addSession(FocusSession(
              domain: 'B', startTime: DateTime(2026, 5, 1, 10, 0), durationMinutes: 30,
            ));
            return service.generateReport();
          }).averageSwitchCost,
          equals(23.0),
        );
      });
    });

    // -----------------------------------------------------------------------
    // Deep work detection
    // -----------------------------------------------------------------------

    group('Deep Work Detector', () {
      test('sessions under 25 min are not deep work', () {
        service.addSession(FocusSession(
          domain: 'Coding',
          startTime: DateTime(2026, 5, 1, 9, 0),
          durationMinutes: 20,
        ));
        final report = service.generateReport();
        expect(report.deepWorkBlocks, isEmpty);
        expect(report.totalDeepWorkMinutes, equals(0));
      });

      test('sessions at exactly 25 min qualify as deep work', () {
        service.addSession(FocusSession(
          domain: 'Coding',
          startTime: DateTime(2026, 5, 1, 9, 0),
          durationMinutes: 25,
        ));
        final report = service.generateReport();
        expect(report.deepWorkBlocks, hasLength(1));
        expect(report.totalDeepWorkMinutes, equals(25));
      });

      test('longer sessions have higher quality scores', () {
        service.addSession(FocusSession(
          domain: 'Coding',
          startTime: DateTime(2026, 5, 1, 9, 0),
          durationMinutes: 25,
        ));
        service.addSession(FocusSession(
          domain: 'Research',
          startTime: DateTime(2026, 5, 1, 11, 0),
          durationMinutes: 120,
        ));
        final report = service.generateReport();
        expect(report.deepWorkBlocks[1].qualityScore,
            greaterThan(report.deepWorkBlocks[0].qualityScore));
      });

      test('deep work quality score is 0-100', () {
        service.addSession(FocusSession(
          domain: 'Coding',
          startTime: DateTime(2026, 5, 1, 9, 0),
          durationMinutes: 200, // very long
        ));
        final report = service.generateReport();
        expect(report.deepWorkBlocks.first.qualityScore, lessThanOrEqualTo(100));
        expect(report.deepWorkBlocks.first.qualityScore, greaterThanOrEqualTo(0));
      });
    });

    // -----------------------------------------------------------------------
    // Flow score
    // -----------------------------------------------------------------------

    group('Flow State Scorer', () {
      test('flow score is 0-100', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(report.flowScore, greaterThanOrEqualTo(0));
        expect(report.flowScore, lessThanOrEqualTo(100));
      });

      test('perfect focus yields high score', () {
        final score = FocusEntropyEngineService.computeFlowScore(
          deepWorkRatio: 1.0,
          entropy: 0.0,
          domainCount: 1,
          switchesPerHour: 0.0,
        );
        expect(score, equals(100));
      });

      test('terrible focus yields low score', () {
        final score = FocusEntropyEngineService.computeFlowScore(
          deepWorkRatio: 0.0,
          entropy: 3.0,
          domainCount: 8,
          switchesPerHour: 10.0,
        );
        expect(score, lessThan(20));
      });

      test('flow score components are balanced', () {
        // Medium everything → should be around 50.
        final score = FocusEntropyEngineService.computeFlowScore(
          deepWorkRatio: 0.5,
          entropy: 1.0,
          domainCount: 4,
          switchesPerHour: 3.0,
        );
        expect(score, greaterThan(30));
        expect(score, lessThan(70));
      });
    });

    // -----------------------------------------------------------------------
    // Focus grade classification
    // -----------------------------------------------------------------------

    group('Focus Grade', () {
      test('single domain is laser', () {
        expect(
          FocusEntropyEngineService.classifyGrade(0.0, 1),
          equals(FocusGrade.laser),
        );
      });

      test('low entropy is laser', () {
        expect(
          FocusEntropyEngineService.classifyGrade(0.5, 3),
          equals(FocusGrade.laser),
        );
      });

      test('moderate entropy is focused', () {
        expect(
          FocusEntropyEngineService.classifyGrade(1.2, 4),
          equals(FocusGrade.focused),
        );
      });

      test('medium entropy is balanced', () {
        expect(
          FocusEntropyEngineService.classifyGrade(1.8, 5),
          equals(FocusGrade.balanced),
        );
      });

      test('high entropy is scattered', () {
        expect(
          FocusEntropyEngineService.classifyGrade(2.3, 6),
          equals(FocusGrade.scattered),
        );
      });

      test('very high entropy is chaotic', () {
        expect(
          FocusEntropyEngineService.classifyGrade(2.8, 7),
          equals(FocusGrade.chaotic),
        );
      });

      test('all grades have labels', () {
        for (final g in FocusGrade.values) {
          expect(g.label, isNotEmpty);
          expect(g.emoji, isNotEmpty);
          expect(g.description, isNotEmpty);
        }
      });
    });

    // -----------------------------------------------------------------------
    // Forecast
    // -----------------------------------------------------------------------

    group('Focus Forecast', () {
      test('sample data produces a forecast', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(report.forecast.confidence, greaterThanOrEqualTo(0.0));
        expect(report.forecast.confidence, lessThanOrEqualTo(1.0));
        expect(FocusTrend.values, contains(report.forecast.trend));
      });

      test('forecast trend is valid enum', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(
          [FocusTrend.improving, FocusTrend.stable, FocusTrend.degrading],
          contains(report.forecast.trend),
        );
      });

      test('all focus trends have labels and emojis', () {
        for (final t in FocusTrend.values) {
          expect(t.label, isNotEmpty);
          expect(t.emoji, isNotEmpty);
        }
      });
    });

    // -----------------------------------------------------------------------
    // Insight generation
    // -----------------------------------------------------------------------

    group('Insight Generator', () {
      test('sample data generates insights', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(report.insights, isNotEmpty);
        expect(report.insights.length, greaterThanOrEqualTo(3));
      });

      test('each insight has title and description', () {
        service.loadSampleData();
        final report = service.generateReport();
        for (final i in report.insights) {
          expect(i.title, isNotEmpty);
          expect(i.description, isNotEmpty);
        }
      });

      test('insight categories are valid', () {
        service.loadSampleData();
        final report = service.generateReport();
        for (final i in report.insights) {
          expect(FocusInsightCategory.values, contains(i.category));
        }
      });

      test('insight priorities are valid', () {
        service.loadSampleData();
        final report = service.generateReport();
        for (final i in report.insights) {
          expect(FocusInsightPriority.values, contains(i.priority));
        }
      });

      test('all insight categories have labels and emojis', () {
        for (final c in FocusInsightCategory.values) {
          expect(c.label, isNotEmpty);
          expect(c.emoji, isNotEmpty);
        }
      });

      test('all insight priorities have labels', () {
        for (final p in FocusInsightPriority.values) {
          expect(p.label, isNotEmpty);
        }
      });

      test('insights include discovery category for dominant domain', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(
          report.insights.any((i) => i.category == FocusInsightCategory.discovery),
          isTrue,
        );
      });
    });

    // -----------------------------------------------------------------------
    // Empty data handling
    // -----------------------------------------------------------------------

    group('Empty data handling', () {
      test('empty service produces valid report', () {
        final report = service.generateReport();
        expect(report.flowScore, equals(0));
        expect(report.focusGrade, equals(FocusGrade.chaotic));
        expect(report.currentEntropy, equals(0.0));
        expect(report.domainDistributions, isEmpty);
        expect(report.deepWorkBlocks, isEmpty);
        expect(report.entropyHistory, isEmpty);
        expect(report.insights, isEmpty);
      });

      test('empty report has stable forecast', () {
        final report = service.generateReport();
        expect(report.forecast.trend, equals(FocusTrend.stable));
        expect(report.forecast.confidence, equals(0.0));
      });
    });

    // -----------------------------------------------------------------------
    // Single session handling
    // -----------------------------------------------------------------------

    group('Single session', () {
      test('single session produces valid report', () {
        service.addSession(FocusSession(
          domain: 'Coding',
          startTime: DateTime(2026, 5, 1, 9, 0),
          durationMinutes: 60,
        ));
        final report = service.generateReport();
        expect(report.currentEntropy, equals(0.0));
        expect(report.focusGrade, equals(FocusGrade.laser));
        expect(report.totalContextSwitches, equals(0));
        expect(report.deepWorkBlocks, hasLength(1));
      });
    });

    // -----------------------------------------------------------------------
    // Sample data
    // -----------------------------------------------------------------------

    group('Sample data', () {
      test('loadSampleData populates sessions', () {
        service.loadSampleData();
        expect(service.sessions, isNotEmpty);
        expect(service.sessions.length, greaterThan(50));
      });

      test('sample data spans multiple days', () {
        service.loadSampleData();
        final dates = service.sessions
            .map((s) => DateTime(s.startTime.year, s.startTime.month, s.startTime.day))
            .toSet();
        expect(dates.length, greaterThanOrEqualTo(14));
      });

      test('sample data has multiple domains', () {
        service.loadSampleData();
        final domains = service.sessions.map((s) => s.domain).toSet();
        expect(domains.length, greaterThanOrEqualTo(5));
      });

      test('sample data produces report with entropy history', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(report.entropyHistory, isNotEmpty);
        expect(report.entropyHistory.length, greaterThanOrEqualTo(14));
      });

      test('sample data report has domain distributions', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(report.domainDistributions, isNotEmpty);
        final totalPct = report.domainDistributions
            .map((d) => d.percentage)
            .fold(0.0, (a, b) => a + b);
        expect(totalPct, closeTo(100.0, 0.1));
      });

      test('sample data has deep work blocks', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(report.deepWorkBlocks, isNotEmpty);
      });

      test('sample data flow score is reasonable', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(report.flowScore, greaterThan(0));
        expect(report.flowScore, lessThanOrEqualTo(100));
      });
    });

    // -----------------------------------------------------------------------
    // Domain distribution
    // -----------------------------------------------------------------------

    group('Domain Distribution', () {
      test('percentages sum to ~100', () {
        service.loadSampleData();
        final report = service.generateReport();
        final sum = report.domainDistributions
            .map((d) => d.percentage)
            .fold(0.0, (a, b) => a + b);
        expect(sum, closeTo(100.0, 0.1));
      });

      test('distributions sorted by total minutes descending', () {
        service.loadSampleData();
        final report = service.generateReport();
        for (int i = 1; i < report.domainDistributions.length; i++) {
          expect(
            report.domainDistributions[i - 1].totalMinutes,
            greaterThanOrEqualTo(report.domainDistributions[i].totalMinutes),
          );
        }
      });

      test('session counts match actual sessions', () {
        service.addSession(FocusSession(
          domain: 'A', startTime: DateTime(2026, 5, 1, 9, 0), durationMinutes: 30,
        ));
        service.addSession(FocusSession(
          domain: 'A', startTime: DateTime(2026, 5, 1, 10, 0), durationMinutes: 30,
        ));
        service.addSession(FocusSession(
          domain: 'B', startTime: DateTime(2026, 5, 1, 11, 0), durationMinutes: 30,
        ));
        final report = service.generateReport();
        final domA = report.domainDistributions.firstWhere((d) => d.domain == 'A');
        final domB = report.domainDistributions.firstWhere((d) => d.domain == 'B');
        expect(domA.sessionCount, equals(2));
        expect(domB.sessionCount, equals(1));
      });
    });

    // -----------------------------------------------------------------------
    // Report integrity
    // -----------------------------------------------------------------------

    group('Report integrity', () {
      test('deep work ratio is between 0 and 1', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(report.deepWorkRatio, greaterThanOrEqualTo(0.0));
        expect(report.deepWorkRatio, lessThanOrEqualTo(1.0));
      });

      test('weekly entropy is non-negative', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(report.weeklyEntropy, greaterThanOrEqualTo(0.0));
      });

      test('total deep work minutes is non-negative', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(report.totalDeepWorkMinutes, greaterThanOrEqualTo(0));
      });

      test('total context switches is non-negative', () {
        service.loadSampleData();
        final report = service.generateReport();
        expect(report.totalContextSwitches, greaterThanOrEqualTo(0));
      });
    });
  });
}

// Helper to build and return a report in a single expression.
FocusEntropyReport report(FocusEntropyReport Function() fn) => fn();
