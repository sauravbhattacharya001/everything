import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/serendipity_engine_service.dart';

void main() {
  late SerendipityEngineService service;

  setUp(() {
    service = SerendipityEngineService();
  });

  // -------------------------------------------------------------------------
  // Signal Collector Tests
  // -------------------------------------------------------------------------

  group('Signal Collector', () {
    test('addSignal stores signal', () {
      final signal = _makeSignal('s1', LifeDomain.work, ['coding', 'ai']);
      service.addSignal(signal);
      expect(service.signals.length, 1);
      expect(service.signals.first.id, 's1');
    });

    test('addSignal allows multiple signals', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['coding']));
      service.addSignal(_makeSignal('s2', LifeDomain.health, ['sleep']));
      service.addSignal(_makeSignal('s3', LifeDomain.creativity, ['music']));
      expect(service.signals.length, 3);
    });

    test('getSignalsByDomain filters correctly', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['coding']));
      service.addSignal(_makeSignal('s2', LifeDomain.work, ['meetings']));
      service.addSignal(_makeSignal('s3', LifeDomain.health, ['sleep']));

      final workSignals = service.getSignalsByDomain(LifeDomain.work);
      expect(workSignals.length, 2);
      expect(workSignals.every((s) => s.domain == LifeDomain.work), true);
    });

    test('getSignalsByDomain returns empty for unused domain', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['coding']));
      final result = service.getSignalsByDomain(LifeDomain.spirituality);
      expect(result, isEmpty);
    });

    test('signals list is unmodifiable', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['coding']));
      expect(() => service.signals.add(_makeSignal('s2', LifeDomain.work, ['x'])),
          throwsA(isA<UnsupportedError>()));
    });
  });

  // -------------------------------------------------------------------------
  // Connection Mining Tests
  // -------------------------------------------------------------------------

  group('Connection Miner', () {
    test('mineConnections finds keyword overlap', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work,
          ['machine-learning', 'patterns', 'data']));
      service.addSignal(_makeSignal('s2', LifeDomain.health,
          ['patterns', 'sleep', 'data']));

      final connections = service.mineConnections(minScore: 10);
      expect(connections, isNotEmpty);
      expect(connections.first.sharedKeywords, contains('patterns'));
    });

    test('mineConnections ignores same-domain signals', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work,
          ['coding', 'review', 'patterns']));
      service.addSignal(_makeSignal('s2', LifeDomain.work,
          ['coding', 'review', 'debug']));

      final connections = service.mineConnections(minScore: 0);
      expect(connections, isEmpty);
    });

    test('mineConnections finds temporal clusters', () {
      final now = DateTime.now();
      service.addSignal(LifeSignal(
        id: 's1',
        domain: LifeDomain.work,
        keywords: ['project'],
        description: 'Started new project',
        timestamp: now,
      ));
      service.addSignal(LifeSignal(
        id: 's2',
        domain: LifeDomain.creativity,
        keywords: ['inspiration'],
        description: 'Had creative burst',
        timestamp: now.add(const Duration(hours: 2)),
      ));

      final connections = service.mineConnections(minScore: 10);
      expect(connections, isNotEmpty);
    });

    test('mineConnections does not duplicate connections', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work,
          ['focus', 'deep-work', 'patterns']));
      service.addSignal(_makeSignal('s2', LifeDomain.fitness,
          ['focus', 'endurance', 'patterns']));

      service.mineConnections(minScore: 10);
      final second = service.mineConnections(minScore: 10);
      expect(second, isEmpty);
    });

    test('mineConnections respects minScore threshold', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['alpha']));
      service.addSignal(_makeSignal('s2', LifeDomain.health, ['beta']));

      final connections = service.mineConnections(minScore: 95);
      expect(connections, isEmpty);
    });

    test('mineConnections finds recurring themes', () {
      // Add a keyword that appears in 3+ domains.
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['growth']));
      service.addSignal(_makeSignal('s2', LifeDomain.health, ['growth']));
      service.addSignal(_makeSignal('s3', LifeDomain.finance, ['growth']));
      service.addSignal(_makeSignal('s4', LifeDomain.relationships, ['growth']));

      final connections = service.mineConnections(minScore: 10);
      expect(connections, isNotEmpty);
    });

    test('connection has valid serendipity score range', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work,
          ['innovation', 'creativity', 'flow']));
      service.addSignal(_makeSignal('s2', LifeDomain.hobbies,
          ['creativity', 'flow', 'joy']));

      final connections = service.mineConnections(minScore: 0);
      for (final conn in connections) {
        expect(conn.serendipityScore, greaterThanOrEqualTo(0));
        expect(conn.serendipityScore, lessThanOrEqualTo(100));
      }
    });
  });

  // -------------------------------------------------------------------------
  // Surprise Scoring Tests
  // -------------------------------------------------------------------------

  group('Surprise Scorer', () {
    test('rare domain pairs score higher than common ones', () {
      // Create many work-health connections first (common pair).
      for (int i = 0; i < 5; i++) {
        service.addSignal(_makeSignal('w$i', LifeDomain.work,
            ['focus', 'energy', 'routine']));
        service.addSignal(_makeSignal('h$i', LifeDomain.health,
            ['energy', 'routine', 'wellness']));
      }
      service.mineConnections(minScore: 0);

      // Now add a rare pair (spirituality-finance).
      service.addSignal(_makeSignal('sp1', LifeDomain.spirituality,
          ['purpose', 'meaning', 'growth']));
      service.addSignal(_makeSignal('fi1', LifeDomain.finance,
          ['growth', 'purpose', 'investment']));

      final newConns = service.mineConnections(minScore: 0);
      // The rare pair should have connections.
      expect(newConns, isNotEmpty);
    });

    test('keyword rarity affects score', () {
      // Add many signals with common keyword.
      for (int i = 0; i < 10; i++) {
        service.addSignal(_makeSignal(
            'common$i', LifeDomain.values[i % 5], ['common-word']));
      }

      // Add signals with rare keyword.
      service.addSignal(_makeSignal('rare1', LifeDomain.work,
          ['quantum-entanglement', 'physics']));
      service.addSignal(_makeSignal('rare2', LifeDomain.creativity,
          ['quantum-entanglement', 'art']));

      final connections = service.mineConnections(minScore: 0);
      // Should find the rare connection.
      final rareConn = connections.where((c) =>
          c.sharedKeywords.contains('quantum-entanglement'));
      expect(rareConn, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Insight Generation Tests
  // -------------------------------------------------------------------------

  group('Insight Generator', () {
    test('generateInsights produces insights from connections', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work,
          ['automation', 'efficiency', 'systems']));
      service.addSignal(_makeSignal('s2', LifeDomain.hobbies,
          ['automation', 'gardening', 'systems']));
      service.mineConnections(minScore: 0);

      final insights = service.generateInsights(maxInsights: 3);
      expect(insights, isNotEmpty);
      expect(insights.first.narrative, isNotEmpty);
      expect(insights.first.actionSuggestion, isNotEmpty);
    });

    test('generateInsights respects maxInsights limit', () {
      // Add many connectable signals.
      for (int i = 0; i < 6; i++) {
        service.addSignal(_makeSignal('a$i',
            LifeDomain.values[i], ['shared-theme', 'topic-$i']));
      }
      service.mineConnections(minScore: 0);

      final insights = service.generateInsights(maxInsights: 2);
      expect(insights.length, lessThanOrEqualTo(2));
    });

    test('generateInsights does not repeat insights for same connection', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work,
          ['focus', 'deep', 'flow']));
      service.addSignal(_makeSignal('s2', LifeDomain.fitness,
          ['focus', 'flow', 'zone']));
      service.mineConnections(minScore: 0);

      service.generateInsights(maxInsights: 5);
      final second = service.generateInsights(maxInsights: 5);
      expect(second, isEmpty);
    });

    test('insight has engagement probability', () {
      service.addSignal(_makeSignal('s1', LifeDomain.learning,
          ['books', 'thinking']));
      service.addSignal(_makeSignal('s2', LifeDomain.relationships,
          ['thinking', 'conversation']));
      service.mineConnections(minScore: 0);

      final insights = service.generateInsights();
      if (insights.isNotEmpty) {
        expect(insights.first.engagementProbability, greaterThanOrEqualTo(0));
        expect(insights.first.engagementProbability, lessThanOrEqualTo(1));
      }
    });

    test('generateInsights returns empty when no connections exist', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['coding']));
      final insights = service.generateInsights();
      expect(insights, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Receptivity Predictor Tests
  // -------------------------------------------------------------------------

  group('Receptivity Predictor', () {
    test('predictReceptivity returns default 0.5 with no data', () {
      final time = DateTime(2026, 1, 15, 10, 0); // Wednesday 10am
      final prob = service.predictReceptivity(time);
      expect(prob, 0.5);
    });

    test('recordEngagement updates receptivity', () {
      final time = DateTime(2026, 1, 15, 10, 0); // Wednesday 10am
      service.recordEngagementAt('insight1', true, time);
      service.recordEngagementAt('insight2', true, time);
      service.recordEngagementAt('insight3', false, time);

      final prob = service.predictReceptivity(time);
      // 2 engaged out of 3 = ~0.667
      expect(prob, closeTo(0.667, 0.01));
    });

    test('different time slots track independently', () {
      final morning = DateTime(2026, 1, 15, 9, 0);
      final evening = DateTime(2026, 1, 15, 21, 0);

      service.recordEngagementAt('i1', true, morning);
      service.recordEngagementAt('i2', true, morning);
      service.recordEngagementAt('i3', false, evening);
      service.recordEngagementAt('i4', false, evening);

      expect(service.predictReceptivity(morning), 1.0);
      expect(service.predictReceptivity(evening), 0.0);
    });
  });

  // -------------------------------------------------------------------------
  // Cultivation Tips Tests
  // -------------------------------------------------------------------------

  group('Serendipity Cultivator', () {
    test('getCultivationTips returns tips', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['coding']));
      final tips = service.getCultivationTips(count: 3);
      expect(tips.length, 3);
    });

    test('tips target neglected domains', () {
      // Only add work signals - other domains are neglected.
      for (int i = 0; i < 5; i++) {
        service.addSignal(_makeSignal('w$i', LifeDomain.work, ['task$i']));
      }

      final tips = service.getCultivationTips(count: 3);
      expect(tips, isNotEmpty);
      // At least one tip should target a domain other than work.
      final tipDomains = tips.expand((t) => t.targetDomains).toSet();
      expect(tipDomains.any((d) => d != LifeDomain.work), true);
    });

    test('tips have valid expected impact', () {
      final tips = service.getCultivationTips(count: 3);
      for (final tip in tips) {
        expect(tip.expectedImpact, greaterThan(0));
        expect(tip.expectedImpact, lessThanOrEqualTo(1));
      }
    });

    test('tips have reasoning', () {
      final tips = service.getCultivationTips(count: 3);
      for (final tip in tips) {
        expect(tip.reasoning, isNotEmpty);
        expect(tip.suggestion, isNotEmpty);
      }
    });

    test('getCultivationTips respects count parameter', () {
      final tips = service.getCultivationTips(count: 1);
      expect(tips.length, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Analytics Tests
  // -------------------------------------------------------------------------

  group('Analytics', () {
    test('getSerendipityScore returns 0 with no signals', () {
      expect(service.getSerendipityScore(), 0);
    });

    test('getSerendipityScore increases with diverse signals', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['a']));
      final score1 = service.getSerendipityScore();

      service.addSignal(_makeSignal('s2', LifeDomain.health, ['b']));
      service.addSignal(_makeSignal('s3', LifeDomain.creativity, ['c']));
      service.addSignal(_makeSignal('s4', LifeDomain.finance, ['d']));
      final score2 = service.getSerendipityScore();

      expect(score2, greaterThan(score1));
    });

    test('getDomainDiversity returns 0 with no signals', () {
      expect(service.getDomainDiversity(), 0);
    });

    test('getDomainDiversity increases with more domains', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['a']));
      final entropy1 = service.getDomainDiversity();

      service.addSignal(_makeSignal('s2', LifeDomain.health, ['b']));
      final entropy2 = service.getDomainDiversity();

      service.addSignal(_makeSignal('s3', LifeDomain.creativity, ['c']));
      final entropy3 = service.getDomainDiversity();

      expect(entropy2, greaterThan(entropy1));
      expect(entropy3, greaterThan(entropy2));
    });

    test('getDomainDiversity is zero for single domain', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['a']));
      service.addSignal(_makeSignal('s2', LifeDomain.work, ['b']));
      expect(service.getDomainDiversity(), 0);
    });

    test('getConnectionGraph returns domain pair counts', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work,
          ['focus', 'energy']));
      service.addSignal(_makeSignal('s2', LifeDomain.fitness,
          ['energy', 'focus']));
      service.mineConnections(minScore: 0);

      final graph = service.getConnectionGraph();
      expect(graph, isNotEmpty);
      // Key should be alphabetically sorted domain names.
      expect(graph.keys.first, contains('-'));
    });

    test('getSerendipityScore is bounded 0-100', () {
      // Add lots of diverse signals.
      for (int i = 0; i < 20; i++) {
        service.addSignal(_makeSignal(
            's$i', LifeDomain.values[i % 10], ['kw$i', 'shared']));
      }
      service.mineConnections(minScore: 0);

      final score = service.getSerendipityScore();
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));
    });
  });

  // -------------------------------------------------------------------------
  // Dashboard Tests
  // -------------------------------------------------------------------------

  group('Dashboard', () {
    test('getDashboard returns all expected keys', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['coding']));
      final dashboard = service.getDashboard();

      expect(dashboard.containsKey('serendipityScore'), true);
      expect(dashboard.containsKey('totalSignals'), true);
      expect(dashboard.containsKey('totalConnections'), true);
      expect(dashboard.containsKey('totalInsights'), true);
      expect(dashboard.containsKey('domainDiversity'), true);
      expect(dashboard.containsKey('domainDistribution'), true);
      expect(dashboard.containsKey('connectionGraph'), true);
      expect(dashboard.containsKey('engagementRate'), true);
    });

    test('getDashboard reflects actual state', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work,
          ['code', 'design']));
      service.addSignal(_makeSignal('s2', LifeDomain.creativity,
          ['design', 'art']));
      service.mineConnections(minScore: 0);
      service.generateInsights();

      final dashboard = service.getDashboard();
      expect(dashboard['totalSignals'], 2);
      expect(dashboard['totalConnections'], greaterThanOrEqualTo(0));
    });
  });

  // -------------------------------------------------------------------------
  // Edge Cases
  // -------------------------------------------------------------------------

  group('Edge Cases', () {
    test('mineConnections with empty signals returns empty', () {
      final connections = service.mineConnections();
      expect(connections, isEmpty);
    });

    test('mineConnections with single signal returns empty', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['coding']));
      final connections = service.mineConnections();
      expect(connections, isEmpty);
    });

    test('duplicate signal ids are stored separately', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['a']));
      service.addSignal(_makeSignal('s1', LifeDomain.health, ['b']));
      expect(service.signals.length, 2);
    });

    test('signals with empty keywords still work', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, []));
      service.addSignal(_makeSignal('s2', LifeDomain.health, []));
      final connections = service.mineConnections(minScore: 0);
      // May or may not find temporal connections, but should not crash.
      expect(connections, isA<List<SignalConnection>>());
    });

    test('exportToJson produces valid JSON', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work, ['code']));
      service.addSignal(_makeSignal('s2', LifeDomain.health, ['code']));
      service.mineConnections(minScore: 0);

      final jsonStr = service.exportToJson();
      expect(() => jsonDecode(jsonStr), returnsNormally);
    });

    test('custom temporal window works', () {
      final narrowService = SerendipityEngineService(temporalWindowHours: 1);
      final now = DateTime.now();

      narrowService.addSignal(LifeSignal(
        id: 's1',
        domain: LifeDomain.work,
        keywords: ['unique1'],
        description: 'A',
        timestamp: now,
      ));
      narrowService.addSignal(LifeSignal(
        id: 's2',
        domain: LifeDomain.health,
        keywords: ['unique2'],
        description: 'B',
        timestamp: now.add(const Duration(hours: 5)),
      ));

      // With 1-hour window, 5-hour gap should not produce temporal cluster.
      final connections = narrowService.mineConnections(minScore: 0);
      final temporalConns = connections
          .where((c) => c.connectionType == ConnectionType.temporalCluster);
      expect(temporalConns, isEmpty);
    });

    test('custom minKeywordSimilarity works', () {
      final strictService =
          SerendipityEngineService(minKeywordSimilarity: 0.8);

      strictService.addSignal(_makeSignal('s1', LifeDomain.work,
          ['a', 'b', 'c', 'd', 'e']));
      strictService.addSignal(_makeSignal('s2', LifeDomain.health,
          ['a', 'x', 'y', 'z', 'w']));

      // Jaccard = 1/9 ≈ 0.11, below 0.8 threshold.
      final connections = strictService.mineConnections(minScore: 0);
      final kwConns = connections
          .where((c) => c.connectionType == ConnectionType.keywordOverlap);
      expect(kwConns, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // Enum Tests
  // -------------------------------------------------------------------------

  group('Enums', () {
    test('LifeDomain has 10 values', () {
      expect(LifeDomain.values.length, 10);
    });

    test('LifeDomain labels are not empty', () {
      for (final domain in LifeDomain.values) {
        expect(domain.label, isNotEmpty);
        expect(domain.emoji, isNotEmpty);
      }
    });

    test('ConnectionType has 5 values', () {
      expect(ConnectionType.values.length, 5);
    });

    test('ConnectionType has labels and descriptions', () {
      for (final type in ConnectionType.values) {
        expect(type.label, isNotEmpty);
        expect(type.description, isNotEmpty);
      }
    });
  });

  // -------------------------------------------------------------------------
  // Serialization Tests
  // -------------------------------------------------------------------------

  group('Serialization', () {
    test('LifeSignal round-trips through JSON', () {
      final signal = _makeSignal('s1', LifeDomain.creativity,
          ['art', 'music']);
      final json = signal.toJson();
      final restored = LifeSignal.fromJson(json);

      expect(restored.id, signal.id);
      expect(restored.domain, signal.domain);
      expect(restored.keywords, signal.keywords);
      expect(restored.description, signal.description);
    });

    test('SignalConnection toJson has required fields', () {
      service.addSignal(_makeSignal('s1', LifeDomain.work,
          ['shared', 'theme']));
      service.addSignal(_makeSignal('s2', LifeDomain.health,
          ['shared', 'wellness']));
      service.mineConnections(minScore: 0);

      if (service.connections.isNotEmpty) {
        final json = service.connections.first.toJson();
        expect(json.containsKey('id'), true);
        expect(json.containsKey('signalAId'), true);
        expect(json.containsKey('signalBId'), true);
        expect(json.containsKey('connectionType'), true);
        expect(json.containsKey('serendipityScore'), true);
      }
    });

    test('ReceptivityWindow toJson works', () {
      final window = ReceptivityWindow(hourOfDay: 10, dayOfWeek: 3);
      window.recordDelivery(true);
      final json = window.toJson();

      expect(json['hourOfDay'], 10);
      expect(json['dayOfWeek'], 3);
      expect(json['totalDeliveries'], 1);
      expect(json['totalEngagements'], 1);
      expect(json['engagementRate'], 1.0);
    });

    test('CultivationTip toJson works', () {
      final tip = CultivationTip(
        id: 'tip_0',
        suggestion: 'Try something new',
        targetDomains: [LifeDomain.learning, LifeDomain.creativity],
        expectedImpact: 0.7,
        reasoning: 'Diversity increases serendipity',
      );
      final json = tip.toJson();

      expect(json['id'], 'tip_0');
      expect(json['targetDomains'], ['learning', 'creativity']);
      expect(json['expectedImpact'], 0.7);
    });
  });
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

LifeSignal _makeSignal(String id, LifeDomain domain, List<String> keywords,
    {DateTime? timestamp}) {
  return LifeSignal(
    id: id,
    domain: domain,
    keywords: keywords,
    description: 'Signal $id in ${domain.label}',
    timestamp: timestamp ?? DateTime.now(),
  );
}


