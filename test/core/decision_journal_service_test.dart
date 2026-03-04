import 'package:flutter_test/flutter_test.dart';
import 'package:everything/models/decision_entry.dart';
import 'package:everything/core/services/decision_journal_service.dart';

// ── Test Helpers ──

DecisionEntry _makeEntry({
  String id = 'd1',
  DateTime? decidedAt,
  String title = 'Test decision',
  String description = 'A test decision',
  DecisionCategory category = DecisionCategory.career,
  ConfidenceLevel confidence = ConfidenceLevel.high,
  String expectedOutcome = 'Should go well',
  List<Alternative> alternatives = const [],
  String? context,
  DateTime? reviewDate,
  DecisionOutcome? outcome,
  DateTime? reviewedAt,
  String? reflection,
  String? lessonsLearned,
}) {
  return DecisionEntry(
    id: id,
    decidedAt: decidedAt ?? DateTime(2026, 1, 15, 10, 0),
    title: title,
    description: description,
    category: category,
    confidence: confidence,
    expectedOutcome: expectedOutcome,
    alternatives: alternatives,
    context: context,
    reviewDate: reviewDate,
    outcome: outcome,
    reviewedAt: reviewedAt,
    reflection: reflection,
    lessonsLearned: lessonsLearned,
  );
}

DecisionJournalService _makeService({List<DecisionEntry>? entries}) {
  return DecisionJournalService(entries: entries);
}

