import 'package:flutter_test/flutter_test.dart';
import 'package:everything/core/services/burnout_detector_service.dart';

void main() {
  late BurnoutDetectorService service;

  setUp(() {
    service = BurnoutDetectorService();
  });

  group('BurnoutRiskLevel', () {
    test('label returns human-readable string', () {
      expect(BurnoutRiskLevel.low.label, 'Low Risk');
      expect(BurnoutRiskLevel.critical.label, 'Critical');
    });

    test('emoji returns correct indicator', () {
      expect(BurnoutRiskLevel.low.emoji, '🟢');
      expect(BurnoutRiskLevel.high.emoji, '🔴');
      expect(BurnoutRiskLevel.critical.emoji, '🚨');
    });
  });

  group('SignalTrend', () {
    test('arrow returns directional symbol', () {
      expect(SignalTrend.improving.arrow, '↑');
      expect(SignalTrend.stable.arrow, '→');
      expect(SignalTrend.declining.arrow, '↓');
    });
  });

  group('getSampleScenarios', () {
    test('returns 4 predefined scenarios', () {
      final scenarios = service.getSampleScenarios();
      expect(scenarios.length, 4);
      expect(scenarios[0].name, 'Healthy Balance');
      expect(scenarios[3].name, 'Critical Burnout');
    });

    test('each scenario has 12 signals', () {
      for (final s in service.getSampleScenarios()) {
        expect(s.signals.length, 12, reason: '${s.name} should have 12 signals');
      }
    });
  });

  group('generateSampleSignals', () {
    test('returns Early Warning scenario signals', () {
      final signals = service.generateSampleSignals();
      expect(signals.length, 12);
      // Early Warning has Sleep Quality = 58
      expect(signals.first.name, 'Sleep Quality');
      expect(signals.first.value, 58);
    });
  });

  group('analyzeSignals - risk classification', () {
    test('empty signals yields zero risk score', () {
      final result = service.analyzeSignals([]);
      expect(result.riskScore, 0);
      expect(result.overallRisk, BurnoutRiskLevel.low);
    });

    test('high-value stable signals yield low risk', () {
      final result = service.analyzeSignals(
        service.getSampleScenarios()[0].signals, // Healthy Balance
      );
      expect(result.overallRisk, BurnoutRiskLevel.low);
      expect(result.riskScore, lessThan(25));
    });

    test('early warning signals yield moderate/elevated risk', () {
      final result = service.analyzeSignals(
        service.getSampleScenarios()[1].signals,
      );
      expect(result.riskScore, greaterThan(25));
      expect(
        result.overallRisk.index,
        greaterThanOrEqualTo(BurnoutRiskLevel.moderate.index),
      );
    });

    test('approaching burnout yields high risk', () {
      final result = service.analyzeSignals(
        service.getSampleScenarios()[2].signals,
      );
      expect(result.overallRisk.index,
          greaterThanOrEqualTo(BurnoutRiskLevel.high.index));
    });

    test('critical burnout yields critical risk', () {
      final result = service.analyzeSignals(
        service.getSampleScenarios()[3].signals,
      );
      expect(result.overallRisk, BurnoutRiskLevel.critical);
      expect(result.riskScore, greaterThan(80));
    });
  });

  group('analyzeSignals - declining trend amplifies risk', () {
    test('declining trend produces higher risk than stable', () {
      const stableSignals = [
        BurnoutSignal(name: 'Sleep Quality', category: 'sleep', value: 50, weight: 1.0, trend: SignalTrend.stable),
      ];
      const decliningSignals = [
        BurnoutSignal(name: 'Sleep Quality', category: 'sleep', value: 50, weight: 1.0, trend: SignalTrend.declining),
      ];
      final stableResult = service.analyzeSignals(stableSignals);
      final decliningResult = service.analyzeSignals(decliningSignals);
      expect(decliningResult.riskScore, greaterThan(stableResult.riskScore));
    });

    test('improving trend reduces risk', () {
      const improvingSignals = [
        BurnoutSignal(name: 'Energy', category: 'energy', value: 50, weight: 1.0, trend: SignalTrend.improving),
      ];
      const stableSignals = [
        BurnoutSignal(name: 'Energy', category: 'energy', value: 50, weight: 1.0, trend: SignalTrend.stable),
      ];
      final improvingResult = service.analyzeSignals(improvingSignals);
      final stableResult = service.analyzeSignals(stableSignals);
      expect(improvingResult.riskScore, lessThan(stableResult.riskScore));
    });
  });

  group('analyzeSignals - risk score clamping', () {
    test('risk score never exceeds 100', () {
      const extremeSignals = [
        BurnoutSignal(name: 'Test', category: 'sleep', value: 0, weight: 5.0, trend: SignalTrend.declining),
      ];
      final result = service.analyzeSignals(extremeSignals);
      expect(result.riskScore, lessThanOrEqualTo(100));
    });

    test('risk score never goes below 0', () {
      const perfectSignals = [
        BurnoutSignal(name: 'Test', category: 'sleep', value: 100, weight: 5.0, trend: SignalTrend.improving),
      ];
      final result = service.analyzeSignals(perfectSignals);
      expect(result.riskScore, greaterThanOrEqualTo(0));
    });
  });

  group('analyzeSignals - warning patterns', () {
    test('detects overwork-sleep spiral', () {
      const signals = [
        BurnoutSignal(name: 'Sleep Quality', category: 'sleep', value: 30, weight: 1.3, trend: SignalTrend.declining),
        BurnoutSignal(name: 'Work Hours', category: 'activity', value: 20, weight: 1.1, trend: SignalTrend.declining),
      ];
      final result = service.analyzeSignals(signals);
      expect(
        result.warningPatterns.any((p) => p.name == 'Overwork-Sleep Spiral'),
        isTrue,
      );
    });

    test('detects social isolation at very low levels', () {
      const signals = [
        BurnoutSignal(name: 'Social Interaction', category: 'social', value: 10, weight: 1.0, trend: SignalTrend.declining),
      ];
      final result = service.analyzeSignals(signals);
      final pattern = result.warningPatterns.firstWhere((p) => p.name == 'Social Isolation');
      expect(pattern.severity, 'severe');
    });

    test('detects energy crash cycle', () {
      const signals = [
        BurnoutSignal(name: 'Energy Level', category: 'energy', value: 20, weight: 1.2, trend: SignalTrend.declining),
        BurnoutSignal(name: 'Break Frequency', category: 'activity', value: 15, weight: 0.9, trend: SignalTrend.declining),
      ];
      final result = service.analyzeSignals(signals);
      expect(
        result.warningPatterns.any((p) => p.name == 'Energy Crash Cycle'),
        isTrue,
      );
    });

    test('detects digital overload', () {
      const signals = [
        BurnoutSignal(name: 'Screen Time', category: 'activity', value: 15, weight: 0.8, trend: SignalTrend.declining),
      ];
      final result = service.analyzeSignals(signals);
      expect(
        result.warningPatterns.any((p) => p.name == 'Digital Overload'),
        isTrue,
      );
    });

    test('detects physical neglect', () {
      const signals = [
        BurnoutSignal(name: 'Nutrition Quality', category: 'nutrition', value: 25, weight: 0.8, trend: SignalTrend.declining),
        BurnoutSignal(name: 'Hydration', category: 'nutrition', value: 30, weight: 0.7, trend: SignalTrend.declining),
      ];
      final result = service.analyzeSignals(signals);
      expect(
        result.warningPatterns.any((p) => p.name == 'Physical Neglect'),
        isTrue,
      );
    });

    test('detects emotional regulation gap', () {
      const signals = [
        BurnoutSignal(name: 'Mindfulness Minutes', category: 'mood', value: 10, weight: 0.7, trend: SignalTrend.declining),
        BurnoutSignal(name: 'Mood Stability', category: 'mood', value: 20, weight: 1.3, trend: SignalTrend.declining),
      ];
      final result = service.analyzeSignals(signals);
      expect(
        result.warningPatterns.any((p) => p.name == 'Emotional Regulation Gap'),
        isTrue,
      );
    });

    test('no patterns when all signals are healthy', () {
      final result = service.analyzeSignals(
        service.getSampleScenarios()[0].signals,
      );
      expect(result.warningPatterns, isEmpty);
    });
  });

  group('analyzeSignals - resilience score', () {
    test('healthy signals yield high resilience', () {
      final result = service.analyzeSignals(
        service.getSampleScenarios()[0].signals,
      );
      expect(result.resilienceScore, greaterThan(50));
    });

    test('critical signals yield very low resilience', () {
      final result = service.analyzeSignals(
        service.getSampleScenarios()[3].signals,
      );
      expect(result.resilienceScore, lessThan(20));
    });

    test('resilience clamped to 0-100', () {
      for (final scenario in service.getSampleScenarios()) {
        final result = service.analyzeSignals(scenario.signals);
        expect(result.resilienceScore, inInclusiveRange(0, 100));
      }
    });
  });

  group('analyzeSignals - recommendations', () {
    test('generates at least one recommendation for any non-empty input', () {
      final result = service.analyzeSignals([
        const BurnoutSignal(name: 'Sleep Quality', category: 'sleep', value: 30, weight: 1.0, trend: SignalTrend.declining),
      ]);
      expect(result.recommendations, isNotEmpty);
    });

    test('high risk includes professional help recommendation', () {
      final result = service.analyzeSignals(
        service.getSampleScenarios()[3].signals,
      );
      expect(
        result.recommendations.any((r) => r.contains('professional')),
        isTrue,
      );
    });

    test('elevated risk includes free time recommendation', () {
      final result = service.analyzeSignals(
        service.getSampleScenarios()[2].signals,
      );
      expect(
        result.recommendations.any((r) => r.contains('free time')),
        isTrue,
      );
    });

    test('recommendations cover worst signal categories', () {
      const signals = [
        BurnoutSignal(name: 'Social Interaction', category: 'social', value: 5, weight: 1.0, trend: SignalTrend.declining),
        BurnoutSignal(name: 'Sleep Quality', category: 'sleep', value: 90, weight: 1.0, trend: SignalTrend.stable),
      ];
      final result = service.analyzeSignals(signals);
      expect(result.recommendations.any((r) => r.contains('friend')), isTrue);
    });
  });

  group('analyzeSignals - recovery plan', () {
    test('always includes immediate steps', () {
      final result = service.analyzeSignals([
        const BurnoutSignal(name: 'Test', category: 'sleep', value: 90, weight: 1.0, trend: SignalTrend.stable),
      ]);
      final immediateSteps = result.recoveryPlan.where((s) => s.phase == 'Immediate');
      expect(immediateSteps.length, 2);
    });

    test('moderate risk adds short-term steps', () {
      final result = service.analyzeSignals(
        service.getSampleScenarios()[1].signals,
      );
      expect(result.recoveryPlan.any((s) => s.phase == 'Short-term'), isTrue);
    });

    test('high risk adds medium-term steps including day off', () {
      final result = service.analyzeSignals(
        service.getSampleScenarios()[3].signals,
      );
      final mediumSteps = result.recoveryPlan.where((s) => s.phase == 'Medium-term');
      expect(mediumSteps.length, greaterThanOrEqualTo(3));
      expect(
        result.recoveryPlan.any((s) => s.action.contains('day off')),
        isTrue,
      );
    });

    test('recovery plan scales with severity', () {
      final lowResult = service.analyzeSignals(
        service.getSampleScenarios()[0].signals,
      );
      final criticalResult = service.analyzeSignals(
        service.getSampleScenarios()[3].signals,
      );
      expect(
        criticalResult.recoveryPlan.length,
        greaterThan(lowResult.recoveryPlan.length),
      );
    });
  });

  group('analyzeSignals - weight sensitivity', () {
    test('higher weight signal has more impact on risk score', () {
      const highWeight = [
        BurnoutSignal(name: 'A', category: 'sleep', value: 30, weight: 3.0, trend: SignalTrend.stable),
        BurnoutSignal(name: 'B', category: 'mood', value: 80, weight: 1.0, trend: SignalTrend.stable),
      ];
      const lowWeight = [
        BurnoutSignal(name: 'A', category: 'sleep', value: 30, weight: 1.0, trend: SignalTrend.stable),
        BurnoutSignal(name: 'B', category: 'mood', value: 80, weight: 3.0, trend: SignalTrend.stable),
      ];
      final highWeightResult = service.analyzeSignals(highWeight);
      final lowWeightResult = service.analyzeSignals(lowWeight);
      // When the bad signal (value=30) has high weight, risk should be higher
      expect(highWeightResult.riskScore, greaterThan(lowWeightResult.riskScore));
    });
  });

  group('analyzeSignals - all scenarios produce valid output', () {
    test('every scenario produces complete analysis', () {
      for (final scenario in service.getSampleScenarios()) {
        final result = service.analyzeSignals(scenario.signals);
        expect(result.riskScore, inInclusiveRange(0, 100));
        expect(result.resilienceScore, inInclusiveRange(0, 100));
        expect(result.signals, equals(scenario.signals));
        expect(result.recoveryPlan, isNotEmpty);
      }
    });
  });
}
