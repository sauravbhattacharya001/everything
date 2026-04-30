import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/regret_minimization_service.dart';

void main() {
  late RegretMinimizationService service;

  setUp(() {
    service = RegretMinimizationService();
  });

  group('RegretMinimizationService', () {
    group('Decision Recording', () {
      test('records decisions', () {
        final decision = Decision(
          id: 'test1',
          timestamp: DateTime.now(),
          title: 'Test Decision',
          description: 'A test decision',
          domain: DecisionDomain.career,
          stakes: StakesLevel.moderate,
          alternatives: ['A', 'B', 'C'],
          chosenOption: 'A',
          reasoning: 'Seemed best',
          confidenceLevel: 0.7,
          emotionsAtTime: ['calm'],
          wasReversible: true,
        );
        service.recordDecision(decision);
        expect(service.decisions.length, 1);
        expect(service.decisions.first.title, 'Test Decision');
      });

      test('records outcome for existing decision', () {
        final decision = Decision(
          id: 'test2',
          timestamp: DateTime.now().subtract(const Duration(days: 60)),
          title: 'Past Decision',
          description: 'Happened a while ago',
          domain: DecisionDomain.health,
          stakes: StakesLevel.low,
          alternatives: ['X', 'Y'],
          chosenOption: 'X',
          reasoning: 'Health first',
          confidenceLevel: 0.8,
          emotionsAtTime: ['hopeful'],
          wasReversible: true,
        );
        service.recordDecision(decision);

        final outcome = DecisionOutcome(
          recordedAt: DateTime.now(),
          satisfaction: OutcomeSatisfaction.satisfied,
          whatHappened: 'Worked out well',
          whatSurprised: 'How easy it was',
          regretType: null,
          regretIntensity: 0.0,
          lessonLearned: 'Trust yourself',
          wouldChooseSameAgain: true,
        );
        service.recordOutcome('test2', outcome);

        expect(service.decisions.first.outcome, isNotNull);
        expect(service.decisions.first.outcome!.satisfaction,
            OutcomeSatisfaction.satisfied);
      });

      test('ignores outcome for non-existent decision', () {
        final outcome = DecisionOutcome(
          recordedAt: DateTime.now(),
          satisfaction: OutcomeSatisfaction.neutral,
          whatHappened: 'Nothing',
          whatSurprised: 'Nothing',
          regretIntensity: 0.0,
          wouldChooseSameAgain: true,
        );
        service.recordOutcome('nonexistent', outcome);
        expect(service.decisions, isEmpty);
      });
    });

    group('Pending Reviews', () {
      test('returns decisions older than 30 days without outcomes', () {
        service.recordDecision(Decision(
          id: 'old',
          timestamp: DateTime.now().subtract(const Duration(days: 45)),
          title: 'Old Decision',
          description: 'Old',
          domain: DecisionDomain.finance,
          stakes: StakesLevel.moderate,
          alternatives: ['A'],
          chosenOption: 'A',
          reasoning: 'Seemed right',
          confidenceLevel: 0.5,
          emotionsAtTime: [],
          wasReversible: true,
        ));
        service.recordDecision(Decision(
          id: 'recent',
          timestamp: DateTime.now().subtract(const Duration(days: 5)),
          title: 'Recent Decision',
          description: 'Recent',
          domain: DecisionDomain.finance,
          stakes: StakesLevel.low,
          alternatives: ['B'],
          chosenOption: 'B',
          reasoning: 'Quick choice',
          confidenceLevel: 0.9,
          emotionsAtTime: [],
          wasReversible: true,
        ));

        final pending = service.getPendingReviews();
        expect(pending.length, 1);
        expect(pending.first.id, 'old');
      });
    });

    group('Regret Analysis', () {
      test('computes zero regret when no outcomes', () {
        expect(service.computeRegretScore(), 0.0);
      });

      test('computes weighted regret score', () {
        service.recordDecision(Decision(
          id: 'r1',
          timestamp: DateTime.now().subtract(const Duration(days: 90)),
          title: 'High stakes regret',
          description: 'Bad choice',
          domain: DecisionDomain.career,
          stakes: StakesLevel.high,
          alternatives: ['A', 'B'],
          chosenOption: 'A',
          reasoning: 'Seemed good',
          confidenceLevel: 0.6,
          emotionsAtTime: [],
          wasReversible: false,
        ));
        service.recordOutcome(
          'r1',
          DecisionOutcome(
            recordedAt: DateTime.now(),
            satisfaction: OutcomeSatisfaction.regretful,
            whatHappened: 'Terrible outcome',
            whatSurprised: 'Everything',
            regretType: RegretType.actionRegret,
            regretIntensity: 0.8,
            wouldChooseSameAgain: false,
          ),
        );

        final score = service.computeRegretScore();
        expect(score, greaterThan(0));
        expect(score, lessThanOrEqualTo(100));
      });

      test('detects regret patterns', () {
        // Add multiple inaction regrets in career
        for (int i = 0; i < 3; i++) {
          service.recordDecision(Decision(
            id: 'pattern_$i',
            timestamp:
                DateTime.now().subtract(Duration(days: 100 + i * 30)),
            title: 'Missed opportunity $i',
            description: 'Didn\'t act',
            domain: DecisionDomain.career,
            stakes: StakesLevel.moderate,
            alternatives: ['Act', 'Skip'],
            chosenOption: 'Skip',
            reasoning: 'Too risky',
            confidenceLevel: 0.3,
            emotionsAtTime: ['anxious'],
            wasReversible: false,
          ));
          service.recordOutcome(
            'pattern_$i',
            DecisionOutcome(
              recordedAt: DateTime.now().subtract(Duration(days: 50 + i * 20)),
              satisfaction: OutcomeSatisfaction.regretful,
              whatHappened: 'Missed out',
              whatSurprised: 'It wasn\'t that risky',
              regretType: RegretType.inactionRegret,
              regretIntensity: 0.7,
              wouldChooseSameAgain: false,
            ),
          );
        }

        final patterns = service.detectRegretPatterns();
        expect(patterns, isNotEmpty);
        expect(patterns.first.type, RegretType.inactionRegret);
        expect(patterns.first.domain, DecisionDomain.career);
        expect(patterns.first.occurrences, 3);
      });

      test('domain satisfaction computation', () {
        service.loadSampleData();
        final domainSat = service.getDomainSatisfaction();
        expect(domainSat, isNotEmpty);
        // Health domain should exist with outcomes
        expect(domainSat.containsKey(DecisionDomain.health), true);
      });
    });

    group('Bias Detection', () {
      test('detects overconfidence bias', () {
        service.recordDecision(Decision(
          id: 'overconf',
          timestamp: DateTime.now().subtract(const Duration(days: 60)),
          title: 'Very confident bad decision',
          description: 'Was sure it would work',
          domain: DecisionDomain.finance,
          stakes: StakesLevel.high,
          alternatives: ['A', 'B'],
          chosenOption: 'A',
          reasoning: 'Absolutely certain this is right',
          confidenceLevel: 0.95,
          emotionsAtTime: ['certain'],
          wasReversible: true,
        ));
        service.recordOutcome(
          'overconf',
          DecisionOutcome(
            recordedAt: DateTime.now(),
            satisfaction: OutcomeSatisfaction.disappointed,
            whatHappened: 'Failed completely',
            whatSurprised: 'How wrong I was',
            regretType: RegretType.actionRegret,
            regretIntensity: 0.6,
            wouldChooseSameAgain: false,
          ),
        );

        final biases = service.getBiasDetections();
        expect(biases.any((b) => b.bias == CognitiveBias.overconfidence), true);
      });

      test('detects sunk cost fallacy', () {
        service.recordDecision(Decision(
          id: 'sunk',
          timestamp: DateTime.now().subtract(const Duration(days: 40)),
          title: 'Kept going despite signs',
          description: 'Continued project',
          domain: DecisionDomain.creative,
          stakes: StakesLevel.moderate,
          alternatives: ['Continue', 'Quit'],
          chosenOption: 'Continue',
          reasoning: 'Already invested too much time, come this far',
          confidenceLevel: 0.5,
          emotionsAtTime: ['stubborn'],
          wasReversible: true,
        ));
        service.recordOutcome(
          'sunk',
          DecisionOutcome(
            recordedAt: DateTime.now(),
            satisfaction: OutcomeSatisfaction.neutral,
            whatHappened: 'Mediocre result',
            whatSurprised: 'Could have started fresh sooner',
            regretType: RegretType.methodRegret,
            regretIntensity: 0.3,
            wouldChooseSameAgain: false,
          ),
        );

        final biases = service.getBiasDetections();
        expect(
            biases.any((b) => b.bias == CognitiveBias.sunkCostFallacy), true);
      });

      test('detects present bias', () {
        service.recordDecision(Decision(
          id: 'present',
          timestamp: DateTime.now().subtract(const Duration(days: 30)),
          title: 'Impulsive purchase',
          description: 'Bought something on impulse',
          domain: DecisionDomain.finance,
          stakes: StakesLevel.low,
          alternatives: ['Buy now', 'Wait a week', 'Skip'],
          chosenOption: 'Buy now',
          reasoning: 'Want it now',
          confidenceLevel: 0.6,
          emotionsAtTime: ['excited', 'impatient'],
          wasReversible: true,
        ));
        service.recordOutcome(
          'present',
          DecisionOutcome(
            recordedAt: DateTime.now(),
            satisfaction: OutcomeSatisfaction.disappointed,
            whatHappened: 'Never used it',
            whatSurprised: 'How quickly the excitement faded',
            regretType: RegretType.actionRegret,
            regretIntensity: 0.4,
            wouldChooseSameAgain: false,
          ),
        );

        final biases = service.getBiasDetections();
        expect(biases.any((b) => b.bias == CognitiveBias.presentBias), true);
      });

      test('detects bandwagon effect', () {
        service.recordDecision(Decision(
          id: 'bandwagon',
          timestamp: DateTime.now().subtract(const Duration(days: 50)),
          title: 'Followed the crowd',
          description: 'Did what everyone else was doing',
          domain: DecisionDomain.lifestyle,
          stakes: StakesLevel.low,
          alternatives: ['Follow crowd', 'Do own thing'],
          chosenOption: 'Follow crowd',
          reasoning: 'Everyone says it works',
          confidenceLevel: 0.7,
          emotionsAtTime: ['peer pressure'],
          wasReversible: true,
          externalPressure: 'All friends are doing it',
        ));
        service.recordOutcome(
          'bandwagon',
          DecisionOutcome(
            recordedAt: DateTime.now(),
            satisfaction: OutcomeSatisfaction.disappointed,
            whatHappened: 'Didn\'t fit my life at all',
            whatSurprised: 'How different my needs were',
            regretType: RegretType.methodRegret,
            regretIntensity: 0.5,
            wouldChooseSameAgain: false,
          ),
        );

        final biases = service.getBiasDetections();
        expect(
            biases.any((b) => b.bias == CognitiveBias.bandwagonEffect), true);
      });

      test('bias profile counts occurrences', () {
        service.loadSampleData();
        final profile = service.getBiasProfile();
        expect(profile, isNotEmpty);
        for (final count in profile.values) {
          expect(count, greaterThan(0));
        }
      });
    });

    group('Wisdom Generation', () {
      test('generates wisdom after sample data', () {
        service.loadSampleData();
        expect(service.wisdomPrinciples, isNotEmpty);
      });

      test('generates inaction dominance principle', () {
        // Create scenario with more inaction regrets
        for (int i = 0; i < 4; i++) {
          service.recordDecision(Decision(
            id: 'inaction_$i',
            timestamp:
                DateTime.now().subtract(Duration(days: 100 + i * 20)),
            title: 'Didn\'t act $i',
            description: 'Held back',
            domain: DecisionDomain.career,
            stakes: StakesLevel.moderate,
            alternatives: ['Act', 'Hold'],
            chosenOption: 'Hold',
            reasoning: 'Safe choice',
            confidenceLevel: 0.3,
            emotionsAtTime: ['fearful'],
            wasReversible: false,
          ));
          service.recordOutcome(
            'inaction_$i',
            DecisionOutcome(
              recordedAt: DateTime.now().subtract(Duration(days: 50 + i * 10)),
              satisfaction: OutcomeSatisfaction.regretful,
              whatHappened: 'Missed opportunity',
              whatSurprised: 'How easy it would have been',
              regretType: RegretType.inactionRegret,
              regretIntensity: 0.7,
              wouldChooseSameAgain: false,
            ),
          );
        }
        // Add one action regret for contrast
        service.recordDecision(Decision(
          id: 'action_0',
          timestamp: DateTime.now().subtract(const Duration(days: 80)),
          title: 'Acted rashly',
          description: 'Jumped in',
          domain: DecisionDomain.finance,
          stakes: StakesLevel.moderate,
          alternatives: ['Act', 'Wait'],
          chosenOption: 'Act',
          reasoning: 'YOLO',
          confidenceLevel: 0.9,
          emotionsAtTime: ['excited'],
          wasReversible: true,
        ));
        service.recordOutcome(
          'action_0',
          DecisionOutcome(
            recordedAt: DateTime.now().subtract(const Duration(days: 30)),
            satisfaction: OutcomeSatisfaction.disappointed,
            whatHappened: 'Lost money',
            whatSurprised: 'Should have waited',
            regretType: RegretType.actionRegret,
            regretIntensity: 0.5,
            wouldChooseSameAgain: false,
          ),
        );

        final principles = service.wisdomPrinciples;
        expect(
          principles.any((p) => p.id == 'inaction_dominance'),
          true,
        );
      });
    });

    group('Future Self Test', () {
      test('returns valid test result', () {
        service.loadSampleData();
        final test = service.runFutureSelfTest(
          title: 'Test decision',
          domain: DecisionDomain.career,
          stakes: StakesLevel.moderate,
          isAction: true,
        );

        expect(test.decisionTitle, 'Test decision');
        expect(test.regretIfAct, greaterThanOrEqualTo(0));
        expect(test.regretIfAct, lessThanOrEqualTo(1));
        expect(test.regretIfSkip, greaterThanOrEqualTo(0));
        expect(test.regretIfSkip, lessThanOrEqualTo(1));
        expect(test.tenYearPerspective, isNotEmpty);
        expect(test.deathbedPerspective, isNotEmpty);
        expect(test.recommendation, isNotEmpty);
      });

      test('life-changing stakes get deathbed framing', () {
        final test = service.runFutureSelfTest(
          title: 'Huge decision',
          domain: DecisionDomain.lifestyle,
          stakes: StakesLevel.lifeChanging,
          isAction: true,
        );
        expect(test.deathbedPerspective.contains('life-defining'), true);
      });

      test('uses historical patterns for career domain', () {
        service.loadSampleData();
        final test = service.runFutureSelfTest(
          title: 'Career move',
          domain: DecisionDomain.career,
          stakes: StakesLevel.moderate,
          isAction: true,
        );
        // Career has inaction regrets in sample data, so skip regret should be higher
        expect(test.regretIfSkip, greaterThan(0));
      });
    });

    group('Dashboard', () {
      test('generates valid dashboard with sample data', () {
        service.loadSampleData();
        final dashboard = service.getDashboard();

        expect(dashboard.totalDecisions, greaterThan(0));
        expect(dashboard.outcomeRecorded, greaterThan(0));
        expect(dashboard.regretScore, greaterThanOrEqualTo(0));
        expect(dashboard.regretScore, lessThanOrEqualTo(100));
        expect(dashboard.wisdomScore, greaterThanOrEqualTo(0));
        expect(dashboard.wisdomScore, lessThanOrEqualTo(100));
        expect(dashboard.healthVerdict, isNotEmpty);
        expect(dashboard.domainSatisfaction, isNotEmpty);
      });

      test('empty dashboard handles gracefully', () {
        final dashboard = service.getDashboard();
        expect(dashboard.totalDecisions, 0);
        expect(dashboard.regretScore, 0.0);
        expect(dashboard.wisdomScore, 0.0);
        expect(dashboard.healthVerdict, isNotEmpty);
      });

      test('regret score bounded 0-100', () {
        service.loadSampleData();
        final score = service.computeRegretScore();
        expect(score, greaterThanOrEqualTo(0));
        expect(score, lessThanOrEqualTo(100));
      });
    });

    group('Enums', () {
      test('DecisionDomain labels and emojis', () {
        for (final d in DecisionDomain.values) {
          expect(d.label, isNotEmpty);
          expect(d.emoji, isNotEmpty);
        }
      });

      test('RegretType labels and descriptions', () {
        for (final r in RegretType.values) {
          expect(r.label, isNotEmpty);
          expect(r.description, isNotEmpty);
        }
      });

      test('CognitiveBias labels, descriptions, and antidotes', () {
        for (final b in CognitiveBias.values) {
          expect(b.label, isNotEmpty);
          expect(b.description, isNotEmpty);
          expect(b.antidote, isNotEmpty);
        }
      });

      test('OutcomeSatisfaction scores range -1 to 1', () {
        for (final s in OutcomeSatisfaction.values) {
          expect(s.score, greaterThanOrEqualTo(-1.0));
          expect(s.score, lessThanOrEqualTo(1.0));
        }
      });

      test('StakesLevel weights are positive', () {
        for (final s in StakesLevel.values) {
          expect(s.weight, greaterThan(0));
        }
      });
    });

    group('Sample Data', () {
      test('loads sample data correctly', () {
        service.loadSampleData();
        expect(service.decisions.length, 8);
        expect(
          service.decisions.where((d) => d.outcome != null).length,
          7,
        );
      });

      test('sample data produces bias detections', () {
        service.loadSampleData();
        final biases = service.getBiasDetections();
        expect(biases, isNotEmpty);
      });

      test('sample data produces regret patterns', () {
        service.loadSampleData();
        final patterns = service.detectRegretPatterns();
        expect(patterns, isNotEmpty);
      });
    });
  });
}
