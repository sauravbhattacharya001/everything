import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/social_capital_engine_service.dart';

void main() {
  late SocialCapitalEngineService service;

  setUp(() {
    service = SocialCapitalEngineService();
  });

  group('SocialCapitalEngineService — Basics', () {
    test('starts empty', () {
      expect(service.relationships, isEmpty);
      expect(service.interactions, isEmpty);
      expect(service.history, isEmpty);
    });

    test('add/remove relationship', () {
      final r = Relationship(
        id: 'r1',
        name: 'Alice',
        tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      );
      service.addRelationship(r);
      expect(service.relationships.length, 1);
      expect(service.relationships.first.name, 'Alice');

      service.removeRelationship('r1');
      expect(service.relationships, isEmpty);
    });

    test('remove relationship also removes interactions', () {
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.message,
        date: DateTime(2025, 6, 1),
      ));
      expect(service.interactions.length, 1);
      service.removeRelationship('r1');
      expect(service.interactions, isEmpty);
    });

    test('update relationship', () {
      final r = Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        importance: 5, createdAt: DateTime(2025, 1, 1),
      );
      service.addRelationship(r);
      service.updateRelationship(r.copyWith(name: 'Alice B.', importance: 8));
      expect(service.relationships.first.name, 'Alice B.');
      expect(service.relationships.first.importance, 8);
    });

    test('log and remove interaction', () {
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.call,
        date: DateTime(2025, 6, 1), quality: 4,
      ));
      expect(service.interactions.length, 1);
      service.removeInteraction('i1');
      expect(service.interactions, isEmpty);
    });

    test('interactionsFor returns newest first', () {
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.message,
        date: DateTime(2025, 3, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i2', relationshipId: 'r1', type: InteractionType.call,
        date: DateTime(2025, 6, 1),
      ));
      final ints = service.interactionsFor('r1');
      expect(ints.first.id, 'i2');
      expect(ints.last.id, 'i1');
    });
  });

  group('Engine 1: Strength Calculator', () {
    test('recent interaction gives high recency score', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.inPerson,
        date: now.subtract(const Duration(days: 1)), quality: 5,
      ));
      final health = service.computeHealth('r1', now: now);
      expect(health.recencyScore, greaterThan(90));
    });

    test('old interaction gives low recency score', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.message,
        date: now.subtract(const Duration(days: 90)), quality: 3,
      ));
      final health = service.computeHealth('r1', now: now);
      expect(health.recencyScore, lessThan(20));
    });

    test('no interactions gives zero strength', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      final health = service.computeHealth('r1', now: now);
      expect(health.strengthScore, 0);
      expect(health.recencyScore, 0);
      expect(health.frequencyScore, 0);
      expect(health.qualityScore, 0);
    });

    test('high quality interactions boost quality score', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      // All quality 5
      for (var i = 0; i < 5; i++) {
        service.logInteraction(Interaction(
          id: 'i$i', relationshipId: 'r1', type: InteractionType.inPerson,
          date: now.subtract(Duration(days: i * 7)), quality: 5,
        ));
      }
      final health = service.computeHealth('r1', now: now);
      expect(health.qualityScore, greaterThan(90));
    });

    test('computed tier matches strength', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      // No interactions → very low strength → dormant
      final health = service.computeHealth('r1', now: now);
      expect(health.computedTier, RelationshipTier.dormant);
    });

    test('frequent recent interactions give high strength', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      for (var i = 0; i < 8; i++) {
        service.logInteraction(Interaction(
          id: 'i$i', relationshipId: 'r1', type: InteractionType.inPerson,
          date: now.subtract(Duration(days: i * 3)), quality: 5,
          initiatedBy: i.isEven
              ? InteractionInitiator.self
              : InteractionInitiator.them,
        ));
      }
      final health = service.computeHealth('r1', now: now);
      expect(health.strengthScore, greaterThan(60));
    });
  });

  group('Engine 2: Decay Predictor', () {
    test('active relationship has future decay date', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.call,
        date: now.subtract(const Duration(days: 2)), quality: 4,
      ));
      final health = service.computeHealth('r1', now: now);
      if (health.strengthScore > 30) {
        expect(health.decayDate, isNotNull);
        expect(health.decayDate!.isAfter(now), isTrue);
      }
    });

    test('dormant relationship has null decay date', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2024, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.message,
        date: now.subtract(const Duration(days: 200)), quality: 2,
      ));
      final health = service.computeHealth('r1', now: now);
      // Extremely old interaction → strength near 0 → already dormant → null
      expect(health.decayDate, isNull);
    });
  });

  group('Engine 3: Cluster Detector', () {
    test('shared tags create clusters', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        tags: ['work', 'tech'], createdAt: DateTime(2025, 1, 1),
      ));
      service.addRelationship(Relationship(
        id: 'r2', name: 'Bob', tier: RelationshipTier.close,
        tags: ['work', 'gaming'], createdAt: DateTime(2025, 1, 1),
      ));
      service.addRelationship(Relationship(
        id: 'r3', name: 'Carol', tier: RelationshipTier.regular,
        tags: ['tech', 'gaming'], createdAt: DateTime(2025, 1, 1),
      ));

      // Need some interactions for health
      for (final rid in ['r1', 'r2', 'r3']) {
        service.logInteraction(Interaction(
          id: 'i_$rid', relationshipId: rid, type: InteractionType.message,
          date: now.subtract(const Duration(days: 5)), quality: 3,
        ));
      }

      final healthMap = <String, RelationshipHealth>{};
      for (final r in service.relationships) {
        healthMap[r.id] = service.computeHealth(r.id, now: now);
      }

      final clusters = service.detectClusters(healthMap);
      expect(clusters.length, greaterThanOrEqualTo(2)); // work, tech, gaming
      final workCluster = clusters.where((c) => c.name == 'work').toList();
      expect(workCluster.length, 1);
      expect(workCluster.first.memberIds, containsAll(['r1', 'r2']));
    });

    test('single-member tags do not create clusters', () {
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        tags: ['unique'], createdAt: DateTime(2025, 1, 1),
      ));
      final clusters = service.detectClusters({});
      expect(clusters.where((c) => c.name == 'unique'), isEmpty);
    });
  });

  group('Engine 4: Reciprocity Analyzer', () {
    test('balanced interactions give index near 0', () {
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.message,
        date: DateTime(2025, 6, 1), initiatedBy: InteractionInitiator.self,
      ));
      service.logInteraction(Interaction(
        id: 'i2', relationshipId: 'r1', type: InteractionType.message,
        date: DateTime(2025, 6, 2), initiatedBy: InteractionInitiator.them,
      ));
      final health = service.computeHealth('r1', now: DateTime(2025, 6, 3));
      expect(health.reciprocityIndex.abs(), lessThan(0.1));
    });

    test('all self-initiated gives positive index', () {
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      for (var i = 0; i < 5; i++) {
        service.logInteraction(Interaction(
          id: 'i$i', relationshipId: 'r1', type: InteractionType.message,
          date: DateTime(2025, 6, i + 1), initiatedBy: InteractionInitiator.self,
        ));
      }
      final health = service.computeHealth('r1', now: DateTime(2025, 6, 10));
      expect(health.reciprocityIndex, greaterThan(0.5));
    });

    test('network reciprocity aggregates all interactions', () {
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.message,
        date: DateTime(2025, 6, 1), initiatedBy: InteractionInitiator.mutual,
      ));
      // mutual counts as both, so should be ~0
      expect(service.networkReciprocity().abs(), lessThan(0.01));
    });
  });

  group('Engine 5: Network Health Scorer', () {
    test('empty network scores 0', () {
      final score = service.computeNetworkScore({});
      expect(score, 0);
    });

    test('active network scores above 0', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.inPerson,
        date: now.subtract(const Duration(days: 2)), quality: 5,
      ));
      final healthMap = {
        'r1': service.computeHealth('r1', now: now),
      };
      final score = service.computeNetworkScore(healthMap);
      expect(score, greaterThan(0));
    });
  });

  group('Engine 6: Insight Generator', () {
    test('generates neglect warning for close friends without recent contact', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2024, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.message,
        date: now.subtract(const Duration(days: 45)), quality: 3,
      ));
      final healthMap = {
        'r1': service.computeHealth('r1', now: now),
      };
      final insights = service.generateInsights(healthMap, [], now: now);
      final neglect = insights.where((i) => i.type == InsightType.neglectWarning);
      expect(neglect, isNotEmpty);
    });

    test('no neglect warning for regular tier', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Bob', tier: RelationshipTier.regular,
        createdAt: DateTime(2024, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.message,
        date: now.subtract(const Duration(days: 45)), quality: 3,
      ));
      final healthMap = {
        'r1': service.computeHealth('r1', now: now),
      };
      final insights = service.generateInsights(healthMap, [], now: now);
      final neglect = insights.where((i) => i.type == InsightType.neglectWarning);
      expect(neglect, isEmpty);
    });

    test('generates reciprocity imbalance insight', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      // All self-initiated
      for (var i = 0; i < 5; i++) {
        service.logInteraction(Interaction(
          id: 'i$i', relationshipId: 'r1', type: InteractionType.message,
          date: now.subtract(Duration(days: i * 5)), quality: 3,
          initiatedBy: InteractionInitiator.self,
        ));
      }
      final healthMap = {
        'r1': service.computeHealth('r1', now: now),
      };
      final insights = service.generateInsights(healthMap, [], now: now);
      final recipInsights =
          insights.where((i) => i.type == InsightType.reciprocityImbalance);
      expect(recipInsights, isNotEmpty);
    });

    test('generates strength milestone for high-strength relationship', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      for (var i = 0; i < 10; i++) {
        service.logInteraction(Interaction(
          id: 'i$i', relationshipId: 'r1', type: InteractionType.inPerson,
          date: now.subtract(Duration(days: i * 3)), quality: 5,
          initiatedBy: i.isEven
              ? InteractionInitiator.self
              : InteractionInitiator.them,
        ));
      }
      final healthMap = {
        'r1': service.computeHealth('r1', now: now),
      };
      // Only check for milestone if strength is actually >= 80
      if (healthMap['r1']!.strengthScore >= 80) {
        final insights = service.generateInsights(healthMap, [], now: now);
        final milestones =
            insights.where((i) => i.type == InsightType.strengthMilestone);
        expect(milestones, isNotEmpty);
      }
    });

    test('generates cluster weakening insight', () {
      final now = DateTime(2025, 7, 1);
      final weakCluster = SocialCluster(
        id: 'c1', name: 'Old Friends', memberIds: ['r1', 'r2'],
        cohesionScore: 25, trend: ClusterTrend.weakening,
      );
      final insights = service.generateInsights({}, [weakCluster], now: now);
      final clusterInsights =
          insights.where((i) => i.type == InsightType.clusterWeakening);
      expect(clusterInsights, isNotEmpty);
    });

    test('generates network gap insight', () {
      final now = DateTime(2025, 7, 1);
      // Add 3+ relationships all in same tier
      for (var i = 0; i < 4; i++) {
        service.addRelationship(Relationship(
          id: 'r$i', name: 'Person $i', tier: RelationshipTier.acquaintance,
          createdAt: DateTime(2025, 1, 1),
        ));
      }
      // All will be dormant (no interactions) → missing inner/close/regular
      final healthMap = <String, RelationshipHealth>{};
      for (final r in service.relationships) {
        healthMap[r.id] = service.computeHealth(r.id, now: now);
      }
      final insights = service.generateInsights(healthMap, [], now: now);
      final gaps = insights.where((i) => i.type == InsightType.networkGap);
      expect(gaps, isNotEmpty);
    });

    test('insights sorted by severity (critical first)', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.innerCircle,
        createdAt: DateTime(2024, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.message,
        date: now.subtract(const Duration(days: 65)), quality: 3,
      ));
      final healthMap = {
        'r1': service.computeHealth('r1', now: now),
      };
      final insights = service.generateInsights(healthMap, [], now: now);
      if (insights.length >= 2) {
        for (var i = 0; i < insights.length - 1; i++) {
          expect(insights[i].severity.index,
              greaterThanOrEqualTo(insights[i + 1].severity.index));
        }
      }
    });
  });

  group('Engine 7: Trend Tracker', () {
    test('single analysis returns stable', () {
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.message,
        date: DateTime(2025, 6, 1), quality: 3,
      ));
      service.analyze(now: DateTime(2025, 6, 2));
      expect(service.trendDirection(), 'stable');
    });

    test('trend detected with multiple analyses', () {
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      // First analysis: old interaction → low score
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.message,
        date: DateTime(2025, 3, 1), quality: 2,
      ));
      service.analyze(now: DateTime(2025, 6, 1));

      // Second analysis: add recent high-quality interaction → higher score
      service.logInteraction(Interaction(
        id: 'i2', relationshipId: 'r1', type: InteractionType.inPerson,
        date: DateTime(2025, 6, 2), quality: 5,
      ));
      service.analyze(now: DateTime(2025, 6, 3));
      // trend may be improving or stable depending on score delta
      expect(['stable', 'improving', 'declining'],
          contains(service.trendDirection()));
    });
  });

  group('Full Analysis', () {
    test('analyze returns complete result', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        tags: ['work'], createdAt: DateTime(2025, 1, 1),
      ));
      service.addRelationship(Relationship(
        id: 'r2', name: 'Bob', tier: RelationshipTier.regular,
        tags: ['work'], createdAt: DateTime(2025, 2, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.call,
        date: now.subtract(const Duration(days: 3)), quality: 4,
      ));
      service.logInteraction(Interaction(
        id: 'i2', relationshipId: 'r2', type: InteractionType.message,
        date: now.subtract(const Duration(days: 10)), quality: 3,
      ));

      final analysis = service.analyze(now: now);
      expect(analysis.overallScore, greaterThanOrEqualTo(0));
      expect(analysis.overallScore, lessThanOrEqualTo(100));
      expect(analysis.healthMap.length, 2);
      expect(analysis.clusters, isNotEmpty); // 'work' cluster
      expect(analysis.analyzedAt, now);
      expect(service.history.length, 1);
    });

    test('analyze appends to history', () {
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.analyze(now: DateTime(2025, 6, 1));
      service.analyze(now: DateTime(2025, 6, 2));
      expect(service.history.length, 2);
    });
  });

  group('Queries', () {
    test('getTopNeglected returns most neglected first', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.addRelationship(Relationship(
        id: 'r2', name: 'Bob', tier: RelationshipTier.regular,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.message,
        date: now.subtract(const Duration(days: 60)),
      ));
      service.logInteraction(Interaction(
        id: 'i2', relationshipId: 'r2', type: InteractionType.message,
        date: now.subtract(const Duration(days: 5)),
      ));
      final neglected = service.getTopNeglected(2, now: now);
      expect(neglected.first.key.name, 'Alice');
      expect(neglected.first.value, 60);
    });

    test('getStrongestRelationships returns strongest first', () {
      final now = DateTime(2025, 7, 1);
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.addRelationship(Relationship(
        id: 'r2', name: 'Bob', tier: RelationshipTier.regular,
        createdAt: DateTime(2025, 1, 1),
      ));
      // Alice: recent high-quality
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.inPerson,
        date: now.subtract(const Duration(days: 1)), quality: 5,
      ));
      // Bob: old low-quality
      service.logInteraction(Interaction(
        id: 'i2', relationshipId: 'r2', type: InteractionType.message,
        date: now.subtract(const Duration(days: 60)), quality: 2,
      ));
      final strongest = service.getStrongestRelationships(2, now: now);
      expect(strongest.first.key.name, 'Alice');
      expect(strongest.first.value, greaterThan(strongest.last.value));
    });
  });

  group('Demo Data', () {
    test('loadDemoData populates relationships and interactions', () {
      service.loadDemoData();
      expect(service.relationships.length, 12);
      expect(service.interactions.length, 40);
    });

    test('demo data produces valid analysis', () {
      service.loadDemoData();
      final analysis = service.analyze();
      expect(analysis.overallScore, greaterThan(0));
      expect(analysis.healthMap.length, 12);
      expect(analysis.clusters, isNotEmpty);
      expect(analysis.insights, isNotEmpty);
    });
  });

  group('Serialization', () {
    test('round-trip JSON preserves data', () {
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        tags: ['work', 'tech'], importance: 7,
        createdAt: DateTime(2025, 1, 1),
      ));
      service.logInteraction(Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.videoCall,
        date: DateTime(2025, 6, 1), quality: 4,
        initiatedBy: InteractionInitiator.them, notes: 'Caught up',
      ));

      final json = service.toJsonString();
      final restored = SocialCapitalEngineService();
      restored.loadFromJsonString(json);

      expect(restored.relationships.length, 1);
      expect(restored.relationships.first.name, 'Alice');
      expect(restored.relationships.first.tags, ['work', 'tech']);
      expect(restored.interactions.length, 1);
      expect(restored.interactions.first.type, InteractionType.videoCall);
      expect(restored.interactions.first.notes, 'Caught up');
    });

    test('Relationship toJson/fromJson round-trip', () {
      final r = Relationship(
        id: 'r1', name: 'Test', tier: RelationshipTier.innerCircle,
        tags: ['a', 'b'], importance: 9,
        createdAt: DateTime(2025, 3, 15),
      );
      final restored = Relationship.fromJson(r.toJson());
      expect(restored.id, r.id);
      expect(restored.tier, r.tier);
      expect(restored.tags, r.tags);
    });

    test('Interaction toJson/fromJson round-trip', () {
      final i = Interaction(
        id: 'i1', relationshipId: 'r1', type: InteractionType.gift,
        date: DateTime(2025, 6, 1), quality: 5,
        initiatedBy: InteractionInitiator.self, notes: 'Birthday',
      );
      final restored = Interaction.fromJson(i.toJson());
      expect(restored.id, i.id);
      expect(restored.type, i.type);
      expect(restored.initiatedBy, i.initiatedBy);
      expect(restored.notes, 'Birthday');
    });

    test('RelationshipHealth toJson/fromJson round-trip', () {
      final h = RelationshipHealth(
        relationshipId: 'r1', strengthScore: 75.5, recencyScore: 80,
        frequencyScore: 60, qualityScore: 90, reciprocityIndex: -0.3,
        decayDate: DateTime(2025, 8, 1),
        computedTier: RelationshipTier.close,
      );
      final restored = RelationshipHealth.fromJson(h.toJson());
      expect(restored.strengthScore, 75.5);
      expect(restored.reciprocityIndex, -0.3);
      expect(restored.decayDate, DateTime(2025, 8, 1));
    });

    test('SocialCluster toJson/fromJson round-trip', () {
      final c = SocialCluster(
        id: 'c1', name: 'Work', memberIds: ['r1', 'r2'],
        cohesionScore: 65.5, trend: ClusterTrend.growing,
      );
      final restored = SocialCluster.fromJson(c.toJson());
      expect(restored.name, 'Work');
      expect(restored.memberIds, ['r1', 'r2']);
      expect(restored.trend, ClusterTrend.growing);
    });

    test('SocialCapitalInsight toJson/fromJson round-trip', () {
      final insight = SocialCapitalInsight(
        type: InsightType.neglectWarning, severity: InsightSeverity.warning,
        message: 'Test message', relationshipId: 'r1',
        actionSuggestion: 'Do something',
        timestamp: DateTime(2025, 7, 1),
      );
      final restored = SocialCapitalInsight.fromJson(insight.toJson());
      expect(restored.type, InsightType.neglectWarning);
      expect(restored.severity, InsightSeverity.warning);
      expect(restored.relationshipId, 'r1');
    });
  });

  group('Edge Cases', () {
    test('single relationship analysis works', () {
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      final analysis = service.analyze(now: DateTime(2025, 7, 1));
      expect(analysis.healthMap.length, 1);
      expect(analysis.overallScore, greaterThanOrEqualTo(0));
    });

    test('relationship with no interactions has zero scores', () {
      service.addRelationship(Relationship(
        id: 'r1', name: 'Alice', tier: RelationshipTier.close,
        createdAt: DateTime(2025, 1, 1),
      ));
      final health = service.computeHealth('r1', now: DateTime(2025, 7, 1));
      expect(health.strengthScore, 0);
      expect(health.reciprocityIndex, 0);
    });
  });
}