void main() {
  // ═══════════════════════════════════════════════════
  // Model Tests
  // ═══════════════════════════════════════════════════

  group('DecisionCategory', () {
    test('all values have labels and emojis', () {
      for (final cat in DecisionCategory.values) {
        expect(cat.label.isNotEmpty, true);
        expect(cat.emoji.isNotEmpty, true);
      }
    });

    test('fromString parses known values', () {
      expect(DecisionCategory.fromString('career'), DecisionCategory.career);
      expect(DecisionCategory.fromString('finance'), DecisionCategory.finance);
    });

    test('fromString returns other for unknown', () {
      expect(DecisionCategory.fromString('unknown'), DecisionCategory.other);
    });
  });

  group('ConfidenceLevel', () {
    test('values range from 1 to 5', () {
      expect(ConfidenceLevel.veryLow.value, 1);
      expect(ConfidenceLevel.veryHigh.value, 5);
    });

    test('fromValue round-trips', () {
      for (final level in ConfidenceLevel.values) {
        expect(ConfidenceLevel.fromValue(level.value), level);
      }
    });

    test('fromValue clamps to moderate for unknown', () {
      expect(ConfidenceLevel.fromValue(99), ConfidenceLevel.moderate);
    });

    test('all values have labels', () {
      for (final level in ConfidenceLevel.values) {
        expect(level.label.isNotEmpty, true);
      }
    });
  });

  group('DecisionOutcome', () {
    test('values range from 1 to 5', () {
      expect(DecisionOutcome.muchWorse.value, 1);
      expect(DecisionOutcome.muchBetter.value, 5);
    });

    test('isPositive for asExpected and above', () {
      expect(DecisionOutcome.muchWorse.isPositive, false);
      expect(DecisionOutcome.worse.isPositive, false);
      expect(DecisionOutcome.asExpected.isPositive, true);
      expect(DecisionOutcome.better.isPositive, true);
      expect(DecisionOutcome.muchBetter.isPositive, true);
    });

    test('all values have labels and emojis', () {
      for (final out in DecisionOutcome.values) {
        expect(out.label.isNotEmpty, true);
        expect(out.emoji.isNotEmpty, true);
      }
    });

    test('fromValue round-trips', () {
      for (final out in DecisionOutcome.values) {
        expect(DecisionOutcome.fromValue(out.value), out);
      }
    });
  });

  group('Alternative', () {
    test('toJson/fromJson round-trip', () {
      const alt = Alternative(
        description: 'Option B',
        reason: 'Too expensive',
      );
      final json = alt.toJson();
      final parsed = Alternative.fromJson(json);
      expect(parsed.description, 'Option B');
      expect(parsed.reason, 'Too expensive');
    });

    test('toJson omits null reason', () {
      const alt = Alternative(description: 'Simple');
      final json = alt.toJson();
      expect(json.containsKey('reason'), false);
    });

    test('equality', () {
      const a = Alternative(description: 'A', reason: 'R');
      const b = Alternative(description: 'A', reason: 'R');
      const c = Alternative(description: 'B', reason: 'R');
      expect(a, b);
      expect(a, isNot(c));
    });
  });

  group('DecisionEntry', () {
    test('isReviewed when outcome is set', () {
      final entry = _makeEntry();
      expect(entry.isReviewed, false);

      final reviewed =
          entry.copyWith(outcome: DecisionOutcome.asExpected);
      expect(reviewed.isReviewed, true);
    });

    test('isReviewDue when past review date and not reviewed', () {
      final entry = _makeEntry(
        reviewDate: DateTime(2020, 1, 1),
      );
      expect(entry.isReviewDue, true);
    });

    test('isReviewDue is false when already reviewed', () {
      final entry = _makeEntry(
        reviewDate: DateTime(2020, 1, 1),
        outcome: DecisionOutcome.better,
      );
      expect(entry.isReviewDue, false);
    });

    test('isReviewDue is false when review date is in future', () {
      final entry = _makeEntry(
        reviewDate: DateTime(2099, 1, 1),
      );
      expect(entry.isReviewDue, false);
    });

    test('wasCalibrated: high confidence + positive outcome = true', () {
      final entry = _makeEntry(
        confidence: ConfidenceLevel.high,
        outcome: DecisionOutcome.better,
      );
      expect(entry.wasCalibrated, true);
    });

    test('wasCalibrated: high confidence + negative outcome = false', () {
      final entry = _makeEntry(
        confidence: ConfidenceLevel.high,
        outcome: DecisionOutcome.worse,
      );
      expect(entry.wasCalibrated, false);
    });

    test('wasCalibrated: low confidence + negative outcome = true', () {
      final entry = _makeEntry(
        confidence: ConfidenceLevel.low,
        outcome: DecisionOutcome.worse,
      );
      expect(entry.wasCalibrated, true);
    });

    test('wasCalibrated: low confidence + positive outcome = false', () {
      final entry = _makeEntry(
        confidence: ConfidenceLevel.low,
        outcome: DecisionOutcome.better,
      );
      expect(entry.wasCalibrated, false);
    });

    test('wasCalibrated: moderate confidence = null', () {
      final entry = _makeEntry(
        confidence: ConfidenceLevel.moderate,
        outcome: DecisionOutcome.asExpected,
      );
      expect(entry.wasCalibrated, null);
    });

    test('wasCalibrated: no outcome = null', () {
      final entry = _makeEntry();
      expect(entry.wasCalibrated, null);
    });

    test('toJson/fromJson round-trip', () {
      final entry = _makeEntry(
        id: 'test-1',
        title: 'Switch jobs',
        description: 'Moving to new company',
        category: DecisionCategory.career,
        confidence: ConfidenceLevel.high,
        expectedOutcome: 'Better growth',
        alternatives: [
          const Alternative(description: 'Stay', reason: 'Comfort'),
        ],
        context: 'Feeling stuck',
        reviewDate: DateTime(2026, 3, 15),
        outcome: DecisionOutcome.better,
        reviewedAt: DateTime(2026, 3, 20),
        reflection: 'Good call',
        lessonsLearned: 'Trust instincts',
      );

      final json = entry.toJson();
      final parsed = DecisionEntry.fromJson(json);

      expect(parsed.id, 'test-1');
      expect(parsed.title, 'Switch jobs');
      expect(parsed.category, DecisionCategory.career);
      expect(parsed.confidence, ConfidenceLevel.high);
      expect(parsed.alternatives.length, 1);
      expect(parsed.outcome, DecisionOutcome.better);
      expect(parsed.reflection, 'Good call');
      expect(parsed.lessonsLearned, 'Trust instincts');
    });

    test('toJson omits null fields', () {
      final entry = _makeEntry();
      final json = entry.toJson();
      expect(json.containsKey('context'), false);
      expect(json.containsKey('outcome'), false);
      expect(json.containsKey('reflection'), false);
    });

    test('fromJson handles missing fields gracefully', () {
      final entry = DecisionEntry.fromJson({'id': 'x'});
      expect(entry.id, 'x');
      expect(entry.title, '');
      expect(entry.category, DecisionCategory.other);
      expect(entry.confidence, ConfidenceLevel.moderate);
    });

    test('encodeList/decodeList round-trip', () {
      final entries = [
        _makeEntry(id: 'a', title: 'First'),
        _makeEntry(id: 'b', title: 'Second'),
      ];
      final json = DecisionEntry.encodeList(entries);
      final parsed = DecisionEntry.decodeList(json);
      expect(parsed.length, 2);
      expect(parsed[0].title, 'First');
      expect(parsed[1].title, 'Second');
    });

    test('equality by id', () {
      final a = _makeEntry(id: 'same');
      final b = _makeEntry(id: 'same', title: 'Different');
      final c = _makeEntry(id: 'other');
      expect(a, b);
      expect(a, isNot(c));
    });

    test('copyWith preserves unmodified fields', () {
      final entry = _makeEntry(
        id: 'd1',
        title: 'Original',
        category: DecisionCategory.finance,
      );
      final updated = entry.copyWith(title: 'Updated');
      expect(updated.title, 'Updated');
      expect(updated.id, 'd1');
      expect(updated.category, DecisionCategory.finance);
    });

    test('toString includes key info', () {
      final entry = _makeEntry(title: 'Test');
      expect(entry.toString(), contains('Test'));
      expect(entry.toString(), contains('pending'));

      final reviewed =
          entry.copyWith(outcome: DecisionOutcome.asExpected);
      expect(reviewed.toString(), contains('reviewed'));
    });
  });

  // ═══════════════════════════════════════════════════
  // Service Tests
  // ═══════════════════════════════════════════════════

  group('DecisionJournalService - CRUD', () {
    test('starts empty', () {
      final svc = _makeService();
      expect(svc.count, 0);
      expect(svc.entries, isEmpty);
    });

    test('addDecision creates entry', () {
      final svc = _makeService();
      final entry = svc.addDecision(
        id: 'd1',
        title: 'Test',
        description: 'A test',
        category: DecisionCategory.career,
        confidence: ConfidenceLevel.high,
        expectedOutcome: 'Good',
      );
      expect(svc.count, 1);
      expect(entry.title, 'Test');
      expect(entry.category, DecisionCategory.career);
    });

    test('addDecision trims whitespace', () {
      final svc = _makeService();
      final entry = svc.addDecision(
        id: 'd1',
        title: '  Padded  ',
        description: '  Desc  ',
        category: DecisionCategory.other,
        confidence: ConfidenceLevel.moderate,
        expectedOutcome: '  Outcome  ',
      );
      expect(entry.title, 'Padded');
      expect(entry.description, 'Desc');
      expect(entry.expectedOutcome, 'Outcome');
    });

    test('addDecision rejects empty title', () {
      final svc = _makeService();
      expect(
        () => svc.addDecision(
          id: 'd1',
          title: '',
          description: 'Desc',
          category: DecisionCategory.other,
          confidence: ConfidenceLevel.moderate,
          expectedOutcome: 'Outcome',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addDecision rejects duplicate id', () {
      final svc = _makeService();
      svc.addDecision(
        id: 'd1',
        title: 'First',
        description: 'Desc',
        category: DecisionCategory.other,
        confidence: ConfidenceLevel.moderate,
        expectedOutcome: 'Outcome',
      );
      expect(
        () => svc.addDecision(
          id: 'd1',
          title: 'Second',
          description: 'Desc',
          category: DecisionCategory.other,
          confidence: ConfidenceLevel.moderate,
          expectedOutcome: 'Outcome',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('addDecision sets default review date', () {
      final svc = DecisionJournalService(
        defaultReviewPeriod: const Duration(days: 7),
      );
      final entry = svc.addDecision(
        id: 'd1',
        title: 'Test',
        description: 'Desc',
        category: DecisionCategory.other,
        confidence: ConfidenceLevel.moderate,
        expectedOutcome: 'Outcome',
        decidedAt: DateTime(2026, 1, 1),
      );
      expect(entry.reviewDate, DateTime(2026, 1, 8));
    });

    test('addDecision skips review date when setDefaultReview=false', () {
      final svc = _makeService();
      final entry = svc.addDecision(
        id: 'd1',
        title: 'Test',
        description: 'Desc',
        category: DecisionCategory.other,
        confidence: ConfidenceLevel.moderate,
        expectedOutcome: 'Outcome',
        setDefaultReview: false,
      );
      expect(entry.reviewDate, null);
    });

    test('addDecision with alternatives', () {
      final svc = _makeService();
      final entry = svc.addDecision(
        id: 'd1',
        title: 'Test',
        description: 'Desc',
        category: DecisionCategory.career,
        confidence: ConfidenceLevel.high,
        expectedOutcome: 'Outcome',
        alternatives: [
          const Alternative(description: 'Alt A', reason: 'Cheaper'),
          const Alternative(description: 'Alt B'),
        ],
      );
      expect(entry.alternatives.length, 2);
      expect(entry.alternatives[0].reason, 'Cheaper');
    });

    test('getById returns entry or null', () {
      final svc = _makeService(entries: [_makeEntry(id: 'd1')]);
      expect(svc.getById('d1'), isNotNull);
      expect(svc.getById('nonexistent'), null);
    });

    test('updateDecision modifies entry', () {
      final svc = _makeService(entries: [_makeEntry(id: 'd1')]);
      final updated = svc.updateDecision('d1', title: 'New title');
      expect(updated.title, 'New title');
      expect(svc.getById('d1')!.title, 'New title');
    });

    test('updateDecision throws on missing id', () {
      final svc = _makeService();
      expect(
        () => svc.updateDecision('nonexistent', title: 'X'),
        throwsA(isA<StateError>()),
      );
    });

    test('removeDecision returns true for existing', () {
      final svc = _makeService(entries: [_makeEntry(id: 'd1')]);
      expect(svc.removeDecision('d1'), true);
      expect(svc.count, 0);
    });

    test('removeDecision returns false for missing', () {
      final svc = _makeService();
      expect(svc.removeDecision('nonexistent'), false);
    });

    test('entries list is unmodifiable', () {
      final svc = _makeService(entries: [_makeEntry()]);
      expect(() => svc.entries.add(_makeEntry(id: 'x')),
          throwsA(isA<UnsupportedError>()));
    });
  });

  group('DecisionJournalService - Outcome Recording', () {
    test('recordOutcome updates entry', () {
      final svc = _makeService(entries: [_makeEntry(id: 'd1')]);
      final updated = svc.recordOutcome(
        'd1',
        outcome: DecisionOutcome.better,
        reflection: 'It worked out',
        lessonsLearned: 'Trust data',
      );
      expect(updated.isReviewed, true);
      expect(updated.outcome, DecisionOutcome.better);
      expect(updated.reflection, 'It worked out');
      expect(updated.lessonsLearned, 'Trust data');
      expect(updated.reviewedAt, isNotNull);
    });

    test('recordOutcome throws on missing id', () {
      final svc = _makeService();
      expect(
        () => svc.recordOutcome('x', outcome: DecisionOutcome.asExpected),
        throwsA(isA<StateError>()),
      );
    });

    test('recordOutcome trims reflection', () {
      final svc = _makeService(entries: [_makeEntry(id: 'd1')]);
      final updated = svc.recordOutcome(
        'd1',
        outcome: DecisionOutcome.asExpected,
        reflection: '  Spaced  ',
      );
      expect(updated.reflection, 'Spaced');
    });
  });

  group('DecisionJournalService - Queries', () {
    test('pendingReviews returns unreviewed with review date', () {
      final svc = _makeService(entries: [
        _makeEntry(id: 'd1', reviewDate: DateTime(2099, 1, 1)),
        _makeEntry(id: 'd2', reviewDate: DateTime(2099, 6, 1)),
        _makeEntry(
          id: 'd3',
          reviewDate: DateTime(2099, 1, 1),
          outcome: DecisionOutcome.asExpected,
        ),
      ]);
      final pending = svc.pendingReviews;
      expect(pending.length, 2);
      expect(pending[0].id, 'd1');
    });

    test('overdueReviews returns past-due unreviewed', () {
      final svc = _makeService(entries: [
        _makeEntry(id: 'd1', reviewDate: DateTime(2020, 1, 1)),
        _makeEntry(id: 'd2', reviewDate: DateTime(2099, 1, 1)),
      ]);
      expect(svc.overdueReviews.length, 1);
      expect(svc.overdueReviews[0].id, 'd1');
    });

    test('byCategory filters correctly', () {
      final svc = _makeService(entries: [
        _makeEntry(id: 'd1', category: DecisionCategory.career),
        _makeEntry(id: 'd2', category: DecisionCategory.finance),
        _makeEntry(id: 'd3', category: DecisionCategory.career),
      ]);
      expect(svc.byCategory(DecisionCategory.career).length, 2);
      expect(svc.byCategory(DecisionCategory.health).length, 0);
    });

    test('inDateRange returns entries in range', () {
      final svc = _makeService(entries: [
        _makeEntry(id: 'd1', decidedAt: DateTime(2026, 1, 10)),
        _makeEntry(id: 'd2', decidedAt: DateTime(2026, 1, 20)),
        _makeEntry(id: 'd3', decidedAt: DateTime(2026, 2, 10)),
      ]);
      final results =
          svc.inDateRange(DateTime(2026, 1, 5), DateTime(2026, 1, 25));
      expect(results.length, 2);
    });

    test('search matches title, description, context, reflection', () {
      final svc = _makeService(entries: [
        _makeEntry(id: 'd1', title: 'Job switch'),
        _makeEntry(id: 'd2', description: 'About my job change'),
        _makeEntry(id: 'd3', context: 'Job market is hot'),
        _makeEntry(
          id: 'd4',
          reflection: 'The job worked out',
          outcome: DecisionOutcome.better,
        ),
        _makeEntry(id: 'd5', title: 'Unrelated'),
      ]);
      expect(svc.search('job').length, 4);
      expect(svc.search('unrelated').length, 1);
    });

    test('search returns empty for blank query', () {
      final svc = _makeService(entries: [_makeEntry()]);
      expect(svc.search(''), isEmpty);
      expect(svc.search('   '), isEmpty);
    });

    test('reviewedDecisions returns only reviewed', () {
      final svc = _makeService(entries: [
        _makeEntry(id: 'd1'),
        _makeEntry(
            id: 'd2', outcome: DecisionOutcome.asExpected),
      ]);
      expect(svc.reviewedDecisions.length, 1);
    });
  });

  group('DecisionJournalService - Analytics', () {
    test('getStats returns correct counts', () {
      final svc = _makeService(entries: [
        _makeEntry(
          id: 'd1',
          category: DecisionCategory.career,
          confidence: ConfidenceLevel.high,
        ),
        _makeEntry(
          id: 'd2',
          category: DecisionCategory.career,
          confidence: ConfidenceLevel.low,
          outcome: DecisionOutcome.better,
          reviewDate: DateTime(2020, 1, 1),
        ),
        _makeEntry(
          id: 'd3',
          category: DecisionCategory.finance,
          confidence: ConfidenceLevel.moderate,
          reviewDate: DateTime(2020, 1, 1),
        ),
      ]);
      final stats = svc.getStats();
      expect(stats.totalDecisions, 3);
      expect(stats.reviewedDecisions, 1);
      expect(stats.overdueReviews, 1); // d3
      expect(stats.byCategory[DecisionCategory.career], 2);
      expect(stats.byCategory[DecisionCategory.finance], 1);
      expect(stats.avgOutcome, 4.0); // better = 4
    });

    test('getStats empty journal', () {
      final svc = _makeService();
      final stats = svc.getStats();
      expect(stats.totalDecisions, 0);
      expect(stats.avgConfidence, 0);
      expect(stats.reviewCompletionRate, 0);
    });

    test('getCategoryStats computes correctly', () {
      final svc = _makeService(entries: [
        _makeEntry(
          id: 'd1',
          category: DecisionCategory.finance,
          confidence: ConfidenceLevel.high,
          outcome: DecisionOutcome.better,
        ),
        _makeEntry(
          id: 'd2',
          category: DecisionCategory.finance,
          confidence: ConfidenceLevel.high,
          outcome: DecisionOutcome.worse,
        ),
      ]);
      final stats = svc.getCategoryStats(DecisionCategory.finance);
      expect(stats.total, 2);
      expect(stats.reviewed, 2);
      expect(stats.positiveOutcomes, 1);
      expect(stats.avgConfidence, 4.0);
    });

    test('getCalibrationReport empty returns insufficient data', () {
      final svc = _makeService();
      final report = svc.getCalibrationReport();
      expect(report.sampleSize, 0);
      expect(report.calibrationLabel, 'Insufficient data');
    });

    test('getCalibrationReport detects overconfidence', () {
      final svc = _makeService(entries: [
        _makeEntry(
          id: 'd1',
          confidence: ConfidenceLevel.veryHigh,
          outcome: DecisionOutcome.worse,
        ),
        _makeEntry(
          id: 'd2',
          confidence: ConfidenceLevel.high,
          outcome: DecisionOutcome.muchWorse,
        ),
      ]);
      final report = svc.getCalibrationReport();
      expect(report.overconfidentCount, 2);
      expect(report.calibratedCount, 0);
    });

    test('getCalibrationReport detects underconfidence', () {
      final svc = _makeService(entries: [
        _makeEntry(
          id: 'd1',
          confidence: ConfidenceLevel.veryLow,
          outcome: DecisionOutcome.better,
        ),
        _makeEntry(
          id: 'd2',
          confidence: ConfidenceLevel.low,
          outcome: DecisionOutcome.muchBetter,
        ),
      ]);
      final report = svc.getCalibrationReport();
      expect(report.underconfidentCount, 2);
    });

    test('getCalibrationReport good calibration', () {
      final entries = <DecisionEntry>[];
      for (var i = 0; i < 6; i++) {
        entries.add(_makeEntry(
          id: 'd$i',
          confidence: ConfidenceLevel.high,
          outcome: DecisionOutcome.better,
        ));
      }
      final svc = _makeService(entries: entries);
      final report = svc.getCalibrationReport();
      expect(report.calibratedCount, 6);
      expect(report.calibrationRate, 1.0);
      expect(report.calibrationLabel, 'Excellent');
    });

    test('getReviewStreak counts consecutive reviews', () {
      final svc = _makeService(entries: [
        _makeEntry(
          id: 'd1',
          decidedAt: DateTime(2026, 1, 1),
          outcome: DecisionOutcome.asExpected,
        ),
        _makeEntry(
          id: 'd2',
          decidedAt: DateTime(2026, 1, 5),
        ), // not reviewed — breaks streak
        _makeEntry(
          id: 'd3',
          decidedAt: DateTime(2026, 1, 10),
          outcome: DecisionOutcome.better,
        ),
        _makeEntry(
          id: 'd4',
          decidedAt: DateTime(2026, 1, 15),
          outcome: DecisionOutcome.asExpected,
        ),
      ]);
      final streak = svc.getReviewStreak();
      expect(streak.current, 2); // d4 + d3 (newest first, consecutive)
      expect(streak.longest, 2);
    });

    test('getReviewStreak empty journal', () {
      final svc = _makeService();
      final streak = svc.getReviewStreak();
      expect(streak.current, 0);
      expect(streak.longest, 0);
    });

    test('getQualityScore empty returns zero', () {
      final svc = _makeService();
      final score = svc.getQualityScore();
      expect(score.overall, 0);
      expect(score.label, 'No data');
    });

    test('getQualityScore with perfect data', () {
      final svc = _makeService(entries: [
        _makeEntry(
          id: 'd1',
          confidence: ConfidenceLevel.high,
          outcome: DecisionOutcome.better,
          reflection: 'Good',
          lessonsLearned: 'Learned',
        ),
      ]);
      final score = svc.getQualityScore();
      // calibration: 100 (calibrated), outcomes: 75 (better=4, norm=(4-1)/4=75%),
      // review: 100, reflection: 100
      expect(score.calibration, 100);
      expect(score.outcomes, 75);
      expect(score.reviewCompletion, 100);
      expect(score.reflectionDepth, 100);
      expect(score.overall, closeTo(93.75, 0.01));
      expect(score.label, 'Excellent');
    });

    test('getQualityScore with mixed data', () {
      final svc = _makeService(entries: [
        _makeEntry(
          id: 'd1',
          confidence: ConfidenceLevel.high,
          outcome: DecisionOutcome.worse, // miscalibrated
        ),
        _makeEntry(id: 'd2'), // unreviewed
      ]);
      final score = svc.getQualityScore();
      expect(score.reviewCompletion, 50); // 1/2 reviewed
      expect(score.calibration, 0); // 0 calibrated out of 1
    });

    test('topCategories ranked by count', () {
      final svc = _makeService(entries: [
        _makeEntry(id: 'd1', category: DecisionCategory.career),
        _makeEntry(id: 'd2', category: DecisionCategory.career),
        _makeEntry(id: 'd3', category: DecisionCategory.finance),
        _makeEntry(id: 'd4', category: DecisionCategory.career),
      ]);
      final top = svc.topCategories(limit: 2);
      expect(top.length, 2);
      expect(top[0].key, DecisionCategory.career);
      expect(top[0].value, 3);
      expect(top[1].key, DecisionCategory.finance);
    });

    test('allLessonsLearned collects non-empty lessons', () {
      final svc = _makeService(entries: [
        _makeEntry(id: 'd1', lessonsLearned: 'Lesson 1'),
        _makeEntry(id: 'd2'), // no lessons
        _makeEntry(id: 'd3', lessonsLearned: 'Lesson 3'),
      ]);
      final lessons = svc.allLessonsLearned();
      expect(lessons.length, 2);
      expect(lessons, contains('Lesson 1'));
      expect(lessons, contains('Lesson 3'));
    });
  });

  group('DecisionJournalService - Persistence', () {
    test('exportToJson/importFromJson round-trip', () {
      final svc = _makeService();
      svc.addDecision(
        id: 'p1',
        title: 'Export test',
        description: 'Testing',
        category: DecisionCategory.technology,
        confidence: ConfidenceLevel.moderate,
        expectedOutcome: 'Works',
        setDefaultReview: false,
      );
      svc.addDecision(
        id: 'p2',
        title: 'Another',
        description: 'Testing 2',
        category: DecisionCategory.health,
        confidence: ConfidenceLevel.high,
        expectedOutcome: 'Also works',
        setDefaultReview: false,
      );

      final json = svc.exportToJson();
      final svc2 = _makeService();
      svc2.importFromJson(json);

      expect(svc2.count, 2);
      expect(svc2.getById('p1')!.title, 'Export test');
      expect(svc2.getById('p2')!.category, DecisionCategory.health);
    });

    test('clear removes all entries', () {
      final svc = _makeService(entries: [
        _makeEntry(id: 'd1'),
        _makeEntry(id: 'd2'),
      ]);
      svc.clear();
      expect(svc.count, 0);
    });

    test('constructor with existing entries', () {
      final entries = [
        _makeEntry(id: 'a'),
        _makeEntry(id: 'b'),
      ];
      final svc = _makeService(entries: entries);
      expect(svc.count, 2);
      // Mutating original list shouldn't affect service
      entries.add(_makeEntry(id: 'c'));
      expect(svc.count, 2);
    });
  });

  group('DecisionJournalService - Edge Cases', () {
    test('addDecision rejects whitespace-only description', () {
      final svc = _makeService();
      expect(
        () => svc.addDecision(
          id: 'd1',
          title: 'Valid',
          description: '   ',
          category: DecisionCategory.other,
          confidence: ConfidenceLevel.moderate,
          expectedOutcome: 'Outcome',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('addDecision rejects whitespace-only expected outcome', () {
      final svc = _makeService();
      expect(
        () => svc.addDecision(
          id: 'd1',
          title: 'Valid',
          description: 'Valid desc',
          category: DecisionCategory.other,
          confidence: ConfidenceLevel.moderate,
          expectedOutcome: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('recentDecisions respects day parameter', () {
      final svc = _makeService(entries: [
        _makeEntry(id: 'd1', decidedAt: DateTime.now()),
        _makeEntry(
          id: 'd2',
          decidedAt: DateTime.now().subtract(const Duration(days: 100)),
        ),
      ]);
      expect(svc.recentDecisions(7).length, 1);
      expect(svc.recentDecisions(365).length, 2);
    });

    test('search is case insensitive', () {
      final svc = _makeService(entries: [
        _makeEntry(id: 'd1', title: 'CAREER Move'),
      ]);
      expect(svc.search('career').length, 1);
      expect(svc.search('CAREER').length, 1);
      expect(svc.search('Career').length, 1);
    });

    test('getCategoryStats for empty category', () {
      final svc = _makeService();
      final stats = svc.getCategoryStats(DecisionCategory.creative);
      expect(stats.total, 0);
      expect(stats.reviewed, 0);
      expect(stats.reviewRate, 0);
      expect(stats.successRate, 0);
    });
  });
}
